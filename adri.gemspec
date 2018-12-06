Gem::Specification.new do |gem|
  gem.name = 'adri'
  gem.version = '0.0.1'
  gem.author = 'Angelos Orfanakos'
  gem.email = 'me@agorf.gr'
  gem.homepage = 'https://github.com/agorf/adri'
  gem.summary = 'Organize photos by date and location in a directory structure'
  gem.license = 'MIT'

  gem.files = Dir['bin/*', '*.md', 'LICENSE.txt']
  gem.executables = Dir['bin/*'].map { |f| File.basename(f) }

  gem.required_ruby_version = '>= 2.3.0'

  gem.add_dependency 'exif', '~> 2.2', '>= 2.2.0'
  gem.add_dependency 'geocoder', '~> 1.5', '>= 1.5.0'
  gem.add_dependency 'slop', '~> 4.6', '>= 4.6.2'

  gem.add_development_dependency 'dotenv', '~> 2.5', '>= 2.5.0'
end
