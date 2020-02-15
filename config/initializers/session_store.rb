# Be sure to restart your server when you modify this file.

Greasyfork::Application.config.session_store :cookie_store, key: '_greasyfork_session', secure: Rails.env.production?
