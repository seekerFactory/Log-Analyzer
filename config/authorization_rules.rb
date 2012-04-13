authorization do
  role :admin do
    has_permission_on :messages, :to => [
      :index,
      :show,
      :destroy,
      :getcompletemessage,
      :getsimilarmessages,
      :showrange,
      :deletebyquickfilter,
      :deletebystream,
    ]

    has_permission_on :streams, :to => [
      :index,
      :show,
      :showrange,
      :create,
      :destroy,
      :setdescription,
      :setalarmvalues,
      :togglefavorited,
      :togglealarmactive,
      :togglealarmforce,
      :rules,
      :forward,
      :analytics,
      :settings,
      :subscribe,
      :togglesubscription,
      :rename,
      :categorize,
      :clone,
      :toggledisabled,
      :addcolumn,
      :removecolumn,
      :shortname,
      :related
    ]
    has_permission_on :streamrules, :to => [:create, :destroy]
    has_permission_on :streamcategories, :to => [:create, :destroy]

    has_permission_on :forwarders, :to => [:create, :destroy]

    has_permission_on :analytics, :to => [:index, :shell]

    has_permission_on :hosts, :to => [:index, :show, :destroy, :quickjump, :showrange]

    has_permission_on :blacklists, :to => [:index, :show, :create, :destroy]
    has_permission_on :blacklistedterms, :to => [:create, :destroy]

    has_permission_on :settings, :to => [:index, :store]

    has_permission_on :users, :to => [:new, :index, :show, :create, :edit, :delete, :update]

    has_permission_on :sessions, :to => [:destroy]

    has_permission_on :dashboard, :to => [:index]

    has_permission_on :health, :to => [:index]

    has_permission_on :retentiontime, :to => [:index]
  end

  role :reader do
    has_permission_on :streams, :to => [:index, :show, :analytics, :showrange] do
      if_attribute :users => contains { user }
    end
    has_permission_on :sessions, :to => [:destroy]
    has_permission_on :messages, :to => [:index, :show]
    has_permission_on :health, :to => [ :index ]
  end
end

privileges do
end
