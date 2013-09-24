Gem::Specification.new do |s|
  s.name          = 'jemc-reporter'
  s.version       = '0.1.5'
  s.date          = '2013-09-23'
  s.summary       = "jemc-reporter"
  s.description   = "A custom minitest reporter made to my"\
                    " personal aesthetic specifications."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/jemc-reporter/'
  s.licenses      = "Copyright (c) Joe McIlvain. All rights reserved "
  
  s.add_dependency('minitest', '~> 4.3.2')
  s.add_dependency('minitest-reporters')
  s.add_dependency('ansi')
  
  s.add_development_dependency('rake')
end