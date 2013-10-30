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
  call self.replace([])
endfunction "}}}
function! s:area.dump() "{{{
  return PP(self._data)
endfunction "}}}
function! s:area.replace(v) "{{{
  let self._data = a:v
  return self
endfunction "}}}

" add
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

" cut
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

" swap
function! s:area.u_swap(v) "{{{
  let height = len(a:v)
  let r = self.u_cut(height)
  call self.u_add(a:v)
  return r
endfunction "}}}
function! s:area.d_swap(v) "{{{
  let height = len(a:v)
  let r = self.d_cut(height)
  call self.d_add(a:v)
  return r
endfunction "}}}
function! s:area.r_swap(v) "{{{
  " assume all member have same width
  let width = len(a:v[0])
  let r = self.r_cut(width)
  call self.r_add(a:v)
  return r
endfunction "}}}
function! s:area.l_swap(v) "{{{
  " assume all member have same width
  let width = len(a:v[0])
  let r = self.l_cut(width)
  call self.l_add(a:v)
  return r
endfunction "}}}

" pushout
function! s:area.u_pushout(v) "{{{
  let height = len(a:v)
  let r = self.d_cut(height)
  call self.u_add(a:v)
  return r
endfunction "}}}
function! s:area.d_pushout(v) "{{{
  let height = len(a:v)
  let r = self.u_cut(height)
  call self.d_add(a:v)
  return r
endfunction "}}}
function! s:area.r_pushout(v) "{{{
  " assume all member have same width
  let width = len(a:v[0])
  let r = self.l_cut(width)
  call self.r_add(a:v)
  return r
endfunction "}}}
function! s:area.l_pushout(v) "{{{
  " assume all member have same width
  let width = len(a:v[0])
  let r = self.r_cut(width)
  call self.l_add(a:v)
  return r
endfunction "}}}

" rotate
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

" duplcate vertical/horizontal(=side)
function! s:area.v_duplicate(n) "{{{
  " vertical
  return self.replace(repeat(self.data(), a:n))
endfunction "}}}
function! s:area.h_duplicate(n) "{{{
  " horizontal, map have side effect, but ensure update value via replace()
  return self.replace( map(copy(self.data()), 'repeat(v:val, a:n)') )
endfunction "}}}

" Public:
function! textmanip#area#new(data) "{{{
  return s:area.new(a:data)
endfunction "}}}
" vim: foldmethod=marker

" Test:
" finish
function! s:split(mode) "{{{
  return split(a:mode, '.\zs')
endfunction "}}}

let s = s:area.new([])
" call s.h_duplicate(2)
call s.u_add(["abc", "def","hij"])
" call s.u_add("def")
echo s.data()
echo "--"
" echo s.r_cut(1)
" echo s.r_cut(1)
echo "pushed :" . string(s.l_pushout(s:split("xyz")))
" echo s.u_pushout([12,24])
echo s.data()
" echo swapped
" let swapped =  s.d_swap(["a","b"])
" echo s.data()
" echo swapped

" function! s:arAAAAAAAAAAAA
  " return self.BBBBBBBBBBBB



