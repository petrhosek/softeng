require 'sinatra/base'

module Sinatra
  module EscapeHelper
    def h(text)
      Rack::Utils.escape_html(text)
    end
  end

  helpers EscapeHelper
end