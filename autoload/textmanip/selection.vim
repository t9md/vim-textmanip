let s:u = textmanip#util#get()

" Util:
function! s:gsub(str,pat,rep) "{{{1
  return substitute(a:str,'\v\C'.a:pat, a:rep,'g')
endfunction

function! s:template(string, vars) "{{{1
  " String interpolation from vars Dictionary.
  " ex)
  "   string = "%{L+1}l%{C+2}c" 
  "   data   = { "L+1": 1, "C+2", 2 }
  "   Result => "%1l%2c"
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction
"}}}

" Main:
" @action = [ 'move', 'duplicate', 'blank']
" @direction = [ '^', 'v', '<', '>' ]
" @count = Number
let s:Selection = {} 

function! s:Selection.new(s, e, mode, dir) "{{{1
  "DONE:
  " both `s` and `e` are instance of textmanip#pos

  let [s, e]      = [a:s, a:e]
  let self.pos    = {}
  let self.pos    = { 'S': s, 'E': e }
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
  let [top, bottom, left, right] =
        \ 1 && (s.line <= e.line) && (s.colm <= e.colm) ? [ s, e, s, e ] :
        \ 2 && (s.line >= e.line) && (s.colm >= e.colm) ? [ e, s, e, s ] :
        \ 3 && (s.line <= e.line) && (s.colm >= e.colm) ? [ s, e, e, s ] :
        \ 4 && (s.line >= e.line) && (s.colm <= e.colm) ? [ e, s, s, e ] :
        \ throw
  call extend(self.pos, { 'T': top, 'B': bottom, 'L': left, 'R': right })

  " Preserve original height and width since it's may change while operation
  let self.toward   = s:u.toward(a:dir)
  let self.height   = self.pos.B.line - self.pos.T.line + 1
  let self.width    = self.pos.R.colm - self.pos.L.colm + 1
  let self.linewise = self.is_linewise()

  return self
endfunction

function! s:Selection.is_linewise()
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
  if self.linewise
    " CAUTION: `y` ignore blank-line, need to use getline().
    return {
          \ "content": getline( self.pos.T.line, self.pos.B.line),
          \ "regtype": "V"
          \ }
  endif

  try
    let reg = textmanip#register#save('x')
    silent execute "normal! \<Esc>"
    call self.select()
    if self.mode ==# 'n'
      silent execute 'normal! "xyy'
    else
      silent execute 'normal! "xy'
    endif
    return {
          \ "content": split(getreg('x'), "\n"),
          \ "regtype": getregtype('x')
          \ }
  finally
    call reg.restore()
  endtry
endfunction

function! s:Selection.paste(data) "{{{1
  if a:data.regtype ==# 'V'
    execute "normal! \<Esc>"

    " Using 'p' is not perfect when data include blank-line.
    " It's unnecessarily omit empty blank-line when paste.
    " So I choose setline() to respect blank-line.
    call setline(self.pos.T.line, a:data.content)
    return self
  endif

  try
    let reg = textmanip#register#save('x')
    call setreg('x',
          \ join(a:data.content, "\n"),
          \ a:data.regtype)
    silent execute 'normal! "xp'
    return self
  finally
    call reg.restore()
  endtry
endfunction

function! s:Selection.move_pos(ope, vars) "{{{1
  for o in s:u.toList(a:ope)
    if empty(o)
      continue
    endif
    for [k,v] in items(a:vars)
      let o = s:gsub(o, k, v)
    endfor
    let p = self._parse(o)
    call self.pos[p.where].move(p.arg[0], p.arg[1])
  endfor
  return self
endfunction

function! s:Selection._parse(s) "{{{1
  let where = a:s[0]
  let arg   = split(a:s[1:], '\v:\s*', 1)
  return {"where" : where, "arg" : arg }
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


function! s:Selection.new_replace()
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
function! s:Selection.move(dir, count, emode) "{{{1
  " support both line and block
  let c = a:count
  if self.toward ==# '<>' && self.linewise
    " a:dir is '<' or '>', yes its valid Vim operator! so I can pass as-is
    execute "'<,'>" . repeat(a:dir, c)
    call self.select()
    return
  endif

  if a:dir ==# 'v'
    " Extend EOF
    let amount = (self.pos.B.line + c) - line('$')
    if amount > 0
      call append(line('$'), map(range(amount), '""'))
    endif
  endif

  let vars = { "c": c }
  let [ before, after ] =  {
        \ "^": [ 'T-c:  ', 'B-c:  ' ],
        \ "v": [ 'B+c:  ', 'T+c:  ' ],
        \ ">": [ 'R  :+c', 'L  :+c' ],
        \ "<": [ 'L  :-c', 'R  :-c' ],
        \ }[a:dir]

  call self.move_pos(before, vars)
  let Y = self.yank()

  if a:emode ==# 'insert'
    let Y.content = textmanip#area#new(Y.content).rotate(a:dir, c).data()
    call self.select()
          \.paste(Y)
          \.move_pos(after, vars)
          \.select()
    return
  endif

  if a:emode ==# 'replace'
    let area        = textmanip#area#new(Y.content)
    let overwritten = area.cut(a:dir, c)
    let reveal      = self.replaced.pushout(a:dir, overwritten)
    call area.add(s:u.opposite(a:dir), reveal)
    let Y.content = area.data()
    call self.select()
          \.paste(Y)
          \.move_pos(after, vars)
          \.select()
    return
  endif
endfunction

function! s:Selection.duplicate(dir, count, emode) "{{{1
  if a:dir =~# '<' && self.linewise
    " Nothing to do
    normal! gv
    return
  endif

  let _count = a:count
  if a:dir ==# '>' && self.linewise
    " dirty hacks
    let _count += 1
  endif

  let Y = self.yank()
  let area       = textmanip#area#new(Y.content)
  let duplicated = area.duplicate(a:dir, _count)
  let Y.content = duplicated.data()

  if a:dir ==# '>' && self.linewise
    call self.paste(Y).select()
    return
  endif

  let vars = { 'c': _count, 'h': self.height, 'w': self.width }
  if a:emode ==# "insert"
    let [ w_h, before] =  {
          \ "^": [ "height", 'B+(h*(c-1)):'         ] ,
          \ "v": [ "height", ['T+h: ', 'B+(h*c):'  ]] ,
          \ ">": [ "width" , ['L :+w', 'R :+(w*c)' ]] ,
          \ "<": [ "width" , 'R :+(w*(c-1))'       ] ,
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
          \ "^": ['T-(h*c):',  'B-h:'],
          \ "v": ['T+h:'    ,  'B+(h*c):' ],
          \ ">": ['L :+w'    , 'R :+(w*c)' ],
          \ "<": ['R :-w'    , 'L :-(w*c)' ],
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

function! textmanip#selection#dump() "{{{1
  return s:Selection.dump()
endfunction
" vim: foldmethod=marker
