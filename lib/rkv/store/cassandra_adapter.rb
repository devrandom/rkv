require 'rubygems'
require 'cassandra'

module Rkv
  class Store
    class CassandraAdapter

      attr_accessor :consistency

      attr_accessor :opts

      attr_accessor :recurse

      def self.open(opts)
        self.new(opts)
      end

      def initialize(opts)
        @format = opts[:format] || :pass
        @consistency = opts[:consistency] || :safe
        @backend = Cassandra.new(opts[:keyspace], opts[:servers])
        @columns = {}
        @recurse = opts[:recurse] || :default
        @opts = {
          :consistency => (consistency == :safe) ? Cassandra::Consistency::QUORUM : Cassandra::Consistency::ONE
        }
      end

      def [](key)
        _must_recurse(key)
        return @columns[key] if @columns[key]
        @columns[key] = ColumnAdapter.new(self, key)
        return @columns[key]
      end

      def []=(key, value)
        _must_recurse(key)
        raise ArgumentError.new("this store does not allow storing at top level - subscript me")
      end

      private

      def _must_recurse(key)
        raise ArgumentError.new("at this depth - key must end with slash, or :recurse option must be specified") unless _recurse?(key)
      end

      def _recurse?(key)
        return false if @recurse.nil?
        return (@recurse == :default || @recurse == "*" || @recurse[key] || key.end_with?("/"))
      end

      public

      def backend
        @backend
      end

      class ColumnAdapter
        attr_reader :store

        attr_reader :id

        attr_reader :recurse

        def initialize(store, column_key)
          @store = store
          @id = column_key.to_sym
          @recurse = @store.recurse
          if Hash === @recurse
            @recurse = @recurse[column_key]
          elsif "*" == @recurse
            @recurse = {}
          end
        end

        def [](key)
          _must_recurse(key)
          RowAdapter.new(self, key, nil)
        end

        def delete(key)
          if _recurse?(key)
            @store.backend.remove(@id, key, @store.opts)
          end
        end

        def []=(key, value)
          _must_recurse(key)
          # TODO allow storing of hashes here
        end

        private

        def _must_recurse(key)
          raise ArgumentError.new("at this depth - key must end with slash, or :recurse option must be specified") unless _recurse?(key)
        end

        def _recurse?(key)
          return false if @recurse.nil?
          return (@recurse == :default || @recurse == "*" || @recurse[key] || key.end_with?("/"))
        end
      end


      class RowAdapter
        def initialize(column, id, prefix)
          @column = column
          @store = column.store
          @prefix = prefix
          @id = id

          @recurse = @column.recurse
          if Hash === @recurse
            @recurse = @recurse[id]
          elsif "*" == @recurse
            @recurse = {}
          end
        end

        def [](key)
          if _recurse?(key)
            RowAdapter.new(@column, @id, (@prefix || "") + key)
          else
            _get[key]
          end
        end

        def []=(key, val)
          key = @prefix + key if @prefix
          # TODO recurse
          @store.backend.insert(@column.id, @id, { key => val } , @store.opts)
        end

        def delete(key)
          if _recurse?(key)
            key = @prefix + key if @prefix
            key = key + "/" unless key.end_with?("/")
            ohash = @store.backend.get(@column.id, @id, @store.opts)
            ohash.each_key do |okey|
              next unless okey == key || okey.start_with?(key)
              @store.backend.remove(@column.id, @id, okey, @store.opts)
            end
          else
            key = @prefix + key if @prefix
            @store.backend.remove(@column.id, @id, key, @store.opts)
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
        def _recurse?(key)
          return false if @recurse.nil?
          return (@recurse == :default || @recurse == "*" || @recurse[key] || key.end_with?("/"))
        end

        def _get
          # TODO cache
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

