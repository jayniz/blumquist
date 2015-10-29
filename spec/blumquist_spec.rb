require 'spec_helper'

describe Blumquist do
  it 'has a version number' do
    expect(Blumquist::VERSION).not_to be nil
  end


  context 'generating getters' do
    let(:support) { File.expand_path("../support", __FILE__) }
    let(:schema) { JSON.parse(open(File.join(support, 'schema.json')).read) }
    let(:data) { JSON.parse(open(File.join(support, 'data.json')).read) }
    let(:b){ Blumquist.new(schema, data) }

    it "has getters for direct properties" do
      expect(b.name).to eq "Ronny Rockel"
    end

    it "has getters for sub-objects" do
      expect(b.shipping_address.city).to eq "Berlin"
    end

    it "has getters for sub-arrays" do
      expect(b.other_addresses.last.street_address).to eq "Blücherstraße 22"
    end

  end
end
