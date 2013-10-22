let g:textmanip_debug = 0
let s:textmanip = {}

" VisualArea:
"=====================
let s:varea = {}
function! s:varea.init(direction, mode) "{{{
  let self._prevcount = v:prevcount
  let self._count = v:count1
  let self._direction = a:direction
  let self.mode = visualmode()

  let self.cur_pos = getpos('.')
  if a:mode ==# 'n'
    return
  endif

  " current pos
  normal! gvo
  exe "normal! " . "\<Esc>"
  let s = getpos('.')[1:2]
  normal! gvo
  exe "normal! " . "\<Esc>"
  let e = getpos('.')[1:]                             

  if     ((s[0] <= e[0]) && (s[1] <  e[1])) | let case = 1
  elseif ((s[0] >= e[0]) && (s[1] >  e[1])) | let case = 2
  elseif ((s[0] <= e[0]) && (s[1] >  e[1])) | let case = 3
  elseif ((s[0] >= e[0]) && (s[1] <= e[1])) | let case = 4
  endif

  if     case ==# 1 | let [u, d, l, r ] = [ s, e, s, e]
  elseif case ==# 2 | let [u, d, l, r ] = [ e, s, e, s]
  elseif case ==# 3 | let [u, d, l, r ] = [ s, e, e, s]
  elseif case ==# 4 | let [u, d, l, r ] = [ e, s, s, e]
  else
    echo [s, e]
    return
  endif

  let ul = [ u[0], l[1] ]
  let dr = [ d[0], r[1]]
  " let ur = [ u[0], r[1]]
  " let dl = [ d[0], l[1]]
  let self.width  = abs(e[1] - s[1]) + 1
  let self.height = abs(e[0] - s[0]) + 1

  let c = 1
  let self.__c = c
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
        \ }
        " \ "u_mov": [ [ s[0]  , s[1]-c ], [  e[0]  ,  e[1]-c ]],
        " \ "u_mov": [ [ s[0]  , s[1]-c ], [  e[0]  ,  e[1]-c ]],

  " echo PP(self.__table)
  "--------------------------------------------------------------

  " let self.cursor_to = e
  " let self.cursor_fr = s
  " exe "normal! " . self.mode

  " " [lnum, col]
  " let pos1 = getpos("'<")[1:2]
  " let pos2 = getpos("'>")[1:2]

  " " original "{{{
  " if pos1[1] >= pos2[1]
    " let self.start = [pos1[0], pos2[1]]
    " let self.end   = [pos2[0], pos1[1]]
  " else
    " let self.start = pos1
    " let self.end   = pos2
  " endif
  let self.start = ul
  let self.end = dr
  " " up "{{{
  " " let self.up_start = [ self.start[0] - 1 , self.start[1]]
  " " let self.up_end   = [ self.end[0] - 1 , self.end[1]]
  " let self.up_start = copy(self.start)
  " let self.up_end = copy(self.end)
  " let self.up_start[0] -= 1
  " let self.up_end[0] -= 1

  " let self.up_fr    = [ self.cursor_fr[0] - 1 , self.cursor_fr[1]]
  " let self.up_to    = [ self.cursor_to[0] - 1 , self.cursor_to[1]]
  " "}}}
  " " down "{{{
  " let self.down_start = copy(self.start)
  " let self.down_end = copy(self.end)
  " let self.down_start[0] += 1
  " let self.down_end[0] += 1

  " let self.down_fr    = [ self.cursor_fr[0] + 1 , self.cursor_fr[1]]
  " let self.down_to    = [ self.cursor_to[0] + 1 , self.cursor_to[1]]

  " "}}}
  " " right  "{{{
  " let self.right_start = copy(self.start)
  " let self.right_end = copy(self.end)
  " let self.right_start[1] += 1
  " let self.right_end[1] += 1

  " let self.right_fr = [ self.cursor_fr[0] , self.cursor_fr[1] + 1]
  " let self.right_to = [ self.cursor_to[0] , self.cursor_to[1] + 1]
  " " }}}
  " " left "{{{
  " let self.left_start = copy(self.start)
  " let self.left_end = copy(self.end)
  " let self.left_start[1] -= 1
  " let self.left_end[1]   -= 1

  " let self.left_fr = [  self.cursor_fr[0] , self.cursor_fr[1] - 1]
  " let self.left_to = [  self.cursor_to[0] , self.cursor_to[1] - 1]
  " "}}}
  " other "{{{
  " let self.width      = (self.end[1] -  self.start[1]) + 1
  " let self.height     = (self.end[0] -  self.start[0]) + 1
  " let self.is_multiline = (self.start[0] !=# self.end[0])
  "
  let self.is_multiline = (self.height > 1)
  let self.is_linewise =
        \ (self.mode ==# 'V' ) || (self.mode ==# 'v' && self.is_multiline)

  let no_space = empty(filter(getline(ul[0],dr[0]),"v:val =~# '^\\s'"))
  let self.is_eol = self.end[0] ==# line('$')
  let self.cant_move =
        \ ( self._direction ==# 'up' && ul[0] == 1) ||
        \ ( self._direction ==# 'left' && ( self.is_linewise && no_space )) ||
        \ ( self._direction ==# 'left' &&
        \       (!self.is_linewise && ul[1] == 1 ))

  if self.mode ==# 'v'
    if self.is_linewise
      let self._select_mode = "V"
    else
      let self._select_mode = "\<C-v>"
    endif
  else
    let self._select_mode = self.mode
  endif
  "}}}
endfunction "}}}
function! s:varea.extend_eol() "{{{
  if self.is_eol && self._direction ==# 'down'
    call append(line('$'),"")
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

function! s:varea.goto(key) "{{{
  let pos = self[a:key] + [0]
  call cursor(pos)
endfunction "}}}
" select area table {{{
let s:select_area_table = {
      \ "selected"       : ["cursor_fr"  , "cursor_to" ] ,
      \ "up_change"      : ["up_start"   , "end"       ] ,
      \ "up_original"    : ["up_fr"      , "up_to"     ] ,
      \ "down_change"    : ["start"  , "down_end"   ] ,
      \ "down_original"  : ["down_fr"    , "down_to"   ] ,
      \ "right_change"   : ["start"      , "right_end" ] ,
      \ "right_original" : ["right_fr"   , "right_to"  ] ,
      \ "left_change"    : ["left_start" , "end"       ] ,
      \ "left_original"  : ["left_fr"    , "left_to"   ] ,
      \ "up_move"        : ["up_fr"      , "up_to"     ] ,
      \ "down_move"      : ["down_fr"    , "down_to"   ] ,
      \ }
"}}}
let s:varea._table = s:select_area_table

function! s:varea.select(area) "{{{
  " ex) up_change, up_original
  let area = a:area ==# "selected" ? "selected": self._direction ."_". a:area
  echo area
  echo area
  let [s, e] = s:select_area_table[area]
  call self.goto(s)
  execute "normal! " . self._select_mode
  call self.goto(e)
endfunction "}}}

function! s:varea.select_area2(area)
  let area = self._direction[0] . "_" . a:area
  let [s, e] = self.__table[area]
  call cursor(s+[0])
  execute "normal! " . self._select_mode
  call cursor(e+[0])
endfunction

let Varea = s:varea
" function! AreaList(A,L,P)
" return keys(s:varea._table)
" endfunction

" let Varea = s:varea

function! s:varea.move(direction) "{{{
  call self.init(a:direction, 'v')

  if self.cant_move
    normal! gv
    return
  endif
  call s:undo.join()
  call self.virtualedit_start()
  call self.extend_eol()
  call s:register.save("x","z")

  if self.is_linewise
    call self.move_line()
  else
    call self.move_block()
    " [FIXME] dirty hack for status management yanking let '< , '> refresh
    normal! "zygv

  endif
  call s:register.restore()

  call self.virtualedit_restore()
  " call s:undo.update_status()
endfunction "}}}
function! s:varea._replace_text() "{{{
  call self.select_area2("chg")
  normal! "xy
  let selected = split(getreg("x"), "\n")

  let dir = self._direction
  if     dir ==# 'up'   | let s = selected[1:] + [selected[0]]
  elseif dir ==# 'down' | let s = [selected[-1]] + selected[:-2]
  elseif dir ==# 'right'| let s = map(selected,
        \ 'v:val[self.width] . v:val[: self.width-1]')
  elseif dir ==# 'left' | let s = map(selected,
        \ 'v:val[1: self.width] . v:val[0]')
  endif
  return join(s, "\n")
endfunction "}}}
function! s:varea.move_block() "{{{
  " echo self._replace_text()
  call setreg("z", self._replace_text(), getregtype("x"))
  call self.select_area2("chg")
  normal! "zp
  call self.select_area2("org")
  call self.visualmode_restore()
endfunction "}}}

function! s:varea.move_line() "{{{
  let dir = self._direction 

  if     dir ==# "up" || dir ==# "down"
    call self.select_area2("chg")
    normal! "xy
    let selected = split(getreg("x"), "\n")

    if dir ==# 'up'
      let replace = selected[1:] + selected[0:0]
      call setline(self.start[0] - 1, replace)
    elseif dir ==# 'down'
      let replace = selected[-1:-1] + selected[:-2]
      call setline(self.start[0], replace)
    endif
    call self.select_area2("org")
    
    return
    call self.visualmode_restore()
  elseif dir ==# "right"
    exe "'<,'>" . repeat(">",self._count)
    normal! gv
  elseif dir ==# "left"
    exe "'<,'>" . repeat("<",self._count)
    normal! gv
  endif
endfunction "}}}

function! s:varea.duplicate_normal() "{{{
  let cnt = self._count
  call setpos('.', self.cur_pos)
  while cnt != 0
    let pos = getpos('.')
    let line = line('.')
    let address = self._direction == "down" ? line : line - 1
    let cmd = line . "," . line . "copy " . address
    " echo cmd
    silent execute cmd
    let cnt -= 1
  endwhile
  let pos[1] = line('.')
  call setpos('.', pos)
endfunction "}}}

function! s:varea.duplicate() "{{{
  let cnt = self._count
  call setpos('.', self.cur_pos)
  while cnt != 0
    let pos = getpos('.')
    let line = line('.')
    let address = self._direction == "down" ? line : line - 1
    let cmd = line . "," . line . "copy " . address
    " echo cmd
    silent execute cmd
    let cnt -= 1
  endwhile
  let pos[1] = line('.')
  call setpos('.', pos)
endfunction "}}}
function! s:varea.duplicate_visual() "{{{
  call setpos('.', self.cur_pos)
  let pos = getpos('.')
  " let status = s:textmanip_status()
  let loop = self._prevcount ? self._prevcount : 1
  while loop != 0
    let copy_to = self._direction == "down" ? self.end[0] : self.start[0] - 1
    let cmd = self.start[0] . "," . self.end[0] . "copy " . copy_to
    silent execute cmd
    call s:decho("  [executed] " . cmd)
    let loop -= 1
  endwhile
  let cnt = self._prevcount ? self._prevcount : 1
  if self._direction == "down"
    let begin_line = self.end[0] + 1
    let end_line   = self.end[0] + (self.height * cnt)
  elseif self._direction == "up"
    let begin_line = self.start[0]
    echo begin_line
    let end_line   = self.start[0] - 1 + (self.height * cnt)
  endif

  let pos[1] = begin_line
  call setpos('.', pos)
  normal! V
  let pos[1] = end_line
  call setpos('.', pos)
endfun "}}}

function! s:textmanip.duplicate_visual(direction) "{{{
  let pos = getpos('.')
  let status = s:textmanip_status()

  let loop = v:prevcount ? v:prevcount : 1
  while loop != 0
    let copy_to = a:direction == "down"
          \ ? status.end_linenr
          \ : status.start_linenr - 1
    let cmd = status.start_linenr . "," . status.end_linenr . "copy " . copy_to
    silent execute cmd
    call s:decho("  [executed] " . cmd)
    let loop -= 1
  endwhile

  let cnt = v:prevcount ? v:prevcount : 1
  if a:direction == "down"
    let begin_line = status.end_linenr + 1
    let end_line   = status.end_linenr + (status.len * cnt)
  elseif a:direction == "up"
    let begin_line = status.start_linenr
    let end_line   = status.start_linenr - 1 + (status.len * cnt)
  endif

  let pos[1] = begin_line
  call setpos('.', pos)
  normal! V
  let pos[1] = end_line
  call setpos('.', pos)
endfun "}}}

function! s:duplicate_normal(direction) "{{{
  let cnt = v:count1
  while cnt != 0
    let pos = getpos('.')
    let line = line('.')
    let address = a:direction == "down" ? line : line - 1
    let cmd = line . "," . line . "copy " . address
    " echo cmd
    silent execute cmd
    " silent execute line . "," . line . "copy " . address
    let cnt -= 1
  endwhile
  let pos[1] = line('.')
  call setpos('.', pos)
endfunction "}}}

function! s:decho(msg) "{{{
  if g:textmanip_debug
    echo a:msg
  endif
endfunction "}}}
function! s:varea.dump() "{{{
  echo PP(self.__table)
endfunction "}}}

" function! Varea.check_select(area, flg) "{{{
" if a:flg ==# 0
" " echo "normal"
" call cursor(getpos("'s")[1:])
" exe "normal! " . "\<C-v>"
" call cursor(getpos("'e")[1:])
" else
" " echo "opposite"
" call cursor(getpos("'e")[1:])
" exe "normal! " . "\<C-v>"
" call cursor(getpos("'s")[1:])
" end
" normal "_y

" call self.init("up")
" let [s, e] = self._table[a:area]
" echo [a:area, s, e]
" call self.goto(s)
" execute "normal! " . self._select_mode
" call self.goto(e)
" " redraw!
" " redraw!
" endfunction "}}}
" command! -nargs=+ -complete=customlist,AreaList
" \ Check :call Varea.check_select(<f-args>)

" Undo:
"===================== "{{{
let s:undo = {}
function! s:undo.join() "{{{
  if exists("b:textmanip_undo") &&
        \ b:textmanip_undo == self.selected()
    " echo "UNDO JOIN"
    try
      silent undojoin
    catch /E790/
      " after move and exit at the same position(actully at cosmetic level no
      " change you made), and 'u'(undo), then restart move.
      " This read to situation 'undojoin is not allowed after undo' error.
      " But this cannot detect, so simply suppress this error.
    endtry
  endif
endfunction "}}}
function! s:undo.update_status() "{{{
  let b:textmanip_undo = self.selected()
endfunction "}}}
function! s:undo.selected() "{{{
  let content = getline(line("'<"), line("'>"))
  if char2nr(visualmode()) ==# char2nr("\<C-v>")
    let s = col("'<")
    let e = col("'>")
    let content = map(content, 'v:val[s-1:e-1]')
  endif
  let v =  {
        \ 'start_linenr': line("'<"),
        \ 'end_linenr': line("'>"),
        \ 'len': len(content),
        \ 'content': content,
        \ }
  " echo PP(v)
  return v
endfunction "}}}
"}}}
" RegisterManagement:
"===================== "{{{
let s:register = {}
let s:register._data = {}
function! s:register.save(...) "{{{
  for r in a:000
    let s:register._data[r] = { "content": getreg(r, 1), "type": getregtype(r) }
  endfor
endfunction "}}}
function! s:register.restore() "{{{
  for [r, val] in items(self._data)
    call setreg(r, val.content, val.type)
  endfor
  let self._data = {}
endfunction "}}}
"}}}

" Other:
function! s:varea.kickout(num, guide) "{{{
  let orig_str = getline(a:num)
  let s1 = orig_str[ : col('.')- 2 ]
  let s2 = orig_str[ col('.')-1 : ]
  let pad = &textwidth - len(orig_str)
  let pad = ' ' . repeat(a:guide, pad - 2) . ' '
  let new_str = join([s1, pad, s2],'')
  return new_str
endfunction "}}}

" PlublicInterface:
"=================================================================
function! textmanip#move(direction) "{{{
  call s:varea.move(a:direction)
endfunction "}}}

function! textmanip#duplicate(direction, mode) "{{{
  if a:mode ==# "n"
    call s:varea.init(a:direction, 'n')
    call s:varea.duplicate_normal()
  elseif a:mode ==# "v"
    call s:varea.init(a:direction, 'v')
    call s:varea.duplicate_visual()
  endif
endfun "}}}

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

function! textmanip#debug() "{{{
  return PP(s:varea)
endfunction "}}}

" Test
" 111111|BBBBBB|111111
" 000000|AAAAAA|000000
" 666665|FFFFFF|666666
" 777777|CCCCCC|777777
" 888888|DDDDDD|888888
" 222222|000000|222222
" 555556|000000|555555
" 333333|000000|333333
" 444444|EEEEEE|444444
" 000000|HHHHHH|000000
" 111111|LLLLLL|111111
" 333333|NNNNNN|333333
" 444444|OOOOOO|444444

" vim: foldmethod=marker
