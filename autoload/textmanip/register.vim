let s:r = {}

function! s:r.new() "{{{1
  let self._data = {}
  return copy(self)
endfunction

function! s:r.save(...) "{{{1
  for reg in a:000
    let self._data[reg] = {
          \ "content": getreg(reg, 1),
          \ "type":    getregtype(reg)
          \ }
  endfor
endfunction

function! s:r.restore() "{{{1
  for [reg, val] in items(self._data)
    call setreg(reg, val.content, val.type)
  endfor
  let self._data = {}
endfunction
"}}}

" API:
function! textmanip#register#new() "{{{1
  return s:r.new()
endfunction
" vim: foldmethod=marker
