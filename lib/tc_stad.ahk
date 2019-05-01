copySTADcallDialog(winID)
{
	/*
		We also want to include the Window Title here for clarity as it's
		not easily discernable by just the data alone. So we need to wait
		for the save dialog to close then modify the clipboard contents
	*/
	
	WinGetTitle, title, ahk_id %winID%
	
	ControlClick, Button2, ahk_id %winID%, , , 2
	waitAndProcessSaveDialog()
	waitForSaveDialogToClose()
	
	Clipboard=%title%`r`n%ClipBoard%
	
	flushLogAndExit()
}