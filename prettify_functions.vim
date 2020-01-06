" This script can be used to prettify functions in a file.
"
" For instance, it will turn:
"   f(a=a, {b:c})
" into:
"   f(
"     a=a,
"     {
"       b:c
"     }
"   )
"
" The script main entry point is PrettifyFunctions(). It can be used with a range to only prettify
" functions in a selection.
"
" EXAMPLE USAGE
" This adds a mapper to prettify all functions in selections
" vnoremap <leader>t :call PrettifyFunctions()<cr>
" This adds a mapper to prettify all functions in a file
" nnoremap <leader>t :%call PrettifyFunctions()<cr>



" fPattern defines a function as one of more keyword (see iskeyword vim help) characters followed
" with opening and closing parenthesis with more than one non space character in between 
"
" FIXME: this is probably not good enough (it will match regexes...)
let s:fPattern = '\v(\k{-1,})(\(.+\))'

" special characters
let s:CLOSING = [")", "}"]
let s:OPENING = ["(", "{"]
let s:IGNORE = ["'", "\""]

" Dirty hack to track the last line to do the search on. This is necessary, as the base selection
" will not be valid once functions start to be prettified (as this will add more lines)
let s:stopLine = 0

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
"   The formatted function as a string, contaning end-of-lines
function! s:prettifyFunction(f, args, i)
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
      let s:stopLine += 1
      continue
    endif

    if index(s:OPENING, c) >= 0
      let indent += 2
      let out .= c . "\n" . s:spaces(indent)
      let s:stopLine += 1
      continue
    endif

    if index(s:CLOSING, c) >= 0
      let indent -= 2
      let out .= "\n" . s:spaces(indent) . c
      let s:stopLine += 1
      continue
    endif

    let out .= c
  endfor
  return out
endfunction

" PrettifyFunctions will prettify all functions (see s:fPattern for what is considered a function)
" found in the selection range. This only supports line selections, and will treat other modes of
" selection as lines (start and end line of the block for blockwise, and current line only for
" characterwise selection).
function! PrettifyFunctions()
  " Go to selection start, at column 0
  exec "normal " . a:firstline . "G"
  " Set stopLine marker to selection end
  let s:stopLine = a:lastline
  " Match starting at cursor position, to handle the case when the pattern starts at column 0
  let flags = "c"
  while search(s:fPattern, flags, s:stopLine) > 0
    let base = indent(line('.'))
    execute 's/' . s:fPattern .  '/\=s:prettifyFunction(submatch(1), submatch(2), base)/g'
  endwhile
endfunction

