@echo off
:: ============================================================
::  GraveGain - Build installer .exe from GraveGainInstaller.cs
::  Uses the C# compiler that ships with .NET Framework 4.x
::  (available on every Windows machine since Windows 7)
::
::  Run this once to produce GraveGainInstaller.exe
::  Double-click the .exe to install (prompts for admin rights)
:: ============================================================

setlocal EnableDelayedExpansion

:: Change to the directory this .bat lives in so relative paths work
cd /d "%~dp0"

:: Find csc.exe - scan all v4.* subdirs under Framework64 then Framework
set "CSC="

for /d %%D in ("%SystemRoot%\Microsoft.NET\Framework64\v4.*") do (
    if exist "%%D\csc.exe" (
        set "CSC=%%D\csc.exe"
        goto :found
    )
)
for /d %%D in ("%SystemRoot%\Microsoft.NET\Framework\v4.*") do (
    if exist "%%D\csc.exe" (
        set "CSC=%%D\csc.exe"
        goto :found
    )
)

goto :notfound

:notfound
echo [ERROR] Could not find csc.exe - .NET Framework 4.x does not appear to be installed.
echo         Download it from: https://dotnet.microsoft.com/download/dotnet-framework
pause
exit /b 1

:found
echo Using compiler: %CSC%
echo.

:: Compile - /target:winexe suppresses the extra console window that would
:: appear behind the PowerShell window
"%CSC%" /nologo ^
    /target:winexe ^
    /platform:anycpu ^
    /optimize+ ^
    /reference:System.Windows.Forms.dll ^
    /out:GraveGainInstaller.exe ^
    GraveGainInstaller.cs

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Compilation failed. See errors above.
    pause
    exit /b 1
)

echo.
echo [OK] GraveGainInstaller.exe built successfully.
echo      Double-click it to install the mod (will prompt for admin rights).
echo.
pause
