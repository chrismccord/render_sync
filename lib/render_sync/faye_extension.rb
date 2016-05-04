module RenderSync
  class FayeExtension

    def incoming(message, callback)
      return handle_eror(message, callback) unless message_authenticated?(message)
      if batch_publish?(message)
        batch_incoming(message, callback)
      else
        single_incoming(message, callback)
      end
    end

    def batch_incoming(message, callback)
      message["data"].each do |message|
        incoming(message, callback)
      end
    end

    def single_incoming(message, callback)
      callback.call(message)
    end

    def batch_publish?(message)
      message['channel'] == "/batch_publish"
    end

    # IMPORTANT: clear out the auth token so it is not leaked to the client
    def outgoing(message, callback)
      if message['ext'] && message['ext']['auth_token']
        message['ext'] = {} 
      end
      callback.call(message)
    end

    def handle_eror(message, callback)
      message['error'] = 'Invalid authentication token'
      callback.call(message)
    end

    def message_authenticated?(message)
      !(message['channel'] !~ %r{^/meta/} && 
        message['ext']['auth_token'] != RenderSync.auth_token)
    end
  end
end
