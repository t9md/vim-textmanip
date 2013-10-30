 CeckList:
=====================
 restore original vim options
 restore original visual mode
 restore original cursor pos including where 'o'pposit pos in visual mode.
 count reflect result.
 undoable for continuous move by one 'undo' command.
 care when move across corner( TOF,EOF, BOL, EOL )
  - by adjusting cursor to appropriate value
  u => TOF
  d => EOF
  r => EOL(but ve care this!)
  l => BOF

 Supported: [O: Finish][X: Not Yet][P: Partially impremented]
 * normal_mode:
 [O] duplicate line to above, below

 * visual_line('V', or multiline 'v':
 [O] duplicate line to above, below
 [O] move righ/left
 [O] undoable/count

 * visual_block(C-v):
 [O] move selected block to up/down/right/left.
   ( but not multibyte char aware ).
 [X] count support, not undoable
