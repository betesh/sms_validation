# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sms_validation/version'

Gem::Specification.new do |spec|
  spec.name          = "sms_validation"
  spec.version       = SmsValidation::VERSION
  spec.authors       = ["Isaac Betesh"]
  spec.email         = ["iybetesh@gmail.com"]
  spec.description   = "Validate the phone number and content of an SMS Message.  This gem does not send SMS messages.  It just makes sure the arguments are valid."
  spec.summary       = `cat README.md`
  spec.homepage      = "https://github.com/betesh/sms_validation/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
