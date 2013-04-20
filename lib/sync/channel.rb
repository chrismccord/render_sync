module Sync

  class Channel

    attr_accessor :name

    def initialize(name)
      self.name = name
    end

    def signature
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest::Digest.new('sha1'),
        Sync.auth_token,
        self.name
      )
    end
  end
end
