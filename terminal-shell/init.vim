" Standard Neovim Configuration
" Basic settings for usability and appearance

" Editor behavior
set number
set relativenumber
set cursorline
set wrap
set scrolloff=8
set sidescrolloff=8

" Search settings
set ignorecase
set smartcase
set incsearch
set hlsearch

" Indentation
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent
set autoindent

" File handling
set hidden
set backup
set backupdir=~/.config/nvim/backup//
set directory=~/.config/nvim/swap//
set undofile
set undodir=~/.config/nvim/undo//

" Create backup directories if they don't exist
if !isdirectory(expand('~/.config/nvim/backup'))
    call mkdir(expand('~/.config/nvim/backup'), 'p')
endif
if !isdirectory(expand('~/.config/nvim/swap'))
    call mkdir(expand('~/.config/nvim/swap'), 'p')
endif
if !isdirectory(expand('~/.config/nvim/undo'))
    call mkdir(expand('~/.config/nvim/undo'), 'p')
endif

" UI improvements
set termguicolors
set signcolumn=yes
set updatetime=300
set timeoutlen=500

" Custom color scheme to match kitty Deep Space theme
highlight Normal guifg=#99eaff guibg=#0b0e0e
highlight CursorLine guibg=#101515
highlight LineNr guifg=#283436 guibg=#0b0e0e
highlight CursorLineNr guifg=#668389 guibg=#101515 gui=bold
highlight Visual guifg=#99eaff guibg=#2b383a
highlight Search guifg=#ffffff guibg=#668389
highlight IncSearch guifg=#0f0c0a guibg=#e0dbd8
highlight StatusLine guifg=#99eaff guibg=#141a1b
highlight StatusLineNC guifg=#283436 guibg=#0d1010
highlight VertSplit guifg=#2b383a guibg=#0b0e0e
highlight Pmenu guifg=#99eaff guibg=#141a1b
highlight PmenuSel guifg=#99eaff guibg=#2b383a
highlight Comment guifg=#334144 gui=italic
highlight String guifg=#8cb0bc
highlight Number guifg=#668389
highlight Function guifg=#e0dbd8
highlight Keyword guifg=#ffffff gui=bold
highlight Type guifg=#a0bec8
highlight Special guifg=#668389
highlight Error guifg=#ff6b6b guibg=#2a0a0a
highlight Warning guifg=#ffa500 guibg=#2a1a00

" Cursor styling to match kitty
set guicursor=n-v-c:block-Cursor/lCursor
set guicursor+=i:ver25-Cursor/lCursor
set guicursor+=r-cr:hor20-Cursor/lCursor

" Split behavior
set splitright
set splitbelow

" Mouse support
set mouse=a

" Clear search highlighting with Escape
nnoremap <Esc> :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Quick save
nnoremap <C-s> :w<CR>

" Better yanking (copy to system clipboard)
vnoremap <leader>y "+y
nnoremap <leader>Y "+yg_
nnoremap <leader>y "+y

" Paste from system clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P