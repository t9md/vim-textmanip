let s:options = {}

function! s:options.set(opts) "{{{1
  let self._opts = {}

  let curbuf = bufname('')
  for [var, val] in items(a:opts)
    let self._opts[var] = getbufvar(curbuf, var)
    call setbufvar(curbuf, var, val)
  endfor
endfunction

function! s:options.restore() "{{{1
  for [ var, val ] in items(self._opts)
    call setbufvar(bufname(''), var, val)
  endfor
endfunction

function! textmanip#options#set(opts) "{{{1
  call s:options.set(a:opts)
endfunction

function! textmanip#options#restore() "{{{1
  call s:options.restore()
endfunction
"}}}
" vim: foldmethod=marker
