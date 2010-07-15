class Company
 include Snowflake::Node

 property :name, String, :id => true

 validates_presence_of :name

 # Has 0 - n projects via leads edges. Has many leads that are companies.
 has n, :leads, :for => :projects

 # Has 0 - n companies via friends edges. Has many friends that are companies.
 has n, :friends, :for => :companies
end

class Project
  include Snowflake::Node

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
  include Snowflake::Node

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
  include Snowflake::Edge
  
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

b.leads.first.project

# What about the list of projects? Maybe...?
b.projects  => actually b.leads.collect {|l| l.project }

# Adding Dynamic Relationships?
#a.has_relationship :friends
#a.has_relationship :leads
#b.has_relationship :friends
#b.has_relationship :leads

#c.has_relationship :leads