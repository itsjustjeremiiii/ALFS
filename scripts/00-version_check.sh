#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/tools/colors.conf"

LC_ALL=C 
PATH=/usr/bin:/bin

head "LFS Host System Requirements Check"
echo ""

bail() { 
    echo "$FAIL $1"
    exit 1
}

grep --version > /dev/null 2> /dev/null || bail "grep does not work"
sed '' /dev/null || bail "sed does not work"
sort /dev/null || bail "sort does not work"

ver_check() {
    if ! type -p $2 &>/dev/null
    then 
        echo "$FAIL Cannot find $2 ($1)"
        return 1
    fi
    v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
    if printf '%s\n' $3 $v | sort --version-sort --check &>/dev/null
    then 
        printf "$PASS %-12s [$v] >= $3\n" "$1"
        return 0
    else 
        printf "$FAIL %-12s [$v] >= $3\n" "$1"
        return 1
    fi
}

ver_kernel() {
    kver=$(uname -r | grep -E -o '^[0-9\.]+')
    if printf '%s\n' $1 $kver | sort --version-sort --check &>/dev/null
    then 
        echo "$PASS Linux Kernel [$kver] >= $1"
        return 0
    else 
        echo "$FAIL Linux Kernel [$kver] >= $1"
        return 1
    fi
}

proc "Core Utilities"
ver_check Coreutils      sort     8.1 || bail "Coreutils too old, cannot continue" # This is because even the script relies on coreutils
ver_check Bash           bash     3.2
ver_check Diffutils      diff     2.8.1
ver_check Findutils      find     4.2.31
ver_check Gawk           gawk     4.0.1
ver_check Grep           grep     2.5.1a
ver_check Gzip           gzip     1.3.12
ver_check Sed            sed      4.1.5
ver_check Tar            tar      1.22
ver_check Xz             xz       5.0.0

echo ""
proc "Build Tools"
ver_check Binutils       ld       2.13.1
ver_check Bison          bison    2.7
ver_check M4             m4       1.4.10
ver_check Make           make     4.0
ver_check Patch          patch    2.5.4
ver_check Texinfo        texi2any 5.0

echo ""
proc "Compilers"
ver_check GCC            gcc      5.4
ver_check "GCC (C++)"    g++      5.4

echo ""
proc "Scripting Languages"
ver_check Perl           perl     5.8.8
ver_check Python         python3  3.4

echo ""
proc "Kernel"
ver_kernel 5.4

if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]
then echo "$PASS Linux Kernel supports UNIX 98 PTY"
else echo "$FAIL Linux Kernel does NOT support UNIX 98 PTY"; fi

echo ""
proc "Symlinks"
alias_check() {
    if $1 --version 2>&1 | grep -qi $2
    then echo "$PASS $1 is $2"
    else echo "$FAIL $1 is NOT $2"; fi
}
alias_check awk GNU
alias_check yacc Bison
alias_check sh Bash

echo ""
proc "Compiler Functionality"
if printf "int main(){}" | g++ -x c++ -
then echo "$PASS g++ works"
else echo "$FAIL g++ does NOT work"; fi
rm -f a.out

echo ""
proc "System Resources"
if [ "$(nproc)" = "" ]; then
    echo "$FAIL nproc is not available or produces empty output"
else
    echo "$PASS nproc reports $(nproc) logical cores available"
fi

echo ""
head "Host system check complete"
