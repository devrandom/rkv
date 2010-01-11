require 'rubygems'
require 'tokyocabinet'

module Rkv
  module Store
    class TokyocabinetAdapter < BaseAdapter
      attr_accessor :recurse

      def self.open(opts)
        self.new(opts)
      end

      def tc_raise
          ecode = @bdb.ecode
          raise "TokyoCabinet - #{@bdb.errmsg(ecode)}"
      end

      def self.new(opts)
        @recurse = opts[:recurse] || :default
        @bdb = TokyoCabinet::BDB::new

        # open the database
        unless @bdb.open(opts[:file], TokyoCabinet::BDB::OWRITER | TokyoCabinet::BDB::OCREAT)
          tc_raise
        end

        TCHash.new(@bdb, @recurse, "")
      end

      class TCHash < BaseAdapter
        def initialize(bdb, recurse, prefix)
          @bdb = bdb
          @recurse = recurse
          @prefix = prefix
        end

        def close
          bdb.close
        end

        def [](key)
          if _recurse?(key)
            key = key[0..-2] if key.end_with?("/")
            new_prefix = "#{@prefix}#{key}/"
            recurse = @recurse
            if Hash === @recurse
              recurse = recurse[key]
            elsif "*" == @recurse
              recurse = nil
            end
            return TCHash.new(@bdb, recurse, new_prefix)
          else
            return _get[key]
          end
        end

        def delete(key)
          full_key = "#{@prefix}#{key}"
          if _recurse?(key)
            full_key = full_key[0..-2] if full_key.end_with?("/")
            cur = TokyoCabinet::BDBCUR.new(@bdb)
            return unless cur.jump(full_key)
            while true
              ckey = cur.key
              return unless ckey.start_with?(full_key)
              cur.out
              return unless cur.next
            end
          else
            @bdb.delete(full_key)
          end
        end

        def []=(key, value)
          # TODO hash value
          full_key = "#{@prefix}#{key}"
          @bdb[full_key] = value
        end

        def inspect
          _get().inspect
        end

        def method_missing(meth, *args, &block)
          _get().send(meth, *args, &block)
        end

        private

        def _recurse?(key)
          return true if key.end_with?("/")
          return false if @recurse.nil?
          return (@recurse == :default || @recurse == "*" || @recurse[key])
        end

        def _get
          cur = TokyoCabinet::BDBCUR.new(@bdb)

          res = {}

          return res unless cur.jump(@prefix)

          while true
            ckey = cur.key
            break unless ckey.start_with?(@prefix)
            value = cur.val
            ckey[@prefix] = ""
            keys = ckey.split("/")
            last_key = keys.pop
            ptr = res
            keys.each do |key|
              ptr[key] ||= {}
              ptr = ptr[key]
            end
            ptr[last_key] = value
            break unless cur.next
          end
          res
        end
      end
    end
  end
end

