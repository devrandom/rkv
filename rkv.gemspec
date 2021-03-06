# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rkv}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Miron Cuperman"]
  s.date = %q{2010-01-11}
  s.description = %q{Ruby Key Value - an adapter on top of various key-value stores, supporting Cassandra and others}
  s.email = %q{c1.github@niftybox.net}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/rkv.rb",
     "lib/rkv/rkv.rb",
     "lib/rkv/store/cassandra_adapter.rb",
     "lib/rkv/store/memory_adapter.rb",
     "lib/rkv/store/tokyocabinet_adapter.rb",
     "rkv.gemspec",
     "spec/integration/stores_spec.rb",
     "spec/lib/rkv_store_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/devrandom/rkv}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Ruby Key Value - an adapter on top of various key-value stores}
  s.test_files = [
    "spec/lib/rkv_store_spec.rb",
     "spec/spec_helper.rb",
     "spec/integration/stores_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

