$files =
    "$profile",
    "~\.gitconfig",
    "~\.gitignore",
    "c:\bin\ConEmu\ConEmu.xml"

foreach ($f in $files) {
    cp $f
}
git cm "$(get-date)"
git push
