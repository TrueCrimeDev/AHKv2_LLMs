// highlight-ahk2.js - AutoHotkey v2 syntax grammar for highlight.js
// Covers v2.0 through v2.1-alpha.26 keywords and patterns

hljs.registerLanguage('ahk2', function(hljs) {
  return {
    name: 'AutoHotkey v2',
    aliases: ['ahk', 'ahk2', 'autohotkey'],
    case_insensitive: true,
    contains: [
      // Block comments /* ... */
      hljs.COMMENT('/\\*', '\\*/', { relevance: 0 }),

      // Line comments
      hljs.COMMENT(';', '$', { relevance: 0 }),

      // Directives (#Requires, #Include, #Import, #Module, #SingleInstance)
      {
        className: 'meta',
        begin: /#(?:Requires|Include|Import|Module|SingleInstance|HotIf|DllLoad|Warn|ErrorStdOut|NoTrayIcon)\b/,
        relevance: 10
      },

      // Strings - double quoted
      {
        className: 'string',
        begin: '"', end: '"',
        contains: [{ begin: '`.' }],
        relevance: 0
      },

      // Strings - single quoted
      {
        className: 'string',
        begin: "'", end: "'",
        contains: [{ begin: '`.' }],
        relevance: 0
      },

      // Struct keyword (v2.1-alpha.22+)
      {
        className: 'keyword',
        begin: /\bStruct\b/,
        relevance: 10
      },

      // Control flow and declarations
      {
        className: 'keyword',
        begin: /\b(?:if|else|for|while|loop|return|break|continue|switch|case|default|try|catch|finally|throw|class|extends|static|global|local|export|new|in|not|and|or|is|isset|unset)\b/
      },

      // Built-in types (v2.1-alpha.22+)
      {
        className: 'type',
        begin: /\b(?:i8|u8|i16|u16|i32|u32|i64|u64|iptr|uptr|Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|IntPtr|UIntPtr|Float32|Float64)\b/,
        relevance: 8
      },

      // Built-in functions
      {
        className: 'built_in',
        begin: /\b(?:MsgBox|InputBox|ToolTip|FileOpen|FileRead|FileAppend|DllCall|CallbackCreate|CallbackFree|ComObject|ComObjGet|ComObjConnect|RegRead|RegWrite|RegDelete|WinExist|WinActive|WinActivate|WinClose|WinWait|WinWaitActive|WinWaitClose|WinGetTitle|WinGetClass|WinGetPos|WinMove|WinHide|WinShow|WinMinimize|WinMaximize|WinRestore|WinSetTitle|WinGetText|WinGetControls|ControlGetText|ControlSetText|ControlClick|ControlSend|ControlFocus|Send|SendInput|SendEvent|Click|MouseMove|MouseClick|MouseGetPos|KeyWait|GetKeyState|Hotkey|SetTimer|Sleep|Run|RunWait|ProcessExist|ProcessClose|ProcessWait|EnvGet|EnvSet|SysGet|MonitorGet|MonitorGetCount|A_ScreenWidth|A_ScreenHeight|Format|FormatTime|StrLen|StrLower|StrUpper|StrReplace|StrSplit|SubStr|InStr|RegExMatch|RegExReplace|Trim|LTrim|RTrim|Sort|Type|IsSet|IsObject|HasProp|HasOwnProp|HasMethod|HasBase|ObjOwnPropCount|GetOwnPropDesc|DefineProp|Sqrt|Abs|Min|Max|Mod|Round|Floor|Ceil|Log|Ln|Exp|Map|Array|Buffer|Gui|Menu|MenuBar|OnMessage|OnExit|OnError|OnClipboardChange|SetTitleMatchMode|DetectHiddenWindows|CoordMode|SendMode|SetWorkingDir|Persistent|Chr|Ord|NumGet|NumPut|StrGet|StrPut)\b(?=\s*[\(])/
      },

      // Built-in variables (A_ prefix)
      {
        className: 'built_in',
        begin: /\bA_\w+\b/
      },

      // Class/type names (PascalCase after class/extends/Struct or standalone)
      {
        className: 'title.class',
        begin: /(?<=(?:class|extends|Struct)\s+)[A-Z]\w*/,
        relevance: 5
      },

      // Fat arrow
      {
        className: 'operator',
        begin: /=>/
      },

      // Assignment and comparison operators
      {
        className: 'operator',
        begin: /(?::=|\.=|\+=|-=|\*=|\/=|\/\/=|<<=|>>=|&=|\|=|\^=|~=|==|!=|<=|>=|&&|\|\||<<|>>|\/\/|\*\*)/
      },

      // Function/method declarations
      {
        className: 'title.function',
        begin: /\b[a-zA-Z_]\w*(?=\s*\([^)]*\)\s*\{)/,
        relevance: 3
      },

      // Function/method calls
      {
        className: 'title.function',
        begin: /\b[a-zA-Z_]\w*(?=\s*\()/,
        relevance: 0
      },

      // Method calls after dot
      {
        className: 'title.function',
        begin: /(?<=\.)[a-zA-Z_]\w*(?=\s*\()/
      },

      // Property access after dot (not a function call)
      {
        className: 'property',
        begin: /(?<=\.)[a-zA-Z_]\w*\b(?!\s*\()/
      },

      // Numbers - hex
      {
        className: 'number',
        begin: /\b0[xX][0-9a-fA-F]+\b/,
        relevance: 0
      },

      // Numbers - float
      {
        className: 'number',
        begin: /\b\d+\.\d+\b/,
        relevance: 0
      },

      // Numbers - integer
      {
        className: 'number',
        begin: /\b\d+\b/,
        relevance: 0
      },

      // Labels/hotkeys (word followed by ::)
      {
        className: 'symbol',
        begin: /^\s*[^\s:]+(?=::)/,
        relevance: 5
      }
    ]
  };
});
