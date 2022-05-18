# frozen_string_literal: true

Rails.application.routes.draw do
  concern :list do
    get :list, on: :collection
  end

  concern :unroll do
    get :unroll, on: :collection
  end

  namespace :banking do
    resources :transactions, only: %i[new] do
      member do
        get :build_requisition
        get :sync_account
      end
    end
  end

end
