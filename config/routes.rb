Rails.application.routes.draw do
  constraints subdomain: 'admin' do
    resources :sessions, only: %i[show create]
    get '/login' => 'sessions#new', as: :login
    delete '/logout' => 'sessions#destroy', as: :logout

    resources :email_suppressions, only: :destroy

    get 'activity_participations/calendar' => 'activity_participations_calendar#show',
      defaults: { format: :ics }
    get 'billing/:year' => 'billings#show', as: :billing
    get 'billing/snapshots/:id' => 'billing_snapshots#show', as: :billing_snapshot

    get 'settings' => 'acps#edit', as: :edit_acp
    get 'settings' => 'acps#edit', as: :acps
    resource :acp, path: 'settings', only: :update

    get 'deliveries/next' => 'next_delivery#next'

    ActiveAdmin.routes(self)
  end

  scope module: 'members', as: 'members' do
    constraints subdomain: 'membres' do
      resources :sessions, only: %i[show create]
      get '/login' => 'sessions#new', as: :login
      delete '/logout' => 'sessions#destroy', as: :logout

      resource :membership, only: %i[show] do
        resource :renewal, only: %i[new create], controller: 'membership_renewals'
        get ':decision' => 'membership_renewals#new'
      end

      resources :deliveries, only: :index
      resources :activities, only: :index
      resources :activity_participations, only: %i[index create destroy]
      namespace :group_buying do
        get '/' => 'base#show'
        resources :orders, only: :create
      end
      resources :absences, only: %i[index create destroy]
      get 'billing' => 'billing#index'
      resource :member, only: %i[new show create], path: '' do
        get 'welcome', on: :collection
      end
      resource :account, only: %i[show edit update]
    end
  end
end
