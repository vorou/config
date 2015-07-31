$config = resolve-path ~\code\config
cmd /c mklink "C:\Program Files\ConEmu\ConEmu.xml" "$config\ConEmu.xml"
cmd /c mklink $profile "$config\Microsoft.PowerShell_profile.ps1"
cmd /c mklink "$home\documents\visual studio 2015\settings\CurrentSettings.vssettings" "$config\CurrentSettings.vssettings"
cmd /c mklink "$home\AppData\Roaming\JetBrains\ReSharper\vAny\GlobalSettingsStorage.DotSettings" "$config\GlobalSettingsStorage.DotSettings"
cmd /c mklink /d "$home\AppData\Roaming\Sublime Text 3\Packages\User" "$config\sublime-3-packages-user\"