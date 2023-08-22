# frozen_string_literal: true

Rails.application.routes.draw do
  concern :list do
    get :list, on: :collection
  end

  concern :unroll do
    get :unroll, on: :collection
  end

  namespace :banking do
    resource :cash_synchronization, only: :new do
      delete :delete_requisition
      get :build_requisition
      get :perform
    end
  end
end
