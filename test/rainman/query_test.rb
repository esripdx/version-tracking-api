require_relative '../test_helper'

class AppTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app
    App
  end

  def setup
    DB.exec 'DELETE FROM stats'
    # Insert a bunch of test data to query

    post '/report', {
      group_id: 'group-a',
      client_id: 'client-1',
      date: '2014-01-01',
      key: 'version',
      value: '1.0',
      number: 2
    }
    post '/report', {
      group_id: 'group-a',
      client_id: 'client-1',
      date: '2014-01-02',
      key: 'version',
      value: '1.0',
      number: 2
    }

  end

  def test_query_empty_parameters
    post '/query'

    assert last_response.ok?
    response = JSON.parse last_response.body
    assert_equal 'invalid_input', response['error']['type']

    required_params = ['keys']

    parameters = response['error']['parameters'].keys
    required_params.each do |param|
      assert_includes response['error']['parameters'].keys, param
      parameters.delete param
    end
    assert_equal [], parameters
  end

  def test_query_rejects_invalid_from_date
    post '/query', { from: 'FOO' }
    response = JSON.parse last_response.body
    assert_equal 'invalid', response['error']['parameters']['from'][0]['type']

    post '/query', { from: '20131201' }
    response = JSON.parse last_response.body
    assert_equal 'invalid', response['error']['parameters']['from'][0]['type']
  end

  def test_query_rejects_invalid_to_date
    post '/query', { to: 'FOO' }
    response = JSON.parse last_response.body
    assert_equal 'invalid', response['error']['parameters']['to'][0]['type']

    post '/query', { to: '20131201' }
    response = JSON.parse last_response.body
    assert_equal 'invalid', response['error']['parameters']['to'][0]['type']
  end

  def test_query_rejects_value_with_multiple_keys
    post '/query', { keys: 'device_os,device_version', value: '1.0' }
    response = JSON.parse last_response.body
    assert_equal 'invalid_input', response['error']['type']
    assert_equal 'invalid', response['error']['parameters']['value'][0]['type']
  end

end
