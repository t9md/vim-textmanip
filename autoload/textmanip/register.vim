let s:Register = {}

function! s:Register.new() "{{{1
  let self._data = {}
  return copy(self)
endfunction

function! s:Register.save(...) "{{{1
  for reg in a:000
    let self._data[reg] = {
          \ "content": getreg(reg, 1),
          \ "type":    getregtype(reg)
          \ }
  endfor
  return self
endfunction

function! s:Register.restore() "{{{1
  for [reg, val] in items(self._data)
    call setreg(reg, val.content, val.type)
  endfor
  let self._data = {}
endfunction
"}}}

" API:
function! textmanip#register#save(...) "{{{1
  let reg = s:Register.new()
  return call(reg.save, a:000, reg)
endfunction
" vim: foldmethod=marker
