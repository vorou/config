$files =
    "~\.gitconfig",
    "~\.gitignore"
foreach ($f in $files) {
    cp $f
}
git cm "$(get-date)"
git push
