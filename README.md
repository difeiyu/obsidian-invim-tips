# obsidian-invim-tips
A little trick to edit obsidian in nvim

------
# usage 
- require 'obsidian'
- nnoremap <silent> <expr> <enter>  &filetype=='markdown' ? ':Olink<cr>': '<enter>'
