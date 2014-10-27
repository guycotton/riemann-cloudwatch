require 'rake'

Gem::Specification.new do |s|
  
  s.name = 'riemann-cloudwatch'
  s.version = '0.1'
  s.author = 'Guy Cotton'
  s.email = 'guycotton@gmail.com'
  s.homepage = 'https://github.com/guycotton/riemann-cloudwatch'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Riemann cloud watch tools'
  s.description = 'Utilities which submit AWS cloudwatch data points to Riemann.'
  s.license = 'MIT'

  s.add_dependency 'riemann-tools', '>= 0.2.2'
  s.add_dependency 'fog', '>= 1.24.0'

  s.files = FileList['lib/**/*', 'bin/*'].to_a
  s.executables |= Dir.entries('bin/')
  s.require_path = 'lib'
  s.has_rdoc = false

  s.required_ruby_version = '>= 1.9.1'
end
