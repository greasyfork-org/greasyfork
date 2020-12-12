if ENV['RAILS_ENV'] == 'development'
  ssl_bind '0.0.0.0', 3000, {
    key: '/www/mkcert/greasyfork.local-key.pem',
    cert: '/www/mkcert/greasyfork.local.pem',
  }
end
