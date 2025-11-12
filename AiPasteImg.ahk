;@Ahk2Exe-ExeName AiImgPaste.exe
;@Ahk2Exe-SetMainIcon sflood.ico
;@Ahk2Exe-SetDescription "Paste clipboard image to @path with tray settings"
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetProductVersion 1.0.0
;@Ahk2Exe-SetProductName "AiImgPaste"
;@Ahk2Exe-SetCompanyName "StillFlood"
;@Ahk2Exe-SetCopyright "(c) 2025 StillFlood"


; ====== 常量 & 配置 ======
APP_NAME  := "AiImgPaste"
CFG_DIR   := A_AppData "\" APP_NAME
CFG_FILE  := CFG_DIR "\config.ini"
DEFAULTS  := Map(
  "SaveRoot",    A_Desktop "\Screens",
  "UseWSLPath",  "0",            ; 0/1
  "AtPrefix",    "@",            ; e.g. "@", "@file "
  "Hotkey",      "!+v",          ; Alt+Shift+V
  "ShowNotify",  "1",             ; 是否显示托盘通知
  "AfterText",   " "             ; 路径后自定义文本（可为空）
)

global g := Map()  ; 运行时配置

; ====== 入口 ======
Init()
BuildTray()
BindHotkey()
return  ; ——— 让自动执行段结束，等待消息循环 ———

; ====== 初始化/读写配置 ======
Init() {
  global g
  if !DirExist(CFG_DIR)
    DirCreate(CFG_DIR)
  ; 加载或写入默认
  for k, v in DEFAULTS
    g[k] := IniRead(CFG_FILE, "config", k, v)
}

SaveConfig() {
  global g
  if !DirExist(CFG_DIR)
    DirCreate(CFG_DIR)
  for k, v in g
    IniWrite(v, CFG_FILE, "config", k)
}

; ====== 托盘菜单 ======
BuildTray() {
  A_IconTip := APP_NAME
  A_TrayMenu.Delete()  ; 清空默认菜单
  A_TrayMenu.Add("设置(&S)...", ShowSettings)
  A_TrayMenu.Add("打开保存目录(&O)", (*) => Run('explorer.exe "' g["SaveRoot"] '"'))
  A_TrayMenu.Add()
  A_TrayMenu.Add("开机自启(&A)", ToggleAutostart)
  A_TrayMenu.Check(GetAutostart())  ; 勾选状态
  A_TrayMenu.Add()
  A_TrayMenu.Add("重载(&R)", (*) => Reload())
  A_TrayMenu.Add("退出(&Q)", (*) => ExitApp())
}

; ====== 自启 ======
GetAutostart() {
  link := A_Startup "\" APP_NAME ".lnk"
  return FileExist(link)
}
ToggleAutostart(ItemName, ItemPos, MyMenu) {
  link := A_Startup "\" APP_NAME ".lnk"
  if GetAutostart() {
    FileDelete(link)
    A_TrayMenu.Uncheck("开机自启(&A)")
  } else {
    FileCreateShortcut(A_ScriptFullPath, link,,,"",A_ScriptFullPath)  ; 自启动
    A_TrayMenu.Check("开机自启(&A)")
  }
}

; ====== 绑定热键（可动态变更） ======
UnbindHotkey() {
  hk := g["Hotkey"]
  if IsSet(hk)
    Hotkey(hk, "", "Off")
}
BindHotkey() {
  hk := g["Hotkey"]
  try Hotkey(hk, DoPaste, "On")
  catch {
    MsgBox("热键绑定失败: " hk "`n改为默认 !+v（Alt+Shift+V）")
    g["Hotkey"] := "!+v"
    Hotkey("!+v", DoPaste, "On")
  }
}

; ====== 主逻辑：保存图片/取文件 → 粘贴 @路径 ======
DoPaste(*) {
  try {
    EnsureDir(g["SaveRoot"])
    path := GetPathFromClipboardOrDumpBitmap(g["SaveRoot"])
    if (!path) {
      Tip("未检测到图片或文件路径，请先截屏或复制文件。", 2000)
      return
    }
    outPath := (g["UseWSLPath"] == "1") ? WinToWsl(path) : path
    ; 支持 \n 转换为换行；若 AfterText 不为空，自动加一个空格分隔
    suffix := StrReplace(g["AfterText"], "\n", "`n")
    txt := g["AtPrefix"] . outPath . (suffix != "" ? " " . suffix : "")
    A_Clipboard := txt
    Sleep 50
    Send "^v"
    Tip("已粘贴: " txt, 1500)
  } catch as e {
    MsgBox "错误: " e.Message
  }
}

; ====== 通知封装（受 ShowNotify 控制） ======
Tip(msg, dur:=1500, title:=APP_NAME) {
  if (g["ShowNotify"] == "1")
    TrayTip(title, msg, dur) ; v2：三参数
}

; ====== GUI：设置窗口 ======
ShowSettings(*) {
  static w
  if IsSet(w) && w {
    w.Show()
    return
  }
  w := Gui("+AlwaysOnTop +OwnDialogs", APP_NAME " - 设置")
  w.SetFont("s10")

  w.Add("Text",, "保存目录：")
  tSave := w.Add("Edit", "w360", g["SaveRoot"])
  btnSel := w.Add("Button", "x+8", "选择...")
  btnSel.OnEvent("Click", (*) => (
    w.Opt("-AlwaysOnTop")
  , dir := DirSelect(g["SaveRoot"], 3, "选择保存图片的目录")
  , w.Opt("+AlwaysOnTop")
  , dir ? (tSave.Value := dir) : 0
  ))

  w.Add("Text", "xm y+12", "前缀：")
  tPrefix := w.Add("Edit", "w150", g["AtPrefix"])
  w.Add("Text", "x+10 yp+3", "(例如 @ 或 @file )")

  ; UseWSL 开关
  w.Add("Checkbox", "xm y+12 vWSL", "使用 WSL 路径（/mnt/...）").Value := (g["UseWSLPath"] == "1")

  ; ShowNotify 开关（新增）
  w.Add("Checkbox", "xm y+8 vShowNotify", "显示托盘通知").Value := (g["ShowNotify"] == "1")

  w.Add("Text", "xm y+12", "后缀文字：")
  tAfter := w.Add("Edit", "w360", g["AfterText"])
  w.Add("Text", "x+10 yp+3", "示例：调用XXX MCP识别图片（支持 \n 为换行）")

  w.Add("Text", "xm y+12", "热键：")
  tHotkey := w.Add("Edit", "w120", g["Hotkey"])
  w.Add("Text", "x+10 yp+3", "示例：!+v = Alt+Shift+V ； ^!p = Ctrl+Alt+P")

  btnOK := w.Add("Button", "xm y+16 w80 Default", "保存")
  btnCancel := w.Add("Button", "x+8 w80", "取消")

  btnOK.OnEvent("Click", (*) => (
    g["SaveRoot"]    := tSave.Value
  , g["AtPrefix"]    := tPrefix.Value
  , g["AfterText"]   := tAfter.Value
  , g["UseWSLPath"]  := (w["WSL"].Value ? "1" : "0")
  , g["ShowNotify"]  := (w["ShowNotify"].Value ? "1" : "0")
  , hkNew := Trim(tHotkey.Value)
  , hkNew := (hkNew="" ? g["Hotkey"] : hkNew)
  , UnbindHotkey()
  , g["Hotkey"] := hkNew
  , BindHotkey()
  , SaveConfig()
  , Tip("设置已保存", 1200)
  , w.Hide()
  ))
  btnCancel.OnEvent("Click", (*) => w.Hide())

  w.Show()
}

; ====== 工具函数 ======
EnsureDir(dir) {
  if !DirExist(dir)
    DirCreate(dir)
}

GetPathFromClipboardOrDumpBitmap(saveRoot) {
  files := GetClipboardFiles()
  if (files.Length)
    return files[1]

  if (ClipboardHasBitmap()) {
    tsDir := FormatTime(A_Now, "yyyy-MM")
    dir := saveRoot "\" tsDir
    EnsureDir(dir)
    ts := FormatTime(A_Now, "yyyyMMdd-HHmmss")
    outPng := dir "\" ts ".png"
    if (DumpClipboardBitmapToPng(outPng))
      return outPng
  }

  clip := A_Clipboard
  if (clip ~= "i)^(?:[A-Za-z]:\\|\\\\|file:///)")
    return NormalizeFileUrlOrTextPath(clip)

  return ""
}

GetClipboardFiles() {
  arr := []
  if !DllCall("OpenClipboard", "Ptr", 0)
    return arr
  hDrop := DllCall("GetClipboardData", "UInt", 15, "Ptr") ; CF_HDROP=15
  if (hDrop) {
    pDrop := DllCall("GlobalLock", "Ptr", hDrop, "Ptr")
    if (pDrop) {
      cnt := DllCall("shell32\DragQueryFileW", "Ptr", pDrop, "UInt", 0xFFFFFFFF, "Ptr", 0, "UInt", 0, "UInt")
      if (cnt > 0) {
        len := DllCall("shell32\DragQueryFileW", "Ptr", pDrop, "UInt", 0, "Ptr", 0, "UInt", 0, "UInt")
        buf := Buffer((len+1)*2, 0)
        DllCall("shell32\DragQueryFileW", "Ptr", pDrop, "UInt", 0, "Ptr", buf, "UInt", len+1, "UInt")
        arr.Push(StrGet(buf, "UTF-16"))
      }
      DllCall("GlobalUnlock", "Ptr", hDrop)
    }
  }
  DllCall("CloseClipboard")
  return arr
}

ClipboardHasBitmap() {
  return DllCall("IsClipboardFormatAvailable", "UInt", 8, "Int")
      || DllCall("IsClipboardFormatAvailable", "UInt", 2, "Int")
}

DumpClipboardBitmapToPng(outPng) {
  safePath := StrReplace(outPng, "'", "''")
  ps  := "Add-Type -AssemblyName System.Windows.Forms, System.Drawing;"
  ps .= "$img=[Windows.Forms.Clipboard]::GetImage();"
  ps .= "if ($img -eq $null) { exit 2 }"
  ps .= "$bmp=New-Object System.Drawing.Bitmap $img;"
  ps .= "$dir=Split-Path -Parent '" safePath "';"
  ps .= "if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }"
  ps .= "$bmp.Save('" safePath "', [System.Drawing.Imaging.ImageFormat]::Png);"
  cmd := "powershell -NoProfile -STA -Command " . Chr(34) . ps . Chr(34)
  RunWait cmd, , "Hide"
  return FileExist(outPng)
}

NormalizeFileUrlOrTextPath(txt) {
  t := Trim(txt, " `t`r`n`"''")
  if (SubStr(t, 1, 8) = "file:///") {
    t := StrReplace(t, "file:///", "")
    t := StrReplace(t, "/", "\")
  }
  return t
}

WinToWsl(path) {
  if !(path ~= "i)^[A-Za-z]:\\")
    return path
  drive := SubStr(path, 1, 1)
  rest  := SubStr(path, 3)
  rest  := StrReplace(rest, "\", "/")
  return "/mnt/" . StrLower(drive) . rest
}
