require 'moneta'

module JWTSessions
  class StorageAdapter
    extend Forwardable

    STORAGE_TYPES = [:Memory, :Redis, :LRUHash].freeze # also :Sqlite OR any of Moneta::Adapters https://github.com/minad/moneta/blob/master/feature_matrix.yaml

    attr_reader :storage, :base_prefix
    def_delegators :@storage, :[], :clear, :create, :delete, :with, :prefix

    class << self
      def instance(storage_opts)
        storage_type = (storage_opts[:storage] || :Memory)
        raise Errors::Malconfigured, "storage #{storage_type} is not supported, try one of #{STORAGE_TYPES}" unless
              STORAGE_TYPES.include?(storage_type)
        @_store ||= build_storage(storage_opts)
        @_prefix ||= storage_opts[:prefix]
        new(@_store, @_prefix)
      end

      def clear
        @_store.clear
      end

      private

      def new(store, prefix)
        super(store, prefix)
      end

      def build_storage(opts)
        store = Moneta.new(opts[:storage], expires: true)
        store = store.prefix(opts[:prefix]) if opts[:prefix]
        store
      end
    end

    def initialize(store, prefix)
      @storage, @base_prefix = store, prefix
    end

    def in_ns(namespace)
      namespace ? prefix(namespace) : storage
    end

    def set(key, payload, opts = {})
      _storage = in_ns(opts[:namespace])
      old_val = _storage[key]
      new_val = if old_val && old_val.is_a?(Hash)
                  old_val.merge!(payload)
                elsif !old_val.is_a?(Hash) && !old_val.is_a?(NilClass)
                  raise Errors::Error, "non-Hash value is not supported by storage - #{old_val}.is_a #{old_val.class}, retry with Hash"
                else
                  payload
                end#.map{|k,v| v='' if v.nil?}
      _storage.store('meta_keys', { key => key }, expires: 0)
      _storage.store(key, new_val, expires: opts[:expires])
    end

    def get(namespace, key, keys = [])
      return in_ns(namespace)[key] if keys.empty?
      in_ns(namespace)[key]&.values_at(*keys)
    end

    def keys_in(namespace)
      in_ns(namespace)['meta_keys'].keys
    end

  end
end
