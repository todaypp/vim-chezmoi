function s:Log(...)
	if g:vimChezmoiDebugMode == 1
		echo a:1
	endif
endfunction

function Chezmoi(...)
	let l:chezmoiBinary = get(a:, 1, "chezmoi")
        let g:vimChezmoiDebugMode = get(a:, 2, 0)

	if executable(l:chezmoiBinary) == 0
		echo "vim-chezmoi: The binary \"". l:chezmoiBinary . "\" does not exist. Check your vimrc and/or chezmoi installation."
		return
	endif
	call s:Log("Executable exists")

	let l:pid = getpid()
	let l:pidFile = '/proc/' . pid . '/stat'

	if filereadable(pidFile)
		call s:Log("Readable pid file")
		let l:pidStatFile = readfile(pidFile)[0]
		let l:parentPid = split(pidStatFile)[3]

		let l:parentPidFile = '/proc/' . l:parentPid . '/cmdline'

		if filereadable(l:parentPidFile)
			call s:Log("Readable parent pid file")
			let l:parentPidFileContents = readfile(l:parentPidFile)[0]
			let l:parentPidFileSplitted = split(l:parentPidFileContents, "\n")
			let l:parentPidFileCmd = join(l:parentPidFileSplitted, " ")

			if stridx(l:parentPidFileCmd, chezmoiBinary . ' edit') != -1
				let l:dotfile = l:parentPidFileSplitted[2]
				call s:Log("This vim session was launched via chezmoi edit. The dotfile that is being edited is " . l:dotfile)
				let g:chezmoiCommandToExecute = "!" . l:chezmoiBinary . " apply " . l:dotfile
				call s:Log("Cmd to execute on write:" . g:chezmoiCommandToExecute)
				if g:vimChezmoiDebugMode != 1
					let g:chezmoiCommandToExecute = ":silent" . g:chezmoiCommandToExecute
				endif
				au BufWritePost * execute g:chezmoiCommandToExecute

			else
				call s:Log("Chezmoi edit command not found on parent process. It's probably not a chezmoi invoke.")
			endif
		else
			call s:Log("Can not open the parent process file " . parentPidFile)
		endif
	else
		call s:Log("Can not open the process file " . pidFile)
	endif
endfunction
