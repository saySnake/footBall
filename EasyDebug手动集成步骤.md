# EasyDebug 手动添加到 Target 的详细步骤

## 方法一：通过 Xcode 图形界面添加（推荐）

### 步骤 1：打开项目

1. 使用 Xcode 打开 `footBall.xcworkspace`（**重要**：必须使用 `.xcworkspace`，不是 `.xcodeproj`）

### 步骤 2：添加 EasyDebug 源文件到项目

#### 2.1 添加 Core 模块文件

1. 在 Xcode 项目导航器中，**右键点击** `footBall` 文件夹（或你想放置 EasyDebug 的位置）
2. 选择 **"Add Files to 'footBall'..."**
3. 导航到 `EasyDebug/Source/Core` 文件夹
4. **重要选项设置**：
   - ✅ **"Create groups"**（选择这个，不是 "Create folder references"）
   - ✅ **"Add to targets: footBall"**（必须勾选！）
   - ❌ **"Copy items if needed"**（不要勾选，因为文件已经在项目目录中）
5. 点击 **"Add"**

#### 2.2 添加 NetworkMonitor 模块文件

重复步骤 2.1，但这次选择 `EasyDebug/Source/NetworkMonitor` 文件夹

#### 2.3 添加 Performance 模块文件

重复步骤 2.1，但这次选择 `EasyDebug/Source/Performance` 文件夹

#### 2.4 添加 CrashMonitor 模块文件

重复步骤 2.1，但这次选择 `EasyDebug/Source/CrashMonitor` 文件夹

#### 2.5 添加资源文件

1. 右键点击 `footBall` 文件夹
2. 选择 **"Add Files to 'footBall'..."**
3. 导航到 `EasyDebug/Source/Resource` 文件夹
4. **选项设置**：
   - ✅ **"Create groups"**
   - ✅ **"Add to targets: footBall"**
   - ✅ **"Copy items if needed"**（这次可以勾选，确保资源文件被复制）
5. 点击 **"Add"**

### 步骤 3：验证文件已添加到 Target

1. 在项目导航器中，选择一个 EasyDebug 的 `.m` 文件（例如 `EasyDebug.m`）
2. 在右侧的 **File Inspector**（文件检查器）中，查看 **"Target Membership"** 部分
3. 确保 **"footBall"** target 已被勾选 ✅

### 步骤 4：配置 Header Search Paths

1. 在 Xcode 中，点击项目根节点（最顶部的蓝色图标）
2. 选择 **"footBall"** target
3. 点击 **"Build Settings"** 标签
4. 在搜索框中输入 **"Header Search Paths"**
5. 双击 **"Header Search Paths"** 行
6. 点击 **"+"** 按钮添加新路径
7. 输入：`$(SRCROOT)/EasyDebug/Source`（或使用相对路径）
8. 确保设置为 **"recursive"**（递归搜索）

### 步骤 5：配置 User Header Search Paths（可选但推荐）

1. 在 Build Settings 中搜索 **"User Header Search Paths"**
2. 添加：`$(SRCROOT)/EasyDebug/Source`
3. 设置为 **"recursive"**

### 步骤 6：确保依赖库已添加

EasyDebug 依赖 **FMDB**，确保项目中已包含：
- 如果使用 CocoaPods，FMDB 应该已经在 Podfile 中
- 如果没有，需要手动添加 FMDB

### 步骤 7：在代码中导入和使用

#### 7.1 修改 AppDelegate.m

在文件顶部添加：

```objc
#ifdef DEBUG
#import "EasyDebug.h"
#endif
```

在 `didFinishLaunchingWithOptions` 方法中添加：

```objc
#ifdef DEBUG
    // 初始化 EasyDebug
    [EasyDebug shared].isOn = YES;
    // 配置模块：网络监控 + 性能监控
    EasyDebugModule modules = EasyDebugNetMonitor | EasyDebugPerformance;
    [EasyDebug config:modules];
    
    // 记录启动日志
    [EasyDebug logWithTag:@"AppLifecycle" 
                      log:@"应用启动 - EasyDebug 已初始化"];
    
    NSLog(@"✅ EasyDebug 已初始化");
#endif
```

### 步骤 8：编译测试

1. 按 **`Cmd + B`** 编译项目
2. 检查是否有编译错误
3. 如果有 "EasyDebug.h file not found" 错误，检查 Header Search Paths 配置
4. 如果有链接错误，确保所有 `.m` 文件都已添加到 target

---

## 方法二：批量添加文件（更快）

### 一次性添加所有源文件

1. 在 Xcode 项目导航器中，右键点击 `footBall` 文件夹
2. 选择 **"Add Files to 'footBall'..."**
3. 导航到 `EasyDebug/Source` 文件夹
4. **按住 `Cmd` 键**，点击选择以下文件夹：
   - `Core`
   - `NetworkMonitor`
   - `Performance`
   - `CrashMonitor`
   - `Resource`
5. **选项设置**：
   - ✅ **"Create groups"**
   - ✅ **"Add to targets: footBall"**
   - ❌ **"Copy items if needed"**（不要勾选）
6. 点击 **"Add"**

然后按照步骤 4-8 完成配置。

---

## 方法三：通过 Target Membership 添加已存在的文件

如果文件已经在项目中但未添加到 target：

### 步骤 1：选择文件

1. 在项目导航器中，选择 `EasyDebug` 文件夹下的所有 `.m` 文件
   - 可以按住 `Cmd` 键多选
   - 或者按住 `Shift` 键选择连续的文件

### 步骤 2：添加到 Target

1. 在右侧的 **File Inspector**（文件检查器）中
2. 找到 **"Target Membership"** 部分
3. 勾选 **"footBall"** target
4. 对所有 `.m` 文件重复此操作

### 步骤 3：添加资源文件

1. 选择 `debug_entry_icon.png` 文件
2. 在 File Inspector 中，确保 **"footBall"** target 被勾选
3. 确保文件在 **"Copy Bundle Resources"** build phase 中

---

## 验证清单

完成所有步骤后，请检查：

- [ ] 所有 `.h` 和 `.m` 文件都在项目中
- [ ] 所有 `.m` 文件的 Target Membership 中勾选了 "footBall"
- [ ] 资源文件 `debug_entry_icon.png` 已添加到 target
- [ ] Header Search Paths 已配置为 `$(SRCROOT)/EasyDebug/Source`（recursive）
- [ ] 项目可以成功编译（`Cmd + B`）
- [ ] 在代码中可以 `#import "EasyDebug.h"` 而不报错
- [ ] 运行时 EasyDebug 功能正常工作

---

## 常见问题解决

### Q1: "EasyDebug.h file not found" 编译错误

**解决方案：**
1. 检查 Header Search Paths 是否正确配置
2. 确保路径是 `$(SRCROOT)/EasyDebug/Source` 或绝对路径
3. 确保设置为 "recursive"（递归）
4. 清理项目（`Cmd + Shift + K`）后重新编译

### Q2: 链接错误 "Undefined symbols"

**解决方案：**
1. 检查所有 `.m` 文件是否都添加到 target
2. 在 File Inspector 中验证 Target Membership
3. 确保 FMDB 依赖已正确添加

### Q3: 资源文件找不到

**解决方案：**
1. 确保 `debug_entry_icon.png` 在 "Copy Bundle Resources" build phase 中
2. 检查 Target -> Build Phases -> Copy Bundle Resources

### Q4: 文件显示为红色（找不到文件）

**解决方案：**
1. 文件路径可能不正确
2. 右键点击红色文件 -> "Show in Finder" 检查文件是否存在
3. 如果文件已移动，删除引用后重新添加

---

## 文件结构参考

添加完成后，项目结构应该类似：

```
footBall/
├── AppDelegate.m
├── SceneDelegate.m
├── ...
└── EasyDebug/  (或你选择的文件夹名)
    └── Source/
        ├── Core/
        │   ├── EasyDebug.h
        │   ├── EasyDebug.m
        │   ├── Controllers/
        │   ├── Helpers/
        │   ├── Models/
        │   ├── Services/
        │   └── Views/
        ├── NetworkMonitor/
        ├── Performance/
        ├── CrashMonitor/
        └── Resource/
            └── debug_entry_icon.png
```

---

## 快速检查命令

在终端中运行以下命令，检查文件是否都在：

```bash
# 检查所有 .m 文件
find EasyDebug/Source -name "*.m" | wc -l

# 应该返回大约 25 个文件
```

---

## 注意事项

1. **不要删除 Podfile 中的 easydebug**：如果之前通过 CocoaPods 添加过，建议先移除 Podfile 中的 `pod 'easydebug'` 行，然后运行 `pod install`
2. **使用 .xcworkspace**：确保使用 `.xcworkspace` 打开项目，不是 `.xcodeproj`
3. **备份项目**：在进行大量文件操作前，建议先提交到 Git 或备份项目
4. **清理构建**：添加文件后，建议清理构建（`Cmd + Shift + K`）然后重新编译

---

## 完成后的代码示例

### AppDelegate.m 完整示例

```objc
#import "AppDelegate.h"
#import "ThemeManager.h"
// ... 其他导入 ...

#ifdef DEBUG
#import "EasyDebug.h"
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ... 现有初始化代码 ...
    
    #ifdef DEBUG
        // 初始化 EasyDebug
        [EasyDebug shared].isOn = YES;
        EasyDebugModule modules = EasyDebugNetMonitor | EasyDebugPerformance;
        [EasyDebug config:modules];
        [EasyDebug logWithTag:@"AppLifecycle" log:@"应用启动"];
        NSLog(@"✅ EasyDebug 已初始化");
    #endif
    
    return YES;
}

@end
```

完成以上步骤后，EasyDebug 就成功手动集成到你的项目中了！
