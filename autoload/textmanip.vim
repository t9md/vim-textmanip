let s:textmanip = {}

function! s:textmanip.setup() "{{{1
    call self.shiftwidth_switch()
    call self.ve_start()
endfunction

function! s:textmanip.finish() "{{{1
    call self.ve_restore()
    call textmanip#status#update()
    call self.shiftwidth_restore()
endfunction

function! s:textmanip.start(env) "{{{1
  call self.init(a:env)
  let dir = self.env.dir

  if self.env.action ==# 'dup'
    if self.varea.linewise
      call self.duplicate_line()
    else
      call self.duplicate_block()
    endif
    return
  endif

  try
    if self.cant_move
      normal! gv
      return
    endif
    call self.setup()
    call self.extend_EOF()

    if self.varea.linewise && dir =~# '\v^(right|left)$'
      let ward =
            \ dir ==# 'right' ? ">" :
            \ dir ==# 'left'  ? "<" : throw
      exe "'<,'>" . repeat(ward, self.env.count)
      call self.varea.select()
      return
    else            
      call self.varea.move(dir, self.env.count, self.env.emode)
    endif
    " [FIXME] dirty hack for status management yanking let '< , '> refresh,
    " use blackhole @_ register
    normal! "_ygv
  finally
    call self.finish()
  endtry
endfunction

function! s:textmanip.duplicate_block() "{{{1
  call self.ve_start()

  let c = self.env.prevcount
  let h = self.height
  let selected = self.varea.content()
  let selected.content =
        \ textmanip#area#new(selected.content).v_duplicate(c).data()
  let self.varea.vars = { 'h': h, 'c': c }

  if self.env.emode ==# "insert"
    let blank_lines = map(range(h*c), '""')
    let ul = self.varea.u.line()
    let dl = self.varea.d.line()
    let [ blank_target, chg, last ] =  {
          \ "up":   [ ul-1, '',                     'd+(h*c-h):' ],
          \ "down": [ dl  , ['u+h: ', 'd+(h*c):'], ''            ],
          \ }[self.env.dir]
    call append(blank_target, blank_lines)
    call self.varea.select(chg).paste(selected).select(last)

  elseif self.env.emode ==# "replace"
    let chg =  {
          \ "up":   ['u-(h*c):', 'd-h:'],
          \ "down": ['u+h:'    , 'd+(h*c):' ],
          \ }[self.env.dir]
    call self.varea.select(chg).paste(selected).select()
  endif

  call self.ve_restore()
endfunction

function! s:textmanip.duplicate_line() "{{{1
  if self.env.mode ==# 'n'
    " normal
    let c     = self.env.count
    let [ line, col ]  = self.varea.u.pos()
    " let col   = self.varea.u.col()
    let selected = self.varea.content().content
    let lines = textmanip#area#new(selected).v_duplicate(c).data()
    let [target_line, last_line ] =
          \ self.env.dir ==# 'up'   ? [line-1, line    ] :
          \ self.env.dir ==# 'down' ? [line  , line + c] : throw
    call append(target_line, lines)
    call cursor(last_line, col)
    return
  endif

  let c        = self.env.prevcount
  let h        = self.height
  let selected = self.varea.content()
  let selected.content =
        \ textmanip#area#new(selected.content).v_duplicate(c).data()
  let self.varea.vars = { 'c': c, 'h': h }

  if self.env.emode ==# "insert"
    let [target_line, last ] = {
          \ "up":   [ self.varea.u.line() -1 , 'd+(h*c-h):' ],
          \ "down": [ self.varea.d.line()    ,['u+h:', 'd+(h*c):'] ],
          \ }[self.env.dir]
    call append(target_line , selected.content)
    call self.varea.select(last)
  elseif self.env.emode ==# "replace"
    let chg =  {
          \ "up":   ['u-(h*c):', 'd-h:'],
          \ "down": ['u+h:'    , 'd+(h*c):' ],
          \ }[self.env.dir]
    call self.varea.select(chg).paste(selected).select()
  endif
endfun

function! s:textmanip.init(env) "{{{1

  let self.env = a:env
  let p            = getpos('.')
  let self.varea   = self.preserve_selection()

  let self.continuous = textmanip#status#continuous()
  if self.continuous
    call self.undojoin()
  else
    let b:textmanip_replaced = self.varea.new_replace()
  endif
  let self.varea.replaced = b:textmanip_replaced

  let self.width  = self.varea.width
  let self.height = self.varea.height

  if self.env.mode ==# 'n' | return | endif

  " adjust count
   if self.env.dir ==# 'up'
     let max = self.varea.u.line() - 1
   elseif self.env.dir ==# 'left' && !self.varea.linewise
     let max = self.varea.u.col() - 1
   else
     let max = self.env.count
   endif
  let self.env.count = min([max, self.env.count])

  " care corner case
  let self.cant_move = 0
  try
    if self.env.dir ==# 'up'
      if self.varea.u.line() ==# 1
        throw "CANT_MOVE"
      endif
    elseif self.env.dir ==# 'left'
      if self.varea.linewise
        if empty(filter(self.varea.content().content, "v:val =~# '^\\s'"))
          throw "CANT_MOVE"
        endif
      else
        if self.varea.u.col() == 1 && self.env.mode ==# "\<C-v>"
          throw "CANT_MOVE"
        endif
      endif
    endif
  catch /CANT_MOVE/
    let self.cant_move = 1
  endtry
endfunction

function! s:textmanip.undojoin() "{{{1
  try
    silent undojoin
  catch /E790/
    " after move and exit at the same position(actully at cosmetic level no
    " change you made), and 'u'(undo), then restart move.
    " This read to situation 'undojoin is not allowed after undo' error.
    " But this cannot detect, so simply suppress this error.
  endtry
endfunction

function! s:textmanip.preserve_selection() "{{{1
  if self.env.mode ==# 'n'
    let s = getpos('.')
    let e = getpos('.')
  else
    exe 'normal! gvo' | let s = getpos('.') | exe "normal! " . "\<Esc>"
    exe 'normal! gvo' | let e = getpos('.') | exe "normal! " . "\<Esc>"
  endif
" getpos() return [bufnum, lnum, col, off]
" off is offset from actual col when virtual edit(ve) mode,
" so, to respect ve position, we sum "col" + "off"
  return textmanip#selection#new(
        \ [s[1], s[2] + s[3]], [e[1], e[2] + e[3]], self.env.mode)
endfunction

function! s:textmanip.extend_EOF() "{{{1
  " even if set ve=all, dont automatically extend EOF
  let amount = (self.varea.d.line() + self.env.count) - line('$')
  if self.env.dir ==# 'down' && amount > 0
    call append(line('$'), map(range(amount), '""'))
  endif
endfunction

function! s:textmanip.ve_start() "{{{1
  let self._ve = &virtualedit
  let &virtualedit = 'all'
endfunction

function! s:textmanip.ve_restore() "{{{1
  let &virtualedit = self._ve
endfunction

function! s:textmanip.shiftwidth_switch() "{{{1
  let self._shiftwidth = &sw
  let &sw = g:textmanip_move_ignore_shiftwidth
        \ ? g:textmanip_move_shiftwidth : &sw
endfunction

function! s:textmanip.shiftwidth_restore() "{{{1
  if has_key(self, "_shiftwidth")
    let &sw = self._shiftwidth
  endif
endfunction

function! s:textmanip.dump() "{{{1
endfunction

function! s:textmanip.kickout(num, guide) "{{{1
  let orig_str = getline(a:num)
  let s1 = orig_str[ : col('.')- 2 ]
  let s2 = orig_str[ col('.')-1 : ]
  let pad = &textwidth - len(orig_str)
  let pad = ' ' . repeat(a:guide, pad - 2) . ' '
  let new_str = join([s1, pad, s2],'')
  return new_str
endfunction

function! textmanip#do(action, direction, mode, emode) "{{{1
  let env = {
        \ "action": a:action,
        \ "dir": a:direction,
        \ "mode": a:mode ==# 'v' ? visualmode() : a:mode,
        \ "emode": (a:emode ==# 'auto') ? g:textmanip_current_mode : a:emode,
        \ "count": v:count1,
        \ "prevcount": (v:prevcount ? v:prevcount : 1),
        \ }
  call s:textmanip.start(env)
endfunction

function! textmanip#do1(action, direction, mode) "{{{1
  try
    let _textmanip_move_ignore_shiftwidth = g:textmanip_move_ignore_shiftwidth
    let _textmanip_move_shiftwidth        = g:textmanip_move_shiftwidth

    let g:textmanip_move_ignore_shiftwidth = 1
    let g:textmanip_move_shiftwidth        = 1
    call textmanip#do(a:action, a:direction, a:mode, "auto")
  finally
    let g:textmanip_move_ignore_shiftwidth = _textmanip_move_ignore_shiftwidth
    let g:textmanip_move_shiftwidth        = _textmanip_move_shiftwidth
  endtry
endfunction

" [FIXME] very rough state.
function! textmanip#kickout(guide) range "{{{1
  " let answer = a:ask ? input("guide?:") : ''
  let guide = !empty(a:guide) ? a:guide : ' '
  let orig_pos = getpos('.')
  if a:firstline !=# a:lastline
    normal! gv
  endif
  for n in range(a:firstline, a:lastline)
    call setline(n, s:textmanip.kickout(n, guide))
  endfor
  call setpos('.', orig_pos)
endfunction

function! textmanip#toggle_mode() "{{{1
  let g:textmanip_current_mode =
        \ g:textmanip_current_mode ==# 'insert' ? 'replace' : 'insert'
  echo "textmanip-mode: " . g:textmanip_current_mode
endfunction

function! textmanip#mode() "{{{1
  return g:textmanip_current_mode
endfunction

function! textmanip#debug() "{{{1
  " return PP(s:textmanip._replaced._data)
endfunction

" vim: foldmethod=marker
