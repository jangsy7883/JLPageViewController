Pod::Spec.new do |s|
  s.name         = "JLPageViewController"
  s.version      = "1.13"
  s.summary      = "JLPageViewController"
  s.homepage     = "https://github.com/jangsy7883/JLPageViewController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "hmhv" => "jangsy7883@gmail.com" }
  s.source       = { :git => "https://github.com/jangsy7883/JLPageViewController.git", :tag => s.version }
  s.source_files = 'JLPageViewController/*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
end
