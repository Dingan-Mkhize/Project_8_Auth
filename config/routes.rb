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

  # Nested resources under users for requests
  resources :users do
    # Existing requests route
    resources :requests, only: [:create]

    # Add routes for fetching my requests and volunteered jobs
    member do
      get 'my-requests', to: 'requests#my_requests'
      get 'volunteered-jobs', to: 'volunteerings#volunteered_jobs'
    end
  end

  # You might need to define a root or other routes here
  # root "some_controller#some_action"
end
