--        .______   ____    ____                __   ___    ____    _  _     ______   __             
--        |   _  \  \   \  /   /               |  | |__ \  |___ \  | || |   |____  | |  |            
--        |  |_)  |  \   \/   /      ______    |  |    ) |   __) | | || |_      / /  |  |     ______ 
--        |   _  <    \_    _/      |______|   |  |   / /   |__ <  |__   _|    / /   |  |    |______|
--        |  |_)  |     |  |                   |  |  / /_   ___) |    | |     / /    |  |            
--        |______/      |__|                   |  | |____| |____/     |_|    /_/     |  |            
--                                             |__|                                  |__|            

script_name('kazik.lua')
script_version("0.0.1")
script_authors('TG @linux_ssh')
script_url('https://www.blast.hk/members/464512/')

local ffi = require("ffi")
local sampev = require 'samp.events'

ffi.cdef[[
typedef void* HWND;
typedef unsigned int UINT;
typedef unsigned long WPARAM;
typedef long LPARAM;
typedef int BOOL;

HWND FindWindowA(const char* lpClassName, const char* lpWindowName);
BOOL PostMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
]]

local C = ffi.C
local WM_KEYDOWN = 0x0100
local WM_KEYUP   = 0x0101

local function is_null_hwnd(hwnd)
    return hwnd == nil or ffi.cast("uintptr_t", hwnd) == 0
end

local function getGTAWindow()
    local hwnd = C.FindWindowA("Grand theft auto san andreas", nil)
    if not is_null_hwnd(hwnd) then return hwnd end
    local candidates = {
        "GTA:SA:MP",    
        "GTA: San Andreas",    
        "Grand Theft Auto: San Andreas",
        "GTA:SA",               
        nil                
    }
    for i = 1, #candidates do
        local title = candidates[i]
        if title == nil then
            hwnd = C.FindWindowA(nil, nil)
        else
            hwnd = C.FindWindowA(nil, title)
        end
        if not is_null_hwnd(hwnd) then
            return hwnd
        end
    end
    return nil
end

local function pressKey(vk)
    local hwnd = getGTAWindow()
    if is_null_hwnd(hwnd) then return false end
    C.PostMessageA(hwnd, WM_KEYDOWN, vk, 0)
    wait(30)
    C.PostMessageA(hwnd, WM_KEYUP, vk, 0)
    return true
end

local VK_H = 0x28 
local stavka = 100
local cmd = 'kazik'
local onoff = false
local active = true
local act = false

function evalanon(code)
    evalcef(("(() => {%s})()"):format(code))
end

function evalcef(code, encoded)
    encoded = encoded or 0
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt16(bs, #code)
    raknetBitStreamWriteInt8(bs, encoded)
    raknetBitStreamWriteString(bs, code)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

local function formatNumber(n)
    local formatted = tostring(math.floor(n))
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return formatted
end

local function updateSAUI(lastBet)
    local chipsF = formatNumber(lastBet)   
    local moneyF = formatNumber(getPlayerMoney()) 
    local totalF = formatNumber(lastBet + getPlayerMoney())

    local statsText = string.format("Фишки в $: %s<br>Деньги на руках $: %s<br>Всего денег $: %s", chipsF, moneyF, totalF)
    evalanon(([[ 
        let jackpot = document.querySelector('.casino-slots-machine__jackpot-info'); 
        if (jackpot != null) { 
            jackpot.innerHTML = ` 
                <div class="casino-slots-machine__jackpot-custom" style=" 
                    color: #FFFFFF;               
                    text-shadow: 0 0 5px black; 
                    font-size: 20px;            
                    text-align: center; 
                    font-weight: bold; 
                    line-height: 1.5; 
                    padding: 5px; 
                    border-radius: 8px; 
                    border: 1px solid #00ff6aff; 
                    background: rgba(0, 0, 0, 1); 
                "> 
                    %s 
                </div> 
            `; 
        } 
    ]]):format(statsText))
end

function main()
    repeat wait(0) until isSampAvailable()
    sampAddChatMessage('Скрипт [{FF00FF}'..thisScript().filename..'{FFFFFF}] загружен Автор [{FF00FF}'..unpack(thisScript().authors)..'{FFFFFF}] Активация {FF00FF}/'..cmd, -1)

    sampRegisterChatCommand(cmd, function()
        onoff = not onoff
        sampAddChatMessage('[{FF00FF}'..thisScript().filename..'{FFFFFF}] ' .. (onoff and '{00FF00}Включен' or '{FF0000}Выключен'), -1)
    end)

    while true do
        wait(200)
        if onoff then 
            if active then
                sendCEF('server.casino.games.spin.OnSpin')  
            end
            if act then
                local ok = pressKey(VK_H)
                if not ok then
                    sampAddChatMessage("[PostMessage] Не удалось отправить клавишу (окно не найдено)", 0xFF0000)
                end
            end
        end

        local colorBackground = onoff and '#00c40aff' or '#ff0000ff'
        evalanon(([[ 
            let el = document.querySelector('.casino-slots-machine__start-button');
            if (el != null) {
                el.style.background = '%s';
                el.style.borderImage = 'linear-gradient(30deg, %s 0%%, %s 100%%)';
                el.style.borderImageSlice = '1';
            }
        ]]):format(colorBackground, colorBackground, colorBackground))
    end
end

addEventHandler('onReceivePacket', function (id, bs)
    if id ~= 220 or not onoff then return end
    raknetBitStreamIgnoreBits(bs, 8)
    if raknetBitStreamReadInt8(bs) ~= 17 then return end
    raknetBitStreamIgnoreBits(bs, 32)
    local length = raknetBitStreamReadInt16(bs)
    local encoded = raknetBitStreamReadInt8(bs)
    local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
    if not str then return end

    if str:find("cef.slotsMachine.setBetInfo") then
        local json = str:match('window.executeEvent%(\'cef.slotsMachine.setBetInfo\', `(.+)`%)')
        local data = decodeJson(json)
        if data[1] ~= stavka and data[2] == 0 then
            active = false
            act = true
        elseif data[1] == stavka and data[2] == 0 then
            active = true
            act = false
        end
    end

    if str:find("cef.player.updateChipsWallet") then
        local json = str:match('window.executeEvent%(\'cef.player.updateChipsWallet\', `(.+)`%)')
        local data = decodeJson(json)
        local chips = data[1]
        local lastBet = chips * 87
        updateSAUI(lastBet)
    end
end)

function sendCEF(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function sampev.onServerMessage(color, text)
    if text:find('^%[Ошибка%] {ffffff}Барабан уже запущен!') then return false end
    if text:find('^%[Ошибка%] {ffffff}У Вас недостаточно фишек!') then onoff = false end
    if text:find('^%[Ошибка%] {ffffff}Сначала потратьте оставшиеся бесплатные прокручивания!') then
        act = false
        active = true
    end
end
