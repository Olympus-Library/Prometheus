
Pod::Spec.new do |s|
  s.name          = "Prometheus"
  s.version       = "1.0.0"
  s.summary       = "Easy Caching for Everyone"
  s.description = <<-DESC
                    Prometheus is a fast, concurrent caching solution for iOS and OS X. 
                    Prometheus provides implementations for an in-memory cache, on-disk 
                    cache, and a composite cache that is both in memory and on disk. 
                    Prometheus caches automatically handle eviction based on their size
                    capacity as well as per-item expiration times. 

                    Prometheus is also designed for customization and allows you to provide 
                    your own implementation of the in-memory or on-disk cache if the default
                    implementations do not meet your needs. 
                  DESC
  s.homepage      = "https://github.com/Olympus-Library/Prometheus"
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = { "Comyar Zaheri" => "" }
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.9"
  s.source        = { :git => "https://github.com/Olympus-Library/Prometheus.git", :tag => s.version.to_s }
  s.source_files  = "Prometheus/*.{h,m}", "Prometheus/**/*.{h,m}"
  s.module_name   = "Prometheus"
  s.requires_arc  = true
  s.dependency    = 'Chronos'
end
