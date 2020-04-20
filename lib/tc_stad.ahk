class STAD
{

	copyRecordsOverview(winID)
	{
		appendLog("copying STAD records - overview")
		Send("!ww")
		save_hwnd := waitAndProcessSaveDialog()
		waitForSaveDialogToClose(save_hwnd)

		stad_output := clipboard
		STAD.insertColumnDividers(stad_output)
		clipboard := stad_output
		flushLogAndExit()

	}

	insertColumnDividers(byref stad_output)
	{
		static needle_header := "m)^\|Started.*?\|"
		static needle_headings := "Server|Transaction|Program|T|Scr.|Wp"

		static rep_left := "m)(?<=^\|.{"
		static rep_right := "})."

		start_time := A_TickCount

		header_start := RegExMatch(stad_output, needle_header, header)
		appendLog("Found '|Started' at position: " . header_start)

		column_offsets := []
		match_p := 1

		while (match_p := RegExMatch(header, needle_headings, , match_p)) {
			column_offsets.push(match_p - 3)
			match_p += 1
		}

		appendLog("Making replacements at " . column_offsets.join(","))

		rep_cnt := 0
		for i, col in column_offsets
		{
			stad_output := RegExReplace(stad_output, rep_left . col . rep_right, "|", reps)
			rep_cnt += reps
		}

		runtime := A_TickCount - start_time
		appendLog(rep_cnt . " replacements in " . runtime . " ms")
	}

	copyCallDialog(winID)
	{
		/*
			We also want to include the Window Title here for clarity as it's
			not easily discernable by just the data alone. So we need to wait
			for the save dialog to close then modify the clipboard contents
		*/
		
		title := WinGetTitle(winID)
		
		ControlClick("Button2", winID, , , 2)
		save_hwnd := waitAndProcessSaveDialog()
		waitForSaveDialogToClose(save_hwnd)
		
		clipboard := title "`r`n" clipboard
				
		flushLogAndExit()
	}
}