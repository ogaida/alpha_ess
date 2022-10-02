Gem::Specification.new do |spec|
  spec.name = 'alpha_ess'
  spec.version = '1.0'
  spec.date = '2022-10-02'
  spec.summary = "Alpha Ess API Calls"
  spec.description = "a Ruby class for Alpha-Ess-API-Calls"
  spec.authors = ["Oliver Gaida"]
  spec.email = 'ogaida@t-online.de'
  spec.files = `git ls-files`.split($/)
  spec.homepage = 'https://github.com/ogaida/alpha_ess'
  #spec.executables = %w(rusdc)
  spec.add_runtime_dependency 'httparty'
  #spec.add_runtime_dependency 'json', '~> 2.1', '>= 2.1.0'
  spec.license = 'MIT'
end
