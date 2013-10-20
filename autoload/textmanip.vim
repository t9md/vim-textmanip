let g:textmanip_debug = 0

" VisualArea:
"=====================
let s:varea = {}
function! s:varea.init(direction) "{{{
  let self._direction = a:direction
  let self.mode = visualmode()
  let self._select_mode = self.mode ==# 'v' ? "\<C-v>" : self.mode

  " [lnum, col]
  let pos1 = getpos("'<")[1:2]
  let pos2 = getpos("'>")[1:2]
  " original "{{{
  if pos1[1] >= pos2[1]
    let self.start = [pos1[0], pos2[1]]
    let self.end   = [pos2[0], pos1[1]]
  else
    let self.start = pos1
    let self.end   = pos2
  endif "}}}
  " up "{{{
  let self.up_start = [self.start[0] - 1 , self.start[1]]
  let self.up_end   = [ self.end[0]  - 1 , self.end[1]]
 "}}}
  " down "{{{
  let self.down_start       = [ self.start[0] + 1 , self.start[1]]
  let self.down_end         = [  self.end[0]  + 1 , self.end[1]]
  let self.down_bottom_left = [  self.end[0]  + 1 , self.start[1]]
 "}}}
  " right  "{{{
  let self.right_start = [  self.start[0], self.start[1] + 1]
  let self.right_end   = [  self.end[0], self.end[1] + 1]
  " }}}
  " left "{{{
  let self.left_start = [  self.start[0], self.start[1] - 1]
  let self.left_end   = [  self.end[0], self.end[1] - 1]
 "}}}
  " other "{{{
  let self.width      = (self.end[1] -  self.start[1]) + 1
  let self.is_multiline = (self.start[0] !=# self.end[0])
  let self.is_linewise =
        \ (self.mode ==# 'V' ) || (self.mode ==# 'v' && self.is_multiline)

  let no_space = empty(filter(getline(self.start[0],self.end[0]),"v:val =~# '^\\s'"))
  let self.is_eol = self.end[0] ==# line('$')
  let self.cant_move =
        \ ( self._direction ==# 'up' && self.start[0] == 1) ||
        \ ( self._direction ==# 'left' && ( self.is_linewise && no_space )) ||
        \ ( self._direction ==# 'left' &&
        \       (!self.is_linewise && self.start[1] == 1 ))
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
let s:select_ara_table = {
      \ "selected"       : ["start"      , "end"       ] ,
      \ "up_replace"     : ["up_start"   , "end"       ] ,
      \ "up_original"    : ["up_start"   , "up_end"    ] ,
      \ "down_replace"   : ["start"      , "down_end"  ] ,
      \ "down_original"  : ["down_start" , "down_end"  ] ,
      \ "right_replace"  : ["start"      , "right_end" ] ,
      \ "right_original" : ["right_start", "right_end" ] ,
      \ "left_replace"   : ["left_start" , "end"       ] ,
      \ "left_original"  : ["left_start" , "left_end"  ] ,
      \ }
"}}}
function! s:varea.select(area) "{{{
  " ex) up_replace, up_original
  let area = a:area ==# "selected" ? "selected": self._direction ."_". a:area
  let [s, e] = s:select_ara_table[area]
  call self.goto(s)
  execute "normal! " . self._select_mode
  call self.goto(e)
endfunction "}}}

function! s:varea.move(direction) "{{{
  call self.init(a:direction)

  if self.cant_move
    normal! gv
    return
  endif
  call s:undo.join()
  call self.virtualedit_start()
  call self.extend_eol()

  if self.is_linewise
    call self.move_line()
  else
    call s:register.save("x","z")
    call self.move_block()
  " [FIXME] dirty hack for status management yanking let '< , '> refresh
    normal! "zygv

    call s:register.restore()
  endif

  call self.virtualedit_restore()
  call s:undo.update_status()
endfunction "}}}
function! s:varea._replace_text() "{{{
  call self.select("replace")
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
  call setreg("z", self._replace_text(), getregtype("x"))
  call self.select("replace")
  normal! "zp
  call self.select("original")
  call self.visualmode_restore()
endfunction "}}}
function! s:varea.move_line() "{{{
  let dir = self._direction 

  " [FIXME] move up/down performance get slow when big file.
  " need improve to swap area so don't use move command!
  if dir ==# 'up'
    let address = self.start[0] - v:count1 - 1
    let address = address < 0 ? 0 : address
  elseif dir ==# 'down'
    let address = self.end[0] + v:count1
    " let eol_extend_size = address - line('$')
    " if eol_extend_size > 0
      " " [FIXME]
      " " call s:extend_eol(eol_extend_size)
    " endif
  endif

  if     dir ==# "up"    | exe "'<,'>move " . address
  elseif dir ==# "down"  | exe "'<,'>move " . address
  elseif dir ==# "right" | exe "'<,'>" . repeat(">",v:count1)
  elseif dir ==# "left"  | exe "'<,'>" . repeat("<",v:count1)
  endif
  normal! gv
endfunction "}}}

function! s:decho(msg) "{{{
  if g:textmanip_debug
    echo a:msg
  endif
endfunction "}}}
function! s:varea.dump() "{{{
  echo PP(self)
endfunction "}}}

" Undo:
"=====================
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

" RegisterManagement:
"=====================
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

" OldObject: neeed rewrite
"=================================================================
let s:textmanip = {}
" Duplicate:
function! s:textmanip_status() "{{{
  let lines = getline(line("'<"), line("'>"))
  return  {
        \ 'start_linenr': line("'<"),
        \ 'end_linenr': line("'>"),
        \ 'lines': lines,
        \ 'len': len(lines),
        \ }
endfunction "}}}
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
function! s:textmanip.duplicate_normal(direction) "{{{
  let cnt = v:count1
  while cnt != 0
    let pos = getpos('.')

    let first_line = line('.')
    let last_line =  line('.')

    let copy_to = a:direction == "down" ? last_line : first_line - 1
    silent execute first_line . "," . last_line . "copy " . copy_to
    let cnt -= 1
  endwhile

  let pos[1] = line('.')
  call setpos('.', pos)
endfunction "}}}
function! s:textmanip.duplicate(direction, mode) "{{{
  if a:mode     ==# "n"
    call self.duplicate_normal(a:direction)
  elseif a:mode ==# "v"
    call self.duplicate_visual(a:direction)
  endif
endfunction "}}}

" Other:
function! s:textmanip.kickout(num, guide) "{{{
  let orig_str = getline(a:num)
  let s1 = strpart(orig_str, 0, col('.') - 1)
  let s2 = strpart(orig_str, col('.') - 1)

  let pad = &textwidth - len(orig_str)
  let pad = ' ' . repeat(a:guide, pad - 2) . ' '
  let new_str = join([s1, pad, s2],'')
  return new_str
endfunction "}}}

" PlublicInterface:
"=================================================================
" Move:
function! textmanip#move(direction) "{{{
  call s:varea.move(a:direction)
endfunction "}}}

" Duplicate:
function! textmanip#duplicate(direction, mode) "{{{
  call s:textmanip.duplicate(a:direction, a:mode)
endfun "}}}

" Other:
function! textmanip#kickout(ask) range "{{{
  let answer = a:ask ? input("guide?:") : ''
  let guide = !empty(answer) ? answer : ' '
  let orig_pos = getpos('.')
  if !(a:firstline == a:lastline)
    normal! gvv
  endif
  for n in range(a:firstline,a:lastline)
    call setline(n, s:textmanip.kickout(n, guide))
  endfor
  call setpos('.', orig_pos)
endfunction "}}}

function! textmanip#debug()
  return PP(s:textmanip)
endfunction

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
