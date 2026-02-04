// PSModulePath Manager Icon Launcher with Icon Resource
using System;
using System.Diagnostics;

class Program
{
    static void Main()
    {
        try
        {
            var scriptPath = System.IO.Path.Combine(
                System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location),
                "PSModulePath-Manager.ps1"
            );

            var startInfo = new ProcessStartInfo
            {
                FileName = "pwsh.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + scriptPath + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };

            Process.Start(startInfo);
        }
        catch
        {
            // Fallback to powershell.exe
            var scriptPath = System.IO.Path.Combine(
                System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location),
                "PSModulePath-Manager.ps1"
            );

            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + scriptPath + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };

            Process.Start(startInfo);
        }
    }
}
