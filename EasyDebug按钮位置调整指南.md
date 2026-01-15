# EasyDebug 按钮位置调整指南

## 方法一：直接修改源码（最简单，推荐）

### 步骤 1：找到位置设置代码

打开文件：`EasyDebug/Source/Core/Services/EZDDisplayer.m`

找到第 69-70 行的代码：

```objc
self.consoleEntryBtn.dg_origin = CGPointMake(window.dg_width * .06,
                                             window.dg_height - self.consoleEntryBtn.dg_height * .4);
```

### 步骤 2：修改位置参数

#### 示例 1：调整到右下角

```objc
// 修改为右下角
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,  // X: 右侧
    window.dg_height - self.consoleEntryBtn.dg_height * .4  // Y: 底部
);
```

#### 示例 2：调整到右上角

```objc
// 修改为右上角
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,  // X: 右侧
    self.consoleEntryBtn.dg_height * .4  // Y: 顶部
);
```

#### 示例 3：调整到左上角

```objc
// 修改为左上角
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width * .06,  // X: 左侧
    self.consoleEntryBtn.dg_height * .4  // Y: 顶部
);
```

#### 示例 4：调整到屏幕底部居中

```objc
// 修改为底部居中
self.consoleEntryBtn.dg_origin = CGPointMake(
    (window.dg_width - self.consoleEntryBtn.dg_width) / 2.0,  // X: 居中
    window.dg_height - self.consoleEntryBtn.dg_height * .4  // Y: 底部
);
```

#### 示例 5：自定义精确位置

```objc
// 自定义位置（例如：距离左边 20，距离底部 100）
self.consoleEntryBtn.dg_origin = CGPointMake(
    20,  // X: 距离左边 20 点
    window.dg_height - 100  // Y: 距离底部 100 点
);
```

#### 示例 6：使用百分比位置

```objc
// 使用百分比（例如：屏幕宽度的 90%，高度的 80%）
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width * 0.9 - self.consoleEntryBtn.dg_width,  // X: 90% 位置
    window.dg_height * 0.8  // Y: 80% 位置
);
```

### 步骤 3：同时修改键盘显示时的位置

找到第 136 和 138 行的代码（键盘显示时的位置调整）：

```objc
- (void)keyboardChange:(NSNotification *)note{
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    if ((frame.size.height > 0) && frame.origin.y < screenH) {
        // 键盘显示时，按钮位置在键盘上方
        self.consoleEntryBtn.dg_y = frame.origin.y - 40;  // 可以调整这个 40 的值
    } else {
        // 键盘隐藏时，恢复原位置
        self.consoleEntryBtn.dg_y = screenH - self.consoleEntryBtn.dg_height * .4;
    }
}
```

如果需要，可以修改这里的逻辑以匹配新的按钮位置。

---

## 方法二：使用配置类（不修改源码）

我已经创建了 `EasyDebugPositionConfig` 类，可以在不修改 EasyDebug 源码的情况下调整位置。

### 使用步骤

#### 1. 在 AppDelegate.m 中导入

```objc
#ifdef DEBUG
#import "EasyDebugPositionConfig.h"
#endif
```

#### 2. 在初始化 EasyDebug 后配置位置

```objc
#ifdef DEBUG
    // 初始化 EasyDebug
    [EasyDebug shared].isOn = YES;
    EasyDebugModule modules = EasyDebugNetMonitor | EasyDebugPerformance;
    [EasyDebug config:modules];
    
    // 配置按钮位置
    // 方式 1：使用预设位置（0-7）
    [EasyDebugPositionConfig configButtonPosition:1  // 1=右下角
                                           offsetX:0 
                                           offsetY:0];
    
    // 方式 2：使用自定义坐标
    // [EasyDebugPositionConfig configButtonPositionWithX:300 y:600];
    
    // 方式 3：使用百分比
    // [EasyDebugPositionConfig configButtonPositionWithXPercent:0.9 yPercent:0.8];
    
    NSLog(@"✅ EasyDebug 已初始化");
#endif
```

#### 3. 预设位置说明

- `0`: 左下角（默认）
- `1`: 右下角
- `2`: 左上角
- `3`: 右上角
- `4`: 底部居中
- `5`: 顶部居中
- `6`: 左侧居中
- `7`: 右侧居中

---

## 常用位置配置示例

### 右下角（推荐，不遮挡左侧内容）

```objc
// 在 EZDDisplayer.m 第 69-70 行修改为：
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,
    window.dg_height - self.consoleEntryBtn.dg_height * .4
);
```

### 右上角

```objc
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,
    self.consoleEntryBtn.dg_height * .4
);
```

### 底部居中

```objc
self.consoleEntryBtn.dg_origin = CGPointMake(
    (window.dg_width - self.consoleEntryBtn.dg_width) / 2.0,
    window.dg_height - self.consoleEntryBtn.dg_height * .4
);
```

### 距离右边 20，距离底部 100

```objc
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - 20,
    window.dg_height - 100
);
```

---

## 按钮大小调整（可选）

如果需要调整按钮大小，找到第 92 行：

```objc
self.consoleEntryBtn.dg_size = CGSizeMake(60, 60);  // 默认 60x60
```

修改为你需要的大小，例如：

```objc
self.consoleEntryBtn.dg_size = CGSizeMake(50, 50);  // 更小
// 或
self.consoleEntryBtn.dg_size = CGSizeMake(70, 70);  // 更大
```

---

## 完整修改示例

### 修改为右下角，按钮大小 50x50

在 `EZDDisplayer.m` 中：

1. **第 92 行**，修改按钮大小：
```objc
self.consoleEntryBtn.dg_size = CGSizeMake(50, 50);
```

2. **第 69-70 行**，修改位置：
```objc
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,
    window.dg_height - self.consoleEntryBtn.dg_height * .4
);
```

3. **第 138 行**（键盘隐藏时），修改恢复位置：
```objc
self.consoleEntryBtn.dg_y = screenH - self.consoleEntryBtn.dg_height * .4;
```

---

## 注意事项

1. **修改后需要重新编译**：修改源码后，需要重新编译项目才能生效
2. **备份源码**：建议在修改前先备份 `EZDDisplayer.m` 文件
3. **键盘适配**：如果修改了按钮位置，记得同时修改 `keyboardChange:` 方法中的位置逻辑
4. **安全区域**：在 iPhone X 及以后的设备上，注意避开底部安全区域（Home Indicator）

---

## 测试建议

1. 修改后运行应用
2. 检查按钮是否在预期位置
3. 测试键盘弹出时按钮位置是否正确
4. 在不同屏幕尺寸的设备上测试（iPhone SE、iPhone 14、iPhone 14 Pro Max）

---

## 快速参考

| 位置 | X 坐标 | Y 坐标 |
|------|--------|--------|
| 左下角（默认） | `window.dg_width * .06` | `window.dg_height - btn.dg_height * .4` |
| 右下角 | `window.dg_width - btn.dg_width - window.dg_width * .06` | `window.dg_height - btn.dg_height * .4` |
| 左上角 | `window.dg_width * .06` | `btn.dg_height * .4` |
| 右上角 | `window.dg_width - btn.dg_width - window.dg_width * .06` | `btn.dg_height * .4` |
| 底部居中 | `(window.dg_width - btn.dg_width) / 2.0` | `window.dg_height - btn.dg_height * .4` |
