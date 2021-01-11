Pod::Spec.new do |s|

  s.name         = "Beekeeper"
  s.version      = "0.6.0"
  s.summary      = "Anonymous Usage Statistics Tracking for iOS"
  s.description  = <<-DESC
  Beekeeper allows you to get insights about your most important KPIs like daily, weekly or monthy active users, funnels and events and much more without sacrifying the users privacy.
                   DESC

  s.homepage     = "https://github.com/ChaosCoder/Beekeeper"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Andreas Ganske" => "a.ganske@chaosspace.de" }

  s.platform     = :ios, "10.0"
  s.swift_version= "5.0"
  s.source       = { :git => "https://github.com/ChaosCoder/Beekeeper.git", :tag => "#{s.version}" }

  s.source_files  = "Sources/Beekeeper", "Sources/Beekeeper/**/*.swift"
  s.dependency "ConvAPI"
  s.dependency "CryptoSwift"
  s.dependency "PromiseKit"

end
