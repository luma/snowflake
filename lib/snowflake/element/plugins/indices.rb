module Snowflake
  module Element
    module Plugins
      module Indices
        Model.add_extensions self
        
        def self.extended(model)
          model.send(:include, InstanceMethods)
        end

        module InstanceMethods
          protected

          def add_to_indices
            self.class.indices[:all].add( self.key )
          end
          
          def delete_from_indices
            self.class.indices[:all].delete( self.key )
          end
          
          def update_indices( old_key )
#            Snowflake.connection.multi do
              self.class.indices[:all].delete( old_key )
              self.class.indices[:all].add( self.key )
#            end
          end
        end # module InstanceMethods

        def indices
          @indices ||= {
            :all => Index.new( :all, self )
          }
        end
      end # module Indices
    end # module Plugins
  end # module Element
end # module Snowflake

=begin

18. Indices: sorted sets of ids?
	18.1. All Elements: %model_name%::indices::all => %model_keys% so product::indices::all => set of product_keys;
	18.2. Marking attributes as indices: attribute :name, String, :index => true, or attribute :name, String, :index => :unique. both would use the form: %model_name%::indices::%index_name%::%index_values% => %set of model keys%.
	18.3. key indices (for relationships)
	18.4. Number indices. %model_name%::indices::%index_name%::%index_values (integers or floats)% => %set of model keys%.
	18.5. Date/Time indices, cast of unix timestamps when saving %model_name%::indices::%index_name%::%index_values (unix timestamps)% => %set of model keys%.
	
=end