# LLVM Bash Completion

This is a bash autocomplete function for LLVM 19.1.0.  
You can download pre-compiled LLVM binary packages from the URL below.  

https://github.com/llvm/llvm-project/releases/tag/llvmorg-19.1.0


Autocomplete functions for `clang` `clang++` commands can be downloaded separately
from this url.  

https://github.com/mug896/clang-bash-completion



## Usage


This script requires the external command 'fsf' to use.  
Therefore, first install the 'fsf' command as follows.  

```sh
bash$ sudo apt install fsf
```

You can try to search for completion words using the glob characters 
`*`, `?`, `[...]` while writing the command line like this:

```sh
bash$ opt -O1 foo.bc -*debug*[tab]

bash$ opt -O1 foo.bc -*[tab]
```


## Installation

Copy contents of gcc-bash-completion.sh to ~/.bash_completion  
open new terminal and try auto completion !


