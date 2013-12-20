
let s:textmanip = {}

function! s:textmanip.start(env) "{{{1
  try
    let sw = g:textmanip_move_ignore_shiftwidth
          \ ? g:textmanip_move_shiftwidth : &shiftwidth
    call textmanip#options#set({ '&virtualedit': 'all', '&shiftwidth': sw })
    call self.init(a:env)
    call self.varea[self.env.action](a:env.dir, a:env.count, a:env.emode)

    if self.env.action ==# 'move'
      let b:textmanip_status = self.varea.state()
    endif
  catch /CANT_MOVE/
    " echo v:exception "\n"
    normal! gv
  finally
    call textmanip#options#restore()
  endtry
endfunction

function! s:textmanip.init(env) "{{{1
  let self.env = a:env
  let self.varea   = self.preserve_selection()

  if get(b:, "textmanip_status", {}) == self.varea.state() &&
        \ a:env.action ==# 'move'
    " continuous move
    silent! undojoin
  else
    let b:textmanip_replaced = self.varea.new_replace()
  endif
  let self.varea.replaced = b:textmanip_replaced

  if self.env.mode   ==# 'n'                                  | return | endif
  if self.env.action ==# 'blank'                              | return | endif
  if self.env.action ==# 'dup' && self.env.emode ==# 'insert' | return | endif
  if self.env.dir    =~# 'd\|r'                               | return | endif

  call self.adjust_count()

  try
    call s:cant_move( "topmost line",
          \ self.env.dir ==# 'u' && self.varea.u.line() ==# 1
          \ )
    call s:cant_move( "all line have no-blank char",
          \ self.env.dir ==# 'l' &&
          \ self.varea.linewise &&
          \ empty(filter(self.varea.content().content, "v:val =~# '^\\s'"))
          \ )
    call s:cant_move( "no space to left",
          \ self.env.dir ==# 'l' &&
          \ !self.varea.linewise &&
          \ self.varea.l.col() == 1 && self.env.mode ==# "\<C-v>"
          \ )
    call s:cant_move( "count 0", self.env.count ==# 0 )
  endtry
endfunction

function! s:textmanip.adjust_count() "{{{1
  " care only 'u' and 'l'
  " echo "pre :" self.env.count
  let dir = self.env.dir

  if dir ==# 'u'
    let max = self.varea.u.line() - 1
  elseif dir ==# 'l'
    if ! self.varea.linewise
      let max = self.varea.l.col()  - 1
    else
      let max = self.env.count
    endif
  endif

  if self.env.emode ==# 'replace' && self.env.action ==# 'dup'
    if     dir ==# 'u' | let max = max / self.varea.height
    elseif dir ==# 'l' | let max = max / self.varea.width
    endif
  endif
  let self.env.count = min([max, self.env.count])
  " echo "post :" self.env.count
endfunction

function! s:cant_move(desc, expr) "{{{1
  if a:expr
    throw "CANT_MOVE " . a:desc
  endif
endfunction


function! s:textmanip.preserve_selection() "{{{1
  if self.env.mode ==# 'n'
    let s = getpos('.')
    let e = s
  else
    exe 'normal! gvo' | let s = getpos('.') | exe "normal! \<Esc>"
    exe 'normal! gvo' | let e = getpos('.') | exe "normal! \<Esc>"
  endif
  return textmanip#selection#new(s, e, self.env.mode)
endfunction

function! s:textmanip.debug() "{{{1
  return PP(b:textmanip_status)
endfunction

function! s:textmanip.kickout(num, guide) "{{{1
  let orig_str = getline(a:num)
  let s1       = orig_str[ : col('.')- 2 ]
  let s2       = orig_str[ col('.')-1 : ]
  let pad      = &textwidth - len(orig_str)
  let pad      = ' ' . repeat(a:guide, pad - 2) . ' '
  let new_str  = join([s1, pad, s2],'')
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

function! textmanip#do1(action, direction, mode, emode) "{{{1
  try
    let _textmanip_move_ignore_shiftwidth = g:textmanip_move_ignore_shiftwidth
    let _textmanip_move_shiftwidth        = g:textmanip_move_shiftwidth

    let g:textmanip_move_ignore_shiftwidth = 1
    let g:textmanip_move_shiftwidth        = 1
    call textmanip#do(a:action, a:direction, a:mode, a:emode)
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
  echo s:textmanip.debug()
endfunction

" vim: foldmethod=marker
