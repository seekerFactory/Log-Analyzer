class Host
  include Mongoid::Document
#  embedded_in :host_group
# :inverse_of => host_group

  PER_PAGE = 30
  paginates_per(PER_PAGE)

  field :host, :type => String
  field :message_count, :type => Float  # FIXME float??? so we can have 3.14 messages from this host?

  validates_presence_of :host

##	-- modiefied here
  STANDARD_HOST_GROUP = :local
  
  field :host_group, :type => String
  
#	This will be replaced by the set
  def self.all_of_group(hostgroup)
    return Host.all :conditions => { :host.in => hostgroup.all_conditions }
  end

  def valid_host_group
    [:local, :nonlocal]
  end
##	-- fin
end
