" Support script for JavaScript
" Language:    JavaScript
" Maintainer:  Romain Lafourcade <romainlafourcade@gmail.com>
" Last Change: 2020 May 19

" Defining a generic 'path' for JavaScript is not easy because there is no
" official standard and there are almost as many conventions as there are
" teams.  Despite that sorry state of affairs, we are going to try to set
" 'path' to a reasonable value that the user can adjust, if necessary.

" An ideal 'path' for JavaScript should contain:
"   1. the directory of the current file
"   2. any contextually relevant directory
"   3. the node_modules directory
"   4. the working directory

" In this implementation, we try a few ways to build a list of
" interesting directories:
"   - tracked directories from Git (async)
"   - tracked directories from Mercurial (async)
"   - baseUrl from jsconfig.json
"
" More methods may be explored later.

" If directories are found via these methods, 'path' should look like this:
"   .,dir1/**,dir2/**,node_modules,,

" If none of the above works, the default 'path' should look like this:
"   .,node_modules,,

function! s:BuildPath(paths) abort
    if a:paths->len()
        setlocal path-=.
        setlocal path-=node_modules
        setlocal path-=,
        setlocal path-=**

        let local_paths = &l:path->split(',') + a:paths
        let full_path = ['.'] + local_paths->sort()->uniq() + ['node_modules', ',']

        let &l:path = full_path->join(',')
    endif
endfunction

function! s:UpdatePathWithJsconfig(fname) abort
    let base_url = readfile(a:fname)
                \ ->join()
                \ ->json_decode()
                \ ->get('compilerOptions', {})
                \ ->get('baseUrl', '.')

    if base_url != '.'
        call s:BuildPath([base_url->substitute('/*$', '/**', '')])
    endif
endfunction

function! s:UpdatePathWithGit() abort
    let cmd = ['git', 'rev-parse', '--abbrev-ref', 'HEAD']
    let opt = { "callback": "javascript#path#GitBranchHandler" }
    let job_branch = job_start(cmd, opt)
endfunction

function! s:UpdatePathWithMercurial() abort
    let cmd = ['hg', 'files', '-0']
    let opt = { "callback": "javascript#path#HgDirsHandler" }
    let job_hg = job_start(cmd, opt)
endfunction

function! javascript#path#GitBranchHandler(channel, msg) abort
    let cmd = ['git', 'ls-tree', '-d', '-z', '--name-only', a:msg]
    let opt = { "callback": "javascript#path#GitDirsHandler" }
    let job_dirs = job_start(cmd, opt)
endfunction

function! javascript#path#GitDirsHandler(channel, msg) abort
    let paths = a:msg
                \ ->split("\x0")
                \ ->filter({ idx, val -> val !~ '^\.' })
                \ ->map({ idx, val -> val .. '/**' })

    if paths->len()
        call s:BuildPath(paths)
    endif
endfunction

function! javascript#path#HgDirsHandler(channel, msg) abort
    let paths = a:msg
                \ ->split("\x0")
                \ ->filter({ idx, val -> val =~ '[\/\\]' })
                \ ->map({ idx, val -> substitute(val, '[\/\\].*', '', '') })
                \ ->uniq()
                \ ->map({ idx, val -> val .. '/**' })

    if paths->len()
        call s:BuildPath(paths)
    endif
endfunction

function! javascript#path#Set() abort
    " If applicable, retrieve the baseUrl defined in jsconfig.json
    let jsconfig = findfile('jsconfig.json', '.;')
    if jsconfig->len()
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
endfunction
