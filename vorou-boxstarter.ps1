# boxstarter.org/package/url?https://raw.githubusercontent.com/vorou/config/master/vorou-boxstarter.ps1

cup -y chocolatey
cinst -y git -params '/GitOnlyOnPath'
if (!(where.exe git)) { Invoke-Reboot }

cd ~
git clone https://github.com/vorou/config.git

cinst -y ConEmu
$conemuLink = "C:\Program Files\ConEmu\ConEmu.xml"
$conemuConfig = resolve-path ~\config\ConEmu.xml
rm $conemuLink
cmd /c mklink $conemuLink $conemuConfig
