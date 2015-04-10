function! s:SID() "{{{1
  let fullname = expand("<sfile>")
  return matchstr(fullname, '<SNR>\d\+_')
endfunction
"}}}
let s:sid = s:SID()


function! s:_opposite_init()
  let data = [
      \   [ 'U', 'D' ],
      \   [ 'L', 'R' ],
      \   [ 'T', 'B' ],
      \   [ '-', '+' ],
      \   [ '>', '<' ],
      \   [ '^', 'V' ],
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
endfunction
let s:opposite_data = s:_opposite_init()

function! s:opposite(char)
  return get(s:opposite_data, a:char)
endfunction
"}}}

let s:functions = [
      \ 'opposite',
      \ ]

let s:u = {}
function! s:u.init() "{{{1
  let self.functions = {}
  for fname in s:functions
    let self.functions[fname] = function(s:sid . fname)
  endfor
endfunction
"}}}
call s:u.init()

" API:
function! textmanip#util#get() "{{{1
  return s:u.functions
endfunction
"}}}

" vim: foldmethod=marker
