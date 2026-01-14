script_properties('work-in-pause')

local samp = require('samp.events')
local effil = require('effil')
local inicfg = require('inicfg')
local ffi = require('ffi')
local SCRIPT_VERSION = "0.1.2" -- Òåêóùàÿ âåðñèÿ âàøåãî ñêðèïòà

local imgui = require('mimgui')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Ïðåäïîëàãàåì, ÷òî èìÿ ôàéëà ñêðèïòà - Item.lua
local SCRIPT_CONFIG_NAME = 'Item'
local SCRIPT_CONFIG_FILENAME = SCRIPT_CONFIG_NAME .. '.ini'

-- Äîáàâëÿåì ñïèñêè ïðåäìåòîâ èç âòîðîãî ñêðèïòà
local items = {
    1811,
    555,
    1425,
    522,
	4344,
	5991,
	1146,
	731,
	9726.,
}

local items_name = {
    [1811] = "Bitcoin (BTC)",
    [555] = "Áðîíçîâàÿ ðóëåòêà",
    [1425] = "Ïëàòèíîâàÿ ðóëåòêà",
    [522] = "Ñåìåéíûé òàëîí",
	[4344] = "Òàëîí +1 EXP ",
	[5991] = "Ãðóíò",
    [1146] = "Ãðàæäàíñêèé òàëîí",
	[731] = "Àz-Coins",
	[9726] = "Ëîòåðåéíûé áèëåò 2ê26",
}

-- Ôóíêöèÿ äëÿ ïðîâåðêè íàëè÷èÿ ýëåìåíòà â òàáëèöå
local function tableIncludes(self, value)
    for _, v in pairs(self) do
        if v == value then
            return true
        end
    end
    return false
end

local cfg = inicfg.load({
    config = {
        chat = '',
        token = '',
        itemAdding = false
    }
}, SCRIPT_CONFIG_NAME) -- Èçìåíåíî íà SCRIPT_CONFIG_NAME

local chat = imgui.new.char[128](tostring(cfg.config.chat))
local token = imgui.new.char[128](tostring(cfg.config.token))

local itemAdding = imgui.new.bool(cfg.config.itemAdding)

local window = imgui.new.bool(false)

function main()
    while not isSampAvailable() do wait(0) end
    sampAddChatMessage('[telegram truck] {ffffff}Àêòèâàöèÿ: /item', 0x3083ff)
    sampRegisterChatCommand('item', function() window[0] = not window[0] end)
    wait(-1)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
end)

local newFrame = imgui.OnFrame(
    function() return window[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 300, 180
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.Begin('telegram truck111', window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        if imgui.InputText(u8('ÈÄ ×àò'), chat, ffi.sizeof(chat), imgui.InputTextFlags.Password) then
            cfg.config.chat = ffi.string(chat)
            inicfg.save(cfg, SCRIPT_CONFIG_FILENAME) -- Èçìåíåíî íà SCRIPT_CONFIG_FILENAME
        end
        if imgui.InputText(u8('Òîêåí'), token, ffi.sizeof(token), imgui.InputTextFlags.Password) then
            cfg.config.token = ffi.string(token)
            inicfg.save(cfg, SCRIPT_CONFIG_FILENAME) -- Èçìåíåíî íà SCRIPT_CONFIG_FILENAME
        end

        if imgui.Checkbox(u8('Äîáàâëåíèå 1111'), itemAdding) then
            cfg.config.itemAdding = itemAdding[0]
            inicfg.save(cfg, SCRIPT_CONFIG_FILENAME) -- Èçìåíåíî íà SCRIPT_CONFIG_FILENAME
        end
        imgui.End()
    end
)

local effilTelegramSendMessage = effil.thread(function(text, chatID, token)
    local requests = require('requests')
    -- Èñïîëüçóåì url_encode äëÿ ïðàâèëüíîé ïåðåäà÷è äàííûõ
    requests.post(('https://api.telegram.org/bot%s/sendMessage'):format(token), {
        params = {
            text = text,
            chat_id = chatID,
        }
    })
end)

-- Ôóíêöèÿ url_encode èç âòîðîãî ñêðèïòà
function url_encode(text)
    local text = string.gsub(text, "([^%w-_ %.~=])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return string.gsub(text, " ", "+")
end

function sendTelegramMessage(text)
    -- Ïðîâåðÿåì, ÷òî ÷àò ID è òîêåí íå ïóñòûå
    local chat_id_str = ffi.string(chat)
    local token_str = ffi.string(token)

    if chat_id_str == '' or token_str == '' then
        print('[telegram truck] Îøèáêà: ID ÷àòà èëè òîêåí Telegram íå óñòàíîâëåíû.')
        return
    end

    local text_to_send = text:gsub('{......}', '') -- Óáèðàåì öâåòîâûå êîäû, åñëè îíè åñòü
    effilTelegramSendMessage(url_encode(u8(text_to_send)), chat_id_str, token_str)
end

function samp.onServerMessage(color, text)
    -- Ïðîâåðÿåì, âêëþ÷åíî ëè äîáàâëåíèå ïðåäìåòîâ è ñîâïàäàåò ëè ñîîáùåíèå
    if color == -65281 and text:find("^Âàì áûë äîáàâëåí ïðåäìåò .+%. Îòêðîéòå èíâåíòàðü, èñïîëüçóéòå êëàâèøó 'Y' èëè /invent$") and itemAdding[0] then
        -- Èçâëåêàåì ID ïðåäìåòà èç ñîîáùåíèÿ
        local item_str = text:match("Âàì áûë äîáàâëåí ïðåäìåò (.+)%. Îòêðîéòå èíâåíòàðü, èñïîëüçóéòå êëàâèøó 'Y' èëè /invent")
        local itemId = tonumber(item_str:match(":item(%d+):")) -- Ïðåäïîëàãàåì ôîðìàò ":item<ID>:"

        if itemId then
            if tableIncludes(items, itemId) then
                -- Åñëè ïðåäìåò åñòü â íàøåì ñïèñêå
                sendTelegramMessage(items_name[itemId])
            else
                -- Åñëè ïðåäìåòà íåò â ñïèñêå, îòïðàâëÿåì åãî ID ñ ïðîñüáîé äîáàâèòü
                sendTelegramMessage("Ïîëó÷åí íåèçâåñòíûé ïðåäìåò. ID: " .. itemId .. ". Ïîæàëóéñòà, äîáàâüòå åãî â ñïèñîê.")
            end
        else
            -- Åñëè íå óäàëîñü èçâëå÷ü ID ïðåäìåòà (íåîæèäàííûé ôîðìàò ñîîáùåíèÿ)
            sendTelegramMessage("Íå óäàëîñü ðàñïîçíàòü ID ïîëó÷åííîãî ïðåäìåòà. Ñîîáùåíèå: " .. text)
        end
    end
end


-- ======================================================================
-- ÀÂÒÎÎÁÍÎÂËÅÍÈÅ
-- ======================================================================

local UPDATE_URL = "https://github.com/dmashmakov2000-coder/item1/raw/refs/heads/main/Item.lua"
local current_version = SCRIPT_VERSION

-- Ôóíêöèÿ äëÿ ïîëó÷åíèÿ òåêóùåé âåðñèè ñ GitHub
local function checkForUpdates()
    local requests = require('requests')
    local response, status, _ = requests.get(UPDATE_URL)

    if status == 200 then
        local remote_script_content = response
        local remote_version = remote_script_content:match('local SCRIPT_VERSION = "(.-)"')

        if remote_version and remote_version ~= current_version then
            sampAddChatMessage(string.format('[Item] {ffff00}Äîñòóïíî îáíîâëåíèå! {ffffff}Òåêóùàÿ âåðñèÿ: %s, Íîâàÿ âåðñèÿ: %s', current_version, remote_version), 0xFFFFFF)
            return remote_script_content -- Âîçâðàùàåì ñîäåðæèìîå íîâîãî ñêðèïòà
        end
    else
        sampAddChatMessage(string.format('[Item] {ff0000}Îøèáêà ïðè ïðîâåðêå îáíîâëåíèé. Êîä: %s', status), 0xFFFFFF)
    end
    return nil
end

-- Ôóíêöèÿ äëÿ ñêà÷èâàíèÿ è çàìåíû ôàéëà ñêðèïòà
local function downloadAndUpdate(new_script_content)
    local script_path = thisScript().path -- Áîëåå íàäåæíûé ñïîñîá ïîëó÷èòü ïóòü ê ñêðèïòó

    local file = io.open(script_path, "w")
    if file then
        file:write(new_script_content)
        file:close()
        sampAddChatMessage(string.format('[Item] {00ff00}Ñêðèïò óñïåøíî îáíîâëåí äî âåðñèè {ffffff}%s!{00ff00} Ïåðåçàïóñòèòå èãðó èëè ñêðèïò äëÿ ïðèìåíåíèÿ èçìåíåíèé.', current_version), 0xFFFFFF)
        return true
    else
        sampAddChatMessage(string.format('[Item] {ff0000}Îøèáêà ïðè çàïèñè íîâîãî ôàéëà ñêðèïòà: %s', script_path), 0xFFFFFF)
        return false
    end
end

-- Îáðàáîò÷èê äëÿ êîìàíäû /update
sampRegisterChatCommand('itemupdate', function()
    sampAddChatMessage(string.format('[Item] {ffffff}Ïðîâåðêà îáíîâëåíèé...'), 0xFFFFFF)
    local new_script_content = checkForUpdates()
    if new_script_content then
        downloadAndUpdate(new_script_content)
    else
        sampAddChatMessage(string.format('[Item] {00ff00}Ó âàñ óñòàíîâëåíà ïîñëåäíÿÿ âåðñèÿ ({ffffff}%s{00ff00}).', current_version), 0xFFFFFF)
    end
end)

-- Àâòîìàòè÷åñêàÿ ïðîâåðêà ïðè çàïóñêå (îïöèîíàëüíî)
-- Åñëè âû õîòèòå àâòîìàòè÷åñêóþ ïðîâåðêó, ëó÷øå èñïîëüçîâàòü os.clock() è onFrame() èëè îòäåëüíûé effil.thread
-- Ïðèìåð ñ onFrame():
-- local check_update_timer = os.clock()
-- local CHECK_INTERVAL = 60 -- Ïðîâåðÿòü êàæäûå 60 ñåêóíä

-- function onFrame()
--     if os.clock() - check_update_timer > CHECK_INTERVAL then
--         check_update_timer = os.clock() -- Ñáðàñûâàåì òàéìåð
--         local new_script_content = checkForUpdates()
--         if new_script_content then
--             sampAddChatMessage(string.format('[Item] {ffff00}Äîñòóïíî îáíîâëåíèå! Èñïîëüçóéòå êîìàíäó /itemupdate äëÿ óñòàíîâêè.'), 0xFFFFFF)
--         end
--     end
-- end

-- ======================================================================
-- ÊÎÍÅÖ ÀÂÒÎÎÁÍÎÂËÅÍÈß
-- ======================================================================


