-- ====== 加载MouseCombo ======
hs.loadSpoon("MouseCombo")

-- ====== 获取鼠标按键 ======
local mouse = spoon.MouseCombo.mouse
-- （自定义）鼠标按键别名，方便配置
local l,r,m,b,f,up,down = mouse.left,   -- 鼠标左键
                    mouse.right, -- 鼠标右键
                    mouse.middle, -- 鼠标中键
                    mouse.back, -- 鼠标后退键
                    mouse.forward, -- 鼠标前进键
                    mouse.scrollUp, -- 鼠标中键向上滚动
                    mouse.scrollDown -- 鼠标中键向下滚动

-- ====== 定义动作，供鼠标组合调用 ======
local actions = {
    -- 复制
    copy = function()
        hs.eventtap.keyStroke({"cmd"}, "c")
    end,
    -- 粘贴
    paste = function()
        hs.eventtap.keyStroke({"cmd"}, "v")
    end,
    -- 放大缩小
    zoomIn = function()
        hs.eventtap.keyStroke({"cmd"}, "=")
    end,
    zoomOut = function()
        hs.eventtap.keyStroke({"cmd"}, "-")
    end,
}

-- ====== 配置鼠标组合 ======
-- * 每条组合包含如下参数
--   * modifier - number, 修饰键，仅支持左键/右键/中键其中之一，必填
--   * combo - array, 组合键序列，必填
--   * action - function, 动作，必填
--   * others - array, 配置杂项，可选
--       * others.tip - string, 动作名称提示，可选
--       * others.isShow - boolean, 是否显示动作名称提示，可选
--       * others.include - array, 应用过滤器-仅这些应用生效，可选；成员元素为bundleID，string
--       * others.exclude - array, 排除的应用-不在这些应用生效，可选；成员元素为bundleID，string
-- 修饰键有且只有一个，支持左键、右键或中键
local combos = {
    -- 完整语法示例：按住右键，单击左键，执行复制动作，会弹出提示“复制”；当Safari浏览器为前台应用时，动作不执行
    {modifier = mouse.right, combo = {mouse.left}, action = actions.copy,{tip="复制",isShow=true,exclude={'com.apple.Safari'}}},
    -- 简写语法示例：按住右键，双击左键，执行粘贴动作，不显示任何提示（因没有设置tip）
    {r, {l,l}, actions.paste},  -- 按住右键，双击左键，粘贴
    -- 简写语法示例：按住中键，滚动滚轮，执行放大/缩小动作，会弹出提示放大/缩小（设置tip时，默认显示提示）
    {m,{up},actions.zoomIn,{"放大"}},
    {m,{down},actions.zoomOut,{"缩小",true}},                
}   

-- ====== 传入配置并启动MouseCombo ======
spoon.MouseCombo
    :config(combos)
    :start()

-- ====== ctrl + cmd + alt + x 开启/停用 ======
hs.hotkey.bind({"ctrl", "cmd", "alt"}, "x", function()
    spoon.MouseCombo:config(combos)
    spoon.MouseCombo:toggle()
end)