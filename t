-- [[ 🎯 Universal Trade System V6.5 - Crate Dupe (Fixed) ]] --
-- Added: Crates Tab with Grid Layout (Centered & No Scrollbar)
-- Fixed: Scrollbar Visibility & Alignment
-- Fixed: Variable Scope Errors
-- 2338
-- วิธีใช้งาน cratesdupe
-- ใช้เวอชั่นนี้
-- 1 ใช้ตัวรับcrates ส่งเทรดไปหา ตัวdupe
-- 2 ตัวdupe add crates 
-- 3 ตัวdupe cancel trade โดยการกด e openegg
-- 4 ใช้ตัวรับส่งหา ตัว dupe ละเทรดเปล่าๆอีกที
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/doedie00-source/trades/refs/heads/main/65dupecrates"))()
-- ========================================== --
-- 📦 Services & Dependencies
-- ========================================== --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local TradeController = Knit.GetController("TradeController")
local TradingService = Knit.GetService("TradingService")
local ReplicaListener = Knit.GetController("ReplicaListener")
local LocalPlayer = Players.LocalPlayer

-- Try to load CratesInfo securely
local SuccessLoad, CratesInfo = pcall(function()
    return require(ReplicatedStorage.GameInfo.CratesInfo)
end)
if not SuccessLoad then 
    warn("⚠️ Failed to load CratesInfo") 
    CratesInfo = {} 
end

-- Cleanup Old GUI
if CoreGui:FindFirstChild("CleanTradeGUI") then
    CoreGui.CleanTradeGUI:Destroy()
end

-- ========================================== --
-- ⚙️ Configuration & Constants
-- ========================================== --
local CONFIG = {
    VERSION = "6.5",
    GUI_NAME = "CleanTradeGUI",
    
    -- Window Settings
    MAIN_WINDOW_SIZE = UDim2.new(0, 800, 0, 500),
    SIDEBAR_WIDTH = 120,
    MINI_ICON_SIZE = UDim2.new(0, 50, 0, 50),
    
    -- Timing
    STATUS_RESET_DELAY = 4,
    BUTTON_CHECK_INTERVAL = 0.5,
    TRADE_RESET_THRESHOLD = 3,
    
    -- UI Spacing
    CORNER_RADIUS = 8,
    LIST_PADDING = 3,
    BUTTON_PADDING = 5,
    
    -- Keybind
    TOGGLE_KEY = Enum.KeyCode.T,
}

local THEME = {
    MainBg = Color3.fromRGB(20, 20, 25),
    MainTransparency = 0.1,
    PanelBg = Color3.fromRGB(10, 10, 15),
    PanelTransparency = 0.5,
    TextWhite = Color3.fromRGB(255, 255, 255),
    TextGray = Color3.fromRGB(180, 180, 180),
    BtnDefault = Color3.fromRGB(50, 50, 60),
    BtnSelected = Color3.fromRGB(0, 140, 255),
    BtnMainTab = Color3.fromRGB(40, 40, 50),
    BtnMainTabSelected = Color3.fromRGB(255, 170, 0),
    BtnDupe = Color3.fromRGB(170, 0, 255),
    BtnDisabled = Color3.fromRGB(40, 40, 40),
    TextDisabled = Color3.fromRGB(100, 100, 100),
    ItemInv = Color3.fromRGB(100, 255, 140),
    ItemWiki = Color3.fromRGB(180, 140, 255),
    ItemEquip = Color3.fromRGB(255, 80, 80),
    ItemInTrade = Color3.fromRGB(255, 200, 80),
    PlayerBtn = Color3.fromRGB(255, 170, 0),
    Success = Color3.fromRGB(85, 255, 127),
    Fail = Color3.fromRGB(255, 85, 85),
    DupeReady = Color3.fromRGB(0, 255, 200),
    CrateSelected = Color3.fromRGB(0, 255, 100), -- Green border for crates
}

-- ข้อมูลสูตรการเสกของ (Dupe Recipes)
local DUPE_RECIPES = {
    Scrolls = {
        {
            Name = "Dark Scroll", 
            Tier = 5, 
            RequiredTiers = {3, 4, 6}, 
            Service = "Scrolls",
            PreventIfOwned = true
        }
    },
    Tickets = {
        {Name = "Void Ticket", Tier = 3, RequiredTiers = {4, 5, 6}, Service = "Tickets"},
        {Name = "Summer Ticket", Tier = 4, RequiredTiers = {3, 5, 6}, Service = "Tickets"},
        {Name = "Eternal Ticket", Tier = 5, RequiredTiers = {3, 4, 6}, Service = "Tickets"},
        {Name = "Arcade Ticket", Tier = 6, RequiredTiers = {3, 4, 5}, Service = "Tickets"},
    },
    Potions = {
        {Name = "White Strawberry", Tier = 1, RequiredTiers = {2}, Service = "Strawberry"},
        {Name = "Mega Luck Potion", Tier = 3, RequiredTiers = {1, 2}, Service = "Luck Potion"},
        {Name = "Mega Wins Potion", Tier = 3, RequiredTiers = {1, 2}, Service = "Wins Potion"},
        {Name = "Mega Exp Potion", Tier = 3, RequiredTiers = {1, 2}, Service = "Exp Potion"},
    },
    Crates = {} -- Placeholder, will be populated dynamically
}

local HIDDEN_ITEMS = {
    Accessories = {"Ghost", "Pumpkin Head", "Tri Tooth", "Tri Foot", "Tri Eyes", "Tri Ton"},
    Pets = {"I.N.D.E.X", "Spooksy", "Spooplet", "Lordfang", "Batkin", "Flame", "Mega Flame", "Turbo Flame", "Ultra Flame", "I2Pet", "Present"},
    Secrets = {"Banananananananito Bandito", "Tung Tung Tung Tung Tung Tung Tung..", "Los Tralaleritos", "Los Karkerkirkursitos", "OMEGA Sahur", "Anpali Babel", "Skull Skull Skull Sahur", "Prestige Skull Skull Skull Sahur", "Shimpanzini Bananini Priestini", "Frappochino Assassino", "Prestige Frappochino Assassino", "I2PERFECTINI FOXININI", "67", "Ban Ban Ban Sahur", "Prestige Ban Ban Sahur", "Santanzelli Trulala"},
    Crates = {"Spooky Crate", "i2Perfect Crate"},
}

local ITEM_PREFIXES = {
    Inventory = "📦 ",
    Equipped = "🔒 ",
    InTrade = "🔄 ",
    Wikipedia = "📖 ",
    Dupe = "✨ ",
}

-- ========================================== --
-- 🛠️ Utility Functions
-- ========================================== --
local Utils = {}

function Utils.IsTradeActive()
    local Windows = LocalPlayer.PlayerGui:FindFirstChild("Windows")
    if not Windows then return false end
    
    local activeWindows = {"TradingFrame", "AreYouSure", "AreYouSureSecret", "AmountSelector"}
    for _, winName in ipairs(activeWindows) do
        local frame = Windows:FindFirstChild(winName)
        if frame and frame.Visible then return true end
    end
    return false
end

function Utils.IsHidden(name, category)
    local list = HIDDEN_ITEMS[category]
    if not list then return false end
    for _, hiddenName in pairs(list) do
        if hiddenName == name then return true end
    end
    return false
end

function Utils.CheckIsEquipped(guid, name, category, allData)
    if category == "Secrets" then
        return (allData.MonsterService.EquippedMonster == name)
    end
    if not guid then return false end
    if category == "Pets" then
        for _, eqGuid in pairs(allData.PetsService.EquippedPets or {}) do
            if eqGuid == guid then return true end
        end
    elseif category == "Accessories" then
        for _, eqGuid in pairs(allData.AccessoryService.EquippedAccessories or {}) do
            if eqGuid == guid then return true end
        end
    end
    return false
end

function Utils.GetItemDetails(info, category)
    if type(info) ~= "table" then return "" end
    local details = ""
    if category == "Pets" then
        local evo = tonumber(info.Evolution)
        if evo and evo > 0 then details = details .. " " .. string.rep("⭐", evo) end
        if info.Level then details = details .. " Lv." .. info.Level end
    elseif category == "Accessories" then
        if info.Scroll and info.Scroll.Name then
            details = details .. " [" .. info.Scroll.Name .. "]"
        end
    end
    if info.Shiny or info.Golden then details = details .. " [✨]" end
    return details
end

function Utils.SanitizeNumberInput(textBox, maxValue, minValue)
    local connection
    connection = textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local txt = textBox.Text
        if txt == "" then return end
        local numStr = txt:gsub("%D", "")
        if numStr == "" then
            textBox.Text = tostring(minValue or 1)
            return
        end
        if txt ~= numStr then
            textBox.Text = numStr
            return
        end
        local n = tonumber(numStr)
        if n then
            if minValue and n < minValue then
                textBox.Text = tostring(minValue)
                return
            end
            if maxValue and n > maxValue then
                textBox.Text = tostring(maxValue)
                return
            end
        end
    end)
    return connection
end

-- ========================================== --
-- 🎨 UI Component Factory
-- ========================================== --
local UIFactory = {}

function UIFactory.CreateButton(props)
    local btn = Instance.new("TextButton")
    btn.Size = props.Size or UDim2.new(0, 100, 0, 30)
    btn.Position = props.Position or UDim2.new(0, 0, 0, 0)
    btn.Text = props.Text or ""
    btn.BackgroundColor3 = props.BgColor or THEME.BtnDefault
    btn.BackgroundTransparency = props.BgTransparency or 0
    btn.TextColor3 = props.TextColor or THEME.TextWhite
    btn.Font = props.Font or Enum.Font.Gotham
    btn.TextSize = props.TextSize or 12
    btn.TextXAlignment = props.TextXAlign or Enum.TextXAlignment.Center
    btn.Parent = props.Parent
    
    if props.Corner ~= false then
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, props.CornerRadius or CONFIG.CORNER_RADIUS)
    end
    if props.OnClick then btn.MouseButton1Click:Connect(props.OnClick) end
    return btn
end

function UIFactory.CreateLabel(props)
    local lbl = Instance.new("TextLabel")
    lbl.Size = props.Size or UDim2.new(1, 0, 0, 30)
    lbl.Position = props.Position or UDim2.new(0, 0, 0, 0)
    lbl.Text = props.Text or ""
    lbl.BackgroundTransparency = props.BgTransparency or 1
    lbl.TextColor3 = props.TextColor or THEME.TextWhite
    lbl.Font = props.Font or Enum.Font.Gotham
    lbl.TextSize = props.TextSize or 12
    lbl.TextXAlignment = props.TextXAlign or Enum.TextXAlignment.Center
    lbl.Parent = props.Parent
    return lbl
end

function UIFactory.CreateFrame(props)
    local frame = Instance.new("Frame")
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = props.BgColor or THEME.PanelBg
    frame.BackgroundTransparency = props.BgTransparency or THEME.PanelTransparency
    frame.Parent = props.Parent
    if props.Corner ~= false then
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, props.CornerRadius or CONFIG.CORNER_RADIUS)
    end
    if props.Stroke then
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = props.StrokeColor or Color3.fromRGB(60, 60, 70)
        stroke.Thickness = props.StrokeThickness or 1.5
        stroke.Transparency = props.StrokeTransparency or 0.4
    end
    return frame
end

function UIFactory.CreateScrollingFrame(props)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = props.Size or UDim2.new(1, -10, 1, -35)
    scroll.Position = props.Position or UDim2.new(0, 5, 0, 30)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = props.ScrollBarThickness or 3
    scroll.Parent = props.Parent
    
    if props.UseGrid then
        local layout = Instance.new("UIGridLayout", scroll)
        layout.CellPadding = UDim2.new(0, 5, 0, 5)
        layout.CellSize = UDim2.new(0, 90, 0, 110)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    else
        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0, props.Padding or CONFIG.LIST_PADDING)
        layout.HorizontalAlignment = props.HAlign or Enum.HorizontalAlignment.Center
    end
    
    return scroll
end

function UIFactory.AddCorner(instance, radius)
    local corner = Instance.new("UICorner", instance)
    corner.CornerRadius = UDim.new(0, radius or CONFIG.CORNER_RADIUS)
    return corner
end

function UIFactory.AddStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke", instance)
    stroke.Color = color or Color3.fromRGB(60, 60, 70)
    stroke.Thickness = thickness or 1.5
    stroke.Transparency = transparency or 0.4
    return stroke
end

function UIFactory.MakeDraggable(topBar, object)
    local dragging, dragInput, dragStart, startPosition
    local function update(input)
        local delta = input.Position - dragStart
        object.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

-- ========================================== --
-- 📊 State Manager
-- ========================================== --
local StateManager = {
    currentMainTab = "Players",
    currentSubTab = "Pets",
    currentDupeTab = "Scrolls",
    itemsInTrade = {},
    selectedCrates = {}, 
    playerButtons = {},
    statusResetTask = nil,
    inputConnection = nil,
}

function StateManager:SetStatus(text, color, statusLabel)
    if self.statusResetTask then task.cancel(self.statusResetTask) end
    statusLabel.Text = text
    statusLabel.TextColor3 = color or THEME.TextGray
    self.statusResetTask = task.delay(CONFIG.STATUS_RESET_DELAY, function()
        statusLabel.Text = "Ready."
        statusLabel.TextColor3 = THEME.TextGray
    end)
end

function StateManager:ResetTrade()
    self.itemsInTrade = {}
    self.selectedCrates = {}
end

function StateManager:AddToTrade(key, itemData)
    if not self.itemsInTrade[key] then
        self.itemsInTrade[key] = {
            Name = itemData.Name, Amount = 0, Guid = itemData.Guid,
            Service = itemData.Service, Category = itemData.Category,
            Type = itemData.Type, RawInfo = itemData.RawInfo
        }
    end
    self.itemsInTrade[key].Amount = self.itemsInTrade[key].Amount + (itemData.Amount or 1)
end

function StateManager:RemoveFromTrade(key)
    self.itemsInTrade[key] = nil
end

function StateManager:IsInTrade(key)
    return self.itemsInTrade[key] ~= nil
end

function StateManager:ToggleCrateSelection(name, amount)
    if self.selectedCrates[name] then
        self.selectedCrates[name] = nil
        return false 
    else
        self.selectedCrates[name] = amount
        return true 
    end
end

-- ========================================== --
-- 🔄 Trade Manager
-- ========================================== --
local TradeManager = {}
TradeManager.IsProcessing = false 

function TradeManager.ForceTradeWith(targetPlayer, statusLabel)
    if not targetPlayer then return end
    if TradeManager.IsProcessing or Utils.IsTradeActive() then return end
    TradeManager.IsProcessing = true 

    StateManager:SetStatus("🚀 Requesting trade...", THEME.PlayerBtn, statusLabel)
    TradingService:InitializeNewTrade(targetPlayer.UserId):andThen(function(result)
        TradeManager.IsProcessing = false 
        if result then
            pcall(function() TradeController:OnTradeRequestAccepted(targetPlayer.UserId) end)
            if debug and debug.setupvalue then
                pcall(function()
                    local func = TradeController.AddToTradeData
                    debug.setupvalue(func, 4, LocalPlayer.UserId) 
                end)
            end
            StateManager:SetStatus("✅ Request sent!", THEME.Success, statusLabel)
        else
            StateManager:SetStatus("❌ Failed (Cooldown/Busy).", THEME.ItemEquip, statusLabel)
        end
    end)
end

function TradeManager.SendTradeSignal(action, itemData, amount, statusLabel, callbacks)
    if not Utils.IsTradeActive() then
        StateManager:SetStatus("⚠️ Trade Menu NOT open!", THEME.ItemEquip, statusLabel)
        return
    end
    
    -- ตรวจสอบว่าเป็นการเรียกจากหน้า Dupe หรือหน้า Trade ปกติ
    local isDupeMode = (StateManager.currentMainTab == "Dupe")
    
    local success, fakeBtn = pcall(function()
        local btn = Instance.new("ImageButton")
        -- ใช้ GUID หรือชื่อ + Timestamp เพื่อให้ชื่อปุ่มไม่ซ้ำกันเด็ดขาด (แก้ปัญหา InTrade ยกแผง)
        local uniqueId = itemData.Guid or (itemData.Name .. "_" .. tick())
        btn.Name = "TradeItem_" .. uniqueId
        btn.Visible = false
        btn.Size = UDim2.new(0, 100, 0, 100)
        btn.BackgroundTransparency = 1
        
        -- [[ 1. Basic Attributes ]]
        btn:SetAttribute("Service", itemData.Service)
        btn:SetAttribute("Index", itemData.Name) 
        btn:SetAttribute("Quantity", amount)
        btn:SetAttribute("IsEquipped", false)
        
        -- [[ 2. Special Logic for Crates (แยกประเภท Dupe กับ Real) ]]
        if itemData.Category == "Crates" then
             btn:SetAttribute("ItemName", itemData.Name)
             btn:SetAttribute("Name", itemData.Name)
             btn:SetAttribute("Amount", amount)
             btn:SetAttribute("Service", "CratesService")
             
             -- ถ้าเป็นโหมด Dupe (เสกกล่องที่ไม่มีในตัว) ให้เพิ่ม Tag พิเศษ
             -- เพื่อให้ระบบจำลอง (Fake) ทำงานแยกจากระบบ Hidden Trade
             if isDupeMode then
                 btn:SetAttribute("IsFakeDupe", true)
             else
                 btn:SetAttribute("IsHiddenTrade", true)
             end
        end

        -- [[ 3. Handling GUID (สำหรับ Accessory/Pets) ]]
        -- สำคัญมาก: ถ้าเป็นไอเทมจริงต้องมี GUID เพื่อให้ระบบระบุตัวชิ้นนั้นๆ ได้
        if itemData.Guid then 
            btn:SetAttribute("Guid", tostring(itemData.Guid)) 
        end

        -- [[ 4. Extra Info ]]
        if itemData.RawInfo then
            if itemData.RawInfo.Evolution then btn:SetAttribute("Evolution", itemData.RawInfo.Evolution) end
            if itemData.RawInfo.Shiny then btn:SetAttribute("Shiny", true) end
            if itemData.RawInfo.Golden then btn:SetAttribute("Golden", true) end
        end
        
        game:GetService("CollectionService"):AddTag(btn, "Tradeable")
        btn.Parent = LocalPlayer:WaitForChild("PlayerGui")
        return btn
    end)
    
    if not success or not fakeBtn then
        StateManager:SetStatus("❌ Failed to create signal!", THEME.ItemEquip, statusLabel)
        return
    end
    
    -- [[ 5. Execute Action ]]
    pcall(function()
        -- ใช้ GUID เป็น Key ถ้าไม่มี (กรณีกล่อง) ให้ใช้ชื่อไอเทมแทน
        local key = itemData.Guid or itemData.Name
        
        if action == "Add" then
            TradeController:AddToTradeData(fakeBtn, amount)
            StateManager:AddToTrade(key, itemData)
            
            local modePrefix = isDupeMode and "✨ Dupe: " or "✅ Added: "
            StateManager:SetStatus(modePrefix .. itemData.Name, THEME.ItemInv, statusLabel)
        elseif action == "Remove" then
            TradeController:RemoveFromTradeData(fakeBtn, amount)
            StateManager:RemoveFromTrade(key)
            StateManager:SetStatus("🗑️ Removed: " .. itemData.Name, THEME.ItemEquip, statusLabel)
        end
    end)
    
    -- ทำลายปุ่มจำลองทิ้งหลังจากส่งสัญญาณเสร็จ
    task.delay(0.5, function() 
        if fakeBtn and fakeBtn.Parent then 
            fakeBtn:Destroy() 
        end 
    end)
    
    -- รัน Callback เพื่ออัปเดต UI หน้าจอของเรา
    if callbacks then
        if callbacks.UpdateTradeViewer then callbacks.UpdateTradeViewer() end
        if callbacks.RefreshInventory then callbacks.RefreshInventory() end
    end
end

function TradeManager.GetGameTradeId()
    local success, tradeId = pcall(function()
        local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
        local TradeController = Knit.GetController("TradeController")
        if debug and debug.getupvalues then
            local upvalues = debug.getupvalues(TradeController.AddToTradeData)
            for i, v in pairs(upvalues) do
                if type(v) == "number" and v > 1000 then return v end
            end
        end
    end)
    return (success and tradeId) or nil
end

function TradeManager.ExecuteMagicDupe(recipe, statusLabel, amount) 
    if TradeManager.IsProcessing or not Utils.IsTradeActive() then 
        if not Utils.IsTradeActive() then
            StateManager:SetStatus("⚠️ Open Trade Menu first!", THEME.Fail, statusLabel)
        end
        return 
    end

    local replica = ReplicaListener:GetReplica()
    local playerData = replica and replica.Data
    if not playerData or not playerData.ItemsService then 
        StateManager:SetStatus("❌ Data Error!", THEME.Fail, statusLabel)
        return 
    end

    local targetTier = tonumber(recipe.Tier)
    local serviceName = recipe.Service
    local itemsInv = playerData.ItemsService.Inventory
    local serviceData = itemsInv and itemsInv[serviceName]

    if serviceData then
        local ownedAmt = serviceData[tostring(targetTier)] or serviceData[targetTier] or 0
        if ownedAmt > 0 then
            StateManager:SetStatus("❌ Owned: You already have this!", THEME.Fail, statusLabel)
            return
        end
    end

    local realTradeId = TradeManager.GetGameTradeId()
    if not realTradeId then
        warn("⚠️ Memory scan failed, using UI fallback...")
        local targetIds = {LocalPlayer.UserId}
        pcall(function()
            local TradingFrame = LocalPlayer.PlayerGui.Windows:FindFirstChild("TradingFrame")
            if TradingFrame then
                for _, v in pairs(TradingFrame:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Visible and #v.Text > 2 then
                        for _, p in pairs(game.Players:GetPlayers()) do
                            if p ~= LocalPlayer and (v.Text:find(p.Name) or v.Text:find(p.DisplayName)) then
                                table.insert(targetIds, p.UserId)
                                break
                            end
                        end
                    end
                end
            end
        end)
        realTradeId = targetIds
    end

    local tradingService = ReplicatedStorage.Packages.Knit.Services.TradingService
    local remote = tradingService.RF:FindFirstChild("UpdateTradeOffer")

    local function sendUpdate(payload)
        local data = {
            MonsterService = {}, CratesService = {}, Currencies = {},
            PetsService = {}, AccessoryService = {},
            ItemsService = { [serviceName] = payload }
        }
        if type(realTradeId) == "table" then
            for _, id in pairs(realTradeId) do
                task.spawn(function() pcall(function() remote:InvokeServer(id, data) end) end)
            end
        else
            pcall(function() remote:InvokeServer(realTradeId, data) end)
        end
    end

    TradeManager.IsProcessing = true 
    local WAIT_TIME = 1.3 

    task.spawn(function()
        if recipe.Name == "White Strawberry" then
            StateManager:SetStatus("⏳ Step 1: Baiting (T2 x2)...", THEME.PlayerBtn, statusLabel)
            sendUpdate({ [2] = 2 })
            task.wait(WAIT_TIME)
            StateManager:SetStatus("🧪 Step 2: Injecting (T1 x" .. amount .. ")...", THEME.BtnDupe, statusLabel)
            sendUpdate({ amount, 1 })
        elseif StateManager.currentDupeTab == "Potions" then
            local baits = {}
            for _, req in ipairs(recipe.RequiredTiers) do baits[tonumber(req)] = 1 end
            local finalPayload = {}
            for k, v in pairs(baits) do finalPayload[k] = v end
            finalPayload[targetTier] = amount

            StateManager:SetStatus("⏳ Step 1: Baiting...", THEME.PlayerBtn, statusLabel)
            sendUpdate(baits)
            task.wait(WAIT_TIME)
            StateManager:SetStatus("🧪 Step 2: Injecting...", THEME.BtnDupe, statusLabel)
            sendUpdate(finalPayload)
        else
            local availableBaits = {}
            if serviceData then
                for _, reqTier in ipairs(recipe.RequiredTiers) do
                    local tNum = tonumber(reqTier)
                    if tNum > 2 and tNum ~= targetTier then 
                        local amt = serviceData[tostring(tNum)] or serviceData[tNum] or 0
                        if amt > 0 then table.insert(availableBaits, tNum) end
                    end
                end
            end
            table.sort(availableBaits, function(a, b) return a > b end)

            if #availableBaits < 2 then
                StateManager:SetStatus("❌ Need 2 Baits (T3+)", THEME.Fail, statusLabel)
                TradeManager.IsProcessing = false; return
            end

            local t1, t2 = availableBaits[1], availableBaits[2]
            StateManager:SetStatus("⏳ 1/4: Place T" .. t1, THEME.PlayerBtn, statusLabel)
            sendUpdate({ [t1] = 1 })
            task.wait(WAIT_TIME)
            StateManager:SetStatus("⏳ 2/4: Add T" .. t2, THEME.PlayerBtn, statusLabel)
            sendUpdate({ [t1] = 1, [t2] = 1 }) 
            task.wait(WAIT_TIME)
            StateManager:SetStatus("✨ 3/4: SWAP to Target", THEME.BtnDupe, statusLabel)
            sendUpdate({ [targetTier] = amount, [t2] = 1 }) 
            task.wait(WAIT_TIME + 0.2)
            StateManager:SetStatus("🔥 4/4: Finishing...", THEME.Success, statusLabel)
            sendUpdate({ [targetTier] = amount })
        end

        StateManager:SetStatus("✅ Execution Complete!", THEME.Success, statusLabel)
        TradeManager.IsProcessing = false 
    end)
end

-- ========================================== --
-- 📋 Inventory Manager
-- ========================================== --
local InventoryManager = {}

function InventoryManager.GetPlayerData()
    local replica = ReplicaListener:GetReplica()
    if not replica then return nil end
    return replica.Data
end

function InventoryManager.HasItem(service, tier, playerData)
    if not playerData or not playerData.ItemsService then return false end
    local itemsInventory = playerData.ItemsService.Inventory
    if not itemsInventory then return false end
    local serviceData = itemsInventory[service]
    if not serviceData then return false end
    local amount = serviceData[tostring(tier)] or serviceData[tonumber(tier)] or 0
    return amount > 0
end

function InventoryManager.CollectItems(category, playerData)
    local items = {}
    local function addItem(name, amount, guid, typeStr, equipped, service, rawInfo, details)
        table.insert(items, {
            Name = name, Amount = amount, Guid = guid,
            Type = typeStr, Equipped = equipped, Service = service,
            RawInfo = rawInfo, Details = details
        })
    end
    
    if category == "Crates" then
        -- วนลูปเช็คกล่องในตัวละคร
        for name, amount in pairs(playerData.CratesService.Crates or {}) do
            -- [[ 🎯 จุดที่แก้ไข: กรองเฉพาะกล่องที่อยู่ใน HIDDEN_ITEMS เท่านั้น ]]
            if Utils.IsHidden(name, "Crates") and amount > 0 then
                -- ใช้ชื่อกล่องเป็น GUID ไปเลยเพราะกล่องไม่มีรหัสแยกชิ้น
                addItem(name, amount, name, "Crate", false, "CratesService", nil, "")
            end
        end
    elseif category == "Secrets" then
        if playerData.MonsterService.SavedMonsters then
            for guid, info in pairs(playerData.MonsterService.SavedMonsters) do
                local name = (type(info) == "table" and info.Name) or info
                if Utils.IsHidden(name, "Secrets") then
                    addItem(name, 1, guid, "Inventory", Utils.CheckIsEquipped(guid, name, "Secrets", playerData), "MonsterService", info, "")
                end
            end
        end
        if playerData.MonsterService.MonstersUnlocked then
            for _, name in pairs(playerData.MonsterService.MonstersUnlocked) do
                if Utils.IsHidden(name, "Secrets") then
                    addItem(name, 1, nil, "Wikipedia", Utils.CheckIsEquipped(nil, name, "Secrets", playerData), "MonsterService", nil, "")
                end
            end
        end
    else
        local path = (category == "Pets" and playerData.PetsService.Pets) or playerData.AccessoryService.Accessories
        local service = (category == "Pets" and "PetsService") or "AccessoryService"
        for guid, info in pairs(path or {}) do
            local name = (type(info) == "table" and info.Name) or info
            if Utils.IsHidden(name, category) then
                -- [[ 🛠️ จุดที่ต้องแก้: เปลี่ยนจากเลข 1 เป็นตัวแปร guid จริงๆ ]]
                addItem(
                    name, 
                    1, 
                    guid,  -- เดิมเป็นเลข 1 ทำให้ไอเทมทุกชิ้น ID ซ้ำกัน
                    "Normal", 
                    Utils.CheckIsEquipped(guid, name, category, playerData), 
                    service, 
                    info, 
                    Utils.GetItemDetails(info, category)
                )
            end
        end
    end
    table.sort(items, function(a, b)
        if a.Equipped ~= b.Equipped then return a.Equipped end
        if a.Type ~= b.Type then return a.Type == "Inventory" end
        return a.Name < b.Name
    end)
    return items
end

-- ========================================== --
-- 🎮 Main GUI Controller
-- ========================================== --
local GUI = {}

function GUI:Initialize()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = CONFIG.GUI_NAME
    self.ScreenGui.Parent = CoreGui
    self.ScreenGui.DisplayOrder = 100
    self.ScreenGui.IgnoreGuiInset = true
    
    self:CreateMiniIcon()
    self:CreateMainWindow()
    self:SetupKeybind()
    self:StartMonitoring()
end

function GUI:CreateMiniIcon()
    self.MiniIcon = UIFactory.CreateButton({
        Size = CONFIG.MINI_ICON_SIZE,
        Position = UDim2.new(0, 20, 0.5, -25),
        BgColor = THEME.MainBg,
        Text = "T",
        TextColor = THEME.BtnSelected,
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        Parent = self.ScreenGui,
        Corner = true,
        CornerRadius = 10,
        OnClick = function() self:ToggleWindow("Open") end
    })
    self.MiniIcon.Visible = false
    self.MiniIcon.Active = true
    UIFactory.AddStroke(self.MiniIcon, THEME.BtnSelected, 2)
    UIFactory.MakeDraggable(self.MiniIcon, self.MiniIcon)
end

function GUI:CreateMainWindow()
    self.MainFrame = UIFactory.CreateFrame({
        Size = CONFIG.MAIN_WINDOW_SIZE,
        Position = UDim2.new(0.5, -400, 0.5, -250),
        BgColor = THEME.MainBg,
        BgTransparency = THEME.MainTransparency,
        Parent = self.ScreenGui,
        Stroke = true
    })
    self.MainFrame.Active = true
    
    self:CreateTitleBar()
    self:CreateStatusBar()
    self:CreateSidebar()
    self:CreateCenterPanel()
    self:CreateRightPanel()
    self:CreatePopup()
    
    self:UpdateUIState()
end

function GUI:CreateTitleBar()
    local titleBar = UIFactory.CreateFrame({
        Size = UDim2.new(1, 0, 0, 40),
        BgColor = Color3.fromRGB(0, 0, 0),
        BgTransparency = 0.7,
        Parent = self.MainFrame,
        CornerRadius = 12
    })
    UIFactory.CreateLabel({
        Text = "  🎯 Universal Trader (V" .. CONFIG.VERSION .. ")",
        Size = UDim2.new(0.6, 0, 1, 0),
        TextXAlign = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = titleBar
    })
    UIFactory.CreateButton({
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        Text = "X",
        BgColor = THEME.ItemEquip,
        Font = Enum.Font.GothamBold,
        CornerRadius = 6,
        Parent = titleBar,
        OnClick = function() self.ScreenGui:Destroy() end
    })
    UIFactory.CreateButton({
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -70, 0, 5),
        Text = "-",
        BgColor = THEME.BtnMainTab,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        CornerRadius = 6,
        Parent = titleBar,
        OnClick = function() self:ToggleWindow("Minimize") end
    })
    UIFactory.MakeDraggable(titleBar, self.MainFrame)
end

function GUI:CreateStatusBar()
    self.StatusLabel = UIFactory.CreateLabel({
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 1, -25),
        Text = "Select a mode.",
        TextColor = THEME.TextGray,
        TextSize = 12,
        TextXAlign = Enum.TextXAlignment.Left,
        Parent = self.MainFrame
    })
end

function GUI:CreateSidebar()
    local sidebar = UIFactory.CreateFrame({
        Size = UDim2.new(0, CONFIG.SIDEBAR_WIDTH, 1, -80),
        Position = UDim2.new(0, 10, 0, 50),
        Parent = self.MainFrame
    })
    
    local mainMenuContainer = UIFactory.CreateFrame({
        Size = UDim2.new(1, 0, 0, 120),
        BgTransparency = 1,
        Parent = sidebar,
        Corner = false
    })
    
    local mainLayout = Instance.new("UIListLayout", mainMenuContainer)
    mainLayout.Padding = UDim.new(0, CONFIG.BUTTON_PADDING)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local padding = Instance.new("UIPadding", mainMenuContainer)
    padding.PaddingTop = UDim.new(0, 10)
    
    self.SubMenuFrame = UIFactory.CreateFrame({
        Size = UDim2.new(1, 0, 1, -130),
        Position = UDim2.new(0, 0, 0, 130),
        BgTransparency = 1,
        Parent = sidebar,
        Corner = false
    })
    self.SubMenuFrame.Visible = false
    
    local subLayout = Instance.new("UIListLayout", self.SubMenuFrame)
    subLayout.Padding = UDim.new(0, CONFIG.BUTTON_PADDING)
    subLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.8, 0, 0, 1)
    line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0.1, 0, 0, 125)
    line.Parent = sidebar
    
    self:CreateMainTabs(mainMenuContainer)
end

function GUI:CreateMainTabs(parent)
    self.MainTabButtons = {}
    local tabs = {
        {name = "Players", icon = "👥"},
        {name = "Trade", icon = "🎒"},
        {name = "Dupe", icon = "✨"}
    }
    
    for _, tab in ipairs(tabs) do
        local btn = UIFactory.CreateButton({
            Size = UDim2.new(0, 100, 0, 30),
            Text = tab.icon .. " " .. tab.name,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            CornerRadius = 6,
            Parent = parent,
            OnClick = function()
                StateManager.currentMainTab = tab.name
                self:UpdateUIState()
            end
        })
        self.MainTabButtons[tab.name] = btn
    end
end

function GUI:UpdateSubTabs()
    for _, child in pairs(self.SubMenuFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    self.SubTabButtons = {}
    
    local tabs = {}
    if StateManager.currentMainTab == "Trade" then
        tabs = {"Pets", "Secrets", "Accessories", "Crates"}
    elseif StateManager.currentMainTab == "Dupe" then
        tabs = {"Scrolls", "Tickets", "Potions", "Crates"} 
    end
    
    for _, tabName in ipairs(tabs) do
        local isSelected = (StateManager.currentMainTab == "Trade" and StateManager.currentSubTab == tabName) or
                           (StateManager.currentMainTab == "Dupe" and StateManager.currentDupeTab == tabName)
                           
        local btn = UIFactory.CreateButton({
            Size = UDim2.new(0, 100, 0, 25),
            Text = tabName,
            TextSize = 12,
            CornerRadius = 6,
            Parent = self.SubMenuFrame,
            OnClick = function()
                if StateManager.currentMainTab == "Trade" then
                    StateManager.currentSubTab = tabName
                else
                    StateManager.currentDupeTab = tabName
                end
                self:UpdateUIState()
            end
        })
        
        btn.BackgroundColor3 = isSelected and THEME.BtnSelected or THEME.BtnDefault
        btn.TextColor3 = isSelected and Color3.new(1,1,1) or THEME.TextGray
        
        self.SubTabButtons[tabName] = btn
    end
end

function GUI:CreateCenterPanel()
    self.InvFrame = UIFactory.CreateFrame({
        Size = UDim2.new(0.79, 0, 1, -80),
        Position = UDim2.new(0, 140, 0, 50),
        Parent = self.MainFrame
    })
    
    self.InvHeader = UIFactory.CreateLabel({
        Size = UDim2.new(1, 0, 0, 30),
        Text = "List",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = self.InvFrame
    })
    
    self.InvContainer, _ = UIFactory.CreateScrollingFrame({
        Parent = self.InvFrame,
        Size = UDim2.new(1, -10, 1, -35)
    })

    self.DupeWarning = UIFactory.CreateLabel({
        Size = UDim2.new(1, -20, 0, 55),
        Position = UDim2.new(0, 10, 1, -60), 
        Text = "",
        TextColor = Color3.fromRGB(255, 100, 100),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        Parent = self.InvFrame,
        Visible = false
    })
    self.DupeWarning.TextWrapped = true
end

function GUI:CreateRightPanel()
    self.TradeFrame = UIFactory.CreateFrame({
        Size = UDim2.new(0.35, 0, 1, -80),
        Parent = self.MainFrame
    })
    self.TradeFrame.Visible = false
    
    UIFactory.CreateLabel({
        Size = UDim2.new(1, 0, 0, 30),
        Text = "Current Offer",
        TextColor = THEME.ItemInv,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = self.TradeFrame
    })
    
    self.TradeContainer, _ = UIFactory.CreateScrollingFrame({
        Parent = self.TradeFrame,
        ScrollBarThickness = 0
    })
end

function GUI:CreatePopup()
    self.PopupFrame = UIFactory.CreateFrame({
        Size = UDim2.new(1, 0, 1, 0),
        BgColor = Color3.new(0, 0, 0),
        BgTransparency = 0.85,
        Parent = self.MainFrame,
        Corner = false
    })
    self.PopupFrame.Visible = false
    self.PopupFrame.ZIndex = 200
    
    local popupBox = UIFactory.CreateFrame({
        Size = UDim2.new(0, 200, 0, 120),
        Position = UDim2.new(0.5, -100, 0.5, -60),
        BgColor = THEME.MainBg,
        BgTransparency = 0.1,
        Parent = self.PopupFrame,
        CornerRadius = 8
    })
    UIFactory.AddStroke(popupBox, THEME.BtnSelected, 1, 0.3)
    
    self.PopupInput = Instance.new("TextBox")
    self.PopupInput.Size = UDim2.new(0.8, 0, 0, 30)
    self.PopupInput.Position = UDim2.new(0.1, 0, 0.3, 0)
    self.PopupInput.Text = "1"
    self.PopupInput.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    self.PopupInput.BackgroundTransparency = 0.5
    self.PopupInput.TextColor3 = Color3.new(1, 1, 1)
    self.PopupInput.Parent = popupBox
    UIFactory.AddCorner(self.PopupInput, 4)
    
    self.PopupConfirm = UIFactory.CreateButton({
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0.65, 0),
        Text = "Confirm",
        BgColor = THEME.BtnSelected,
        CornerRadius = 4,
        Parent = popupBox
    })
    
    UIFactory.CreateButton({
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0, 5),
        Text = "X",
        BgColor = THEME.ItemEquip,
        CornerRadius = 4,
        Parent = popupBox,
        OnClick = function() self.PopupFrame.Visible = false end
    })
end

function GUI:ShowQuantityPopup(itemData, onConfirm)
    self.PopupFrame.Visible = true
    local startValue = itemData.Default or 1
    local maxValue = itemData.Max or 999999
    
    self.PopupInput.Text = tostring(startValue)
    if StateManager.inputConnection then StateManager.inputConnection:Disconnect() end
    StateManager.inputConnection = Utils.SanitizeNumberInput(self.PopupInput, maxValue)
    
    local confirmConn
    confirmConn = self.PopupConfirm.MouseButton1Click:Connect(function()
        local quantity = tonumber(self.PopupInput.Text)
        if quantity and quantity > 0 and quantity <= maxValue then
            onConfirm(quantity)
            self.PopupFrame.Visible = false
            if StateManager.inputConnection then StateManager.inputConnection:Disconnect() end
        end
        confirmConn:Disconnect()
    end)
end

function GUI:ToggleWindow(state)
    if state == "Minimize" then
        self.MainFrame.Visible = false
        self.MiniIcon.Visible = true
    elseif state == "Open" then
        self.MainFrame.Visible = true
        self.MiniIcon.Visible = false
    elseif state == "Toggle" then
        if self.MainFrame.Visible then self:ToggleWindow("Minimize") else self:ToggleWindow("Open") end
    end
end

function GUI:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == CONFIG.TOGGLE_KEY then
            self:ToggleWindow("Toggle")
        end
    end)
end

function GUI:UpdateUIState()
    self:UpdateSubTabs()
    self.DupeWarning.Visible = false
    
    -- Reset Scroll Layout
    if self.InvContainer:FindFirstChild("UIGridLayout") then
        self.InvContainer:ClearAllChildren()
        local layout = Instance.new("UIListLayout", self.InvContainer)
        layout.Padding = UDim.new(0, CONFIG.LIST_PADDING)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    end
    self.InvContainer.Size = UDim2.new(1, -10, 1, -35)

    if StateManager.currentMainTab == "Players" then
        self.SubMenuFrame.Visible = false
        self.TradeFrame.Visible = false
        self.InvFrame.Size = UDim2.new(1, -150, 1, -80) 
        self.InvHeader.Text = "Server Players (Force Trade)"
        
    elseif StateManager.currentMainTab == "Trade" then
        self.SubMenuFrame.Visible = true
        self.TradeFrame.Visible = true
        self.InvFrame.Size = UDim2.new(0, 320, 1, -80) 
        self.TradeFrame.Position = UDim2.new(0, 140 + 320 + 10, 0, 50)
        self.TradeFrame.Size = UDim2.new(0, 320, 1, -80) 
        self.InvHeader.Text = "Selection List (" .. StateManager.currentSubTab .. ")"
        
    elseif StateManager.currentMainTab == "Dupe" then
        self.SubMenuFrame.Visible = true
        self.TradeFrame.Visible = false
        self.InvFrame.Size = UDim2.new(1, -150, 1, -80)
        self.InvHeader.Text = "✨ Magic Dupe (" .. StateManager.currentDupeTab .. ")"
        
        if StateManager.currentDupeTab == "Crates" then
            self.DupeWarning.Visible = false
        else
            self.DupeWarning.Visible = true
            self.InvContainer.Size = UDim2.new(1, -10, 1, -95)
            local limitInfo = ""
            if StateManager.currentDupeTab == "Scrolls" then limitInfo = "SCROLLS LIMIT: 1XX"
            elseif StateManager.currentDupeTab == "Tickets" then limitInfo = "TICKETS LIMIT: 10,000"
            elseif StateManager.currentDupeTab == "Potions" then limitInfo = "POTIONS & STRAWBERRY LIMIT: 2,000" end
            self.DupeWarning.Text = string.format("⚠️ WARNING: Do not exceed limits.\n%s TOTAL.\nRisk of ban if hoarding excessive amounts.", limitInfo)
        end
    end
    
    for name, btn in pairs(self.MainTabButtons) do
        local isSelected = (name == StateManager.currentMainTab)
        btn.BackgroundColor3 = isSelected and THEME.BtnMainTabSelected or THEME.BtnMainTab
        if name == "Dupe" and isSelected then btn.BackgroundColor3 = THEME.BtnDupe end 
        btn.TextColor3 = isSelected and Color3.new(1, 1, 1) or THEME.TextGray
    end
    
    self:RefreshInventory()
end

function GUI:RefreshInventory()
    for _, child in pairs(self.InvContainer:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then child:Destroy() end
    end
    
    if StateManager.currentMainTab == "Players" then
        self:RenderPlayersList()
    elseif StateManager.currentMainTab == "Trade" then
        self:RenderTradeItems()
    elseif StateManager.currentMainTab == "Dupe" then
        if StateManager.currentDupeTab == "Crates" then
            self:RenderCrateGrid()
        else
            self:RenderDupeMenu()
        end
    end
end

function GUI:RenderCrateGrid()
    self.InvContainer.ScrollBarThickness = 0
    self.InvContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    self.InvContainer.CanvasSize = UDim2.new(0, 0, 0, 0)     
    
    local replica = ReplicaListener:GetReplica()
    local playerData = replica and replica.Data
    local inventoryCrates = (playerData and playerData.CratesService and playerData.CratesService.Crates) or {}

    if self.InvContainer:FindFirstChild("UIListLayout") then self.InvContainer.UIListLayout:Destroy() end
    
    local layout = self.InvContainer:FindFirstChild("UIGridLayout")
    if not layout then
        layout = Instance.new("UIGridLayout", self.InvContainer)
        layout.CellPadding = UDim2.new(0, 10, 0, 10)
        layout.CellSize = UDim2.new(0, 80, 0, 100) 
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    end

    -- 1. กรองรายชื่อกล่องและเก็บทั้ง "Key ในระบบ" และ "ชื่อที่ใช้แสดง"
    local cratesList = {}
    for internalId, info in pairs(CratesInfo) do
        if type(info) == "table" then
            local displayName = info.Name or internalId
            if displayName ~= "KeKa Crate" then 
                table.insert(cratesList, {
                    DisplayName = displayName, 
                    InternalID = internalId, -- รหัสอ้างอิงภายใน (เช่น "Bronze")
                    Image = info.Image or "0"
                })
            end
        end
    end
    table.sort(cratesList, function(a, b) return a.DisplayName < b.DisplayName end)

    for _, crate in ipairs(cratesList) do
        -- [[ 🎯 จุดแก้ไขสำคัญ: ตรรกะการเช็คว่ามีอยู่ในระบบหรือไม่ (Double Check) ]]
        -- เช็คทั้งชื่อที่มี "Crate" ต่อท้าย และชื่อดิบๆ จาก ID
        local amountInInv = inventoryCrates[crate.DisplayName] or inventoryCrates[crate.InternalID]
        
        -- ถ้าค่าที่หาได้ไม่ใช่ nil (นับรวม 0) ให้ถือว่าเป็น OWNED
        local isOwnedInSystem = (amountInInv ~= nil)
        local isSelected = StateManager.selectedCrates[crate.DisplayName] ~= nil

        local Card = Instance.new("Frame")
        Card.Name = crate.DisplayName
        Card.Parent = self.InvContainer
        Card.BackgroundColor3 = isOwnedInSystem and Color3.fromRGB(25, 25, 30) or Color3.fromRGB(35, 35, 40)
        Card.BackgroundTransparency = isOwnedInSystem and 0.4 or 0
        UIFactory.AddCorner(Card, 6)
        
        -- สีขอบ: ถ้า Owned แล้วให้เป็นสีแดง/มืด เพื่อบอกว่าห้ามกด
        local strokeColor = Color3.fromRGB(55, 55, 60)
        if isOwnedInSystem then
            strokeColor = Color3.fromRGB(180, 40, 40) 
        elseif isSelected then
            strokeColor = THEME.CrateSelected
        end

        local stroke = UIFactory.AddStroke(Card, strokeColor, 1.5, isOwnedInSystem and 0.4 or 0.2)
        
        local Image = Instance.new("ImageLabel")
        Image.Parent = Card
        Image.BackgroundTransparency = 1
        Image.Position = UDim2.new(0, 5, 0, 12) 
        Image.Size = UDim2.new(1, -10, 0, 50)  
        Image.ImageTransparency = isOwnedInSystem and 0.5 or 0
        local imgId = tostring(crate.Image)
        if not imgId:find("rbxassetid://") then imgId = "rbxassetid://" .. imgId end
        Image.Image = imgId
        Image.ScaleType = Enum.ScaleType.Fit
        
        local NameLbl = Instance.new("TextLabel")
        NameLbl.Parent = Card
        NameLbl.BackgroundTransparency = 1
        NameLbl.Position = UDim2.new(0, 2, 0, 65) 
        NameLbl.Size = UDim2.new(1, -4, 0, 30)
        NameLbl.Font = Enum.Font.Gotham
        
        if isSelected then
            NameLbl.Text = crate.DisplayName .. "\n[x" .. StateManager.selectedCrates[crate.DisplayName] .. "]"
            NameLbl.TextColor3 = THEME.CrateSelected
        elseif isOwnedInSystem then
            -- แสดงผล (OWNED) กำกับเสมอถ้าตรวจพบในข้อมูล
            NameLbl.Text = crate.DisplayName .. "\n(OWNED)"
            NameLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
        else
            NameLbl.Text = crate.DisplayName
            NameLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        NameLbl.TextSize = 8 
        NameLbl.TextWrapped = true
        NameLbl.TextYAlignment = Enum.TextYAlignment.Top

        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Parent = Card
        ClickBtn.BackgroundTransparency = 1
        ClickBtn.Size = UDim2.new(1, 0, 1, 0)
        ClickBtn.Text = ""

        ClickBtn.MouseButton1Click:Connect(function()
            if not Utils.IsTradeActive() then
                StateManager:SetStatus("⚠️ Open Trade Menu first!", THEME.Fail, self.StatusLabel)
                return
            end

            -- [[ 🚫 บล็อคการส่งสัญญาณถ้ามีอยู่ในระบบ ]]
            if isOwnedInSystem then
                StateManager:SetStatus("🚫 Locked: This crate exists in your inventory history.", Color3.fromRGB(255, 80, 80), self.StatusLabel)
                return 
            end

            if StateManager.selectedCrates[crate.DisplayName] then
                local oldAmount = StateManager.selectedCrates[crate.DisplayName]
                StateManager:ToggleCrateSelection(crate.DisplayName, nil)
                TradeManager.SendTradeSignal("Remove", { Name = crate.DisplayName, Service = "CratesService", Category = "Crates" }, oldAmount, self.StatusLabel)
                self:RefreshInventory()
            else
                self:ShowQuantityPopup({Default = 50000, Max = 99999}, function(qty)
                    StateManager:ToggleCrateSelection(crate.DisplayName, qty)
                    TradeManager.SendTradeSignal("Add", { Name = crate.DisplayName, Service = "CratesService", Category = "Crates" }, qty, self.StatusLabel)
                    self:RefreshInventory()
                end)
            end
        end)
    end
end

function GUI:RenderDupeMenu()
    local recipes = DUPE_RECIPES[StateManager.currentDupeTab] or {}
    local playerData = InventoryManager.GetPlayerData()
    local yOffset = 0
    local isPotionTab = (StateManager.currentDupeTab == "Potions")
    
    for _, recipe in ipairs(recipes) do
        local recipeFrame = UIFactory.CreateFrame({
            Size = UDim2.new(1, 0, 0, 65),
            BgColor = Color3.fromRGB(30, 30, 35),
            Parent = self.InvContainer,
            CornerRadius = 6,
            Stroke = true,
            StrokeColor = Color3.fromRGB(60, 60, 70)
        })
        
        local displayIcon = "✨"
        local itemTypeSingular, itemTypePlural = "Item", "Items"
        local serviceName = recipe.Service
        
        if StateManager.currentDupeTab == "Scrolls" then
            displayIcon = "📜"; itemTypeSingular, itemTypePlural = "Scroll", "Scrolls"
        elseif StateManager.currentDupeTab == "Tickets" then
            displayIcon = "🎟️"; itemTypeSingular, itemTypePlural = "Ticket", "Tickets"
        elseif isPotionTab then
            displayIcon = (recipe.Name == "White Strawberry") and "🍓" or "🧪"
            itemTypeSingular, itemTypePlural = "Potion", "Potions"
        end
        
        UIFactory.CreateLabel({
            Size = UDim2.new(1, -120, 0, 25),
            Position = UDim2.new(0, 10, 0, 5),
            Text = displayIcon .. " " .. recipe.Name,
            TextXAlign = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor = THEME.BtnDupe,
            Parent = recipeFrame
        })
        
        local isOwned = false
        if playerData and playerData.ItemsService and playerData.ItemsService.Inventory then
            local inv = playerData.ItemsService.Inventory[serviceName]
            if inv then
                local amt = inv[tostring(recipe.Tier)] or inv[tonumber(recipe.Tier)] or 0
                if amt > 0 then isOwned = true end
            end
        end
        
        local totalNeeded, foundCount = 0, 0
        if isPotionTab then
            totalNeeded = #recipe.RequiredTiers
            for _, tier in ipairs(recipe.RequiredTiers) do
                if InventoryManager.HasItem(serviceName, tier, playerData) then foundCount = foundCount + 1 end
            end
        else
            totalNeeded = 2
            for _, tier in ipairs(recipe.RequiredTiers) do
                local tierNum = tonumber(tier)
                if tierNum > 2 and tierNum ~= tonumber(recipe.Tier) then
                    if InventoryManager.HasItem(serviceName, tierNum, playerData) then foundCount = foundCount + 1 end
                end
            end
        end
        
        local missingCount = totalNeeded - math.min(foundCount, totalNeeded)
        local statusText, statusColor = "", THEME.Success
        if isOwned then
            statusText = "Already Owned: Remove from inventory first"
            statusColor = THEME.Fail
        elseif missingCount > 0 then
            statusText = "Requires: " .. totalNeeded .. " other " .. (totalNeeded > 1 and itemTypePlural or itemTypeSingular) .. " (Missing: " .. missingCount .. ")"
            statusColor = THEME.Fail
        else
            statusText = "Ready to Dupe"
            statusColor = THEME.Success
        end
        
        UIFactory.CreateLabel({
            Size = UDim2.new(1, -120, 0, 20),
            Position = UDim2.new(0, 10, 0, 30),
            Text = statusText,
            TextXAlign = Enum.TextXAlignment.Left,
            TextSize = 11,
            TextColor = statusColor,
            Parent = recipeFrame
        })
        
        local canExecute = (not isOwned) and (missingCount == 0)
        UIFactory.CreateButton({
            Size = UDim2.new(0, 80, 0, 30),
            Position = UDim2.new(1, -90, 0.5, -15),
            Text = "DUPE",
            BgColor = canExecute and THEME.BtnDupe or THEME.BtnDisabled,
            TextColor = canExecute and THEME.TextWhite or THEME.TextDisabled,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            CornerRadius = 4,
            Parent = recipeFrame,
            OnClick = function()
                if TradeManager.IsProcessing then return end 
                if not Utils.IsTradeActive() then
                    StateManager:SetStatus("⚠️ Open Trade Menu first!", THEME.Fail, self.StatusLabel)
                    return
                end
                if isOwned then
                    StateManager:SetStatus("❌ You already have " .. recipe.Name, THEME.Fail, self.StatusLabel)
                    return
                end
                if canExecute then
                    local startVal, currentMax = 99, 100
                    if StateManager.currentDupeTab == "Scrolls" then startVal, currentMax = 99, 120
                    elseif StateManager.currentDupeTab == "Tickets" then startVal, currentMax = 5000, 10000 
                    elseif StateManager.currentDupeTab == "Potions" then startVal, currentMax = 500, 1000 end
                    self:ShowQuantityPopup({Default = startVal, Max = currentMax}, function(quantity)
                        TradeManager.ExecuteMagicDupe(recipe, self.StatusLabel, quantity)
                    end)
                end
            end
        })
        yOffset = yOffset + 70
    end
    self.InvContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function GUI:RenderPlayersList()
    StateManager.playerButtons = {}
    local isTrading = Utils.IsTradeActive()
    local count = 0
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = UIFactory.CreateButton({
                Size = UDim2.new(1, 0, 0, 35),
                BgColor = Color3.fromRGB(35, 35, 40),
                BgTransparency = 0.2,
                Text = "  👤 " .. plr.DisplayName .. " (@" .. plr.Name .. ")",
                TextColor = THEME.PlayerBtn,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlign = Enum.TextXAlignment.Left,
                CornerRadius = 6,
                Parent = self.InvContainer
            })
            local actionBtn = UIFactory.CreateButton({
                Size = UDim2.new(0, 80, 0, 25),
                Position = UDim2.new(1, -85, 0, 5),
                Text = "TRADE",
                BgColor = isTrading and THEME.BtnDisabled or THEME.BtnSelected,
                TextColor = isTrading and THEME.TextDisabled or THEME.TextWhite,
                Font = Enum.Font.GothamBold,
                CornerRadius = 4,
                Parent = btn
            })
            actionBtn.AutoButtonColor = not isTrading
            table.insert(StateManager.playerButtons, actionBtn)
            actionBtn:SetAttribute("OriginalColor", THEME.BtnSelected)
            actionBtn:SetAttribute("OriginalTextColor", THEME.TextWhite)
            actionBtn.MouseButton1Click:Connect(function()
                if Utils.IsTradeActive() then
                    StateManager:SetStatus("🔒 Trade is active! Finish it first.", THEME.ItemEquip, self.StatusLabel)
                    return
                end
                TradeManager.ForceTradeWith(plr, self.StatusLabel)
            end)
            count = count + 1
        end
    end
    self.InvContainer.CanvasSize = UDim2.new(0, 0, 0, count * 38)
end

function GUI:RenderTradeItems()
    local playerData = InventoryManager.GetPlayerData()
    if not playerData then return end
    local items = InventoryManager.CollectItems(StateManager.currentSubTab, playerData)
    
    for _, item in ipairs(items) do
        local key = item.Guid or item.Name
        local inTrade = StateManager:IsInTrade(key)
        local prefix, textColor, bgColor, tag = ITEM_PREFIXES.Inventory, THEME.ItemInv, Color3.fromRGB(30, 35, 40), ""
        
        if item.Equipped then
            prefix, textColor, bgColor, tag = ITEM_PREFIXES.Equipped, THEME.ItemEquip, Color3.fromRGB(50, 20, 20), " [EQUIPPED]"
        elseif inTrade then
            prefix, textColor, bgColor, tag = ITEM_PREFIXES.InTrade, THEME.ItemInTrade, Color3.fromRGB(60, 50, 20), " [IN TRADE]"
        elseif item.Type == "Wikipedia" then
            prefix, textColor, bgColor = ITEM_PREFIXES.Wikipedia, THEME.ItemWiki, Color3.fromRGB(35, 30, 50)
        end
        local showAmt = (item.Amount > 1) and (" [x" .. item.Amount .. "]") or ""
        
        local btn = UIFactory.CreateButton({
            Size = UDim2.new(1, 0, 0, 35),
            Text = " " .. prefix .. item.Name .. (item.Details or "") .. tag .. showAmt,
            TextColor = textColor,
            BgColor = bgColor,
            BgTransparency = 0.4,
            TextSize = 13,
            TextXAlign = Enum.TextXAlignment.Left,
            CornerRadius = 6,
            Parent = self.InvContainer
        })
        
        if not item.Equipped then
            btn.MouseButton1Click:Connect(function()
                local itemData = {
                    Name = item.Name, Guid = item.Guid, Service = item.Service,
                    Category = StateManager.currentSubTab, Type = item.Type, RawInfo = item.RawInfo
                }
                if inTrade then
                    TradeManager.SendTradeSignal("Remove", itemData, StateManager.itemsInTrade[key].Amount, self.StatusLabel, {
                        UpdateTradeViewer = function() self:UpdateTradeViewer() end,
                        RefreshInventory = function() self:RefreshInventory() end
                    })
                else
                    if StateManager.currentSubTab == "Crates" and item.Amount > 1 then
                        item.Max = item.Amount 
                        self:ShowQuantityPopup(item, function(quantity)
                            itemData.Amount = quantity 
                            TradeManager.SendTradeSignal("Add", itemData, quantity, self.StatusLabel, {
                                UpdateTradeViewer = function() self:UpdateTradeViewer() end,
                                RefreshInventory = function() self:RefreshInventory() end
                            })
                        end)
                    else
                        TradeManager.SendTradeSignal("Add", itemData, 1, self.StatusLabel, {
                            UpdateTradeViewer = function() self:UpdateTradeViewer() end,
                            RefreshInventory = function() self:RefreshInventory() end
                        })
                    end
                end
            end)
        end
    end
    self.InvContainer.CanvasSize = UDim2.new(0, 0, 0, #items * 38)
end

function GUI:UpdateTradeViewer()
    for _, child in pairs(self.TradeContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local sorted = {}
    for _, item in pairs(StateManager.itemsInTrade) do table.insert(sorted, item) end
    table.sort(sorted, function(a, b) return a.Name < b.Name end)
    
    for _, item in ipairs(sorted) do
        local text = " 🔻 " .. item.Name
        if item.RawInfo then
            if item.RawInfo.Evolution and tonumber(item.RawInfo.Evolution) > 0 then text = text .. " " .. string.rep("⭐", item.RawInfo.Evolution) end
            if item.RawInfo.Shiny then text = text .. " [✨]" end
        end
        if item.Category == "Crates" then text = text .. " [x" .. item.Amount .. "]" end
        
        UIFactory.CreateButton({
            Size = UDim2.new(1, 0, 0, 35),
            Text = text,
            BgColor = Color3.fromRGB(40, 30, 30),
            BgTransparency = 0.3,
            TextColor = Color3.fromRGB(255, 150, 150),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlign = Enum.TextXAlignment.Left,
            CornerRadius = 6,
            Parent = self.TradeContainer,
            OnClick = function()
                TradeManager.SendTradeSignal("Remove", item, item.Amount, self.StatusLabel, {
                    UpdateTradeViewer = function() self:UpdateTradeViewer() end,
                    RefreshInventory = function() self:RefreshInventory() end
                })
            end
        })
    end
    self.TradeContainer.CanvasSize = UDim2.new(0, 0, 0, #sorted * 38)
end

function GUI:UpdatePlayerButtonStates()
    local tradeActive = Utils.IsTradeActive()
    for _, btn in pairs(StateManager.playerButtons) do
        if btn and btn.Parent then
            if tradeActive then
                btn.BackgroundColor3 = THEME.BtnDisabled
                btn.TextColor3 = THEME.TextDisabled
                btn.AutoButtonColor = false
            else
                if btn:GetAttribute("OriginalColor") then btn.BackgroundColor3 = btn:GetAttribute("OriginalColor") end
                if btn:GetAttribute("OriginalTextColor") then btn.TextColor3 = btn:GetAttribute("OriginalTextColor") end
                btn.AutoButtonColor = true
            end
        end
    end
end

function GUI:StartMonitoring()
    task.spawn(function()
        local missingCounter = 0
        while self.ScreenGui.Parent do
            self:UpdatePlayerButtonStates()
            if Utils.IsTradeActive() then
                missingCounter = 0
            else
                missingCounter = missingCounter + 1
            end
            if missingCounter > CONFIG.TRADE_RESET_THRESHOLD then
                TradeManager.IsProcessing = false 
                if next(StateManager.itemsInTrade) ~= nil then
                    StateManager:ResetTrade()
                    StateManager:SetStatus("Trade closed → Reset.", THEME.TextGray, self.StatusLabel)
                    self:UpdateTradeViewer()
                    self:RefreshInventory()
                end
            end
            task.wait(CONFIG.BUTTON_CHECK_INTERVAL)
        end
    end)
    Players.PlayerAdded:Connect(function() if StateManager.currentMainTab == "Players" then self:RefreshInventory() end end)
    Players.PlayerRemoving:Connect(function() if StateManager.currentMainTab == "Players" then self:RefreshInventory() end end)
end

-- ========================================== --
-- 🚀 Initialize
-- ========================================== --
local app = GUI
app:Initialize()

print("✅ Universal Trade System V" .. CONFIG.VERSION .. " loaded successfully!")
