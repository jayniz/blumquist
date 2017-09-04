require 'spec_helper'

RSpec.describe Blumquist::JSONPointer do
  let(:path_to_schema) { File.expand_path('../../support/schema.json', __FILE__) }
  let(:document) { JSON.parse( File.read(path_to_schema) ) }

  subject { described_class.new(uri, document: document).value }

  describe '#value' do
    context 'valid pointer path' do
      context 'points to current document' do
        let(:uri)  { '#/properties/phone_numbers/items' }

        it { is_expected.to eq([{"$ref" => "spec/support/phone_number_schema.json"}]) }
      end

      context 'points to external document' do
        let(:uri)  { 'spec/support/array_schema.json#/type' }

        it { is_expected.to eq('object') }
      end
    end

    context 'invalid pointer path' do
      context 'not supported pointer' do
        let(:uri)  { '/properties/phone_numbers/items' }

        it 'raises Errors::UnsupportedPointer' do
          expect { subject }.to raise_error(Blumquist::Errors::UnsupportedPointer, /#{uri}/)
        end
      end

      context 'points to non existent key' do
        let(:uri)  { '#/properties/phone_numbers/gosh' }

        it 'raises Errors::InvalidPointer' do
          expect { subject }.to raise_error(Blumquist::Errors::InvalidPointer, /#{uri}/)
        end
      end
    end
  end
end
