" define function as one of more non space characters followed with opening and closing parenthesis
" with more than one argument
" NOTE: this pattern is probably not good enough (it will match regexes...)
" A function name can be made of:
"   - characters
"   - keywords (see iskeyword vim option)
let s:fPattern = '\v(\k{-1,})(\(.+\))'

" special characters
let s:CLOSING = [")", "}"]
let s:OPENING = ["(", "{"]
let s:IGNORE = ["'", "\""]

function! s:spaces(indent)
  return repeat(" ", a:indent)
endfunction

" prettifyFunction will replace a function with a properly indented version of itself.
" Example:
"   - f(a=a, {b:c}) will become
"   f(
"     a=a,
"     {
"       b:c
"     }
"   )
"
" for a list of characters triggering indentation, see s:OPENING and s:CLOSING.
" Of course, this does not perform any syntax checking, and results WILL be nonsense if the function
" is not correct.
"
" Args:
"   f (str): the function name
"   args (str): the arguments to this function as a string, including the parenthesis (in the
"   example above, args would be "(a=a, {b:c})"
"   i (int): the initial indentation level of the function (number of spaces from the left)
" Returns:
"   the properly formated function as a string
function! s:prettifyFunction(f, args, i)
  echom a:f
  echom a:args
  let indent = a:i
  let out = a:f
  let ignoreFlag = 0
  for c in split(a:args, '\zs')
    if index(s:IGNORE, c) >= 0
      if ignoreFlag ==# 1
        let ignoreFlag = 0
      else
        let ignoreFlag = 1
      endif
      let out .= c
      continue
    endif

    if ignoreFlag ==# 1
      let out .= c
      continue
    endif

    if c ==# ' '
      continue 
    endif

    if c ==# ','
      let out .= c . "\n" . s:spaces(indent)
      continue
    endif

    if index(s:OPENING, c) >= 0
      let indent += 2
      let out .= c . "\n" . s:spaces(indent)
      continue
    endif

    if index(s:CLOSING, c) >= 0
      let indent -= 2
      let out .= "\n" . s:spaces(indent) . c
      continue
    endif

    let out .= c
  endfor
  return out
endfunction

function! Format()
  normal G$
  let flags = "w"
  while search(s:fPattern, flags) > 0
    let base = indent(line('.'))
    let cmd = 's/' . s:fPattern .  '/\=Prettify(submatch(1), submatch(2), base)/g'
    execute cmd
    let flags = "W"
  endwhile
endfunction

" FormatFunctions will prettify all functions (see s:fPattern for what is considered a function)
" found in the selection range. This only supports line selections, and will treat other modes of
" selection as lines (start and end line of the block for blockwise, and current line only for
" characterwise selection).
"
function! FormatFunctions(_)
  echom "cc"
  exec "normal '<"
  let stopline = line("'>")
  " do not wrap at end of file
  " TODO: do we need this?
  echom stopline
  let flags = "Wc"
  while search(s:fPattern, flags, stopline) > 0
    echom "derp"
    let base = indent(line('.'))
    let cmd = 's/' . s:fPattern .  '/\=Prettify(submatch(1), submatch(2), base)/g'
    execute cmd
  endwhile
endfunction

vnoremap <leader>t :<c-u>call FormatFunctions(visualmode())<cr>
