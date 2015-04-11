let s:Options = {}

function! s:Options.new() "{{{1
  let self._opts = {}
  return copy(self)
endfunction 

function! s:Options.replace(opts) "{{{1
  let curbuf = bufname('')
  for [name, val] in items(a:opts)
    let self._opts[name] = getbufvar(curbuf, name)
    call setbufvar(curbuf, name, val)
  endfor
endfunction

function! s:Options.restore() "{{{1
  for [name, val] in items(self._opts)
    call setbufvar(bufname(''), name, val)
  endfor
  let self._opts = {}
endfunction
"}}}

" Api:
function! textmanip#options#new() "{{{1
  return s:Options.new()
endfunction
"}}}
" vim: foldmethod=marker
