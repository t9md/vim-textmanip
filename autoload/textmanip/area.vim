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
  return self
endfunction "}}}
function! s:area.d_add(val) "{{{
  let v = type(a:val) ==# 3 ? a:val : [a:val]
  let self._data = self._data + v
  return self
endfunction "}}}
function! s:area.r_add(val) "{{{
  if empty(self._data)
    let self._data = map(copy(a:val), 'v:val')
  else
    call map(self._data, 'v:val . a:val[v:key]')
  endif
  return self
endfunction "}}}
function! s:area.l_add(val) "{{{
  if empty(self._data)
    let self._data = map(copy(a:val), 'v:val')
  else
    cal map(self._data, 'a:val[v:key] . v:val')
  endif
  return self
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
  return r     
endfunction "}}}
function! s:area.u_rotate(n) "{{{
  call self.d_add(self.u_cut(a:n))
  return self
endfunction "}}}
function! s:area.d_rotate(n) "{{{
  call self.u_add(self.d_cut(a:n))
  return self
endfunction "}}}
function! s:area.l_rotate(n) "{{{
  call self.r_add(self.l_cut(a:n))
  return self
endfunction "}}}
function! s:area.r_rotate(n) "{{{
  call self.l_add(self.r_cut(a:n))
  return self
endfunction "}}}
function! s:area.v_duplicate(n) "{{{
  " vertical
  let data = copy(self.data())
  for n in range(a:n)
    call self.u_add(data)
  endfor
  return self
endfunction "}}}
" function! s:area.d_dup(n) "{{{
  " return self.u_dup(a:n)
" endfunction "}}}
               
               
" Public:
function! textmanip#area#new(data) "{{{
  return s:area.new(a:data)
endfunction "}}}
" vim: foldmethod=marker
