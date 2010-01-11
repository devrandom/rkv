require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def test_store(store)
  userid = "__test1"
  users = store["Users"]
  users.delete(userid)
  user = users[userid]
  user.batch do
    user["x1"] = "3"
    user["x2"] = "4"
  end
  users[userid].should == {"x1" => "3", "x2" => "4"}
  test = []
  user.each_pair { |k,v| test << [k,v] }
  test.should == [["x1", "3"], ["x2", "4"]]
  user.delete("x1")
  user["abc/"]["def"] = "xyz"
  user["abc/"]["lmn"] = "xyz"

  users[userid].should == {"abc"=>{"lmn"=>"xyz", "def"=>"xyz"}, "x2"=>"4"}
  users[userid]["abc/"].should == {"lmn"=>"xyz", "def"=>"xyz"}
  user["abc/"].delete("def")
  users[userid].should == {"abc"=>{"lmn"=>"xyz"}, "x2"=>"4"}
  user.delete("abc/")
  users[userid].should == {"x2"=>"4"}
  users.delete(userid)
  users[userid].should == {}
end

def open_store(store_name)
  case store_name
  when :memory then
    store = Rkv.open(:memory, :recurse => {"Users" => "*"})
  when :cassandra then
    store = Rkv.open(:cassandra, :servers => "127.0.0.1:9160", :keyspace => 'Twitter', :recurse => {"Users" => "*"})
  else
    raise "Unknown store #{store_name}"
  end
end

describe Rkv do
  [:memory, :cassandra, :pstore].each do |store_name|
    it "should work with #{store_name}" do
      store = open_store(store_name) rescue nil
      if store
        test_store(store)
      else
        fail "failed to load store - is it installed?"
      end
    end
  end
end
