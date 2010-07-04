class Company
 include RedisGraph::Node

 property :name, String, :id => true

 validates_presence_of :name

 # Has 0 - n projects via leads edges. Has many leads that are companies.
 has n, :leads, :for => :projects

 # Has 0 - n companies via friends edges. Has many friends that are companies.
 has n, :friends, :for => :companies
end

class Project
  include RedisGraph::Node

  property :name,         String
  property :description,  String
  
  validates_presence_of :name

  # Is a client of another company 
  belongs_to :client, :for => :companies

  # Has 0 - n research, via a undecorated edge
  has n, :research

  # Has 0 - n assets, that can be any type of thing
  has n, :assets, :model => :any
end

class Research
  include RedisGraph::Node

  property :name,         String
  property :data,         Binary
  property :mime_type,    String
  property :notes,        Text
  property :tags,         Set

  validates_presence_of :name
  
  # Is a projects research, via a undecorated edge
  belongs_to :project
end

class Lead
  include RedisGraph::Edge
  
  property :name,         String
  property :likelyhood,   Integer, :default => 5
  
  validates_presence_of :name
end

luma = Company.get('luma')
luma.leads              => Leads{label => 'Leads'}[0..n]
luma.leads.projects     => Basically luma.leads.collect {|lead| lead.project } only achieve with more efficiency
luma.friends            => Edges{label => 'Friends'}[0..n]
luma.friends.companies  => see luma.leads.projects


luma.outgoing_edges => [:leads, :friends]
luma.incoming_edges => [:friends]
