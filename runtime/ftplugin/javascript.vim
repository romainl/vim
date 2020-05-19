" Vim filetype plugin file
" Language:     Javascript
" Maintainer:   Doug Kearns <dougkearns@gmail.com>
" Last Change:  2020 May 19
" URL:          http://gus.gscit.monash.edu.au/~djkea2/vim/ftplugin/javascript.vim
" Contributor:  Romain Lafourcade <romainlafourcade@gmail.com>

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo-=C

" Set 'formatoptions' to break comment lines but not other lines,
" and insert the comment leader when hitting <CR> or using "o".
setlocal formatoptions-=t formatoptions+=croql

" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
    setlocal omnifunc=javascript#javascriptcomplete#CompleteJS
endif

" Set 'comments' to format dashed lists in comments.
setlocal comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,://

setlocal commentstring=//%s

" Change the :browse e filter to primarily show JavaScript-related files.
if has("gui_win32")
    let  b:browsefilter="Javascript Files (*.js)\t*.js\n" .
                \ "All Files (*.*)\t*.*\n"
endif

" The following suffixes should be implied when resolving filenames
setlocal suffixesadd+=.js,.jsx,.vue,.vuex,.es,.es6,.mjs,.json

" The following suffixes should have low priority
setlocal suffixes+=.snap

" Prepend node_modules/.bin to $PATH if applicable
" Allows calling npm/yarn-installed CLI executables like eslint
let s:bin = finddir('node_modules/.bin', '.;')->fnamemodify(':.')
if len(s:bin) && $PATH !~ s:bin
    let $PATH = s:bin .. ':' .. $PATH
endif
unlet s:bin

" @ is a common alias in vue/webpack setups
setlocal isfname+=@-@

" Find explicit module imports. CommonJS/Node.js and ES2015 syntaxes are
" supported:
"     var foo = require('foo');
"     import foo from 'foo';
setlocal include=^\\s*[^\/]\\+\\(from\\\|require(\\)\\s*['\"]\\ze

" Try to set 'path' to a reasonable default value
call javascript#path#Set()

" Set 'define' to a useful value
let &l:define = '^\s*\('
            \ .. '\(export\s\)*\(\w\+\s\)*\(var\|const\|let\|function\|class\|as\)\s'
            \ .. '\|\(static\|get\s\|set\)\s'
            \ .. '\|\(export\sdefault\s\)'
            \ .. '\|\(async\sfunction\)\s'
            \ .. '\|\(\ze\i\+([^)]*).*{$\)'
            \ .. '\)'

" placeholder
setlocal includeexpr&

" placeholder
setlocal formatprg&

let b:undo_ftplugin = "setl fo< ofu< com< cms< sua< su< isf< inc< def< pa< inex< fp<"

let &cpo = s:cpo_save
unlet s:cpo_save
