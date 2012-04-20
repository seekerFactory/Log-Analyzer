class HostGroup
  include Mongoid::Document
  has_many :host

  PER_PAGE = 30
  paginates_per(PER_PAGE)

  field :name, :type => String
  field :host_count, :type => Integer  

  validates_presence_of :host_group

##	-- modiefied here
  STANDARD_HOST_GROUP = :local
  
  field :name, :type => String
  index :name,          :background => true, :unique => true
  
  def valid_host_group
#    [:local, :nonlocal]
  end
##	-- fin
end
