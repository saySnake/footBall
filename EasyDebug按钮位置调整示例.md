# EasyDebug 按钮位置调整 - 快速示例

## 将按钮移到右下角（推荐）

### 修改文件：`EasyDebug/Source/Core/Services/EZDDisplayer.m`

#### 1. 修改初始位置（第 69-70 行）

**原代码：**
```objc
self.consoleEntryBtn.dg_origin = CGPointMake(window.dg_width * .06,
                                             window.dg_height - self.consoleEntryBtn.dg_height * .4);
```

**修改为（右下角）：**
```objc
// 右下角：距离右边 6%，距离底部 40% 的按钮高度
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,
    window.dg_height - self.consoleEntryBtn.dg_height * .4
);
```

#### 2. 修改键盘隐藏时的恢复位置（第 138 行）

**原代码：**
```objc
self.consoleEntryBtn.dg_y = screenH - self.consoleEntryBtn.dg_height * .4;
```

**保持不变**（因为 Y 坐标逻辑相同，只是 X 坐标变了）

---

## 其他常用位置示例

### 右上角

```objc
// 第 69-70 行修改为：
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,
    self.consoleEntryBtn.dg_height * .4
);

// 第 138 行修改为：
self.consoleEntryBtn.dg_y = self.consoleEntryBtn.dg_height * .4;
```

### 底部居中

```objc
// 第 69-70 行修改为：
self.consoleEntryBtn.dg_origin = CGPointMake(
    (window.dg_width - self.consoleEntryBtn.dg_width) / 2.0,
    window.dg_height - self.consoleEntryBtn.dg_height * .4
);

// 第 138 行保持不变
```

### 自定义精确位置（例如：距离右边 20，距离底部 100）

```objc
// 第 69-70 行修改为：
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - 20,
    window.dg_height - 100
);

// 第 138 行修改为：
self.consoleEntryBtn.dg_y = screenH - 100;
```

---

## 完整修改示例：右下角

以下是完整的修改后的代码片段：

```objc
// 第 69-70 行
self.consoleEntryBtn.dg_origin = CGPointMake(
    window.dg_width - self.consoleEntryBtn.dg_width - window.dg_width * .06,
    window.dg_height - self.consoleEntryBtn.dg_height * .4
);

// 第 138 行保持不变（因为 Y 坐标逻辑相同）
self.consoleEntryBtn.dg_y = screenH - self.consoleEntryBtn.dg_height * .4;
```

---

## 修改步骤总结

1. 打开 `EasyDebug/Source/Core/Services/EZDDisplayer.m`
2. 找到第 69-70 行，修改 `CGPointMake` 的参数
3. 如果需要，修改第 138 行的 Y 坐标
4. 保存文件
5. 重新编译运行项目

---

## 位置参数说明

- **X 坐标**：
  - 左侧：`window.dg_width * .06`（屏幕宽度的 6%）
  - 右侧：`window.dg_width - btn.dg_width - window.dg_width * .06`
  - 居中：`(window.dg_width - btn.dg_width) / 2.0`

- **Y 坐标**：
  - 顶部：`btn.dg_height * .4`（按钮高度的 40%）
  - 底部：`window.dg_height - btn.dg_height * .4`
  - 居中：`(window.dg_height - btn.dg_height) / 2.0`
