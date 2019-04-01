""""""""""""""""""""""""""""""""""""""""""
"    LICENSE: 
"     Author: 
"    Version: 
" CreateTime: 2018-09-26 15:10:29
" LastUpdate: 2018-09-26 15:10:29
"       Desc: 
""""""""""""""""""""""""""""""""""""""""""

if exists("s:is_load")
	call nvim_log#log_info("lsp-lc complete is load")
	finish
end
let s:is_load = 1

let s:cur_timer = 0
let s:fire_complete_interval = 30

let s:fire_count = 0

func! s:count_fire(ctx)
	if s:fire_count > 100000000
		let s:fire_count = 1
	else
		let s:fire_count = s:fire_count + 1
	endif
	let a:ctx['fire_count'] = s:fire_count
endfunc

func! s:check_fire_count(ctx)
	return a:ctx['fire_count'] == s:fire_count
endfunc

func! lsp_lc#complete(ctx)
	if s:cur_timer != 0
		call timer_stop(s:cur_timer)
		let s:cur_timer = 0
	endif
	func! Callback(time_id) closure
		if a:time_id != s:cur_timer
			return
		endif
		call s:fire_complete(a:ctx)
	endfunc

	let s:cur_timer = timer_start(s:fire_complete_interval, function('Callback'))
endfunc

func! s:fire_complete(ctx)
	"ctx.{line, col} 提供的是当前光标的前的字母位置, 并且是1-based
	"lsp 补全位置是当前光标的位置，并且是0-based
    let l:params = {
                \ 'filename': LSP#filename(),
				\ 'position': {
					\ 'line': a:ctx.line - 1,
					\ 'character': a:ctx.col,
				\ },
			\ }

	call s:count_fire(a:ctx)
    let l:Callback = function('s:complete_callback', [a:ctx])
	return LanguageClient#Call('textDocument/completion', l:params, l:Callback)
	"return LanguageClient#textDocument_completion({}, l:Callback)
endfunc

func! s:complete_callback(ctx, ret_data)
	if ! s:check_fire_count(a:ctx)
		"echo "lsp lc complete late"
		return
	endif

	call nvim_log#log_debug(string(a:ret_data))
	call luaeval("require('complete-engine/lsp-lc').complete_callback(_A.ctx, _A.data)", {
				\ "ctx": a:ctx,
				\ "data": a:ret_data,
				\ })
endfunc

call luaeval("require('complete-engine/lsp-lc').init()")
