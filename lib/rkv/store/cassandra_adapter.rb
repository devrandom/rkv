require 'rubygems'
require 'cassandra'

module Rkv
  class Store
    class CassandraAdapter

      attr_accessor :consistency

      attr_accessor :opts

      def self.open(opts)
        self.new(opts)
      end

      def initialize(opts)
        @format = opts[:format] || :pass
        @consistency = opts[:consistency] || :safe
        @backend = Cassandra.new(opts[:keyspace], opts[:servers])
        @columns = {}
        @opts = {
          :consistency => (consistency == :safe) ? Cassandra::Consistency::QUORUM : Cassandra::Consistency::ONE
        }
      end

      def [](key)
        return @columns[key] if @columns[key]
        @columns[key] = ColumnAdapter.new(self, key)
        return @columns[key]
      end

      def []=(key, value)
        raise ArgumentError.new("this store does not allow storing at top level - subscript me twice")
      end

      def delete_this(key)
        # this does nothing, because nothing is stored at this level
      end


      def backend
        @backend
      end

      class ColumnAdapter
        attr_reader :store
        attr_reader :id

        def initialize(store, column_key)
          @store = store
          @id = column_key.to_sym
        end

        def [](key)
          RowAdapter.new(self, key, nil)
        end

        def delete_this(key)
          # this does nothing, because nothing is stored at this level
        end

        def delete(key)
          @store.backend.remove(@id, key, @store.opts)
        end

        def []=(key, value)
          raise ArgumentError.new("this store does not allow storing at second level - subscript me once")
        end
      end


      class RowAdapter
        def initialize(column, id, prefix)
          @column = column
          @store = column.store
          @prefix = prefix
          @id = id
        end

        def [](key)
          RowAdapter.new(@column, @id, (@prefix || "") + key + "/")
        end

        def []=(key, val)
          key = @prefix + key if @prefix
          @store.backend.insert(@column.id, @id, { key => val } , @store.opts)
        end

        def delete_this(key)
          key = @prefix + key if @prefix
          @store.backend.remove(@column.id, @id, key, @store.opts)
        end

        def delete(key)
          key = @prefix + key if @prefix
          key_prefix = key + "/"
          ohash = @store.backend.get(@column.id, @id, @store.opts)
          ohash.each_key do |okey|
            next unless okey == key || okey.start_with?(key_prefix)
            @store.backend.remove(@column.id, @id, okey, @store.opts)
          end
        end


        def method_missing(meth, *args, &block)
          _get.send(meth, *args, &block)
        end

        def inspect
          _get.inspect
        end

        def to_s
          _get.to_s
        end

        private

        def _get
          ohash = @store.backend.get(@column.id, @id, @store.opts)
          res = {}
          ohash.each_pair do |okey, value|
            if @prefix
              next unless okey.start_with?(@prefix)
              okey[@prefix] = ""
            end
            keys = okey.split("/")
            last_key = keys.pop
            ptr = res
            keys.each do |key|
              ptr[key] ||= {}
              ptr = ptr[key]
            end
            ptr[last_key] = value
          end
          res
        end
      end
    end
  end
end

