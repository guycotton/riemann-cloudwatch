require 'rake'

Gem::Specification.new do |s|
  
  s.name = 'riemann-airtext'
  s.version = '0.1'
  s.author = 'Guy Cotton'
  s.email = 'guy@aitext.co.uk'
  s.homepage = 'https://bitbucket.org/airtext/riemann-airtext'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Utilities which submit airtext core system events to Riemann.'
  s.description = 'Utilities which submit airtext core system events to Riemann.'
  s.license = 'proprietary'

  s.add_dependency 'riemann-tools', '>= 0.2.2'
  s.add_dependency 'rest-client', '>= 1.7.2'

  s.files = FileList['lib/**/*', 'bin/*'].to_a
  s.executables |= Dir.entries('bin/')
  s.require_path = 'lib'
  s.has_rdoc = false

  s.required_ruby_version = '>= 1.8.7'
end
