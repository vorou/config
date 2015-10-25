$config = resolve-path ~\code\config

cmd /c mklink "$home\hosts" "C:\Windows\System32\drivers\etc\hosts"

rm -re -fo "$home\.atom"
cmd /c mklink /d "$home\.atom" "$config\.atom"

rm "C:\Users\vorop\AppData\Roaming\ConEmu.xml", "C:\Program Files\ConEmu\ConEmu.xml", $profile, "$home\.gitconfig", "$home\.gitignore"
rm -re -fo "$home\AppData\Roaming\Sublime Text 3\Packages\User"

cmd /c mklink "C:\Program Files\ConEmu\ConEmu.xml" "$config\ConEmu.xml"
cmd /c mklink "C:\Users\vorop\AppData\Roaming\ConEmu.xml" "$config\ConEmu.xml"
cmd /c mklink $profile "$config\Microsoft.PowerShell_profile.ps1"
cmd /c mklink "$home\.gitconfig" "$config\.gitconfig"
cmd /c mklink "$home\.gitignore" "$config\.gitignore"
cmd /c mklink /d "$home\AppData\Roaming\Sublime Text 3\Packages\User" "$config\sublime-3-packages-user\"

rm "$home\documents\visual studio 2015\settings\CurrentSettings.vssettings", "$home\AppData\Roaming\JetBrains\Shared\vAny\GlobalSettingsStorage.DotSettings"
cmd /c mklink "$home\documents\visual studio 2015\settings\CurrentSettings.vssettings" "$config\CurrentSettings.vssettings"
cmd /c mklink "$home\AppData\Roaming\JetBrains\Shared\vAny\GlobalSettingsStorage.DotSettings" "$config\GlobalSettingsStorage.DotSettings"
