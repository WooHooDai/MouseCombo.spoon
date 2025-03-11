--- === MouseCombo ===
---
--- 按住一个鼠标键（修饰键），再按下鼠标键组合（连招），触发指定动作

--- === END ===

local obj = {}
obj.__index = obj

-- 元数据
obj.name = "MouseCombo"
obj.version = "0.2"
obj.author = "静声 <woohoodai>"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.homepage = "https://github.com/WooHooDai/MouseCombo"

-- 定义鼠标按键常量
obj.mouse = {left = 0, right = 1, middle = 2, back = 3, forward = 4, scrollUp="scroll_up", scrollDown="scroll_down"}    -- 鼠标按键常量
obj.actions = {}    -- 动作函数列表
obj.comboConfig = {}    -- 鼠标组合配置
obj._isNativeBlocked = {    -- 鼠标按键作为修饰键时，是否阻止原生事件
    [0] = false, -- left
    [1] = true,  -- right
    [2] = true,  -- middle
    [3] = true,  -- back
    [4] = true   -- forward
}

-- Spoon状态
obj._isRunning = false  -- 记录Spoon是否已启动

-- 内部状态
obj._isModifierPressed = false  -- 记录修饰键是否被按下
obj._modifierButton = nil   -- 记录修饰键
obj._pointerClicks = {}     --记录组合键序列
obj._isScrolling = false    -- 判断修饰键按下期间是否有滚轮事件发生，若有方便阻止修饰键释放后的原生事件
obj._mouseWatcher = nil     -- 鼠标事件监听器
obj._currentApp = nil       -- 记录当前前台应用


-- 滚轮事件相关状态
obj._lastScrollTime = 0  -- 上次滚动事件的时间戳
obj._scrollThreshold = 0.1  -- 滚动事件的节流阈值（秒）
obj._scrollSensitivity = 0.1  -- 滚动灵敏度阈值，数值越大灵敏度越低


-- 重置内部状态
function obj:resetCombo()
    self._isModifierPressed = false
    self._modifierButton = nil
    self._pointerClicks = {}
    self._isScrolling = false
end

--发送点击事件（用于修饰键被独立按下并释放时）
function obj:sendMouseClick(button, point)
    if button == self.mouse.right then
        hs.eventtap.rightClick(point)
    elseif button == self.mouse.left then
        hs.eventtap.leftClick(point)
    else
        hs.eventtap.otherClick(point, 200000, button)
    end
    self:showDebug("修饰键" .. self._modifierButton .. "被单独击发")
end

--  该动作是否可执行：取决于应用过滤器
function obj:canActionRun(combo)
    local config = combo.others or combo[4]
    
    if config == nil then
        self:showDebug("触发动作")
        return true
    end

    local includes = config.include or config[3]
    local excludes = config.exclude or config[4]

    local curApp = hs.application.frontmostApplication():bundleID()

    -- 排除应用
    if excludes~=nil and #excludes~=0 then
        for _, app in ipairs(excludes) do
            if app == curApp then
                hs.alert.show("被排除"..app)
                self:showDebug("动作被应用过滤器排除（exclude）")
                return false
            end
        end
    end

    -- 限定应用
    if includes~=nil and #includes~=0 then
        for _, app in ipairs(includes) do
            if app == curApp then
                return true
            end
        end
        self:showDebug("动作被应用过滤器排除（include）")
        return false    -- 当限定应用的时候，则只在限定应用里生效
    end

    -- 无应用过滤器时，默认在所有应用生效
    self:showDebug("动作成功")
    return true
end

-- 展示动作名称
-- 如果没有配置名称，则不展示
-- 如果配置了名称，没有配置是否展示，则默认展示
-- 如果配置了名称，且配置了是否展示，则根据配置展示
function obj:showActionTip(combo)
    local config = combo.others or combo[4]
    if config == nil then
        self:showDebug("动作提示因未设置而不显示")
        return
    end
    
    local tip = config.tip or config[1]
    local isShow = config.isShow or config[2]

    if tip == nil then
        self:showDebug("动作提示因未设置而不显示")
        return
    end

    -- 定制展示样式
    local screen = hs.screen.mainScreen()
    local frame = screen:fullFrame()
    local alertStyle = {
        strokeWidth = 0,
        fadeInDuration = 0.15,
        fadeOutDuration = 0.15,
        -- padding = 15,
        radius = 10,
        atScreenEdge = 0,  -- 0 for middle, 1 for top, 2 for bottom
    }

    if isShow == nil or isShow~='boolean' then   -- 默认展示
        isShow = true
    end

    if isShow then   
        hs.alert.show(tip,alertStyle,screen,1) -- 展示1秒
    end

end


-- 调试工具
obj.isDebug = false -- 默认关闭调试信息
function obj:showDebug(info)
    if self.isDebug then
        hs.alert.show(info)
    end
end

--- MouseCombo:init()
--- Method
--- 初始化MouseCombo Spoon
function obj:init()
    local self = obj
    -- 初始化鼠标事件监听器
    self._mouseWatcher = hs.eventtap.new({
        hs.eventtap.event.types.otherMouseDown,
        hs.eventtap.event.types.otherMouseUp,
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.leftMouseUp,
        hs.eventtap.event.types.rightMouseDown,
        hs.eventtap.event.types.rightMouseUp,
        hs.eventtap.event.types.scrollWheel  -- 添加滚轮事件监听
    }, function(event)
        local eventType = event:getType()
        local button = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)

        -- 处理滚轮事件
        if eventType == hs.eventtap.event.types.scrollWheel then
            -- 仅在有修饰键被按下时处理滚轮事件
            if self._isModifierPressed then
                self._isScrolling = true
                -- 获取当前时间
                local currentTime = hs.timer.secondsSinceEpoch()
                
                -- 节流处理：如果距离上次滚动事件时间太短，则忽略本次事件
                if (currentTime - self._lastScrollTime) < self._scrollThreshold then
                    return true
                end
                
                -- 获取滚动值（垂直和水平）
                local deltaY = event:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)
                local deltaX = event:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis2)
                
                -- 防抖动：仅处理超过灵敏度阈值的滚动
                if math.abs(deltaY) > self._scrollSensitivity then
                    -- 更新最后滚动时间
                    self._lastScrollTime = currentTime
                    
                    -- 确定滚动方向并触发对应动作
                    local scrollDirection = deltaY > 0 and self.mouse.scrollUp or self.mouse.scrollDown
                    self:showDebug("触发滚轮事件：" .. scrollDirection)
                    
                    -- 在配置中查找匹配的动作并执行
                    for _, config in ipairs(self.comboConfig) do
                        if config[1] == self._modifierButton and    -- 存在修饰键
                           config[2] and #config[2] == 1 and    -- 存在组合键序列，且组合键序列为1（滚动事件每触发一次，需立即调用一次动作）
                           config[2][1] == scrollDirection and -- 判断配置滚动方向与实际滚动方向是否匹配
                           self:canActionRun(config)   then 
                            local action = config[3]
                            if type(action) == "function" then
                                action()
                                self:showActionTip(config)
                            end
                            break
                        end
                    end
                    return true
                end
            end
            return false
        end

        -- 处理按下和释放事件，返回true将阻止原生事件，返回false或者不返回则传递原生事件

        -- 处理按下事件
        if eventType == hs.eventtap.event.types.leftMouseDown or 
           eventType == hs.eventtap.event.types.rightMouseDown or 
           eventType == hs.eventtap.event.types.otherMouseDown then

            -- 若当前没有修饰键，则当前按键作为修饰键
            if self._modifierButton == nil then
                self._modifierButton = button
                self._isModifierPressed = true
                self:showDebug("设置修饰键为" .. self._modifierButton)
                return self._isNativeBlocked[button]    -- 根据配置决定是否阻止原生事件（例如左键不阻止原生事件，避免其无法按下拖动选择）
            end

            -- 如果已经有修饰键，则分情况处理
            -- 如果当前事件是主键被按下，记录主键次数
            -- 如果当前事件是修饰键被按下，则重置内部状态
            if button ~= self._modifierButton then
                table.insert(self._pointerClicks, button)
                self:showDebug("当前被按下的主键的数量" .. #self._pointerClicks .. "\n按键序列为" .. table.concat(self._pointerClicks))
                return true
            else
                --  修饰键被第二次按下，说明修饰键被单独击发
                self:resetCombo()
                return false
            end
        end
        
        -- 处理释放事件
        if eventType == hs.eventtap.event.types.leftMouseUp or 
           eventType == hs.eventtap.event.types.rightMouseUp or 
           eventType == hs.eventtap.event.types.otherMouseUp then

            -- 被释放时没有修饰键，说明正在释放的就是修饰键（修饰键被单独激发）
            if self._modifierButton == nil then
                return false
            end

            -- 如果当前按键是修饰键，分情况处理
            -- 如果主键次数为零，则重新触发一次修饰键，并将修饰键和主键重置
            -- 如果主键次数不为零，则在配置表里寻找是否有匹配的配置，若有则执行动作，若无则重置并阻止原生事件
            if button == self._modifierButton then
                if #self._pointerClicks == 0 and self._isScrolling == false then    -- 修饰键按下期间，没有其他按键和滚动事件
                    if self._isNativeBlocked[self._modifierButton] == true then
                        self._isModifierPressed = false
                        local point = hs.mouse.absolutePosition()
                        self:sendMouseClick(self._modifierButton, point)
                        return true
                    else
                        self:showDebug("修饰键" .. self._modifierButton .. "被单独击发")
                        self:resetCombo()
                        return false
                    end
                else
                    self:showDebug("主键被按下" .. #self._pointerClicks .. "次")
                    local curCombo = table.concat(self._pointerClicks)
                    for _, config in ipairs(self.comboConfig) do
                        if config[2] and #config[2] > 0 then
                            local combo = table.concat(config[2])
                            if self._modifierButton == config[1] and
                            curCombo == combo and
                            self:canActionRun(config) then
                                local action = config[3]
                                if type(action) == "function" then
                                    action()
                                    self:showActionTip(config)
                                end
                                break
                            end
                        end
                    end

                    self:resetCombo()
                    return self._isNativeBlocked[button]
                end
            else
                return self._isNativeBlocked[button]
            end
        end
    end)
    
    return self
end

--- MouseCombo:start()
--- Method
--- 启动MouseCombo
function obj:start()
    self._mouseWatcher:start()
    obj._isRunning = true
    hs.notify.new({title = "MouseCombo", informativeText = "MouseCombo 已启动"}):send()
    return self
end

--- MouseCombo:stop()
--- Method
--- 停止MouseCombo
function obj:stop()
    if self._mouseWatcher then
        self._mouseWatcher:stop()
        self:resetCombo()
        obj._isRunning = false
        hs.notify.new({title = "MouseCombo", informativeText = "MouseCombo 已停止"}):send()
    end
    return self
end

--- MouseCombo:config(combos)
--- Method
--- 配置 MouseCombo
--- Parameters:
---   * combos - dict, 配置, 必填
---     * combos.modifier - number, 修饰键，必填
---     * combos.combo - array, 组合键序列，必填
---     * combos.action - function, 动作，必填
---     * combos.others - array, 应用过滤器，可选
---         * combos.others.tip - string, 动作名称提示，可选
---         * combos.others.isShow - boolean, 是否显示动作名称提示，可选
---         * combos.others.include - array, 应用过滤器-仅这些应用生效，可选
---         * combos.others.exclude - array, 排除的应用-不在这些应用生效，可选
function obj:config(combos)
    if combos then
        self.comboConfig = {}
        for _, combo in ipairs(combos) do
            -- Support both table and array style configs
            local modifier = combo.modifier or combo[1]
            local sequence = combo.combo or combo[2]
            local action = combo.action or combo[3]
            local others = combo.others or combo[4]
            
            if modifier and sequence and action then
                table.insert(self.comboConfig, {
                    modifier,
                    sequence,
                    action,
                    others
                })
            end
        end
    end
    
    return self
end

--- MouseCombo:toggle()
--- Method
--- 切换 MouseCombo 的开关
function obj:toggle()
    if obj._isRunning then
        obj:stop()
    else
        obj:start()
    end
    return self
end

return obj
