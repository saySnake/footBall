# Uncomment the next line to define a global platform for your project
 platform :ios, '15.0'

target 'footBall' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for footBall
  pod 'AFNetworking'
  pod 'MJExtension'
  pod 'Masonry'
  pod 'MBProgressHUD'
  pod 'MJRefresh'
  pod 'SDWebImage'
  pod 'YYCategories'
  pod 'YYModel'
  pod 'IQKeyboardManager'
  pod 'DoraemonKit'
  pod 'libpag'
  pod 'SocketRocket'
  pod 'QMUIKit'
  # EasyDebug - 使用本地路径
  # pod 'easydebug', :path => './EasyDebug'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end

  afn_dir = File.join(installer.sandbox.root.to_s, 'AFNetworking', 'AFNetworking')
  if Dir.exist?(afn_dir)
    Dir.glob(File.join(afn_dir, '*.{h,m}')).each do |path|
      next unless File.file?(path)
      system('chmod', 'u+w', path)
      contents = File.read(path)
      patched = contents.gsub(/^#import <netinet6\/in6\.h>\s*\n/, '')
      File.write(path, patched) if patched != contents
    end
  end
end
