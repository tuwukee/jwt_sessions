# frozen_string_literal: true

require "minitest/autorun"
require "jwt_sessions"

class TestMemoryStoreAdapter < Minitest::Test
  attr_reader :store

  def setup
    @store = JWTSessions::StoreAdapters.build_by_name(:memory)
  end

  def test_error_on_unknown_option
    assert_raises ArgumentError do
      JWTSessions::StoreAdapters::MemoryStoreAdapter.new(something: "something")
    end
  end

  def test_persist_and_fetch_access
    store.persist_access("uid", "csrf", Time.now.to_i + 3600)
    assert_equal({ csrf: "csrf" }, store.fetch_access("uid"))

    store.persist_access("uid", "csrf", Time.now.to_i - 3600)
    assert_equal({}, store.fetch_access("uid"))
  end

  def test_persist_and_fetch_refresh
    expiration = Time.now.to_i + 3600
    store.persist_refresh(
      uid: "uid",
      access_expiration: expiration,
      access_uid: "access_uid",
      csrf: "csrf",
      expiration: expiration,
      namespace: ""
    )
    refresh = store.fetch_refresh("uid", "")
    assert_equal "csrf", refresh[:csrf]

    expiration = Time.now.to_i - 3600
    store.persist_refresh(
      uid: "uid",
      access_expiration: expiration,
      access_uid: "access_uid",
      csrf: "csrf",
      expiration: expiration,
      namespace: ""
    )
    refresh = store.fetch_refresh("uid", "")
    assert_nil refresh[:csrf]
  end

  def test_update_refresh
    expiration = Time.now.to_i + 3600
    store.persist_refresh(
      uid: "uid",
      access_expiration: expiration,
      access_uid: "access_uid",
      csrf: "csrf",
      expiration: expiration,
      namespace: ""
    )
    store.update_refresh(
      uid: "uid",
      access_expiration: expiration,
      access_uid: "access_uid",
      csrf: "csrf2",
      namespace: ""
    )
    refresh = store.fetch_refresh("uid", "")
    assert_equal "csrf2", refresh[:csrf]
  end

  def test_all_refresh_tokens
    expiration = Time.now.to_i + 3600
    store.persist_refresh(
      uid: "uid",
      access_expiration: expiration,
      access_uid: "access_uid",
      csrf: "csrf",
      expiration: expiration,
      namespace: "ns"
    )
    store.persist_refresh(
      uid: "uid",
      access_expiration: expiration,
      access_uid: "access_uid",
      csrf: "csrf",
      expiration: expiration,
      namespace: "ns2"
    )
    refresh_tokens = store.all_refresh_tokens("ns")
    assert_equal 1, refresh_tokens.count
  end

  def test_destroy_refresh
    expiration = Time.now.to_i + 3600
    store.persist_refresh(
      uid: "uid",
      access_expiration: expiration,
      access_uid: "access_uid",
      csrf: "csrf",
      expiration: expiration,
      namespace: ""
    )
    store.destroy_refresh("uid", "")
    refresh = store.fetch_refresh("uid", "")
    assert_equal({}, refresh)
  end

  def test_destroy_access
    store.persist_access("uid", "csrf", Time.now.to_i + 3600)
    store.destroy_access("uid")
    assert_equal({}, store.fetch_access("uid"))
  end
end
