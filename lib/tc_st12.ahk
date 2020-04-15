/*
	The call stack area is 30 columns wide
	
	To tell if the call stack is enabled, look for an "Off" button in the AppToolbar
	
	To find the call stack area, look for R 248 G 229 B 200 (0xF8E5C8)
	at an offset of y+30 from the top left corner of SAPALVGrid2
	
	https://autohotkey.com/docs/commands/PixelSearch.htm
	Search can be reversed, perfect
	
	The column header needs to be click at a y offset of +5 and x offset of +/-8 from the pixel searches above
	
	
*/


st12_findEdgeDown(byref pbm, x, y, num_checks, byref y_edge){

	appendLog("looking for a color border below x,y:" . x . "," . y)
	
	max_y := y + num_checks
	
	;get the starting color
	cc := Gdip_GetPixel(pbm, x, y)
	
	y++
	next_c := Gdip_GetPixel(pbm, x, y)
	
	while (cc = next_c AND y < max_y) {
		y++
		next_c := Gdip_GetPixel(pbm, x, y)
	} 
	
	if (y >= max_y){
		ErrorLevel := 1
		return
	}
	
	y_edge := y - 1
	
	appendLog("color border directly below x,y:" . x . "," . y_edge)
}

st12_findEdgeRight(byref pbm, x, y, num_checks, byref x_edge){

	appendLog("looking for a color border right of x,y:" . x . "," . y)
	
	max_x := y + num_checks
	
	;get the starting color
	cc := Gdip_GetPixel(pbm, x, y)
	
	x++
	next_c := Gdip_GetPixel(pbm, x, y)
	
	while (cc = next_c AND x < max_x) {
		x++
		next_c := Gdip_GetPixel(pbm, x, y)
	} 
	
	if (x >= max_x){
		ErrorLevel := 1
		return
	}
	
	x_edge := x - 1
	
	appendLog("color border directly right of x,y:" . x . "," . x_edge)
}

st12_findCallStackArea(byref pbm, alvx, alvy, byref stack_left, byref stack_right){
/*
	WIP
*/
	;static stack_area_color = 0xf8e5c8
	static stack_area_color = 0xfff8e5c8
	static sy_offset := 30
	
	search_x := alvx + 100, search_y := alvy + 30
	
	appendLog("looking for the call stack area right of x=" . search_x . " and at y=" . search_y)
	
	CoordMode, Pixel, Window
	
	;get the left side
	PixelSearch, x1, , % search_x, % search_y, % search_x + 800, % search_y + 1, 0xf8e5c8, , Fast RGB
	;st12_findColorRight(search_x, search_y, stack_area_color)
	
	
	if (ErrorLevel){
		appendLog("couldn't find the left side of the stack area")
		return
	}
	
	appendLog("left side of call stack found at " . x1)
	
	
	;look down until we find an edge so we can then move right without
	;worrying about the call stack characters getting in the way
	st12_findEdgeDown(pbm, x1, alvy + sy_offset, 40, celly)
	
	if (ErrorLevel){
		appendLog("couldn't find bottom of alv cell")
		return
	}
	
	
	;find the right side of the call stack area
	st12_findEdgeRight(pbm, x1, celly, 1000, x2)
	
	if (ErrorLevel){
		return
	}
	
	stack_left := x1, stack_right := x2
	
	appendLog("stack area is between x=" . stack_left . " and x=" . stack_right)
}

st12_copyByALVHeader(win_id, start_x, end_x, y){
	
	moveClickDragRestore(start_x, y, end_x, y)
	
	clipboard :=
	
	;Send {Ctrl Down}{Down}{Space}c{Down}{Ctrl Up}
	Send {Ctrl Down}c{Ctrl Up}
	startt := A_tickcount
	ClipWait, 5
	delta := A_tickcount - startt
	appendLog("waited " . delta . " ms for clipboard data")
}

st12_processCallStackOutput(byref call_stacks){
/*
	before --- after
	     =     ^
		 C     |
		 D     |
		 ,     o
		 >     v
*/
	appendLog("processing call stack output")
	
	static needle1 := "((?<=\t)(?=\r\n))|((?<=\t)(?=\t))"
	call_stacks := RegexReplace(call_stacks, needle1, " ")
	
	call_stacks := RegexReplace(call_stacks, "\t", " ")
	
	call_stacks := StrReplace(call_stacks, "=", "^")
	call_stacks := StrReplace(call_stacks, "C", "|")
	call_stacks := StrReplace(call_stacks, "D", "|")
	call_stacks := StrReplace(call_stacks, ",", "o")
	call_stacks := StrReplace(call_stacks, ">", "v")
	
}

st12_copyCallStack(win_id){
	
	/* TODO: name of the ALVGrid in ST12 is not always SAPALVGrid2
		change this to a generic SAPALVGrid control by detecting the main control in the window
	*/
	static alv_name := "SAPALVGrid2"
	
	alvgrid := getControlProperties(win_id, alv_name)
	
	if (ErrorLevel){
		appendLog("'" . alv_name . "' not found")
		return
	}
	
	appendLog("taking screenshot of ST12")
	pbm := Gdip_BitmapFromHWND(win_id)
	if (debug_gdip){
		appendLog("saving gdip bmp to file")
		Gdip_SaveBitmapToFile(pbm, "debug_st12_copyCallStack.png")
	}
	
	
	
	st12_findCallStackArea(pbm, alvgrid.x, alvgrid.y, stack_start, stack_end)
	
	if (ErrorLevel){
		appendLog("something went wrong looking for the call stack area")
		return ""
	}
	
	stack_start += 8, stack_end -= 8
	stack_y := alvgrid.y + 8
	
	appendLog("executing keystrokes to copy stack")
	st12_copyByALVHeader(win_id, stack_start, stack_end, stack_y)
	
	if (clipboard = ""){
		ErrorLevel := 1
		appendLog("nothing copied")
	}
	
	call_stacks := clipboard
	
	st12_processCallStackOutput(call_stacks)
	
	return call_stacks
}


st12_callStackEnabled(win_id){
/*
	Determines if the call stack is showing in the ABAP trace of ST12
	The test is a search for the "Stack Off" button in the AppToolbar
*/
	appendLog("checking for a call stack")
	
	t := getControlProperties(win_id, "AppToolbar")
	
	if (ErrorLevel){
		appendLog("couldn't find the standard toolbar, 'AppToolbar'")
		return
	}
	
	locateGuiElementWithinParent(win_id, t, "at_stkoff_btn")
	
	if (ErrorLevel){
		ErrorLevel := 0
		appendLog("call stack not enabled")
		return false
	}
	
	appendLog("call stack enabled")
	return true
}


st12_copyABAPTraceScreen(win_id){
	
	;try for call stack(s)
	if (st12_callStackEnabled(win_id)){
		;try to get the call stack
		
		call_stacks := st12_copyCallStack(win_id)
		
		if (call_stacks = ""){
			appendLog("no callstacks")
		}
	}
	
	clipboard :=
	;get the regular output
	Send, !sxl
	waitAndProcessSaveDialog()
	
	;wait for the clipboard to be populated
	ClipWait, 10
	
	screen_out := clipboard
	
	clipboard := screen_out . "`r`n" . call_stacks
	
	flushLogAndExit()
}

