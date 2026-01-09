@echo off
setlocal
cd /d "%~dp0"
set LOGFILE=toggle_log.txt

echo [DATE: %DATE% %TIME%] Starting Toggle Script for DISPLAY2... > %LOGFILE%

:: 1. Проверка прав администратора
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Requesting Admin rights... >> %LOGFILE%
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Создание C# кода
echo Building script...
echo $c = 'using System;' > toggle.ps1
echo $c += 'using System.Runtime.InteropServices;' >> toggle.ps1
echo $c += 'public class D {' >> toggle.ps1
echo $c += '[DllImport("user32.dll")] public static extern int ChangeDisplaySettingsEx(string l, ref DM d, IntPtr h, int f, IntPtr p);' >> toggle.ps1
echo $c += '[DllImport("user32.dll")] public static extern bool EnumDisplaySettings(string d, int n, ref DM m);' >> toggle.ps1
echo $c += '[StructLayout(LayoutKind.Sequential)] public struct DM {' >> toggle.ps1
echo $c += '[MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;' >> toggle.ps1
echo $c += 'public short dmSpecVersion; public short dmDriverVersion; public short dmSize;' >> toggle.ps1
echo $c += 'public short dmDriverExtra; public int dmFields;' >> toggle.ps1
echo $c += 'public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmFixedOutput;' >> toggle.ps1
echo $c += 'public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption;' >> toggle.ps1
echo $c += 'public short dmCollate; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;' >> toggle.ps1
echo $c += 'public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;' >> toggle.ps1
echo $c += 'public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent;' >> toggle.ps1
echo $c += 'public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2;' >> toggle.ps1
echo $c += 'public int dmPanningWidth; public int dmPanningHeight;' >> toggle.ps1
echo $c += '}' >> toggle.ps1
echo $c += 'public static void R() {' >> toggle.ps1
echo $c += 'DM m = new DM(); m.dmSize = (short)Marshal.SizeOf(m);' >> toggle.ps1
echo $c += 'string n = "\\\\.\\DISPLAY2";' >> toggle.ps1
echo $c += 'if(EnumDisplaySettings(n, -1, ref m)){' >> toggle.ps1
echo $c += '  int w = m.dmPelsWidth; int h = m.dmPelsHeight;' >> toggle.ps1
echo $c += '  int current = m.dmDisplayOrientation;' >> toggle.ps1
echo $c += '  if (current == 0) {' >> toggle.ps1
echo $c += '     Console.WriteLine("Switching to Vertical (270)...");' >> toggle.ps1
echo $c += '     m.dmDisplayOrientation = 3;' >> toggle.ps1
echo $c += '     m.dmPelsWidth = Math.Min(w, h);' >> toggle.ps1
echo $c += '     m.dmPelsHeight = Math.Max(w, h);' >> toggle.ps1
echo $c += '  } else {' >> toggle.ps1
echo $c += '     Console.WriteLine("Switching to Normal (0)...");' >> toggle.ps1
echo $c += '     m.dmDisplayOrientation = 0;' >> toggle.ps1
echo $c += '     m.dmPelsWidth = Math.Max(w, h);' >> toggle.ps1
echo $c += '     m.dmPelsHeight = Math.Min(w, h);' >> toggle.ps1
echo $c += '  }' >> toggle.ps1
echo $c += '  m.dmFields = 0x180080;' >> toggle.ps1
echo $c += '  int i = ChangeDisplaySettingsEx(n, ref m, IntPtr.Zero, 0, IntPtr.Zero);' >> toggle.ps1
echo $c += '  Console.WriteLine("Result code: " + i);' >> toggle.ps1
echo $c += '}' >> toggle.ps1
echo $c += '}' >> toggle.ps1
echo $c += '}' >> toggle.ps1
echo Add-Type -TypeDefinition $c >> toggle.ps1
echo [D]::R() >> toggle.ps1

:: 3. Запуск
powershell -ExecutionPolicy Bypass -File toggle.ps1 >> %LOGFILE% 2>&1

:: 4. Очистка
del toggle.ps1
echo Done. Check toggle_log.txt if needed.