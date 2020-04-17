;Global alvgrid_export_images := {}

;alvgrid_export_images.at := []

;alvgrid_export_images.at[1] := {}
;alvgrid_export_images.at[1].ihandle := LoadPicture("signature/western_menu_inverted.png")


findExport(winID, parentclass, byref type_found=""){
	/*
		parentclass here is an object with properites
		obtained via lib/helpers.ahk:getControlProperties
	*/
	
	appendLog("export search in control '" . parentclass.classnn . "'")
	
	;get the search area
	;x1 := parentclass.x, x2 := parentclass.x + parentclass.w
	;y1 := parentclass.y, y2 := parentclass.y + parentclass.h
	
	;construct the filenames
	;TODO : preload/cache the images in the helpers.ahk file
	elements := []
	
	
	if (InStr(parentclass.classnn, "ToolbarWindow")){
		elements.push("tbw_exp_drop")
		elements.push("tbw_exp_btn")
	}
	else{
		elements.push("at_exp_btn")
	}
	
	
	for i, elem in elements {
		xy := locateGuiElementWithinParent(winID, parentclass, elem)
		if (!ErrorLevel){
			;found
			type_found := getGuiElementType(elem)
			appendLog("export of type '" . type_found . "' at x,y:" . xy.x . "," . xy.y)
			return xy
		}
	}
	
	;not found
	ErrorLevel := 1
	appendLog("no export found")
	return ""
}


waitForExportDropButton(winID, control_to_search, timeout=5){
	
	start_time := A_TickCount
	timeout := timeout * 1000
	
	coord := getControlProperties(winID, control_to_search)
	
	;control should exist
	if (ErrorLevel){
		appendLog("could not retrieve the properties for control '" . control_to_search . "'")
		return
	}
	
	;define search area
	x := coord.x, x2 := coord.x + coord.w
	y := coord.y, y2 := coord.y + coord.y
	
	while ((A_TickCount - start_time) < timeout){
		
		locateGuiElement(winID, x, y, x2, y2, "tbw_exp_drop")
		
		if (!ErrorLevel){
			return
		}
		
		sleep, 5
	}
	
	ErrorLevel := 1
	appendLog("timeout of " . timeout . "ms reached in waitForExportButton")
	
}

getToolbarWindowForALVGrid(winID, alvgridnn){
/*
	TODO:
	only elect toolbars which have a lower y value (i.e. above the alvgrid)
*/
	
	appendLog("getting ToolbarWindow for '" . alvgridnn . "'")
	
	toolbar_windows := getClassNNByClass(winID, "ToolbarWindow")
	
	if (ErrorLevel){
		appendLog("no ToolbarWindows found")
		return ""
	}
	appendLog("found '" . toolbar_windows.Length() . "' ToolbarWindows")
	
	;no toolbar found, set error level and return
	if (toolbar_windows.Length() = 0){
		ErrorLevel := 1
		return
	}
	
	;exactly one toolbar is found
	if (toolbar_windows.Length() = 1){
		ErrorLevel := 0
		return toolbar_windows[1]
	}
	
	;multiple, determine the most appropriate choice based on distance
	;get the distance between the top-left corners of the grid and the first toolbar
	
	d1 := getDistanceBetweenControls(winId, alvgridnn, toolbar_windows[1])
	closest := toolbar_windows[1]
	
	i := 2
	appendLog("'" . toolbar_windows[1] . "' is " . d1 . " units away")
	while (i <= toolbar_windows.length()){
		d2 := getDistanceBetweenControls(winId, alvgridnn, toolbar_windows[i])
		appendLog("'" . toolbar_windows[i] . "' is " . d2 . " units away")
		
		if (d2 < d1){
			closest := toolbar_windows[i]
			d1 := d2
		}
		i++
	}
	
	appendLog("returning '" . closest . "'")
	
	ErrorLevel := 0
	return closest
	
}

unhideStandardALVToolbar(winID, alv_toolbarnn)
{
	
	toolbar := getControlProperties(winID, alv_toolbarnn)
	
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
	
	;we found an unhide button, so we need to click it.
	moveClickRestore(winID, coord.x + 5, coord.y + 5, False)
	
	;wait for the toolbar to expand, this is unfortunately a dialog step
	waitForExportDropButton(winID, alv_toolbarnn)
	
}


clickAppToolbarExport(winID){

	appendLog("trying the export button in the standard AppToolbar")
	
	t := getControlProperties(winID, "AppToolbar")
	
	if (ErrorLevel){
		appendLog("couldn't find the standard toolbar, 'AppToolbar'")
		return
	}
	
	appendLog("AppToolbar found at x,y:" . t.x . "," . t.y . " with w,h:" . t.w . "," . t.y)
	
	cxy := findExport(winID, t)
	
	if (ErrorLevel){
		appendLog("couldn't find the export button on the 'AppToolbar' toolbar")
		return
	}
	
	;we should see the export button in the standard toolbar now
	cx := cxy.x + 5, cy := cxy.y + 5
	appendLog("ControlClick to x,y:" . cx . "," . cy)
	CoordMode, Mouse, Window
	ControlClick, x%cx% y%cy%, ahk_id %winID%, , , 2
	
	ErrorLevel := 0
}

processALVGrid(winID, alvgrid_nn){
	
	appendLog("processing ALVGrid: '" . alvgrid_nn . "'")
	
	;first we try the nearby ToolbarWindow:
	toolbar_windownn := getToolbarWindowForALVGrid(winID, alvgrid_nn)
	
	if (!ErrorLevel){
		;found a ToolbarWindow
		t := getControlProperties(winID, toolbar_windownn)
		
		appendLog("ToolbarWindow: " . t.classnn . "," . t.x . "," . t.y . "," . t.w . "," . t.h)
		
		;ensure the standard ALV buttons are showing (i.e. ST05 hides them by default)
		unhideStandardALVToolbar(winID, t.classnn)
		
		;look for an export button
		eb := findExport(winID, t, btype)
		
		if (ErrorLevel){
			appendLog("export not found within control '" . t.classnn . "'")
			goto, StandardToolbar
		}
		else
			appendLog("export found in '" . t.classnn . "' ,type '" . btype . "'")
		
		ErrorLevel := 0
		
		;at this point we should see an export drop down button on the toolbar, click it
		moveClickRestore(winID, eb.x + 5, eb.y + 5, tbcname)
		
		
		if (btype = "dd_button"){
			;Wait for that silly dialog box/menu to appear
			appendLog("waiting for #32768")
			WinWait, ahk_class #32768, , 4
			
			if (ErrorLevel){
				appendLog("timeout waiting for #32768; exiting")
				flushLogAndExit()
			}
			appendLog("#32768 is visible")

			;send an 'l' to bring up the local file dialog box using the toolbar class name we obtained earlier
			ControlSend, %tbcname%, l, ahk_id %winID%
		}
		
		return
	}
	
	StandardToolbar:
	;try the standard toolbar
	
	clickAppToolbarExport(winID)
	
	return
}