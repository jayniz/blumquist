# encoding: utf-8
require 'spec_helper'

describe Blumquist do
  it 'has a version number' do
    expect(Blumquist::VERSION).not_to be nil
  end


  context 'generating getters' do
    let(:support) { File.expand_path("../support", __FILE__) }
    let(:schema) { JSON.parse(open(File.join(support, 'schema.json')).read) }
    let(:data) { JSON.parse(open(File.join(support, 'data.json')).read) }
    let(:b) { Blumquist.new(schema: schema, data: data) }

    it "has getters for direct properties" do
      expect(b.name).to eq "Moviepilot, Inc."
    end

    it "has getters for non primitive properties" do
      expect(b.current_address.city).to eq "Berlin"
    end

    it "has getters for arrays of references" do
      expect(b.old_addresses[1].street_address).to eq "Bluecherstr. 22"
    end

    it "has getters for arrays of objects" do
      expect(b.phone_numbers[0].prefix).to eq 555
      expect(b.phone_numbers[0].extension).to eq 1234
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
    end

    context "validation" do
      let(:invalid_data) {
        invalid = JSON.parse(data.to_json)
        invalid['name'] = 1
        invalid
      }

      it "is on by default" do
        expect {
          Blumquist.new(schema: schema, data: invalid_data)
        }.to raise_error(JSON::Schema::ValidationError)
      end

      it "can be switched off" do
        b = Blumquist.new(schema: schema, data: invalid_data, validate: false)
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
        data = JSON.parse('{"an_array":[0,1,99,3,4]}')
        expect {
          blumquist_object = Blumquist.new(schema: event_schema, data: data)
          expect(blumquist_object.an_array[2]).to eq 99
        }.to_not raise_error
      end

      it "correctly validates a nullable array of numbers" do
        event_schema=JSON.parse(open(File.join(support, "array_schema_nullable.json")).read)
        data = JSON.parse('{"an_array_nullable": [0,1,99,3,4]}')
        expect {
          blumquist_object = Blumquist.new(schema: event_schema, data: data)
          expect(blumquist_object.an_array_nullable[2]).to eq 99
        }.to_not raise_error
      end

      it "correctly validates a nullable array of numbers that is null" do
        event_schema=JSON.parse(open(File.join(support, "array_schema_nullable.json")).read)
        data = JSON.parse('{"an_array_nullable": null}')
        expect {
          blumquist_object = Blumquist.new(schema: event_schema, data: data)
          expect(blumquist_object.an_array_nullable).to eq nil
        }.to_not raise_error
      end
    end


  end
end
