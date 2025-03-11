# MouseCombo（鼠标连招）
MouseCombo（鼠标连招） 是一个 Hammerspoon Spoon，**用于自定义鼠标按键组合**。

通过按住一个鼠标键（修饰键）并点击其他鼠标按键组合（连招），来触发自定义动作。

## 功能特点

- 自由指定修饰键：支持左键、中键、右键任一鼠标键作为修饰键
- 自由指定组合键：支持单次点击和连续点击组合
- 自由定制动作功能：自定义动作函数
- 支持鼠标滚轮事件：如按住中键，向上滚动放大页面，向下滚动缩小页面
- 支持应用过滤：仅在指定应用中生效动作；不在指定应用中生效动作
- 支持动作提示：可配置动作激发时提示文本；可配置指定动作是否展示提示

## 示例
[示例配置](./Examples/init.lua)中实现了如下三种效果：
- 按住右键，单击左键，触发复制（Ctrl + C），弹出动作提示“复制”；当Safari浏览器为前台应用时，动作不执行
- 按住右键，双击左键，触发粘贴（Ctrl + V），无动作提示
- 按住中键，向上滚动，放大页面；向下滚动，缩小页面。弹出动作提示“放大”/“缩小”

## 安装方法

1. 下载本仓库，或者直接下载[插件压缩包](https://github.com/WooHooDai/MouseCombo/releases/tag/v0.1)
2. 解压后将 `Source/MouseCombo.spoon` 目录复制到 `~/.hammerspoon/Spoons/` 目录下

## 使用方法

完整示例代码见[示例配置](./Examples/init.lua)

### 基本使用
在 Hammerspoon 的配置文件中按需**定义动作**、**定义鼠标组合**即可

```lua
-- 加载 Spoon
hs.loadSpoon("MouseCombo")

-- 定义鼠标按键别名（可选）
local mouse = spoon.MouseCombo.mouse
local l,r,m,f,b,up,down = mouse.left, mouse.right, mouse.middle, mouse.forward, mouse.backward, mouse.scrollUp, mouse.scrollDown

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
    -- 完整语法示例：按住右键，单击左键，执行复制动作，会弹出提示“复制”；当Safari浏览器为前台应用时，动作不执行
    {modifier = mouse.right, combo = {mouse.left}, action = actions.copy,{tip="复制",isShow=true,exclude={'com.apple.Safari'}}},
    -- 简写语法示例：按住右键，双击左键，执行粘贴动作，不显示任何提示（因没有设置tip）
    {r, {l,l}, actions.paste},  -- 按住右键，双击左键，粘贴
}

-- 启动 MouseCombo
spoon.MouseCombo:config(combos):start()
```
### 便捷开启/停用
提供了`toggle()`这个api，方便快速开启/停用脚本
```lua
-- ctrl + cmd + alt + x 开启/停用
hs.hotkey.bind({"ctrl", "cmd", "alt"}, "x", function()
    spoon.MouseCombo:config(combos)
    spoon.MouseCombo:toggle()
end)
```

### 配置管理
考虑到动作函数的定义较多，可以考虑分离出去单独管理，具体方式如下：
1. 在`.hammerspoon`目录下新建配置文件夹，如`config`
2. 在config文件夹下新建动作配置文件，如`mouseComboActions.lua`
3. 编辑`mouseComboActions.lua`
```lua
-- 定义动作，供鼠标组合调用
local actions = {
    copy = function()
        hs.eventtap.keyStroke({"cmd"}, "c")
    end,
}
-- ====== 返回动作 ======
return actions
```
4. 在`.hammerspoon/init.lua`中引入动作配置文件，并使用动作
```lua
local actions = require("config.mouseComboActions")
local combos = {r,{l},actions.copy}
```

## TODO
- [ ] 组合键提示清单 / CheatSheet
- [ ] 更好的配置形式


## 许可证
本项目采用 MIT 许可证，详见[LICENSE](https://opensource.org/license/MIT)。
