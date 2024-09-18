# frozen_string_literal: true

JWTSessions.algorithm = 'HS256'
JWTSessions.signing_key = 'super-secret-key'
JWTSessions.token_store = ENV['STORE_ADAPTER'] || 'redis'
