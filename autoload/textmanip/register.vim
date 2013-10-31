" Private:
let s:register = {}
function! s:register.save(registers) "{{{
  let s:register._data = {}
  for r in a:registers
    let s:register._data[r] = { "content": getreg(r, 1), "type": getregtype(r) }
  endfor
  return deepcopy(self)
endfunction "}}}
function! s:register.restore() "{{{
  for [r, val] in items(self._data)
    call setreg(r, val.content, val.type)
  endfor
  let self._data = {}
endfunction "}}}

" Public:
function! textmanip#register#save(...) "{{{
  return s:register.save(a:000)
endfunction "}}}
function! textmanip#register#restore(...) "{{{
  call s:register.restore()
endfunction "}}}
" vim: foldmethod=marker
