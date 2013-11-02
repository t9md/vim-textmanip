let s:selection = {}
function! s:gsub(str,pat,rep) "{{{1
  return substitute(a:str,'\v\C'.a:pat, a:rep,'g')
endfunction

function! s:selection.new(s, e, mode) "{{{1
" 4 Selection cases {{{
"
"    u--- s----+----+
"      |  |    |    |
"  height +----+----+  s => start  e => end
"      |  |    |    |  u => up     d => downt
"    d--- +----+----e  l => left   r => righ
"         |--width--|
"         l         r
"
"     [ case1 ]        [ case2 ]         [ case3 ]        [ case4 ]
" (1,1) >   >      (1,1)                  <    < (1,3)           (1,3)
"    s----+----+      e----+----+       +----+----s      +----+----e
"    |    |    | V  ^ |    |    |     V |    |    |      +    |    | ^
"    +----+----+      +----+----+       +----+----+      +----+----+
"    |    |    | V  ^ |    |    |     V |    |    |      |    |    | ^
"    +----+----e      +----+----s       e----+----+      s----+----+
"            (3,3)      <    < (3,3)  (3,1)           (3,1) >    >
" }}}
  let self.mode = a:mode
  let self.s = textmanip#pos#new(a:s)
  let self.e = textmanip#pos#new(a:e)
  let self.vars = {}
  let s = self.s
  let e = self.e

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

function! s:selection.dup() "{{{1
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
      call self.select()
      normal! "xy
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

function! s:selection._parse(s) "{{{1
  let target = a:s[0]
  let arg  = split(a:s[1:], '\v:\s*', 1)
  return {"target" : target, "arg" : arg }
endfunction

function! s:selection.select(...) "{{{1
  call self.move_pos(a:0 ? a:1 : '')

  call cursor(self.s.pos()+[0])
  execute "normal! " . self.mode
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

function! s:selection.move(direction, count, emode) "{{{1
  " support both line and block
  let c = a:count
  " (d)own, (u)p, (r)ight, (l)eft
  let d = a:direction[0]
  let self.vars = { "c": c }
  let [ chg, last ] =  {
        \ "u": ['u-c:  ', 'd-c:  ' ],
        \ "d": ['d+c:  ', 'u+c:  ' ],
        \ "r": ['r  :+c', 'l  :+c' ],
        \ "l": ['l  :-c', 'r  :-c' ],
        \ }[d]

  call self.mode_switch()
  let selected = self.content(chg)
  if a:emode ==# 'insert'
    let selected.content =
          \ textmanip#area#new(selected.content)[d ."_rotate"](c).data()
  elseif a:emode ==# 'replace'
    let selected.content =
          \ self.replace(a:direction, selected.content, c)
  endif
  call self.select().paste(selected).mode_restore().select(last)
endfunction

function! s:selection.replace(direction, content, c) "{{{1
  let d = a:direction[0]
  let area  = textmanip#area#new(a:content)
  " opposite direction
  let [ od ] =
        \ d ==# 'u' ? [ 'd' ]:
        \ d ==# 'd' ? [ 'u' ]:
        \ d ==# 'l' ? [ 'r' ]:
        \ d ==# 'r' ? [ 'l' ]: throw

  let overwritten = area[d . '_cut'](a:c)
  let reveal = self.replaced[d . '_pushout'](overwritten)
  return area[od . '_add'](reveal).data()
endfunction

function! s:selection.new_replace()
  let self.replaced = textmanip#area#new([])
  let emptyline = self.linewise ? [''] : [repeat(" ", self.width)]
  return textmanip#area#new(repeat(emptyline, self.height))
endfunction


" Pulic:
function! textmanip#selection#new(start, end, mode) "{{{1
  return s:selection.new(a:start, a:end, a:mode)
endfunction

function! textmanip#selection#dump() "{{{1
  return s:selection.dump()
endfunction

" Test:
finish

" # Pos should be specified in relation to [start, pos]
"  ## move
"  +------------------------------------------------------+
"  |  block  |     change,  |           last              |
"  +---------+--------------+-----------------------------|
"  |  move-u | u-[ -1,    ] |  u-[ -1,    ], d-[ -1,    ] |
"  +---------+--------------+----+------------------------|
"  |  move-d | d-[ +1,    ] |  u-[ +1,    ], d-[ +1,    ] |
"  +---------+--------------+----+------------------------|
"  |  move-r | -r[   , +1 ] |  -r[   , +1 ], -r[   , +1 ] |
"  +---------+--------------+----+------------------------|
"  |  move-l | -l[   , -1 ] |  -l[   , -1 ], -l[   , -1 ] |
"  +------------------------------------------------------+
"  +------------------------------------------------------+
"  |  line   |     change,   |           last             |
"  +---------+---------------+----------------------------|
"  |  move-u | u-[ -1,    ]  | u-[ -1,    ], d-[ -1,    ] |
"  +---------+---------------+----------------------------|
"  |  move-d | d-[ +1,    ]  | u-[ +1,    ], d-[ +1,    ] |
"  +---------+---------------+----------------------------|
"  |  move-r |     N/A       |           N/A              |
"  +---------+---------------+----------------------------|
"  |  move-l |     N/A       |           N/A              |
"  +------------------------------------------------------+
"
"  # dup
"  +------------------------------------------------------+
"  |  block  |     change,   |           last             |
"  +---------+---------------+----------------------------|
"  |   dup-u | u-[   ,    ]  | u[ ,   ], d-[ +h*(c-1), ]  |
"  +---------+---------------+----------------------------|
"  |   dup-d | d-[ +h,    ]  | u-[ +1,    ], d-[ +1,    ] |
"  +---------+---------------+----------------------------|
"  |   dup-r |     N/A       |           N/A              |
"  +---------+---------------+----------------------------|
"  |   dup-l |     N/A       |           N/A              |
"  +------------------------------------------------------+
"
" [line] "{{{
" move-u  ul[ "-1", "" ]   ul["-1", ""], dr["-1", ""]
" move-d  ul[ "+1", "" ]   ul["+1", ""], dr["+1", ""]
" move-r  N/A
" move-l  N/A "}}}

" ## dup
" [block]    change,           last
" dup-u  ul[ "-h", "" ]   ul["-h", ""], dr["-h", ""]
" dup-d  ul[ "+h", "" ]   ul["+h", ""], dr["+h", ""]
" dup-r  ul[ "", "+w" ]   ul["", "+w"], dr["", "+w"]
" dup-l  ul[ "", "-w" ]   ul["", "-w"], dr["", "-w"]
" [line]
" dup-u  ul[ "-h", "" ]   ul["-h", ""], dr["-h", ""]
" dup-d  ul[ "+h", "" ]   ul["+h", ""], dr["+h", ""]
" dup-r  N/A
" dup-l  N?A

" vim: foldmethod=marker
