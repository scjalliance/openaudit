#!/bin/bash

function __oae.Usage {
	echo ""
	echo "usage: $0 <version> [destination]"
	echo ""
	echo "  version:     'all' means to build all versions listed in versions.txt"
	echo "               '1.2.3' means to build only version '1.2.3' (for example)"
	echo ""
	echo "  destination: if version==all, where the build directories will go (subdir created per version)"
	echo "               if version!=all, where the single build will go (no subdir created)"
	echo "               if omitted, destination is parent directory"
	echo ""
}

function __oae.Build {
	local S="$1"
	local V="$2"
	local D="$3"
	cat Dockerfile | sed "s/%VERSION%/$V/g" > "$D/Dockerfile"
	cp -a run.sh "$D/run.sh"
	pushd "$D" >/dev/null
	rm -f build.okay
	docker build -t "scjalliance/openaudit:$V" . | tee build.log && touch build.okay
	popd >/dev/null
}

function __oae.PrepAndBuild {
	local S="$1"
	local V="$2"
	local D="$3"
	if [ -z "$S" -o -z "$V" -o -z "$D" ]; then
		echo "Source directory, version number, or destination directory is not specified.  Aborting."
		echo -e "S=$S\nV=$V\nD=$D"
		__oae.Usage
		exit 1
	fi
	echo "$V = $D"
	mkdir -p "$D"
	__oae.Build "$S" "$V" "$D"
}

##### start...

if [ "$1" == "-h" -o "$1" == "help" ]; then
	__oae.Usage
	exit 1
fi

S="$(readlink -f "$(dirname "$0")")"
V="$1"
D="$2"

if [ -z "$V" ]; then
	echo "You must supply either 'all' or the version number to build, such as '1.12.10', as the first argument."
	__oae.Usage
	exit 1
else
	if [ "$V" == "all" ]; then
		cat versions.txt | tac | while read Vi; do
			Di="$(readlink -m "${D:-$S/..}/$Vi")"
			__oae.PrepAndBuild "$S" "$Vi" "$Di"
		done
	else
		Di="${D:-$(readlink -m "$S/../$V")}"
		__oae.PrepAndBuild "$S" "$V" "$Di"
	fi
fi
