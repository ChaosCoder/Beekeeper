Pod::Spec.new do |s|

  s.name         = "Beekeeper"
  s.version      = "0.0.1"
  s.summary      = "Anonymous Usage Statistics Tracking for iOS"
  s.description  = <<-DESC
                   Anonymous Usage Statistics Tracking for iOS
                   DESC

  s.homepage     = "https://github.com/ChaosCoder/Beekeeper"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Andreas Ganske" => "a.ganske@chaosspace.de" }

  s.platform     = :ios, "10.0"

  s.source       = { :git => "https://github.com/ChaosCoder/Beekeeper.git", :tag => "#{s.version}" }

  s.source_files  = "Beekeeper", "Beekeeper/**/*.swift"
  s.dependency "JSONAPI"
  s.dependency "CryptoSwift"

end
