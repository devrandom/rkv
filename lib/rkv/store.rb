module Rkv
  class Store
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
      str.to_s.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
    end
  end
end
