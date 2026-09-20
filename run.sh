!#/bin/bash
erl -sname "$1" -kernel prevent_overlapping_partitions false
