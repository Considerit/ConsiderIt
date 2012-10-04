$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "assessable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "assessable"
  s.version     = Assessable::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary."
  s.description = "TODO: Description."

  s.files       = `git ls-files`.split("\n")
  s.test_files = Dir["test/**/*"]

end
