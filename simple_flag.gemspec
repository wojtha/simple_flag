# frozen_string_literal: true

require_relative 'lib/simple_flag/version'

Gem::Specification.new do |spec|
  spec.name          = 'simple_flag'
  spec.authors       = ['Vojtěch Kusý']
  spec.email         = ['wojtha@gmail.com']
  spec.license       = 'MIT'
  spec.version       = SimpleFlag::VERSION

  spec.summary       = 'Simple feature flags'
  spec.description   = 'Simple but powerful feature flag implementation in 90 LOC.'
  spec.homepage      = 'https://github.com/wojtha/simple_flag'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['changelog_uri']     = 'https://github.com/wojtha/simple_flag/blob/master/CHANGELOG.md'
  spec.metadata['source_code_uri']   = 'https://github.com/wojtha/simple_flag'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/wojtha/simple_flag/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 2.7.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = []
  spec.require_paths = ['lib']
end
