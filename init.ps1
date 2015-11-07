$config = resolve-path ~\code\config
"config location: $config"

function mklink($link, $target, $message) {
  "# $message"
  rm $link -erroraction silentlyContinue
  cmd /c mklink $link $target
  ""
}

function mkdlink($link, $target) {
  rm -re -fo $link -erroraction silentlyContinue
  cmd /c mklink /d $link $target
}

mklink "$home\hosts" "C:\Windows\System32\drivers\etc\hosts" "hosts"

mkdlink "$home\.atom" "$config\.atom" "atom"

mklink "C:\Program Files\ConEmu\ConEmu.xml" "$config\ConEmu.xml" "ConEmu"
mklink "C:\Users\vorop\AppData\Roaming\ConEmu.xml" "$config\ConEmu.xml" "ConEmu"

mkdir (split-path $profile) -errorAction silentlyContinue
mklink $profile "$config\Microsoft.PowerShell_profile.ps1" "Powershell"

mklink "$home\.gitconfig" "$config\.gitconfig" "gitconfig"
mklink "$home\.gitignore" "$config\.gitignore" "gitignore"

mkdlink "$home\AppData\Roaming\Sublime Text 3\Packages\User" "$config\sublime-3-packages-user\" "Sublime"

mklink "$home\documents\visual studio 2015\settings\CurrentSettings.vssettings" "$config\CurrentSettings.vssettings" "VS"

mklink "$home\AppData\Roaming\JetBrains\Shared\vAny\GlobalSettingsStorage.DotSettings" "$config\GlobalSettingsStorage.DotSettings" "R#"
