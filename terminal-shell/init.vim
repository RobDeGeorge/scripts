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
highlight Normal guifg=#eed8a9 guibg=#060b12
highlight CursorLine guibg=#09101b
highlight LineNr guifg=#0f192c guibg=#060b12
highlight CursorLineNr guifg=#27406f guibg=#09101b gui=bold
highlight Visual guifg=#eed8a9 guibg=#192c4c
highlight Search guifg=#f9f4eb guibg=#27406f
highlight IncSearch guifg=#000819 guibg=#cbba96
highlight StatusLine guifg=#eed8a9 guibg=#070c16
highlight StatusLineNC guifg=#0f192c guibg=#070d15
highlight VertSplit guifg=#192c4c guibg=#060b12
highlight Pmenu guifg=#eed8a9 guibg=#070c16
highlight PmenuSel guifg=#eed8a9 guibg=#192c4c
highlight Comment guifg=#132037 gui=italic
highlight String guifg=#888687
highlight Number guifg=#27406f
highlight Function guifg=#cbba96
highlight Keyword guifg=#e2d9c5 gui=bold
highlight Type guifg=#959394
highlight Special guifg=#27406f
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