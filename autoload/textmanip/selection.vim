" Util:
let s:u = textmanip#util#get()

function! s:getpos(mode) "{{{1
  if a:mode ==# 'n'
    let s = getpos('.')
    return [s, s]
  endif

  exe 'normal! gvo' | let s = getpos('.') | exe "normal! \<Esc>"
  exe 'normal! gvo' | let e = getpos('.') | exe "normal! \<Esc>"

  return [s, e]
endfunction

" Main:
let s:Selection = {} 
function! s:Selection.new(env) "{{{1
  let [_s, _e]      = s:getpos(a:env.mode)
  let s             = textmanip#pos#new(_s)
  let e             = textmanip#pos#new(_e)
  let self.env      = a:env
  let self.toward   = s:u.toward(self.env.dir)
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
  let self.pos = { 'S': s, 'E': e, '^': T, 'v': B, '<': L, '>': R, }

  " Preserve original height and width
  let self.height     = self.pos['v'].line - self.pos['^'].line + 1
  let self.width      = self.pos['>'].colm - self.pos['<'].colm + 1
  let self.linewise   = self.is_linewise()
  let self.continuous = get(b:, "textmanip_status", {}) == self.state()
  return self
endfunction

function! s:Selection.manip() "{{{1
  call self[self.env.action]()
endfunction

function! s:Selection.is_linewise() "{{{1
  return 
        \ (self.env.mode ==# 'V' ) ||
        \ (self.env.mode ==# 'n' ) ||
        \ (self.env.mode ==# 'v' && self.height > 1)
endfunction

function! s:Selection.finish(...) "{{{1
  call call(self.select, a:000, self)

  if self.env.action ==# 'move'
    call self.update_status()
  endif

  if self.env.mode ==# 'v'
    execute 'normal! v'
    throw 'FINISH'
  endif

  if self.env.mode ==# 'n'
    execute "normal! \<Esc>"
    if self.env.action ==# 'duplicate'
      call self.pos[self.env.dir].set_cursor()
    endif
  endif

  throw 'FINISH'
endfunction

function! s:Selection.select(...) "{{{1
  if a:0
    call call(self.move_pos, a:000, self)
  endif
  silent execute "normal! \<Esc>"
  call self.pos.S.set_cursor()
  execute 'normal! ' . (self.linewise ? 'V' : "\<C-v>")
  call self.pos.E.set_cursor()
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

function! s:Selection.modify() "{{{1
  let action = self.env.action ==# 'move' ? 'rotate' : self.env.action
  let args   = [self.register.content]

  if action ==# 'rotate' && self.env.emode ==# 'replace'
    if ! self.continuous
      let initial = self.linewise ? [''] : [repeat(' ', self.width)]
      let b:textmanip_replaced = textmanip#area#new(repeat(initial, self.height))
    endif
    let args += [b:textmanip_replaced]
  endif
  let self.register.content =
        \ call('textmanip#area#new', args)[action](self.env.dir, self.env.count).data()
  return self
endfunction

function! s:Selection.move_pos(opes) "{{{1
  let vars = { 'c': self.env.count, 'h': self.height, 'w': self.width, 'SW': &sw }
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
        \ '^': self.pos['^'].line-1, 'v': self.pos['v'].line,
        \ '<': self.pos['<'].colm-1, '>': self.pos['>'].colm,
        \ }[a:dir]                            
  if self.toward ==# '^v'
    call append(where, map(range(a:num), '""'))
  else
    let lines = map(getline(self.pos['^'].line, self.pos['v'].line),
          \ 'v:val[0 : where-1] . repeat(" ", a:num) . v:val[ where : ]')
    call setline(self.pos['^'].line, lines)
  endif
  return self
endfunction

function! s:Selection.state() "{{{1
  " should not depend current visual selction to keep selection state
  " unchanged. So need to extract rectangle region from colum.
  let content = getline(self.pos['^'].line, self.pos['v'].line)
  if !self.linewise
    call map(content, 'v:val[ self.pos["<"].colm - 1 : self.pos[">"].colm - 1]')
  endif
  return  {
        \ 'emode':       self.env.emode,
        \ 'line_top':    self.pos['^'].line,
        \ 'line_bottom': self.pos['v'].line,
        \ 'len':         len(content),
        \ 'content':     content,
        \ }
endfunction

function! s:Selection.update_status() "{{{1
  let b:textmanip_status = self.state()
  return self
endfunction
"}}}

" Action:
function! s:Selection.move() "{{{1
  let [dir, c, emode] = [self.env.dir, self.env.count, self.env.emode]
  if self.continuous
    silent! undojoin
  endif
  if self.toward ==# '<>' && self.linewise
    " a:dir is '<' or '>', yes its valid Vim operator! so I can pass as-is
    execute "'<,'>" . repeat(dir, c)
    let _last = {
          \ '>': ['^ :+(SW * c)', 'v :+(SW * c)'],
          \ '<': ['^ :-(SW * c)', 'v :-(SW * c)'],
          \ }[dir]
    call self.finish(_last)
  endif

  if dir ==# 'v' " Extend EOF if needed
    let amount = (self.pos['v'].line + c) - line('$')
    if amount > 0
      call append(line('$'), map(range(amount), '""'))
    endif
  endif

  let [ _yank, _last ] = {
        \ "^": ['^ -c:  ', 'v -c:  '],
        \ "v": ['v +c:  ', '^ +c:  '],
        \ ">": ['>   :+c', '<   :+c'],
        \ "<": ['<   :-c', '>   :-c'],
        \ }[dir]
  call self
        \.yank(_yank).modify().paste().finish(_last)
endfunction

function! s:Selection.duplicate() "{{{1
  let action = 'duplicate'
  let [dir, c, emode] = [self.env.dir, self.env.count, self.env.emode]
  call self.yank()

  if self.toward ==# '<>' && self.linewise
    let self.env.c += 1
    call self.modify().paste().finish()
  endif

  if emode ==# 'insert'
    call self.insert_blank(dir, self[self.toward ==# '^v' ? 'height' : 'width'] * c)
  endif

  if emode ==# 'insert'
    let _paste = {
          \ "^": ['v +h*(c-1):        '                   ],
          \ "v": ['^ +h      :        ', 'v +(h*c):      '],
          \ ">": ['<         :+w      ', '>       :+(w*c)'],
          \ "<": ['>         :+w*(c-1)'                   ],
          \ }[dir]
  else
    let _paste = {
          \ "^": ['^ -(h*c):  ', 'v -h    :      '],
          \ "v": ['^ +h    :  ', 'v +(h*c):      '],
          \ ">": ['<       :+w', '>       :+(w*c)'],
          \ "<": ['>       :-w', '<       :-(w*c)'],
          \ }[dir]
  endif
  call self.modify().paste(_paste).finish()
endfunction

function! s:Selection.blank() "{{{1
  call self.insert_blank(self.env.dir, self.env.count)
  " simpley 'normal! gv' is enough tough, I choose,
  " instruction and select() pattern to be consistent
  " to other action.
  "
  let _last = {
        \ "^": [ '^ +c:', 'v +c:'],
        \ "v": [ 'v :           '],
        \ }[self.env.dir]
  call self.finish(_last)
endfunction
"}}}

" Api:
function! textmanip#selection#new(...) "{{{1
  return call(s:Selection.new, a:000, s:Selection)
endfunction
"}}}
" vim: foldmethod=marker
