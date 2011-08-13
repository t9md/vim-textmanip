function! textmanip#duplicate(mode) range "{{{
    let pos = getpos('.')
    let cmd = a:firstline . ",". a:lastline . "copy " . a:lastline
    execute cmd

    if a:mode ==# 'v'
        normal! `[V`]
    elseif a:mode ==# 'n'
        let pos[1] = line('.')
        call setpos('.', pos)
    endif
endfun "}}}


function! textmanip#move(direction) range "{{{
    let action       = {}
    let action.down  = a:firstline. ",". a:lastline . "move " . (a:lastline  + 1)
    let action.up    = a:firstline. ",". a:lastline . "move " . (a:firstline - 2)
    let action.right = "normal! gv>>"
    let action.left  = "normal! gv<<"

    if a:direction == 'down' && a:lastline == line('$')
        call append(line('$'), "")
    endif

    execute action[a:direction]
    normal! gv
endfun "}}}
" vim: foldmethod=marker
