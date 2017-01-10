# frozen_string_literal: true
require 'spec_helper'
require 'request_handler/body_handler'
describe RequestHandler::BodyHandler do
  let(:handler) do
    described_class.new(schema: schema, request: build_mock_request(params: {}, headers: {}, body: raw_body))
  end
  shared_examples 'flattens the body as expected' do
    it 'returns the flattend body' do
      expect(handler).to receive(:validate_schema).with(wanted_result)
      handler.run
    end
  end

  let(:schema) { Dry::Validation.JSON {} }

  context 'one relationships' do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "id": "fer342ref",
          "type": "post",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
              "data": {
                "id": "54",
                "type": "category"
              }
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        'id'         => 'fer342ref',
        'type'       => 'post',
        'user_id'    => 'awesome_user_id',
        'name'       => 'About naming stuff and cache invalidation',
        'publish_on' => '2016-09-26T12:23:55Z',
        'category'   => {
          'id'   => '54',
          'type' => 'category'
        }
      }
    end
    it_behaves_like 'flattens the body as expected'
  end

  context 'multiple relationships' do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
              "data": {
                "id": "54",
                "type": "category"
              }
            },
            "comments": {
              "data": {
                "id": "1",
                "type": "comment"
              }
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        'id'         => 'fer342ref',
        'type'       => 'post',
        'user_id'    => 'awesome_user_id',
        'name'       => 'About naming stuff and cache invalidation',
        'publish_on' => '2016-09-26T12:23:55Z',
        'category'   => {
          'id'   => '54',
          'type' => 'category'
        },
        'comments' => {
          'id'   => '1',
          'type' => 'comment'
        }
      }
    end
    it_behaves_like 'flattens the body as expected'
  end

  context 'array in a relationship' do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "id": "fer342ref",
          "type": "post",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
              "data": [
                {
                  "id": "54",
                  "type": "category"
                },
                {
                  "id": "55",
                  "type": "category2"
                }
              ]
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        'id'         => 'fer342ref',
        'type'       => 'post',
        'user_id'    => 'awesome_user_id',
        'name'       => 'About naming stuff and cache invalidation',
        'publish_on' => '2016-09-26T12:23:55Z',
        'category'   => [
          {
            'id'   => '54',
            'type' => 'category'
          },
          {
            'id'   => '55',
            'type' => 'category2'
          }
        ]
      }
    end
    it_behaves_like 'flattens the body as expected'
  end

  context 'without relationships' do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        'id'         => 'fer342ref',
        'type'       => 'post',
        'user_id'    => 'awesome_user_id',
        'name'       => 'About naming stuff and cache invalidation',
        'publish_on' => '2016-09-26T12:23:55Z'
      }
    end
    it_behaves_like 'flattens the body as expected'
  end

  context 'different types of Inputs' do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": 2,
            "name": [1 ,2, 3],
            "published": false
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        'id'        => 'fer342ref',
        'type'      => 'post',
        'user_id'   => 2,
        'name'      => [1, 2, 3],
        'published' => false
      }
    end
    it_behaves_like 'flattens the body as expected'
  end

  context 'without attributes' do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "relationships":{
            "category": {
              "data": {
                "id": "54",
                "type": "category"
              }
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        'id'       => 'fer342ref',
        'type'     => 'post',
        'category' => {
          'id'   => '54',
          'type' => 'category'
        }
      }
    end
    it_behaves_like 'flattens the body as expected'
  end

  it 'fails if the request body is nil' do
    schema = Dry::Validation.JSON {}
    expect do
      described_class.new(schema:  schema,
                          request: instance_double('Rack::Request', params: {}, env: {}, body: nil))
    end
      .to raise_error(RequestHandler::MissingArgumentError)
  end
end