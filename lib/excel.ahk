excel_setSeparators(byref xl, byref cb){

	cb_detectNumberFormat(cb, dsep, tsep)
	
	if (ErrorLevel){
		TrayTip("Set Excel Separators"
		, "Couldn't detect the number separator from the clipboard data. Ensure the Excel separators are set accordingly."
		, 18)
	}
	
	xl.UseSystemSeparators := 0
	
	; xlDecimalSeparator = 3
	; xlThousandsSeparator = 4
	; https://docs.microsoft.com/en-us/office/vba/api/excel.xlapplicationinternational
	
	xl.DecimalSeparator := dsep
	xl.ThousandsSeparator := tsep
}

excel_paste(byref xl, byref cb){
/*
	puts cb into the clipboard and executes a paste
	then restores the previous contents of the clipboard
	
	For some reason the paste will fail unexplicably...
	I wonder if certain COM properties are not available
	right away after the last COM command
	
	Anyway, this seems to work for now
*/
	appendLog("attempt excel paste")
	
	static max_attempts := 10
	
	temp := clipboard
	clipboard := cb
	i := 0
	while (i < max_attempts){
		try{
			
			;do a COM paste, it's synchronous so we don't have to do any waiting/sleeping
			xl.ActiveCell.PasteSpecial
			clipboard := temp
			appendLog("paste successful")
			return
			
		} catch e {
			i++
			appendLog("attempt " . i . " failed")
			sleep(20)
			if (i >= 10){
				clipboard := temp
				throw e
			}
		}
	}
	
}

excel_preProcess(byref cb){
	
	cb_removeHorizontalLines(cb)
	
	;better solution might be to convert single | to tabs
	;even better is to the use the header line to determine the 
	;positions of the table bars and replace them specifically
	cb_replaceSQLConcat(cb)
	
	cb_removeWhiteSpace(cb)
	cb_removeLeadingBar(cb)
	cb_removeBlankLines(cb)
	cb_convertDateToNA(cb)
	
}