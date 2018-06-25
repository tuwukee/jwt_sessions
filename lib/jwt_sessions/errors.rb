module JWTSessions
  module Errors
    class Error < RuntimeError; end
    class Malconfigured < Error; end
    class InvalidPayload < Error; end
    class Unauthorized < Error; end
    class ClaimsVerification < Unauthorized; end
  end
end
