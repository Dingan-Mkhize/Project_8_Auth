# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'project8auth-production.up.railway.app' # This is for development only, to replace with app's URL for production.

    resource '*',
      headers: :any, 
      expose: ['Authorization', 'Access-Token', 'Uid'],
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      credentials: true
end
end