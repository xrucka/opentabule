#!/bin/bash

function usage(){
	printf "Usage: %s [-i <instance-id>] <command> [filename]\n" "$1"
	printf "\t%s [-i <instance-id>] convert <filename>\n" "$1"
	printf "\t%s [-i <instance-id>] unemployed <filename>\n" "$1"
	printf "\t%s [-i <instance-id>] pause\n" "$1"
	printf "\t%s [-i <instance-id>] resume\n" "$1"
}

function err_exit(){
	printf "%s\n" "$2" >&2
	exit $1
}

binary="$0"
ffmpegbinary="ffmpeg"
instance=0
cmd=""
filename=""
tmpdir="/tmp"

while [[ $# -gt 0 ]] ; do
	if [[ "x$1" = "x-h" ]] || [[ "x$1" = "x--help" ]] ; then
		usage "$binary"
		exit 1
	elif [[ "x$1" = "x-i" ]] || [[ "x$1" = "x--instance" ]] ; then
		shift
		instance="$1"
	elif [[ "x$cmd" = "x" ]] ; then
		cmd="$1"
	elif [[ "x$filename" = "x" ]] ; then
		filename="$1"
	fi
	
	shift
done

if [[ ! "x$filename" = "x" ]] ; then
	filename="$(realpath "$filename")"
fi
pidfilename="/tmp/movie-crawler-worker-$instance"
pid=

if [[ -f "$pidfilename" ]] ; then
	pid=$(cat "$pidfilename" | sed -r 's#^([0-9]+)([^0-9].*)?$#\1#g')
fi

case "$cmd" in 
"unemployed")
	if [[ -f "$pidfilename" ]] ; then
		oldfile="$(cat "$pidfilename" | sed -r 's#^[^ ]+ ##g')"
		if grep -- "$(basename "$binary")" "/proc/$pid/cmdline" 1>/dev/null 2>&1 ; then
			kill -s SIGCONT "$pid"
			err_exit 1 "Allready running on different? file"
		fi
	fi
	;;&
"convert" | "unemployed")
	[[ ! -f "$tmpfile" ]] || err_exit 3 "File is allready processed"

	rm -f "$pidfilename"
	pid=$$
	printf "%s %s\n" "$pid" "$filename" > "$pidfilename"
	
	tmpfile="$tmpdir/$(basename "$filename").$pid.mkv"
	tgtfile="$(echo "$filename" | sed -r 's#[.][a-zA-Z0-9]+$#.mkv#g')"
	nice -n 19 "$ffmpegbinary" -i "$filename" -c:a copy -c:v libx265 -preset veryslow "$tmpfile" || err_exit 1 "FFmpeg failed"
	[[ ! -f "$tgtfile" ]] && mv "$tmpfile" "$tgtfile" || echo "target file still in place!" 1>&2
	[[ "$tgtfile" != "$filename" ]] && rm "$filename" || echo "original file kept in place!" 1>&2

	rm "$pidfilename"
	;;
"pause")
	# signal pid from pidfile
	kill -s SIGTSTP "$pid"
	;;
"resume")
	# signal pid from pidfile
	kill -s SIGCONT "$pid"
	;;
esac 

exit 0