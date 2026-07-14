// Tiny console launcher for the MSIX package: MSIX applications must declare an
// .exe entry point, and powershell.exe cannot be referenced from outside the
// package. This launcher starts Windows PowerShell against the bundled
// WinTrash.ps1 in the SAME console window and forwards the exit code.
//
// Build (build-msix.ps1 does this automatically):
//   csc.exe /target:exe /platform:anycpu /out:WinTrashLauncher.exe WinTrashLauncher.cs

using System;
using System.Diagnostics;
using System.IO;

internal static class WinTrashLauncher
{
    private static int Main(string[] args)
    {
        string appDir = AppDomain.CurrentDomain.BaseDirectory;
        string script = Path.Combine(appDir, "WinTrash.ps1");
        if (!File.Exists(script))
        {
            Console.Error.WriteLine("WinTrash.ps1 not found next to the launcher: " + script);
            return 2;
        }

        // Flag consumed by WinTrash.ps1: disables self-update (Store policy) and
        // is part of the packaged-mode detection alongside the WindowsApps path.
        Environment.SetEnvironmentVariable("WINTRASH_PACKAGED", "1");

        var psi = new ProcessStartInfo
        {
            FileName = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe"),
            Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\"" +
                        (args.Length > 0 ? " " + string.Join(" ", args) : string.Empty),
            UseShellExecute = false
        };

        try
        {
            using (var proc = Process.Start(psi))
            {
                proc.WaitForExit();
                return proc.ExitCode;
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("Failed to start PowerShell: " + ex.Message);
            return 3;
        }
    }
}
