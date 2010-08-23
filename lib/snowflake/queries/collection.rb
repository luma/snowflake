module Snowflake
  module Queries
    class Collection
    	attr_reader :element_klass, :operand

    	def initialize( element_klass, operand )
    		@element_klass, @operand = element_klass, operand
    	end

      def all
        # @all ||= @element_klass.get_many( keys )
        @all ||= begin          
          # We need this to make as the keys must be loaded outside the multi-block
          tmp_keys = keys
          
          hashes = tmp_keys.collect do |key|
            Snowflake.connection.hgetall( key )
          end

          # hashes = Snowflake.connection.multi do |con|
          #   tmp_keys.each do |key|
          #     puts @element_klass.key_for(key).inspect
          #     debugger
          #     con.hgetall( @element_klass.key_for(key) )
          #   end
          # end
          # 
          # debugger

          # @todo error check
          i = 0
          hashes.collect do |attributes|
            unless attributes == nil
              # @todo Deal with extended properties that aren't part of the hash: Maybe lazy load them?
              
              node = initialize_element_from_key_and_attributes( keys[i], attributes )

              i += 1
              node
            else
              i += 1
              nil
            end        
          end.compact
        end
      end

    	def each
    		all.each do |element|
    			yield element
    		end
    	end
    	
    	def first
    	  if elements_loaded?
      	  all.first
  	    elsif !empty?
  	      get_element_from_key_and_attributes( keys.first )
	      else
	        nil
	      end
  	  end
  	  
  	  def last
    	  if elements_loaded?
      	  all.last
  	    elsif !empty?
  	      get_element_from_key_and_attributes( keys.last )
	      else
	        nil
	      end
	    end
	    
	    def random
    	  Collection.new( @element_klass, Operations::RandomOperation.new( @operand ) ).first
      end

      def length
        keys.length
      end

      def empty?
        keys.empty?
      end

      def include?( key )
        matcher = Regexp.new("([a-zA-Z][a-zA-Z0-9]*)\:(#{key})")

        keys.each do |full_key|
          if ( full_key =~ matcher ) == 0
            return true
          end
        end

        false
      end

      # Only return an element if it is actually contained in this collection
      def get( key )
        matcher = Regexp.new("([a-zA-Z][a-zA-Z0-9]*)\:(#{key})")

        keys.each do |full_key|
          if ( full_key =~ matcher ) == 0
            return get_element_from_key_and_attributes( key )
          end
        end

        nil
      end

    	# return a new collection that consists of this collection and the other one
    	def &(options)
        filters = Operand.from_options( @element_klass, options )
    		Collection.new( @element_klass, Operations::AndOperation.new( @operand, *filters ) )
    	end
    	alias :and :&

    	# return a new collection that consists of this collection or the other one	
    	def |(options)
  	    filters = Operand.from_options( @element_klass, options )
  	    
  	    inner_op =  if filters.length > 1
              	      Operations::AndOperation.new( *filters )
            	      else
            	        filters.first
                    end

    		Collection.new( @element_klass, Operations::OrOperation.new( @operand, inner_op ) )
    	end
    	alias :or :|

    	def reload
    	  @keys = nil
    	  @all = nil
    	  @command_set = nil
      end

    	def keys
        # @todo this is a little clumsy
    		if @keys == nil
    		  @keys = command_set.execute( @operand.results_size ) || []
    		  
          if Snowflake.log_level == :debug
            explain
          end
  		  end

  		  @keys
    	end 

    	def explain
    	  lines = [
    	    "\nEXPLAIN:",
    	    @operand.explain(1),
    	    "\nRESULTS STATISTICS:"
  	    ]

    	  ['length', 'keys'].each do |attr|
    	    tab_stops = " " * (20 - attr.length)
    	    lines << "#{tab_stops}#{attr}: #{send(attr).inspect}"
  	    end

        lines << "\nCOMMANDS STATISTICS:"
        command_set.statistics.each do |statistic, value|
    	    tab_stops = " " * (20 - statistic.length)
    	    lines << "#{tab_stops}#{statistic}: #{value.inspect}"
        end

        Snowflake.logger.debug lines.join("\n")
  	    true
  	  end

    	private

    	def command_set
    	  @command_set ||= @operand.eval(nil, true)
  	  end

    	def keys_loaded?
    	  @keys != nil
  	  end

      def elements_loaded?
        @all != nil
      end
      
      def element_for_key( full_key )
        element_klass, key = Keys.parts_from_key( full_key )

        # We use #allocate, rather than #new, as we use #new to mean a Element that has not yet been
        # saved in the DB.        
        node = element_klass.constantize.allocate
        node.update_key_with_renaming( key )

        node
      end
      
      def initialize_element_from_key_and_attributes( full_key, attributes )
        node = element_for_key( full_key )
        node.attributes = attributes

        node.reset!
        node
      end

      def get_element_from_key_and_attributes( full_key )
        node_attributes = Snowflake.connection.hgetall( full_key )
        return nil if node_attributes.empty?

        element_klass, key = Keys.parts_from_key( full_key )

        # @todo Deal with extended properties that aren't part of the hash: Maybe lazy load them?

        # We use #allocate, rather than #new, as we use #new to mean a Element that has not yet been
        # saved in the DB.
        node = element_klass.constantize.allocate
        node.update_key_with_renaming( key )
        node.attributes = node_attributes

        node.reset!
        node
      end

      # def keys
      #   @keys ||= ( @operand.eval(nil, true).execute( @operand.results_size ) || [] )
      # end
    end
  end # module Queries
end # module Snowflake