class Company
 include RedisGraph::Node

 property :name, String, :id => true

 validates_presence_of :name

 has n, :leads => :projects
 has n, :friends => :companies
end

class Project
  include RedisGraph::Node

  property :name,         String
  property :description,  String
  
  validates_presence_of :name

  belongs_to :client => :companies
  has n, :research
end

class Research
  include RedisGraph::Node

  property :name,         String
  property :data,         Binary
  property :mime_type,    String
  property :notes,        Text
  property :tags,         Set

  validates_presence_of :name
  
  belongs_to :project
end

class Lead
  include RedisGraph::Edge
  
  property :name,         String
  property :likelyhood,   Integer, :default => 5
  
  validates_presence_of :name
end

a = Company.new :name => 'a'
b = Company.new :name => 'b'
c = Project.new :name => 'c'

a.friends << b
a.leads << c
a.save

b.friends << a
b.leads << Lead.new(:name => 'Lead from Bob', :likelyhood => 10, :project => c)
b.save

puts a.leads.first.inspect
  => <Lead name=nil likelyhood=5 project=<Project ...>>

puts b.leads.first.inspect
  => <Lead name='Lead from Bob' likelyhood=10 project=<Project ...>>

# Adding Dynamic Relationships
#a.has_relationship :friends
#a.has_relationship :leads
#b.has_relationship :friends
#b.has_relationship :leads

#c.has_relationship :leads