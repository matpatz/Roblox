-- friendly key name -> Enum.KeyCode (what UserInputService:IsKeyDown expects)
return {
    -- Mouse buttons
    ["Left Mouse"] = Enum.KeyCode.MouseLeftButton,
    ["Right Mouse"] = Enum.KeyCode.MouseRightButton,
    ["Middle Mouse"] = Enum.KeyCode.MouseMiddleButton,
    ["Mouse Back"] = Enum.KeyCode.MouseBackButton,

    -- Control keys
    ["Backspace"] = Enum.KeyCode.Backspace,
    ["Tab"] = Enum.KeyCode.Tab,
    ["Clear"] = Enum.KeyCode.Clear,
    ["Enter"] = Enum.KeyCode.Return,

    -- Modifier keys
    ["Shift"] = Enum.KeyCode.LeftShift,
    ["Control"] = Enum.KeyCode.LeftControl,
    ["Alt"] = Enum.KeyCode.LeftAlt,
    ["Pause"] = Enum.KeyCode.Pause,
    ["Caps Lock"] = Enum.KeyCode.CapsLock,

    -- Navigation keys
    ["Escape"] = Enum.KeyCode.Escape,
    ["Space"] = Enum.KeyCode.Space,
    [" "] = Enum.KeyCode.Space,
    ["Page Up"] = Enum.KeyCode.PageUp,
    ["Page Down"] = Enum.KeyCode.PageDown,
    ["End"] = Enum.KeyCode.End,
    ["Home"] = Enum.KeyCode.Home,

    -- Arrow keys
    ["Left Arrow"] = Enum.KeyCode.Left,
    ["Up Arrow"] = Enum.KeyCode.Up,
    ["Right Arrow"] = Enum.KeyCode.Right,
    ["Down Arrow"] = Enum.KeyCode.Down,

    -- System keys
    ["Print"] = Enum.KeyCode.Print,
    ["Print Screen"] = Enum.KeyCode.Print,
    ["Insert"] = Enum.KeyCode.Insert,
    ["Delete"] = Enum.KeyCode.Delete,
    ["Help"] = Enum.KeyCode.Help,

    -- Number keys (0-9)
    ["0"] = Enum.KeyCode.Zero,
    ["1"] = Enum.KeyCode.One,
    ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four,
    ["5"] = Enum.KeyCode.Five,
    ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven,
    ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,

    -- Letter keys (A-Z)
    ["A"] = Enum.KeyCode.A,
    ["B"] = Enum.KeyCode.B,
    ["C"] = Enum.KeyCode.C,
    ["D"] = Enum.KeyCode.D,
    ["E"] = Enum.KeyCode.E,
    ["F"] = Enum.KeyCode.F,
    ["G"] = Enum.KeyCode.G,
    ["H"] = Enum.KeyCode.H,
    ["I"] = Enum.KeyCode.I,
    ["J"] = Enum.KeyCode.J,
    ["K"] = Enum.KeyCode.K,
    ["L"] = Enum.KeyCode.L,
    ["M"] = Enum.KeyCode.M,
    ["N"] = Enum.KeyCode.N,
    ["O"] = Enum.KeyCode.O,
    ["P"] = Enum.KeyCode.P,
    ["Q"] = Enum.KeyCode.Q,
    ["R"] = Enum.KeyCode.R,
    ["S"] = Enum.KeyCode.S,
    ["T"] = Enum.KeyCode.T,
    ["U"] = Enum.KeyCode.U,
    ["V"] = Enum.KeyCode.V,
    ["W"] = Enum.KeyCode.W,
    ["X"] = Enum.KeyCode.X,
    ["Y"] = Enum.KeyCode.Y,
    ["Z"] = Enum.KeyCode.Z,

    -- Windows keys
    ["Left Windows"] = Enum.KeyCode.LeftSuper,
    ["Right Windows"] = Enum.KeyCode.RightSuper,
    ["Applications"] = Enum.KeyCode.Menu,

    -- Numpad keys
    ["Numpad 0"] = Enum.KeyCode.KeypadZero,
    ["Numpad 1"] = Enum.KeyCode.KeypadOne,
    ["Numpad 2"] = Enum.KeyCode.KeypadTwo,
    ["Numpad 3"] = Enum.KeyCode.KeypadThree,
    ["Numpad 4"] = Enum.KeyCode.KeypadFour,
    ["Numpad 5"] = Enum.KeyCode.KeypadFive,
    ["Numpad 6"] = Enum.KeyCode.KeypadSix,
    ["Numpad 7"] = Enum.KeyCode.KeypadSeven,
    ["Numpad 8"] = Enum.KeyCode.KeypadEight,
    ["Numpad 9"] = Enum.KeyCode.KeypadNine,
    ["Numpad Multiply"] = Enum.KeyCode.KeypadMultiply,
    ["Numpad Add"] = Enum.KeyCode.KeypadPlus,
    ["Numpad Subtract"] = Enum.KeyCode.KeypadMinus,
    ["Numpad Decimal"] = Enum.KeyCode.KeypadPeriod,
    ["Numpad Divide"] = Enum.KeyCode.KeypadDivide,
    ["Numpad Enter"] = Enum.KeyCode.KeypadEnter,
    ["Numpad Equals"] = Enum.KeyCode.KeypadEquals,

    -- Function keys (F1-F15)
    ["F1"] = Enum.KeyCode.F1,
    ["F2"] = Enum.KeyCode.F2,
    ["F3"] = Enum.KeyCode.F3,
    ["F4"] = Enum.KeyCode.F4,
    ["F5"] = Enum.KeyCode.F5,
    ["F6"] = Enum.KeyCode.F6,
    ["F7"] = Enum.KeyCode.F7,
    ["F8"] = Enum.KeyCode.F8,
    ["F9"] = Enum.KeyCode.F9,
    ["F10"] = Enum.KeyCode.F10,
    ["F11"] = Enum.KeyCode.F11,
    ["F12"] = Enum.KeyCode.F12,
    ["F13"] = Enum.KeyCode.F13,
    ["F14"] = Enum.KeyCode.F14,
    ["F15"] = Enum.KeyCode.F15,

    -- Lock keys
    ["Num Lock"] = Enum.KeyCode.NumLock,
    ["Scroll Lock"] = Enum.KeyCode.ScrollLock,

    -- Modified modifier keys
    ["Left Shift"] = Enum.KeyCode.LeftShift,
    ["Right Shift"] = Enum.KeyCode.RightShift,
    ["Left Control"] = Enum.KeyCode.LeftControl,
    ["Right Control"] = Enum.KeyCode.RightControl,
    ["Left Alt"] = Enum.KeyCode.LeftAlt,
    ["Right Alt"] = Enum.KeyCode.RightAlt,

    -- OEM keys (US ANSI layout)
    ["Semicolon"] = Enum.KeyCode.Semicolon,
    ["Equals"] = Enum.KeyCode.Equals,
    ["Comma"] = Enum.KeyCode.Comma,
    ["Minus"] = Enum.KeyCode.Minus,
    ["Period"] = Enum.KeyCode.Period,
    ["Slash"] = Enum.KeyCode.Slash,
    ["Grave"] = Enum.KeyCode.Backquote,

    -- Gamepad buttons
    ["Gamepad A"] = Enum.KeyCode.ButtonA,
    ["Gamepad B"] = Enum.KeyCode.ButtonB,
    ["Gamepad X"] = Enum.KeyCode.ButtonX,
    ["Gamepad Y"] = Enum.KeyCode.ButtonY,
    ["Gamepad Right Shoulder"] = Enum.KeyCode.ButtonR1,
    ["Gamepad Left Shoulder"] = Enum.KeyCode.ButtonL1,
    ["Gamepad Left Trigger"] = Enum.KeyCode.ButtonL2,
    ["Gamepad Right Trigger"] = Enum.KeyCode.ButtonR2,
    ["Gamepad Dpad Up"] = Enum.KeyCode.DPadUp,
    ["Gamepad Dpad Down"] = Enum.KeyCode.DPadDown,
    ["Gamepad Dpad Left"] = Enum.KeyCode.DPadLeft,
    ["Gamepad Dpad Right"] = Enum.KeyCode.DPadRight,
    ["Gamepad Menu"] = Enum.KeyCode.ButtonStart,
    ["Gamepad View"] = Enum.KeyCode.ButtonSelect,
    ["Gamepad Left Thumbstick"] = Enum.KeyCode.ButtonL3,
    ["Gamepad Right Thumbstick"] = Enum.KeyCode.ButtonR3,

    -- More OEM keys
    ["Left Bracket"] = Enum.KeyCode.LeftBracket,
    ["Backslash"] = Enum.KeyCode.BackSlash,
    ["Right Bracket"] = Enum.KeyCode.RightBracket,
    ["Quote"] = Enum.KeyCode.Quote,

    -- Direct character mappings
    [","] = Enum.KeyCode.Comma,
    ["."] = Enum.KeyCode.Period,
    ["/"] = Enum.KeyCode.Slash,
    [";"] = Enum.KeyCode.Semicolon,
    ["'"] = Enum.KeyCode.Quote,
    ["["] = Enum.KeyCode.LeftBracket,
    ["]"] = Enum.KeyCode.RightBracket,
    ["\\"] = Enum.KeyCode.BackSlash,
    ["-"] = Enum.KeyCode.Minus,
    ["="] = Enum.KeyCode.Equals,
    ["`"] = Enum.KeyCode.Backquote,

    -- Shift-modified characters
    ["<"] = Enum.KeyCode.LessThan,
    [">"] = Enum.KeyCode.GreaterThan,
    ["?"] = Enum.KeyCode.Question,
    [":"] = Enum.KeyCode.Colon,
    ["\""] = Enum.KeyCode.QuotedDouble,
    ["{"] = Enum.KeyCode.LeftCurly,
    ["}"] = Enum.KeyCode.RightCurly,
    ["|"] = Enum.KeyCode.Pipe,
    ["_"] = Enum.KeyCode.Underscore,
    ["+"] = Enum.KeyCode.Plus,
    ["~"] = Enum.KeyCode.Tilde,

    -- Parentheses
    ["("] = Enum.KeyCode.LeftParenthesis,
    [")"] = Enum.KeyCode.RightParenthesis,

    -- Shift-number symbols
    ["@"] = Enum.KeyCode.At,
    ["#"] = Enum.KeyCode.Hash,
    ["$"] = Enum.KeyCode.Dollar,
    ["%"] = Enum.KeyCode.Percent,
    ["^"] = Enum.KeyCode.Caret,
    ["&"] = Enum.KeyCode.Ampersand,
    ["*"] = Enum.KeyCode.Asterisk,
}