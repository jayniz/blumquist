# encoding: utf-8
require 'spec_helper'
require 'pry'

describe Blumquist do
  it 'has a version number' do
    expect(Blumquist::VERSION).not_to be nil
  end


  context 'generating getters' do
    let(:support) { File.expand_path("../support", __FILE__) }
    let(:schema) { JSON.parse(open(File.join(support, 'schema.json')).read) }
    let(:oneOf_schema) { JSON.parse(open(File.join(support, 'oneOf_schema.json')).read) }
    let(:data) { JSON.parse(open(File.join(support, 'data.json')).read) }
    let(:b) { Blumquist.new(schema: schema, data: data) }

    it "has getters for direct properties" do
      expect(b.name).to eq "Moviepilot, Inc."
    end

    it "has getters for non primitive properties" do
      expect(b.current_address.city).to eq "Berlin"
    end

    it "has getters for arrays of references" do
      expect(b.old_addresses[2].street_address).to eq "Bluecherstr. 22"
    end

    it "has getters for arrays of objects" do
      expect(b.phone_numbers[0].prefix).to eq 555
      expect(b.phone_numbers[0].extension).to eq 1234
    end

    let(:invalid_data_name_too_long) {
      invalid = JSON.parse(data.to_json)
      invalid['name'] = "Moviepilot GmbH, Moviepilot, Inc."
      invalid
    }

    it "supports maxLength on strings" do
      expect {
        Blumquist.new(schema: schema, data: invalid_data_name_too_long, validate: true)
      }.to raise_error(Blumquist::Errors::ValidationError)
    end

    context "oneOf expressions" do

      it "with inline objects" do
        data = {"current_address" => {"planet" => "οὐρανός"}}
        blumquist = Blumquist.new(schema: schema, data: data)
        expect(blumquist.current_address.planet).to eq "οὐρανός"
      end

      it "with null objects" do
        data = {"current_address" => nil}
        blumquist = Blumquist.new(schema: schema, data: data)
        expect(blumquist.current_address).to be_nil
      end

      it "with primitives allowed in an array but only non matching objects contained" do
        schema = {"type" => "object", "properties": { "oo": {"type": "array", "items": {"oneOf": [{"type": "null"}]}}}}
        data = {"oo" => [{"invalid" => "object"}]}
        Blumquist.new(schema: schema, data: data, validate: false)
      end

      context "with oneOfs references that do not appear in the data" do
        let(:blumquist) do
          data = { "name" => { "first_name" => "Mario" } }
          Blumquist.new(schema: oneOf_schema, data: data, validate: true)
        end

        it "defines getters for all oneOfs" do
          expect(blumquist.name).to respond_to(:first_name)
          expect(blumquist.name).to respond_to(:middle_name)
        end
      end
    end

    context "validation" do

      let(:invalid_data_name_as_number) {
        invalid = JSON.parse(data.to_json)
        invalid['name'] = 1
        invalid
      }

      it "is on by default" do
        expect {
          Blumquist.new(schema: schema, data: invalid_data_name_as_number)
        }.to raise_error(Blumquist::Errors::ValidationError)
      end

      it "can be switched off" do
        b = Blumquist.new(schema: schema, data: invalid_data_name_as_number, validate: false)
        expect(b.name).to eq 1
      end

      it "correctly validate sub schema with an object property" do
        # Converting properties of type 'object' seem to have an array as schema-type (like '[object]')
        # ensure, that creating a Blumquist object from such a property works as expected
        # Blumquist.new() had a problem validating such a schema.
        event_schema=JSON.parse(open(File.join(support, 'event_schema.json')).read)
        data = JSON.parse('{"event":{"type":"edward.comment"}}')
        expect {
          Blumquist.new(schema: event_schema, data: data)
        }.to_not raise_error
      end

      it "correctly validates an array of numbers property" do
        event_schema=JSON.parse(open(File.join(support, "array_schema.json")).read)
        data = JSON.parse('{"mentions":[0,1,99,3,4]}')
        expect {
          blumquist_object = Blumquist.new(schema: event_schema, data: data)
          expect(blumquist_object.mentions[2]).to eq 99
        }.to_not raise_error

      end

    end
  end

  context 'object serialization' do
    let(:support) { File.expand_path("../support", __FILE__) }
    let(:schema) { JSON.parse(open(File.join(support, 'schema.json')).read) }
    let(:data) { JSON.parse(open(File.join(support, 'data.json')).read) }
    let(:b) { Blumquist.new(schema: schema, data: data) }

    it 'serializes the object to binary' do
      expect { Marshal.dump(b) }.to_not raise_error
    end

    it 'deserializes the binary string to a blumquist object' do
      binary = Marshal.dump(b)
      loaded_blumquist = Marshal.load(binary)
      expect(loaded_blumquist.name).to eq(b.name)
      expect(loaded_blumquist.phone_numbers.map { |p| p.prefix }).to eq(b.phone_numbers.map { |p| p.prefix })
      expect(loaded_blumquist.phone_numbers.map { |p| p.extension }).to eq(b.phone_numbers.map { |p| p.extension })
      expect(loaded_blumquist.current_address.street_address).to eq(b.current_address.street_address)
      expect(loaded_blumquist.current_address.city).to eq(b.current_address.city)
      expect(loaded_blumquist.current_address.state).to eq(b.current_address.state)
      expect(loaded_blumquist.old_addresses.map { |o| o.street_address }).to eq(b.old_addresses.map { |o| o.street_address })
      expect(loaded_blumquist.old_addresses.map { |o| o.city }).to eq(b.old_addresses.map { |o| o.city })
      expect(loaded_blumquist.old_addresses.map { |o| o.state }).to eq(b.old_addresses.map { |o| o.state })
    end
  end
end
