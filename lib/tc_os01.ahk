whichLanCheckScreen(winID)
{
	/*
		Used to determine which OS01 screen we're on at the moment
		by examining the layout
	*/
	
	;the "specific IP" pings are bit different
	;but the details screen should work
	WinGetTitle, title, ahk_id %winID%
	if InStr(title, "Specific IP Address")
	return "details"
	
	;check if button15 is visible first -> Server selection screen
	ControlGet, bvisible, Visible, , Button15, ahk_id %winID%
	if (ErrorLevel) ;if button doesn't exist, then we're not in OS01
	return ""
	if (bvisible) ;button not visible, we're in the detail screen
	return "serverlist"
	
	;check if button6 is visible next -> Server type screen
	ControlGet, bvisible, Visible, , Button6, ahk_id %winID%
	if (bvisible) ;button not visible, we're in the detail screen
	return "servertypelist"
	
	;check if button3 is visible last -> Results screen
	ControlGet, bvisible, Visible, , Button3, ahk_id %winID%
	if (bvisible) ;button not visible, we're in the detail screen
	return "results"
	
	;last possibility is the Details screen
	return "details"
}

copyLanCheckScreenDetails(winID)
{
	/*
		assumes we are on the LAN check details screen
		e.g.:   "03.04.2019 05:31:00       from <hostname> (n.n.n.n)"
		
		ControlSend is not reliable due to SAPGUI interpretation time
		Controls sent with ControlSend might be ignore or behave weirdly
		if SAPGUI is making UI adjustments (like shading a button you just hovered over)
	*/
	
	
	;Get the header text
	header_classnn := getClassNNByClass(winID, "Internet Explorer_Server")[1]
	
	;put focus on the header area
	;ControlFocus acts really weird here; SAPGUI doesn't know how to handle it properly
	;So we use a ControlClick instead
	ControlClick, %header_classnn%, ahk_id %winID%
	Send, {Ctrl Down}ac{Ctrl Up}
	
	;save to clipboard and get rid of some whitespace
	output := ClipBoard
	output := StrReplace(output, "`r`n")
	output := RegExReplace(output, " {1,}", " ")
	
	;get the body text
	body_classnn := getClassNNByClass(winID, "SAPALVGrid")[1]
	ControlFocus, %body_classnn%, ahk_id %winID%
	
	;Send, {Ctrl Down}{Down}{Space}c{Down}{Ctrl Up}
	ControlSend, %body_classnn%, {Ctrl Down}{Down}{Space}c{Down}{Ctrl Up}, ahk_id %WinID%
	

	output=%output%`r`n`r`n%ClipBoard%
	
	Clipboard := output
	
	
}


copyLanCheckScreen(winID)
{
	/*
		The screens for ping result (overall and individual)
	*/
	
	appendLog("entering copyLanCheckScreen")
	
	;we have to find out which screen we're on, the titles are the same for the most part
	os01_screen := whichLanCheckScreen(winID)
	
	appendLog("I think I'm on screen %os01_screen%")
	
	if (os01_screen = "serverlist"){
		appendLog("executing 'serverlist' screen copy")
		clickAppToolbarExport(winID)
		if (!ErrorLevel)
			waitAndProcessSaveDialog()
		flushLogAndExit()
	}
	
	if (os01_screen = "results"){
		appendLog("executing 'results' screen copy")
		sendSystemListSave(winID)
	}
	
	if (os01_screen = "details"){
		appendLog("executing 'details' screen copy")
		copyLanCheckScreenDetails(winID)
	}
	
}