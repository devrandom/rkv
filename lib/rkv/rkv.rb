module Rkv
  module Store
    class BaseAdapter
      def batch
        # default batch just passes control to block
        yield
      end
      def ==(other)
        my_keys = keys.sort
        o_keys = keys.sort
        return false unless my_keys == o_keys
        my_keys.each do |key|
          puts "#{key}" unless self[key] == other[key]
          return false unless self[key] == other[key]
        end
        return true
      end
    end
  end

  @@backends = {}
  def self.open(backend_name, opts)
    get_backend(backend_name).open(opts)
  end

  private

  def self.get_backend(backend_name)
    backend = @@backends[backend_name]
    return backend if backend
    return load_backend(backend_name)
  end

  def self.load_backend(backend_name)
    my_require "rkv/store/#{backend_name}_adapter"
    backend = Rkv::Store.const_get(camelize(backend_name) + "Adapter")
    @@backends[backend_name] = backend
    return backend
  end

  def self.my_require(path)
    require path
  end

  def self.camelize(str)
    str.to_s.split(/[^a-z0-9]/i).map{|word| word.capitalize}.join
  end
end
