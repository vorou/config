Import-Module WebAdministration

# Load posh-git example profile
. 'C:\Users\vorou\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1'

New-Alias f Clear-Host
New-Alias e explorer.exe
New-Alias rap "C:\Program Files\Rapid Environment Editor\RapidEE.exe"
New-Alias vs "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.exe"
New-Alias p .\psake.ps1
New-Alias npp "C:\Program Files (x86)\Notepad++\notepad++.exe"
New-Alias wh where.exe
New-Alias ssh "C:\Program Files (x86)\Git\bin\ssh.exe"
New-Alias 7z "C:\Program Files\7-Zip\7z.exe"
New-Alias rabbitmqctl "C:\Program Files (x86)\RabbitMQ Server\rabbitmq_server-3.3.1\sbin\rabbitmqctl.bat"
New-Alias kdiff "C:\Program Files\KDiff3\kdiff3.exe"

function sln {
    vs (Get-ChildItem -recurse -filter *.sln)[0].FullName
}

function restart($serviceName) {
    Stop-Service $serviceName
    Start-Service $serviceName
}

function xy($computerName) {
    mstsc /v:$computerName
}

function git-dm($Commit = 'HEAD', [switch]$Force) {
    git branch --merged $Commit |
    ? { $_ -notmatch '(^\*)|(^. master$)' } |
    % { git branch $(if($Force) { '-D' } else { "-d" }) $_.Substring(2) }
}

function respec($to) {
    if ($to -eq "d") {
        rm -fo ~\code\gofra\Source\Front\Local.config
    }
    else {
        cp ~\Local.config ~\code\gofra\Source\Front\
    }
    Restart-WebAppPool DefaultAppPool
}

cd ~\code\gofra

function reset-rabbit {
    rabbitmqctl stop_app
    rabbitmqctl reset
    rabbitmqctl start_app
}
