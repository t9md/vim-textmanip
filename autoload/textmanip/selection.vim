" Util:
let s:u = textmanip#util#get()

" Main:
let s:Selection = {} 

function! s:Selection.new(s, e, env) "{{{1
  " both `s` and `e` are instance of textmanip#pos
  let [s, e]       = [a:s, a:e]
  let self.env     = a:env
  let self.toward  = s:u.toward(self.env.dir)
  let self.register = textmanip#register#use('x')

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
  let self.height     = self.pos.B.line - self.pos.T.line + 1
  let self.width      = self.pos.R.colm - self.pos.L.colm + 1
  let self.linewise   = self.is_linewise()
  let self.content    = []
  let self.regtype    = ''
  let self.continuous = get(b:, "textmanip_status", {}) == self.state()
  return self
endfunction

function! s:Selection.cursor(pos) "{{{1
  call cursor(self.pos[a:pos].pos())
  return self
endfunction

function! s:Selection.update_status() "{{{1
  let b:textmanip_status = self.state()
  return self
endfunction

function! s:Selection.is_linewise() "{{{1
  " may be unnecessary
  return 
        \ (self.env.mode ==# 'n' ) ||
        \ (self.env.mode ==# 'V' ) ||
        \ (self.env.mode ==# 'v' && self.height > 1)
endfunction

function! s:Selection.select(...) "{{{1
  if a:0
    call call(self.move_pos, a:000, self)
  endif

  silent execute "normal! \<Esc>"
  call cursor(self.pos.S.pos())

  let mode =
        \ self.env.mode ==# 'v' ? ( self.height ==# 1 ? "\<C-v>" : 'V' ) :
        \ self.env.mode ==# 'n' ? 'V' : self.env.mode

  execute 'normal! ' . mode
  call cursor(self.pos.E.pos())
  return self
endfunction

function! s:Selection.yank(...) "{{{1
  call call(self.select, a:000, self)
  call self.register.yank()
  return self
endfunction

function! s:Selection.paste(...) "{{{1
  call call(self.select, a:000, self)
  call self.register.paste()
  return self
endfunction

function! s:Selection.manipulate(action, emode, dir, c) "{{{1
  let args = [self.register.content]
  if a:action ==# 'rotate' && a:emode ==# 'replace'
    if ! self.continuous
      let b:textmanip_replaced = self.new_replace()
    endif
    let args += [b:textmanip_replaced]
  endif

  let area = call('textmanip#area#new', args)
  let data = area[a:action](a:dir, a:c).data()
  let self.register.content = data
  return self
endfunction

function! s:Selection.move_pos(opes) "{{{1
  let vars = { 'c': self.env.count, 'h': self.height, 'w': self.width }
  for ope in s:u.toList(a:opes)
    let pos = ope[0]
    let _ope = split(ope[1:], '\v\s*:\s*', 1)
    call map(_ope, 's:u.template(v:val, vars)')
    call self.pos[pos].move(_ope)
  endfor
  return self
endfunction

function! s:Selection.insert_blank(dir, num) "{{{1
  let where = {
        \ '^': self.pos.T.line-1, 'v': self.pos.B.line,
        \ '<': self.pos.L.colm-1, '>': self.pos.R.colm,
        \ }[a:dir]                            
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
  let emptyline     = self.linewise ? [''] : [repeat(' ', self.width)]
  return textmanip#area#new(repeat(emptyline, self.height))
endfunction

function! s:Selection.state() "{{{1
  " should not depend current visual selction to keep selection state
  " unchanged. So need to extract rectangle region from colum.
  let content = getline(self.pos.T.line, self.pos.B.line)
  if !self.linewise
    let content = getline(self.pos.T.line, self.pos.B.line)
    call map(content, 'v:val[ self.pos.L.colm - 1 : self.pos.R.colm - 1]')
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
" function! s:Selection.move(dir, c, emode) "{{{1
function! s:Selection.move() "{{{1
  if self.continuous
    silent! undojoin
  endif

  let [dir, c, emode] = [self.env.dir, self.env.count, self.env.emode]

  if self.toward ==# '<>' && self.linewise
    " a:dir is '<' or '>', yes its valid Vim operator! so I can pass as-is
    execute "'<,'>" . repeat(dir, c)
    call self.select().update_status()
    return
  endif

  if dir ==# 'v'
    " Extend EOF if needed
    let amount = (self.pos.B.line + c) - line('$')
    if amount > 0
      call append(line('$'), map(range(amount), '""'))
    endif
  endif

  let [ before, after ] =  {
        \ "^": [ 'T -c:  ', 'B -c:  ' ],
        \ "v": [ 'B +c:  ', 'T +c:  ' ],
        \ ">": [ 'R   :+c', 'L   :+c' ],
        \ "<": [ 'L   :-c', 'R   :-c' ],
        \ }[dir]

  call self
        \.yank(before)
        \.manipulate('rotate', emode, dir, c)
        \.paste().select(after).update_status()
endfunction

function! s:Selection.duplicate()
  let [dir, c, emode] = [self.env.dir, self.env.count, self.env.emode]

  call self.yank()
  if self.toward ==# '<>' && self.linewise
    call self.manipulate('duplicate', emode, dir, c+1).paste().select()
    return
  endif

  if emode ==# "insert"
    let before = {
          \ "^": ['B +h*(c-1):          '                   ],
          \ "v": ['T +h        :        ', 'B +(h*c):      '],
          \ ">": ['L           :+w      ', 'R       :+(w*c)'],
          \ "<": ['R           :+w*(c-1)'                   ],
          \ }[dir]

    call self.insert_blank(dir, self[self.toward ==# '^v' ? 'height' : 'width'] * c)

  elseif emode ==# "replace"
    let before =  {
          \ "^": ['T -(h*c):  ', 'B -h    :      '],
          \ "v": ['T +h    :  ', 'B +(h*c):      '],
          \ ">": ['L       :+w', 'R       :+(w*c)'],
          \ "<": ['R       :-w', 'L       :-(w*c)'],
          \ }[dir]
  endif
  call self.manipulate('duplicate', emode, dir, c)
        \.paste(before).select()

  if self.env.mode ==# 'n'
    execute "normal! \<Esc>"
    call self.cursor(dir ==# '^' ? 'T': 'B')
  endif
endfunction

function! s:Selection.blank() "{{{1
  let where = {
        \ '^': self.pos.T.line-1,
        \ 'v': self.pos.B.line,
        \ }[self.env.dir]
  call append(where, map(range(self.env.count), '""'))
  if !(self.env.mode ==# 'n')
    normal! gv
  endif
endfunction
"}}}

" Api:
function! textmanip#selection#new(...) "{{{1
  return call(s:Selection.new, a:000, s:Selection)
endfunction
" vim: foldmethod=marker
