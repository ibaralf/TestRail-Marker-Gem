
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trail_marker/version"

Gem::Specification.new do |spec|
  spec.name          = "trail_marker"
  spec.version       = TrailMarker::VERSION
  spec.authors       = ["Ibarra Alfonso"]
  spec.email         = ["ibarra.alfonso@gmail.com"]

  spec.summary       = %q{Marks results on TestRails parsing XML results files.}
  spec.description   = %q{Executable tools pakcaged as a ruby gem that will parse RSPEC results files in XML and mark results in TestRails.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  #spec.files         = `git ls-files -z`.split("\x0").reject do |f|
  #  f.match(%r{^(test|spec|features)/})
  #end

  spec.files = Dir.glob("{bin,lib}/**/*") + %w(README.md)

  spec.bindir        = "exe"
  spec.executables = ['testrail_marker']
  spec.require_paths = ["lib"]

  spec.add_dependency 'os', '~> 0.9'
  spec.add_dependency 'nokogiri', '~> 1.8'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
