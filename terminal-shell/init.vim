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
highlight Normal guifg=#feda99 guibg=#0f0f09
highlight CursorLine guibg=#16160d
highlight LineNr guifg=#1c1c13 guibg=#0f0f09
highlight CursorLineNr guifg=#474731 guibg=#16160d gui=bold
highlight Visual guifg=#feda99 guibg=#3d3d28
highlight Search guifg=#fcf5e8 guibg=#474731
highlight IncSearch guifg=#0d0d0b guibg=#caa563
highlight StatusLine guifg=#feda99 guibg=#0e0e09
highlight StatusLineNC guifg=#1c1c13 guibg=#12120a
highlight VertSplit guifg=#3d3d28 guibg=#0f0f09
highlight Pmenu guifg=#feda99 guibg=#0e0e09
highlight PmenuSel guifg=#feda99 guibg=#3d3d28
highlight Comment guifg=#232318 gui=italic
highlight String guifg=#33342e
highlight Number guifg=#474731
highlight Function guifg=#caa563
highlight Keyword guifg=#d9be8f gui=bold
highlight Type guifg=#383932
highlight Special guifg=#474731
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