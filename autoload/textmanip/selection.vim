let s:selection = {}

function! s:gsub(str,pat,rep) "{{{1
  return substitute(a:str,'\v\C'.a:pat, a:rep,'g')
endfunction

function! s:selection.new(s, e, mode) "{{{1
"    u--- s----+----+
"      |  |    |    |
"  height +----+----+  s => start  e => end
"      |  |    |    |  u => up     d => downt
"    d--- +----+----e  l => left   r => righ
"         |--width--|
"         l         r
  let self.mode = a:mode
  let self.s = textmanip#pos#new(a:s)
  let self.e = textmanip#pos#new(a:e)
  let self.vars = {}
  let s = self.s
  let e = self.e

"     [ case1 ]    [ case2 ]    [ case3 ]    [ case4 ]
"    s----+----+  e----+----+  +----+----s  +----+----e
"    |    |    |  |    |    |  |    |    |  +    |    |
"    +----+----+  +----+----+  +----+----+  +----+----+
"    |    |    |  |    |    |  |    |    |  |    |    |
"    +----+----e  +----+----s  e----+----+  s----+----+
  let case =
        \ (s.line() <= e.line()) && (s.col() <=  e.col()) ? 1 :
        \ (s.line() >= e.line()) && (s.col() >=  e.col()) ? 2 :
        \ (s.line() <= e.line()) && (s.col() >=  e.col()) ? 3 :
        \ (s.line() >= e.line()) && (s.col() <=  e.col()) ? 4 :
        \ throw

  let [u, d, l, r ] =
        \ case ==# 1 ?  [ s, e, s, e ] :
        \ case ==# 2 ?  [ e, s, e, s ] :
        \ case ==# 3 ?  [ s, e, e, s ] :
        \ case ==# 4 ?  [ e, s, s, e ] :
        \ throw

                 let self.u = u
  let self.l = l       |       let self.r = r
                 let self.d = d

  " pleserve original height and width since it's may change while operation
  let self.height = self.d.line() - self.u.line() + 1
  let self.width  = self.r.col()  - self.l.col()  + 1
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
    let content = getline( self.u.line(), self.d.line() )
    let r = { "content": content, "regtype": "V" }
  else
    try
      let register = textmanip#register#save("x")
      silent exe "normal! " . "\<Esc>"
      call self.select()
      silent normal! "xy
      let content = split(getreg("x"), "\n")
      let r = { "content": content, "regtype": getregtype("x") }
    finally
      call register.restore()
    endtry
  endif
  return r
endfunction

function! s:selection.paste(data) "{{{1
  try
    if a:data.regtype ==# 'V'
      " setline() will not clear visual mode , at least my
      " environment. So ensure return to normal mode before setline()
      exe "normal! " . "\<Esc>"
      " using 'p' is not perfect when date include blankline.
      " It's unnecessarily kindly omit empty blankline when paste!
      " so I choose setline its more precies to original data
      call setline(self.u.line(), a:data.content)
    else
      let register = textmanip#register#save("x")
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
        \ a:dir ==# 'u' ? self.u.line() - 1 :
        \ a:dir ==# 'd' ? self.d.line()     :
        \ a:dir ==# 'r' ? self.r.col()      :
        \ a:dir ==# 'l' ? self.l.col() - 1  : throw
  if a:dir =~# 'd\|u'
    call append(where, map(range(a:num), '""'))
  else
    let lines = map(getline(self.u.line(), self.d.line()),
          \ 'v:val[0 : where - 1 ] . repeat(" ", a:num) . v:val[ where : ]')
    call setline(self.u.line(), lines)
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
  let amount = (self.d.line() + a:n ) - line('$')
  if amount > 0
    call append(line('$'), map(range(amount), '""'))
  endif
endfunction

function! s:selection.move(dir, count, emode) "{{{1
  " support both line and block
  let c = a:count
   
  if a:dir =~# 'r\|l' && self.linewise
    let ward =
          \ a:dir ==# 'r' ? ">" :
          \ a:dir ==# 'l'  ? "<" : throw
    exe "'<,'>" . repeat(ward, c)
    call self.select()
    return
  endif

  if a:dir ==# 'd'
    call self.extend_EOF(c)
  endif

  let self.vars = { "c": c }
  let [ chg, last ] =  {
        \ "u": ['u-c:  ', 'd-c:  ' ],
        \ "d": ['d+c:  ', 'u+c:  ' ],
        \ "r": ['r  :+c', 'l  :+c' ],
        \ "l": ['l  :-c', 'r  :-c' ],
        \ }[a:dir]

  call self.mode_switch()
  let selected = self.content(chg)
  if a:emode ==# 'insert'
    let selected.content =
          \ textmanip#area#new(selected.content)[a:dir ."_rotate"](c).data()
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
  let [c, h, w ]  = [a:count, self.height, self.width ]
  " let dir      = a:dir[0]
  let selected = self.content()
  let ward =
        \ a:dir =~# 'u\|d' ? 'v' :
        \ a:dir =~# 'l\|r' ? 'h' : throw
  let duplicated = textmanip#area#new(selected.content)[ward . "_duplicate"](c)
  let selected.content = duplicated.data()
  let self.vars = { 'c': c, 'h': h, 'w': w }


  if a:dir =~# 'l\|r' && self.linewise
    echo "NOT SUPPORT" "\n"
    normal! gv
    return
  endif

  if a:emode ==# "insert"
    let [ w_h, chg] =  {
          \ "u": [ "height", 'd+(h*(c-1)):'         ] ,
          \ "d": [ "height", ['u+h: ', 'd+(h*c):'  ]] ,
          \ "r": [ "width" , ['l :+w', 'r :+(w*c)' ]] ,
          \ "l": [ "width" , 'r :+(w*(c-1))'       ] ,
          \ }[a:dir]
    call self.insert_blank(a:dir, duplicated[w_h]()).select(chg).paste(selected)
    if self.mode ==# 'n'
      call cursor( self[a:dir].pos() )
    else
      call self.select()
    endif
  elseif a:emode ==# "replace"
    let chg =  {
          \ "u": ['u-(h*c):', 'd-h:'],
          \ "d": ['u+h:'    , 'd+(h*c):' ],
          \ "r": ['l :+w'    , 'r :+(w*c)' ],
          \ "l": ['r :-w'    , 'l :-(w*c)' ],
          \ }[a:dir]
    call self.select(chg)
    call self.paste(selected).select()
  endif
endfunction

function! s:selection.blank(dir, count, emode) "{{{1
  call self.insert_blank(a:dir, a:count)
  if !(self.mode ==# 'n')
    normal! gv
  endif
endfunction

function! s:selection.replace(dir, content, c) "{{{1
  let area  = textmanip#area#new(a:content)
  " opposite direction
  let od  =
        \ a:dir ==# 'u' ? 'd':
        \ a:dir ==# 'd' ? 'u':
        \ a:dir ==# 'l' ? 'r':
        \ a:dir ==# 'r' ? 'l': throw

  let overwritten = area[a:dir . '_cut'](a:c)
  let reveal = self.replaced[a:dir . '_pushout'](overwritten)
  return area[od . '_add'](reveal).data()
endfunction

function! s:selection.new_replace()
  let self.replaced = textmanip#area#new([])
  let emptyline = self.linewise ? [''] : [repeat(" ", self.width)]
  return textmanip#area#new(repeat(emptyline, self.height))
endfunction

function! s:selection.state() "{{{1
  " should not depend current visual selction to keep selection state
  " unchanged. So need to extract rectangle region from colum.
  let content = getline(self.u.line(), self.d.line())
  if !self.linewise
    let content = getline(self.u.line(), self.d.line())
    let content = map(content, 'v:val[ self.l.col() - 1 : self.r.col() - 1]')
  endif
  return  {
        \ 'line_u': self.u.line(),
        \ 'line_d': self.d.line(),
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
