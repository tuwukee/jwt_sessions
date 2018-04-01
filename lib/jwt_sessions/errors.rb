module JWTSessions
  module Errors
    class Error < RuntimeError; end
    class Malconfigured < Error; end
    class InvalidPayload < Error; end
    class Unauthorized < Error; end
  end
end
