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
  pod 'AliyunOSSiOS'
  # EasyDebug - 使用本地路径
  pod 'easydebug'
  # pod 'easydebug', :path => './EasyDebug'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end

  # QMUIKit: iOS 部分版本下 `visualProvider.contentView` 不可 KVC，可能触发
  # NSUnknownKeyException: key contentView。这里每次 pod install 后自动打补丁。
  qmui_navbar_path = File.join(installer.sandbox.root.to_s, 'QMUIKit', 'QMUIKit', 'UIKitExtensions', 'UINavigationBar+QMUI.m')
  if File.exist?(qmui_navbar_path)
    system('chmod', 'u+w', qmui_navbar_path)
    content = File.read(qmui_navbar_path)
    # 仅在原始实现存在且尚未打过补丁时替换，保持幂等
    if content.include?('return [self valueForKeyPath:@"visualProvider.contentView"];') && !content.include?('@try {')
      content = content.gsub(
        /- \(UIView \*\)qmui_contentView\s*\{\s*return \[self valueForKeyPath:@\"visualProvider\.contentView\"\];\s*\}/m,
        %Q(- (UIView *)qmui_contentView {\n    // Some iOS versions no longer expose `visualProvider.contentView` via KVC.\n    // Use a safe fallback to avoid `NSUnknownKeyException` crashes.\n    @try {\n        return [self valueForKeyPath:@"visualProvider.contentView"];\n    } @catch (NSException *exception) {\n        return nil;\n    }\n})
      )
      File.write(qmui_navbar_path, content)
      puts "[post_install] Patched QMUIKit UINavigationBar+QMUI.m (safe KVC)"
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
