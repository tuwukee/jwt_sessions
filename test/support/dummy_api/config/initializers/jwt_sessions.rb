JWTSessions.algorithm = "HS256"
JWTSessions.signing_key = Rails.application.secrets.secret_key_base
JWTSessions.token_store = ENV['STORE_ADAPTER'] || 'redis'
