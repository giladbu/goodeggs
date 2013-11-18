require 'sinatra/partial'
require 'dashing'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'
  set :history, {}
  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  register Sinatra::Partial
  run Sinatra::Application.sprockets
end

run Sinatra::Application
