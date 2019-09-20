let s:Options = {}

function! s:Options.new() "{{{1
  let self._opts = {}
  return copy(self)
endfunction 

function! s:Options.replace(opts) "{{{1
  let curbuf = fnameescape(bufname(''))
  for [name, val] in items(a:opts)
    let self._opts[name] = getbufvar(curbuf, name)
    call setbufvar(curbuf, name, val)
  endfor
  return self
endfunction

function! s:Options.restore() "{{{1
  for [name, val] in items(self._opts)
    call setbufvar(fnameescape(bufname('')), name, val)
  endfor
  let self._opts = {}
  return self
endfunction
"}}}

" Api:
function! textmanip#options#replace(...) "{{{1
  let opts = s:Options.new()
  return call(opts.replace, a:000, opts)
endfunction
"}}}
" vim: foldmethod=marker
