require 'sinatra/base'

module Sinatra
  module BasicAuth
    module Helpers
      def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
      end
      
      def authorized?
        unauthorized! unless request.env['REMOTE_USER']
      end

      def unauthorized!(realm="portal")
        header 'WWW-Authenticate' => %(Basic realm="#{realm}")
        throw :halt, [ 401, 'Authorization Required' ]
      end

      def authorize!
        unless authorized?
          @auth ||=  Rack::Auth::Basic::Request.new(request.env)
          @auth.provided? && @auth.basic? && @auth.credentials
          request.env['REMOTE_USER'] = @auth.username
        end
      end
    end

    def self.registered(app)
      app.helpers BasicAuth::Helpers
    end
  end

  register BasicAuth
end