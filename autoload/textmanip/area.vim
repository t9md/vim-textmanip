" function! s:split(mode) "{{{
  " return split(a:mode, '.\zs')
" endfunction "}}}

" Private:
"         l_cut/add           r_cut/add
"                 |           |
"                 V           V        _.data idx
"                +-+---------+-+----      0
"   u_cut/add -> +-+         +-+   ^      |
"                |             |   |      |
"                |             |  height  |
"                |             |   |      |
"                +-+         +-+   V      |
"   d_cut/add -> +-+---------+-+ ---   len(_.data)
"                |             |
"                +<-- width -->+
let s:area = {}
function! s:area.new(data) "{{{
  let o = deepcopy(self)
  let o._data = a:data
  return o
endfunction "}}}
function! s:area.data() "{{{
  return self._data
endfunction "}}}
function! s:area.height() "{{{
  return len(self._data)
endfunction "}}}
function! s:area.width() "{{{
  " assume all data have same width
  return len(self._data[0])
endfunction "}}}
function! s:area.reset() "{{{
  let self._data = []
endfunction "}}}
function! s:area.dump() "{{{
  echo PP(self._data)
endfunction "}}}

function! s:area.u_add(val) "{{{
  let v = type(a:val) ==# 3 ? a:val : [a:val]
  let self._data = v + self._data
endfunction "}}}
function! s:area.d_add(val) "{{{
  let v = type(a:val) ==# 3 ? a:val : [a:val]
  let self._data = self._data + v
endfunction "}}}
function! s:area.r_add(val) "{{{
  if empty(self._data)
    let self._data = map(copy(a:val), 'v:val')
  else
    call map(self._data, 'v:val . a:val[v:key]')
  endif
endfunction "}}}
function! s:area.l_add(val) "{{{
  if empty(self._data)
    let self._data = map(copy(a:val), 'v:val')
  else
    cal map(self._data, 'a:val[v:key] . v:val')
  endif
endfunction "}}}
function! s:area.u_cut(n) "{{{
  " n: number of cut
  return remove(self._data, 0, a:n-1)
endfunction "}}}
function! s:area.d_cut(n) "{{{
  " n: number of cut
  let last = self.height()
  return remove(self._data, last-a:n, last-1)
endfunction "}}}
function! s:area.r_cut(n) "{{{
  let r = map(copy(self._data), 'v:val[-a:n : -1]')
  call map(self._data, 'v:val[:-a:n-1]')
  return r
endfunction "}}}
function! s:area.l_cut(n) "{{{
  let r = map(copy(self._data), 'v:val[ : a:n-1]')
  call map(self._data, 'v:val[a:n :]')
  call map(self._data, 'v:val[a:n :]')
  return r     
endfunction "}}}
               
               
" Public:
function! textmanip#area#new(data) "{{{
  return s:area.new(a:data)
endfunction "}}}
" vim: foldmethod=marker
