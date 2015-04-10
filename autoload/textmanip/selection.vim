let s:u = textmanip#util#get()

function! s:gsub(str,pat,rep) "{{{1
  return substitute(a:str,'\v\C'.a:pat, a:rep,'g')
endfunction

function! s:toward(dir) "{{{1
  return
        \ a:dir =~#  '\^\|v' ? 'V' :
        \ a:dir =~#   '>\|<' ? 'H' : throw
endfunction

let s:selection = {}

function! s:selection.new(s, e, mode) "{{{1
"    u--- s----+----+
"      |  |    |    |
"  height +----+----+  s => start  e => end
"      |  |    |    |  u => up     d => downt
"    d--- +----+----e  l => left   r => righ
"         |--width--|
"         l         r
  let self.mode = a:mode
  let self.s    = textmanip#pos#new(a:s)
  let self.e    = textmanip#pos#new(a:e)

  " let self.toward = "vertical" or "horizontal"
  " let self.toward = a:dir =~# 'u\|d' ? 'V' :
        " \ a:dir =~# 'l\|r' ? 'H' : throw

  let self.vars = {}
  let s = self.s
  let e = self.e
  let l_s = s.line()
  let l_e = e.line()
  let c_s = s.col()
  let c_e = e.col()

"     [ case1 ]    [ case2 ]    [ case3 ]    [ case4 ]
"    s----+----+  e----+----+  +----+----s  +----+----e
"    |    |    |  |    |    |  |    |    |  +    |    |
"    +----+----+  +----+----+  +----+----+  +----+----+
"    |    |    |  |    |    |  |    |    |  |    |    |
"    +----+----e  +----+----s  e----+----+  s----+----+
  let case =
        \ (l_s <= l_e) && (c_s <= c_e) ? 1 :
        \ (l_s >= l_e) && (c_s >= c_e) ? 2 :
        \ (l_s <= l_e) && (c_s >= c_e) ? 3 :
        \ (l_s >= l_e) && (c_s <= c_e) ? 4 :
        \ throw

  let [self.T, self.B, self.L, self.R ] =
        \ case ==# 1 ?  [ s, e, s, e ] :
        \ case ==# 2 ?  [ e, s, e, s ] :
        \ case ==# 3 ?  [ s, e, e, s ] :
        \ case ==# 4 ?  [ e, s, s, e ] :
        \ throw

  " pleserve original height and width since it's may change while operation
  let self.height = self.B.line() - self.T.line() + 1
  let self.width  = self.R.col()  - self.L.col()  + 1
  let self.linewise =
        \ (self.mode ==# 'n' ) ||
        \ (self.mode ==# 'V' ) ||
        \ (self.mode ==# 'v' && self.height > 1)
  return deepcopy(self)
endfunction

function! s:selection.dump() "{{{1
  return PP([self.s.pos(), self.e.pos()])
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
    let content = getline( self.T.line(), self.B.line() )
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
      call setline(self.T.line(), a:data.content)
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
        \ a:dir ==# '^' ? self.T.line() - 1 :
        \ a:dir ==# 'v' ? self.B.line()     :
        \ a:dir ==# '>' ? self.R.col()      :
        \ a:dir ==# '<' ? self.L.col() - 1  : throw
  if s:toward(a:dir) is 'V'
    call append(where, map(range(a:num), '""'))
  else
    let lines = map(getline(self.T.line(), self.B.line()),
          \ 'v:val[0 : where - 1 ] . repeat(" ", a:num) . v:val[ where : ]')
    call setline(self.T.line(), lines)
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
  let amount = (self.B.line() + a:n ) - line('$')
  if amount > 0
    call append(line('$'), map(range(amount), '""'))
  endif
endfunction

function! s:selection.move(dir, count, emode) "{{{1
  " support both line and block
  let c = a:count
   
  if s:toward(a:dir) is 'H' && self.linewise
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
  " work following case
  " * normal duplicate(insert/replace) allways linewise
  " * visual duplicate(insert/replace) linewise/blockwise
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
  let duplicated = textmanip#area#new(selected.content).duplicate(s:toward(a:dir), c)
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
      call cursor( self[a:dir].pos() )
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
  let content = getline(self.T.line(), self.B.line())
  if !self.linewise
    let content = getline(self.T.line(), self.B.line())
    let content = map(content, 'v:val[ self.L.col() - 1 : self.R.col() - 1]')
  endif
  return  {
        \ 'line_top': self.T.line(),
        \ 'line_bottom': self.B.line(),
        \ 'len': len(content),
        \ 'content': content,
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
