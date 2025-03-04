--- === MouseCombo ===
---
--- 按住一个鼠标键（修饰键），再按下鼠标键组合（连招），触发指定动作
---
--- === END ===

local obj = {}
obj.__index = obj

-- 元数据
obj.name = "MouseCombo"
obj.version = "0.1"
obj.author = "静生 <woohoodai>"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- 定义鼠标按键常量
obj.mouse = {left = 0, right = 1, middle = 2, back = 3, forward = 4}    -- 鼠标按键常量
obj.actions = {}    -- 动作函数列表
obj.comboConfig = {}    -- 鼠标组合配置
obj._isNativeBlocked = {    -- 鼠标按键作为修饰键时，是否阻止原生事件
    [0] = false, -- left
    [1] = true,  -- right
    [2] = true,  -- middle
    [3] = true,  -- back
    [4] = true   -- forward
}

-- 内部状态
obj._isModifierPressed = false
obj._modifierButton = nil
obj._pointerClicks = {}
obj._mouseWatcher = nil

-- 重置内部状态
function obj:resetCombo()
    self._isModifierPressed = false
    self._modifierButton = nil
    self._pointerClicks = {}
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
        hs.eventtap.event.types.rightMouseUp
    }, function(event)
        local eventType = event:getType()
        local button = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
        
        -- 处理按下和释放事件，返回true将阻止原生事件，返回false或者不返回则传递原生事件

        -- 处理按下事件
        if eventType == hs.eventtap.event.types.leftMouseDown or 
           eventType == hs.eventtap.event.types.rightMouseDown or 
           eventType == hs.eventtap.event.types.otherMouseDown then

            -- 若当前没有修饰键，则当前按键作为修饰键
            if self._modifierButton == nil then
                self._modifierButton = button
                self._isModifierPressed = true
                self:showDebug("按下按键" .. button)
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
                if #self._pointerClicks == 0 then
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
                    self:showDebug("触发动作")
                    local curCombo = table.concat(self._pointerClicks)
                    for _, config in ipairs(self.comboConfig) do
                        if config[2] and #config[2] > 0 then
                            local combo = table.concat(config[2])
                            if self._modifierButton == config[1] and curCombo == combo then
                                local action = config[3]
                                if type(action) == "function" then
                                    action()
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
    hs.alert.show("MouseCombo 已启动")
    return self
end

--- MouseCombo:stop()
--- Method
--- 停止MouseCombo
function obj:stop()
    if self._mouseWatcher then
        self._mouseWatcher:stop()
        self:resetCombo()
        hs.alert.show("MouseCombo 已停止")
    end
    return self
end

--- MouseCombo:config(combos)
--- Method
--- 配置 MouseCombo
--- Parameters:
---   * combos - 手势配置数组
function obj:config(combos)
    if combos then
        self.comboConfig = {}
        for _, combo in ipairs(combos) do
            -- Support both table and array style configs
            local modifier = combo.modifier or combo[1]
            local sequence = combo.combo or combo[2]
            local action = combo.action or combo[3]
            
            if modifier and sequence and action then
                table.insert(self.comboConfig, {
                    modifier,
                    sequence,
                    action
                })
            end
        end
    end
    
    return self
end

return obj