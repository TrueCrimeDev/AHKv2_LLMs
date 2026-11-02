// highlight-ahk2.js - AutoHotkey v2 syntax grammar for highlight.js
// Matches VS Code Dark+ theme colors for AHK v2 through v2.1-alpha.37

(function() {

  // Names the code declares as classes: class and struct declarations,
  // #Import aliases (as W32Gdi) and #Import lists ({RECT as DM_RECT, POINT}).
  // A grammar can't tell a class from a variable, so a before:highlight plugin
  // scans each block first and DECLARED_NAME colors every use of these names
  // teal. Pages that render a whole document call AHK2Highlight.declarePage()
  // first, so a block also sees names imported in a later block. Names are
  // stored lowercase because AutoHotkey names are case-insensitive.
  var pageNames = new Set();
  var declared = new Set();

  function addName(set, name) {
    if (name && /^[A-Za-z_]\w*$/.test(name)) set.add(name.toLowerCase());
  }

  function collectNames(code, set) {
    var m;
    var decl = /^[ \t]*(?:class|struct)[ \t]+([A-Za-z_]\w*)/gim;
    while ((m = decl.exec(code))) addName(set, m[1]);

    // #Import [Export] module [as Alias] [{A as B, C}]; the list may span lines.
    var imp = /^[ \t]*#Import\b[ \t]*(?:Export\b[ \t]*)?("[^"\n]*"|'[^'\n]*'|[\w.\\]+)?([^\n{;]*)(\{[^}]*\})?/gim;
    while ((m = imp.exec(code))) {
      var alias = /\bas[ \t]+([A-Za-z_]\w*)/i.exec(m[2]);
      if (alias) {
        addName(set, alias[1]);
      } else if (!m[3] && m[1] && /^[A-Za-z_]\w*$/.test(m[1])) {
        addName(set, m[1]);   // #Import Win32 exposes Win32.X
      }
      if (m[3]) {
        var items = m[3].slice(1, -1).replace(/;[^\n]*/g, '').split(',');
        for (var i = 0; i < items.length; i++) {
          var item = items[i].trim();
          var renamed = /^\S+[ \t\r\n]+as[ \t\r\n]+([A-Za-z_]\w*)$/i.exec(item);
          addName(set, renamed ? renamed[1] : item);
        }
      }
    }
    return set;
  }

  // Collect names from every AutoHotkey fence in a Markdown document. Prose is
  // skipped: a sentence like "each enum is a class of constants" must not
  // declare "of".
  function declarePage(markdown) {
    pageNames = new Set();
    var lines = String(markdown || '').split(/\r?\n/);
    var open = null;
    var buf = [];
    for (var i = 0; i < lines.length; i++) {
      var f = /^[ \t]*(`{3,}|~{3,})[ \t]*([\w+-]*)/.exec(lines[i]);
      if (open === null) {
        if (f) {
          open = { mark: f[1], ahk: /^(?:ahk2?|autohotkey|cpp|)$/i.test(f[2]) };
          buf = [];
        }
      } else if (f && !f[2] && f[1].charAt(0) === open.mark.charAt(0) && f[1].length >= open.mark.length) {
        if (open.ahk) collectNames(buf.join('\n'), pageNames);
        open = null;
      } else {
        buf.push(lines[i]);
      }
    }
    return pageNames;
  }

  window.AHK2Highlight = { declarePage: declarePage, collectNames: collectNames };

  hljs.addPlugin({
    'before:highlight': function(data) {
      var lang = data.language && hljs.getLanguage(data.language);
      if (!lang || lang !== hljs.getLanguage('ahk2')) return;
      declared = collectNames(data.code, new Set(pageNames));
    }
  });

  hljs.registerLanguage('ahk2', function(hljs) {

    // Struct/class declarations -- keyword + the type name highlighted as a
    // class title (teal). Uses the begin-array form so the captured name gets
    // its own scope; a plain `match` mode is terminal and would drop `contains`.
    // Keywords are case-insensitive in AutoHotkey; alpha.37 code writes `struct`.
    var STRUCT_DEF = {
      begin: [/\b[Ss]truct\b/, /\s+/, /[A-Za-z_]\w*/],
      beginScope: { 1: 'keyword', 3: 'title.class' },
      relevance: 10
    };

    var CLASS_DEF = {
      begin: [/\b[Cc]lass\b/, /\s+/, /[A-Za-z_]\w*/],
      beginScope: { 1: 'keyword', 3: 'title.class' }
    };

    // extends keyword + parent class name
    var EXTENDS_DEF = {
      begin: [/\bextends\b/, /\s+/, /[A-Za-z_]\w*/],
      beginScope: { 1: 'keyword', 3: 'title.class' }
    };

    var LINE_COMMENT = hljs.COMMENT(';', '$');

    var STRING_DOUBLE = {
      className: 'string',
      begin: '"',
      end: '"',
      contains: [{ begin: /`./ }]
    };

    var STRING_SINGLE = {
      className: 'string',
      begin: "'",
      end: "'",
      contains: [{ begin: /`./ }]
    };

    // #Import: the directive pink, the module path a string, aliases and the
    // names in a {...} list teal, `as` and the punctuation grey (as VS Code).
    var IMPORT_ALIAS = {
      begin: [/\bas\b/, /\s+/, /[A-Za-z_]\w*/],
      beginScope: { 1: 'punctuation', 3: 'title.class' }
    };

    var IMPORT_NAME = {
      className: 'title.class',
      begin: /[A-Za-z_]\w*/,
      relevance: 0
    };

    var IMPORT_LIST = {
      begin: /\{/,
      end: /\}/,
      beginScope: 'punctuation',
      endScope: 'punctuation',
      contains: [
        LINE_COMMENT,
        IMPORT_ALIAS,
        IMPORT_NAME,
        { className: 'operator', begin: /\*/ },
        { className: 'punctuation', begin: /,/ }
      ]
    };

    var IMPORT = {
      begin: /#Import\b/,
      beginScope: 'meta',
      end: /$/,
      contains: [
        LINE_COMMENT,
        { className: 'keyword', begin: /\bExport\b/ },
        STRING_DOUBLE,
        STRING_SINGLE,
        IMPORT_LIST,
        IMPORT_ALIAS,
        IMPORT_NAME
      ],
      relevance: 10
    };

    // #Include <Lib> / #Include path: the argument is a string.
    var INCLUDE = {
      begin: /#Include(?:Again)?\b/,
      beginScope: 'meta',
      end: /$/,
      contains: [
        hljs.COMMENT(/[ \t];/, '$'),
        { className: 'string', begin: /[^\s;]/, end: /(?=[ \t]+;|$)/ }
      ],
      relevance: 10
    };

    // #Requires AutoHotkey v2.1-alpha.37: the whole line is the directive.
    var REQUIRES = {
      className: 'meta',
      begin: /#Requires\b/,
      end: /$/,
      contains: [hljs.COMMENT(/[ \t];/, '$')],
      relevance: 10
    };

    // Typed property declarations at the start of a line: `p: DM_POINT[3]`,
    // `GdiplusVersion: UInt32`. The type must start with a capital, which
    // keeps out `:=`, `::` hotkeys and `default:` labels.
    var TYPED_FIELD = {
      begin: [/^[ \t]*/, /(?!(?:default|case)\b)[A-Za-z_]\w*/, /[ \t]*:[ \t]*/, /[A-Z]\w*/],
      beginScope: { 2: 'property', 3: 'punctuation', 4: 'type' },
      relevance: 0
    };

    // A name the code declared as a class or imported (see collectNames).
    // Any other identifier is handed on to the modes after this one.
    var DECLARED_NAME = {
      className: 'title.class',
      begin: /\b[A-Za-z_]\w*\b/,
      'on:begin': function(match, response) {
        if (!declared.has(match[0].toLowerCase())) response.ignoreMatch();
      },
      relevance: 0
    };

    // Built-in functions that use parentheses
    var BUILTIN_FUNCS = '(?:' + [
      'MsgBox', 'InputBox', 'ToolTip', 'FileOpen', 'FileRead', 'FileAppend',
      'DllCall', 'CallbackCreate', 'CallbackFree', 'ComObject', 'RegRead',
      'RegWrite', 'WinExist', 'WinActive', 'WinActivate', 'WinClose', 'WinWait',
      'WinWaitActive', 'WinGetTitle', 'WinGetClass', 'WinGetPos', 'WinMove',
      'WinHide', 'WinShow', 'WinSetTitle', 'WinGetText', 'WinMinimize',
      'WinMaximize', 'WinRestore', 'WinGetControls',
      'ControlGetText', 'ControlSetText', 'ControlClick', 'ControlSend', 'ControlFocus',
      'Send', 'SendInput', 'SendEvent', 'Click', 'MouseMove', 'MouseClick',
      'MouseGetPos', 'KeyWait', 'GetKeyState', 'Hotkey', 'SetTimer', 'Sleep',
      'Run', 'RunWait', 'ProcessExist', 'ProcessClose', 'ProcessWait',
      'EnvGet', 'EnvSet', 'SysGet', 'MonitorGet', 'MonitorGetCount',
      'Format', 'FormatTime', 'StrLen', 'StrLower', 'StrUpper', 'StrReplace',
      'StrSplit', 'SubStr', 'InStr', 'RegExMatch', 'RegExReplace',
      'Trim', 'LTrim', 'RTrim', 'Sort', 'Type', 'IsSet', 'IsObject',
      'HasProp', 'HasOwnProp', 'HasMethod', 'HasBase', 'ObjOwnPropCount',
      'GetOwnPropDesc', 'DefineProp', 'Sqrt', 'Abs', 'Min', 'Max', 'Mod',
      'Round', 'Floor', 'Ceil', 'Log', 'Ln', 'Exp',
      'Map', 'Array', 'Buffer', 'Gui', 'Menu', 'MenuBar',
      'OnMessage', 'OnExit', 'OnError', 'OnClipboardChange',
      'SetTitleMatchMode', 'DetectHiddenWindows', 'CoordMode', 'SendMode',
      'SetWorkingDir', 'Persistent', 'Chr', 'Ord', 'NumGet', 'NumPut',
      'StrGet', 'StrPut', 'FileExist', 'DirExist', 'String',
      'Reload', 'ExitApp', 'Suspend', 'Pause'
    ].join('|') + ')';

    return {
      name: 'AutoHotkey v2',
      aliases: ['ahk', 'ahk2', 'autohotkey'],
      case_insensitive: false,
      contains: [
        // Block comments
        hljs.COMMENT('/\\*', '\\*/'),

        // Line comments
        LINE_COMMENT,

        // Directives with arguments
        IMPORT,
        INCLUDE,
        REQUIRES,

        // Struct definition
        STRUCT_DEF,

        // Class definition
        CLASS_DEF,

        // extends keyword
        EXTENDS_DEF,

        // Other directives - purple
        {
          className: 'meta',
          begin: /#(?:Module|SingleInstance|HotIf|HotIfTimeout|DllLoad|Warn|ErrorStdOut|NoTrayIcon|EnableEval|CrashLog|Hotstring|UseHook|InputLevel|SuspendExempt|WinActivateForce|MaxThreads|MaxThreadsBuffer|MaxThreadsPerHotkey|ClipboardTimeout)\b/,
          relevance: 10
        },

        // Strings
        STRING_DOUBLE,
        STRING_SINGLE,

        // Typed property declarations
        TYPED_FIELD,

        // Typed field annotations
        {
          className: 'type',
          begin: /\b(?:i8|u8|i16|u16|i32|u32|i64|u64|iptr|uptr|Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|IntPtr|UIntPtr|Float32|Float64)\b/,
          relevance: 8
        },

        // Control flow keywords - blue
        {
          className: 'keyword',
          begin: /\b(?:if|else|for|while|loop|return|break|continue|switch|case|default|try|catch|finally|throw|static|global|local|export|in|not|and|or|is|this|super|unset)\b/
        },

        // Built-in variables (A_ prefix) - light blue
        {
          className: 'variable.language',
          begin: /\bA_\w+\b/
        },

        // Built-in functions/commands -- match with OR without parens (command style)
        {
          className: 'built_in',
          begin: new RegExp('\\b' + BUILTIN_FUNCS + '\\b'),
          relevance: 0
        },

        // Declared and imported class names - teal
        DECLARED_NAME,

        // Punctuation: parens, brackets, braces -- white
        {
          className: 'punctuation',
          begin: /[()[\]{}]/,
          relevance: 0
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

        // Colons (field type separator, ternary) -- white
        {
          className: 'punctuation',
          begin: /:/,
          relevance: 0
        },

        // Commas -- white
        {
          className: 'punctuation',
          begin: /,/,
          relevance: 0
        },

        // Constructor/class calls (PascalCase + parens) - yellow
        {
          className: 'title.function.invoke',
          begin: /\b[A-Z]\w*(?=\s*\()/,
          relevance: 0
        },

        // Function declarations
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
          begin: /^\s*[#!^+<>*~$]*\w[^\n:]*(?=::)/,
          relevance: 5
        }
      ]
    };
  });

})();
