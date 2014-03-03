Greasyfork::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

	# disable destroying users
	devise_for :users, :skip => :registrations, :controllers => { :sessions => "sessions" }
		devise_scope :user do
		resource :registration,
		only: [:new, :create, :edit, :update],
		path: 'users',
		path_names: { new: 'sign_up' },
		controller: :registrations,
		as: :user_registration do
			get :cancel
		end
	end
	devise_scope :user do 
		# a GET path for logging out for use with the forum
		get '/users/sign_out' => 'sessions#destroy'
	end
  
	root :to => "home#index"

	resources :scripts, :only => [:index, :show] do
		get 'code.user.js', :to => 'scripts#user_js', :as =>  'user_js'
		get 'code.meta.js', :to => 'scripts#meta_js', :as =>  'meta_js'
		get 'code(.:format)', :to => 'scripts#show_code', :as =>  'show_code'
		get 'feedback(.:format)', :to => 'scripts#feedback', :as =>  'feedback'
		post 'install-ping', :to => 'scripts#install_ping', :as => 'install_ping'
		get 'diff', :to => 'scripts#diff', :as => 'diff', :constraints => lambda{ |req| !req.params[:v1].blank? and !req.params[:v2].blank? }
		collection do
			get 'by-site(.:format)', :action => 'by_site', :as => 'site_list'
			get 'by-site/:site(.:format)', :action => 'index', :as => 'by_site', :constraints => {:site => /.*/}
			get 'under-assessment(.:format)', :action => 'under_assessment', :as => 'under_assessment'
		end
		resources :script_versions, :only => [:create, :new, :show, :index], :path => 'versions'
	end
	resources :script_versions, :only => [:create, :new]
	resources :users, :only => :show

	get 'import', :to => 'import#step1', :as => 'import_start'
	post 'import-step2', :to => 'import#step2', :as => 'import_step2'
	post 'import-step3', :to => 'import#step3', :as => 'import_step3'

	get 'help/allowed-markup', :to => 'help#allowed_markup', :as => 'help_allowed_markup'
	get 'help/code-rules', :to => 'help#code_rules', :as => 'help_code_rules'

	post 'preview-markup', :to => 'home#preview_markup', :as => 'preview_markup'

	get 'sso', :to => 'home#sso'

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

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
