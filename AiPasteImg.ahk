#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; ===== 可选：编译元信息（Ahk2Exe 识别） =====
;@Ahk2Exe-ExeName AiImgPaste.exe
;@Ahk2Exe-SetDescription "Paste clipboard image to @path with tray settings"
;@Ahk2Exe-SetFileVersion 1.1.0.0
;@Ahk2Exe-SetProductVersion 1.1.0
;@Ahk2Exe-SetProductName "AiImgPaste"
;@Ahk2Exe-SetCompanyName "StillFlood"
;@Ahk2Exe-SetCopyright "(c) 2025 StillFlood"
;@Ahk2Exe-SetMainIcon sflood.ico

; ===== 全局配置 / 默认值 =====
APP_NAME  := "AiImgPaste"
CFG_DIR   := A_AppData "\" APP_NAME
CFG_FILE  := CFG_DIR "\config.ini"
DEFAULTS  := Map(
  "SaveRoot",    A_Desktop "\Screens", ; 默认保存目录
  "UseWSLPath",  "0",                  ; 0=Windows路径, 1=WSL路径(/mnt/..)
  "AtPrefix",    "@",                  ; 粘贴前缀，如 "@", "@file "
  "AfterText",   "",                   ; 路径后附加文字（支持 \n）
  "Hotkey",      "!+v",                ; Alt+Shift+V
  "ShowNotify",  "1",                  ; 1=显示托盘通知
  "AsyncSave",   "1",                  ; 1=异步保存图片（快速响应）
  "Lang",        "zh"                  ; "zh" 或 "en"
)

; ===== 语言包 =====
Lang := Map(
  "zh", Map(
    "tray_settings",   "设置(&S)...",
    "tray_open_dir",   "打开保存目录(&O)",
    "tray_autostart",  "开机自启(&A)",
    "tray_reload",     "重载(&R)",
    "tray_quit",       "退出(&Q)",
    "win_title",       "设置",
    "save_dir",        "保存目录：",
    "choose",          "选择...",
    "prefix",          "前缀：",
    "suffix",          "后缀文字：",
    "suffix_hint",     "示例：调用MCP识别图片（支持 \\n 为换行）",
    "use_wsl",         "使用 WSL 路径（/mnt/...）",
    "notify",          "显示托盘通知",
    "async_save",      "异步保存图片（更快响应）",
    "hotkey",          "热键：",
    "hotkey_hint",     "示例：!+v=Alt+Shift+V；^!p=Ctrl+Alt+P",
    "lang",            "界面语言：",
    "lang_zh",         "中文",
    "lang_en",         "English",
    "btn_save",        "保存",
    "btn_cancel",      "取消",
    "tip_saved",       "设置已保存",
    "tip_reload_ui",   "提示：设置窗口语言需重载程序后生效",
    "tip_no_path",     "未检测到图片或文件路径，请先截屏或复制文件。",
    "tip_pasted",      "已粘贴："
  ),
  "en", Map(
    "tray_settings",   "Settings...",
    "tray_open_dir",   "Open Save Folder",
    "tray_autostart",  "Run at Startup",
    "tray_reload",     "Reload",
    "tray_quit",       "Quit",
    "win_title",       "Settings",
    "save_dir",        "Save directory:",
    "choose",          "Browse...",
    "prefix",          "Prefix:",
    "suffix",          "Suffix text:",
    "suffix_hint",     "Example: Ask MCP to parse image (supports \\n as newline)",
    "use_wsl",         "Use WSL path (/mnt/...)",
    "notify",          "Show tray notifications",
    "async_save",      "Async save image (faster response)",
    "hotkey",          "Hotkey:",
    "hotkey_hint",     "e.g. !+v=Alt+Shift+V; ^!p=Ctrl+Alt+P",
    "lang",            "Language:",
    "lang_zh",         "中文",
    "lang_en",         "English",
    "btn_save",        "Save",
    "btn_cancel",      "Cancel",
    "tip_saved",       "Settings saved",
    "tip_reload_ui",   "UI language will take effect after reload",
    "tip_no_path",     "No image or file path detected. Please screenshot or copy a file first.",
    "tip_pasted",      "Pasted: "
  )
)

global g := Map()  ; 运行时配置
global L := Lang["zh"]  ; 当前语言文本缓存

; ===== 入口 =====
Init()
BuildTray()
BindHotkey()
return

; ================= 工具/配置 =================
Init() {
  global g, L
  if !DirExist(CFG_DIR)
    DirCreate(CFG_DIR)
  for k, v in DEFAULTS
    g[k] := IniRead(CFG_FILE, "config", k, v)
  ; 语言缓存
  L := Lang.Has(g["Lang"]) ? Lang[g["Lang"]] : Lang["zh"]
  EnsureDir(g["SaveRoot"])
}

SaveConfig() {
  global g
  if !DirExist(CFG_DIR)
    DirCreate(CFG_DIR)
  for k, v in g
    IniWrite(v, CFG_FILE, "config", k)
}

EnsureDir(dir) {
  if !DirExist(dir)
    DirCreate(dir)
}

; ================= 托盘菜单（随语言重建） =================
BuildTray() {
  global L
  A_IconTip := APP_NAME
  A_TrayMenu.Delete()
  A_TrayMenu.Add(L["tray_settings"], ShowSettings)
  A_TrayMenu.Add(L["tray_open_dir"], (*) => Run('explorer.exe "' g["SaveRoot"] '"'))
  A_TrayMenu.Add()
  
  ; 语言子菜单
  langMenu := Menu()
  langMenu.Add(L["lang_zh"], (*) => SwitchLanguage("zh"))
  langMenu.Add(L["lang_en"], (*) => SwitchLanguage("en"))
  if (g["Lang"] = "zh")
    langMenu.Check(L["lang_zh"])
  else
    langMenu.Check(L["lang_en"])
  A_TrayMenu.Add(L["lang"], langMenu)
  
  A_TrayMenu.Add()
  A_TrayMenu.Add(L["tray_autostart"], ToggleAutostart)
  if GetAutostart()
    A_TrayMenu.Check(L["tray_autostart"])
  A_TrayMenu.Add()
  A_TrayMenu.Add(L["tray_reload"], (*) => Reload())
  A_TrayMenu.Add(L["tray_quit"],   (*) => ExitApp())
}

SwitchLanguage(newLang) {
  global g, L
  if (g["Lang"] = newLang)
    return
  oldLang := g["Lang"]
  g["Lang"] := newLang
  L := Lang[newLang]
  SaveConfig()
  BuildTray()
  ; 使用新语言显示提示（强制显示，不受ShowNotify控制）
  TipForce(L["tip_saved"] . " - " . L["tip_reload_ui"], 2500)
}

GetAutostart() {
  link := A_Startup "\" APP_NAME ".lnk"
  return FileExist(link)
}
ToggleAutostart(ItemName, ItemPos, MyMenu) {
  link := A_Startup "\" APP_NAME ".lnk"
  if GetAutostart() {
    FileDelete(link)
    A_TrayMenu.Uncheck(ItemName)
  } else {
    FileCreateShortcut(A_ScriptFullPath, link,,,"",A_ScriptFullPath)
    A_TrayMenu.Check(ItemName)
  }
}

; ================= 热键绑定 =================
UnbindHotkey() {
  hk := g["Hotkey"]
  if IsSet(hk)
    Hotkey(hk, "", "Off")
}
BindHotkey() {
  hk := g["Hotkey"]
  try {
    Hotkey(hk, DoPaste, "On")
  } catch {
    ; 绑定失败就退回默认
    g["Hotkey"] := "!+v"
    Hotkey("!+v", DoPaste, "On")
  }
}

; ================= 通知封装 =================
Tip(msg, dur:=1500, title:=APP_NAME) {
  if (g["ShowNotify"] == "1")
    TrayTip(title, msg, dur)
}

; 强制显示通知（不受ShowNotify控制，用于重要提示）
TipForce(msg, dur:=1500, title:=APP_NAME) {
  TrayTip(title, msg, dur)
}

; ================= 主功能：生成并粘贴 @路径 =================
DoPaste(*) {
  try {
    EnsureDir(g["SaveRoot"])
    
    ; 1) 先尝试快速获取路径（文件/文本路径）
    files := GetClipboardFiles()
    if (files.Length) {
      path := files[1]
      PastePathNow(path)
      return
    }
    
    ; 2) 检查文本路径
    clip := A_Clipboard
    if (clip ~= "i)^(?:[A-Za-z]:\\|\\\\|file:///)")  {
      path := NormalizeFileUrlOrTextPath(clip)
      PastePathNow(path)
      return
    }
    
    ; 3) 剪贴板位图 -> 根据配置选择同步或异步保存
    if (ClipboardHasBitmap()) {
      tsDir := FormatTime(A_Now, "yyyy-MM")
      dir := g["SaveRoot"] "\" tsDir
      EnsureDir(dir)
      ts := FormatTime(A_Now, "yyyyMMdd-HHmmss")
      outPng := dir "\" ts ".png"
      
      ; 根据配置选择保存方式
      if (g["AsyncSave"] == "1") {
        ; 异步模式：先复制剪贴板数据，立即粘贴，后台保存
        savedClip := ClipboardAll()
        PastePathNow(outPng)
        SetTimer(() => SaveImageFromClipData(savedClip, outPng), -10)
      } else {
        ; 同步模式：先保存图片，再粘贴路径
        if (!DumpClipboardBitmapToPng(outPng)) {
          Tip(L["tip_no_path"], 2000)
          return
        }
        PastePathNow(outPng)
      }
      return
    }
    
    ; 未检测到任何内容
    Tip(L["tip_no_path"], 2000)
    
  } catch as e {
    MsgBox "错误: " e.Message
  }
}

; 立即粘贴路径（提取为独立函数）
PastePathNow(path) {
  global g, L
  outPath := (g["UseWSLPath"] == "1") ? WinToWsl(path) : path
  suffix  := StrReplace(g["AfterText"], "\n", "`n")
  txt     := g["AtPrefix"] . outPath . (suffix != "" ? " " . suffix : "")
  A_Clipboard := txt
  Sleep 50
  Send "^v"
  Tip(L["tip_pasted"] . txt, 1600)
}

; ================= 设置窗口（多语言） =================
ShowSettings(*) {
  global L
  static w
  if IsSet(w) && w {
    w.Show()
    return
  }

  w := Gui("+AlwaysOnTop +OwnDialogs", APP_NAME " - " L["win_title"])
  w.SetFont("s10")

  ; 保存目录
  w.Add("Text",, L["save_dir"])
  tSave := w.Add("Edit", "w360", g["SaveRoot"])
  btnSel := w.Add("Button", "x+8", L["choose"])
  btnSel.OnEvent("Click", (*) => (
      w.Opt("-AlwaysOnTop")
    , dir := DirSelect(g["SaveRoot"], 3, L["save_dir"])
    , w.Opt("+AlwaysOnTop")
    , dir ? (tSave.Value := dir) : 0
  ))

  ; 前缀
  w.Add("Text", "xm y+12", L["prefix"])
  tPrefix := w.Add("Edit", "w150", g["AtPrefix"])

  ; 后缀
  w.Add("Text", "xm y+12", L["suffix"])
  tAfter  := w.Add("Edit", "w360", g["AfterText"])
  w.Add("Text", "x+10 yp+3", L["suffix_hint"])

  ; WSL & 通知
  cbWSL := w.Add("Checkbox", "xm y+12", L["use_wsl"])
  cbWSL.Value := (g["UseWSLPath"] == "1")

  cbNotify := w.Add("Checkbox", "xm y+8", L["notify"])
  cbNotify.Value := (g["ShowNotify"] == "1")

  cbAsync := w.Add("Checkbox", "xm y+8", L["async_save"])
  cbAsync.Value := (g["AsyncSave"] == "1")

  ; 热键
  w.Add("Text", "xm y+12", L["hotkey"])
  tHotkey := w.Add("Edit", "w120", g["Hotkey"])
  w.Add("Text", "x+10 yp+3", L["hotkey_hint"])

  ; 按钮
  btnOK := w.Add("Button", "xm y+16 w80 Default", L["btn_save"])
  btnCancel := w.Add("Button", "x+8 w80", L["btn_cancel"])

  btnOK.OnEvent("Click", (*) => (
      g["SaveRoot"]    := tSave.Value
    , g["AtPrefix"]    := tPrefix.Value
    , g["AfterText"]   := tAfter.Value
    , g["UseWSLPath"]  := cbWSL.Value ? "1" : "0"
    , g["ShowNotify"]  := cbNotify.Value ? "1" : "0"
    , g["AsyncSave"]   := cbAsync.Value ? "1" : "0"
    , hkNew := Trim(tHotkey.Value)
    , hkNew := (hkNew="" ? g["Hotkey"] : hkNew)
    , UnbindHotkey()
    , g["Hotkey"] := hkNew
    , BindHotkey()
    , SaveConfig()
    , Tip(L["tip_saved"], 1200)
    , w.Hide()
  ))

  btnCancel.OnEvent("Click", (*) => w.Hide())

  w.Show()
}

; ================= 剪贴板处理 =================
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
      DllCall("GlobalUnlock", "Ptr", pDrop)
    }
  }
  DllCall("CloseClipboard")
  return arr
}

ClipboardHasBitmap() {
  return DllCall("IsClipboardFormatAvailable", "UInt", 8, "Int")   ; CF_DIB
      || DllCall("IsClipboardFormatAvailable", "UInt", 2, "Int")   ; CF_BITMAP
}

; 从保存的剪贴板数据中提取并保存图片
SaveImageFromClipData(clipData, outPng) {
  ; 临时恢复剪贴板数据
  oldClip := A_Clipboard
  A_Clipboard := clipData
  
  ; 保存图片
  result := DumpClipboardBitmapToPng(outPng)
  
  ; 恢复原剪贴板（如果需要）
  ; A_Clipboard := oldClip  ; 注释掉，因为用户可能已经在使用新的剪贴板内容
  
  return result
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
