
class Company
 include RedisGraph::Node

 attribute :name, String, :id => true
 
 allow_dynamic_attributes!

 validates_presence_of :name
end

class Project
  include RedisGraph::Node

  attribute :name,         String
  attribute :description,  String
  
  # Boolean index type, create two sets: one true, one false
  # Project:index:active:true and Project:index:active:false
  attribute :active,       Boolean, :index => true
  
  allow_dynamic_attributes!

  list :todos
  set :tags

  validates_presence_of :name
end

class Research
  include RedisGraph::Node

  attribute :name,         String
  attribute :data,         Binary
  
  # String index type, one set for each index type: Research:index:mime_type:x
  attribute :mime_type,    String, :index => true
  attribute :notes,        Text

  set :tags

  set :data, ResearchData
  counter :version

  validates_presence_of :name
end

class ResearchData
  include RedisGraph::Node

  attribute :data,         Binary
  attribute :mime_type,    String
  attribute :notes,        Text  
  attribute :version,      Integer
  
  allow_dynamic_attributes!
end

class Category
  include RedisGraph::Node

  attribute :name,         String, :index => true
  attribute :description,  Text

  # Default this Category's level to be one more than it's parent
  # Index:  Category:index:level:x
  attribute :level, Integer, :default => {|n, p| n.parent.level + 1 unless n == nil }, :index => true

  # a single Category:x stored in the attribute hash?
  belongs_to :parent, :model => Category

  # set of ids of the form: Category:x, where x is the key
  has n, :children, :model => Category

  # set of ids of the form: Category:x, where x is the key
  has n, :descendants, :model => Category

  # set of ids of the form: y:x, where y is the model class, and x is the key
  has n, :products, :model => :any

  validate :ensure_valid_parents

  # Override the parent categoriess writer to ensure that all the parent's children and descendants get's properly recalculated
  def parent=(new_parent)
    # This should happend in one MULTI block
    # @todo all methods that might perform stuff in a MULTI block should accept a block to allow extra bits to get tacked on the end
    super do
      p = self.parent
      
      # Remove ourselves from our parent
      p.children.delete(self)

      d = self.descendants.append(self)

      # Then, for each parent, remove all descendants that were part of this subtree
      unless p == nil
        p.descendants.delete(d)
        p = p.parent
      end
    end
  end

  # Retrieve all top level (i.e. ones that have a level of 0) Categories
  def self.top_level
    all(:level => 0)
  end

  protected

  # Validate to ensure we never end up in a situation where a Category is the ancester of itself
  def ensure_valid_parents
    # @todo
    p = self.parent

    untill p == nil
      if p == self
        errors.add :parent, "Add helpful error message here"
        return false
      end
    end

    true
  end
end

# Get all Top Level Categories, and print their names
Category.top_level.each do |cat|
  puts cat.name # => Category#name
end

# Get the Category called 'iPad', and print the names of it's children
cat = Category.get('iPad')
cat.children.each do |child|
  puts child.name   # => Category#name
end

# Get the Category called 'iPod', and the print the names and base prices of all it's products
cat = Category.get('iPod')
cat.products.each do |product|
  puts "#{product.name}: $#{product.base_price}"
end

# Move a Category (and all it's children) from a 'Accessories' to 'iPad'
cat = Category.get('iPad Accessories')
puts cat.parent.name  # => 'Accessories'
cat.parent = Category.get('iPad')
puts cat.parent.name  # => 'iPad'


# This version supports multiple parent Categories
class Category
  include RedisGraph::Node

  attribute :name,         String, :index => true
  attribute :description,  Text
  attribute :top,          Boolean, :default => false, :index => true

  # set of ids of the form Category:x
  has n, :parents, :model => Category

  # set of ids of the form: Category:x, where x is the key
  has n, :children, :model => Category

  # set of ids of the form: Category:x, where x is the key
  has n, :descendants, :model => Category

  # set of ids of the form: y:x, where y is the model class, and x is the key
  has n, :products, :model => :any

  validate_with :ensure_valid_parents

  # Override the parent categoriess writer to ensure that all the parent's children and descendants get's properly recalculated
  def parent=(new_parent)
    # This should happend in one MULTI block
    # @todo all methods that might perform stuff in a MULTI block should accept a block to allow extra bits to get tacked on the end
    super do
      self.parents.each do |parent|
        # Remove ourselves from our parent
        parent.children.delete(self)

        d = self.descendants.append(self)

        # Then, for each parent, remove all descendants that were part of this subtree
        p = parent

        unless p == nil
          p.descendants.delete(d)
          p = p.parent
        end
      end
    end
  end

  # Retrieve all top level Categories
  def self.top_level
    all(:top => true)
  end

  protected

  # Validate to ensure we never end up in a situation where a Category is the ancester of itself
  def ensure_valid_parents
    # @todo we should only do this if the Category has been reparented
    self.parents.each do |parent|
      p = parent
      untill p == nil
        if p == self
          errors.add :parent, "Add helpful error message here"
          return false
        end

        p = p.parent
      end
    end

    true
  end
end
