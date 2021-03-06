Pod::Spec.new do |s|
  s.name     = 'ZKSforce'
  s.version  = '30.0.0'
  s.license  = 'MIT'
  s.summary  = 'A Cocoa library for calling the Salesforce.com SOAP APIs.'
  s.homepage = 'https://github.com/superfell/zkSforce'
  s.author   = { 'Simon Fell' => 'fellforce@gmail.com' }
  s.source   = { :git => 'https://github.com/jdp-global/zkSforce.git', :commit=>'a8461f176333e208c2d4b462b8f84ac3cfe61d1c' }
  s.source_files = 'zkSforce'
  s.library = 'xml2'
  s.osx.dependency  'XMLDictionary'
  s.ios.dependency    'XMLDictionary'
  s.osx.framework = 'Security'
  s.requires_arc = false
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.ios.platform = :ios, "6.0"
  s.osx.platform = :osx, "10.7"
end
