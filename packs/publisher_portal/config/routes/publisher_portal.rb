# frozen_string_literal: true

scope :publisher_portal do
  get '/index', to: 'subscription_charge#index'
end
