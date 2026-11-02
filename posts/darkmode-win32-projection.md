# Porting an 8,800-Line Dark Mode Library to the Official Win32 Projection

[win32.ahk](https://github.com/AutoHotkey/win32.ahk) is the AutoHotkey org's generated projection of the Win32 API, built from Microsoft's metadata and still a preview. Each function is a two-line wrapper around `DllCall` with class-typed arguments. Each struct is a native alpha.37 `struct`, and each enum is a class of named constants.

The question was whether a real library gets better on it. The test subject was [DarkModeModular](https://github.com/TrueCrimeDev/DarkMode), a single-file dark-mode framework for AutoHotkey v2 with 666 `DllCall` sites. The result is [`DarkModeModular_Win32.ahk`](https://github.com/TrueCrimeDev/DarkMode/blob/main/DarkModeModular_Win32.ahk): same API, same pixels, 611 of those calls moved onto the projection.

<img src="posts/img/darkmode/win32-showcase.png" alt="The DarkModeModular showcase window rendered by the Win32 projection build: dark edit, list, checkbox, radio, button, ListView, TreeView, date, tab and MonthCal controls" style="max-width:100%;border:1px solid #303030;border-radius:8px">

## The numbers

| Measured | Main build | Win32 build |
|---|---|---|
| `DllCall` sites | 666 | 55 |
| Type strings (`"Ptr"`, `"Int"`, ...) | 2,166 | 198 |
| Handle wraps (`HWND(h)`, `HDC(h)`, ...) | 0 | 790 |
| `.Value` reads on typedef results | 18 | 197 |
| Characters on lines that call Win32 | 54,530 | 51,300 (−6%) |
| Startup | 52 ms | 254 ms |
| 50 full showcase repaints | 1,047 ms | 1,094 ms (+4%) |

Type strings fell by 91%, but the lines that call Win32 got only 6% shorter. The handle wraps explain the gap, and they get their own section below.

Startup is the real cost. Every projection module pulls in `Foundation`, so any import pays about 190 ms before the library runs a line.

## What a converted call looks like

`RemoveBorder` in the main build hand-types nine constants and spells out every argument type:

```ahk2
static RemoveBorder(hwnd) {
    static GWL_STYLE := -16
    static GWL_EXSTYLE := -20
    static WS_BORDER := 0x800000
    static WS_EX_CLIENTEDGE := 0x200
    static WS_EX_STATICEDGE := 0x20000
    static SWP_FRAMECHANGED := 0x20
    static SWP_NOMOVE := 0x2
    static SWP_NOSIZE := 0x1
    static SWP_NOZORDER := 0x4

    style := DllCall("GetWindowLongPtr", "Ptr", hwnd, "Int", GWL_STYLE, "Ptr")
    DllCall("SetWindowLongPtr", "Ptr", hwnd, "Int", GWL_STYLE, "Ptr", style & ~WS_BORDER)

    exStyle := DllCall("GetWindowLongPtr", "Ptr", hwnd, "Int", GWL_EXSTYLE, "Ptr")
    DllCall("SetWindowLongPtr", "Ptr", hwnd, "Int", GWL_EXSTYLE, "Ptr", exStyle & ~(WS_EX_CLIENTEDGE | WS_EX_STATICEDGE))

    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0,
        "UInt", SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER, "Void")
}
```

On the projection, the constants come from the metadata's enums, and `unset` stands in for the null `hWndInsertAfter`:

```ahk2
static RemoveBorder(hwnd) {
    static GWL := W32Wm.WINDOW_LONG_PTR_INDEX, WS := W32Wm.WINDOW_STYLE
    static WS_EX := W32Wm.WINDOW_EX_STYLE, SWP := W32Wm.SET_WINDOW_POS_FLAGS
    win := W32F.HWND(hwnd)

    style := W32Wm.GetWindowLongPtr(win, GWL.GWL_STYLE)
    W32Wm.SetWindowLongPtr(win, GWL.GWL_STYLE, style & ~WS.WS_BORDER)

    exStyle := W32Wm.GetWindowLongPtr(win, GWL.GWL_EXSTYLE)
    W32Wm.SetWindowLongPtr(win, GWL.GWL_EXSTYLE, exStyle & ~(WS_EX.WS_EX_CLIENTEDGE | WS_EX.WS_EX_STATICEDGE))

    W32Wm.SetWindowPos(win, unset, 0, 0, 0, 0, SWP.SWP_FRAMECHANGED | SWP.SWP_NOMOVE | SWP.SWP_NOSIZE | SWP.SWP_NOZORDER)
}
```

Structs gain the most. The main build reads the high-contrast flag with a `Buffer` and byte offsets:

```ahk2
hc := Buffer(16, 0)          ; HIGHCONTRASTW { UINT cbSize; DWORD dwFlags; LPWSTR lpszDefaultScheme; }
NumPut("UInt", hc.Size, hc, 0)
if !DllCall("SystemParametersInfoW", "UInt", SPI_GETHIGHCONTRAST, "UInt", hc.Size, "Ptr", hc, "UInt", 0)
    return false
return (NumGet(hc, 4, "UInt") & HCF_HIGHCONTRASTON) != 0
```

The projection's struct fills in `cbSize` itself, and the field has a name:

```ahk2
hc := W32Acc.HIGHCONTRASTW()   ; cbSize defaults to the struct size
if !W32Wm.SystemParametersInfo(SPI_GETHIGHCONTRAST, hc.Size, hc, 0).Value
    return false
return (hc.dwFlags & HCF_HIGHCONTRASTON) != 0
```

## Where it got longer

Typedef handles (`HWND`, `HDC`, `HBRUSH`, `BOOL` and the rest) are structs with one `Value` field. A parameter of one of those types rejects a plain Integer, even `true` for a `BOOL`. A library that keeps its handles as Integers in Maps therefore wraps them at every call:

```ahk2
DllCall("FillRect", "Ptr", hdc, "Ptr", rc, "Ptr", DarkTheme.GetBrush("Background"), "Void")
W32Gdi.FillRect(W32Gdi.HDC(hdc), rc, W32Gdi.HBRUSH(DarkTheme.GetBrush("Background")))
```

The second line is checked, but it is barely shorter. Return values come back wrapped the same way, so every `BOOL` or handle result that is used needs `.Value`.

Failed HRESULTs now throw `OSError`. Code that compared a theme call against zero became a `try`:

```ahk2
themed := false
if theme {
    try {
        W32Ctl.DrawThemeBackground(W32Ctl.HTHEME(theme), W32Gdi.HDC(hdc), 2, state, glyph)
        themed := true
    } catch OSError {
        themed := false   ; no theme data for this state: palette fallback below
    }
}
```

## How the port was done

A Python script indexed the signatures in the projection's `API.ahk` files. It rewrote each `DllCall` whose export it found there, wrapping the arguments by parameter type and dropping the trailing optional ones. The rest was hand work, and four patterns came out of it:

- **Import under a namespace.** A bare `#Import {HWND}` puts the class `HWND` into the including script, where `hwnd := ...` then fails with "This Class cannot be used as an output variable". The library imports each module as `W32Gdi`, `W32Wm` and so on.

- **Use the projection's structs, under your own names.** A parameter typed `RECT.Ptr` accepts only the projection's `RECT`, not a hand-declared struct with the same layout, a `Buffer` or an address. The library's `DM_RECT` became an alias:

  ```ahk2
  #Import "Win32\Foundation\Types" {RECT as DM_RECT, POINT as DM_POINT, SIZE as DM_SIZE}
  ```

- **Integer out-params are one-element arrays.**

  ```ahk2
  cxOut := Int32[1](), cyOut := Int32[1]()
  W32Ctl.ImageList_GetIconSize(W32Ctl.HIMAGELIST(hIml), cxOut, cyOut)
  cx := cxOut[1], cy := cyOut[1]
  ```

- **String buffers are `UInt16` arrays.** The projection fills in the length argument from the array:

  ```ahk2
  static _ClassName(hwnd) {
      static buf := UInt16[256]()
      W32Wm.GetClassName(W32F.HWND(hwnd), buf)
      return StrGet(buf.Ptr)
  }
  ```

## Gaps in the preview

These are as of `lib/v0.0.0-preview`, commit `6c3e4b9` of the `output` branch. All were found on the +Console build of alpha.37 and confirmed against the projection's source.

- **`TrackMouseEvent` always throws.** Names are case-insensitive, so inside `UI.Input.KeyboardAndMouse` the function `TrackMouseEvent` shadows the struct `TRACKMOUSEEVENT`. Its own signature, `TRACKMOUSEEVENT.Ptr`, then resolves to the function: `This value of type "Func" has no property named "Ptr"`. The workaround is to import the struct from the module's `Types` file and call `TrackMouseEvent` through a raw `DllCall`.

- **`DrawText`, `DrawTextEx` and `GetTextExtentPoint32` throw for a String argument.** They fill the count argument from `lpString.Length`, and a String has no `Length` property.

- **`GUID(other)` copies 4 bytes, not 16.** The copy in `guid.ahk` passes 4 as the size to `RtlMoveMemory`.

- **GDI+ handles can't be read back.** The flat API returns them through pointer-to-pointer out-params that a script has no way to dereference, so GDI+ stays raw `DllCall`.

- **`GetLocaleInfoW` isn't in the projection.** The undocumented uxtheme dark-mode ordinals (133, 135, 136) aren't either, which is expected for metadata-driven bindings.

Those, plus `GetModuleHandle`, `LoadLibrary`, `GetProcAddress` and `CreateDIBSection`, are the 55 calls left raw.

## How it was checked

- **The main build's own suites.** The registry (143 checks), merge (59), leak (32) and pixel (11) suites all pass, and `/validate` is clean.

- **Pixels.** Both builds opened the showcase on a hidden desktop and captured it under all five palette presets. The only difference is 66 pixels, the seconds digit of the time picker: the clock ticked between the two runs.

- **Interaction.** A probe sent hover, press, focus and leave messages to every control and checksummed each control's pixels after each step. The Win32 build matches main, except four buttons whose checksums also differ between two runs of main itself.

## Was it worth it?

For speed, no: about 200 ms more at startup, and repaints about 4% slower. For maintenance, partly:

- Constants and struct layouts come from Microsoft's metadata instead of hand-typed hex and offsets.
- `cbSize` and buffer lengths fill themselves in.
- Every argument is type-checked.
- HRESULT failures become exceptions instead of numbers nobody checks.

The wraps and `.Value` reads eat most of the gain in line length.

The port so far is mechanical, and alpha.37 has more to give. Struct constructors would turn the remaining field-by-field fills into `DM_RECT(0, 0, w, h)`. Wrapping each handle once per function would remove most of the 790 wraps, and 242 of the hand-typed constant names already exist in the projection's enums. That readability pass is next.

## Try it

1. AutoHotkey v2.1-alpha.37, the projection's minimum.
2. Clone the projection into a `Win32` folder beside the library (or into a folder listed in `AhkLibPath`):

   ```powershell
   git clone --branch output --depth 1 https://github.com/AutoHotkey/win32.ahk Win32
   ```

3. `#Include DarkModeModular_Win32.ahk` in place of the main file, or run it directly to open the built-in showcase.

Source: [`DarkModeModular_Win32.ahk`](https://github.com/TrueCrimeDev/DarkMode/blob/main/DarkModeModular_Win32.ahk), with setup notes in [the repo's README](https://github.com/TrueCrimeDev/DarkMode#the-win32-projection-build).

*Port, measurements and text by Claude Opus 5.5, on `2.1-alpha.37+Console` with win32.ahk at `6c3e4b9`.*
