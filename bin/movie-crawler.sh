#!/bin/bash

function usage(){
	printf "Usage: %s <directory-to-crawl>\n" "$1"
}

function err_exit(){
	printf "%s\n" "$2" >&2
	exit $1
}

binary="$0"
worker="movie-crawler-worker.sh"
instance=0
directory=""
tmpdir="/tmp"

while [[ $# -gt 0 ]] ; do
	if [[ "x$1" = "x-h" ]] || [[ "x$1" = "x--help" ]] ; then
		usage "$binary"
		exit 1
	elif [[ "x$1" = "x-i" ]] || [[ "x$1" = "x--instance" ]] ; then
		shift
		instance="$1"
	elif [[ "x$directory" = "x" ]] ; then
		directory="$1"
	fi
	
	shift
done

if [[ ! "x$directory" = "x" ]] ; then
	directory="$(realpath "$directory")"
fi

find "$directory" -regextype posix-extended -iregex '.*[.]((mkv)|(mp4)|(avi)|(vmw))$' -print0 | sort -z -R | while read -r -d $'\0' cf ; do
	filename="$(realpath "$cf")"
	if (ffmpeg -i "$filename" |& grep -E 'Video:.*((libx265)|(hevc)|(h265))' 1>/dev/null 2>&1) ; then
		continue
	fi

	# filename is a good candidate
	if [[ $(( RANDOM % 10 )) -lt 5 ]] ; then
		# not this time baby
		continue
	fi

	"$worker" -i "$instance" unemployed "$filename" &
	exit 0
done
