" Selection:
let s:selection = {}
function! s:selection.new(s, e, mode) "{{{
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

  let self.height = self.d.line() - self.u.line() + 1
  let self.width  = self.r.col()  - self.l.col()  + 1
  return deepcopy(self)
endfunction "}}}

function! s:selection.dup() "{{{
  return deepcopy(self)
endfunction "}}}

function! s:selection.dump() "{{{
  return PP([self.s.pos(), self.e.pos()])
endfunction "}}}

function! s:selection.move(ope) "{{{
  let ope = type(a:ope) ==# type([]) ? a:ope : [a:ope]
  for o in ope
    if empty(o) | continue | endif
    let parsed = self._parse(o)
    call self[parsed.meth].move(parsed.arg[0], parsed.arg[1])
  endfor
  " echo parsed
  return self
endfunction "}}}

function! s:selection.content() "{{{
  if ( self.mode ==# 'V') || ( self.mode ==# 'v' && self.height > 1 )
    " linewise
    let content = getline( self.u.line(), self.d.line() )
    let r = { "content": content, "regtype": self.mode }
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
endfunction "}}}

function! s:selection.paste(data) "{{{
  try
    let register = textmanip#register#save("x")
    let content = join(a:data.content, "\n")
    call setreg("x", content, a:data.regtype)
    normal! "xp
  finally
    call register.restore()
  endtry
  return self
endfunction "}}}

function! s:selection._parse(s) "{{{
  let meth = a:s[0]
  let arg  = split(a:s[1:], '\v,\s*', 1)
  return {"meth" : meth, "arg" : arg }
endfunction "}}}

function! s:selection.select() "{{{
  call cursor(self.s.pos()+[0])
  execute "normal! " . self.mode
  call cursor(self.e.pos()+[0])
  return self
endfunction "}}}

function! s:selection._move_block_insert(direction, count) "{{{
  let c = a:count
  " (d)own, (u)p, (r)ight, (l)eft
  let d = a:direction[0]

  let [ chg, last ] =  {
        \ "u": ['u-1, ', 'd-1, ' ],
        \ "d": ['d+1, ', 'u+1, ' ],
        \ "r": ['r ,+1', 'l, +1' ],
        \ "l": ['l ,-1', 'r, -1' ],
        \ }[d]
  let selected = self.move(chg).content()
  let selected.content =
        \ textmanip#area#new(selected.content)[d ."_rotate"](c).data()
  call self.select().paste(selected).move(last).select()
endfunction "}}}

function! s:selection._move_block_replace(direction, count, replace)
  let c = a:count
  let d = a:direction[0]
  let [ chg, cut_meth, add_meth, last ] =  {
        \ "u": ['u-1, ', 'u_cut', 'd_add', 'd-1, ' ],
        \ "d": ['d+1, ', 'd_cut', 'u_add', 'u+1, ' ],
        \ "r": ['r ,+1', 'r_cut', 'l_add', 'l, +1' ],
        \ "l": ['l ,-1', 'l_cut', 'r_add', 'r, -1' ],
        \ }[d]

  let selected = self.move(chg).content()
  let area     = textmanip#area#new(selected.content)
  let rest     = a:replace[a:direction](area[cut_meth](c))
  let selected.content = area[add_meth](rest).data()
  call self.select().paste(selected).move(last).select()
endfunction

function! s:selection.u_move(count) "{{{
  call self._move("up", a:count)
endfunction "}}}

" Pulic:
function! textmanip#selection#new(start, end, mode) "{{{
  return s:selection.new(a:start, a:end, a:mode)
endfunction "}}}
function! textmanip#selection#dump() "{{{
  return s:selection.dump()
endfunction "}}}

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
