" Memo:
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
  " data is array of string
  "  ex) [ 'string1', 'string2'...]
  "
  " and `_data` is only state this object keep.
  " So we dont' need deepcopy, shallow copy is ok here.
  let o = copy(self)
  let o._data = a:data
  return o
endfunction

function! s:area.data(...) "{{{1
  if a:0
    let self._data = a:1
  endif
  return self._data
endfunction

function! s:area.height() "{{{1
  return len(self.data())
endfunction

function! s:area.is_empty() "{{{1
  return empty(self.data())
endfunction

function! s:area.width() "{{{1
  " assume all data have same width, so this function is useless!
  " FIXME should delete this function?
  return len(self.data()[0])
endfunction

function! s:area.reset() "{{{1
  call self.data([])
endfunction

function! s:area.dump() "{{{1
  return PP(self.data())
endfunction

" add
function! s:area.u_add(val) "{{{1
  " add to top
  let v = type(a:val) ==# 3 ? a:val : [a:val]
  call self.data(v + self.data())
  return self
endfunction

function! s:area.d_add(val) "{{{1
  " add to bottom
  let v = type(a:val) ==# 3 ? a:val : [a:val]
  call self.data(self.data() + v)
  return self
endfunction

function! s:area.r_add(lis) "{{{1
  " add to right
  if self.is_empty()
    call self.data(a:lis)
  else
    call map(self.data(), 'v:val . a:lis[v:key]')
  endif
  return self
endfunction

function! s:area.l_add(val) "{{{1
  " add to left
  if self.is_empty()
    call self.data(a:lis)
  else
    cal map(self._data, 'a:val[v:key] . v:val')
  endif
  return self
endfunction

" cut
function! s:area.u_cut(n) "{{{1
  " n: number of cut
  let end = min([a:n, self.height()]) - 1
  return remove(self.data(), 0, end)
endfunction

function! s:area.d_cut(n) "{{{1
  " n: number of cut
  let last = self.height()
  return remove(self.data(), last-a:n, last-1)
endfunction

function! s:area.r_cut(n) "{{{1
  let R = map(copy(self.data()), 'v:val[-a:n : -1]')
  call map(self.data(), 'v:val[:-a:n-1]')
  return R
endfunction

function! s:area.l_cut(n) "{{{1
  let R = map(copy(self.data()), 'v:val[ : a:n-1]')
  call map(self.data(), 'v:val[a:n :]')
  return R
endfunction

" swap
function! s:area.u_swap(v) "{{{1
  let R = self.u_cut(len(a:v))
  call self.u_add(a:v)
  return R
endfunction

function! s:area.d_swap(v) "{{{1
  let R = self.d_cut(len(a:v))
  call self.d_add(a:v)
  return R
endfunction

function! s:area.r_swap(v) "{{{1
  " Assumption:
  "  'v' is List
  "  'v': all member have same width,
  "  'v': len(v) ==# self.height()
  " assume all member have same width,
  let R = self.r_cut(len(a:v[0]))
  call self.r_add(a:v)
  return R
endfunction

function! s:area.l_swap(v) "{{{1
  " assume all member have same width
  let R = self.l_cut(len(a:v[0]))
  call self.l_add(a:v)
  return R
endfunction

" pushout
function! s:area.u_pushout(v) "{{{1
  call self.u_add(a:v)
  return self.d_cut(len(a:v))
endfunction

function! s:area.d_pushout(v) "{{{1
  call self.d_add(a:v)
  return self.u_cut(len(a:v))
endfunction

function! s:area.r_pushout(v) "{{{1
  call self.r_add(a:v)
  return self.l_cut(len(a:v[0]))
endfunction

function! s:area.l_pushout(v) "{{{1
  call self.l_add(a:v)
  return self.r_cut(len(a:v[0]))
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
  call self.data(repeat(self.data(), a:n))
  return self
endfunction

function! s:area.h_duplicate(n) "{{{1
  " horizontal, map have side effect, so no need to updata with data()
  call map(self.data(), 'repeat(v:val, a:n)')
  return self
endfunction

" Public:
function! textmanip#area#new(data) "{{{1
  return s:area.new(a:data)
endfunction
" vim: foldmethod=marker
