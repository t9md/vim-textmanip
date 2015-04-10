let s:register = {}

function! s:register.new() "{{{1
  let self._data = {}
  return copy(self)
endfunction

function! s:register.save(...) "{{{1
  for reg in a:000
    let s:register._data[reg] = {
          \ "content": getreg(reg, 1),
          \ "type": getregtype(reg)
          \ }
  endfor
endfunction

function! s:register.restore() "{{{1
  for [reg, val] in items(self._data)
    call setreg(reg, val.content, val.type)
  endfor
  let self._data = {}
endfunction
"}}}

" API:
function! textmanip#register#new() "{{{1
  return s:register.new()
endfunction
" vim: foldmethod=marker
