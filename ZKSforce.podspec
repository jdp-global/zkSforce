Pod::Spec.new do |s|
  s.name     = 'ZKSforce'
  s.version  = '30.0.0'
  s.license  = 'MIT'
  s.summary  = 'A Cocoa library for calling the Salesforce.com SOAP APIs.'
  s.homepage = 'https://github.com/superfell/zkSforce'
  s.author   = { 'Simon Fell' => 'fellforce@gmail.com' }
  s.source   = { :git => 'https://github.com/jdp-global/zkSforce.git', :commit=>'42cafc74270aceaffb8da323b638537e0fb85990' }
  s.source_files = 'zkSforce'
  s.library = 'xml2'
  s.osx.dependency  'XMLReader'
  s.ios.dependency    'XMLReader'
  s.osx.framework = 'Security'
  s.requires_arc = false
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.ios.platform = :ios, "6.0"
  s.osx.platform = :osx, "10.7"
end
