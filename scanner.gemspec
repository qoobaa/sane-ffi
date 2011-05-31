# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "scanner/version"

Gem::Specification.new do |s|
  s.name        = "scanner"
  s.version     = Scanner::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jakub Kuźma"]
  s.email       = ["qoobaa@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{SANE bindings}
  s.description = %q{Scanner Access now Easier}

  # s.rubyforge_project = "scanner"

  s.add_dependency "ffi"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
