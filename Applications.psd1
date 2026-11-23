@{

    Applications = @(

        @{
            Name = "7-Zip"
            DisplayNamePattern = "^7-Zip"
            DisplayName = "7-Zip"
            Installer = "\\infra.lucas.fr\NETLOGON\Applications\7zip\7z-x64.exe"
            InstallerType = "EXE"
            SilentArgs = "/S"
            VersionSource = "FileVersion"
            Processes = @("7zFM")
        }

        @{
            Name = "Firefox"
            DisplayNamePattern = "^Mozilla Firefox"
            DisplayName = "Mozilla Firefox"
            Installer = "\\infra.lucas.fr\NETLOGON\Applications\Firefox\Firefox Setup 160.0.msi"
            InstallerType = "MSI"
            SilentArgs = "/qn /norestart"
            VersionSource = "FileName"
            Processes = @("firefox")
        }

        @{
            Name = "VLC"
            DisplayNamePattern = "^VLC media player"
            DisplayName = "VLC media player"
            Installer = "\\infra.lucas.fr\NETLOGON\Applications\VLC\vlc-3.0.24-win64.exe"
            InstallerType = "EXE"
            SilentArgs = "/S"
            VersionSource = "FileName"
            Processes = @("vlc")
        }

        @{
            Name = "TeamViewer Host"
            DisplayNamePattern = "^TeamViewer Host$"
            DisplayName = "TeamViewer Host"
            Installer = "\\infra.lucas.fr\NETLOGON\Applications\Teamviewer\TeamViewer_Host_Setup_15.82.6.exe"
            InstallerType = "EXE"
            SilentArgs = "/S /norestart"
            VersionSource = "FileName"
            Processes = @("TeamViewer")
            IgnoreIfOtherEditionInstalled = $true
        }

        @{
            Name = "OCS Inventory NG Agent"
            DisplayNamePattern = "^OCS Inventory NG Agent"
            DisplayName = "OCS Inventory NG Agent"
            Installer = "\\infra.lucas.fr\NETLOGON\Applications\OCS\OCS-Windows-Agent-Setup-x64-2.11.0.1.exe"
            InstallerType = "EXE"
            SilentArgs = "/server=https://ocs.groupelucas.fr/ocsinventory /S /NOSPLASH /NOW /SSL=0"
            VersionSource = "FileName"
            Processes = @(
                "OcsService"
                "OcsSystray"
            )
        }


        @{
            Name = "TightVNC"
            DisplayNamePattern = "^TightVNC"
            DisplayName = "TightVNC"
            Installer = "\\infra.lucas.fr\NETLOGON\Applications\Tight\tightvnc-2.8.90-gpl-setup-64bit.msi"            
            InstallerType = "MSI"
            SilentArgs = "/qn /norestart"
            VersionSource = "FileName"
            Processes = @(
                "tvnserver"
                "tvnviewer"
            )

            RegistryPath = "HKLM:\SOFTWARE\TightVNC\Server"

            PostInstallRegistry = @{

                Password = @{
                    Type = "Binary"
                    Value = @(0x30,0x84,0xE8,0x34,0xF4,0xA4,0x08,0xDD)
                }

                QueryConnect = @{ Type="DWord"; Value=1 }
                QueryOnlyIfLoggedOn = @{ Type="DWord"; Value=0 }
                AcceptRfbConnections = @{ Type="DWord"; Value=1 }
                RfbPort = @{ Type="DWord"; Value=5900 }
                AllowLoopback = @{ Type="DWord"; Value=1 }
                AllowShutdown = @{ Type="DWord"; Value=0 }
                AllowProperties = @{ Type="DWord"; Value=0 }
                AllowEditClients = @{ Type="DWord"; Value=0 }
                AcceptHttpConnections = @{ Type="DWord"; Value=0 }
                InputShared = @{ Type="DWord"; Value=0 }
                BlockRemoteInput = @{ Type="DWord"; Value=0 }
                BlockLocalInput = @{ Type="DWord"; Value=0 }
                IpAccessControl = @{
                    Type = "String"
                    Value = "192.168.1.90-192.168.1.94:0"
                }
                ExtraPorts = @{ Type="String"; Value="" }
                QueryTimeout = @{ Type="DWord"; Value=30 }
                QueryAcceptOnTimeout = @{ Type="DWord"; Value=0 }
                LocalInputPriorityTimeout = @{ Type="DWord"; Value=3 }
                LocalInputPriority = @{ Type="DWord"; Value=0 }
                HttpPort = @{ Type="DWord"; Value=5800 }
                DisconnectAction = @{ Type="DWord"; Value=0 }
                UseVncAuthentication = @{ Type="DWord"; Value=1 }
                UseControlAuthentication = @{ Type="DWord"; Value=0 }
                RepeatControlAuthentication = @{ Type="DWord"; Value=0 }
                LoopbackOnly = @{ Type="DWord"; Value=0 }
                LogLevel = @{ Type="DWord"; Value=0 }
                EnableFileTransfers = @{ Type="DWord"; Value=1 }
                RemoveWallpaper = @{ Type="DWord"; Value=1 }
                UseD3D = @{ Type="DWord"; Value=1 }
                UseMirrorDriver = @{ Type="DWord"; Value=1 }
                EnableUrlParams = @{ Type="DWord"; Value=1 }
                AlwaysShared = @{ Type="DWord"; Value=0 }
                NeverShared = @{ Type="DWord"; Value=0 }
                DisconnectClients = @{ Type="DWord"; Value=1 }
                PollingInterval = @{ Type="DWord"; Value=1000 }
                VideoRecognitionInterval = @{ Type="DWord"; Value=3000 }
                GrabTransparentWindows = @{ Type="DWord"; Value=1 }
                SaveLogToAllUsersPath = @{ Type="DWord"; Value=0 }
                RunControlInterface = @{ Type="DWord"; Value=1 }
                ConnectToRdp = @{ Type="DWord"; Value=0 }
                IdleTimeout = @{ Type="DWord"; Value=0 }
                VideoClasses = @{ Type="String"; Value="" }
                VideoRects = @{ Type="String"; Value="" }
            }

            RestartService = "tvnserver"
        }
    )
}