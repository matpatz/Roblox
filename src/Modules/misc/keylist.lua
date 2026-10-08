return {
    -- Mouse buttons
    ["Left Mouse"] = 0x01,
    ["Right Mouse"] = 0x02,
    ["Cancel"] = 0x03,
    ["Middle Mouse"] = 0x04,
    ["X1 Mouse"] = 0x05,
    ["X2 Mouse"] = 0x06,
    
    -- Control keys
    ["Backspace"] = 0x08,
    ["Tab"] = 0x09,
    ["Clear"] = 0x0C,
    ["Enter"] = 0x0D,
    
    -- Modifier keys
    ["Shift"] = 0x10,
    ["Control"] = 0x11,
    ["Alt"] = 0x12,
    ["Pause"] = 0x13,
    ["Caps Lock"] = 0x14,
    
    -- IME keys
    ["Kana"] = 0x15,
    ["Hangul"] = 0x15,
    ["IME On"] = 0x16,
    ["Junja"] = 0x17,
    ["Final"] = 0x18,
    ["Hanja"] = 0x19,
    ["Kanji"] = 0x19,
    ["IME Off"] = 0x1A,
    
    -- Navigation keys
    ["Escape"] = 0x1B,
    ["Convert"] = 0x1C,
    ["NonConvert"] = 0x1D,
    ["Accept"] = 0x1E,
    ["Mode Change"] = 0x1F,
    ["Space"] = 0x20,
	[" "] = 0x20,
    ["Page Up"] = 0x21,
    ["Page Down"] = 0x22,
    ["End"] = 0x23,
    ["Home"] = 0x24,
    
    -- Arrow keys
    ["Left Arrow"] = 0x25,
    ["Up Arrow"] = 0x26,
    ["Right Arrow"] = 0x27,
    ["Down Arrow"] = 0x28,
    
    -- Function keys
    ["Select"] = 0x29,
    ["Print"] = 0x2A,
    ["Execute"] = 0x2B,
    ["Print Screen"] = 0x2C,
    ["Insert"] = 0x2D,
    ["Delete"] = 0x2E,
    ["Help"] = 0x2F,
    
    -- Number keys (0-9)
    ["0"] = 0x30,
    ["1"] = 0x31,
    ["2"] = 0x32,
    ["3"] = 0x33,
    ["4"] = 0x34,
    ["5"] = 0x35,
    ["6"] = 0x36,
    ["7"] = 0x37,
    ["8"] = 0x38,
    ["9"] = 0x39,
    
    -- Letter keys (A-Z)
    ["A"] = 0x41,
    ["B"] = 0x42,
    ["C"] = 0x43,
    ["D"] = 0x44,
    ["E"] = 0x45,
    ["F"] = 0x46,
    ["G"] = 0x47,
    ["H"] = 0x48,
    ["I"] = 0x49,
    ["J"] = 0x4A,
    ["K"] = 0x4B,
    ["L"] = 0x4C,
    ["M"] = 0x4D,
    ["N"] = 0x4E,
    ["O"] = 0x4F,
    ["P"] = 0x50,
    ["Q"] = 0x51,
    ["R"] = 0x52,
    ["S"] = 0x53,
    ["T"] = 0x54,
    ["U"] = 0x55,
    ["V"] = 0x56,
    ["W"] = 0x57,
    ["X"] = 0x58,
    ["Y"] = 0x59,
    ["Z"] = 0x5A,
    
    -- Windows keys
    ["Left Windows"] = 0x5B,
    ["Right Windows"] = 0x5C,
    ["Applications"] = 0x5D,
    ["Sleep"] = 0x5F,
    
    -- Numpad keys
    ["Numpad 0"] = 0x60,
    ["Numpad 1"] = 0x61,
    ["Numpad 2"] = 0x62,
    ["Numpad 3"] = 0x63,
    ["Numpad 4"] = 0x64,
    ["Numpad 5"] = 0x65,
    ["Numpad 6"] = 0x66,
    ["Numpad 7"] = 0x67,
    ["Numpad 8"] = 0x68,
    ["Numpad 9"] = 0x69,
    ["Numpad Multiply"] = 0x6A,
    ["Numpad Add"] = 0x6B,
    ["Numpad Separator"] = 0x6C,
    ["Numpad Subtract"] = 0x6D,
    ["Numpad Decimal"] = 0x6E,
    ["Numpad Divide"] = 0x6F,
    
    -- Function keys (F1-F24)
    ["F1"] = 0x70,
    ["F2"] = 0x71,
    ["F3"] = 0x72,
    ["F4"] = 0x73,
    ["F5"] = 0x74,
    ["F6"] = 0x75,
    ["F7"] = 0x76,
    ["F8"] = 0x77,
    ["F9"] = 0x78,
    ["F10"] = 0x79,
    ["F11"] = 0x7A,
    ["F12"] = 0x7B,
    ["F13"] = 0x7C,
    ["F14"] = 0x7D,
    ["F15"] = 0x7E,
    ["F16"] = 0x7F,
    ["F17"] = 0x80,
    ["F18"] = 0x81,
    ["F19"] = 0x82,
    ["F20"] = 0x83,
    ["F21"] = 0x84,
    ["F22"] = 0x85,
    ["F23"] = 0x86,
    ["F24"] = 0x87,
    
    -- Lock keys
    ["Num Lock"] = 0x90,
    ["Scroll Lock"] = 0x91,
    
    -- Modified modifier keys
    ["Left Shift"] = 0xA0,
    ["Right Shift"] = 0xA1,
    ["Left Control"] = 0xA2,
    ["Right Control"] = 0xA3,
    ["Left Alt"] = 0xA4,
    ["Right Alt"] = 0xA5,
    
    -- Browser keys
    ["Browser Back"] = 0xA6,
    ["Browser Forward"] = 0xA7,
    ["Browser Refresh"] = 0xA8,
    ["Browser Stop"] = 0xA9,
    ["Browser Search"] = 0xAA,
    ["Browser Favorites"] = 0xAB,
    ["Browser Home"] = 0xAC,
    
    -- Volume keys
    ["Volume Mute"] = 0xAD,
    ["Volume Down"] = 0xAE,
    ["Volume Up"] = 0xAF,
    
    -- Media keys
    ["Next Track"] = 0xB0,
    ["Previous Track"] = 0xB1,
    ["Stop Media"] = 0xB2,
    ["Play/Pause Media"] = 0xB3,
    ["Start Mail"] = 0xB4,
    ["Select Media"] = 0xB5,
    ["Start App 1"] = 0xB6,
    ["Start App 2"] = 0xB7,
    
    -- OEM keys (US ANSI layout)
    ["Semicolon"] = 0xBA,        -- ; and :
    ["Equals"] = 0xBB,           -- = and +
    ["Comma"] = 0xBC,            -- , and <
    ["Minus"] = 0xBD,            -- - and _
    ["Period"] = 0xBE,           -- . and >
    ["Slash"] = 0xBF,            -- / and ?
    ["Grave"] = 0xC0,            -- ` and ~
    
    -- Gamepad buttons
    ["Gamepad A"] = 0xC3,
    ["Gamepad B"] = 0xC4,
    ["Gamepad X"] = 0xC5,
    ["Gamepad Y"] = 0xC6,
    ["Gamepad Right Shoulder"] = 0xC7,
    ["Gamepad Left Shoulder"] = 0xC8,
    ["Gamepad Left Trigger"] = 0xC9,
    ["Gamepad Right Trigger"] = 0xCA,
    ["Gamepad Dpad Up"] = 0xCB,
    ["Gamepad Dpad Down"] = 0xCC,
    ["Gamepad Dpad Left"] = 0xCD,
    ["Gamepad Dpad Right"] = 0xCE,
    ["Gamepad Menu"] = 0xCF,
    ["Gamepad View"] = 0xD0,
    ["Gamepad Left Thumbstick"] = 0xD1,
    ["Gamepad Right Thumbstick"] = 0xD2,
    
    -- More OEM keys
    ["Left Bracket"] = 0xDB,     -- [ and {
    ["Backslash"] = 0xDC,        -- \ and |
    ["Right Bracket"] = 0xDD,    -- ] and }
    ["Quote"] = 0xDE,            -- ' and "
    ["OEM 8"] = 0xDF,
    ["OEM 102"] = 0xE2,
    
    -- Special keys
    ["Process Key"] = 0xE5,
    ["Packet"] = 0xE7,
    ["Attn"] = 0xF6,
    ["CrSel"] = 0xF7,
    ["ExSel"] = 0xF8,
    ["Erase EOF"] = 0xF9,
    ["Play"] = 0xFA,
    ["Zoom"] = 0xFB,
    ["PA1"] = 0xFD,
    ["OEM Clear"] = 0xFE,
    
    -- Direct character mappings
    [","] = 0xBC,        -- Comma
    ["."] = 0xBE,        -- Period  
    ["/"] = 0xBF,        -- Forward slash
    [";"] = 0xBA,        -- Semicolon
    ["'"] = 0xDE,        -- Single quote
    ["["] = 0xDB,        -- Left bracket
    ["]"] = 0xDD,        -- Right bracket
    ["\\"] = 0xDC,       -- Backslash
    ["-"] = 0xBD,        -- Minus/hyphen
    ["="] = 0xBB,        -- Equals
    ["`"] = 0xC0,        -- Grave accent
    
    -- Shift-modified characters
    ["<"] = 0xBC,        -- Less than (Shift + ,)
    [">"] = 0xBE,        -- Greater than (Shift + .)
    ["?"] = 0xBF,        -- Question mark (Shift + /)
    [":"] = 0xBA,        -- Colon (Shift + ;)
    ["\""] = 0xDE,       -- Double quote (Shift + ')
    ["{"] = 0xDB,        -- Left curly brace (Shift + [)
    ["}"] = 0xDD,        -- Right curly brace (Shift + ])
    ["|"] = 0xDC,        -- Pipe (Shift + \)
    ["_"] = 0xBD,        -- Underscore (Shift + -)
    ["+"] = 0xBB,        -- Plus (Shift + =)
    ["~"] = 0xC0,        -- Tilde (Shift + `)
    
    -- Parentheses
    ["("] = 0x39,        -- Left parenthesis (Shift + 9)
    [")"] = 0x30,        -- Right parenthesis (Shift + 0)
    
    -- Shift-number symbols
    ["!"] = 0x31,        -- Exclamation (Shift + 1)
    ["@"] = 0x32,        -- At symbol (Shift + 2)
    ["#"] = 0x33,        -- Hash/pound (Shift + 3)
    ["$"] = 0x34,        -- Dollar (Shift + 4)
    ["%"] = 0x35,        -- Percent (Shift + 5)
    ["^"] = 0x36,        -- Caret (Shift + 6)
    ["&"] = 0x37,        -- Ampersand (Shift + 7)
    ["*"] = 0x38         -- Asterisk (Shift + 8)
}