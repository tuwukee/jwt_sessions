module JWTSessions
  module RailsAuthorization
    include Authorization

    if Rails::VERSION::MAJOR < 5
      def request_headers
        request.headers
      end
    else
      def request_headers
        ActionDispatch::Http::Headers.from_hash(request.headers)
      end
    end

    def request_cookies
      request.cookie_jar
    end

    def request_method
      request.method
    end
  end
end
