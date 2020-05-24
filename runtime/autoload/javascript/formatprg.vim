" Support script for JavaScript
" Language:    JavaScript
" Maintainer:  Romain Lafourcade <romainlafourcade@gmail.com>
" Last Change: 2020 May 24

" Js-beautify and prettier are two popular JavaScript formatters.

function! javascript#formatprg#Set() abort
    let format_prg = &l:formatprg->split(' ')

    if executable('js-beautify')
        let format_prg = [
                    \ 'js-beautify -f -',
                    \ get(g:, 'javascript_jsbeautify_options', '-j --editorconfig'),
                    \ ]
    endif

    if executable('prettier')
        let format_prg = [
                    \ 'prettier --stdin-filepath %',
                    \ get(g:, 'javascript_prettier_options', ''),
                    \ ]
    endif

    let &l:formatprg = format_prg->join(' ')
endfunction

" vim: textwidth=78 tabstop=8 shiftwidth=0 softtabstop=0 expandtab
