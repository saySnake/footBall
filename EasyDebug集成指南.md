# EasyDebug 集成到 footBall 项目的步骤指南

## 方式一：通过 CocoaPods 集成（推荐）

### 步骤 1：修改 Podfile

在 `Podfile` 中添加 easydebug，使用本地路径：

```ruby
target 'footBall' do
  # ... 其他依赖 ...
  
  # 调试工具
  pod 'DoraemonKit', '~> 3.0'
  
  # EasyDebug - 使用本地路径
  pod 'easydebug', :path => './EasyDebug'
end
```

### 步骤 2：安装依赖

在终端运行：

```bash
cd /Users/zhangwei/Desktop/footBall
pod install
```

### 步骤 3：在代码中导入和使用

#### 3.1 在 AppDelegate.m 中导入头文件

在 `AppDelegate.m` 文件顶部添加：

```objc
#ifdef DEBUG
#import <easydebug/EasyDebug.h>
#endif
```

#### 3.2 在 AppDelegate 中初始化 EasyDebug

在 `application:didFinishLaunchingWithOptions:` 方法中添加：

```objc
#ifdef DEBUG
    // 初始化 EasyDebug
    [EasyDebug shared].isOn = YES;
    // 配置模块：网络监控 + 性能监控
    EasyDebugModule modules = EasyDebugNetMonitor | EasyDebugPerformance;
    [EasyDebug config:modules];
    NSLog(@"✅ EasyDebug 已初始化");
#endif
```

#### 3.3 在 SceneDelegate.m 中导入（可选）

如果需要在使用 SceneDelegate 的地方使用 EasyDebug，可以添加：

```objc
#ifdef DEBUG
#import <easydebug/EasyDebug.h>
#endif
```

---

## 方式二：手动添加到 Xcode Target

### 步骤 1：在 Xcode 中添加文件引用

1. 打开 Xcode 项目（使用 `footBall.xcworkspace`）
2. 在项目导航器中，右键点击 `footBall` 文件夹
3. 选择 "Add Files to 'footBall'..."
4. 导航到 `EasyDebug/Source` 文件夹
5. **重要**：选择以下选项：
   - ✅ "Create groups"（不是 "Create folder references"）
   - ✅ "Add to targets: footBall"
   - ✅ "Copy items if needed"（如果文件不在项目目录内）
6. 点击 "Add"

### 步骤 2：添加资源文件

1. 同样方式添加 `EasyDebug/Source/Resource` 文件夹中的图片资源
2. 确保添加到 target

### 步骤 3：配置 Build Settings

1. 选择项目 -> footBall target
2. 进入 "Build Settings"
3. 搜索 "Header Search Paths"
4. 添加：
   ```
   $(SRCROOT)/EasyDebug/Source
   ```
5. 搜索 "User Header Search Paths"，添加：
   ```
   $(SRCROOT)/EasyDebug/Source
   ```

### 步骤 4：添加依赖库

EasyDebug 依赖 FMDB，确保项目中已包含 FMDB（你的 Podfile 中已有）。

### 步骤 5：在代码中导入和使用

#### 5.1 创建桥接头文件或直接导入

在需要使用 EasyDebug 的文件中：

```objc
#ifdef DEBUG
#import "EasyDebug.h"
#endif
```

#### 5.2 初始化代码（同方式一的步骤 3.2）

---

## 方式三：使用 CocoaPods 本地路径（最简单）

如果你的 Podfile 中已经有 `pod 'easydebug'`，但使用的是远程仓库，可以改为本地路径：

### 修改 Podfile

```ruby
# 将这行：
# pod 'easydebug'

# 改为：
pod 'easydebug', :path => './EasyDebug'
```

然后运行：

```bash
pod install
```

---

## 验证集成是否成功

### 1. 编译检查

在 Xcode 中按 `Cmd + B` 编译项目，确保没有编译错误。

### 2. 运行时检查

在 `AppDelegate.m` 的 `didFinishLaunchingWithOptions` 方法中添加测试代码：

```objc
#ifdef DEBUG
    // 测试 EasyDebug 日志
    [EasyDebug logWithTag:@"AppStart" log:@"EasyDebug 集成成功！"];
    NSLog(@"✅ EasyDebug 测试日志已发送");
#endif
```

运行应用后，应该能看到 EasyDebug 的调试面板。

### 3. 快捷键

在模拟器中，可以使用快捷键打开 EasyDebug 面板（具体快捷键请查看 EasyDebug 文档）。

---

## 完整集成示例代码

### AppDelegate.m 完整示例

```objc
#import "AppDelegate.h"
#import "ThemeManager.h"
#import "LanguageManager.h"
#import "ColorManager.h"
#import "APIManager.h"
#import "APIEnvironmentManager.h"
#import "APIRequestInterceptor.h"
#import "AuthManager.h"
#import "PagFilePreloader.h"
#import <DoraemonKit/DoraemonManager.h>

#ifdef DEBUG
#import <easydebug/EasyDebug.h>  // 如果使用 CocoaPods
// 或者
// #import "EasyDebug.h"  // 如果手动集成
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ... 现有代码 ...
    
    // 初始化 EasyDebug（仅在 Debug 模式）
    #ifdef DEBUG
        // 开启 EasyDebug
        [EasyDebug shared].isOn = YES;
        
        // 配置模块：网络监控 + 性能监控
        EasyDebugModule modules = EasyDebugNetMonitor | EasyDebugPerformance;
        [EasyDebug config:modules];
        
        // 记录启动日志
        [EasyDebug logWithTag:@"AppLifecycle" 
                          log:@"应用启动 - EasyDebug 已初始化"];
        
        NSLog(@"✅ EasyDebug 已初始化");
    #endif
    
    return YES;
}

@end
```

---

## 常见问题

### Q1: 编译错误 "EasyDebug.h file not found"

**解决方案：**
- 如果使用 CocoaPods：确保运行了 `pod install`，并且使用 `.xcworkspace` 打开项目
- 如果手动集成：检查 Header Search Paths 配置是否正确

### Q2: 链接错误 "Undefined symbols"

**解决方案：**
- 确保 EasyDebug 的所有源文件都已添加到 target
- 检查是否缺少 FMDB 依赖

### Q3: EasyDebug 面板不显示

**解决方案：**
- 确保 `[EasyDebug shared].isOn = YES;` 已设置
- 确保在 Debug 模式下运行
- 检查是否有初始化错误日志

---

## 下一步

集成成功后，你可以：

1. **记录自定义日志**：
   ```objc
   [EasyDebug logWithTag:@"CustomTag" log:@"这是一条日志"];
   ```

2. **记录网络请求**（自动，已配置网络监控模块）

3. **监控性能指标**（自动，已配置性能监控模块）

4. **查看崩溃日志**（如果配置了 CrashMonitor 模块）

---

## 注意事项

1. **仅在 Debug 模式启用**：使用 `#ifdef DEBUG` 确保生产环境不包含调试代码
2. **性能影响**：EasyDebug 在 Debug 模式下运行，不会影响 Release 版本
3. **与 DoraemonKit 共存**：EasyDebug 和 DoraemonKit 可以同时使用，互不冲突
