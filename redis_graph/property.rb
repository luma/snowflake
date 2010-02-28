module RedisGraph
  class Property
    attr_accessor :name, :type, :reader_visibility, :writer_visiblity
    attr_reader :node, :instance_variable_name

    def initialize(node, name, type, options = {})
      @node = node
      @name = name
      @type = type
      
      @reader_visibility = options.delete(:reader_visibility) || 'public'
      @writer_visibility = options.delete(:writer_visibility) || 'public'

      @instance_variable_name = "@#{@name}".freeze
    end
    
    def get(node)
      node.send(@name)
    end
    
    # TODO: typecast?
  end
end # module Test3