let s:u = textmanip#util#get()

let s:textmanip = {}

function! s:textmanip.start(env) "{{{1
  try
    let shiftwidth = g:textmanip_move_ignore_shiftwidth
          \ ? g:textmanip_move_shiftwidth
          \ : &shiftwidth
    let options = textmanip#options#new()
    call options.replace({'&virtualedit': 'all', '&shiftwidth': shiftwidth })

    call self.init(a:env)
    call self.varea[self.env.action](a:env.dir, a:env.count, a:env.emode)

    if self.env.action ==# 'move'
      let b:textmanip_status = self.varea.state()
    endif
  catch /CANT_MOVE/
    normal! gv
  finally
    call options.restore()
  endtry
endfunction

function! s:textmanip.init(env) "{{{1
  let self.env = a:env
  let [s, e] = self.getpos()
  let pos_s = textmanip#pos#new(s)
  let pos_e = textmanip#pos#new(e)
  let varea = textmanip#selection#new(pos_s, pos_e, self.env.mode)
  if get(b:, "textmanip_status", {}) == self.varea.state() &&
        \ a:env.action ==# 'move'
    " continuous move
    silent! undojoin
  else
    let b:textmanip_replaced = self.varea.new_replace()
  endif
  let self.varea.replaced = b:textmanip_replaced

  let self.env.toward = s:u.toward(self.env.dir)
  if self.env.mode   ==# 'n'                                  | return | endif
  if self.env.action ==# 'blank'                              | return | endif
  if self.env.action ==# 'dup' && self.env.emode ==# 'insert' | return | endif
  if self.env.dir =~# 'v\|>'  | return | endif

  call self.adjust_count()

  try
    call s:cant_move("Topmost line",
          \ self.env.dir ==# '^' && self.varea.T.line ==# 1
          \ )
    call s:cant_move( "all line have no-blank char",
          \ self.env.dir ==# '<' &&
          \ self.varea.linewise &&
          \ empty(filter(self.varea.content().content, "v:val =~# '^\\s'"))
          \ )
    call s:cant_move( "no space to left",
          \ self.env.dir ==# '<' &&
          \ !self.varea.linewise &&
          \ self.varea.L.colm == 1 && self.env.mode ==# "\<C-v>"
          \ )
    call s:cant_move("count 0", self.env.count ==# 0 )
  endtry
endfunction

function! s:textmanip.adjust_count() "{{{1
  let dir = self.env.dir

  if dir ==# '^'
    let max = self.varea.T.line - 1
  elseif dir ==# '<'
    if ! self.varea.linewise
      let max = self.varea.L.colm  - 1
    else
      let max = self.env.count
    endif
  endif

  if self.env.emode ==# 'replace' && self.env.action ==# 'dup'
    if     dir ==# '^' | let max = max / self.varea.height
    elseif dir ==# '<' | let max = max / self.varea.width
    endif
  endif
  let self.env.count = min([max, self.env.count])
endfunction

function! s:cant_move(desc, expr) "{{{1
  if a:expr
    throw "CANT_MOVE " . a:desc
  endif
endfunction

function! s:textmanip.getpos() "{{{1
  if self.env.mode is 'n'
    let s = getpos('.')
    return [s, s]
  endif

  exe 'normal! gvo' | let s = getpos('.') | exe "normal! \<Esc>"
  exe 'normal! gvo' | let e = getpos('.') | exe "normal! \<Esc>"

  return [s, e]
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

function! textmanip#do(action, dir, mode, emode) "{{{1
  let env = {
        \ "action": a:action,
        \ "dir": a:dir,
        \ "mode": a:mode is 'x' ? visualmode() : a:mode,
        \ "emode": (a:emode is 'auto') ? g:textmanip_current_mode : a:emode,
        \ "count": v:count1,
        \ }
  call s:textmanip.start(env)
endfunction

" [FIXME] Dirty!!
function! textmanip#do1(action, dir, mode, emode) "{{{1
  try
    let _textmanip_move_ignore_shiftwidth = g:textmanip_move_ignore_shiftwidth
    let _textmanip_move_shiftwidth        = g:textmanip_move_shiftwidth

    let g:textmanip_move_ignore_shiftwidth = 1
    let g:textmanip_move_shiftwidth        = 1
    call textmanip#do(a:action, a:dir, a:mode, a:emode)
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
        \ g:textmanip_current_mode is 'insert'
        \ ? 'replace' : 'insert'
  echo "textmanip-mode: " . g:textmanip_current_mode
endfunction

function! textmanip#mode() "{{{1
  return g:textmanip_current_mode
endfunction

function! textmanip#debug() "{{{1
  echo s:textmanip.debug()
endfunction

" vim: foldmethod=marker
