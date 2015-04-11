let s:u = textmanip#util#get()

" Util:
function! s:gsub(str,pat,rep) "{{{1
  return substitute(a:str,'\v\C'.a:pat, a:rep,'g')
endfunction

function! s:template(string, data) "{{{1
  " String interpolation from vars Dictionary.
  " ex)
  "   string = "%{L+1}l%{C+2}c" 
  "   data   = { "L+1": 1, "C+2", 2 }
  "   Result => "%1l%2c"
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:data[submatch(1)]', 'g')
endfunction
  " let wv.pattern   = s:template(font.pattern, s:vars([line_s, col], font))
"}}}

" Main:
" @action = [ 'move', 'duplicate', 'blank']
" @direction = [ '^', 'v', '<', '>' ]
" @count = Number
let s:Selection = {}
function! s:Selection.new(s, e, mode, dir) "{{{1
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
  let self.height   = self.pos['B'].line - self.pos['T'].line + 1
  let self.width    = self.pos['R'].colm - self.pos['L'].colm + 1
  let self.linewise = self.is_linewise()
  return self
endfunction

function! s:Selection.is_linewise()
  return 
        \ (self.mode is 'n' ) ||
        \ (self.mode is 'V' ) ||
        \ (self.mode is 'v' && self.height > 1)
endfunction

function! s:Selection.move_pos(ope) "{{{1
  for o in s:u.toList(a:ope)
    if empty(o)
      continue
    endif
    for [k,v] in items(self.vars)
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

function! s:Selection.content(...) "{{{1
  if a:0
    call self.move_pos(a:1)
  endif

  if self.linewise
    let content = getline(self.pos.T.line, self.pos.B.line)
    let R = { "content": content, "regtype": "V" }
  else
    try
      let register = textmanip#register#new()
      call register.save("x")
      silent exe "normal! " . "\<Esc>"
      call self.select()
      silent normal! "xy
      let content = split(getreg("x"), "\n")
      let R = { "content": content, "regtype": getregtype("x") }
    finally
      call register.restore()
    endtry
  endif
  return R
endfunction

function! s:Selection.paste(data) "{{{1
  try
    if a:data.regtype ==# 'V'
      " setline() will not clear visual mode , at least my
      " environment. So ensure return to normal mode before setline()
      exe "normal! \<Esc>"
      " using 'p' is not perfect when data include blankline.
      " It's unnecessarily kindly omit empty blankline when paste!
      " so I choose setline its more precies to original data
      call setline(self.pos.T.line, a:data.content)
    else
      let register = textmanip#register#new()
      call register.save("x")
      let content = join(a:data.content, "\n")
      call setreg("x", content, a:data.regtype)
      normal! "xp
    endif
  finally
    if exists("register")
      call register.restore()
    endif
  endtry
  return self
endfunction

function! s:Selection.insert_blank(dir, num) "{{{1
  let where =
        \ a:dir ==# '^' ? self.pos.T.line-1 :
        \ a:dir ==# 'v' ? self.pos.B.line   :
        \ a:dir ==# '>' ? self.pos.R.colm   :
        \ a:dir ==# '<' ? self.pos.L.colm-1 : throw   
  if self.toward is '<>'
    call append(where, map(range(a:num), '""'))
  else
    let lines = map(getline(self.pos.T.line, self.pos.B.line),
          \ 'v:val[0 : where - 1 ] . repeat(" ", a:num) . v:val[ where : ]')
    call setline(self.pos.T.line, lines)
  endif
  return self
endfunction

function! s:Selection.select(...) "{{{1
  if a:0
    call self.move_pos(a:1)
  endif

  call cursor(self.pos.S.pos()+[0])
  if self.mode !=# 'n'
    execute "normal! " . self.mode
  endif
  call cursor(self.pos.E.pos()+[0])
  return self
endfunction

function! s:Selection.mode_switch() "{{{1
  if self.mode ==# 'v' && !self.linewise
    let self._mode_org = self.mode
    let self.mode = "\<C-v>"
  endif
  return self
endfunction

function! s:Selection.mode_restore() "{{{1
  if has_key(self, "_mode_org")
    let self.mode = self._mode_org
  endif
  return self
endfunction

function! s:Selection.extend_EOF(n) "{{{1
  let amount = (self.pos.B.line + a:n) - line('$')
  if amount > 0
    call append(line('$'), map(range(amount), '""'))
  endif
endfunction

function! s:Selection.replace(dir, content, c) "{{{1
  let area        = textmanip#area#new(a:content)
  let overwritten = area.cut(a:dir, a:c)
  let reveal      = self.replaced.pushout(a:dir, overwritten)
  return area.add(s:u.opposite(a:dir), reveal).data()
endfunction

function! s:Selection.new_replace()
  let self.replaced = textmanip#area#new([])
  let emptyline     = self.linewise ? [''] : [repeat(" ", self.width)]
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

" Action:
function! s:Selection.move(dir, count, emode) "{{{1
  " support both line and block
  let c = a:count
   
  if self.toward is '<>' && self.linewise
    " a:dir is '<' or '>', yes its valid Vim operator! so I can pass as-is
    exe "'<,'>" . repeat(a:dir, c)
    call self.select()
    return
  endif

  if a:dir is 'v'
    call self.extend_EOF(c)
  endif

  let self.vars = { "c": c }
  let [ chg, last ] =  {
        \ "^": [ 'T-c:  ', 'B-c:  ' ],
        \ "v": [ 'B+c:  ', 'T+c:  ' ],
        \ ">": [ 'R  :+c', 'L  :+c' ],
        \ "<": [ 'L  :-c', 'R  :-c' ],
        \ }[a:dir]

  call self.mode_switch()
  let selected = self.content(chg)
  if a:emode ==# 'insert'
    let selected.content =
          \ textmanip#area#new(selected.content).rotate(a:dir, c).data()
  elseif a:emode ==# 'replace'
    let selected.content =
          \ self.replace(a:dir, selected.content, c)
  endif
  call self.select().paste(selected).mode_restore().select(last)
endfunction

function! s:Selection.duplicate(dir, count, emode) "{{{1
  " - normal duplicate(insert/replace) allways linewise
  " - visual duplicate(insert/replace) linewise/blockwise
  if a:dir =~# '<' && self.linewise
    normal! gv
    return
  endif

  let [c, h, w ]  = [a:count, self.height, self.width ]
  if a:dir is '>' && self.linewise
    " dirty hacks
    let c += 1
  endif

  " change mode before yank with content()
  call self.mode_switch()
  let selected = self.content()
  let duplicated = textmanip#area#new(selected.content).duplicate(a:dir, c)
  let selected.content = duplicated.data()
  let self.vars = { 'c': c, 'h': h, 'w': w }

  if a:dir is '>' && self.linewise
    call self.paste(selected).select()
    return
  endif

  if a:emode ==# "insert"
    let [ w_h, chg] =  {
          \ "^": [ "height", 'B+(h*(c-1)):'         ] ,
          \ "v": [ "height", ['T+h: ', 'B+(h*c):'  ]] ,
          \ ">": [ "width" , ['L :+w', 'R :+(w*c)' ]] ,
          \ "<": [ "width" , 'R :+(w*(c-1))'       ] ,
          \ }[a:dir]
    call self.insert_blank(a:dir, duplicated[w_h]()).select(chg).paste(selected)
    if self.mode ==# 'n'
      let where = {
            \ "^": 'T',
            \ "v": 'B',
            \ ">": 'L',
            \ "<": 'R',
            \ }[a:dir]
      call cursor( self.pos[where].pos() )
    else
      call self.mode_restore().select()
    endif
  elseif a:emode ==# "replace"
    let chg =  {
          \ "^": ['T-(h*c):',  'B-h:'],
          \ "v": ['T+h:'    ,  'B+(h*c):' ],
          \ ">": ['L :+w'    , 'R :+(w*c)' ],
          \ "<": ['R :-w'    , 'L :-(w*c)' ],
          \ }[a:dir]

    call self.select(chg)
    call self.paste(selected).mode_restore().select()
  endif
endfunction

function! s:Selection.blank(dir, count, emode) "{{{1
  call self.insert_blank(a:dir, a:count)
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
