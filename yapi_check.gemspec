require_relative 'lib/yapi_check/version'

Gem::Specification.new do |spec|
  spec.name = 'yapi_check'
  spec.version     = YapiCheck::VERSION
  spec.authors     = ['KlayHU', 'Shootingfly']
  spec.email       = ['hudongrui_klay@163.com', '790174750@qq.com']
  spec.summary       = 'A tool for checking consistency between YAPI API documentation and Rails code.'
  spec.description   = <<-DESC
    YapiCheck is a gem that automates the process of checking the consistency and conformity between YAPI API documentation and Rails code.
    It includes features for validating request and response parameters, supporting batch checks, and more.
  DESC
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.license     = 'MIT'
  spec.homepage    = 'https://github.com/shootingfly/yapi_check'
  spec.metadata['source_code_uri'] = 'https://github.com/shootingfly/yapi_check.git'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 3.0.0'

  spec.require_paths = ['lib']
  spec.add_dependency 'rake'
  spec.add_runtime_dependency 'http', '>= 3.0'
  spec.add_runtime_dependency 'method_source', '~> 1.0'
  spec.add_runtime_dependency 'rails', '>= 5.2'
  spec.add_runtime_dependency 'railties', '>= 4.0'
end
