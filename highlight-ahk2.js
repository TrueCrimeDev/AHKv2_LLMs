// highlight-ahk2.js - AutoHotkey v2 syntax grammar for highlight.js
// Matches VS Code Dark+ theme colors for AHK v2 through v2.1-alpha.26

hljs.registerLanguage('ahk2', function(hljs) {

  var STRUCT_DEF = {
    className: 'keyword',
    begin: /\bStruct\b/,
    starts: {
      contains: [
        {
          className: 'title.class',
          begin: /[A-Z]\w*/,
          relevance: 0
        },
        {
          className: 'keyword',
          begin: /\bextends\b/
        }
      ],
      end: /\{/,
      excludeEnd: true
    },
    relevance: 10
  };

  var CLASS_DEF = {
    className: 'keyword',
    begin: /\bclass\b/,
    starts: {
      contains: [
        {
          className: 'title.class',
          begin: /[A-Z]\w*/,
          relevance: 0
        },
        {
          className: 'keyword',
          begin: /\bextends\b/
        }
      ],
      end: /\{/,
      excludeEnd: true
    }
  };

  return {
    name: 'AutoHotkey v2',
    aliases: ['ahk', 'ahk2', 'autohotkey'],
    case_insensitive: false,
    contains: [
      // Block comments
      hljs.COMMENT('/\\*', '\\*/'),

      // Line comments
      hljs.COMMENT(';', '$'),

      // Struct definition (keyword + class name)
      STRUCT_DEF,

      // Class definition
      CLASS_DEF,

      // Directives - purple
      {
        className: 'meta',
        begin: /#(?:Requires|Include|Import|Module|SingleInstance|HotIf|DllLoad|Warn|ErrorStdOut|NoTrayIcon)\b/,
        relevance: 10
      },

      // Strings - double quoted
      {
        className: 'string',
        begin: '"',
        end: '"',
        contains: [{ begin: /`./ }]
      },

      // Strings - single quoted
      {
        className: 'string',
        begin: "'",
        end: "'",
        contains: [{ begin: /`./ }]
      },

      // Typed field annotations (e.g., x: i32, y: Float64)
      {
        className: 'type',
        begin: /\b(?:i8|u8|i16|u16|i32|u32|i64|u64|iptr|uptr|Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|IntPtr|UIntPtr|Float32|Float64)\b/,
        relevance: 8
      },

      // Control flow keywords - blue
      {
        className: 'keyword',
        begin: /\b(?:if|else|for|while|loop|return|break|continue|switch|case|default|try|catch|finally|throw|static|global|local|export|in|not|and|or|is|this|super)\b/
      },

      // Built-in variables (A_ prefix) - light blue
      {
        className: 'variable.language',
        begin: /\bA_\w+\b/
      },

      // Built-in functions - yellow
      {
        className: 'built_in',
        begin: /\b(?:MsgBox|InputBox|ToolTip|FileOpen|FileRead|FileAppend|DllCall|CallbackCreate|CallbackFree|ComObject|RegRead|RegWrite|WinExist|WinActive|WinActivate|WinClose|WinWait|WinWaitActive|WinGetTitle|WinGetClass|WinGetPos|WinMove|WinHide|WinShow|WinSetTitle|WinGetText|Send|SendInput|Click|MouseMove|MouseClick|MouseGetPos|KeyWait|GetKeyState|Hotkey|SetTimer|Sleep|Run|RunWait|ProcessExist|ProcessClose|Format|FormatTime|StrLen|StrLower|StrUpper|StrReplace|StrSplit|SubStr|InStr|RegExMatch|RegExReplace|Trim|Sort|Type|IsSet|IsObject|HasProp|HasOwnProp|HasMethod|HasBase|ObjOwnPropCount|GetOwnPropDesc|DefineProp|Sqrt|Abs|Min|Max|Mod|Round|Floor|Ceil|Map|Array|Buffer|Gui|Menu|OnMessage|OnExit|OnError|Chr|Ord|NumGet|NumPut|StrGet|StrPut|SetTitleMatchMode|DetectHiddenWindows|CoordMode|SendMode|Persistent|FileExist|DirExist|String)\b(?=\s*\()/
      },

      // Fat arrow operator
      {
        className: 'operator',
        begin: /=>/
      },

      // Assignment and comparison operators
      {
        className: 'operator',
        begin: /(?::=|\.=|\+=|-=|\*=|\/=|==|!=|<=|>=|&&|\|\||<<|>>|\*\*|~=)/
      },

      // Constructor/class calls (PascalCase followed by parenthesis) - yellow
      {
        className: 'title.function.invoke',
        begin: /\b[A-Z]\w*(?=\s*\()/,
        relevance: 0
      },

      // Function declarations (name before params + brace)
      {
        className: 'title.function',
        begin: /\b[a-zA-Z_]\w*(?=\s*\([^)]*\)\s*[\{=])/,
        relevance: 2
      },

      // Function/method calls - yellow
      {
        className: 'title.function.invoke',
        begin: /\b[a-z_]\w*(?=\s*\()/,
        relevance: 0
      },

      // Method calls after dot
      {
        className: 'title.function.invoke',
        begin: /(?:\.)\w+(?=\s*\()/
      },

      // Property access after dot - light blue
      {
        className: 'property',
        begin: /(?:\.)\w+/,
        relevance: 0
      },

      // Hex numbers
      {
        className: 'number',
        begin: /\b0[xX][0-9a-fA-F]+\b/
      },

      // Float numbers
      {
        className: 'number',
        begin: /\b\d+\.\d+\b/
      },

      // Integer numbers
      {
        className: 'number',
        begin: /\b\d+\b/,
        relevance: 0
      },

      // Hotkey labels
      {
        className: 'symbol',
        begin: /^\s*[#!^+<>*~$]+\w[^\n:]*(?=::)/,
        relevance: 5
      }
    ]
  };
});
