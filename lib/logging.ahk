;doesn't fire when a thread completes a hotkey
;can we get to work when a thread finishes rather than the script actually closing?
;for the time being use flushLogAndExit instead of just exit
;OnExit("flushLogOnExit", -1)

Global exec_log := ""
Global script_start := 0

clearLog(){
	global exec_log := "log cleared at " . A_Now . "`r`n"
	global script_start := A_TickCount
}

appendLog(mes, stack_offset := -1){
/*
	Format is:
	nnnn ms : file : line : message   (executing function)
*/
	logger := Exception(".", stack_offset)
	caller := Exception(".", stack_offset - 1)
	
	;indent formatting based on stack level
	i := -1
	e := Exception(".", i)
	
	while (e.What != i){
		i--
		e := Exception(".", i)
	}
	
	depth:= (-1 * i) - 2
	offset := ""
	while (depth > 1){
		offset .= "  "
		depth--
	}
	;end of indent formatting
	
	;SplitPath(InputVar [, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive])
	SplitPath(logger.file, fname)
	
	diff := A_TickCount - script_start
	
	loglinepre := Format("{:5} ms : {:-18}:{:-4} : {}{}   ({})"
	, diff, fname, logger.line, offset, mes, caller.what)
	
	global exec_log .= loglinepre . "`r`n"
}

flushLog(){
	appendLog("flush called by ===>", -2)
	
	FileAppend(exec_log, "log.txt", "UTF-8")
	global exec_log := ""
	;MsgBox % A_WorkingDir
}

flushLogAndExit(e := ""){
	appendLog("flush and exit called by ===>", -2)
	
	FileAppend(exec_log, "log.txt", "UTF-8")
	;MsgBox % A_WorkingDir
	exit
}