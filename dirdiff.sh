#!/bin/bash

SYSDIR="/home/jman/code/deb-sysverify/test/"
WORKDIR="/home/jman/code/deb-sysverify/workdir/"
TMPROOT="$WORKDIR/test-root/"

# File attribute comparison

# Use mtree to collect attributes for the two directory trees.
# By default mtree compares: flags, gid, mode, nlink, size, link, time, and uid
# Changing directory timestamps add alot of noise and are safe, so remove them.

echo "Comparing attributes of all files and directories in"
echo "    $TMPROOT"
echo "to corresponding files in"
echo "    $SYSDIR"
echo


MTREE=$(freebsd-mtree -c -p "$TMPROOT")
# Join long lines ending with \<newline>
MTREE2=$(echo "$MTREE" \
            | awk '{if (sub(/\\$/,"")) printf "%s", $0; else print $0}')
# Remove "time=" stamps from directories
MTREE3=$(echo "$MTREE2" \
             | awk '{   printf "%s ", $1; 
                        d = 0; 
                        for(col=2; col<=NF; col++)
                            if ( $col == "type=dir" )
                                d = 1;
                        for(col=2; col<=NF; col++)
                            if ( !(d == 1 && $col ~ /^time=/) )
                                printf "%s ", $col;
                        print "";   }')

MTREEDIFF=$(echo "$MTREE3" | freebsd-mtree -p "$SYSDIR")
echo "$MTREEDIFF" | grep --invert-match " extra$" > attrib_changes
# We get a list of extra files for free, so save them if wanted.
# Filter out the "extra" lines and removing the " extra^" column.
EXTRA_FILES=$(echo "$MTREEDIFF" | grep " extra$" \
                | rev | cut --delimiter=" " --fields=2- | rev)
echo "$EXTRA_FILES" > extras



# File content comparison

echo "Comparing binary contents of all files in"
echo "    $TMPROOT"
echo "to corresponding files in"
echo "    $SYSDIR"
echo

# Compare all binaries and files in the extracted test-root/ to the system files
TESTLIST=$(find $TMPROOT -type f)
for file in $TESTLIST; do
    diff --brief "$file" "$SYSDIR${file:${#TMPROOT}}" 
done

