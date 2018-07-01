Pod::Spec.new do |s|

  s.name         = "EPUBKit"
  s.version      = "0.3.0"
  s.summary      = "📚 A simple swift library for parsing EPUB documents."
  s.description  = <<-DESC
  EPUBKit is a lightweight library designed for parsing EPUB documents.
                   DESC
  s.homepage     = "https://github.com/witekbobrowski/EPUBKit"
  s.license      = "MIT"
  s.author             = { "witekbobrowski" => "witek@bobrowski.com.pl" }
  s.social_media_url   = "https://github.com/witekbobrowski"
  s.swift_version = '4.1'
  s.source       = { :git => "https://github.com/witekbobrowski/EPUBKit.git", :tag => "0.3.0" }
  s.source_files = [
      'EPUBKit/*.{h,swift}',
      'EPUBKit/**/*.swift',
    ]

  spec.ios.deployment_target  = '10.0'
  spec.osx.deployment_target  = '10.10'
  spec.tvos.deployment_target = '9.0'
  s.libraries  = "z"  
  s.dependency 'Zip'
  s.dependency 'AEXML'

end
