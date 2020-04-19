;Global alvgrid_export_images := {}

;alvgrid_export_images.at := []

;alvgrid_export_images.at[1] := {}
;alvgrid_export_images.at[1].ihandle := LoadPicture("signature/western_menu_inverted.png")


; parent_control is an MyControl object
findExport(parent_control, byref type_found := "")
{
	appendLog("export search in control '" . parent_control.classnn . "'")
	
	elements := []
	
	if (InStr(parent_control.wclass, "ToolbarWindow"))
	{
		elements.push("tbw_exp_drop")
		elements.push("tbw_exp_btn")
	}
	else{
		elements.push("at_exp_btn")
	}
	
	for i, elem in elements {
		xy := locateElementWithinControl(parent_control, elem)
		if (xy){
			type_found := getGuiElementType(elem)
			appendLog("export type '" type_found "' at x,y:" xy.x "," xy.y)
			return xy
		}
	}
	
	; not found
	appendLog("no export found")
	return ""
}


waitForExportDropButton(winID, control_to_search, timeout := 5){
	
	start_time := A_TickCount
	timeout := timeout * 1000
	
	;control should exist
	if (ErrorLevel){
		appendLog("could not retrieve the properties for control '" . control_to_search . "'")
		return
	}
	
	;define search area
	x := control_to_search.x
	x2 := control_to_search.x + control_to_search.w
	y := control_to_search.y
	y2 := control_to_search.y + control_to_search.y
	
	while ((A_TickCount - start_time) < timeout){
		
		locateGuiElement(winID, x, y, x2, y2, "tbw_exp_drop")
		
		if (!ErrorLevel){
			return
		}
		
		sleep(5)
	}
	
	ErrorLevel := 1
	appendLog("timeout of " . timeout . "ms reached in waitForExportButton")
	
}

getToolbarWindowForALVGrid(winID, alvgrid){
/*
	TODO:
	only elect toolbars which have a lower y value (i.e. above the alvgrid)
*/
	
	appendLog("getting ToolbarWindow for '" . alvgrid.classnn . "'")
	
	toolbar_windows := getControlsByClass(winID, "ToolbarWindow")

	; only get visible toolbarwindows
	temp := []
	for i, tbw in toolbar_windows
	{
		if (tbw.visible)
			temp.push(tbw)
	}

	toolbar_windows := temp
	
	if (!(toolbar_windows.length))
	{
		appendLog("no ToolbarWindow found")
		return ""
	}

	appendLog("found '" . toolbar_windows.length . "' visible ToolbarWindows")
	
	;exactly one toolbar is found
	if (toolbar_windows.Length = 1)
	{
		return toolbar_windows[1]
	}
	
	;multiple, determine the most appropriate choice based on distance
	;get the distance between the top-left corners of the grid and the first toolbar
	
	d1 := alvgrid.getDistance(toolbar_windows[1])
	closest := toolbar_windows[1]
	
	i := 2
	appendLog("'" . toolbar_windows[1].classnn . "' is " . d1 . " units away")
	while (i <= toolbar_windows.length){
		d2 := alvgrid.getDistance(toolbar_windows[i])
		appendLog("'" . toolbar_windows[i].classnn . "' is " . d2 . " units away")
		
		if (d2 < d1){
			closest := toolbar_windows[i]
			d1 := d2
		}
		i++
	}
	
	appendLog("returning '" . closest.classnn . "'")
	
	return closest
}

unhideStandardALVToolbar(winID, alv_toolbar)
{
	throw Exception ("not supported yet.")
	
	tx := toolbar.x, ty = toolbar.y,
	tx2 := toolbar.x + toolbar.w, ty2 := toolbar.y + toolbar.h
	
	;look for the unhide button
	
	;TEMPORARILY DISABLED
	;coord := findImage(winID, tx, ty, tx2, ty2, "show_std_alv.png")
	ErrorLevel := 1
	;/TEMPORARILY DISABLED
	
	;if we didn't find un unhide button, either 
	;it's not there or it's already been expanded
	;so we don't need to go any further
	if (ErrorLevel){
		appendLog("no unhide button found.")
		ErrorLevel := 0
		return
	}
	
	; we found an unhide button, so we need to click it.
	moveClickRestore(winID, coord.x + 5, coord.y + 5, False)
	
	; wait for the toolbar to expand, this is unfortunately a dialog step
	waitForExportDropButton(winID, alv_toolbarnn)
	
}


clickAppToolbarExport(winID)
{

	appendLog("trying the export button in the standard AppToolbar")
	
	app_tb := MyControl.new(ControlGetHwnd("AppToolbar", winID))
	
	if (ErrorLevel){
		appendLog("couldn't find the standard toolbar, 'AppToolbar'")
		return false
	}
	
	appendLog("AppToolbar at x,y:" app_tb.x . "," app_tb.y " , w,h:" app_tb.w "," app_tb.h)
	
	app_tb_export := findExport(app_tb)
	
	if (!app_tb_export){
		appendLog("couldn't find the export button in 'AppToolbar'")
		return false
	}
	
	; we should see the export button in the standard toolbar now
	cx := app_tb_export.x + 5
	cy := app_tb_export.y + 5
	appendLog("ControlClick to x,y:" . cx . "," . cy)
	CoordMode("Mouse", "Client")
	ControlClick("X" . cx . " Y" . cy, winID, , , 2)
	
	return true
}

processALVGrid(winID, alvgrid){
	
	appendLog("processing ALVGrid: '" . alvgrid.classnn . "'")

	ErrorLevel := 0
	
	; first we try the nearby ToolbarWindow:
	toolbar_window := getToolbarWindowForALVGrid(winID, alvgrid)

	if (!toolbar_window)
	{
		appendLog("No ToolbarWindow found")
		goto StandardToolbar
	}
	
	; found a ToolbarWindow
		
	appendLog(toolbar_window.classnn . ": " 
		. toolbar_window.x . "," . toolbar_window.y . "--" 
		. toolbar_window.w . "x" . toolbar_window.h)
		
	; ensure the standard ALV buttons are showing (i.e. ST05 hides them by default)
	; TODO: unhideStandardALVToolbar(toolbar_window)
		
	; look for an export button
	eb := findExport(toolbar_window, btype)
	
	if (!eb){
		appendLog("export not found within '" toolbar_window.classnn "'")
		goto StandardToolbar
	}

	; found an export button

	appendLog("export found in '" toolbar_window.classnn "' , type '" btype "'")
		
	; at this point we should see an export drop down button on the toolbar, click it
	moveClickRestore(winID, eb.x + 5, eb.y + 5, tb_hwnd)
		
	if (btype = "dd_button")
	{
		;Wait for that silly dialog box/menu to appear
		appendLog("waiting for #32768")
		found := WinWait( "ahk_class #32768", , 5)
		
		if (!found){
			appendLog("timeout waiting for #32768")
			ErrorLevel := 1
			return
		}
		appendLog("#32768 is visible")

		; send an 'l' to bring up the local file dialog box using the toolbar class name we obtained earlier
		ControlSend("l", tb_hwnd)
	}

	; if we made it this far, we should now be waiting for the 
	; "Save list in file..." dialog box
	
	
	return
	
	StandardToolbar:
	; try the standard toolbar
	clickAppToolbarExport(winID)
	
	return
}