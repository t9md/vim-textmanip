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

let s:u = textmanip#util#get()

function! s:height(val) "{{{1
  return len(a:val)
endfunction

function! s:width(val) "{{{1
  return len(a:val[0])
endfunction
"}}}

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

function! s:area.dump() "{{{1
  return PP(self.data())
endfunction

" add
function! s:area.add(dir, val) "{{{1
  let lis = type(a:val) ==# 3 ? a:val : [a:val]
  let dir = toupper(a:dir)

  if dir is 'U'
    call self.data(lis + self.data())
    return self
  endif

  if dir is 'D'
    call self.data(self.data() + lis) 
    return self
  endif

  if self.is_empty()
    call self.data(lis)
    return self
  endif

  if dir is 'L'
    cal map(self.data(), 'lis[v:key] . v:val')
    return self
  endif

  if dir is 'R'
    call map(self.data(), 'v:val . lis[v:key]')
    return self
  endif

  throw 'never happen!'
endfunction


" cut
function! s:area.cut(dir, n) "{{{1
  " n: number of cut
  let dir = toupper(a:dir)

  if dir is 'U'
    let end = min([a:n, self.height()]) - 1
    return remove(self.data(), 0, end)
  endif

  if dir is 'D'
    let last = self.height()
    return remove(self.data(), last-a:n, last-1)
  endif

  if dir is 'L'
    let R = map(copy(self.data()), 'v:val[ : a:n-1]')
    call map(self.data(), 'v:val[a:n :]')
    return R
  endif

  if dir is 'R'
    let R = map(copy(self.data()), 'v:val[-a:n : -1]')
    call map(self.data(), 'v:val[:-a:n-1]')
    return R
  endif

  throw 'never happen!'
endfunction

" swap
function! s:area.swap(dir, val) "{{{1
  let dir = toupper(a:dir)
  let count =
        \ dir =~# 'U\|D' ? s:height(a:val) : s:width(a:val)

  let R = self.cut(dir, count)
  call self.add(dir, a:val)
  return R
  throw 'never happen!'
endfunction

" pushout
function! s:area.pushout(dir, val) "{{{1
  let dir = toupper(a:dir)

  let count =
        \ dir =~# 'U\|D' ? s:height(a:val) : s:width(a:val)

  call self.add(dir, a:val)
  return self.cut(s:u.opposite(dir), count)
endfunction

" rotate
function! s:area.rotate(dir, n)
  let dir = toupper(a:dir)
  let add = s:u.opposite(dir)
  call self.add(add, self.cut(dir, a:n))
  return self
endfunction

" duplcate vertical/horizontal(=side)
function! s:area.duplicate(dir, n) "{{{1
  let dir = toupper(a:dir)
  if dir is 'V' " vertical
    call self.data(repeat(self.data(), a:n))
    return self
  endif

  if dir is 'H' " horizontal
    " horizontal, map have side effect, so no need to updata with data()
    call map(self.data(), 'repeat(v:val, a:n)')
    return self
  endif
endfunction
"}}}

" Public:
function! textmanip#area#new(data) "{{{1
  return s:area.new(a:data)
endfunction
" vim: foldmethod=marker
