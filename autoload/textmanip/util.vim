function! s:SID() "{{{1
  let fullname = expand("<sfile>")
  return matchstr(fullname, '<SNR>\d\+_')
endfunction
"}}}
let s:sid = s:SID()

function! s:_opposite_init() "{{{1
  let data = [
      \   [ '>', '<' ],
      \   [ '^', 'v' ],
      \ ]

  let R = {}
  for [ v1, v2 ] in data
    let R[v1] = v2
    let R[v2] = v1
    if v1 =~# '\u'
      let _v1 = tolower(v1)
      let _v2 = tolower(v2)
      let R[_v1] = _v2
      let R[_v2] = _v1
    endif
  endfor
  return R
endfunction "}}}
let s:opposite_data = s:_opposite_init()

function! s:opposite(char) "{{{1
  return get(s:opposite_data, a:char)
endfunction

function! s:toward(dir) "{{{1
  return
        \ a:dir =~#  '\^\|v' ? '^v' :
        \ a:dir =~#   '>\|<' ? '<>' : throw
endfunction

function! s:template(string, vars) "{{{1
  let pattern = '\v(' . join(keys(a:vars), '|') . ')'
  return substitute(a:string, pattern,'\=a:vars[submatch(1)]', 'g')
endfunction

function! s:define_type_checker() "{{{1
  " dynamically define s:isNumber(v)  etc..
  let types = {
        \ "Number":     0,
        \ "String":     1,
        \ "Funcref":    2,
        \ "List":       3,
        \ "Dictionary": 4,
        \ "Float":      5,
        \ }

  for [type, number] in items(types)
    let s = ''
    let s .= 'function! s:is' . type . '(v)' . "\n"
    let s .= '  return type(a:v) ==# ' . number . "\n"
    let s .= 'endfunction' . "\n"
    execute s
  endfor
endfunction
"}}}
call s:define_type_checker()
unlet! s:define_type_checker

function! s:toList(arg)
  return s:isList(a:arg) ? a:arg : [a:arg]
endfunction

let s:functions = [
      \ 'opposite',
      \ 'toward',
      \ "isNumber",
      \ "isString",
      \ "isFuncref",
      \ "isList",
      \ "isDictionary",
      \ "isFloat",
      \ "toList",
      \ "template",
      \ ]

let s:Util = {}
function! s:Util.init() "{{{1
  let self.functions = {}
  for fname in s:functions
    let self.functions[fname] = function(s:sid . fname)
  endfor
endfunction
"}}}
call s:Util.init()

" API:
function! textmanip#util#get() "{{{1
  return s:Util.functions
endfunction
"}}}

" vim: foldmethod=marker
