
let s:textmanip = {}
function! s:textmanip.setup() "{{{1
  let sw = g:textmanip_move_ignore_shiftwidth ? g:textmanip_move_shiftwidth : &sw
  call textmanip#options#set({
        \ 've': 'all',
        \ 'sw': sw,
        \ })
endfunction

function! s:textmanip.finish() "{{{1
  call textmanip#options#restore()
  if self.env.action ==# 'dup'
    return
  endif
  call textmanip#status#update()
endfunction

function! s:textmanip.start(env) "{{{1
  let dir   = a:env.dir
  let c     = a:env.count
  let emode = a:env.emode

  try
    call self.setup()
    call self.init(a:env)

    if self.env.action ==# 'dup'
      call self.varea.duplicate(dir, c, emode)
      return
    endif

    call self.extend_EOF()
    call self.varea.move(dir, c, emode)
    " [FIXME] dirty hack for status management yanking let '< , '> refresh,
    " use blackhole @_ register
    normal! "_ygv
  catch /CANT_MOVE/
    normal! gv
  finally
    call self.finish()
  endtry
endfunction

function! s:textmanip.init(env) "{{{1
  let self.env = a:env
  let self.varea   = self.preserve_selection()

  let self.continuous = textmanip#status#continuous()
  if self.continuous
    call self.undojoin()
  else
    let b:textmanip_replaced = self.varea.new_replace()
  endif
  let self.varea.replaced = b:textmanip_replaced

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

  if self.env.action ==# 'dup' | return | endif

  try
    call s:cant_move(
          \ self.env.dir ==# 'up' && self.varea.u.line() ==# 1
          \ )
    call s:cant_move(
          \ self.env.dir ==# 'left' &&
          \ self.varea.linewise &&
          \ empty(filter(self.varea.content().content, "v:val =~# '^\\s'"))
          \ )
    call s:cant_move(
          \ self.env.dir ==# 'left' &&
          \ !self.varea.linewise &&
          \ self.varea.u.col() == 1 && self.env.mode ==# "\<C-v>"
          \ )
  endtry
endfunction

function! s:cant_move(expr) "{{{1
  if a:expr
    throw "CANT_MOVE"
  endif
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
  return textmanip#selection#new(s, e, self.env.mode)
endfunction

function! s:textmanip.extend_EOF() "{{{1
  " even if set ve=all, dont automatically extend EOF
  let amount = (self.varea.d.line() + self.env.count) - line('$')
  if self.env.dir ==# 'down' && amount > 0
    call append(line('$'), map(range(amount), '""'))
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
