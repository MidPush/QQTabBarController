
Pod::Spec.new do |spec|

  spec.name         = "QQTabBarKit"
  spec.version      = "1.0.2"
  spec.summary      = "QQTabBarController."
  spec.homepage     = "https://github.com/MidPush/QQTabBarController"
  spec.license      = { :type => "MIT" }
  spec.author       = { "xz" => "497569855@qq.com" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/MidPush/QQTabBarController.git", :tag => spec.version }
  spec.source_files  = "QQTabBarController/**/*.{h,m}"

end