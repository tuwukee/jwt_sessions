module JWTSessions
  module Errors
    class Error < RuntimeError; end
    class DecodeError < Error; end
    class Malconfigured < Error; end
    class Unauthorized < Error; end
  end
end
