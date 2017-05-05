#!/bin/bash
# add standard systemd path
TABULEROOT="${BASH_SOURCE[0]}"
if [[ "x$TABULEROOT" == "x" ]] ; then
	echo "Unable to determine opentabule scripts root" 1>&2
fi

TABULEROOT="$(realpath "$(dirname "$(realpath "$TABULEROOT")")/..")"

SYSTEMD_UNIT_PATH="${SYSTEMD_UNIT_PATH}:"
export SYSTEMD_UNIT_PATH

# claim cache file
OPENTABULE_CACHEFILE="${HOME}/.local/enabled/.cache"
export OPENTABULE_CACHEFILE

function droppath() {
	EXPORTFILE="${HOME}/.pathmanip-${RANDOM}"
	touch "${EXPORTFILE}"
	"${TABULEROOT}"/libexec/opentabule/pathmanip droppath $1 "${EXPORTFILE}"
	source ${EXPORTFILE}
	rm "${EXPORTFILE}"
}
function addpath() {
	EXPORTFILE="${HOME}/.pathmanip-${RANDOM}"
	touch "${EXPORTFILE}"
	"${TABULEROOT}"/libexec/opentabule/pathmanip addpath "$1" "${EXPORTFILE}"
	source ${EXPORTFILE}
	rm "${EXPORTFILE}"
}
function rebuildpathcache(){
	echo "#!/bin/bash" > "${OPENTABULE_CACHEFILE}"

	for dir in ${HOME}/.local/enabled/* ; do
		if ! [[ -d "$dir" ]] ; then continue; fi
		"${TABULEROOT}"/libexec/opentabule/pathmanip addpath "$dir" "${OPENTABULE_CACHEFILE}"
	done
}
function enablepath() {
	local ENABLE="$1"
	local ENABLELINKNAME="$(basename "$1")"
	local ENABLEBASE="${HOME}/.local/enabled"
	local TARGET="."
	local TARGET_STD="${ENABLEBASE}/../${ENABLE}"

	mkdir -p "${ENABLEBASE}"

	if [[ -d "${ENABLEBASE}/${ENABLELINKNAME}" ]] ; then
		echo "entry named ${ENABLELINKNAME} allready exist - consider manual link creation" 1>&2
		return 1;
	fi

	if [[ -d "${ENABLE}" ]] ; then
		echo "entry ${ENABLE} found local to $(realpath .)"
		TARGET="$(realpath "${ENABLE}")"
	elif [[ -d "${TARGET_STD}" ]] ; then
		echo "entry ${ENABLE} found local to $(realpath "${ENABLEBASE}/..")"
		TARGET="${TARGET_STD}"
	else
		echo "${ENABLE} not found in any path" 1>&2 
		return 1;
	fi

	ln -s "$(realpath --relative-to "${ENABLEBASE}" "${TARGET}")" "${ENABLEBASE}/${ENABLELINKNAME}"
	addpath "${ENABLELINKNAME}"

	# build cache
	rebuildpathcache

}
function disablepath() {
	local DISABLE="$1"
	local ENABLEBASE="${HOME}/.local/enabled"

	local RELATIVE="$(realpath --relative-to "${ENABLEBASE}" "${DISABLE}")"

	pushd "$ENABLEBASE" > /dev/null
	for dir in * ; do
		if ! [[ -d "$dir" ]] ; then continue; fi
		if ! [[ "x$(realpath --relative-to "${ENABLEBASE}" "${dir}")" = "x$RELATIVE" ]] ; then continue ; fi
		rm "$dir"
	done
	popd > /dev/null

	# build cache
	rebuildpathcache
}


source "${OPENTABULE_CACHEFILE}"

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
