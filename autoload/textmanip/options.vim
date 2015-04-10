let s:options = {}

function! s:options.new() "{{{1
  let self._opts = {}
  return copy(self)
endfunction 

function! s:options.replace(opts) "{{{1
  let curbuf = bufname('')
  for [name, val] in items(a:opts)
    let self._opts[name] = getbufvar(curbuf, name)
    call setbufvar(curbuf, name, val)
  endfor
endfunction

function! s:options.restore() "{{{1
  for [name, val] in items(self._opts)
    call setbufvar(bufname(''), name, val)
  endfor
  let self._opts = {}
endfunction
"}}}

" Api:
function! textmanip#options#new() "{{{1
  return s:options.new()
endfunction
"}}}
" vim: foldmethod=marker
