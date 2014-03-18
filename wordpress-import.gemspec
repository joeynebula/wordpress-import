# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name        = "wordpress-import"
  s.summary     = "Import WordPress XML dumps into your Ruby on Rails app."
  s.description = "This gem imports a WordPress XML dump into Rails (Page, User, BlogPost, BlogCategory, Tag, BlogComment)"
  s.version     = "0.4.4"
  s.date        = "2014-03-17"

  s.authors     = ['Will Bradley']
  s.email       = 'bradley.will@gmail.com'
  s.homepage    = 'https://github.com/zyphlar/wordpress-import'

  s.add_dependency 'bundler', '~> 1.0'
  s.add_dependency 'nokogiri', '~> 1.6.0'
  s.add_dependency 'shortcode', '~> 0.1.1'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'database_cleaner'

  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
end
