Rails.application.routes.draw do
  mount SidekiqCockpit::Engine => '/admin/sidekiq'
end
