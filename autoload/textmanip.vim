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
function! s:varea.setup() "{{{
    " call self.shiftwidth_switch()
    call textmanip#register#save("x", "y", "z")
    call self.virtualedit_start()
    if ! textmanip#status#undojoin()
      let b:textmanip_replaced = textmanip#replaced#new(self)
    endif
    let self._replaced = b:textmanip_replaced
endfunction "}}}
function! s:varea.finish() "{{{
    call textmanip#register#restore()
    call self.virtualedit_restore()
    call textmanip#status#update()
    " call self.shiftwidth_restore()
endfunction "}}}
function! s:varea.move(direction) "{{{
  try
    if self.cant_move
      normal! gv
      return
    endif
    call self.setup()
    call self.extend_EOF()

    if self.is_linewise
      call self.move_line()
    else
      call self.move_block()
    endif
    " [FIXME] dirty hack for status management yanking let '< , '> refresh
    normal! "zygv
  finally
    call self.finish()
  endtry
endfunction "}}}             
function! s:varea.move_block() "{{{
  let varea = self._pos_org.dup()
  let c = self._count
  let mode = self._select_mode

  if s:textmanip_current_mode ==# "insert"
    let [ chg, last ] =  { 
          \ "up":   ['u-1, ', 'd-1, ' ],
          \ "down": ['d+1, ', 'u+1, ' ],
          \ "right":['r ,+1', 'l, +1' ],
          \ "left": ['l ,-1', 'r, -1' ],
          \ }[self._direction]
    " (d)own, (u)p, (r)ight, (l)eft
    let meth = self._direction[0] . "_rotate"
    let selected = varea.move(chg).content('block')
    let replace  = join(textmanip#area#new(selected)[meth](c).data(), "\n")
    call setreg("z", replace, getregtype("x"))
    call varea.select(mode)
    normal! "zp
    call varea.move(last).select(mode)
  elseif s:textmanip_current_mode ==# "replace"
    let [ chg, cut_meth, add_meth, last ] =  { 
          \ "up":   ['u-1, ', 'u_cut', 'd_add', 'd-1, ' ],
          \ "down": ['d+1, ', 'd_cut', 'u_add', 'u+1, ' ],
          \ "right":['r ,+1', 'r_cut', 'l_add', 'l, +1' ],
          \ "left": ['l ,-1', 'l_cut', 'r_add', 'r, -1' ],
          \ }[self._direction]

    let selected = varea.move(chg).content('block')
    let area     = textmanip#area#new(selected)
    let rest     = self._replaced[self._direction](area[cut_meth](c))
    let replace  = area[add_meth](rest).data()
    call setreg("z", join(replace,"\n"), getregtype("x"))
    call varea.select(mode)
    normal! "zp
    call varea.move(last).select(mode)
  endif
  call self.visualmode_restore()
endfunction "}}}

function! s:varea.move_line() "{{{
  let c = self._count
  let varea = self._pos_org.dup()                              

  if self._direction =~# '\v^(right|left)$'
    let ward = {'right': ">", 'left': "<" }[self._direction]
    exe "'<,'>" . repeat(ward, c)
    call varea.select(self.mode)
    return                                                     
  endif                                                        
                                                               
  if s:textmanip_current_mode ==# "insert"                     
    let [ chg, last ] =  { 
          \ "up":   ['u-1, ', 'd-1, ' ],
          \ "down": ['d+1, ', 'u+1, ' ],
          \ }[self._direction]

    "(u)_rotate
    let meth = self._direction[0] . "_rotate"
    let replace  = textmanip#area#new(
          \ varea.move(chg).content('line')                      
          \ )[meth](c).data()          
    call setline(varea.u.line(), replace)                                 
    call varea.move(last).select(self._select_mode)                      

  elseif s:textmanip_current_mode ==# "replace"
    let ul = varea.u.line()
    let dl = varea.d.line()
    let [ replace_line, set_line, replace_rule, last ] =  { 
          \ "up":   [ ul-c, ul-c, "selected + rest",  ['u-1, ','d-1, ']],
          \ "down": [ dl+c, ul  , "rest + selected",  ['u+1,', 'd+1, ']],
          \ }[self._direction]
    let selected = varea.content('line')
    let rest     = self._replaced[self._direction](getline(replace_line))
    let replace  = eval(replace_rule)
    call setline(set_line, replace)
    call varea.move(last).select(self._select_mode)
  endif
endfunction "}}}

function! s:varea.shiftwidth_switch() "{{{
  let self._shiftwidth = &sw
  let &sw = g:textmanip_move_ignore_shiftwidth
        \ ? g:textmanip_move_shiftwidth : &sw
endfunction "}}}
function! s:varea.shiftwidth_restore() "{{{
  let &sw = self._shiftwidth
endfunction "}}}
function! s:varea.duplicate_block() "{{{
  call self.virtualedit_start()
  call textmanip#register#save("x","z")

  let c = self._prevcount
  let h = self.height
  let varea = self._pos_org.dup()                              
  let C_v = self._select_mode
  let replace = textmanip#area#new(varea.content('block')).v_duplicate(c).data()
  call setreg("z", join(replace, "\n"), getregtype("x"))

  if s:textmanip_current_mode ==# "insert"
    let blank_lines = map(range(h*c), '""')

    let ul = varea.u.line()
    let dl = varea.d.line()
    let [ blank_target, chg, last ] =  { 
          \ "up":   [ ul-1, '', 'd+'.(h*c-h).', ' ],
          \ "down": [ dl  , ['u+'. h .', ', 'd+'.(h*c).', '], ''],
          \ }[self._direction]
    call append(blank_target, blank_lines)
    call varea.move(chg).select(C_v)
    normal! "zp
    call varea.move(last).select(C_v)

  elseif s:textmanip_current_mode ==# "replace"
    let chg =  { 
          \ "up":   ['u-' . (h*c) . ', ', 'd-' . h . ', '],
          \ "down": ['u+' . h . ', ', 'd+'.(h*c).', ' ],
          \ }[self._direction]
    call varea.move(chg).select(C_v)
    normal! "zp
    call varea.select(C_v)
  endif

  call textmanip#register#restore()
  call self.virtualedit_restore()
endfunction "}}}

function! s:varea.duplicate_line(mode) "{{{
  if a:mode ==# 'n'
    " normal
    let c = self._count
    let line = self.cur_pos[1]
    let col  = self.cur_pos[2]
    let lines = textmanip#area#new(getline(line,line)).v_duplicate(c).data()
    let [target_line, last_line ] = {
          \ "up": [line-1, line ],
          \ "down": [line  , line + c ],
          \ }[self._direction]
    call append(target_line, lines)
    call cursor(last_line, col)
  else
    " visual
    let c     = self._prevcount
    let h     = self.height
    let varea = self._pos_org.dup()
    let selected = varea.content('line')
    let append = textmanip#area#new(selected).v_duplicate(c).data()

    let [target_line, last ] = {
          \ "up": [ varea.u.line() -1 , 'd+' . (h*c-h) . ', ' ],
          \ "down": [varea.d.line() ,['u+' . h . ', ', 'd+'.(h*c).', '] ],
          \ }[self._direction]

    call append(target_line , append)
    call varea.move(last).select(self._select_mode)
    call self.visualmode_restore()
  end
endfun "}}}
function! s:varea.init(direction, mode) "{{{
  let self._prevcount = (v:prevcount ? v:prevcount : 1)
  let self._direction = a:direction
  let self.mode       = visualmode()
  let self.cur_pos    = getpos('.')
  let self._count     = v:count1
  if a:mode ==# 'n' | return | endif

  " current pos
  exe 'normal! gvo' | let s = getpos('.') | exe "normal! " . "\<Esc>"
  exe 'normal! gvo' | let e = getpos('.') | exe "normal! " . "\<Esc>"
" getpos() return [bufnum, lnum, col, off]
" off is offset from actual col when virtual edit(ve) mode,
" so, to respect ve position, we sum "col" + "off"
  let varea = textmanip#selection#new([s[1], s[2] + s[3]], [e[1], e[2] + e[3]] )
  let self._pos_org = varea

  " adjust count
  let self.width  = varea.width()
  let self.height = varea.height()
  let self.is_linewise = (self.mode ==# 'V' )
        \ || (self.mode ==# 'v' && self.height > 1)

  " adjust count
  let max = self._count
  if self._direction ==# 'up'
    let max = varea.u.line() - 1
  elseif self._direction ==# 'left' && !self.is_linewise
    let max = varea.u.col() - 1
  endif
  let self._count = min([max, self._count])

  let self.cant_move = 0
  try
    if self._direction ==# 'up'
      if varea.u.line() ==# 1
        throw "CANT_MOVE"
      endif
    elseif self._direction ==# 'left'
      if self.is_linewise
        if empty(filter(varea.content('line'),"v:val =~# '^\\s'"))
          throw "CANT_MOVE"
        endif
      else
        if varea.u.col() == 1 && self.mode ==# "\<C-v>"
          throw "CANT_MOVE"
        endif
      endif
    endif
  catch /CANT_MOVE/
    let self.cant_move = 1
  endtry
    
  " set useful attribute
  " let self.cant_move =
        " \ ( self._direction ==# 'up' && varea.u.line() ==# 1) ||
        " \ ( self._direction ==# 'left' && ( self.is_linewise && no_space )) ||
        " \ ( self._direction ==# 'left' &&
        " \    (!self.is_linewise && varea.u.col() == 1 && self.mode ==# "\<C-v>" ))
  let self._select_mode = self.mode
  if self.mode ==# 'v'
    let self._select_mode = (self.is_linewise) ? "V" : "\<C-v>"
  endif
endfunction "}}}
function! s:varea.extend_EOF() "{{{
  " even if set ve=all, dont automatically extend EOF
  let amount = (self._pos_org.d.line() + self._count) - line('$')
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
function! textmanip#do(action, direction, mode, ...) "{{{
  call s:varea.init(a:direction, a:mode)
  let s:textmanip_current_mode = ( a:0 > 0 ) ? a:1 : g:textmanip_current_mode

  if a:action ==# 'move'
    call s:varea.move(a:direction)   
  elseif a:action ==# 'dup'
    if char2nr(visualmode()) ==# char2nr("\<C-v>") ||
          \ s:varea.mode ==# 'v' && !s:varea.is_linewise
      call s:varea.duplicate_block()
    else
      call s:varea.duplicate_line(a:mode)
    endif
  endif
endfunction "}}}

function! textmanip#do1(action, direction, mode) "{{{
  try
    let _textmanip_move_ignore_shiftwidth = g:textmanip_move_ignore_shiftwidth
    let _textmanip_move_shiftwidth        = g:textmanip_move_shiftwidth

    let g:textmanip_move_ignore_shiftwidth = 1
    let g:textmanip_move_shiftwidth        = 1
    call textmanip#do(a:action, a:direction, a:mode)
  finally
    let g:textmanip_move_ignore_shiftwidth = _textmanip_move_ignore_shiftwidth
    let g:textmanip_move_shiftwidth        = _textmanip_move_shiftwidth
  endtry
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

" Test:
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
