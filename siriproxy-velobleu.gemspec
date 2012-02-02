# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "siriproxy-velobleu"
  s.version     = "0.0.1" 
  s.authors     = ["David LAURENT"]
  s.email       = ["Twitter @dragouf"]
  s.homepage    = ""
  s.summary     = %q{An Example Siri Proxy Plugin}
  s.description = %q{Devrait permettre d'obtenir des informations sur le velo bleu'. }

  s.rubyforge_project = "siriproxy-eyelp"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency "json"
  #s.add_runtime_dependency "uri"
end
