" Util:
let s:u       = textmanip#util#get()
let s:newArea = function('textmanip#area#new')

" Main:
" @action = [ 'move', 'duplicate', 'blank']
" @direction = [ '^', 'v', '<', '>' ]
" @count = Number
let s:Selection = {} 

function! s:Selection.new(s, e, mode, dir) "{{{1
  "DONE:
  " both `s` and `e` are instance of textmanip#pos

  let [s, e]      = [a:s, a:e]
  let self.mode   = a:mode
  let self.vars   = {}
  let self.toward = s:u.toward(a:dir)

  "     [   1   ]    [   2   ]    [   3   ]    [   4   ]
  "    s----+----+  e----+----+  +----+----s  +----+----e
  "    |    |    |  |    |    |  |    |    |  |    |    |
  "    +----+----+  +----+----+  +----+----+  +----+----+
  "    |    |    |  |    |    |  |    |    |  |    |    |
  "    +----+----e  +----+----s  e----+----+  s----+----+
  "
  let [T, B, L, R] =
        \ 1 && (s.line <= e.line) && (s.colm <= e.colm) ? [ s, e, s, e ] :
        \ 2 && (s.line >= e.line) && (s.colm >= e.colm) ? [ e, s, e, s ] :
        \ 3 && (s.line <= e.line) && (s.colm >= e.colm) ? [ s, e, e, s ] :
        \ 4 && (s.line >= e.line) && (s.colm <= e.colm) ? [ e, s, s, e ] :
        \ throw
  let self.pos = { 'S': s, 'E': e, 'T': T, 'B': B, 'L': L, 'R': R }

  " Preserve original height and width since it's may change while operation
  let self.toward   = s:u.toward(a:dir)
  let self.height   = self.pos.B.line - self.pos.T.line + 1
  let self.width    = self.pos.R.colm - self.pos.L.colm + 1
  let self.linewise = self.is_linewise()
  let self.content  = []
  let self.regtype  = ''
  return self
endfunction

function! s:Selection.cursor(pos) "{{{1
  call cursor(self.pos[a:pos].pos())
  return self
endfunction

function! s:Selection.is_linewise() "{{{1
  " may be unnecessary
  return 
        \ (self.mode ==# 'n' ) ||
        \ (self.mode ==# 'V' ) ||
        \ (self.mode ==# 'v' && self.height > 1)
endfunction

function! s:Selection.select(...) "{{{1
  if a:0
    call call(self.move_pos, a:000, self)
  endif

  silent execute "normal! \<Esc>"
  call cursor(self.pos.S.pos()+[0])

  let mode =
        \ self.mode ==# 'v' ? ( self.height ==# 1 ? "\<C-v>" : 'V' ) :
        \ self.mode ==# 'n' ? 'V' : self.mode

  execute 'normal! ' . mode

  call cursor(self.pos.E.pos()+[0])
  return self
endfunction

function! s:Selection.yank() "{{{1
  " DONE:
  try
    let reg = textmanip#register#save('x')
    if self.mode ==# 'n'
      silent execute 'normal! "xyy'
    else
      silent execute 'normal! "xy'
    endif

    let regtype = getregtype('x')
    let content = split(getreg('x'), "\n", 1)
    " if linewise, content have empty string('') entry at end of List.
    if regtype ==# 'V'
      let content =  content[0:-2]
    endif
    let self.content = content
    let self.regtype = regtype
    return self
  finally
    call reg.restore()
  endtry
endfunction

function! s:Selection.paste() "{{{1
  call self.select()
  try
    let reg = textmanip#register#save('x')
    call setreg('x', self.content, self.regtype)
    silent execute 'normal! "xp'
    return self
  finally
    call reg.restore()
  endtry
endfunction

function! s:Selection.manipulate(action, emode, dir, c) "{{{1
  let args = [self.content]
  if a:action ==# 'rotate' && a:emode ==# 'replace'
    let args += [self.replaced]
  endif

  let area = call('textmanip#area#new', args)
  let self.content = area[a:action](a:dir, a:c).data()
  return self
endfunction

function! s:Selection.move_pos(opes, vars) "{{{1
  for ope in s:u.toList(a:opes)
    let pos = ope[0]
    let _ope = split(ope[1:], '\v\s*:\s*', 1)
    call map(_ope, 's:u.template(v:val, a:vars)')
    call self.pos[pos].move(_ope)
  endfor
  return self
endfunction

function! s:Selection.insert_blank(dir, num) "{{{1
  let where =
        \ a:dir ==# '^' ? self.pos.T.line-1 :
        \ a:dir ==# 'v' ? self.pos.B.line   :
        \ a:dir ==# '>' ? self.pos.R.colm   :
        \ a:dir ==# '<' ? self.pos.L.colm-1 : throw   
  if self.toward ==# '^v'
    call append(where, map(range(a:num), '""'))
  else
    let lines = map(getline(self.pos.T.line, self.pos.B.line),
          \ 'v:val[0 : where-1] . repeat(" ", a:num) . v:val[ where : ]')
    call setline(self.pos.T.line, lines)
  endif
  return self
endfunction


function! s:Selection.new_replace() "{{{1
  let self.replaced = textmanip#area#new([])
  let emptyline     = self.linewise ? [''] : [repeat(' ', self.width)]
  return textmanip#area#new(repeat(emptyline, self.height))
endfunction

function! s:Selection.state() "{{{1
  " should not depend current visual selction to keep selection state
  " unchanged. So need to extract rectangle region from colum.
  let content = getline(self.pos.T.line, self.pos.B.line)
  if !self.linewise
    let content = getline(self.pos.T.line, self.pos.B.line)
    let content = map(content, 'v:val[ self.pos.L.colm - 1 : self.pos.R.colm - 1]')
  endif
  return  {
        \ 'line_top':    self.pos.T.line,
        \ 'line_bottom': self.pos.B.line,
        \ 'len':         len(content),
        \ 'content':     content,
        \ }
endfunction
"}}}

" Action:
function! s:Selection.move(dir, c, emode) "{{{1
  " DONE:
  if self.toward ==# '<>' && self.linewise
    " a:dir is '<' or '>', yes its valid Vim operator! so I can pass as-is
    execute "'<,'>" . repeat(a:dir, a:c)
    call self.select()
    return
  endif

  if a:dir ==# 'v'
    " Extend EOF if needed
    let amount = (self.pos.B.line + a:c) - line('$')
    if amount > 0
      call append(line('$'), map(range(amount), '""'))
    endif
  endif

  let [ before, after ] =  {
        \ "^": [ 'T -c:  ', 'B -c:  ' ],
        \ "v": [ 'B +c:  ', 'T +c:  ' ],
        \ ">": [ 'R   :+c', 'L   :+c' ],
        \ "<": [ 'L   :-c', 'R   :-c' ],
        \ }[a:dir]

  let vars = {'c': a:c }
  call self.move_pos(before, vars)
        \.select().yank()
        \.manipulate('rotate', a:emode, a:dir, a:c)
        \.select().paste().move_pos(after, vars).select()
endfunction

function! s:Selection.duplicate(dir, c, emode) "{{{1
  call self.select().yank()

  if self.toward ==# '<>' && self.linewise
    call self.manipulate('duplicate', a:emode, a:dir, a:c+1).paste().select()
    return
  endif

  if a:emode ==# "insert"
    let before = {
          \ "^": ['B +h*(c-1):          '                   ],
          \ "v": ['T +h        :        ', 'B +(h*c):      '],
          \ ">": ['L           :+w      ', 'R       :+(w*c)'],
          \ "<": ['R           :+w*(c-1)'                   ],
          \ }[a:dir]

    call self.insert_blank(a:dir, self[self.toward ==# '^v' ? 'height' : 'width'] * a:c)

  elseif a:emode ==# "replace"
    let before =  {
          \ "^": ['T -(h*c):  ', 'B -h    :      '],
          \ "v": ['T +h    :  ', 'B +(h*c):      '],
          \ ">": ['L       :+w', 'R       :+(w*c)'],
          \ "<": ['R       :-w', 'L       :-(w*c)'],
          \ }[a:dir]
  endif

  let vars = { 'c': a:c, 'h': self.height, 'w': self.width }
  call self.manipulate('duplicate', a:emode, a:dir, a:c)
        \.select(before, vars).paste().select()

  if self.mode ==# 'n'
    execute "normal! \<Esc>"
    call self.cursor(a:dir ==# '^' ? 'T': 'B')
  endif
endfunction

function! s:Selection.blank(dir, count, emode) "{{{1
  " DONE:
  let where =
        \ a:dir ==# '^' ? self.pos.T.line-1 :
        \ a:dir ==# 'v' ? self.pos.B.line   : throw
  call append(where, map(range(a:count), '""'))
  if !(self.mode ==# 'n')
    normal! gv
  endif
endfunction

"}}}

" Api:
function! textmanip#selection#new(...) "{{{1
  return call(s:Selection.new, a:000, s:Selection)
endfunction

" vim: foldmethod=marker
