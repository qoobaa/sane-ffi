# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sane/version"

Gem::Specification.new do |s|
  s.name        = "sane-ffi"
  s.version     = Sane::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jakub Kuźma"]
  s.email       = ["qoobaa@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{SANE bindings}
  s.description = %q{Scanner Access now Easier}

  s.add_dependency "ffi"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
