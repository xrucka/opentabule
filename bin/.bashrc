#!/bin/bash
# add standard systemd path
SYSTEMD_UNIT_PATH="${SYSTEMD_UNIT_PATH}:"
export SYSTEMD_UNIT_PATH

function droppath() {
	EXPORTFILE="${HOME}/.local/pathmanip-${RANDOM}"
	touch "${EXPORTFILE}"
	"${HOME}"/.local/scripts/bin/.pathmanip droppath $1 "${EXPORTFILE}"
	source ${EXPORTFILE}
	rm "${EXPORTFILE}"
}
function addpath() {
	EXPORTFILE="${HOME}/.local/pathmanip-${RANDOM}"
	touch "${EXPORTFILE}"
	"${HOME}"/.local/scripts/bin/.pathmanip addpath "$1" "${EXPORTFILE}"
	source ${EXPORTFILE}
	rm "${EXPORTFILE}"
}


for dir in ${HOME}/.local/enabled/* ; do
	if ! [[ -d "$dir" ]] ; then continue; fi
	addpath $dir
done

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
