
# Constants
#################################
$Root = Resolve-Path "$PSScriptRoot/../" -Relative

$Layout = "$Root/_partials/layout.html"

$Index = "$Root/index.html"

$HeaderPath = "$Root/_partials/header.html"
$HeaderMark = "<!--HEADER-->"

$InputFolder = "_posts"
$InputPath = "$Root/$InputFolder/"

$PostSliceMark = "<!--POSTSLICES-->"

$OutputFolder = "pub"
$OutputPath = "$Root/$OutputFolder/"

$ImageMark = "PostImage:"

$IndexMark = "PostIndex:"

#################################

$ofs = ""
$ErrorActionPreference = "Stop"

# Pull first line
# This should be the title of the document
#################################
function Get-PostContents ($file, $preview = $true){
	
	$fileContents = Get-Content $file
	if ($preview) {
		return ($fileContents | ? {$_.startsWith("<")} | ? {-not $_.startsWith("<img")} | select -first ([Math]::min( $fileContents.length, 3 )) ) # pare down to a few paragraphs...
	} else {
		return ($fileContents | ? {($_ -replace '\s','').startsWith("<")} | select -first ([Math]::min( $fileContents.length, 10000000 )))
	}
}

# Returns first line of file
#################################
function Get-PostTitle {
	Param (
		$file
	);
	
	return (Get-Content $file | select -first 1)
}

function Get-PostIndex {
	Param (
		$file
	);
	
	Get-Content $file | select -first 10 | % {
		if ($_.startsWith($IndexMark)) {
			return $_[$IndexMark.length..($_.length-1)]
		}
	}
	
	return 0;
}

function Get-PostURL {
	Param (
		$file
	);
	$relPath = (Resolve-Path $file -relative)

	$relPath = $relPath -replace "$InputFolder", "$OutputFolder"

	return $relPath
}

# Returns the line after PostImage:
function Get-PostImage {
	Param (
		$file
	);
	
	Get-Content $file | select -first 10 | % {
		if ($_.startsWith($ImageMark)) {
			return $_[$ImageMark.length..($_.length-1)]
		}
	}
}

function buildPostPage {
	Param (
		$file
	);
	$dest = Get-PostURL($file)
	
	echo "Destination is $dest"
	echo "File is $file"
	
	"" | set-content $dest
	
	$contents = get-content $Layout 
	
	
	$contents | ? {$_.startsWith("<")} | %{
		if ($_ -match $PostSliceMark) {
			$_ += "<h1>"
			$_ += Get-PostTitle $file
			$_ += "</h1>"
			$_ += Get-PostContents -file $file -preview $false
		}
		if ($_ -match $HeaderMark) {
			$_ = get-content $HeaderPath
		}
		
		$_ # Drop $_ onto pipe/stack
	} | add-content $dest
	
	#get-content $file | add-content $dest
	
}

# Load all posts and add them to the index page.
# Also, generate the index page.
function updateIndex {
	# Wipe out index
	"" | Set-Content $Index

	$content = (Get-Content $Layout)

	$posts = Get-ChildItem $InputPath
	
	$posts = $posts | sort-object -descending {Get-PostIndex $_.fullName}

	$i = 0
	
	# For each line in the template
	for (;($i -lt $content.length) -and ($j -lt $posts.length); $i++) {
		if ($content[$i] -match $PostSliceMark) {
			Write-Host "Adding post summaries"
			$posts | ForEach-Object {
				
				$postURL = (Get-PostURL $_.fullName)
				$postURL = $postURL[1..($postURL.length - 1)]
				echo "linking to $postURL"
				$content[$i] += "<h3><a href=`""   #"
				$content[$i] += $postURL
				$content[$i] += "`">" #" This comment is here to remove bad escape character handing in notepad++
				$content[$i] += (Get-PostTitle $_.fullName)
				$content[$i] += "</a></h3>"
				$content[$i] += "<hr>"
				if (Get-PostImage $_.fullName) {
					$content[$i] += "<img src=`""
					$content[$i] += Get-PostImage $_.fullName
					$content[$i] += "`" width=50% />"
				}
				$content[$i] += (Get-PostContents $_.fullName)
				
				$content[$i] += "<p><a href=`"$postURL`">Continue reading</a></p>"
				$content[$i] += "<br>"
				
				buildPostPage($_.fullName)
			}
		}
		if ($content[$i] -match $HeaderMark) {
			Write-Host "Adding header"
			$content[$i] = (Get-Content $HeaderPath)
		}
	}

$content | Set-Content $index
}

cd $Root
updateIndex

echo "Running server..."
echo "Crtl-c to exit"
python -m http.server
