# MouseCombo（鼠标连招）
MouseCombo（鼠标连招） 是一个 Hammerspoon Spoon，**用于自定义鼠标按键组合**。
通过按住一个鼠标键（修饰键）并点击其他鼠标按键组合（连招），来触发自定义动作。

## 功能特点

- 支持左键、中键、右键任一鼠标键作为修饰键
- 支持单次点击和连续点击组合
- 支持自定义要触发的动作函数
- 配置方式简单易写

## 示例
[示例配置](./Examples/init.lua)中实现了如下三种效果：
- 按住右键，单击左键，触发复制（Ctrl + C）
- 按住右键，双击左键，触发粘贴（Ctrl + V）
- 按住左键，依次点击右键、前进、后退，触发关闭当前标签页（Ctrl + W）
## 安装方法

1. 下载本仓库
2. 将 `Source/MouseCombo.spoon` 目录复制到 `~/.hammerspoon/Spoons/` 目录下

## 使用方法

在 Hammerspoon 的配置文件中按需**定义动作**、**定义鼠标组合**即可

鼠标可为鼠标按键配置别名，简化鼠标组合的配置

完整示例代码见[示例配置](./Examples/init.lua)

```lua
-- 加载 Spoon
hs.loadSpoon("MouseCombo")

-- 定义鼠标按键别名（可选）
local mouse = spoon.MouseCombo.mouse
local l,r,m,f,b = mouse.left, mouse.right, mouse.middle, mouse.forward, mouse.backward

-- ===
-- 定义动作
-- ===
local actions = {
    copy = function()
        hs.eventtap.keyStroke({"cmd"}, "c")
        hs.alert.show("复制")
    end
}

-- ===
-- 定义鼠标组合
-- ===
local combos = {
    {modifier = r, combo = {l}, action = actions.copy},     -- 完整语法
    {r, {l,l}, actions.paste}                              -- 简写语法
}

-- 启动 MouseCombo
spoon.MouseCombo:config(combos):start()
```

## 许可证
本项目采用 MIT 许可证，详见[LICENSE](https://opensource.org/license/MIT)。