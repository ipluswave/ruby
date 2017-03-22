Rails.application.routes.draw do

  mount Bootsy::Engine => '/bootsy', as: 'bootsy'
  wash_out :icard
  
  resources :costs

  resources :card_templates do
    get "upload", :on => :member
    member do
      get 'image/:user_data_id/:side(/:preview)', :action => 'image', :as => 'image'
    end
  end

  resources :card_types

  resources :organizations
  
  get 'card/:card_id/:side/preview', to: 'cards#preview'

  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  
  namespace :api do
    match "/" => "v1/docs#api", :via => :get
    namespace :v1 do
      match "/" => "docs#api", :via => :get
      resources :docs
      resources :card_templates do
        post "upload", :on => :member, defaults: {format: :json}
      end
      resources :print_jobs do
        post "add_users", :on => :member, defaults: {format: :json}
        put "print", :on => :member, defaults: {format: :json}
      end
      resources :organizations, :only => [:index] do
        get "letters", :on => :member, defaults: {format: :json}
        get "fonts", :on => :member, defaults: {format: :json}
        get "special_handlings", :on => :member, defaults: {format: :json}
      end
      resources :card_types, :only => [:index]
    end
    match "/v2/" => "v2/docs#api", :via => :get
    namespace :v2 do
      match "/" => "docs#api", :via => :get
      post "authenticate" => "authentication#authenticate"
      get "profile/me" => "users#me"
      post "users/password_reset" => "users#password_reset"
      post "users/password_new" => "users#password_new"
      resources :docs
      resources :organizations, :only => [:index, :show, :update] do
        get "balance", :on => :member
        get "shipping_providers", :on => :member
        resources :addresses, :only => [:index, :show, :create, :update, :destroy]
        resources :contacts, :only => [:index, :show, :create, :update, :destroy]
        resources :users, :only => [:index, :show, :create, :update, :destroy]
        resources :card_templates, :only => [:index] do
          get "fields", :on => :member
        end
        resources :cards, :only => [:index, :show, :create, :update, :destroy] do
          post "image", :on => :member
          get "preview", :on => :member
        end
        resources :print_jobs, :only => [:index, :show, :create, :update] do
          post "add_cards", :on => :member
          delete "remove_cards/:card_id", :action => "remove_cards", :on => :member
          post "print", :on => :member
          get "check_balance", :on => :member
        end
      end
    end
  end

  # You can have the root of your site routed with "root"
  root :to => redirect('/admin/')

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
