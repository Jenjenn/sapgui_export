whichLanCheckScreen(winID)
{
	/*
		Used to determine which OS01 screen we're on at the moment
		by examining the layout
	*/
	
	; the "specific IP" pings are bit different
	; but the details screen should work
	if InStr(WinGetTitle(winID), "Specific IP Address")
		return "details"
	
	; check if button15 is visible first -> Server selection screen
	button15 := ControlGetHwnd("Button15", winID)

	; if button doesn't exist, then we're not in OS01
	if (!button15)
		return ""

	; check if button15 is visible first -> Server selection screen
	if (ControlGetVisible(button15))
		return "serverlist"
	
	; check if button6 is visible next -> Server type screen
	if (ControlGetVisible("Button6", winID))
		return "servertypelist"
	
	; check if button3 is visible last -> Results screen
	if (ControlGetVisible("Button3", winID))
		return "results"
	
	; button15, button6, and button3 are not visible -> details screen
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

	cliptimeout := 10
		
	; Get the control of the header
	header_control := getControlsByClass(winID, "Internet Explorer_Server").filter("visible", true)[1]
	
	; put focus on the header area
	; ControlFocus acts really weird here; SAPGUI doesn't know how to handle it properly
	; So we use a ControlClick instead
	ControlClick(header_control)

	clipboard := ""
	Send("{Ctrl Down}ac{Ctrl Up}")
	ClipWait(cliptimeout)

	; save the copied text and get rid of some whitespace
	output := clipboard
	output := StrReplace(output, "`r`n")
	output := RegExReplace(output, " {1,}", " ")
	

	; get the body which is an ALVGrid
	body_control := getControlsByClass(winID, "SAPALVGrid").filter("visible", true)[1]

	; put focus on the ALVGrid
	ControlFocus(body_control)

	; this screen really doesn't like controlsend
	; {Space} will *toggle* select the entire column
	; so the first {Down} makes sure we don't have the entire column already selected
	; and the second {Down} clears the selection
	clipboard := ""
	;ControlSend("{Ctrl Down}{Down}{Space}c{Down}{Ctrl Up}", body_control)
	Send("{Ctrl Down}{Down}{Space}c{Ctrl Up}")
	ClipWait(cliptimeout)

	;combine the copied text with the previously saved output
	output := output "`r`n`r`n" clipboard
	output := RegExReplace(output, "`r`n`r`n", "`r`n---`r`n")
	
	clipboard := output
}


copyLanCheckScreen(winID)
{
	/*
		The screens for ping result (overall and individual)
	*/
	
	appendLog("entering copyLanCheckScreen")
	
	; we have to find out which screen we're on, the titles are the same for the most part
	os01_screen := whichLanCheckScreen(winID)
	
	appendLog("I think I'm on screen " os01_screen)
	
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