" Util:
let s:_ = textmanip#util#get()

function! s:getpos(mode) "{{{1
  if a:mode ==# 'n'
    let s = getpos('.')
    return [s, s]
  endif
  exe 'normal! gvo' | let s = getpos('.') | exe "normal! \<Esc>"
  exe 'normal! gvo' | let e = getpos('.') | exe "normal! \<Esc>"
  return [s, e]
endfunction
"}}}

" Main:
let s:TM = {}

function! s:TM.start(action, dir, mode, emode) "{{{1
  if &modifiable == 0
      return
  endif
  try
    let opts = { '&virtualedit': 'all' }
    if a:action ==# 'move1'
      let opts['&shiftwidth'] = 1
    elseif g:textmanip_move_ignore_shiftwidth
      let opts['&shiftwidth'] = g:textmanip_move_shiftwidth
    endif
    let options = textmanip#options#replace(opts)

    let env = {
          \ "action": a:action ==# 'move1' ? 'move' : a:action,
          \ "dir":    a:dir,
          \ "mode":   a:mode ==# 'x' ? visualmode() : a:mode,
          \ "emode":  (a:emode ==# 'auto') ? g:textmanip_current_mode : a:emode,
          \ "count":  v:count1,
          \ }
    call self.init(env)
    call self.manip()

  catch /STOP/
    if g:textmanip_debug
      " call Plog(v:exception)
    endif
  catch /FINISH/
  finally
    call self.register.restore()
    call options.restore()
  endtry
endfunction

function! s:TM.init(env) "{{{1
  let [_s, _e]      = s:getpos(a:env.mode)
  let s             = textmanip#pos#new(_s)
  let e             = textmanip#pos#new(_e)
  let self.env      = a:env
  let self.toward   = s:_.toward(self.env.dir)
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

function! s:TM.manip() "{{{1
  call self[self.env.action]()
endfunction

function! s:TM.is_linewise() "{{{1
  return
        \ (self.env.mode ==# 'V' ) ||
        \ (self.env.mode ==# 'n' ) ||
        \ (self.env.mode ==# 'v' && self.height > 1)
endfunction

function! s:TM.finish(...) "{{{1
  call call(self.select, a:000, self)

  if exists('*g:textmanip_hooks.finish')
    call g:textmanip_hooks['finish'](self)
  endif

  if self.env.action ==# 'move'
    let b:textmanip_status = self.state()
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

function! s:TM.stop(desc, expr) "{{{1
  if !a:expr
    return
  endif
  if self.env.mode !=# 'n'
    normal! gv
  endif
  throw 'STOP: ' . a:desc
endfunction

function! s:TM.select(...) "{{{1
  if a:0
    call call(self.move_pos, a:000, self)
  endif
  silent execute "normal! \<Esc>"
  call self.pos.S.set_cursor()
  execute 'normal! ' . (self.linewise ? 'V' : "\<C-v>")
  call self.pos.E.set_cursor()
  return self
endfunction

function! s:TM.yank(...) "{{{1
  call call(self.select, a:000, self)
  call self.register.yank()
  return self
endfunction

function! s:TM.paste(...) "{{{1
  call call(self.select, a:000, self)
  call self.register.paste()
  return self
endfunction

function! s:TM.modify() "{{{1
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

function! s:TM.move_pos(opes) "{{{1
  let vars = { 'c': self.env.count, 'h': self.height, 'w': self.width, 'SW': &sw }
  for ope in s:_.toList(a:opes)
    let pos = ope[0]
    let _ope = split(ope[1:], '\v\s*:\s*', 1)
    call map(_ope, 's:_.template(v:val, vars)')
    call self.pos[pos].move(_ope)
  endfor
  return self
endfunction

function! s:TM.insert_blank(dir, num) "{{{1
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

function! s:TM.state() "{{{1
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
"}}}

" Action:
function! s:TM.move() "{{{1
  let [dir, c, emode] = [self.env.dir, self.env.count, self.env.emode]

  if dir ==# '^'
    call self.stop('Topmost line', self.pos['^'].line ==# 1)
    let self.env.count = min([self.pos['^'].line - 1 , c])
  endif
  if dir ==# '<'
    if self.linewise
      let content = self.yank().register.content
      call self.stop('No empty space to <', empty(filter(content, "v:val =~# '^\\s'")))
    else
      call self.stop('Leftmost cursor', self.pos['<'].colm ==# 1)
      let self.env.count = min([self.pos['<'].colm - 1 , c])
    endif
  endif

  if self.continuous
    silent! undojoin
  endif

  if self.toward ==# '<>' && self.linewise
    " a:dir is '<' or '>', yes its valid Vim operator! so I can pass as-is
    execute self.pos['^'].line . ',' . self.pos['v'].line . repeat(dir,c)
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

function! s:TM.duplicate() "{{{1
  let action = 'duplicate'
  let [dir, c, emode] = [self.env.dir, self.env.count, self.env.emode]
  call self.yank()

  if self.toward ==# '<>' && self.linewise
    let self.env.count += 1
    call self.modify().paste().finish()
  endif

  if emode ==# 'insert'
    call self.insert_blank(dir, self[self.toward ==# '^v' ? 'height' : 'width'] * c)
    let _paste = {
          \ "^": ['v +h*(c-1):        '                   ],
          \ "v": ['^ +h      :        ', 'v +(h*c):      '],
          \ ">": ['<         :+w      ', '>       :+(w*c)'],
          \ "<": ['>         :+w*(c-1)'                   ],
          \ }[dir]
  else
    " replace
    if dir ==# '^'
      call self.stop('No enough space to duplicate to ^', self.pos['^'].line - 1 < self.height)
      let self.env.count = min([ (self.pos['^'].line - 1) / self.height, c ])
    elseif dir ==# '<'
      call self.stop('No enough space to duplicate to <', self.pos['<'].colm - 1 < self.width)
      let self.env.count = min([ (self.pos['<'].colm - 1) / self.width, c ])
    endif

    let _paste = {
          \ "^": ['^ -(h*c):  ', 'v -h    :      '],
          \ "v": ['^ +h    :  ', 'v +(h*c):      '],
          \ ">": ['<       :+w', '>       :+(w*c)'],
          \ "<": ['>       :-w', '<       :-(w*c)'],
          \ }[dir]
  endif
  call self.modify().paste(_paste).finish()
endfunction

function! s:TM.blank() "{{{1
  call self.insert_blank(self.env.dir, self.env.count)
  " simpley 'normal! gv' is enough tough, I choose,
  " instruction and select() pattern to be consistent
  " to other action.
  let _last = {
        \ "^": [ '^ +c:', 'v +c:'],
        \ "v": [ 'v :           '],
        \ }[self.env.dir]
  call self.finish(_last)
endfunction
"}}}

" API:
function! textmanip#start(...) "{{{1
  return call(s:TM.start, a:000, s:TM)
endfunction

function! textmanip#mode(...) "{{{1
  if a:0 ==# 0
    return g:textmanip_current_mode
  endif

  let g:textmanip_current_mode =
        \ g:textmanip_current_mode ==# 'insert' ? 'replace' : 'insert'
  echo "textmanip-mode: " . g:textmanip_current_mode
endfunction
"}}}
" vim: foldmethod=marker
