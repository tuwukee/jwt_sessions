# frozen_string_literal: true

module JWTSessions
  class CSRFToken
    CSRF_LENGTH = 32

    attr_reader :encoded, :token

    def initialize(csrf_token = nil)
      @encoded = csrf_token || SecureRandom.base64(CSRF_LENGTH)
      @token   = masked_token
    end

    def valid_authenticity_token?(encoded_masked_token)
      if !encoded_masked_token.is_a?(String) || encoded_masked_token.empty?
        return false
      end

      begin
        masked_token = Base64.strict_decode64(encoded_masked_token)
      rescue ArgumentError
        return false
      end

      if masked_token.length == CSRF_LENGTH
        secure_compare(masked_token, raw_token)
      elsif masked_token.length == CSRF_LENGTH * 2
        csrf_token = unmask_token(masked_token)
        secure_compare(csrf_token, raw_token)
      else
        false
      end
    end

    private

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end

    def unmask_token(masked_token)
      one_time_pad = masked_token[0...CSRF_LENGTH]
      encrypted_csrf_token = masked_token[CSRF_LENGTH..-1]
      xor_byte_strings(one_time_pad, encrypted_csrf_token)
    end

    def masked_token
      one_time_pad = SecureRandom.random_bytes(CSRF_LENGTH)
      encrypted_csrf_token = xor_byte_strings(one_time_pad, raw_token)
      masked_token = one_time_pad + encrypted_csrf_token
      Base64.strict_encode64(masked_token)
    end

    def raw_token
      Base64.strict_decode64(encoded)
    end

    def xor_byte_strings(s1, s2)
      s2_bytes = s2.bytes
      s1.each_byte.with_index { |c1, i| s2_bytes[i] ^= c1 }
      s2_bytes.pack("C*")
    end
  end
end