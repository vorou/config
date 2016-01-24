# git merge-base --is-ancestor <commit> <commit>

Import-Module WebAdministration
Import-Module PSReadLine
Import-Module Mdbc
Import-Module '~\Documents\WindowsPowerShell\Modules\Jump.Location\Jump.Location.psd1'


Remove-Item alias:curl
New-Alias restart Restart-Computer
New-Alias sco sc.exe
New-Alias f Clear-Host
New-Alias e explorer.exe
New-Alias rap "C:\Program Files\Rapid Environment Editor\RapidEE.exe"
New-Alias vs "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\devenv.exe"
New-Alias p .\psake.ps1
New-Alias n "C:\Program Files (x86)\Notepad++\notepad++.exe"
New-Alias wh where.exe
New-Alias ssh "C:\bin\gitbin\ssh.exe"
New-Alias 7z "C:\Program Files\7-Zip\7z.exe"
New-Alias rabbitmqctl "C:\Program Files (x86)\RabbitMQ Server\rabbitmq_server-3.5.3\sbin\rabbitmqctl.bat"
New-Alias kdiff "C:\Program Files\KDiff3\kdiff3.exe"
New-Alias st "C:\Program Files (x86)\Atlassian\SourceTree\SourceTree.exe"
New-Alias json ConvertFrom-Json
New-Alias gh "C:\Users\vorou\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\GitHub, Inc\GitHub.appref-ms"
New-Alias subl "C:\Program Files\Sublime Text 3\sublime_text.exe"
New-Alias rein 'C:\bin\ReadyToIndex\ReadyToIndexMessageSender.exe'
New-Alias down 'C:\bin\DownloadAttachments\DownloadAttachments.exe'
New-Alias npp 'C:\Program Files (x86)\Notepad++\notepad++.exe'
New-Alias rssv Restart-Service

function idea {
   & "C:\Program Files (x86)\JetBrains\IntelliJ IDEA Community Edition 14.1.3\bin\idea.exe" $pwd
}
function co {
  git co $args
}

function logstash {
    rm c:\.sincedb*
    rm C:\Windows\System32\config\systemprofile\.sincedb*
    rm ~\.sincedb*

    C:\Logstash\bin\logstash.bat agent --verbose -f C:\Users\vorou\code\gofra\Deployment\logstash.conf 2>&1
}

function sln {
    vs (Get-ChildItem -recurse -filter *.sln)[0].FullName
}

function xy($computerName) {
    mstsc /v:$computerName
}

function git-dm($Commit = 'HEAD', [switch]$Force) {
    git branch --merged $Commit |
    ? { $_ -notmatch '(^\*)|(^. master$)|(^. develop$)' } |
    % { git branch $(if($Force) { '-D' } else { "-d" }) $_.Substring(2) }
}

function respec($to) {
    if ($to -eq "d") {
        rm -fo ~\code\gofra\Source\Front\Local.config -errorAction silentlyContinue
    }
    else {
        cp ~\Local.config ~\code\gofra\Source\Front\
    }
    Restart-WebAppPool DefaultAppPool
}

function Reset-Rabbit {
    rabbitmqctl stop_app
    rabbitmqctl reset
    rabbitmqctl start_app
}

$services = "RabbitMQ", "MongoDB", "elasticsearch-service-x64"

function Dev {
    foreach ($s in $services) {
        Get-Service $s
    }
}

function Dev-On {
    foreach ($s in $services) {
        Start-Service $s
    }
}

function Dev-Off {
    foreach ($s in $services) {
        Stop-Service $s
    }
}

function cwd {
    (Resolve-Path .).ToString() | clip
}

function copy-path($item) {
    (Resolve-Path $item).ToString() | clip
}

function rs {
    Restart-WebAppPool DefaultAppPool
}

function cm {
    If (Test-Path .\commit-message.txt)
    {
        rm .\commit-message.txt
    }

    Write-Host -NoNewLine "message: "
    $msg = Read-Host
    Add-Content -Encoding UTF8 .\commit-message.txt $msg

    Write-Host -NoNewLine "description: "
    $desc = Read-Host
    if ($desc) {
        Add-Content -Encoding UTF8 .\commit-message.txt ""
        Add-Content -Encoding UTF8 .\commit-message.txt $desc
    }

    git add -A
    git commit -F .\commit-message.txt
}

function test-proxy($proxy) {
    http --headers --proxy=http:http://VIP126053:G4R9sQcpE8@$proxy example.org
}

function mv-oldlogs($root) {
    $backupRoot = join-path $root "bak"
    $backupDate = Get-Date -f yyyyMMdd_hhmmss
    $backupDir = "$backupRoot\\logs_$backupDate\\"
    mkdir -force $backupDir
    $logsDir = join-path $root "logs"
    ls $logsDir | where {$_.LastWriteTime -lt (Get-Date).AddDays(-2)} | mv -dest $backupDir
}

function find-badreferences($dll, $nuget) {
    $projects = ls -re packages.config | sls $nuget -list | select -expand path | %{split-path (split-path $_ -parent) -leaf}
    ls -re *.csproj | where {sls -simple -pattern $dll $_} | select -expand basename | ? {$_ -notin $projects}
}

function zip($folder) {
  7z
}

function unzip($zip, $output) {
    7z x $zip "-o$output"
}

function isAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
}

function save {
    ~\code\config\save.ps1
}

function bye {
    save
    Stop-Computer -Force
}

function off {
    Stop-Computer -Force
}

function c {
  cd ~\code
}

function g {
  cd ~\code\gofra
}

function Get-Region($id) {
    [Guid]$id.ToString() | %{mongo gofra1/gofra --eval ("printjson(db.regions.findOne({_id: '" + $_ + "'}))")}
}

function octave {
  C:\Software\Octave-3.6.4\bin\octave.exe -i
}

function raw($url) {
  $url -match '(?:.*\/|^)(.*)$' | out-null
  $id = $Matches[1]
  $output = "$env:home\desktop\output.js"
  mongoexport --quiet --pretty -h gofra1 -d gofra -c purchases -q @('{"_id":'''+$id+'''}') -o $output
  atom $output
}

function me($command) {
  $printJson = 'printjson("'+$command+'")'
  mongo gofra2/gofra --eval $printJson
}

. ~\code\config\ps\Remove-Item.ps1

function ssh-gofra {
  (sls gofra ~\code\gofra\Deployment\credentials.md)[0].Line.Split(':')[1] | clip
  ssh gofra@zakupki.kontur.ru
}

function http-gpb($id) {
  '{"action":"Procedure","method":"load","data":[{"procedure_id":"' + $id +'","act":null}],"type":"rpc","tid":4,"token":null}' | http post 'https://etp.gpb.ru/index.php?rpctype=direct&amp;amp;module=default' --timeout=120
}

function raw-gpb($id) {
  $out = "C:\Users\vorou\Desktop\GPB-$id.json"
  http-gpb $id | out-file -enc utf8 $out
  atom $out
}

function send-notify {
  '{"vhost":"/","name":"amq.default","properties":{"delivery_mode":1,"headers":{},"type":"DataAccess.Messaging.NotifyUsersAboutNewPurchasesMessage:Zakupki.DataAccess"},"routing_key":"DataAccess.Messaging.NotifyUsersAboutNewPurchasesMessage:Zakupki.DataAccess_NotifyUsersAboutNewPurchasesMessage","delivery_mode":"1","payload":"{}","headers":{},"props":{"type":"DataAccess.Messaging.NotifyUsersAboutNewPurchasesMessage:Zakupki.DataAccess"},"payload_encoding":"string"}' | http post http://localhost:15672/api/exchanges/%2F/amq.default/publish Authorization:'Basic Z3Vlc3Q6Z3Vlc3Q='
}

function deploy-notify {
  p update-services -properties @{config='Debug'; services='EmailService','NewPurchasesNotificationService'}
  send-notify
}

function logs {
  rm c:\logs\*
  atom c:\logs\
}

function import-dump {
  rm -rf c:\Users\vorou\Desktop\dump
  mkdir C:\Users\vorou\Desktop\dump
  7z e C:\Users\vorou\Desktop\dump.7z -oC:\Users\vorou\Desktop\dump
  Connect-Mdbc . easynetq dump -NewCollection
  $Database.DropCollection('dump')
  ls ~\Desktop\dump\*message* | cat | json | Add-MdbcData
}

function pc {
  p compile
}


# posh-git
Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)
Import-Module ~\code\posh-git\posh-git.psm1
function global:prompt {
    Write-Host
    $realLASTEXITCODE = $LASTEXITCODE
    Write-Host($pwd.ProviderPath) -nonewline
    Write-VcsStatus
    $global:LASTEXITCODE = $realLASTEXITCODE
    Write-Host
    return "$ "
}
Pop-Location
