Rails.application.routes.draw do
  # Existing routes

  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  # Fetch the current user's details
  get 'current_user', to: 'current_user#index'

  # Routes for requests
  resources :requests, only: [:show] do
    member do
      patch 'mark-as-completed', to: 'requests#mark_as_completed'
      post 'republish', to: 'requests#republish'
    end

    # Correctly place the collection block here, inside the resources :requests block
    collection do
      get 'active', to: 'requests#all_active_requests'
    end
  end  # This end closes the resources :requests block

  # Nested resources under users for requests
  resources :users do
    resources :requests, only: [:create, :show] do
      member do
        patch 'mark-as-completed', to: 'requests#mark_as_completed'
        post 'republish', to: 'requests#republish'
      end
    end

    # Existing routes for fetching my requests and volunteered jobs
    member do
      get 'my-requests', to: 'requests#my_requests'
      get 'volunteered-jobs', to: 'volunteerings#volunteered_jobs'
    end
  end

  # You might need to define a root or other routes here
  # root "some_controller#some_action"
end

