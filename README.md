# LLVM Bash Completion

This is a bash completion function for the following commands.
these commands can be installed in Ubuntu 22.10 using

> bash# apt install llvm clang clang-tools clang-format clang-tidy clangd lld lldb

`llc` `lli` `opt` `lldb` `bugpoint` `dsymutil` `obj2yaml` `yaml2obj`
`sanstats` `verify-uselistorder` `llvm-addr2line` `llvm-ar` `llvm-as`
`llvm-bcanalyzer` `llvm-c-test` `llvm-cat` `llvm-cfi-verify` `llvm-config`
`llvm-cxxfilt` `llvm-dis` `llvm-dlltool` `llvm-dwarfdump` `llvm-exegesis`
`llvm-extract` `llvm-link` `llvm-lto` `llvm-lto2` `llvm-mc` `llvm-mca` `llvm-diff`
`llvm-modextract` `llvm-nm` `llvm-objcopy` `llvm-objdump` `llvm-opt-report`
`llvm-ranlib` `llvm-readelf` `llvm-readobj` `llvm-rtdyld` `llvm-size` `llvm-split`
`llvm-stress` `llvm-strings` `llvm-strip` `llvm-symbolizer` `llvm-tblgen`
`llvm-cov` `llvm-pdbutil` `llvm-profdata` `llvm-undname` `llvm-xray` `ld.lld`
`wasm-ld` `clang-format` `clang-format-diff` `clangd` `clang-tidy`
`clang-tidy-diff` `run-clang-tidy`

The following commands do not have symbolic links. so I made it like this:  

> bash# ln -s /usr/bin/clang-cpp-15 /usr/bin/clang-cpp

Or you can just add `/usr/lib/llvm-15/bin/` directory to the `$PATH` variable.

`clang-cpp` `llvm-gsymutil`  `llvm-debuginfod` `llvm-debuginfod-find` `llvm-ifs`
`llvm-install-name-tool` `llvm-jitlink` `llvm-jitlink-executor` `llvm-libtool-darwin`
`llvm-lipo` `llvm-otool` `llvm-tli-checker` `llvm-windres` `llvm-cxxmap`
`llvm-dwarfutil` `llvm-dwp` `llvm-reduce` `llvm-remark-size-diff` `llvm-profgen` `llvm-sim`
`clang-apply-replacements` `clang-change-namespace` `clang-check clang-doc`
`clang-extdef-mapping` `clang-include-fixer` `clang-linker-wrapper` `clang-move`
`clang-nvlink-wrapper` `clang-offload-bundler` `clang-offload-packager` `clang-cl`
`clang-offload-wrapper` `clang-pseudo` `clang-query` `clang-refactor` `clang-rename`
`clang-reorder-fields` `clang-repl` `clang-scan-deps` `analyze-build` `c-index-test`
`find-all-symbols` `hwasan_symbolize` `intercept-build` `modularize` `pp-trace sancov`
`scan-build` `scan-build-py` `scan-view` `diagtool` `hmaptool`


> Commands written in scripts ( not binary executables ) can be a bit slow.


Completion function for `clang` `clang++` commands can be downloaded separately
from this url https://github.com/mug896/clang-bash-completion



## Usage

You can try to search for completion words using the glob characters 
`*`, `?`, `[...]` while writing the command line like this:

```sh
bash$ opt -O1 foo.bc -*debug*[tab]
. . .
10 --debug-entry-values
11 --debug-info-correlate
12 --debug-pass-manager
13 --debug-pass-manager=
14 --debug-pass=
15 --debugger-tune=
. . .                       # "q"
[tab]                       # [tab] to exit to the prompt.

# After searching, you can use the numbers in the list to input completion words.
$ opt -O1 foo.bc 14[tab]

$ opt -O1 foo.bc --debug-pass=
```


## Installation

Copy contents of gcc-bash-completion.sh to ~/.bash_completion  
open new terminal and try auto completion !


> please leave an issue above if you have problems using this script.
