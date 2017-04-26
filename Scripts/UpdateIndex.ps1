$Index = "../Index.html"
$PostPath = "../Posts/"
$IndexBase = "../IndexBase.html"

$PostSliceMark = "<!--POSTSLICES-->"

# Wipe out index
"" | Set-Content $Index

$content = (Get-Content $IndexBase)

$posts = Get-ChildItem $PostPath

$j = 0
$i = 0
for (;($i -lt $content.length) -and ($j -lt $posts.length); $i++) {
	if ($content[$i] -match $PostSliceMark) {
		Write-Host "Adding $j"
		$content[$i] = (Get-Content $posts[$j].fullName)
		$j++
	}
}

$content | Set-Content $index