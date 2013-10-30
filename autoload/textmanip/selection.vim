" Selection:
let s:selection = {}
function! s:selection.new(s, e) "{{{
  let s = a:s
  let e = a:e
  if     ((s[0] <= e[0]) && (s[1] <=  e[1])) | let case = 1
  elseif ((s[0] >= e[0]) && (s[1] >=  e[1])) | let case = 2
  elseif ((s[0] <= e[0]) && (s[1] >=  e[1])) | let case = 3
  elseif ((s[0] >= e[0]) && (s[1] <=  e[1])) | let case = 4
  endif

  let self.s = textmanip#pos#new(s)
  let self.e = textmanip#pos#new(e)
  let ps = self.s
  let pe = self.e

  if     case ==# 1 | let [u, d, l, r ] = [ ps, pe, ps, pe ]
  elseif case ==# 2 | let [u, d, l, r ] = [ pe, ps, pe, ps ]
  elseif case ==# 3 | let [u, d, l, r ] = [ ps, pe, pe, ps ]
  elseif case ==# 4 | let [u, d, l, r ] = [ pe, ps, ps, pe ]
  endif
                 let self.u = u
  let self.l = l                let self.r = r 
                 let self.d = d

  return deepcopy(self)
endfunction "}}}

function! s:selection.width() "{{{
  return self.d.col() - self.u.col() + 1
endfunction "}}}
function! s:selection.height() "{{{
  return self.r.line() - self.l.line() + 1
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
    let parsed = self._parse(o)
    call self[parsed.meth].move(parsed.arg[0], parsed.arg[1])
  endfor
  " echo parsed
  return self
endfunction "}}}

function! s:selection.content(wise) "{{{
  if a:wise ==# 'line'
    let content = getline( self.u.pos()[0], self.d.pos()[0])
  elseif a:wise ==# 'block'
    call self.select("\<C-v>")
    " FIXME
    normal! "xy
    let content = split(getreg("x"), "\n")
  endif
  return content
endfunction "}}}

function! s:selection._parse(s) "{{{
  let meth = a:s[0]
  let arg  = split(a:s[1:], '\v,\s*', 1)
  return {"meth" : meth, "arg" : arg }
endfunction "}}}

function! s:run(s) "{{{
  " echo a:s
  let operations = type(a:s) ==# type([]) ? a:s : [a:s]
  for ope in operations
    call s:parse(ope)
  endfor
endfunction "}}}

function! s:selection.select(select_mode) "{{{
  call cursor(self.s.pos()+[0])
  execute "normal! " . a:select_mode
  call cursor(self.e.pos()+[0])
endfunction "}}}

" Pulic:
function! textmanip#selection#select(select_mode) "{{{
  call s:selection.select(a:select_mode)
endfunction "}}}
function! textmanip#selection#new(start, end) "{{{
  return s:selection.new(a:start, a:end)
endfunction "}}}
function! textmanip#selection#dump() "{{{
  return s:selection.dump()
endfunction "}}}


" Test:
finish
" call Test("case2", [66,23], [61,11]) "{{{
" call Test("case3", [61,11], [66,23])
" call Test("case3", [66,23], [61,11])
" call Test("case4", [61,11], [66,23])
" "}}}
let Area = {}
function! Area.init()
  normal! gvo
  let _s = getpos('.')
  exe "normal! " . "\<Esc>"
  let s = [_s[1], _s[2] + _s[3]]
  normal! gvo
  let _e = getpos('.')
  exe "normal! " . "\<Esc>"
  let e = [_e[1], _e[2] + _e[3]]
  let self._pos_org = textmanip#selection#new(s, e)
endfunction
function! Area.run()
  call self.init()
  let pos = deepcopy(self._pos_org)
  let selected = pos.move("u-1, ").content('line')
  let area = textmanip#area#new(selected)
  let up = area.u_cut(1)
  " let replace = selected[ 1 : ] + selected[ : 1-1 ]
  let replace = area.data() + up
  call setline(pos.u.pos()[0], replace)
endfunction

" xnoremap <C-k> :<C-u>call Area.run()<CR>
finish
function! Test(action, s, e) "{{{
  let b_v = "\<C-v>"
  " let b_v = "V"
  "
  let wise =  b_v ==# "\<C-v>" ? "blockwise" : "linewise"

  echo "-- " . a:action
  let org = textmanip#selection#new(a:s, a:e)
  " let chg = deepcopy(org)
  " let lst = deepcopy(org)

  call org.select(b_v) | call s:show()
  for area in ["change", "last"]
    call deepcopy(org).move(s:area[wise][a:action][area]).select(b_v)
    call s:show()
    " call chg.move("u-1, ").select(b_v) | call s:show()
    " call org.move(['u-1,  ', 'd-1,  ']).select(b_v) | call s:show()
  endfor
endfunction "}}}


function! s:show() "{{{
  redraw | sleep 1
  exe "normal! " . "\<Esc>"
endfunction "}}}

function! RunTest() "{{{
  call Test("move_u", [11,11], [21,31])
  call Test("move_d", [11,11], [21,31])
  call Test("move_r", [11,11], [21,31])
  call Test("move_l", [11,11], [21,31])
endfunction "}}}
nnoremap  <F9> :<C-u>call RunTest()<CR>
finish
finish
" block


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

"   * REPLACE - action table >
"   +-----------------+--------------+--------------+
"   |  action	     | linewise     | blockwise    |
"   +-----------------+--------------|--------------|
"   | move-up/down    |	    O	    |	   O	   |
"   | move-right/left |	   N/A	    |	   O	   |
"   | dup-up/down     |	   TODO     |	   O	   |
"   | dup-righ/left   |	   TODO     |	TODO	   |
"   +-----------------+--------------+--------------+



" vim: foldmethod=marker
