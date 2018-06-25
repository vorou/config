function HgCompletion {
    param($wordToComplete, $commandAst)

    hg branches | %{$_.split()[0]} |
      Where-Object {$_ -like "$wordToComplete*"} |
      Sort-Object |
      ForEach-Object {
          $_
      }
}

Register-ArgumentCompleter `
  -CommandName 'hg' `
  -Native `
  -ScriptBlock $function:HgCompletion
