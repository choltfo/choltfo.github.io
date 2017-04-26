
# Constants
#################################
$Index = "../Index.html"

$IndexBase = "../IndexBase.html"

$HeaderPath = "../header.html"
$HeaderMark = "<!--HEADER-->"

$PostPath = "../Posts/"
$PostSliceMark = "<!--POSTSLICES-->"
$FormattedPostPath = "../FormattedPosts/"
#################################


# Pull first line
# This should be the title of the document
#################################
function Get-PostContents {
	Param (
		$file
	);
	
	$fileContents = Get-Content $file
	return ($fileContents | ? {$_.startsWith("<")} | ? {-not $_.startsWith("<img")} | select -first ([Math]::min( $fileContents.length, 3 )) ) # pare down to a few paragraphs...
}

# Returns furst line of file
#################################
function Get-PostTitle {
	Param (
		$file
	);
	
	return (Get-Content $file | select -first 1)
}

function Get-PostURL {
	Param (
		$file
	);
	$relPath = (rvpa $file -relative)
	$tempOFS = $ofs
	$ofs = ""
	$relPath = "$FormattedPostPath"+[string]$relPath[($PostPath.length)..($relPath.length-1)]
	$ofs = $tempOFS
	return $relPath
}

# Returns the line after PostImage:
function Get-PostImage {
	Param (
		$file
	);
	
	Get-Content $file | select -first 10 | % {
		if ($_.startsWith("PostImage:")) {
			return $_[10..($_.length-1)]
		}
	}
}

# Load all posts and add them to the index page.
# Also, generate the index page.
function updateIndex {
	# Wipe out index
	"" | Set-Content $Index

	$content = (Get-Content $IndexBase)

	$posts = Get-ChildItem $PostPath

	$j = 0
	$i = 0
	for (;($i -lt $content.length) -and ($j -lt $posts.length); $i++) {
		if ($content[$i] -match $PostSliceMark) {
			Write-Host "Adding post summaries"
			$posts | %{
				$content[$i] += "<h3><a href=`""
				$content[$i] += Get-PostURL $_.fullName # NOPENOPENOPE!
				$content[$i] += "`">"
				$content[$i] += (Get-PostTitle $_.fullName)
				$content[$i] += "</a></h3>"
				$content[$i] += "<hr>"
				if (Get-PostImage $_.fullName) {
					$content[$i] += "<img src=`""
					$content[$i] += Get-PostImage $_.fullName
					$content[$i] += "`" width=50% />"
				}
				$content[$i] += (Get-PostContents $_.fullName)
				$content[$i] += "<br>"
			}
		}
		if ($content[$i] -match $HeaderMark) {
			Write-Host "Adding header"
			$content[$i] = (Get-Content $HeaderPath)
		}
	}

$content | Set-Content $index
}

updateIndex