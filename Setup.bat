@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set LOGFILE=setup_log.txt
echo [%DATE% %TIME%] === SETUP STARTED === > %LOGFILE%

echo ========================================
echo    DISPLAY ROTATION SETUP
echo ========================================
echo.

:: Check admin rights
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [%DATE% %TIME%] Requesting admin rights... >> %LOGFILE%
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo [%DATE% %TIME%] Admin rights OK >> %LOGFILE%

:: ========================================
:: STEP 1: Scan real monitors
:: ========================================
echo Scanning monitors...
echo.

:: Create PowerShell scanner using parentheses
(
echo $code = @"
echo using System;
echo using System.Runtime.InteropServices;
echo public class S {
echo     [DllImport^("user32.dll"^)] public static extern bool EnumDisplaySettings^(string d, int n, ref DM m^);
echo     [StructLayout^(LayoutKind.Sequential^)] public struct DM {
echo         [MarshalAs^(UnmanagedType.ByValTStr, SizeConst=32^)] public string dmDeviceName;
echo         public short a,b,dmSize,c; public int d,e,f,dmDisplayOrientation,g;
echo         public short h,i,j,k,l; [MarshalAs^(UnmanagedType.ByValTStr, SizeConst=32^)] public string m;
echo         public short n; public int o,dmPelsWidth,dmPelsHeight,p,q,r,s,t,u,v,w,x,y;
echo     }
echo     public static void Scan^(^) {
echo         string[] o = {"Landscape","Portrait","Landscape flipped","Portrait flipped"};
echo         for^(int i=1; i^<10; i++^) {
echo             DM dm = new DM^(^); dm.dmSize = ^(short^)Marshal.SizeOf^(dm^);
echo             if^(EnumDisplaySettings^("\\\\.\\DISPLAY"+i, -1, ref dm^)^)
echo                 Console.WriteLine^("  "+i+" = DISPLAY"+i+" - "+dm.dmPelsWidth+"x"+dm.dmPelsHeight+" ["+o[dm.dmDisplayOrientation]+"]"^);
echo         }
echo     }
echo }
echo "@
echo Add-Type -TypeDefinition $code
echo [S]::Scan^(^)
) > scanner.ps1

echo Available monitors:
powershell -ExecutionPolicy Bypass -File scanner.ps1 2>nul
del scanner.ps1 2>nul
echo.

:: ========================================
:: STEP 2: Select monitor
:: ========================================
set /p MONITOR="Enter m onitor number (1-9): "
echo [%DATE% %TIME%] User selected monitor: %MONITOR% >> %LOGFILE%

if "%MONITOR%"=="" (
    echo No monitor selected. Exiting.
    pause
    exit /b
)

:: ========================================
:: STEP 3: Select target orientation
:: ========================================
echo.
echo Orientation options:
echo   0 = Landscape (normal)
echo   1 = Portrait (90 degrees)
echo   2 = Landscape flipped (180 degrees)
echo   3 = Portrait flipped (270 degrees)
echo.
set /p ORIENT="Target orientation (0-3): "
echo [%DATE% %TIME%] Target orientation: %ORIENT% >> %LOGFILE%

:: ========================================
:: STEP 4: Swap mode?
:: ========================================
echo.
echo Swap mode? (toggle back and forth)
echo   Y = Toggle between Landscape and target
echo   N = Just set to target once
set /p SWAP="Swap mode (Y/N): "
echo [%DATE% %TIME%] Swap mode: %SWAP% >> %LOGFILE%

:: ========================================
:: STEP 5: Enter filename
:: ========================================
echo.
set /p FILENAME="Filename without .bat [rotate]: "
if "%FILENAME%"=="" set FILENAME=rotate

set OUTFILE=%FILENAME%.bat
echo [%DATE% %TIME%] Output filename: %OUTFILE% >> %LOGFILE%

:: ========================================
:: STEP 6: Determine width/height logic
:: ========================================
set W_LOGIC=Math.Min
set H_LOGIC=Math.Max
if "%ORIENT%"=="0" set W_LOGIC=Math.Max
if "%ORIENT%"=="0" set H_LOGIC=Math.Min
if "%ORIENT%"=="2" set W_LOGIC=Math.Max
if "%ORIENT%"=="2" set H_LOGIC=Math.Min

echo [%DATE% %TIME%] W_LOGIC=%W_LOGIC% H_LOGIC=%H_LOGIC% >> %LOGFILE%

:: ========================================
:: STEP 7: Generate script
:: ========================================
echo.
echo Generating %OUTFILE%...

if /i "%SWAP%"=="Y" (
    echo [%DATE% %TIME%] Generating SWAP version >> %LOGFILE%
    call :GEN_SWAP
) else (
    echo [%DATE% %TIME%] Generating NO-SWAP version >> %LOGFILE%
    call :GEN_NOSWAP
)

echo.
echo ========================================
echo DONE!
echo ========================================
echo.
echo Created: %OUTFILE%
echo Monitor: DISPLAY%MONITOR%
echo Orientation: %ORIENT%
echo Swap mode: %SWAP%
echo.
echo [%DATE% %TIME%] === SETUP COMPLETE === >> %LOGFILE%
pause
exit /b

:: ========================================
:: SUBROUTINE: Generate SWAP version
:: ========================================
:GEN_SWAP
echo @echo off > "%OUTFILE%"
echo setlocal >> "%OUTFILE%"
echo cd /d "%%~dp0" >> "%OUTFILE%"
echo set LOGFILE=%FILENAME%_log.txt >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo echo [%%DATE%% %%TIME%%] Starting Toggle Script for DISPLAY%MONITOR%... ^> %%LOGFILE%% >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo net session ^>nul 2^>^&1 >> "%OUTFILE%"
echo if %%errorLevel%% NEQ 0 ( >> "%OUTFILE%"
echo     powershell -Command "Start-Process '%%~f0' -Verb RunAs" >> "%OUTFILE%"
echo     exit /b >> "%OUTFILE%"
echo ) >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo echo Building script... >> "%OUTFILE%"
echo echo $c = 'using System;' ^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'using System.Runtime.InteropServices;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public class D {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")] public static extern int ChangeDisplaySettingsEx(string l, ref DM d, IntPtr h, int f, IntPtr p);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")] public static extern bool EnumDisplaySettings(string d, int n, ref DM m);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[StructLayout(LayoutKind.Sequential)] public struct DM {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmSpecVersion; public short dmDriverVersion; public short dmSize;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmDriverExtra; public int dmFields;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmFixedOutput;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmCollate; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPanningWidth; public int dmPanningHeight;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public static void R() {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'DM m = new DM(); m.dmSize = (short)Marshal.SizeOf(m);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'string n = "\\\\.\\DISPLAY%MONITOR%";' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'if(EnumDisplaySettings(n, -1, ref m)){' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  int w = m.dmPelsWidth; int h = m.dmPelsHeight;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  int current = m.dmDisplayOrientation;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  if (current == 0) {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     Console.WriteLine("Switching to orientation %ORIENT%...");' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     m.dmDisplayOrientation = %ORIENT%;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     m.dmPelsWidth = %W_LOGIC%(w, h);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     m.dmPelsHeight = %H_LOGIC%(w, h);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  } else {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     Console.WriteLine("Switching to Landscape (0)...");' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     m.dmDisplayOrientation = 0;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     m.dmPelsWidth = Math.Max(w, h);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '     m.dmPelsHeight = Math.Min(w, h);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  }' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  m.dmFields = 0x180080;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  int i = ChangeDisplaySettingsEx(n, ref m, IntPtr.Zero, 0, IntPtr.Zero);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  Console.WriteLine("Result code: " + i);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo Add-Type -TypeDefinition $c ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo [D]::R() ^>^> toggle.ps1 >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo powershell -ExecutionPolicy Bypass -File toggle.ps1 ^>^> %%LOGFILE%% 2^>^&1 >> "%OUTFILE%"
echo del toggle.ps1 >> "%OUTFILE%"
echo echo Done. >> "%OUTFILE%"
goto :eof

:: ========================================
:: SUBROUTINE: Generate NO-SWAP version
:: ========================================
:GEN_NOSWAP
echo @echo off > "%OUTFILE%"
echo setlocal >> "%OUTFILE%"
echo cd /d "%%~dp0" >> "%OUTFILE%"
echo set LOGFILE=%FILENAME%_log.txt >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo echo [%%DATE%% %%TIME%%] Setting DISPLAY%MONITOR% to orientation %ORIENT%... ^> %%LOGFILE%% >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo net session ^>nul 2^>^&1 >> "%OUTFILE%"
echo if %%errorLevel%% NEQ 0 ( >> "%OUTFILE%"
echo     powershell -Command "Start-Process '%%~f0' -Verb RunAs" >> "%OUTFILE%"
echo     exit /b >> "%OUTFILE%"
echo ) >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo echo Building script... >> "%OUTFILE%"
echo echo $c = 'using System;' ^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'using System.Runtime.InteropServices;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public class D {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")] public static extern int ChangeDisplaySettingsEx(string l, ref DM d, IntPtr h, int f, IntPtr p);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")] public static extern bool EnumDisplaySettings(string d, int n, ref DM m);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[StructLayout(LayoutKind.Sequential)] public struct DM {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '[MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmSpecVersion; public short dmDriverVersion; public short dmSize;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmDriverExtra; public int dmFields;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmFixedOutput;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmCollate; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPanningWidth; public int dmPanningHeight;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'public static void R() {' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'DM m = new DM(); m.dmSize = (short)Marshal.SizeOf(m);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'string n = "\\\\.\\DISPLAY%MONITOR%";' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += 'if(EnumDisplaySettings(n, -1, ref m)){' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  int w = m.dmPelsWidth; int h = m.dmPelsHeight;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  Console.WriteLine("Setting to orientation %ORIENT%...");' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  m.dmDisplayOrientation = %ORIENT%;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  m.dmPelsWidth = %W_LOGIC%(w, h);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  m.dmPelsHeight = %H_LOGIC%(w, h);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  m.dmFields = 0x180080;' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  int i = ChangeDisplaySettingsEx(n, ref m, IntPtr.Zero, 0, IntPtr.Zero);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '  Console.WriteLine("Result code: " + i);' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo $c += '}' ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo Add-Type -TypeDefinition $c ^>^> toggle.ps1 >> "%OUTFILE%"
echo echo [D]::R() ^>^> toggle.ps1 >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo powershell -ExecutionPolicy Bypass -File toggle.ps1 ^>^> %%LOGFILE%% 2^>^&1 >> "%OUTFILE%"
echo del toggle.ps1 >> "%OUTFILE%"
echo echo Done. >> "%OUTFILE%"
goto :eof