module Snowflake
  module IdentityMap
    def self.[](id)
      return identity_map[id] if identity_map.include?(id)

      node = load(id)
      identity_map[id] = node

      node
    end

    def self.[]=(id, node)
      return false unless save(id, node) == true

      identity_map[id] = node
      true
    end

    private

    def self.identity_map
      @identity_map ||= {}
    end

    def self.load(id)
      raw = Snowflake.connection[id]
      return nil if raw == nil

      JSON.parse(raw)
    end

    def self.save(id, node)
      raw = JSON.dump(node)
      Snowflake.connection[id] = raw
    end
  end # module IdentityMap
end # module Snowflake