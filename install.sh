#!/bin/sh
set -euf

PACKAGE_NAME='fix-wine-wechat-shadow'

if [[ ! -f "${PACKAGE_NAME}.kwinscript" ]]; then
	echo "Error: can't find package file: ${PWD}/${PACKAGE_NAME}.kwinscript"
	echo "Please run 'pack.sh' first"
	exit 1
fi >&2

plasmapkg2 -i "${PACKAGE_NAME}.kwinscript" || plasmapkg2 -u "${PACKAGE_NAME}.kwinscript"
mkdir -pv "${HOME}/.local/share/kservices5/"
cp -vf "metadata.desktop" "~/.local/share/kservices5/${PACKAGE_NAME}.desktop"
