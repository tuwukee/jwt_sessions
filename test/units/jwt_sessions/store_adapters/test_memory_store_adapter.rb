# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestMemoryStoreAdapter < Minitest::Test
  attr_reader :store

  def setup
    @store = JWTSessions::StoreAdapters.build_by_name(:memory)
  end

  def test_error_on_unknown_option
    assert_raises ArgumentError do
      JWTSessions::StoreAdapters::MemoryStoreAdapter.new(something: 'something')
    end
  end

  def test_persist_and_fetch_access
    store.persist_access('uid', 'csrf', Time.now.to_i + 3600)
    assert_equal({ csrf: 'csrf' }, store.fetch_access('uid'))

    store.persist_access('uid', 'csrf', Time.now.to_i - 3600)
    assert_equal({}, store.fetch_access('uid'))
  end

  def test_persist_and_fetch_refresh
    expiration = Time.now.to_i + 3600
    store.persist_refresh('uid', expiration, 'access_uid', 'csrf', expiration, '')
    refresh = store.fetch_refresh('uid', '')
    assert_equal 'csrf', refresh[:csrf]

    expiration = Time.now.to_i - 3600
    store.persist_refresh('uid', expiration, 'access_uid', 'csrf', expiration, '')
    refresh = store.fetch_refresh('uid', '')
    assert_nil refresh[:csrf]
  end

  def test_update_refresh
    expiration = Time.now.to_i + 3600
    store.persist_refresh('uid', expiration, 'access_uid', 'csrf', expiration, '')
    store.update_refresh('uid', expiration, 'access_uid', 'csrf2', '')
    refresh = store.fetch_refresh('uid', '')
    assert_equal 'csrf2', refresh[:csrf]
  end

  def test_all
    expiration = Time.now.to_i + 3600
    store.persist_refresh('uid', expiration, 'access_uid', 'csrf', expiration, 'ns')
    store.persist_refresh('uid', expiration, 'access_uid', 'csrf', expiration, 'ns2')
    refresh_tokens = store.all('ns')
    assert_equal 1, refresh_tokens.count
  end

  def test_destroy_refresh
    expiration = Time.now.to_i + 3600
    store.persist_refresh('uid', expiration, 'access_uid', 'csrf', expiration, '')
    store.destroy_refresh('uid', '')
    refresh = store.fetch_refresh('uid', '')
    assert_equal({}, refresh)
  end

  def test_destroy_access
    store.persist_access('uid', 'csrf', Time.now.to_i + 3600)
    store.destroy_access('uid')
    assert_equal({}, store.fetch_access('uid'))
  end
end
