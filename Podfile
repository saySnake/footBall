# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'footBall' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # 网络请求库
  pod 'AFNetworking', '~> 4.0'
  
  # JSON 模型转换
  pod 'MJExtension', '~> 3.4'
  
  # UI 组件
  pod 'Masonry', '~> 1.1'
  pod 'MBProgressHUD', '~> 1.2'
  pod 'MJRefresh', '~> 3.7.6'
  pod 'QMUIKit'
  pod 'SDWebImage', '~> 5.18'
  
  # 动画库
  pod 'libpag', '4.2.41'
  
  # WebSocket
  pod 'SocketRocket', '~> 0.6.0'
  
  # 工具类
  pod 'YYCategories', '~> 1.0'
  pod 'IQKeyboardManager', '~> 6.5'
  # 调试工具
  pod 'DoraemonKit', '~> 3.0'
  # EasyDebug - 使用本地路径
  pod 'easydebug', :path => './EasyDebug'


end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
