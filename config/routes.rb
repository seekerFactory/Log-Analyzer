Graylog2WebInterface::Application.routes.draw do
  match 'logout' => 'sessions#destroy', :as => :logout
  match 'login' => 'sessions#new', :as => :login
  resource :session
  resources :dashboard
  resources :operations

  resources :users do
    collection do
      post :createfirst
      get :first
    end
  end

  resources :messages do
    collection do
      post :showrange
      get :showrange
      post :deletebystream
      post :deletebyquickfilter
    end
    member do
      post :show
    end
  end

  resources :blacklists do
    resources :blacklistedterms, :as => "terms"
  end

  resources :hosts, :constraints => { :id => /.*/ } do
    resources :messages

    member do
      post :showrange
      get :showrange
    end

    collection do
      post :quickjump
    end
  end

  resources :messagecomments do
  end

  resources :streams do
    resources :messages
    resources :streamrules
    resources :forwarders

    resources :dashboard

    member do
      get :analytics
      post :favorite
      post :unfavorite
      post :alertable
      post :setdescription
      post :showrange
      get :showrange
      post :rules
      get :rules
      post :forward
      get :forward
      post :setalarmvalues
      post :togglealarmactive
      post :togglefavorited
      post :togglealarmforce
      post :togglesubscription
      post :toggledisabled
      post :rename
      post :clone
      get :settings
      post :subscribe
      post :unsubscribe
      post :categorize
      post :addcolumn
      delete :removecolumn
      post :shortname
      post :related
    end
  end

  resources :alertedstreams do
    member do
      post :toggle
    end
  end

  resources :subscribedstreams do
    member do
      post :toggle
    end
  end

  resources :streamcategories do
    member do
      get :rename
    end
  end

  resource :analytics do
    get :index
    post :shell
  end

  resources :versioncheck do
    collection do
      get :perform
    end
  end

  resources :filteredterms

  resources :visuals, :constraints => {:id => /[a-z]+/} do
    member do
      post :fetch
    end
  end

  resources :health do
    collection do
      post :currentthroughput
      post :currentmqsize
    end
  end

  resources :retentiontime

  resources :settings do
    collection do
      post :store
    end
  end

  match '/visuals/fetch/:id' => 'visuals#fetch',:as => "visuals"

  root :to => 'messages#index'
end
