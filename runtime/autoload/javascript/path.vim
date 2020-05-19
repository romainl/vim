" Support script for JavaScript
" Language:    JavaScript
" Maintainer:  Romain Lafourcade <romainlafourcade@gmail.com>
" Last Change: 2020 May 19

" Defining a generic 'path' for JavaScript is not easy because there is no official
" standard and there are almost as many conventions as there are teams. Our
" goal, here, is to set 'path' to a reasonable value that the user can adjust,
" if necessary.

" Ideally, 'path' should contain:
"   1. the directory of the current file
"   2. any contextually relevant directory
"   3. the node_modules directory
"   4. the working directory

" In C, the language for which the default 'path' is defined, includes are
" relative to specific directories, generally outside of the current project.
" In JavaScript, includes can be relative to the local node_modules directory,
" very roughly similar to C's /usr/include, but also to the current file, or
" to other arbitrary directories... and let's not talk about aliases.
" Therefore, building a list of 'contextually relevant directories' that would
" suit everyone is near impossible.

" In this implementation, the directories tracked by Git or Mercurial are used
" if applicable, as well as the baseUrl defined in jsconfig.json, a Visual
" Studio Code artefact, again if applicable. More may come in the future.

" If directories are found via these methods, 'path' should look like this:
"   .,dir1/**,dir2/**,node_modules,,

" If none of the above works, the default 'path' should look like this:
"   .,node_modules,,

function! s:UpdatePathWithGit() abort
    let job_branch = job_start(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], { "callback": "BranchHandler" })

    function! BranchHandler(channel, msg) abort
        let job_dirs = job_start(['git', 'ls-tree', '-d', '-z', '--name-only', a:msg], { "callback": "DirsHandler" })
    endfunction

    function! DirsHandler(channel, msg) abort
        setlocal path-=,

        let &l:path = &l:path .. ',' .. a:msg
                    \ ->split("\x0")
                    \ ->filter({ idx, val -> val !~ '^\.' })
                    \ ->map({ idx, val -> val .. '/**' })
                    \ ->join(',')

        setlocal path-=node_modules
        setlocal path+=node_modules
        setlocal path+=,
    endfunction
endfunction

function! s:UpdatePathWithMercurial() abort
    let job_hg = job_start(['hg', 'files', '-0'], { "callback": "HgHandler" })

    function! HgHandler(channel, msg) abort
        setlocal path-=,

        let &l:path = &l:path .. ',' .. a:msg
                    \ ->split("\x0")
                    \ ->filter({ idx, val -> val =~ '[\/\\]' })
                    \ ->map({ idx, val -> substitute(val, '[\/\\].*', '', '') })
                    \ ->uniq()
                    \ ->map({ idx, val -> val .. '/**' })
                    \ ->join(',')

        setlocal path-=node_modules
        setlocal path+=node_modules
        setlocal path+=,
    endfunction
endfunction

function! s:UpdatePathWithJsconfig(fname) abort
    setlocal path-=,

    let &l:path = &l:path .. ',' .. readfile(a:fname)
                \ ->join()
                \ ->json_decode()
                \ ->get('compilerOptions', {})
                \ ->get('baseUrl', '.')
                \ ->substitute('/*$', '/**', '')

    setlocal path-=node_modules
    setlocal path+=node_modules
    setlocal path+=,
endfunction

function! javascript#path#Set() abort
    setlocal path=.

    " If applicable, retrieve the baseUrl defined in jsconfig.json
    let jsconfig = findfile('jsconfig.json', '.;')
    if len(jsconfig)
        call <SID>UpdatePathWithJsconfig(jsconfig)
    endif

    " If applicable, ask Git for the list of tracked directories
    if finddir('.git', '.;')->len()
        call <SID>UpdatePathWithGit()
    endif

    " If applicable, ask Mercurial for the list of tracked directories
    if finddir('.hg', '.;')->len()
        call <SID>UpdatePathWithMercurial()
    endif

    setlocal path-=node_modules
    setlocal path+=node_modules
    setlocal path+=,
endfunction
