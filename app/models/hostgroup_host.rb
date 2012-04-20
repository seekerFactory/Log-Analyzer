class HostgroupHost
  include Mongoid::Document

  belongs_to :hostgroups
  validates_presence_of :hostgroup_id, :ruletype, :hostname

  field :hostname, :type => String

  TYPE_SIMPLE = 0
  TYPE_REGEX = 1

end
