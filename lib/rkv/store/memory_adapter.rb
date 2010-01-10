require 'rubygems'

module Rkv
  class Store
    class MemoryAdapter < BaseAdapter
      attr_accessor :recurse

      def self.open(opts)
        self.new(opts)
      end

      def initialize(opts)
        @recurse = opts[:recurse] || :default
        @content = {}
      end

      def [](key)
        if _recurse?(key)
          key = key[0..-2] if key.end_with?("/")
          res = @content[key]
          return res if res
          recurse = @recurse
          if Hash === @recurse
            recurse = recurse[key]
          elsif "*" == @recurse
            recurse = nil
          end
          res = MemoryAdapter.new(:recurse => recurse)
          @content[key] = res
          return res
        else
          return @content[key]
        end
      end

      def delete(key)
        key = key[0..-2] if key.end_with?("/")
        @content.delete(key)
      end

      def []=(key, value)
        # TODO hash value
        @content[key] = value
      end

      def inspect
        @content.inspect
      end

      def method_missing(meth, *args, &block)
        @content.send(meth, *args, &block)
      end

      private

      def _recurse?(key)
        return false if @recurse.nil?
        return (@recurse == :default || @recurse == "*" || @recurse[key] || key.end_with?("/"))
      end
    end
  end
end

