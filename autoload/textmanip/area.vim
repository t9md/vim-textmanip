" Private:
"         l_cut/add           r_cut/add
"                 |           |
"                 V           V        _.data index
"                +-+---------+-+----      0
"   u_cut/add -> +-+         +-+   ^      |
"                |             |   |      |
"                |             |  height  |
"                |             |   |      |
"                +-+         +-+   V      N
"   d_cut/add -> +-+---------+-+ ---   len(_.data)
"                |             |
"                +<-- width -->+
let s:area = {}
function! s:area.new(data) "{{{1
  let o = deepcopy(self)
  let o._data = a:data
  return o
endfunction

function! s:area.data() "{{{1
  return self._data
endfunction

function! s:area.height() "{{{1
  return len(self._data)
endfunction

function! s:area.width() "{{{1
  " assume all data have same width
  return len(self._data[0])
endfunction

function! s:area.reset() "{{{1
  call self.replace([])
endfunction

function! s:area.dump() "{{{1
  return PP(self._data)
endfunction

function! s:area.replace(v) "{{{1
  let self._data = a:v
  return self
endfunction

" add
function! s:area.u_add(val) "{{{1
  let v = type(a:val) ==# 3 ? a:val : [a:val]
  let self._data = v + self._data
  return self
endfunction

function! s:area.d_add(val) "{{{1
  let v = type(a:val) ==# 3 ? a:val : [a:val]
  let self._data = self._data + v
  return self
endfunction

function! s:area.r_add(val) "{{{1
  if empty(self._data)
    let self._data = map(copy(a:val), 'v:val')
  else
    call map(self._data, 'v:val . a:val[v:key]')
  endif
  return self
endfunction

function! s:area.l_add(val) "{{{1
  if empty(self._data)
    let self._data = map(copy(a:val), 'v:val')
  else
    cal map(self._data, 'a:val[v:key] . v:val')
  endif
  return self
endfunction

" cut
function! s:area.u_cut(n) "{{{1
  " n: number of cut
  return remove(self._data, 0, a:n-1)
endfunction

function! s:area.d_cut(n) "{{{1
  " n: number of cut
  let last = self.height()
  return remove(self._data, last-a:n, last-1)
endfunction

function! s:area.r_cut(n) "{{{1
  let r = map(copy(self._data), 'v:val[-a:n : -1]')
  call map(self._data, 'v:val[:-a:n-1]')
  return r
endfunction

function! s:area.l_cut(n) "{{{1
  let r = map(copy(self._data), 'v:val[ : a:n-1]')
  call map(self._data, 'v:val[a:n :]')
  return r     
endfunction

" swap
function! s:area.u_swap(v) "{{{1
  let height = len(a:v)
  let r = self.u_cut(height)
  call self.u_add(a:v)
  return r
endfunction

function! s:area.d_swap(v) "{{{1
  let height = len(a:v)
  let r = self.d_cut(height)
  call self.d_add(a:v)
  return r
endfunction

function! s:area.r_swap(v) "{{{1
  " assume all member have same width
  let width = len(a:v[0])
  let r = self.r_cut(width)
  call self.r_add(a:v)
  return r
endfunction

function! s:area.l_swap(v) "{{{1
  " assume all member have same width
  let width = len(a:v[0])
  let r = self.l_cut(width)
  call self.l_add(a:v)
  return r
endfunction


" pushout
function! s:area.u_pushout(v) "{{{1
  let height = len(a:v)
  call self.u_add(a:v)
  let r = self.d_cut(height)
  return r
endfunction

function! s:area.d_pushout(v) "{{{1
  let height = len(a:v)
  call self.d_add(a:v)
  let r = self.u_cut(height)
  return r
endfunction

function! s:area.r_pushout(v) "{{{1
  " assume all member have same width
  let width = len(a:v[0])
  call self.r_add(a:v)
  let r = self.l_cut(width)
  return r
endfunction

function! s:area.l_pushout(v) "{{{1
  " assume all member have same width
  let width = len(a:v[0])
  call self.l_add(a:v)
  let r = self.r_cut(width)
  return r
endfunction

" rotate
function! s:area.u_rotate(n) "{{{1
  call self.d_add(self.u_cut(a:n))
  return self
endfunction

function! s:area.d_rotate(n) "{{{1
  call self.u_add(self.d_cut(a:n))
  return self
endfunction

function! s:area.l_rotate(n) "{{{1
  call self.r_add(self.l_cut(a:n))
  return self
endfunction

function! s:area.r_rotate(n) "{{{1
  call self.l_add(self.r_cut(a:n))
  return self
endfunction

" duplcate vertical/horizontal(=side)
function! s:area.v_duplicate(n) "{{{1
  " vertical
  return self.replace(repeat(self.data(), a:n))
endfunction

function! s:area.h_duplicate(n) "{{{1
  " horizontal, map have side effect, but ensure update value via replace()
  return self.replace( map(copy(self.data()), 'repeat(v:val, a:n)') )
endfunction

" Public:
function! textmanip#area#new(data) "{{{1
  return s:area.new(a:data)
endfunction
" vim: foldmethod=marker
