#Requires AutoHotkey v2.0

/**
 * CloudAHK Client - Send AHK v2 scripts to CloudAHK API for remote execution
 *
 * Example:
 *   client := CloudAhkClient("http://localhost:8000")
 *   response := client.Run('FileAppend "test", "*"')
 *   MsgBox "Output: " . response.stdout
 */
class CloudAhkClient {
    __New(baseUrl := "http://localhost:8000") {
        this.baseUrl := RTrim(baseUrl, "/")
        this.endpoint := this.baseUrl . "/v2/run"
    }

    /**
     * Execute AHK v2 code remotely
     * @param code - The AHK v2 script code to execute
     * @param options - Optional parameters:
     *   - timeout: Execution timeout in seconds (default: 10.0)
     *   - args: Array of command-line arguments
     *   - stdin: String to pass to script's stdin
     *   - prepend_requires: Auto-add #Requires directive (default: true)
     * @returns Object with: exit_code, stdout, stderr, timed_out, duration, interpreter
     */
    Run(code, options := "") {
        if !IsObject(options)
            options := Map()

        payload := this.BuildPayload(code, options)

        try {
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("POST", this.endpoint, false)
            http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
            http.Send(payload)

            if http.Status = 200 {
                return this.ParseResponse(http.ResponseText)
            } else {
                throw Error("HTTP " . http.Status . ": " . http.StatusText . "`n" . http.ResponseText)
            }
        } catch as err {
            throw Error("API Request Failed: " . err.Message)
        }
    }

    /**
     * Check API health status
     * @returns Object with: status, interpreter, parser
     */
    Health() {
        try {
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", this.baseUrl . "/health", false)
            http.Send()
            return this.ParseResponse(http.ResponseText)
        } catch as err {
            throw Error("Health check failed: " . err.Message)
        }
    }

    BuildPayload(code, options) {
        payload := Map(
            "code", code,
            "timeout", options.Has("timeout") ? options["timeout"] : 10.0,
            "prepend_requires", options.Has("prepend_requires") ? options["prepend_requires"] : true
        )

        if options.Has("args")
            payload["args"] := options["args"]
        else
            payload["args"] := []

        if options.Has("stdin")
            payload["stdin"] := options["stdin"]

        return this.ToJson(payload)
    }

    ParseResponse(jsonText) {
        ; Simple JSON parser for the response
        response := Map()

        ; Extract exit_code
        if RegExMatch(jsonText, '"exit_code"\s*:\s*(-?\d+)', &exitCodeMatch)
            response["exit_code"] := Integer(exitCodeMatch[1])

        ; Extract stdout
        if RegExMatch(jsonText, '"stdout"\s*:\s*"((?:[^"\\]|\\.)*)"', &stdoutMatch)
            response["stdout"] := this.DecodeJsonString(stdoutMatch[1])
        else
            response["stdout"] := ""

        ; Extract stderr
        if RegExMatch(jsonText, '"stderr"\s*:\s*"((?:[^"\\]|\\.)*)"', &stderrMatch)
            response["stderr"] := this.DecodeJsonString(stderrMatch[1])
        else
            response["stderr"] := ""

        ; Extract timed_out
        if RegExMatch(jsonText, '"timed_out"\s*:\s*(true|false)', &timedOutMatch)
            response["timed_out"] := (timedOutMatch[1] = "true")

        ; Extract duration
        if RegExMatch(jsonText, '"duration"\s*:\s*([0-9.]+)', &durationMatch)
            response["duration"] := Float(durationMatch[1])

        ; Extract interpreter
        if RegExMatch(jsonText, '"interpreter"\s*:\s*"((?:[^"\\]|\\.)*)"', &interpreterMatch)
            response["interpreter"] := this.DecodeJsonString(interpreterMatch[1])

        ; Extract status (for health endpoint)
        if RegExMatch(jsonText, '"status"\s*:\s*"([^"]*)"', &statusMatch)
            response["status"] := statusMatch[1]

        ; Extract parser (for health endpoint)
        if RegExMatch(jsonText, '"parser"\s*:\s*"([^"]*)"', &parserMatch)
            response["parser"] := parserMatch[1]

        return response
    }

    ToJson(obj) {
        if obj is Map {
            pairs := []
            for key, value in obj {
                pairs.Push('"' . key . '":' . this.ToJson(value))
            }
            return "{" . this.Join(pairs, ",") . "}"
        }
        else if obj is Array {
            items := []
            for value in obj {
                items.Push(this.ToJson(value))
            }
            return "[" . this.Join(items, ",") . "]"
        }
        else if obj is String {
            return '"' . this.EncodeJsonString(obj) . '"'
        }
        else if obj is Number {
            return String(obj)
        }
        else if obj = true {
            return "true"
        }
        else if obj = false {
            return "false"
        }
        else {
            return '""'
        }
    }

    EncodeJsonString(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")
        s := StrReplace(s, "`b", "\b")
        s := StrReplace(s, "`f", "\f")
        return s
    }

    DecodeJsonString(s) {
        s := StrReplace(s, "\\", "\")
        s := StrReplace(s, '\"', '"')
        s := StrReplace(s, "\n", "`n")
        s := StrReplace(s, "\r", "`r")
        s := StrReplace(s, "\t", "`t")
        s := StrReplace(s, "\b", "`b")
        s := StrReplace(s, "\f", "`f")
        return s
    }

    Join(arr, delimiter) {
        result := ""
        for item in arr {
            result .= (result = "" ? "" : delimiter) . item
        }
        return result
    }
}
