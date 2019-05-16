require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::RequestBody do
  let(:root) { OpenAPIParser.parse(petstore_with_discriminator_schema, {}) }

  describe 'discriminator' do
    let(:content_type) { 'application/json' }
    let(:http_method) { :post }
    let(:request_path) { '/save_the_pets' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }

    it 'picks correct object based on mapping and succeeds' do
      body = {
        "baskets" => [
          {
            "name"    => "cats",
            "content" => [
              {
                "name"        => "Mr. Cat",
                "born_at"     => "2019-05-16T11 =>37 =>02.160Z",
                "description" => "Cat gentleman",
                "milk_stock"  => 10
              }
            ]
          },
        ]
      }

      request_operation.validate_request_body(content_type, body)
    end

    it 'picks correct object based on mapping and fails' do
      body = {
        "baskets" => [
          {
            "name"    => "cats",
            "content" => [
              {
                "name"        => "Mr. Cat",
                "born_at"     => "2019-05-16T11 =>37 =>02.160Z",
                "description" => "Cat gentleman",
                "nut_stock"   => 10 # passing squirrel attribute here, but discriminator still picks cats and fails
              }
            ]
          },
        ]
      }
      expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
        expect(e.kind_of?(OpenAPIParser::NotExistRequiredKey)).to eq true
        expect(e.message.start_with?("required parameters milk_stock not exist")).to eq true
      end
    end
  end
end
