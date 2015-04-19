let s:Register = {}

function! s:Register.use(reg) "{{{1
  let self.name    = a:reg
  let self.content = []
  let self.type    = ''
  let self._modified = 0
  let self._org      = {
        \ "content": getreg(a:reg, 1),
        \ "type":    getregtype(a:reg)
        \ }
  return copy(self)
endfunction

function! s:Register.yank() "{{{1
  silent execute 'normal! "' . self.name . 'y'
  let self.type    = getregtype(self.name)
  let self.content = split(getreg(self.name), "\n", 1)
  if self.type ==# 'V'
    call remove(self.content, -1)
  endif
  return self
endfunction

function! s:Register.paste() "{{{1
  call setreg(self.name, self.content, self.type)
  silent execute 'normal! "' . self.name . 'p'
endfunction

function! s:Register.restore() "{{{1
  if self._modified
    call setreg(self.name, self._org.content, self._org.type)
  endif
  let self._org = {}
endfunction
"}}}

" API:
function! textmanip#register#use(...) "{{{1
  return call(s:Register.use, a:000, s:Register)
endfunction
" vim: foldmethod=marker
