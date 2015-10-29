require 'spec_helper'

describe Bumquist do
  it 'has a version number' do
    expect(Bumquist::VERSION).not_to be nil
  end



  context 'generating getters' do
    let(:support) { File.expand_path("../support", __FILE__) }
    let(:schema) { open(File.join(support, 'schema.json')).read }
    let(:data) { open(File.join(support, 'schema.json')).read }
    let(:b){ Bumquist.new(schema, data) }

  end
end
