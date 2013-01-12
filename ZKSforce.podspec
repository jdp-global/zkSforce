Pod::Spec.new do |s|
  s.name     = 'ZKSforce'
  s.version  = '26.0'
  s.license  = 'MIT'
  s.summary  = 'A Cocoa library for calling the Salesforce.com SOAP APIs.'
  s.homepage = 'https://github.com/superfell/zkSforce'
  s.author   = { 'Simon Fell' => 'fellforce@gmail.com' }
  s.source   = { :git => 'https://github.com/jdp-global/zkSforce.git', :commit=>'7c0c7aeff2fa840487d8fbbd51a303d574c07e52' }
  s.source_files = 'zkSforce'
  s.library = 'xml2'
  s.osx.dependency  'XMLReader'
  s.ios.dependency    'XMLReader'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
end