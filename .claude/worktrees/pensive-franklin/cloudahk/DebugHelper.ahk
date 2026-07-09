#Requires AutoHotkey v2.0

/**
 * Debug Helper for CloudAHK Remote Execution
 * Captures debug output and sends to stdout for remote debugging
 */

class DebugHelper {
    static debugOutput := ""
    static isEnabled := true

    /**
     * Log a debug message
     * @param message - The debug message
     * @param level - Debug level (INFO, WARN, ERROR)
     */
    static Log(message, level := "INFO") {
        if !this.isEnabled
            return

        timestamp := FormatTime(A_Now, "HH:mm:ss")
        entry := "[" . timestamp . "] [" . level . "] " . message . "`n"
        this.debugOutput .= entry
    }

    /**
     * Log variable value
     * @param varName - Variable name
     * @param value - Variable value
     */
    static LogVar(varName, value) {
        if !this.isEnabled
            return

        valueStr := this.ValueToString(value)
        this.Log(varName . " = " . valueStr, "DEBUG")
    }

    /**
     * Log function entry
     * @param funcName - Function name
     * @param params - Parameters (optional)
     */
    static Enter(funcName, params := "") {
        if !this.isEnabled
            return

        msg := "ENTER " . funcName
        if params != ""
            msg .= "(" . params . ")"
        this.Log(msg, "TRACE")
    }

    /**
     * Log function exit
     * @param funcName - Function name
     * @param returnValue - Return value (optional)
     */
    static Exit(funcName, returnValue := "") {
        if !this.isEnabled
            return

        msg := "EXIT " . funcName
        if returnValue != ""
            msg .= " => " . this.ValueToString(returnValue)
        this.Log(msg, "TRACE")
    }

    /**
     * Log error with stack trace
     * @param err - Error object
     */
    static LogError(err) {
        this.Log("ERROR: " . err.Message, "ERROR")
        this.Log("  File: " . err.File . ":" . err.Line, "ERROR")
        if err.HasProp("What")
            this.Log("  What: " . err.What, "ERROR")
        if err.HasProp("Extra")
            this.Log("  Extra: " . err.Extra, "ERROR")
    }

    /**
     * Assert condition
     * @param condition - Condition to check
     * @param message - Message if assertion fails
     */
    static Assert(condition, message := "Assertion failed") {
        if !condition {
            this.Log("ASSERTION FAILED: " . message, "ERROR")
            throw Error(message)
        }
    }

    /**
     * Output all debug info to stdout
     */
    static Flush() {
        if this.debugOutput != ""
            FileAppend "=== DEBUG OUTPUT ===`n" . this.debugOutput . "=== END DEBUG ===`n", "*"
    }

    /**
     * Get debug output as string
     */
    static GetOutput() {
        return this.debugOutput
    }

    /**
     * Clear debug output
     */
    static Clear() {
        this.debugOutput := ""
    }

    /**
     * Convert value to string for logging
     */
    static ValueToString(value) {
        if IsObject(value) {
            if value is Array {
                items := []
                for item in value
                    items.Push(this.ValueToString(item))
                return "[" . this.Join(items, ", ") . "]"
            }
            else if value is Map {
                pairs := []
                for key, val in value
                    pairs.Push(key . ": " . this.ValueToString(val))
                return "{" . this.Join(pairs, ", ") . "}"
            }
            else {
                return Type(value)
            }
        }
        else if value is String {
            return '"' . value . '"'
        }
        else {
            return String(value)
        }
    }

    static Join(arr, delimiter) {
        result := ""
        for item in arr {
            result .= (result = "" ? "" : delimiter) . item
        }
        return result
    }
}

/**
 * Wrap code execution with automatic debug output
 * @param code - Function to execute
 * @param autoFlush - Auto flush debug output (default: true)
 */
RunWithDebug(code, autoFlush := true) {
    DebugHelper.Clear()
    DebugHelper.Log("Starting execution...")

    try {
        result := code()
        DebugHelper.Log("Execution completed successfully")
        if autoFlush
            DebugHelper.Flush()
        return result
    }
    catch Error as err {
        DebugHelper.LogError(err)
        if autoFlush
            DebugHelper.Flush()
        throw err
    }
}
