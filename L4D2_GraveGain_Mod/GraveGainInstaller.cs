// GraveGain Mod Installer Launcher
// Compile with:
//   %SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /out:GraveGainInstaller.exe GraveGainInstaller.cs
// Or run build_installer.bat which does this automatically.
//
// This launcher:
//  1. Finds install_gravegain.ps1 next to this .exe
//  2. Re-launches itself as Administrator if not already elevated
//  3. Runs the PowerShell script with -ExecutionPolicy Bypass
//  4. Shows output in a console window that stays open until dismissed

using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("GraveGain Mod Installer")]
[assembly: AssemblyDescription("Installs the GraveGain Melee Overhaul mod for Left 4 Dead 2")]
[assembly: AssemblyVersion("1.0.0.0")]

// Runner is a class so it can hold instance fields for the event handlers
// (C# 5 / .NET 4.0 compatible - no local functions, no lambdas with closures)
class Runner
{
    StreamWriter _log;
    readonly object _lock = new object();

    // Thread-safe write to both console and log file
    void Log(string line)
    {
        lock (_lock)
        {
            Console.WriteLine(line);
            try { _log.WriteLine(line); } catch { }
        }
    }

    void OnOutput(object sender, DataReceivedEventArgs e)
    {
        if (e.Data != null) Log(e.Data);
    }

    void OnError(object sender, DataReceivedEventArgs e)
    {
        if (e.Data != null) Log("[STDERR] " + e.Data);
    }

    public int Run(string psScript, string logFile, string exeDir, string title)
    {
        try
        {
            _log = new StreamWriter(logFile, false, Encoding.UTF8);
            _log.AutoFlush = true;
        }
        catch (Exception ex)
        {
            Console.WriteLine("[WARN] Cannot open log file: " + ex.Message);
            _log = StreamWriter.Null;
        }

        Log("=== " + title + " ===");
        Log("Started : " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
        Log("Script  : " + psScript);
        Log("Log     : " + logFile);
        Log(new string('=', 60));

        var psi = new ProcessStartInfo();
        psi.FileName               = "powershell.exe";
        psi.Arguments              = "-NoProfile -ExecutionPolicy Bypass -File \"" + psScript + "\"";
        psi.UseShellExecute        = false;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError  = true;
        psi.WorkingDirectory       = exeDir;
        psi.CreateNoWindow         = true;
        psi.StandardOutputEncoding = Encoding.UTF8;
        psi.StandardErrorEncoding  = Encoding.UTF8;

        int exitCode = 1;
        try
        {
            Process proc = Process.Start(psi);
            proc.OutputDataReceived += OnOutput;
            proc.ErrorDataReceived  += OnError;
            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();
            proc.WaitForExit();
            exitCode = proc.ExitCode;
        }
        catch (Exception ex)
        {
            Log("[ERROR] Failed to launch PowerShell: " + ex.Message);
        }

        Log(new string('=', 60));
        Log("Exit code : " + exitCode);
        Log("Finished  : " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
        Log("Log saved : " + logFile);

        try { _log.Close(); } catch { }
        return exitCode;
    }
}

static class Program
{
    [DllImport("kernel32.dll")] static extern bool AllocConsole();
    [DllImport("kernel32.dll")] static extern bool AttachConsole(int pid);

    [STAThread]
    static void Main(string[] args)
    {
        bool uninstall = args.Length > 0 &&
                         args[0].Equals("/uninstall", StringComparison.OrdinalIgnoreCase);

        string exeDir   = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        string psScript = Path.Combine(exeDir, uninstall ? "uninstall_gravegain.ps1" : "install_gravegain.ps1");
        string logFile  = Path.Combine(exeDir, "gravegain_installer_latest.log");
        string title    = uninstall ? "GraveGain Uninstaller" : "GraveGain Installer";

        if (!File.Exists(psScript))
        {
            MessageBox.Show(
                "Could not find:\n" + psScript +
                "\n\nMake sure GraveGainInstaller.exe is in the same folder as the mod files.",
                title + " - File Not Found",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            Environment.Exit(1);
        }

        // Re-launch elevated via UAC if needed
        if (!IsAdmin())
        {
            try
            {
                ProcessStartInfo elevate = new ProcessStartInfo();
                elevate.FileName        = Assembly.GetExecutingAssembly().Location;
                elevate.Arguments       = uninstall ? "/uninstall" : "";
                elevate.UseShellExecute = true;
                elevate.Verb            = "runas";
                Process.Start(elevate);
            }
            catch (System.ComponentModel.Win32Exception)
            {
                MessageBox.Show(
                    "Administrator rights are required.\n\nPlease accept the UAC prompt.",
                    title + " - Elevation Required",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
            }
            return;
        }

        // Allocate or attach a console window (winexe has none by default)
        if (!AttachConsole(-1))
            AllocConsole();

        Console.Title          = title;
        Console.OutputEncoding = Encoding.UTF8;

        int exitCode = new Runner().Run(psScript, logFile, exeDir, title);

        if (exitCode != 0)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("\n[FAILED] Exit code " + exitCode);
            Console.WriteLine("Full log: " + logFile);
            Console.ResetColor();
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("\n[SUCCESS] Complete.");
            Console.ResetColor();
        }

        Console.WriteLine("\nPress any key to close...");
        Console.ReadKey(true);
        Environment.Exit(exitCode);
    }

    static bool IsAdmin()
    {
        using (WindowsIdentity id = WindowsIdentity.GetCurrent())
        {
            return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
        }
    }
}
