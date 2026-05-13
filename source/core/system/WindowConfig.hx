package core.system;

import lime.app.Application;
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
    <lib name="user32.lib" if="windows" />
    <lib name="advapi32.lib" if="windows" />
</target>
')
@:headerCode('
#include <Windows.h>
#include <dwmapi.h>

#ifndef DWMWA_CAPTION_COLOR
  #define DWMWA_CAPTION_COLOR 35
#endif

static BOOL CALLBACK _enumGameWindow(HWND w, LPARAM lParam) {
    DWORD pid = 0;
    GetWindowThreadProcessId(w, &pid);
    if (pid == GetCurrentProcessId() && IsWindowVisible(w) && GetParent(w) == NULL) {
        *(HWND*)lParam = w;
        return 0;
    }
    return 1;
}

static inline HWND _getGameHwnd() {
    HWND hwnd = GetActiveWindow();
    if (hwnd != NULL) return hwnd;
    hwnd = NULL;
    EnumWindows(_enumGameWindow, (LPARAM)&hwnd);
    return hwnd;
}

#undef TRUE
#undef FALSE
#undef NO_ERROR
')

class WindowConfig {
	 @:functionCode('
        HWND hwnd = _getGameHwnd();
        if (hwnd == NULL) return;

        HKEY hKey;
        DWORD accentColor = 0x00333333;
        DWORD dataSize = sizeof(DWORD);
        if (RegOpenKeyExW(HKEY_CURRENT_USER,
                          L"Software\\\\Microsoft\\\\Windows\\\\DWM",
                          0, KEY_READ, &hKey) == ERROR_SUCCESS) {
            RegQueryValueExW(hKey, L"AccentColor", NULL, NULL,
                             (LPBYTE)&accentColor, &dataSize);
            RegCloseKey(hKey);
        }

        BYTE r = (accentColor >> 0)  & 0xFF;
        BYTE g = (accentColor >> 8)  & 0xFF;
        BYTE b = (accentColor >> 16) & 0xFF;
        COLORREF color = RGB(r, g, b);
        DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, &color, sizeof(COLORREF));
        UpdateWindow(hwnd);
    ')
    public static function applyAccentColor():Void {}
}
