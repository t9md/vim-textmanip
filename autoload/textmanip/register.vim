let s:register = {}
function! s:register.save(registers) "{{{1
  let s:register._data = {}
  for r in a:registers
    let s:register._data[r] = { "content": getreg(r, 1), "type": getregtype(r) }
  endfor
  return deepcopy(self)
endfunction

function! s:register.restore() "{{{1
  for [r, val] in items(self._data)
    call setreg(r, val.content, val.type)
  endfor
  let self._data = {}
endfunction

function! textmanip#register#save(...) "{{{1
  return s:register.save(a:000)
endfunction

function! textmanip#register#restore(...) "{{{1
  call s:register.restore()
endfunction
" vim: foldmethod=marker
