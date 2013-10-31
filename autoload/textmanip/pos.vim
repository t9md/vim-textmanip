" POS:
let s:pos = {}
function! s:pos.new(pos) "{{{
  " pos = [line, col]
  let self._data = a:pos
  return deepcopy(self)
endfunction "}}}
function! s:pos.pos() "{{{
  return self._data
endfunction "}}}
function! s:pos.line() "{{{
  return self._data[0]
endfunction "}}}
function! s:pos.col() "{{{
  return self._data[1]
endfunction "}}}

function! s:pos.move(line_ope, col_ope) "{{{
  let self._data[0] = eval(self._data[0] . a:line_ope)
  let self._data[1] = eval(self._data[1] . a:col_ope)
  return self              
endfunction "}}}           
          
function! s:pos.dump() "{{{
  return self._data
endfunction "}}}
          
" Public: 
function! textmanip#pos#new(pos)
  " pos = [line, col]
  return s:pos.new(a:pos)
endfunction
" vim: foldmethod=marker
