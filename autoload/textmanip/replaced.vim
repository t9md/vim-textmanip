" Private:
let s:replaced = {}
function! s:replaced.new(owner) "{{{
  let o = deepcopy(self)
  let o.owner = a:owner
  let o._data = textmanip#area#new([])
  return o
endfunction "}}}
function! s:replaced.data() "{{{
  return self._data.data()
endfunction "}}}
function! s:replaced.height() "{{{
  return self._data.height()
endfunction "}}}
function! s:replaced.width() "{{{
  return self._data.width()
endfunction "}}}
function! s:replaced.reset() "{{{
  call self._data.reset()
endfunction "}}}
function! s:replaced.dump() "{{{
  echo PP(self)
endfunction "}}}

function! s:replaced.up(val) "{{{
  call self._data.u_add(a:val)
  let c = self.height() - self.owner.height
  if c > 0
    " visual area moved over height need un-eat
    return self._data.d_cut(c)
  else
    return self.owner.is_linewise ? [''] : [repeat(' ', self.owner.width)]
  endif
endfunction "}}}
function! s:replaced.down(val) "{{{
  call self._data.d_add(a:val)
  let c = self.height() - self.owner.height
  if c > 0
    return self._data.u_cut(c)
  else
    return self.owner.is_linewise ? [''] : [repeat(' ', self.owner.width)]
  endif
endfunction "}}}
function! s:replaced.left(val) "{{{
  call self._data.l_add(a:val)
  let c = self.width() - self.owner.width
  if c > 0
    " visual area moved over width need un-eat
    return self._data.r_cut(c)
  else
    let space = repeat(" ", len(a:val[0]))
    return map(range(self.owner.height), 'space')
  endif
endfunction "}}}
function! s:replaced.right(val) "{{{
  call self._data.r_add(a:val)
  let c = self.width() - self.owner.width
  if c > 0
    " visual area moved over width need un-eat
    return self._data.l_cut(c)
  else
    let space = repeat(" ", len(a:val[0]))
    return map(range(self.owner.height), 'space')
  endif
endfunction "}}}

" Public:
function! textmanip#replaced#new(owner) "{{{
  return s:replaced.new(a:owner)
endfunction "}}}


" Test:
" finish
let varea = {}
let varea.is_linewise = 1
let varea.width  = 3
let varea.height = 4

let replaced = textmanip#replaced#new(varea)
echo replaced.up("abc")
echo replaced.up("abc")
echo replaced.height()
finish
echo replaced.up("def")
echo replaced.up("ghi")
echo replaced.data()
let a = textmanip#area#new( copy(replaced.data() ))
" echo replace.left([1,2,3])
echo replaced.right([1,2,3])
echo replaced.data()        
echo a.data()
" vim: foldmethod=marker
