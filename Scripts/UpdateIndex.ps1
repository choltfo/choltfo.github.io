$Index = "../Index.html"

$IndexBase = "../IndexBase.html"

$HeaderPath = "../header.html"
$HeaderMark = "<!--HEADER-->"

$PostPath = "../Posts/"
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
	if ($content[$i] -match $HeaderMark) {
		Write-Host "Adding header"
		$content[$i] = (Get-Content $HeaderPath)
	}
}

$content | Set-Content $index