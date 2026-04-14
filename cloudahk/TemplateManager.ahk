#Requires AutoHotkey v2.0

; =====================================================
; Template Manager Class
; Handles loading templates and variable substitution
; =====================================================

class TemplateManager {
    __New(templateDir := "templates", apiEndpoint := "http://localhost:8000/v2/run") {
        this.templateDir := templateDir
        this.client := CloudAhkClient(apiEndpoint)
    }

    /**
     * Generate code from a template file
     * @param templateName - Name of template file (without path)
     * @param variables - Map of variable names to values (optional)
     * @returns Generated AHK code or throws error
     */
    Generate(templateName, variables := "") {
        ; Load template
        templatePath := this.templateDir . "\" . templateName
        if !FileExist(templatePath)
            throw Error("Template not found: " . templatePath)

        template := FileRead(templatePath)

        ; Substitute variables if provided
        if IsObject(variables) {
            for key, value in variables {
                placeholder := "{{" . key . "}}"
                template := StrReplace(template, placeholder, value)
            }
        }

        ; Send to API
        result := this.client.Run(template)
        response := this.ParseJson(result)

        ; Check for errors
        if response["exit_code"] != 0
            throw Error("Code generation failed:`n" . response["stderr"])

        return response["stdout"]
    }

    /**
     * Generate and save code to a file
     * @param templateName - Name of template file
     * @param outputFile - Output file path
     * @param variables - Map of variable names to values (optional)
     */
    GenerateToFile(templateName, outputFile, variables := "") {
        code := this.Generate(templateName, variables)
        FileAppend code, outputFile
        return code
    }

    /**
     * List available templates
     * @returns Array of template file names
     */
    ListTemplates() {
        templates := []
        Loop Files, this.templateDir . "\*.ahk"
            templates.Push(A_LoopFileName)
        return templates
    }

    ParseJson(jsonText) {
        response := Map()
        if RegExMatch(jsonText, '"exit_code"\s*:\s*(-?\d+)', &exitCodeMatch)
            response["exit_code"] := Integer(exitCodeMatch[1])
        if RegExMatch(jsonText, '"stdout"\s*:\s*"((?:[^"\\]|\\.)*)"', &stdoutMatch)
            response["stdout"] := this.DecodeJsonString(stdoutMatch[1])
        if RegExMatch(jsonText, '"stderr"\s*:\s*"((?:[^"\\]|\\.)*)"', &stderrMatch)
            response["stderr"] := this.DecodeJsonString(stderrMatch[1])
        return response
    }

    DecodeJsonString(s) {
        s := StrReplace(s, '\"', '"')
        s := StrReplace(s, "\n", "`n")
        s := StrReplace(s, "\r", "`r")
        s := StrReplace(s, "\t", "`t")
        s := StrReplace(s, "\\", "\")
        return s
    }
}

class CloudAhkClient {
    __New(endpoint := "http://localhost:8000/v2/run") {
        this.endpoint := endpoint
    }

    Run(code) {
        payload := '{"code":"' . this.EncodeString(code) . '"}'
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", this.endpoint, false)
        http.SetRequestHeader("Content-Type", "application/json")
        http.Send(payload)
        return http.ResponseText
    }

    EncodeString(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")
        return s
    }
}
