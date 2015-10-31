$config = resolve-path ~\code\config
"config location: $config"

"hosts"
rm "C:\Windows\System32\drivers\etc\hosts"
cmd /c mklink "$home\hosts" "C:\Windows\System32\drivers\etc\hosts"

"atom"
rm -re -fo "$home\.atom"
cmd /c mklink /d "$home\.atom" "$config\.atom"

"removing ConEmu, profile, gitconfig, gitignore"
rm "C:\Users\vorop\AppData\Roaming\ConEmu.xml", "C:\Program Files\ConEmu\ConEmu.xml", $profile, "$home\.gitconfig", "$home\.gitignore"

"removing Sublime"
rm -re -fo "$home\AppData\Roaming\Sublime Text 3\Packages\User"

"ConEmu"
cmd /c mklink "C:\Program Files\ConEmu\ConEmu.xml" "$config\ConEmu.xml"
cmd /c mklink "C:\Users\vorop\AppData\Roaming\ConEmu.xml" "$config\ConEmu.xml"

"Powershell"
mkdir (split-path $profile)
cmd /c mklink $profile "$config\Microsoft.PowerShell_profile.ps1"

"git"
cmd /c mklink "$home\.gitconfig" "$config\.gitconfig"
cmd /c mklink "$home\.gitignore" "$config\.gitignore"

"Sublime"
cmd /c mklink /d "$home\AppData\Roaming\Sublime Text 3\Packages\User" "$config\sublime-3-packages-user\"

"VS"
rm "$home\documents\visual studio 2015\settings\CurrentSettings.vssettings", "$home\AppData\Roaming\JetBrains\Shared\vAny\GlobalSettingsStorage.DotSettings"
cmd /c mklink "$home\documents\visual studio 2015\settings\CurrentSettings.vssettings" "$config\CurrentSettings.vssettings"

"R#"
cmd /c mklink "$home\AppData\Roaming\JetBrains\Shared\vAny\GlobalSettingsStorage.DotSettings" "$config\GlobalSettingsStorage.DotSettings"
