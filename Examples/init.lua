-- 加载MouseCombo
hs.loadSpoon("MouseCombo")
local mouse = spoon.MouseCombo.mouse
local l,r,m,b,f = mouse.left, mouse.right, mouse.middle, mouse.back, mouse.forward  -- 鼠标按键别名，可自定义

-- 定义动作，供鼠标组合调用
local actions = {
    copy = function()
        hs.eventtap.keyStroke({"cmd"}, "c")
        hs.alert.show("复制")
    end,
    paste = function()
        hs.eventtap.keyStroke({"cmd"}, "v")
        hs.alert.show("粘贴")
    end,
    --关闭当前标签页
    closeTab = function()
        hs.eventtap.keyStroke({"cmd"}, "w")
        hs.alert.show("关闭当前标签页")
    end
}

-- 定义鼠标组合
-- 格式：{修饰键，鼠标组合序列，执行动作}
-- 修饰键有且只有一个，支持左键、右键或中键
-- 完整语法与简写语法如下
local combos = {
    {modifier = mouse.right, combo = {mouse.left}, action = actions.copy},  -- 按住右键，单击左键，复制
    {r, {l,l}, actions.paste},  -- 按住右键，双击左键，粘贴
    {l,{r,f,b}, actions.closeTab}   -- 按住左键，                              
}   

-- 传入配置并启动MouseCombo
spoon.MouseCombo
    :config(combos)
    :start()


-- 重新加载配置快捷键
hs.hotkey.bind({"ctrl", "cmd", "alt"}, "r", function()
    hs.reload()
    hs.alert.show("Hammerspoon 配置已重新加载")
end)