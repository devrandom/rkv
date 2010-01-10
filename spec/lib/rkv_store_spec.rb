require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Rkv
  class Store
    class TestAdapter
      def self.open(opts)
        return self.new
      end
    end
  end
end

describe Rkv::Store do
  before :each do
    @opts = {:servers => ['dummy1:8888']}
    @store = Rkv::Store::TestAdapter.new
  end

  it "should load backend" do
    Rkv::Store.should_receive(:my_require).with("rkv/store/test_adapter").and_return(true)
    Rkv::Store::TestAdapter.should_receive(:open).with(@opts).and_return(@store)
    store = Rkv::Store.open(:test, @opts)
    store.should == @store
  end
end

