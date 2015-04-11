let s:default = {
      \ "enable_mappings" : 0,
      \ "startup_mode"    : "insert",
      \ "move_ignore_shiftwidth" : 0,
      \ "move_shiftwidth" : 1,
      \ }

" Config:
let s:Config = {}

function! s:Config.user() "{{{1
  let R = {}
  let prefix = 'textmanip_'
  for [name, default] in items(s:default)
    let R[name] = get(g:, prefix . name, default)
    unlet default
  endfor
  return R
endfunction

function! s:Config.get() "{{{1
  return self.user()
endfunction
"}}}

" API:
function! textmanip#config#get() "{{{1
  return s:Config.get()
endfunction
"}}}

" vim: fdm=marker:
