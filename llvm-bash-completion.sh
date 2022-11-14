_init_comp_wordbreaks()
{
    if [[ $PROMPT_COMMAND == *";COMP_WORDBREAKS="* ]]; then
        [[ $PROMPT_COMMAND =~ ^:\ ([^;]+)\; ]]
        [[ ${BASH_REMATCH[1]} != "${COMP_WORDS[0]}" ]] && eval "${PROMPT_COMMAND%%$'\n'*}"
    fi
    if [[ $PROMPT_COMMAND != *";COMP_WORDBREAKS="* ]]; then
        PROMPT_COMMAND=": ${COMP_WORDS[0]};COMP_WORDBREAKS=${COMP_WORDBREAKS@Q};\
        "$'PROMPT_COMMAND=${PROMPT_COMMAND#*$\'\\n\'}\n'$PROMPT_COMMAND
    fi
}
_llvm_bind() { bind '"\011": complete' ;}
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
    if [[ -z $COMPREPLY ]]; then
        words=$( <<< $words sed -E 's/^[[:blank:]]+|[[:blank:]]+$//g' )
        IFS=$'\n' COMPREPLY=($(compgen -W "$words" -- "$cur"))
    fi
    [[ ${COMPREPLY: -1} == "=" ]] && compopt -o nospace
}
_llvm_option_list()
{
    <<< $help sed -En '/^[ ]{,10}-/{ s/, -/\a-/g;
    tR; :R s/^[ ]{,10}(-[[:alnum:]-]+\[?=?)[^\a]*/\1\n/; TZ;
    s/(\a(-[[:alnum:]-]+\[?=?)[^\a]*)/\2\n/g; s/[[\a]|\n[^\n]*$//g; p; :Z }'
}
_llvm_search()
{
    local -A aar; IFS=$'\n'; echo
    words=$( _llvm_option_list )
    for v in $words; do 
        let aar[$v]++
        if [[ $v == $cur && ${aar[$v]} -eq 1 ]]; then
            echo -e "\\e[36m$v\\e[0m"
        fi
    done | less -FRSXi
    IFS=$'\n' COMPREPLY=( "${cur_o%%[[*?]*}" )
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

    help=$({ $cmd --help-hidden || $cmd --help ;} 2>&1 )

    if [[ $cur == -*[[*?]* ]]; then
        _llvm_search

    elif [[ $cur == -* ]]; then
        if [[ $cmd == llvm-c-test ]]; then
            words=$( $cmd |& sed -E 's/ (-[[:alnum:]-]+)|./\1/g;')
        else
            words=$( _llvm_option_list )
        fi
    
    elif [[ $cmd == opt && $prev == --passes ]]; then
        words=$(opt --print-passes | sed -E '/^[^ ].+:$/d')

    elif [[ $prev == -* || "," == @($cur_o|$prev_o) ]]; then
        [[ $prev == -* ]] && args=$prev || args=$preo
        words=$(<<< $help sed -En '/'"$args"'/{ :X n; s/^[ ]{,10}=([^ ]+).*/\1/p; tX; Q}')
        if [[ -z $words ]]; then
            words=$(<<< $help sed -En 's/.* '"$prev"'=\[([^]]+)].*/\1/; tX; b; :X s/[,|]/\n/g; p; Q')
        fi
    fi

    _llvm_footer
}
_llvm_cov() 
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
        esac
        COMPREPLY=($(compgen -W "$words" -- "$cur"))
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
        words=$(<<< $help sed -En '/'"$args"'/{ :X n; s/^[ ]{,10}=([^ ]+).*/\1/p; tX}')
    fi

    _llvm_footer
}

complete -o default -o bashdefault -F _llvm \
    llc lli opt bugpoint dsymutil \
    obj2yaml yaml2obj sanstats verify-uselistorder \
    llvm-addr2line llvm-ar llvm-as llvm-bcanalyzer llvm-c-test llvm-cat llvm-cfi-verify \
    llvm-config llvm-cxxfilt llvm-dis llvm-dlltool llvm-dwarfdump \
    llvm-exegesis llvm-extract llvm-link llvm-lto llvm-mc llvm-mca \
    llvm-modextract llvm-nm llvm-objcopy llvm-objdump llvm-opt-report \
    llvm-ranlib llvm-readelf llvm-readobj llvm-rtdyld llvm-size llvm-split \
    llvm-stress llvm-strings llvm-strip llvm-symbolizer llvm-tblgen \
    llvm-undname llvm-xray ld.lld wasm-ld clang-format clang-format-diff \
    clang-cpp clangd

complete -o default -o bashdefault -F _llvm_cov llvm-cov llvm-lto2 llvm-pdbutil \
    llvm-profdata
