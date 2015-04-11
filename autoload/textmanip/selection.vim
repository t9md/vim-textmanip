let s:u = textmanip#util#get()

function! s:gsub(str,pat,rep) "{{{1
  return substitute(a:str,'\v\C'.a:pat, a:rep,'g')
endfunction

let s:selection = {}

function! s:selection.new(s, e, mode) "{{{1
" both `s` and `e` are instance of textmanip#pos

"    T--- s----+----+
"      |  |    |    |
"  height +----+----+  s => start  e => end
"      |  |    |    |  T => Top    B => Bottom
"    B--- +----+----e  L => Left   r => Right
"         |--width--|
"         L         R
  let [s, e]           = [a:s, a:e]
  let [self.s, self.e] = [s, e]
  let self.mode        = a:mode
  let self.vars        = {}

"     [   1   ]    [   2   ]    [   3   ]    [   4   ]
"    s----+----+  e----+----+  +----+----s  +----+----e
"    |    |    |  |    |    |  |    |    |  |    |    |
"    +----+----+  +----+----+  +----+----+  +----+----+
"    |    |    |  |    |    |  |    |    |  |    |    |
"    +----+----e  +----+----s  e----+----+  s----+----+
  let [self.T, self.B, self.L, self.R ] =
        \ 1 && (s.line <= e.line) && (s.colm <= e.colm) ? [ s, e, s, e ] :
        \ 2 && (s.line >= e.line) && (s.colm >= e.colm) ? [ e, s, e, s ] :
        \ 3 && (s.line <= e.line) && (s.colm >= e.colm) ? [ s, e, e, s ] :
        \ 4 && (s.line >= e.line) && (s.colm <= e.colm) ? [ e, s, s, e ] :
        \ throw

  " Preserve original height and width since it's may change while operation
  let self.height = self.B.line - self.T.line + 1
  let self.width  = self.R.colm - self.L.colm + 1

  let self.linewise =
        \ (self.mode ==# 'n' ) ||
        \ (self.mode ==# 'V' ) ||
        \ (self.mode ==# 'v' && self.height > 1)
  return self
endfunction

function! s:selection.move_pos(ope) "{{{1
  let ope = type(a:ope) ==# type([]) ? a:ope : [a:ope]
  for o in ope
    if empty(o) | continue | endif
    for [k,v] in items(self.vars)
      let o = s:gsub(o, k, v)
    endfor
    let p = self._parse(o)
    call self[p.target].move(p.arg[0], p.arg[1])
  endfor
  return self
endfunction

function! s:selection.content(...) "{{{1
  call self.move_pos(a:0 ? a:1 : '')

  if self.linewise
    let content = getline(self.T.line, self.B.line)
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

function! s:selection.paste(data) "{{{1
  try
    if a:data.regtype ==# 'V'
      " setline() will not clear visual mode , at least my
      " environment. So ensure return to normal mode before setline()
      exe "normal! \<Esc>"
      " using 'p' is not perfect when data include blankline.
      " It's unnecessarily kindly omit empty blankline when paste!
      " so I choose setline its more precies to original data
      call setline(self.T.line, a:data.content)
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


function! s:selection.insert_blank(dir, num) "{{{1
  let where =
        \ a:dir ==# '^' ? self.T.line-1 :
        \ a:dir ==# 'v' ? self.B.line   :
        \ a:dir ==# '>' ? self.R.colm   :
        \ a:dir ==# '<' ? self.L.colm-1 : throw
  if s:u.toward(a:dir) is 'V'
    call append(where, map(range(a:num), '""'))
  else
    let lines = map(getline(self.T.line, self.B.line),
          \ 'v:val[0 : where - 1 ] . repeat(" ", a:num) . v:val[ where : ]')
    call setline(self.T.line, lines)
  endif
  return self
endfunction

function! s:selection._parse(s) "{{{1
  let target = a:s[0]
  let arg  = split(a:s[1:], '\v:\s*', 1)
  return {"target" : target, "arg" : arg }
endfunction

function! s:selection.select(...) "{{{1
  call self.move_pos(a:0 ? a:1 : '')

  call cursor(self.s.pos()+[0])
  if self.mode !=# 'n'
    execute "normal! " . self.mode
  endif
  call cursor(self.e.pos()+[0])
  return self
endfunction

function! s:selection.mode_switch() "{{{1
  if self.mode ==# 'v' && !self.linewise
    let self._mode_org = self.mode
    let self.mode = "\<C-v>"
  endif
  return self
endfunction

function! s:selection.mode_restore() "{{{1
  if has_key(self, "_mode_org")
    let self.mode = self._mode_org
  endif
  return self
endfunction

function! s:selection.extend_EOF(n) "{{{1
  let amount = (self.B.line + a:n) - line('$')
  if amount > 0
    call append(line('$'), map(range(amount), '""'))
  endif
endfunction

function! s:selection.move(dir, count, emode) "{{{1
  " support both line and block
  let c = a:count
   
  if s:u.toward(a:dir) is 'H' && self.linewise
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

function! s:selection.dup(dir, count, emode) "{{{1
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
  let duplicated = textmanip#area#new(selected.content).duplicate(s:u.toward(a:dir), c)
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
            \ "^": 'T':
            \ "v": 'B':
            \ ">": 'L':
            \ "<": 'R',
            \ }[a:dir]
      call cursor( self[where].pos() )
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

function! s:selection.blank(dir, count, emode) "{{{1
  call self.insert_blank(a:dir, a:count)
  if !(self.mode ==# 'n')
    normal! gv
  endif
endfunction

function! s:selection.replace(dir, content, c) "{{{1
  let area        = textmanip#area#new(a:content)
  let overwritten = area.cut(a:dir, a:c)
  let reveal      = self.replaced.pushout(a:dir, overwritten)
  return area.add(s:u.opposite(a:dir), reveal).data()
endfunction

function! s:selection.new_replace()
  let self.replaced = textmanip#area#new([])
  let emptyline     = self.linewise ? [''] : [repeat(" ", self.width)]
  return textmanip#area#new(repeat(emptyline, self.height))
endfunction

function! s:selection.state() "{{{1
  " should not depend current visual selction to keep selection state
  " unchanged. So need to extract rectangle region from colum.
  let content = getline(self.T.line, self.B.line)
  if !self.linewise
    let content = getline(self.T.line, self.B.line)
    let content = map(content, 'v:val[ self.L.colm - 1 : self.R.colm - 1]')
  endif
  return  {
        \ 'line_top':    self.T.line,
        \ 'line_bottom': self.B.line,
        \ 'len':         len(content),
        \ 'content':     content,
        \ }
endfunction

" Pulic:
function! textmanip#selection#new(start, end, mode) "{{{1
  return s:selection.new(a:start, a:end, a:mode)
endfunction

function! textmanip#selection#dump() "{{{1
  return s:selection.dump()
endfunction
" vim: foldmethod=marker
