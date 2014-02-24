module Sync

  class Channel

    attr_accessor :name

    def initialize(name)
      self.name = name
    end

    def signature
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        Sync.auth_token,
        self.name
      )
    end

    def to_s
      Sync.client.normalize_channel(self.signature)
    end
  end
end
