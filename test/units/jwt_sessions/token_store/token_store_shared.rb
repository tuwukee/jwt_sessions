require 'jwt_sessions'

module TokenStoreShared
  def test_access_token
    expiration = Time.now.to_i + 3600
    @store.persist_access(@uid, @csrf, expiration)
    assert_equal({ csrf: @csrf }, @store.fetch_access(@uid))

    @store.destroy_access(@uid)
    assert_equal({}, @store.fetch_access(@uid))
  end

  def test_access_token_expired
    expiration = Time.now.to_i - 1
    @store.persist_access(@uid, @csrf, expiration)
    assert_equal({}, @store.fetch_access(@uid))
  end


  def test_refresh_token
    expiration = Time.now.to_i + 3600
    access_expiration = Time.now.to_i + 3900
    access_uid = SecureRandom.uuid
    namespace = 'test'

    @store.persist_refresh(@uid, access_expiration, access_uid, @csrf, expiration, namespace)
    token = @store.fetch_refresh(@uid, namespace)
    assert_equal({
                   csrf: @csrf,
                   access_uid: access_uid,
                   access_expiration: access_expiration.to_s,
                   expiration: expiration.to_s
                 }, token)

    wrong_token = @store.fetch_refresh(@uid, 'wrong')
    assert_equal({}, wrong_token)

    token = @store.fetch_refresh(@uid, nil)
    assert_equal({
                   csrf: @csrf,
                   access_uid: access_uid,
                   access_expiration: access_expiration.to_s,
                   expiration: expiration.to_s
                 }, token)

    new_csrf = JWTSessions::CSRFToken.new.encoded
    new_access_expiration = Time.now.to_i + 4000
    new_access_uid = SecureRandom.uuid
    @store.update_refresh(@uid, new_access_expiration, new_access_uid, new_csrf, namespace)

    token = @store.fetch_refresh(@uid, namespace)
    assert_equal({
                   csrf: new_csrf,
                   access_uid: new_access_uid,
                   access_expiration: new_access_expiration.to_s,
                   expiration: expiration.to_s
                 }, token)

    @store.destroy_refresh(@uid, namespace)

    token = @store.fetch_refresh(@uid, namespace)
    assert_equal({}, token)
  end

  def test_refresh_token_expired
    expiration = Time.now.to_i - 1
    access_expiration = Time.now.to_i + 3900
    access_uid = SecureRandom.uuid
    namespace = 'test'
    @store.persist_refresh(@uid, access_expiration, access_uid, @csrf, expiration, namespace)

    assert_equal({}, @store.fetch_refresh(@uid, namespace))
  end

  def test_all_refresh_token
    uid1 = SecureRandom.uuid
    uid2 = SecureRandom.uuid
    uid3 = SecureRandom.uuid
    access_uid = SecureRandom.uuid
    namespace = 'test'
    expiration = Time.now.to_i + 3600
    access_expiration = Time.now.to_i + 3900
    @store.persist_refresh(uid1, access_expiration, access_uid, @csrf, expiration, namespace)
    @store.persist_refresh(uid2, access_expiration, access_uid, @csrf, expiration, namespace)
    @store.persist_refresh(uid3, access_expiration, access_uid, @csrf, expiration)

    tokens = @store.all(namespace)
    assert_equal 2, tokens.size

    namespaced_uids = tokens.keys
    assert_includes namespaced_uids, uid1
    assert_includes namespaced_uids, uid2

    tokens = @store.all('')
    assert_equal 1, tokens.size
    assert_includes tokens.keys, uid3
  end
end
