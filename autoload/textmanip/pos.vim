let s:pos = {}

function! s:pos.new(pos) "{{{1
  " pos is result of `getpos()`

  " getpos() return [bufnum, lnum, col, off]
  " off is offset from actual col when virtual edit(ve) mode,
  " so, to respect ve position, we sum "col" + "off"

  let self.line = a:pos[1]
  let self.colm = a:pos[2] + a:pos[3]
  return copy(self)
endfunction

function! s:pos.pos() "{{{1
  return [self.line, self.colm]
endfunction

function! s:pos.move(line_ope, col_ope) "{{{1
  let self.line = eval(self.line . a:line_ope)
  let self.colm = eval(self.colm . a:col_ope)
  return self
endfunction

function! textmanip#pos#new(pos) "{{{1
  " pos = [line, col]
  return s:pos.new(a:pos)
endfunction
" vim: foldmethod=marker
