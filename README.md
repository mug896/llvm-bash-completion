# LLVM Bash Completion

This is a bash completion function for the following commands.
these commands can be installed in Ubuntu 22.10 using

> apt install llvm clang lld clang-format clangd 

`llc` `lli` `opt` `bugpoint` `dsymutil` `obj2yaml` `yaml2obj`
`sanstats` `verify-uselistorder` `llvm-addr2line` `llvm-ar` `llvm-as`
`llvm-bcanalyzer` `llvm-c-test` `llvm-cat` `llvm-cfi-verify` `llvm-config`
`llvm-cxxfilt` `llvm-dis` `llvm-dlltool` `llvm-dwarfdump` `llvm-exegesis`
`llvm-extract` `llvm-link` `llvm-lto` `llvm-lto2` `llvm-mc` `llvm-mca`
`llvm-modextract` `llvm-nm` `llvm-objcopy` `llvm-objdump` `llvm-opt-report`
`llvm-ranlib` `llvm-readelf` `llvm-readobj` `llvm-rtdyld` `llvm-size` `llvm-split`
`llvm-stress` `llvm-strings` `llvm-strip` `llvm-symbolizer` `llvm-tblgen`
`llvm-cov` `llvm-pdbutil` `llvm-profdata` `llvm-undname` `llvm-xray`
`clang-format` `clang-format-diff` `ld.lld` `clang-cpp` `clangd`

Completion function for `clang` command can be downloaded separately
from this url https://github.com/mug896/clang-bash-completion


## Usage

You can search for completion words using `*`, `?`, `[...]` glob characters
while writing command line like this

```sh
bash$ opt -*print*[tab]
. . .
--print-after=
--print-after-all
--print-after-isel
--print-all-options
--print-before=
--print-before-all
--print-before-changed
. . .                       # "q"
[tab]                       # [tab] to exit to the prompt.
```


## Installation

Copy contents of gcc-bash-completion.sh to ~/.bash_completion  
open new terminal and try auto completion !


> please leave an issue above if you have any problems using this script.
