#!/bin/sh

n_fail=0;

while read -r file; do
	if ! test -e "$file"; then echo "no such file: $file" 1>&2; continue; fi
	if tmp=$(mktemp /tmp/situ.XXXXXXXXXXXX) && "$@" <"$file" >"$tmp" && cat <"$tmp" >"$file" && rm "$tmp"; then echo "$file"
	else
		echo "failed to modify $file" 1>&2
		n_fail=$(($n_fail + 1))
	fi
done

exit $n_fail;
