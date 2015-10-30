require 'spec_helper'

describe Blumquist do
  it 'has a version number' do
    expect(Blumquist::VERSION).not_to be nil
  end


  context 'generating getters' do
    let(:support) { File.expand_path("../support", __FILE__) }
    let(:schema) { JSON.parse(open(File.join(support, 'schema.json')).read) }
    let(:data) { JSON.parse(open(File.join(support, 'data.json')).read) }
    let(:b){ Blumquist.new(schema: schema, data: data) }

    it "has getters for direct properties" do
      expect(b.name).to eq "Moviepilot, Inc."
    end

    it "has getters for sub-objects" do
      expect(b.current_address.city).to eq "Berlin"
    end

    it "has getters for sub-arrays" do
      expect(b.old_addresses[1].street_address).to eq "Bluecherstr. 22"
    end

    context "validation" do
      let(:invalid_data){ 
        invalid = JSON.parse(data.to_json)
        invalid['name'] = 1
        invalid
      }

      it "is on by default" do
        expect{
          Blumquist.new(schema: schema, data: invalid_data) 
        }.to raise_error(JSON::Schema::ValidationError)
      end

      it "can be switched off" do
        b = Blumquist.new(schema: schema, data: invalid_data, validate: false)
        expect(b.name).to eq 1
      end

    end


  end
end
