" define function as one of more non space characters followed with opening and closing parenthesis
" with more than one argument
" NOTE: this pattern is probably not good enough (it will match regexes...)
let s:fPattern = '\v(\S+)\((.+)\)'
function! TrimSpaces(_, str)
  return substitute(a:str, " ", "", "")
endfunction

" example pour mettre 4 espaces :call Format(repeat(" ", 4))
function! Format(sep)
  normal G$
  let flags = "w"
  while search(s:fPattern, flags) > 0
    let base = repeat(" ", indent(line('.')))
    let indent = base . a:sep
    " TODO this wont support , like in split=','
    let cmd = 's/' . s:fPattern . '/\=base.submatch(1)."(\n".indent.join(map(split(submatch(2),","),function("TrimSpaces")),",\n".indent)."\n)"'
    execute cmd
    " s/\v(\a+\=\a+%(,|\)))/\="\n".i.a:sep.substitute(submatch(1),')',"\r" . i . ")",'')/g
    let flags = "W"
  endwhile
endfunction
