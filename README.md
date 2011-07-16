What is this?
==================================
textmanip.vim is minimal utility for

  * duplicate text easily
  * move visually selected text easily

Use case
================================
* Indent text block
While editing markdown or vim help file.
Indenting selected text more easily.

* Duplicate selected text below.
When you want to call same function multiple time with various
arguments or create facially resemble code structure by yank and
paste.
It is bothersome to `visually select text block` then `yank` then
`move cursor` then `paste`
This mini-plugin enables you to simply select text and then `<M-d>` to
duplicate selected text block to bottom direction.
Of course, `<M-d>` is my choice, you can assign your favorite key map.

Mapping Example
==================================

Duplicete selected text bellow
--------------------------------
### Linux
    vmap <M-d> <Plug>(Textmanip.duplicate_selection_v)
    nmap <M-d> <Plug>(Textmanip.duplicate_selection_n)

    " for Terminal
    xmap D        <Plug>(Textmanip.duplicate_selection_v)
    nmap <Space>d <Plug>(Textmanip.duplicate_selection_n)

### Mac
    vmap <D-d> <Plug>(Textmanip.duplicate_selection_v)
    nmap <D-d> <Plug>(Textmanip.duplicate_selection_n)

Move visually selected text with Control and `hjkl`
---------------------------------------------------

    vmap <C-j> <Plug>(Textmanip.move_selection_down)
    vmap <C-k> <Plug>(Textmanip.move_selection_up)
    vmap <C-h> <Plug>(Textmanip.move_selection_left)
    vmap <C-l> <Plug>(Textmanip.move_selection_right)


Other keymap
===================================================
I use following key map to select text block(paragraph) speedy.
This mapping fit well with this `textmanip.vim` plugin

### Linux
    inoremap <M-l>  <Esc>V
    nnoremap <M-l>  V
    vnoremap <M-l>  ip

    " for Terminal
    nnoremap <silent> L V
    xnoremap <silent> L ip

### Mac
    inoremap <D-l>  <Esc>V
    nnoremap <D-l>  V
    vnoremap <D-l>  ip

Practice text block manipulation
===================================================
1. `<M-l>`: in normal-mode chose text-block.
2. `<M-d>`: duplicate text-block bottom direction.
3. `<C-l><C-l>`: right indent twice
