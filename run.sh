!#/bin/bash
erl -sname "$1" -kernel prevent_overlapping_paritions false
