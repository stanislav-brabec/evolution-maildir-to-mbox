#!/bin/bash

EXPORT_DIR="$HOME/MAIL-EVO-EXPORT"

shopt -s nullglob
set -o errexit

mkdir "$EXPORT_DIR"
cd ~/.local/share/evolution/mail/local

if ! test -f "..maildir++" ; then
	echo >&2 "$0: ~/.local/share/evolution/mail/local does not contain ..maildir++. Probably not an Evolution maildir."
	exit 1
fi

find . -name cur -type d | while read ; do
	DIR="${REPLY%/*}"
	eval test \" "$DIR/new"/* \" = \"  \"
	if test $? -gt 0 ; then
		echo >&2 "$0: $DIR/new is not empty. Probably not an Evolution maildir."
		exit 1
	fi
	eval test \" "$DIR/tmp"/* \" = \"  \"
	if test $? -gt 0 ; then
		echo >&2 "$0: $DIR/tmp is not empty. Probably not an Evolution maildir."
		exit 1
	fi
	if test "$DIR" = "." ; then
		EXPORT_MBOX="Inbox"
	else
		DIR=${DIR#./}
		if test "$DIR" = .Inbox ; then
			echo >&2 "$0: Maildir named .Inbox should never exist!"
			exit 1
		fi
		EXPORT_MBOX=${DIR#.}
		EXPORT_MBOX=${EXPORT_MBOX//.//}
	fi
	EXPORT_PATH=$EXPORT_DIR/${EXPORT_MBOX////.sbd/}

	mkdir -p "${EXPORT_PATH%/*}"

	echo >&2 "$EXPORT_MBOX..."
	for MSG in "$DIR"/cur/* ; do
		FLAGS=${MSG##*,}

		STATUS=O
		case $FLAGS in
		# Read
		*S* )
			STATUS=R${STATUS}
			;;
		esac

		XSTATUS=
		case $FLAGS in
		# Replied
		*R* )
			XSTATUS=${XSTATUS}A
			;;
		esac
		case $FLAGS in
		# Flagged
		*F* )
			XSTATUS=${XSTATUS}F
			;;
		esac
		case $EXPORT_MBOX in
		# Draft
		Drafts )
			XSTATUS=${XSTATUS}T
			;;
		esac
		case $FLAGS in
		# Deleted
		*T* )
			XSTATUS=${XSTATUS}D
			;;
		esac

		formail -I "Status: $STATUS" -I "X-Status: $XSTATUS" <"$MSG"
	done >"$EXPORT_PATH"

done

echo >&2 "Finishing..."
find "$EXPORT_DIR" -name "*.sbd" -type d | while read ; do
	if ! test -f "${REPLY%.sbd}" ; then
		touch "${REPLY%.sbd}"
	fi
done
