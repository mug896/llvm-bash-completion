_init_comp_wordbreaks()
{
    if [[ $PROMPT_COMMAND =~ ^:[^\;]+\;COMP_WORDBREAKS ]]; then
        [[ $PROMPT_COMMAND =~ ^:\ ([^;]+)\; ]]
        [[ ${BASH_REMATCH[1]} != "${COMP_WORDS[0]}" ]] && eval "${PROMPT_COMMAND%%$'\n'*}"
    fi
    if ! [[ $PROMPT_COMMAND =~ ^:[^\;]+\;COMP_WORDBREAKS ]]; then
        PROMPT_COMMAND=": ${COMP_WORDS[0]};COMP_WORDBREAKS=${COMP_WORDBREAKS@Q};\
        "$'PROMPT_COMMAND=${PROMPT_COMMAND#*$\'\\n\'}\n'$PROMPT_COMMAND
    fi
}
_llvm_header() 
{
    cur=${COMP_WORDS[COMP_CWORD]} cur_o=$cur
    comp_line2=${COMP_LINE:0:$COMP_POINT}
    [[ ${comp_line2: -1} = " " || $COMP_WORDBREAKS == *"$cur"* ]] && cur=""
    prev=${COMP_WORDS[COMP_CWORD-1]} prev_o=$prev
    [[ $prev == [,=] ]] && prev=${COMP_WORDS[COMP_CWORD-2]}
    if (( COMP_CWORD > 4 )); then
        [[ $cur_o == [,=] ]] && prev2=${COMP_WORDS[COMP_CWORD-3]} || prev2=${COMP_WORDS[COMP_CWORD-4]}
    fi
    eval arr=( $comp_line2 ) 2> /dev/null
    for (( i = ${#arr[@]} - 1; i > 0; i-- )); do
        if [[ ${arr[i]} == -* ]]; then
            preo=${arr[i]%%[^[:alnum:]_-]*}
            [[ ($preo == ${comp_line2##*[ ]}) && ($preo == $cur_o) ]] && preo=""
            break
        fi
    done
}
_llvm_footer()
{
    if ! declare -p COMPREPLY &> /dev/null; then
        words=$( <<< $words sed -E 's/^[ \t]+|[ \t]+$//g' )
        IFS=$'\n' COMPREPLY=($(compgen -W "$words" -- "$cur"))
    fi
    [[ ${COMPREPLY: -1} == "=" ]] && compopt -o nospace
}
_llvm_option_list()
{
    if [[ $cmd == @(llvm-c-test|f18-parse-demo) ]]; then
        <<< $help sed -E 's/ (--?[[:alnum:]][[:alnum:]_-]*)|./\1\n/g;'
        if [[ $cmd == f18-parse-demo ]]; then
            echo -e "-fbackslash\n-fno-backslash\n-Mbackslash\n-Mno-backslash"
        fi
    elif [[ $cmd == lldb-server && $cmd2 == @(p|platform) ]]; then
        <<< $help sed -E 's/[[ ](--?[[:alnum:]][[:alnum:]_-]*)|./\1\n/g;'
    elif [[ $cmd == c-index-test ]]; then
        <<< $help sed -En '/c-index-test -/{ s/[^[:alnum:]](-[[:alnum:]-]+=?)|./\1\n/g; p }'
    else
        <<< $help sed -En '/^[ ]{,10}--?[[:alnum:]]/{ s/, -/\a-/g;
        tR; :R s/^[ ]{,10}(--?[[:alnum:]][[:alnum:]_+-]*\[?=?)[^\a]*/\1\n/; T;
        s/(\a(--?[[:alnum:]][[:alnum:]_+-]*\[?=?)[^\a]*)/\2\n/g; s/[[\a]|\n[^\n]*$//g; p }'
    fi
}
_llvm_option_list2()
{
    <<< $help sed -En 's#^[ ]{,10}(/[[:alnum:]?][[:alnum:]_:-]*).*#\1\n#p'
}
_llvm_search()
{
    local res IFS=$'\n'
    words=$( _llvm_option_list | sed -E 's/^[ \t]+|[ \t]+$//g' | sort -u )
    for v in $words; do
        if [[ $v == $cur ]]; then
            res+=$v$'\n'
        fi
    done 
    words=$( <<< $res fzf -m --info=inline)
    COMPREPLY=( "${words//$'\n'/ }" )
}
_llvm() 
{
    # It is recommended that all completion functions start with _init_comp_wordbreaks,
    # regardless of whether you change the COMP_WORDBREAKS variable afterward.
    _init_comp_wordbreaks
    COMP_WORDBREAKS=${COMP_WORDBREAKS//:/}
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","

    local IFS=$' \t\n' cur cur_o prev prev_o prev2 preo
    local cmd=${1##*/} cmd1=$1 cmd2 words comp_line2 help args arr i v
    _llvm_header
    if [[ $cmd == @(f18-parse-demo|lldb-dap|llvm-lib|llvm-ml) ]]; then
        help=$( $cmd1 -help 2>&1 )
    elif [[ $cmd == llvm-rc ]]; then
        help=$( $cmd1 /? 2>&1 )
    else
        help=$({ $cmd1 --help-hidden || $cmd1 --help || $cmd1 -help ;} 2>&1 )
    fi

    if [[ $cur == -*[[*?]* ]]; then
        _llvm_search

    elif [[ $cur == -* ]]; then
        words=$( _llvm_option_list )
    
    elif [[ $cur == /* ]]; then
        words=$( _llvm_option_list2 )
    
    elif [[ $cmd == opt && $prev == --passes ]]; then
        words=$(opt --print-passes | sed -E '/^[^ ].+:$/d')

    elif [[ $prev == -* || "," == @($cur_o|$prev_o) ]]; then
        [[ $prev == -* ]] && args=$prev || args=$preo
        words=$(<<< $help sed -En '/^[ ]*'"$args"'[ =]/{ 
            :X n; /^[ ]{10}|^[ ]*'"$args"'[ =]/bX; s/^[ ]{,10}=([^ ]+).*/\1/p; tX; Q }')
        if [[ -z $words ]]; then
            words=$(<<< $help sed -En 's/.* '"$prev"'[ =]\[([^]]+)].*/\1/; T; s/[,|]/\n/g; p; Q')
        fi
    fi

    _llvm_footer
}
_llvm_subcommand() 
{
    local IFS=$' \t\n' cur cur_o prev prev_o prev2 preo
    local cmd=${1##*/} cmd1=$1 cmd2 words comp_line2 help args arr i v
    _llvm_header

    if [[ $COMP_CWORD == 1 && $cur != -* ]]; then
        help=$( $cmd1 --help 2>&1 )
        case $cmd in
            llvm-cov)
                words=$(<<< $help sed -En '/^Subcommands:/,/\a/{ //d; s/:.*$//; p }') ;;
            llvm-lto2)
                words=$(<<< $help sed -En 's/^Available (sub)?commands: //; s/[ ,]+/\n/; p') ;;
            clang-refactor | llvm-pdbutil | llvm-profdata | llvm-remarkutil | llvm-xray)
                words=$(<<< $help sed -En '/SUBCOMMANDS:/,/OPTIONS:/{ //d; s/^ *([^ ]+) *- .*$/\1/p }') ;;
            diagtool)
                words=$(<<< $help sed -E '1d; s/^\s*([^ ]+).*/\1/') ;;
            hmaptool)
                words=$(<<< $help sed -En '/^Available commands:/,/\a/{ s/ -.*$//p }') ;;
            lldb-server)
                words=$'version\ngdbserver\ng\nplatform\np' ;;
        esac
        _llvm_footer
        return
    fi
    [[ ${COMP_WORDS[1]} != -* ]] && cmd2=${COMP_WORDS[1]}
    if [[ $cmd == lldb-server ]]; then
        help=$( $cmd1 $cmd2 --help 2>&1 )
    else
        help=$({ $cmd1 $cmd2 --help-hidden || $cmd1 $cmd2 --help ;} 2>&1 )
    fi

    if [[ $cur == -*[[*?]* ]]; then
        _llvm_search

    elif [[ $cur == -* ]]; then
        words=$( _llvm_option_list )

    elif [[ $prev == -* || "," == @($cur_o|$prev_o) ]]; then
        [[ $prev == -* ]] && args=$prev || args=$preo
        words=$(<<< $help sed -En '/^[ ]*'"$args"'[ =]/{ 
            :X n; /^[ ]{10}|^[ ]*'"$args"'[ =]/bX; s/^[ ]{,10}=([^ ]+).*/\1/p; tX; Q}')
    fi

    _llvm_footer
}

complete -o default -o bashdefault -F _llvm \
amdgpu-arch analyze-build bbc bugpoint c-index-test \
clang-apply-replacements clang-change-namespace clang-check clang-cl \
clang-cpp clang-doc clang-extdef-mapping clang-format clang-include-cleaner \
clang-include-fixer clang-installapi clang-linker-wrapper clang-move \
clang-nvlink-wrapper clang-offload-bundler clang-offload-packager clang-pseudo \
clang-query clang-refactor clang-rename clang-reorder-fields clang-repl \
clang-scan-deps clang-tblgen clang-tidy clangd dsymutil f18-parse-demo \
find-all-symbols fir-opt flang-new git-clang-format intercept-build \
ld.lld ld64.lld llc lld-link lldb lldb-dap lldb-instr \
lli llvm-addr2line llvm-ar llvm-as llvm-bcanalyzer llvm-bitcode-strip llvm-bolt \
llvm-bolt-heatmap llvm-boltdiff llvm-c-test llvm-cat llvm-cfi-verify llvm-config \
llvm-cvtres llvm-cxxdump llvm-cxxfilt llvm-cxxmap llvm-debuginfo-analyzer \
llvm-debuginfod llvm-debuginfod-find llvm-diff llvm-dis llvm-dlltool llvm-dwarfdump \
llvm-dwarfutil llvm-dwp llvm-exegesis llvm-extract llvm-gsymutil llvm-ifs \
llvm-install-name-tool llvm-jitlink llvm-lib llvm-libtool-darwin llvm-link llvm-lipo \
llvm-lto llvm-mc llvm-mca llvm-ml llvm-modextract llvm-mt llvm-nm \
llvm-objcopy llvm-objdump llvm-opt-report llvm-otool \
llvm-profgen llvm-ranlib llvm-rc llvm-readelf llvm-readobj llvm-readtapi llvm-reduce \
llvm-rtdyld llvm-sim llvm-size llvm-split llvm-stress llvm-strings \
llvm-strip llvm-symbolizer llvm-tblgen llvm-tli-checker llvm-undname llvm-windres \
merge-fdata mlir-cpu-runner mlir-linalg-ods-yaml-gen \
mlir-lsp-server mlir-minimal-opt mlir-minimal-opt-canonicalize mlir-opt mlir-pdll \
mlir-pdll-lsp-server mlir-query mlir-reduce mlir-tblgen mlir-transform-opt \
mlir-translate modularize nvptx-arch opt perf2bolt pp-trace reduce-chunk-list \
run-clang-tidy sancov sanstats scan-build scan-build-py scan-view tblgen-lsp-server \
tblgen-to-irdl tco verify-uselistorder wasm-ld

complete -o default -o bashdefault -F _llvm_subcommand \
    clang-refactor llvm-cov llvm-lto2 llvm-pdbutil llvm-profdata diagtool hmaptool \
    lldb-server llvm-remarkutil llvm-xray




