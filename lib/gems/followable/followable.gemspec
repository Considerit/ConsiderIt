$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "followable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "followable"
  s.version     = Followable::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of ActsAsFollowable."
  s.description = "TODO: Description of ActsAsFollowable."

  s.files       = `git ls-files`.split("\n")
  s.test_files = Dir["test/**/*"]

end
