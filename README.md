What is this?
==================================
text_manup.vim is minimal utility for

  * duplicate text easily
  * move selected text easily

Duplicete selected text bellow
================================
Linux
-----------

    vmap <M-d> <Plug>(TextManup.duplicate_selection_v)
    nmap <M-d> <Plug>(TextManup.duplicate_selection_n)

Mac
-----------

    vmap <D-d> <Plug>(TextManup.duplicate_selection_v)
    nmap <D-d> <Plug>(TextManup.duplicate_selection_n)


Move visually selected text with Control and `hjkl`
===================================================

    vmap <C-j> <Plug>(TextManup.move_selection_down)
    vmap <C-k> <Plug>(TextManup.move_selection_up)
    vmap <C-h> <Plug>(TextManup.move_selection_left)
    vmap <C-l> <Plug>(TextManup.move_selection_right)


Other keymap
===================================================
I think following keymap fit well with this plugin

Linux
------------------------
    inoremap <M-l>  <Esc>V
    nnoremap <M-l>  V
    vnoremap <M-l>  ip

Mac
------------------------
    inoremap <D-l>  <Esc>V
    nnoremap <D-l>  V
    vnoremap <D-l>  ip
