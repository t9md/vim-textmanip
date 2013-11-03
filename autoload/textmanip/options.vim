let s:options = {}
let s:options._data = {}
function! s:options.set(opt) "{{{1
  for [ name, val ] in items(a:opt)
    let self._data[name] = eval( '&' . name)
    let cmd = 'let &' . name . '=' . string(val)
    exe cmd
  endfor
endfunction
function! s:options.restore() "{{{1
  for [ name, val ] in items(self._data)
    let cmd = 'let &' . name . '=' . string(val)
    exe cmd
  endfor
  let self._data = {}
endfunction
function! textmanip#options#set(dict)
  call s:options.set(a:dict)
endfunction
function! textmanip#options#restore()
  call s:options.restore()
endfunction
" vim: foldmethod=marker
