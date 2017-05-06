
# Constants
#################################
$Index = "../Index.html"

$IndexBase = "../IndexBase.html"

$HeaderPath = "../header.html"
$HeaderMark = "<!--HEADER-->"

$PostHeaderFile = "../posthead.html"

$PostPath = "../Posts/"
$PostSliceMark = "<!--POSTSLICES-->"
$FormattedPostPath = "../FormattedPosts/"
#################################

$ofs = ""


# Pull first line
# This should be the title of the document
#################################
function Get-PostContents ($file, $preview = $true){
	
	$fileContents = Get-Content $file
	if ($preview) {
		return ($fileContents | ? {$_.startsWith("<")} | ? {-not $_.startsWith("<img")} | select -first ([Math]::min( $fileContents.length, 3 )) ) # pare down to a few paragraphs...
	} else {
		return ($fileContents | ? {$_.startsWith("<")} |select -first ([Math]::min( $fileContents.length, 10000000 )))
	}
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

function buildPostPage {
	Param (
		$file
	);
	$dest = Get-PostURL($file)
	
	echo "Destination is $dest"
	echo "Destination is $(rvpa $dest)"
	echo "File is $file"
	
	"" | set-content $dest
	
	$contents = get-content $PostHeaderFile 
	
	
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

	$content = (Get-Content $IndexBase)

	$posts = Get-ChildItem $PostPath

	$i = 0
	for (;($i -lt $content.length) -and ($j -lt $posts.length); $i++) {
		if ($content[$i] -match $PostSliceMark) {
			Write-Host "Adding post summaries"
			$posts | %{
				
				$postURL = (Get-PostURL $_.fullName)
				$postURL = $postURL[3..($postURL.length - 1)]
				
				$content[$i] += "<h3><a href=`""   #"
				$content[$i] += $postURL
				echo "linking to $($postURL[3..($postURL.length - 1)])"
				$content[$i] += "`">" #" Here to remove bad escape character handing in notepad++
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

updateIndex