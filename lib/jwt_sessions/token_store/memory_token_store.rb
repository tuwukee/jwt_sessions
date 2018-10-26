# frozen_string_literal: true

require 'redis'
require_relative 'abstract_token_store'

module JWTSessions
  module TokenStore
    class MemoryTokenStore < AbstractTokenStore
      EXPIRATION_KEY = :expiration
      UUID_REGEXP = /\A[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}\z/

      class << self
        def instance(_options = {})
          @instance ||= new
        end
      end

      attr_reader :access_store, :refresh_store

      def initialize
        @access_store = Hash.new { |h, k| h[k] = {} }
        @refresh_store = Hash.new { |h, k| h[k] = {} }
      end

      def fetch_access(uid)
        token = access_store[uid]
        return {} if expired?(token)
        except(token, EXPIRATION_KEY)
      end

      def persist_access(uid, csrf, expiration)
        access_store[uid] = { csrf: csrf, EXPIRATION_KEY => expiration }
      end

      def fetch_refresh(uid, namespace)
        built_key = refresh_key(uid, namespace)
        token_key = refresh_store.keys.find { |key| key.end_with?(built_key) }
        return {} unless token_key

        token = refresh_store[token_key]
        expired?(token) ? {} : token.dup
      end

      def persist_refresh(uid, access_expiration, access_uid, csrf, expiration, namespace = nil)
        key = refresh_key(uid, namespace)
        update_refresh(uid, access_expiration, access_uid, csrf, namespace)
        refresh_store[key][EXPIRATION_KEY] = expiration.to_s
      end

      def update_refresh(uid, access_expiration, access_uid, csrf, namespace = nil)
        refresh_store[refresh_key(uid, namespace)].merge!(
          csrf: csrf,
          access_expiration: access_expiration.to_s,
          access_uid: access_uid
        )
      end

      # TODO: Not quite understand what kind of namespace could be accepted here
      # Found nil as example, but for redis it also accepts '*' and returns all tokens
      def all(namespace)
        tokens = refresh_store.reject { |_, token| expired?(token) }
        tokens = if namespace && !namespace.empty?
                   tokens.select { |key| key.start_with?("#{namespace}_") }
                 else
                   tokens.select { |key| key.match(UUID_REGEXP) }
                 end

        tokens.each_with_object({}) do |(key, value), acc|
          uid = uid_from_key(key)
          acc[uid] = value
        end
      end

      def destroy_refresh(uid, namespace)
        refresh_store.delete(refresh_key(uid, namespace))
      end

      def destroy_access(uid)
        access_store.delete(uid)
      end

      private

      def except(hash, key)
        hash.reject { |k, _| k == key }
      end

      def expired?(token)
        token[EXPIRATION_KEY].to_i < Time.now.to_i
      end

      def refresh_key(uid, namespace = nil)
        namespace ? "#{namespace}_#{uid}" : uid
      end

      def uid_from_key(key)
        key.split('_').last
      end
    end
  end
end
