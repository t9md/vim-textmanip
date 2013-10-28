" nnoremap <F9> :<C-u>echo textmanip#debug()["_data"]<CR>
nnoremap <F9> :<C-u>echo PP(textmanip#debug()._data)<CR>
xnoremap <F9> <Esc>:<C-u>echo PP(textmanip#debug()._data)<CR>
nnoremap <F9> :<C-u>echo PP(textmanip#debug())<CR>
xnoremap <F9> <Esc>:<C-u>echo PP(textmanip#debug())<CR>
" xnoremap <F9> <Esc>
" xnoremap <F9> :<C-u>echo "HOGEHOGE" <bar>echo "HOGEHOG"<CR>

let g:textmanip_debug = 0
let g:textmanip_move = 'replace'
" nnoremap <F9> :let g:textmanip_debug =
      " \ !g:textmanip_debug <bar>echo g:textmanip_debug<CR>

" CeckList:
"===================== {{{
" restore original vim options
" restore original visual mode
" restore original cursor pos including where 'o'pposit pos in visual mode.
" count reflect result.
" undoable for continuous move by one 'undo' command.
" care when move across corner( TOF,EOF, BOL, EOL )
"  - by adjusting cursor to appropriate value
"  u => TOF
"  d => EOF
"  r => EOL(but ve care this!)
"  l => BOF
"
" Supported: [O: Finish][X: Not Yet][P: Partially impremented]
" * normal_mode:
" [O] duplicate line to above, below
"
" * visual_line('V', or multiline 'v':
" [O] duplicate line to above, below
" [O] move righ/left
" [O] undoable/count
"
" * visual_block(C-v):
" [O] move selected block to up/down/right/left.
"   ( but not multibyte char aware ).
" [X] count support, not undoable
"
"}}}
"
" CusrsorPos Management:
"===================== {{{
"
"     (ul)|--width--|(ur)
"     --- +----+----+      (s)tart  (e)end
"      |  |    |    |      (u)p, (d)own (l)eft, (r)ight
"  height +----+----+      (ul) u/l, (ur) u/r,
"      |  |    |    |      (dl) d/l, (dr) u/l
"     --- +----+----+
"     (dl)           (dr)
"
"          [ case1 ]        [ case2 ]         [ case3 ]        [ case4 ]
"      (1,1) >   >      (1,1)                  <    < (1,3)           (1,3)
"         s----+----+      e----+----+       +----+----s      +----+----e
"         |    |    | V  ^ |    |    |     V |    |    |      +    |    | ^
"         +----+----+      +----+----+       +----+----+      +----+----+
"         |    |    | V  ^ |    |    |     V |    |    |      |    |    | ^
"         +----+----e      +----+----s       e----+----+      s----+----+
"                 (3,3)      <    < (3,3)  (3,1)           (3,1) >    >
"}}}
" BlockMoveSummary:
"======================= {{{
"  c = 1
"  a  = [1, 2, 3]
" Up:
"  a[     : c-1 ] = [1]
"  a[   c :     ] = [2, 3]
"  a[   c :     ] + a[   : c-1 ] = [2, 3, 1]
"
" Down:
"  a[  -1 :     ] = [3]
"  a[     : -2  ] = [1, 2]
"  a[  -1 :     ] + a[   :   -2] = [3, 1, 2]
"
"}}}
" Up_or_Left:
"======================= {{{
"
"    Line                      index
"        +-----------------+   -+-
"     1  |   Replaced      | 0  | count amount
"        +-----------------+   -+-(1 in this example)
"     2  |                 | 1  |
"        +   Original      +    | height
"     3  |   Selection     | 2  |
"        +-----------------+   -+-
"                |
"                | let s = getline(1, 3)
"                |
"                V
"  index    0      1      2            1      2      0
"  idx rev -3     -2     -1           -2     -1     -3
"       +======+------+------+     +------+------+======+
"       |  L1  |  L2  |  L3  | =>  |  L2  |  L3  |  L1  |
"       +======+------+------+     +------+------+======+
"       |-count|--- height---|     |--- height---|-count|
"       s[:c-1]|   s[c:]     |     |   s[c:]  +   s[:c-1]
"       |  |   |      |      |     |      |      |  |   |
"       |  V   |      V      |     |      V      |  V   |
"       |s[:0] |    s[1:]    | =>  |    s[1:]    |s[:0] |
"
"
" "}}}
" Down:
"======================= {{{
"    Line                      index
"        +-----------------+   -+-
"     1  |   Original      | 0  |
"        +   Selection     +    | height
"     2  |                 | 1  |
"        +-----------------+   -+-
"     3  |   Replaced      | 2  | count amount
"        +-----------------+   -+-(1 in this example)
"                |
"                | let s = getline(1, 3)
"                |
"                V
"  index    0      1      2           2      0      1
"  idx rev -3     -2     -1          -1     -3     -2
"       +------+------+======+    +======+------+------+
"       |  L1  |  L2  |  L3  | => |  L3  |  L1  |  L2  |
"       +------+------+======+    +======+------+------+
"       |--- height---|-count|    |-count|--- height---|
"       | s[0:-c-1]   |s[-c:]|    |s[-c:]|  s[ :-c-1]  |
"       |      |      |  |   |    |      |             |
"       |      V      |  V   |    |      |             |
"       | s[0:-2]     |s[-1:]| => |s[-1:]+  s[ :-2]    |
"}}}

" VisualArea:
"=====================
let s:varea = {}
function! s:varea.move(direction) "{{{
  call self.virtualedit_start()
  let self._continue = textmanip#status#undojoin()
                            
  call self.init(a:direction, 'v')
  if !self._continue        
    let b:textmanip_replaced = textmanip#replaced#new(self)
  endif              
  let self._replaced = b:textmanip_replaced

  if self.cant_move
    call self.virtualedit_restore()
    normal! gv
    return
  endif
  call self.extend_EOF()
  call textmanip#register#save("x","z")

  if self.is_linewise
    call self.move_line()
    " [FIXME] dirty hack for status management yanking let '< , '> refresh
    normal! "zygv
  else
    call self.move_block()
    " [FIXME] dirty hack for status management yanking let '< , '> refresh
    normal! "zygv
  endif

  call textmanip#register#restore()
  call self.virtualedit_restore()
  call textmanip#status#update()
endfunction "}}}             
                             
function! s:varea.move_block() "{{{
  if g:textmanip_current_mode ==# "insert"
    call setreg("z", self._replace_text(), getregtype("x"))
    call self.select_area("chg")
    normal! "zp
    call self.select_area("org")
    call self.visualmode_restore()
  elseif g:textmanip_current_mode ==# "replace"
    let c = self._count
    let d = self._direction
    let w = self.width

    call self.select_area("chg")
    normal! "xy
    let _s = split(getreg("x"), "\n")

    if     d ==# 'up'
      let eat = _s[: c-1]
      let orig = _s[c :]
      " throw eat
      let rest = self._replaced.up(eat)
      let replace   = orig + rest
    elseif d ==# 'down'
      let eat  = _s[-c :]
      let orig = _s[: -c-1]
      let rest = self._replaced.down(eat)
      let replace = rest + orig
    elseif d ==# 'right'
      let eat = map(copy(_s), 'v:val[-c :]')
      let orig = map(copy(_s), 'v:val[ : -c-1]')
      let rest = self._replaced.right(eat)
      let replace = map(orig, 'rest[v:key] . v:val')
    elseif d ==# 'left'                                      
      let eat = map(copy(_s), 'v:val[: c-1]')                
      let orig = map(copy(_s), 'v:val[c : ]')
      let rest = self._replaced.left(eat)
      let replace = map(orig, 'v:val . rest[v:key]')
    endif

    call setreg("z", join(replace,"\n"), getregtype("x"))
    call self.select_area("chg")
    normal! "zp
    call self.select_area("org")
    call self.visualmode_restore()
  endif
endfunction "}}}

function! s:varea.move_line() "{{{
  let dir = self._direction

  let c = self._count
  if     dir ==# "up" || dir ==# "down"

    if dir ==# 'up'
      if g:textmanip_current_mode ==# "insert"
        let selected = getline(self.__pos.ul[0]-c, self.__pos.dr[0])
        let replace = selected[ c : ] + selected[ : c-1 ]
        if g:textmanip_debug > 2  "{{{
          echo PP(selected)
          echo len(selected)
          echo '--'
          echo PP(replace)
          echo len(replace)
          return
        endif "}}}
        call setline(self.__pos.ul[0] - c, replace)
      elseif g:textmanip_current_mode ==# "replace"
        let selected  = getline(self.__pos.ul[0], self.__pos.dr[0])
        let rest = self._replaced.up(getline(self.__pos.ul[0]-c))
        let replace   = selected + rest
        call setline(self.__pos.ul[0] - c, replace)
      endif
    elseif dir ==# 'down'
      if g:textmanip_current_mode ==# "insert"
        let selected = getline(self.__pos.ul[0], self.__pos.dr[0]+c)
        let replace = selected[ -c : ] + selected[ : -c-1 ]
        if g:textmanip_debug > 2  "{{{
          echo PP(selected)
          echo len(selected)
          echo '--'
          echo PP(replace)
          echo len(replace)
          return
        endif "}}}
        call setline(self.__pos.ul[0], replace)

      elseif g:textmanip_current_mode ==# "replace"
        let selected  = getline(self.__pos.ul[0], self.__pos.dr[0])
        let rest = self._replaced.down(getline(self.__pos.dr[0]+c))
        let replace   = rest + selected
        call setline(self.__pos.ul[0], replace)
      endif
    endif
    call self.select_area("org")
    call self.visualmode_restore()
  elseif dir ==# "right"
    " if c > 1
      " call self.shiftwidth_switch(1)
    " endif
    exe "'<,'>" . repeat(">",c)
    " if c > 1
      " call self.shiftwidth_restore()
    " endif
    normal! gv
  elseif dir ==# "left"
    exe "'<,'>" . repeat("<",c)
    normal! gv
  endif
endfunction "}}}

function! s:varea.shiftwidth_switch(v) "{{{
  let self._shiftwidth = &shiftwidth
  silent exe "set shiftwidth=" . a:v
endfunction "}}}
function! s:varea.shiftwidth_restore() "{{{
  silent exe "set shiftwidth=".self._shiftwidth
endfunction "}}}

function! s:varea._selct_org() "{{{
  call cursor(self.__pos.ul + [0])
  execute "normal! " . self._select_mode
  call cursor(self.__pos.dr + [0])
endfunction "}}}


function! s:varea.duplicate_block() "{{{
  call self.virtualedit_start()
  call textmanip#register#save("x","z")

  let d = self._direction
  let c = self._prevcount
  let h = self.height
  let s = copy(self.__pos.ul) + [0]
  let e = copy(self.__pos.dr) + [0]

  if g:textmanip_current_mode ==# "insert"
    call self._selct_org()
    normal! "xy

    let target_line = d ==# 'up'
          \ ? self.__pos.ul[0]-1
          \ : self.__pos.dr[0]

    let blank_line = map(range(h*c), '""')
    call append(target_line, blank_line)

    let _str = split(getreg("x"), "\n")
    let _replace = copy(_str)
    for n in range(c)
      let _replace += _str
    endfor
    let replace = join( _replace , "\n")
    call setreg("z", replace, getregtype("x"))

    let e[0] += h*c
    call cursor(s)
    execute "normal! " . self._select_mode
    call cursor(e)

    normal! "zp
    call self.select_area("dup")
  elseif g:textmanip_current_mode ==# "replace"
    call self._selct_org()
    normal! "xy
    let _str = split(getreg("x"), "\n")

    let _replace = copy(_str)
    for n in range(c)
      let _replace += _str
    endfor
    let replace = join( _replace , "\n")
    call setreg("z", replace, getregtype("x"))

    if d ==# 'up'
      let s[0] -= h*c
    elseif d ==# 'down'
      let e[0] += h*c
    endif

    call cursor(s)
    execute "normal! " . self._select_mode
    call cursor(e)

    normal! "zp
    call self.select_area("dup_replace")
  endif

  call textmanip#register#restore()
  call self.virtualedit_restore()
endfunction "}}}

function! s:varea.duplicate_normal() "{{{
  let c    = self._count
  let line = self.cur_pos[1]
  let selected = getline(line)
  let append = map(range(c), 'selected')
  if g:textmanip_debug > 2 "{{{
    echo PP(selected)
    echo '--'
    echo PP(append)
    return
  endif "}}}
  if     self._direction ==# 'up'
    let target_line = line - 1
  elseif self._direction ==# 'down'
    let target_line = line
    let line += c
  endif
  call append(target_line, append)
  call cursor(line, self.cur_pos[2])
endfunction "}}}

function! s:varea.duplicate_visual() "{{{
  " call self.select_area("mov")
  let dir      = self._direction
  let c        = self._prevcount
  let selected = getline(self.__pos.ul[0], self.__pos.dr[0])
  let append   = repeat(selected, c)
  if g:textmanip_debug > 2 "{{{
    echo PP(selected)
    echo len(selected)
    echo '--'
    echo PP(append)
    echo len(append)
    return
  endif "}}}
  let target_line = dir ==# 'up'
        \ ? self.__pos.ul[0]-1
        \ : self.__pos.dr[0]
  call append(target_line, append)
  call self.select_area("dup")
  call self.visualmode_restore()
endfun "}}}


function! s:varea.init(direction, mode) "{{{
  let self._prevcount = (v:prevcount ? v:prevcount : 1)
  let self._direction = a:direction
  let self.mode       = visualmode()
  let self.cur_pos    = getpos('.')
  let self._count     = v:count1
  if a:mode ==# 'n'
    return
  endif
  " echo "pre: " . self._count

  " current pos
  normal! gvo

  let _s = getpos('.')
  exe "normal! " . "\<Esc>"
" getpos() return [bufnum, lnum, col, off]
" off is offset from actual col when virtual edit(ve) mode,
" so to respect ve position, we sum "col" + "off"
  let s = [_s[1], _s[2] + _s[3]]
  normal! gvo
  let _e = getpos('.')
  exe "normal! " . "\<Esc>"
  let e = [_e[1], _e[2] + _e[3]]

  if     ((s[0] <= e[0]) && (s[1] <=  e[1])) | let case = 1
  elseif ((s[0] >= e[0]) && (s[1] >=  e[1])) | let case = 2
  elseif ((s[0] <= e[0]) && (s[1] >=  e[1])) | let case = 3
  elseif ((s[0] >= e[0]) && (s[1] <=  e[1])) | let case = 4
  endif

  if     case ==# 1 | let [u, d, l, r ] = [ s, e, s, e]
  elseif case ==# 2 | let [u, d, l, r ] = [ e, s, e, s]
  elseif case ==# 3 | let [u, d, l, r ] = [ s, e, e, s]
  elseif case ==# 4 | let [u, d, l, r ] = [ e, s, s, e]
  endif

  let ul = [ u[0], l[1] ]     " let ur = [ u[0], r[1]]
  let dr = [ d[0], r[1]]      " let dl = [ d[0], l[1]]

  let pc = self._prevcount
  let w = abs(e[1] - s[1]) + 1
  let h = abs(e[0] - s[0]) + 1

  " adjust count
  let self.width  = w
  let self.height = h
  let self.is_linewise = (self.mode ==# 'V' ) || (self.mode ==# 'v' && h > 1)

  let max = self._count
  if self._direction ==# 'up'
    let max = ul[0]-1
  elseif self._direction ==# 'down'
    " nothing to care
  elseif self._direction ==# 'right'
    " nothing to care
  elseif self._direction ==# 'left'
    if !self.is_linewise
      let max = ul[1]-1
    endif
  endif
  let self._count = min([max, self._count])
  let c = self._count

  " echo "aft: " . self._count

  " define movement/selection table
  let self.__pos = { "s": s, "e": e, "ul": ul, "dr": dr }
  let self.__table = {
        \ "u_chg": [       dr,           [ ul[0]-c, ul[1]   ]],
        \ "d_chg": [       ul,           [ dr[0]+c, dr[1]   ]],
        \ "r_chg": [       ul,           [ dr[0]  , dr[1]+c ]],
        \ "l_chg": [       dr,           [ ul[0]  , ul[1]-c ]],
        \ "u_org": [ [ s[0]-c, s[1]   ], [  e[0]-c,  e[1]   ]],
        \ "d_org": [ [ s[0]+c, s[1]   ], [  e[0]+c,  e[1]   ]],
        \ "r_org": [ [ s[0]  , s[1]+c ], [  e[0]  ,  e[1]+c ]],
        \ "l_org": [ [ s[0]  , s[1]-c ], [  e[0]  ,  e[1]-c ]],
        \ "d_mov": [ [ s[0]+h, s[1]   ], [  e[0]+h,  e[1]   ]],
        \ "u_mov": [ [ s[0]  , s[1]   ], [  e[0]  ,  e[1]   ]],
        \ }
  let u_dup = (s[0] <= e[0])
        \ ? [ [ s[0], s[1]   ], [  e[0]+(h*pc)-h,  e[1]   ]]
        \ : [ [ s[0]+(h*pc)-h, s[1]], [ e[0],  e[1]   ]]
  let d_dup = (s[0] <= e[0])
        \ ? [ [ s[0]+h, s[1]   ], [  e[0]+(h*pc),  e[1]   ]]
        \ : [ [ s[0]+(h*pc), s[1]   ], [ e[0]+h,  e[1]   ]]
  let u_dup_replace = (s[0] <= e[0])
        \ ? [ [ s[0]-(h*c), s[1]   ], [  e[0]-h,  e[1]   ]]
        \ : [ [ s[0]-h, s[1]], [ e[0]-(h*c),  e[1]   ]]

  let self.__table.u_dup = u_dup
  let self.__table.d_dup = d_dup
  let self.__table.u_dup_replace = u_dup_replace
  let self.__table.d_dup_replace = d_dup

  " set useful attribute
  let no_space = empty(filter(getline(ul[0], dr[0]),"v:val =~# '^\\s'"))
  let self.cant_move =
        \ ( self._direction ==# 'up' && ul[0] ==# 1) ||
        \ ( self._direction ==# 'left' && ( self.is_linewise && no_space )) ||
        \ ( self._direction ==# 'left' &&
        \    (!self.is_linewise && ul[1] == 1 && self.mode ==# "\<C-v>" ))
  " throw self.cant_move
  let self._select_mode = self.mode
  if self.mode ==# 'v'
    let self._select_mode = (self.is_linewise) ? "V" : "\<C-v>"
  endif
  " throw string([self._count, self._prevcount])
  " let g:V = self._
endfunction "}}}

function! s:varea.extend_EOF() "{{{
  " even if set ve=all, dont automatically extend EOF
  let amount = (self.__pos.dr[0] + self._count) - line('$')
  if self._direction ==# 'down' && amount > 0
    call append(line('$'), map(range(amount), '""'))
  endif
endfunction "}}}

function! s:varea.visualmode_restore() "{{{
  if self.mode !=# self._select_mode
    exe "normal! " . self.mode
  endif
endfunction "}}}

function! s:varea.virtualedit_start() "{{{
  let self._virtualedit = &virtualedit
  let &virtualedit = 'all'
endfunction "}}}

function! s:varea.virtualedit_restore() "{{{
  let &virtualedit = self._virtualedit
endfunction "}}}

function! s:varea.select_area(area) "{{{
  let area = self._direction[0] . "_" . a:area
  let [s, e] = self.__table[area]
  call cursor(s+[0])
  execute "normal! " . self._select_mode
  call cursor(e+[0])
endfunction "}}}

function! s:varea._replace_text() "{{{
  call self.select_area("chg")
  normal! "xy
  let _s = split(getreg("x"), "\n")

  let c = self._count
  let d = self._direction
  let w = self.width
  if     d ==# 'up'   | let s = _s[c :] +  _s[: c-1]
  elseif d ==# 'down' | let s = _s[-c :] + _s[: -c-1]
  elseif d ==# 'right'| let s = map(_s,'v:val[-c :] . v:val[: -c-1]')
  elseif d ==# 'left' | let s = map(_s,'v:val[c : ] . v:val[:  c-1]')
  endif
  if g:textmanip_debug > 0
    echo c
    echo "-- selected"
    echo PP(_s)
    echo "-- replace"
    echo PP(s)
  endif
  return join(s, "\n")
endfunction "}}}

function! s:decho(msg) "{{{
  if g:textmanip_debug
    echo a:msg
  endif
endfunction "}}}

function! s:varea.dump() "{{{
  echo PP(self.__table)
endfunction "}}}
" }}}

" Other:
"===================== {{{
function! s:varea.kickout(num, guide) "{{{
  let orig_str = getline(a:num)
  let s1 = orig_str[ : col('.')- 2 ]
  let s2 = orig_str[ col('.')-1 : ]
  let pad = &textwidth - len(orig_str)
  let pad = ' ' . repeat(a:guide, pad - 2) . ' '
  let new_str = join([s1, pad, s2],'')
  return new_str
endfunction "}}}
" }}}

" PlublicInterface:
"===================== {{{
function! textmanip#do(action, direction, mode) "{{{
  if a:action ==# 'move'
    call s:varea.move(a:direction)
  elseif a:action ==# 'dup'
    if a:mode ==# "n"
      call s:varea.init(a:direction, 'n')
      call s:varea.duplicate_normal()
    elseif a:mode ==# "v"
      call s:varea.init(a:direction, 'v')
      if char2nr(visualmode()) ==# char2nr("\<C-v>") ||
            \ s:varea.mode ==# 'v' && !s:varea.is_linewise
        call s:varea.duplicate_block()
      else
        call s:varea.duplicate_visual()
      endif
    endif
  endif
endfunction "}}}

" [FIXME] very rough state.
function! textmanip#kickout(guide) range "{{{
  " let answer = a:ask ? input("guide?:") : ''
  let guide = !empty(a:guide) ? a:guide : ' '
  let orig_pos = getpos('.')
  if a:firstline !=# a:lastline
    normal! gv
  endif
  for n in range(a:firstline, a:lastline)
    call setline(n, s:varea.kickout(n, guide))
  endfor
  call setpos('.', orig_pos)
endfunction "}}}

function! textmanip#toggle_mode() "{{{
  let g:textmanip_current_mode =
        \ g:textmanip_current_mode ==# 'insert'
        \ ? 'replace' : 'insert'
  echo "textmanip-mode: " . g:textmanip_current_mode
endfunction "}}}

function! textmanip#mode() "{{{
  return g:textmanip_current_mode
endfunction "}}}

function! textmanip#debug() "{{{
  " return s:replaced
  return PP(s:varea._replaced._data)
endfunction "}}}
" }}}

" Test
" 111111|BBBBBB|111111
" 000000|AAAAAA|000000
" 666665|FFFFFF|666666
" 777777|CCCCCC|777777
" 888888|DDDDDD|888888
" 222222|000000|222222          
" 555556|000000|555555          
" 333333|000000|333333          
" 444444|000000|444444
" 000000|000000|000000
" 111111|000000|111111
" 333333|NNNNNN|333333
" 444444|OOOOOO|444444
               
" vim: foldmethod=marker
               
               
               
