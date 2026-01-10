@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set LOGFILE=setup_log.txt
echo [%DATE% %TIME%] === SETUP STARTED === > %LOGFILE%

echo ========================================
echo    DISPLAY ROTATION SETUP
echo    Multi-Monitor Support
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

:: Create PowerShell scanner
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
:: STEP 2: Select monitors (comma separated)
:: ========================================
echo Select monitors to configure (comma separated)
echo Example: 1, 2 or just 1
echo.
set /p MONITORS_INPUT="Monitors: "
echo [%DATE% %TIME%] User input: %MONITORS_INPUT% >> %LOGFILE%

:: Parse comma-separated input using PowerShell
for /f "delims=" %%a in ('powershell -Command "('%MONITORS_INPUT%' -replace ' ','').Split(',') -join ' '"') do set MONITORS_LIST=%%a

echo.
echo Orientation options:
echo   0 = Landscape (normal)
echo   1 = Portrait (90 degrees)
echo   2 = Landscape flipped (180 degrees)
echo   3 = Portrait flipped (270 degrees)
echo.

:: ========================================
:: STEP 3: Configure each monitor in order
:: ========================================
set MONITOR_COUNT=0

for %%M in (%MONITORS_LIST%) do (
    set /a MONITOR_COUNT+=1
    set "MON!MONITOR_COUNT!=%%M"
)

echo You selected %MONITOR_COUNT% monitor(s): %MONITORS_LIST%
echo.

set IDX=1
:CONFIG_LOOP
if %IDX% GTR %MONITOR_COUNT% goto CONFIG_DONE

set "CURRENT_MON=!MON%IDX%!"

echo ----------------------------------------
echo Monitor %IDX%: DISPLAY!CURRENT_MON!
echo ----------------------------------------
set /p "ORI%IDX%=Target orientation (0-3): "

echo Swap mode? (Y = toggle, N = set once)
set /p "SWAP%IDX%=Swap mode (Y/N): "

echo [%DATE% %TIME%] DISPLAY!CURRENT_MON! Orient=!ORI%IDX%! Swap=!SWAP%IDX%! >> %LOGFILE%
echo.

set /a IDX+=1
goto CONFIG_LOOP

:CONFIG_DONE

:: ========================================
:: STEP 4: Enter filename
:: ========================================
echo ----------------------------------------
set /p FILENAME="Filename without .bat [rotate]: "
if "%FILENAME%"=="" set FILENAME=rotate

set OUTFILE=%FILENAME%.bat
echo [%DATE% %TIME%] Output filename: %OUTFILE% >> %LOGFILE%

:: ========================================
:: STEP 5: Generate combined script
:: ========================================
echo.
echo Generating %OUTFILE%...

:: Start the output file
echo @echo off > "%OUTFILE%"
echo setlocal >> "%OUTFILE%"
echo cd /d "%%~dp0" >> "%OUTFILE%"
echo set LOGFILE=%FILENAME%_log.txt >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo echo [%%DATE%% %%TIME%%] Starting Multi-Monitor Rotation... ^> %%LOGFILE%% >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo net session ^>nul 2^>^&1 >> "%OUTFILE%"
echo if %%errorLevel%% NEQ 0 ( >> "%OUTFILE%"
echo     powershell -Command "Start-Process '%%~f0' -Verb RunAs" >> "%OUTFILE%"
echo     exit /b >> "%OUTFILE%"
echo ) >> "%OUTFILE%"
echo. >> "%OUTFILE%"

:: Generate code for each monitor
set IDX=1

:GEN_LOOP
if %IDX% GTR %MONITOR_COUNT% goto GEN_DONE

set "CURRENT_MON=!MON%IDX%!"
set "CURRENT_ORI=!ORI%IDX%!"
set "CURRENT_SWAP=!SWAP%IDX%!"

:: Determine width/height logic
set W_LOGIC=Math.Min
set H_LOGIC=Math.Max
if "!CURRENT_ORI!"=="0" set W_LOGIC=Math.Max& set H_LOGIC=Math.Min
if "!CURRENT_ORI!"=="2" set W_LOGIC=Math.Max& set H_LOGIC=Math.Min

echo [%DATE% %TIME%] Generating code for DISPLAY!CURRENT_MON! >> %LOGFILE%

echo echo Processing DISPLAY!CURRENT_MON!... >> "%OUTFILE%"

if /i "!CURRENT_SWAP!"=="Y" (
    call :GEN_SWAP !CURRENT_MON! !CURRENT_ORI! !W_LOGIC! !H_LOGIC! %IDX%
) else (
    call :GEN_NOSWAP !CURRENT_MON! !CURRENT_ORI! !W_LOGIC! !H_LOGIC! %IDX%
)

set /a IDX+=1
goto GEN_LOOP

:GEN_DONE

echo echo Done. >> "%OUTFILE%"

echo.
echo ========================================
echo DONE!
echo ========================================
echo.
echo Created: %OUTFILE%
echo.
echo Configuration:

set IDX=1
:SUMMARY_LOOP
if %IDX% GTR %MONITOR_COUNT% goto SUMMARY_DONE
echo   DISPLAY!MON%IDX%! - Orientation: !ORI%IDX%! - Swap: !SWAP%IDX%!
set /a IDX+=1
goto SUMMARY_LOOP

:SUMMARY_DONE
echo.
echo [%DATE% %TIME%] === SETUP COMPLETE === >> %LOGFILE%
pause
exit /b

:: ========================================
:: SUBROUTINE: Generate SWAP code
:: ========================================
:GEN_SWAP
set M_NUM=%1
set M_ORI=%2
set M_WLOG=%3
set M_HLOG=%4
set M_IDX=%5

echo echo $c = 'using System;using System.Runtime.InteropServices;' ^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public class D%M_IDX%{' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")]public static extern int ChangeDisplaySettingsEx(string l,ref DM d,IntPtr h,int f,IntPtr p);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")]public static extern bool EnumDisplaySettings(string d,int n,ref DM m);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[StructLayout(LayoutKind.Sequential)]public struct DM{' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmDeviceName;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmSpecVersion;public short dmDriverVersion;public short dmSize;public short dmDriverExtra;public int dmFields;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPositionX;public int dmPositionY;public int dmDisplayOrientation;public int dmDisplayFixedOutput;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmColor;public short dmDuplex;public short dmYResolution;public short dmTTOption;public short dmCollate;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmFormName;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmLogPixels;public int dmBitsPerPel;public int dmPelsWidth;public int dmPelsHeight;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmDisplayFlags;public int dmDisplayFrequency;public int dmICMMethod;public int dmICMIntent;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmMediaType;public int dmDitherType;public int dmReserved1;public int dmReserved2;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPanningWidth;public int dmPanningHeight;}' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public static void R(){' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'DM m=new DM();m.dmSize=(short)Marshal.SizeOf(m);string n="\\\\.\\DISPLAY%M_NUM%";' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'if(EnumDisplaySettings(n,-1,ref m)){int w=m.dmPelsWidth;int h=m.dmPelsHeight;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'Console.WriteLine("DISPLAY%M_NUM%: current="+m.dmDisplayOrientation);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'if(m.dmDisplayOrientation==0){m.dmDisplayOrientation=%M_ORI%;m.dmPelsWidth=%M_WLOG%(w,h);m.dmPelsHeight=%M_HLOG%(w,h);}' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'else{m.dmDisplayOrientation=0;m.dmPelsWidth=Math.Max(w,h);m.dmPelsHeight=Math.Min(w,h);}' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'm.dmFields=0x180080;int r=ChangeDisplaySettingsEx(n,ref m,IntPtr.Zero,0,IntPtr.Zero);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'Console.WriteLine("DISPLAY%M_NUM%: result="+r);}}}' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo Add-Type -TypeDefinition $c ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo [D%M_IDX%]::R() ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo powershell -ExecutionPolicy Bypass -File t%M_IDX%.ps1 ^>^> %%LOGFILE%% 2^>^&1 >> "%OUTFILE%"
echo del t%M_IDX%.ps1 >> "%OUTFILE%"
echo. >> "%OUTFILE%"
goto :eof

:: ========================================
:: SUBROUTINE: Generate NO-SWAP code
:: ========================================
:GEN_NOSWAP
set M_NUM=%1
set M_ORI=%2
set M_WLOG=%3
set M_HLOG=%4
set M_IDX=%5

echo echo $c = 'using System;using System.Runtime.InteropServices;' ^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public class D%M_IDX%{' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")]public static extern int ChangeDisplaySettingsEx(string l,ref DM d,IntPtr h,int f,IntPtr p);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[DllImport("user32.dll")]public static extern bool EnumDisplaySettings(string d,int n,ref DM m);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[StructLayout(LayoutKind.Sequential)]public struct DM{' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmDeviceName;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmSpecVersion;public short dmDriverVersion;public short dmSize;public short dmDriverExtra;public int dmFields;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPositionX;public int dmPositionY;public int dmDisplayOrientation;public int dmDisplayFixedOutput;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmColor;public short dmDuplex;public short dmYResolution;public short dmTTOption;public short dmCollate;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += '[MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmFormName;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public short dmLogPixels;public int dmBitsPerPel;public int dmPelsWidth;public int dmPelsHeight;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmDisplayFlags;public int dmDisplayFrequency;public int dmICMMethod;public int dmICMIntent;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmMediaType;public int dmDitherType;public int dmReserved1;public int dmReserved2;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public int dmPanningWidth;public int dmPanningHeight;}' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'public static void R(){' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'DM m=new DM();m.dmSize=(short)Marshal.SizeOf(m);string n="\\\\.\\DISPLAY%M_NUM%";' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'if(EnumDisplaySettings(n,-1,ref m)){int w=m.dmPelsWidth;int h=m.dmPelsHeight;' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'Console.WriteLine("DISPLAY%M_NUM%: setting to %M_ORI%...");' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'm.dmDisplayOrientation=%M_ORI%;m.dmPelsWidth=%M_WLOG%(w,h);m.dmPelsHeight=%M_HLOG%(w,h);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'm.dmFields=0x180080;int r=ChangeDisplaySettingsEx(n,ref m,IntPtr.Zero,0,IntPtr.Zero);' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo $c += 'Console.WriteLine("DISPLAY%M_NUM%: result="+r);}}}' ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo Add-Type -TypeDefinition $c ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo echo [D%M_IDX%]::R() ^>^> t%M_IDX%.ps1 >> "%OUTFILE%"
echo powershell -ExecutionPolicy Bypass -File t%M_IDX%.ps1 ^>^> %%LOGFILE%% 2^>^&1 >> "%OUTFILE%"
echo del t%M_IDX%.ps1 >> "%OUTFILE%"
echo. >> "%OUTFILE%"
goto :eof
