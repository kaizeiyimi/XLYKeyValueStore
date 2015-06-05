Pod::Spec.new do |s|
  s.name         = "XLYKeyValueStore"
  s.version      = "1.0.0"
  s.summary      = "A simple key-value store support in-memory and persistance."
  
  s.description  = <<-DESC
                  simple key-value store like NSUserDefault's set and get API. Support 
                  in-memory and persistance.
                   DESC

  s.homepage     = "https://github.com/kaizeiyimi/XLYKeyValueStore"
  
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "kaizei" => "kaizeiyimi@126.com" }

  s.platform     = :ios, "5.0"

  s.source       = { :git => "https://github.com/kaizeiyimi/XLYKeyValueStore.git", :tag => 'v1.0.0' }
  s.source_files  = "codes/**/*.{h,m}"
  s.frameworks = 'CoreData'

  s.requires_arc = true

end
