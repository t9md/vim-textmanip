" Util:
let s:u = textmanip#util#get()

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

function! s:Selection.select() "{{{1
  " DONE:
  call cursor(self.pos.S.pos()+[0])

  if self.mode ==# 'n'
    return self
  endif

  let mode =
        \ self.mode ==# 'v' ? ( self.height ==# 1 ? "\<C-v>" : 'V' ) :
        \ self.mode

  execute 'normal! ' . mode
  call cursor(self.pos.E.pos()+[0])
  return self
endfunction

function! s:Selection.yank() "{{{1
  " DONE:
  try
    let reg = textmanip#register#save('x')
    silent execute "normal! \<Esc>"
    call self.select()
    if self.mode ==# 'n'
      silent execute 'normal! "xyy'
    else
      silent execute 'normal! "xy'
    endif

    let regtype = getregtype('x')
    let content =  split(getreg('x'), "\n", 1)
    " if linewise, content have empty string('') entry at end of List.
    if regtype ==# 'V'
      let content =  content[0:-2]
    endif
    return {
          \ "content": content, 
          \ "regtype": regtype,
          \ }
  finally
    call reg.restore()
  endtry
endfunction

function! s:Selection._paste(data, cmd) "{{{1
  try
    let reg = textmanip#register#save('x')
    call setreg('x', a:data.content, a:data.regtype)
    silent execute 'normal! "x' . a:cmd
    return self
  finally
    call reg.restore()
  endtry
endfunction

function! s:Selection.paste(data) "{{{1
  return self._paste(a:data, 'p')
endfunction

function! s:Selection.p(data) "{{{1
  return self._paste(a:data, 'p')
endfunction

function! s:Selection.P(data) "{{{1
  return self._paste(a:data, 'P')
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

  let vars = { "c": a:c }
  let [ before, after ] =  {
        \ "^": [ 'T -c:  ', 'B -c:  ' ],
        \ "v": [ 'B +c:  ', 'T +c:  ' ],
        \ ">": [ 'R   :+c', 'L   :+c' ],
        \ "<": [ 'L   :-c', 'R   :-c' ],
        \ }[a:dir]

  call self.move_pos(before, vars)
  let Y    = self.yank()
  let args = [Y.content]
  if a:emode ==# 'replace'
    let args += [self.replaced]
  endif
  let Y.content = call('textmanip#area#new', args).rotate(a:dir, a:c).data()

  call self.select().paste(Y).move_pos(after, vars).select()
endfunction


function! s:Selection.duplicate(dir, c, emode) "{{{1
  let Y = self.yank()
  " let area       = textmanip#area#new(Y.content)
  " let duplicated = area.duplicate(a:dir, a:c)
  " let Y.content = duplicated.data()

  let vars = { 'c': a:c, 'h': self.height, 'w': self.width }
  if a:emode ==# "insert"
    if self.linewise
      if a:dir ==# '^'
        let Y.content = textmanip#area#new(Y.content).duplicate('v', a:c).data()
        call self.cursor('T').P(Y).move_pos('B +h*(c-1):', vars).select()
        return
      endif

      if a:dir ==# 'v'
        let Y.content = textmanip#area#new(Y.content).duplicate('v', a:c).data()
        call self.cursor('B').p(Y).move_pos(['T +h:', 'B +h*c:'], vars).select()
        return
      endif

      if a:dir ==# '<'
        call self.select()
        return
      endif

      if a:dir ==# '>'
        let Y.content = textmanip#area#new(Y.content).duplicate('>', a:c +1).data()
        call self.select().p(Y).select()
        return
      endif
    else
      if a:dir ==# '^'
        let Y.content = textmanip#area#new(Y.content).duplicate('v', a:c).data()
        call self.insert_blank('^', self.height*a:c)
        call self.move_pos('B +h*(c-1):', vars).select().p(Y).select()
        return
      endif

      if a:dir ==# 'v'
        let Y.content = textmanip#area#new(Y.content).duplicate('v', a:c).data()
        call self.insert_blank('v', self.height*a:c)
        call self.move_pos(['T +h:', 'B +(h*c):'], vars).select().p(Y).select()
        return
      endif
    endif

    let [ w_h, before] =  {
          \ "^": [ "height", ['B +(h*(c-1)):          '                   ]],
          \ "v": [ "height", ['T +h        :          ', 'B +(h*c):      ']],
          \ ">": [ "width" , ['L           :+w        ', 'R       :+(w*c)']],
          \ "<": [ "width" , ['R           :+(w*(c-1))'                   ]],
          \ }[a:dir]
    call self.insert_blank(a:dir, duplicated[w_h]())
          \.move_pos(before, vars)
          \.select()
          \.paste(Y)
    if self.mode ==# 'n'
      let where = { "^": 'T', "v": 'B', ">": 'L', "<": 'R', }[a:dir]
      call cursor(self.pos[where].pos())
    else
      call self.select()
    endif
    return 
  endif

  if a:emode ==# "replace"
    let before =  {
          \ "^": ['T -(h*c):  ', 'B -h    :      '],
          \ "v": ['T +h    :  ', 'B +(h*c):      '],
          \ ">": ['L       :+w', 'R       :+(w*c)'],
          \ "<": ['R       :-w', 'L       :-(w*c)'],
          \ }[a:dir]

    call self.move_pos(before, vars)
          \.select()
          \.paste(Y)
          \.select()
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
