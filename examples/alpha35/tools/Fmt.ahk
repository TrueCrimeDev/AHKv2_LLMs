; tools\Fmt.ahk -- a helper library that is private to tools\.
global FmtFile := A_LineFile

Heading(text) => text "`n" StrReplace(Format("{:" StrLen(text) "}", ""), " ", "=")
Bullet(n, text) => Format("  {}. {}", n, text)
