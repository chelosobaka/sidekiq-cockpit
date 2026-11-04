Rails.application.routes.draw do
  mount SidekiqJobsDisplayer::Engine => '/admin/sidekiq'
end
