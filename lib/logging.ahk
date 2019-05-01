;doesn't fire when a thread completes a hotkey
;can we get to work when a thread finishes rather than the script actually closing?
;for the time being use flushLogAndExit instead of just exit
;OnExit("flushLogOnExit", -1)

Global exec_log:=
Global script_start:=

clearLog(){
	global exec_log:="log cleared at " . A_Now . "`r`n"
	global script_start:=A_TickCount
}

appendLog(mes, stack_offset:=-1){
/*
	Format is:
	ms
	nnnn : file : line : message   (executing function)
*/
	logger := Exception(".", stack_offset)
	caller := Exception(".", stack_offset - 1)
	
	
	SplitPath, % logger.file, fname
	
	diff := A_TickCount - script_start
	
	loglinepre:=Format("{:5} ms : {:-18}:{:-4} : {}   ({})"
	, diff, fname, logger.line, mes, caller.what)
	
	global exec_log .= loglinepre . "`r`n"
}


flushLogAndExit(){
	appendLog("flushing log and exiting", -2)
	
	FileAppend, %exec_log%, log.txt, UTF-8
	;MsgBox % A_WorkingDir
	exit
}