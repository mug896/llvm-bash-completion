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
    [[ ${COMP_LINE:COMP_POINT-1:1} = " " || $COMP_WORDBREAKS == *$cur* ]] && cur=""
    prev=${COMP_WORDS[COMP_CWORD-1]} prev_o=$prev
    [[ $prev == [,=] ]] && prev=${COMP_WORDS[COMP_CWORD-2]}
    if (( COMP_CWORD > 4 )); then
        [[ $cur_o == [,=] ]] && prev2=${COMP_WORDS[COMP_CWORD-3]} || prev2=${COMP_WORDS[COMP_CWORD-4]}
    fi
    comp_line2=${COMP_LINE:0:$COMP_POINT}
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
    if [[ $cmd == llvm-c-test ]]; then
        $cmd --help |& sed -E 's/ (--?[[:alnum:]][[:alnum:]_-]*)|./\1\n/g;'
    elif [[ $cmd == c-index-test ]]; then
        $cmd --help |& sed -En '/c-index-test -/{ s/[^[:alnum:]](-[[:alnum:]-]+=?)|./\1\n/g; p }'
    else
        <<< $help sed -En '/^[ ]{,10}--?[[:alnum:]]/{ s/, -/\a-/g;
        tR; :R s/^[ ]{,10}(--?[[:alnum:]][[:alnum:]_+-]*\[?=?)[^\a]*/\1\n/; TZ;
        s/(\a(--?[[:alnum:]][[:alnum:]_+-]*\[?=?)[^\a]*)/\2\n/g; s/[[\a]|\n[^\n]*$//g; p; :Z }'
    fi
}
_llvm_bind() { bind '"\011": complete' ;}
_llvm_search()
{
    words=$( _llvm_option_list | sed -E 's/^[ \t]+|[ \t]+$//g' | sort -u )
    local res count opt
    local IFS=$'\n'; echo
    for v in $words; do
        if [[ $v == $cur ]]; then
            res+=$'\e[36m'"$v"$'\e[0m\n'
            let count++
        fi
    done
    (( count >= LINES )) && opt="+Gg"
    less -FRSXiN $opt <<< ${res%$'\n'}
    COMPREPLY=( "${comp_line2##*[ ,]}" )
    bind -x '"\011": _llvm_bind'
}
_llvm() 
{
    # It is recommended that all completion functions start with _init_comp_wordbreaks,
    # regardless of whether you change the COMP_WORDBREAKS variable afterward.
    _init_comp_wordbreaks
    COMP_WORDBREAKS=${COMP_WORDBREAKS//:/}
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","

    local IFS=$' \t\n' cur cur_o prev prev_o prev2 preo
    local cmd=$1 cmd2 words comp_line2 help args arr i v
    _llvm_header

    help=$({ $cmd --help-hidden || $cmd --help || $cmd -help ;} 2>&1 )

    if [[ $cur == -*[[*?]* ]]; then
        _llvm_search

    elif [[ $cur == -* ]]; then
        words=$( _llvm_option_list )
    
    elif [[ $cmd == opt && $prev == --passes ]]; then
        words=$(opt --print-passes | sed -E '/^[^ ].+:$/d')

    elif [[ $prev == -* || "," == @($cur_o|$prev_o) ]]; then
        [[ $prev == -* ]] && args=$prev || args=$preo
        words=$(<<< $help sed -En '/'"$args"'/{ :X n; s/^[ ]{,10}=([^ ]+).*/\1/p; tX; Q}')
        if [[ -z $words ]]; then
            words=$(<<< $help sed -En 's/.* '"$prev"'[ =]\[([^]]+)].*/\1/; tX; b; :X s/[,|]/\n/g; p; Q')
        fi
    fi

    _llvm_footer
}
_llvm_subcommand() 
{
    local IFS=$' \t\n' cur cur_o prev prev_o prev2 preo
    local cmd=$1 cmd2 words comp_line2 help args arr i v
    _llvm_header

    if (( COMP_CWORD == 1 )); then
        help=$( $cmd --help 2>&1 )
        case $cmd in
            llvm-cov)
                words=$(<<< $help sed -En '/^Subcommands:/,/\a/{ //d; s/:.*$//; p }') ;;
            llvm-lto2)
                words=$(<<< $help sed -En 's/^Available (sub)?commands: //; s/[ ,]+/\n/; p') ;;
            llvm-pdbutil)
                words=$(<<< $help sed -En '/SUBCOMMANDS:/,/OPTIONS:/{ //d; s/^ *([^ ]+) *- .*$/\1/p }') ;;
            llvm-profdata)
                words=$(<<< $help sed -En 's/Available (sub)?commands: //; tX b; :X s/[ ,]+/\n/g; p') ;;
            llvm-jitlink-executor)
                words=$'filedescs=\nlisten=' ;;
            diagtool)
                words=$(<<< $help sed -E '1d; s/^\s*([^ ]+).*/\1/') ;;
            hmaptool)
                words=$(<<< $help sed -En '/^Available commands:/,/\a/{ s/ -.*$//p }') ;;
        esac
        _llvm_footer
        return
    fi
    cmd2=${COMP_WORDS[1]}
    help=$({ $cmd $cmd2 --help-hidden || $cmd $cmd2 --help ;} 2>&1 )

    if [[ $cur == -*[[*?]* ]]; then
        _llvm_search

    elif [[ $cur == -* ]]; then
        words=$( _llvm_option_list )
    
    elif [[ $prev == -* || "," == @($cur_o|$prev_o) ]]; then
        [[ $prev == -* ]] && args=$prev || args=$preo
        words=$(<<< $help sed -En '/'"$args"'/{ :X n; s/^[ ]{,10}=([^ ]+).*/\1/p; tX; Q}')
    fi

    _llvm_footer
}

complete -o default -o bashdefault -F _llvm \
    llc lli opt lldb bugpoint dsymutil \
    obj2yaml yaml2obj sanstats verify-uselistorder \
    llvm-addr2line llvm-ar llvm-as llvm-bcanalyzer llvm-c-test llvm-cat llvm-cfi-verify \
    llvm-config llvm-cxxfilt llvm-dis llvm-dlltool llvm-dwarfdump \
    llvm-exegesis llvm-extract llvm-link llvm-lto llvm-mc llvm-mca \
    llvm-modextract llvm-nm llvm-objcopy llvm-objdump llvm-opt-report \
    llvm-ranlib llvm-readelf llvm-readobj llvm-rtdyld llvm-size llvm-split \
    llvm-stress llvm-strings llvm-strip llvm-symbolizer llvm-tblgen \
    llvm-undname llvm-xray ld.lld wasm-ld clang-format clang-format-diff clangd \
    clang-cpp clang-tidy clang-tidy-diff run-clang-tidy llvm-debuginfod \
    llvm-debuginfod-find llvm-ifs llvm-install-name-tool llvm-jitlink \
    llvm-libtool-darwin llvm-lipo llvm-otool llvm-tli-checker llvm-windres \
    llvm-cxxmap llvm-dwarfutil llvm-gsymutil llvm-dwp llvm-reduce llvm-diff \
    llvm-remark-size-diff llvm-profgen llvm-sim clang-apply-replacements \
    clang-change-namespace clang-check clang-doc clang-cl clang-extdef-mapping \
    clang-include-fixer clang-linker-wrapper clang-move clang-nvlink-wrapper \
    clang-offload-bundler clang-offload-packager clang-offload-wrapper clang-pseudo \
    clang-query clang-refactor clang-rename clang-reorder-fields clang-repl \
    clang-scan-deps  analyze-build c-index-test find-all-symbols hwasan_symbolize \
    intercept-build modularize pp-trace sancov scan-build scan-build-py scan-view

complete -o default -o bashdefault -F _llvm_subcommand \
    llvm-cov llvm-lto2 llvm-pdbutil llvm-profdata llvm-jitlink-executor \
    diagtool hmaptool
