" original => change => last
" [line, col]
"
" u u[0] - 1
" d d[0] + 1
" l l[1] - 1
" r r[1] + 1

" POS:
let s:pos = {}
function! s:pos.new(pos) "{{{
  " pos = [line, col]
  let self._data = a:pos
  return deepcopy(self)
endfunction "}}}

function! s:pos.pos() "{{{
  return self._data
endfunction "}}}

function! s:pos.line() "{{{
  return self._data[0]
endfunction "}}}
function! s:pos.col() "{{{
  return self._data[1]
endfunction "}}}

function! s:pos.move_line(ope) "{{{
  let self._data[0] = eval(self._data[0] . a:ope)
  return self._data
endfunction "}}}

function! s:pos.move_col(ope) "{{{
  let self._data[1] = eval(self._data[1] . a:ope)
  return self._data
endfunction "}}}

function! s:pos.move(line_ope, col_ope) "{{{
  let self._data = [
        \ eval(self._data[0] . a:line_ope),
        \ eval(self._data[1] . a:col_ope),
        \ ]
  return self
endfunction "}}}

function! s:pos.set(line, col) "{{{
  let self._data = [ a:line, a:col ]
  return self._data
endfunction "}}}

function! s:pos.dump() "{{{
  return self._data
endfunction "}}}

" Selection:
let s:selection = {}
function! s:selection.new(s, e) "{{{
  let self.s = s:pos.new(a:s)
  let self.e = s:pos.new(a:e)
  let s = a:s
  let e = a:e

  if     ((s[0] <= e[0]) && (s[1] <=  e[1])) | let case = 1
  elseif ((s[0] >= e[0]) && (s[1] >=  e[1])) | let case = 2
  elseif ((s[0] <= e[0]) && (s[1] >=  e[1])) | let case = 3
  elseif ((s[0] >= e[0]) && (s[1] <=  e[1])) | let case = 4
  endif

  let ps = self.s
  let pe = self.e

  if     case ==# 1 | let [u, d, l, r ] = [ ps, pe, ps, pe ]
  elseif case ==# 2 | let [u, d, l, r ] = [ pe, ps, pe, ps ]
  elseif case ==# 3 | let [u, d, l, r ] = [ ps, pe, pe, ps ]
  elseif case ==# 4 | let [u, d, l, r ] = [ pe, ps, ps, pe ]
  endif

  let self.u = u
  let self.d = d
  let self.l = l
  let self.r = r
  " let ul = [ u[0], l[1] ]     " let ur = [ u[0], r[1]]
  " let dr = [ d[0], r[1]]      " let dl = [ d[0], l[1]]

  " let self.ul = s:pos.new(ul)
  " let self.dr = s:pos.new(dr)

  let self.width  = abs(e[1] - s[1]) + 1
  let self.height = abs(e[0] - s[0]) + 1

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

" call Test("case2", [66,23], [61,11]) "{{{
" call Test("case3", [61,11], [66,23])
" call Test("case3", [66,23], [61,11])
" call Test("case4", [61,11], [66,23])
" "}}}

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

let s:area = {}
let blockwise.move_u = { "change": 'u-1,  ', "last": ['u-1,  ', 'd-1,  '] }
let blockwise.move_d = { "change": 'd+1,  ', "last": ['u+1,  ', 'd+1,  '] }
let blockwise.move_r = { "change": 'r  ,+1', "last": ['l  ,+1', 'r  ,+1'] }
let blockwise.move_l = { "change": 'l  ,-1', "last": ['l  ,-1', 'r  ,-1'] }
let linewise.move_u = { "change": 'u-1,  ', "last": ['u-1,  ', 'd-1,  '] }
let linewise.move_d = { "change": 'd+1,  ', "last": ['u+1,  ', 'd+1,  '] }

let s:area.blockwise = blockwise
let s:area.linewise = linewise
"
" let s:area.move_r = { "change": 'r  ,+1', "last": ['r  ,+1', 'r  ,+1'] }
" let s:area.move_l = { "change": 'l  ,-1', "last": ['l  ,-1', 'l  ,-1'] }

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
"  | [block] |     change,  |           last              |
"  +---------+--------------+-----------------------------|
"  |  move-u | u-[ -1,    ] |  u-[ -1,    ], d-[ -1,    ] | 
"  +---------+--------------+----+------------------------|
"  |  move-d | d-[ +1,    ] |  u-[ +1,    ], d-[ +1,    ] |
"  +---------+--------------+----+------------------------|
"  |  move-r | -r[   , +1 ] |  -r[   , +1 ], -r[   , +1 ] |
"  +---------+--------------+----+------------------------|
"  |  move-l | -l[   , -1 ] |  -l[   , -1 ], -l[   , -1 ] |
"  +------------------------------------------------------+
"
"  +------------------------------------------------------+
"  | [Line ] |     change,   |           last             |
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
"
" [line]
" move-u  ul[ "-1", "" ]   ul["-1", ""], dr["-1", ""]
" move-d  ul[ "+1", "" ]   ul["+1", ""], dr["+1", ""]
" move-r  N/A
" move-l  N/A

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
