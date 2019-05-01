excel_setSeparators(byref xl, byref cb){

	cb_detectNumberFormat(cb, dsep, tsep)
	
	;Do not use the system separators, set it myself
	xl.UseSystemSeparators := 0
	
	; xlDecimalSeparator = 3
	; xlThousandsSeparator = 4
	; https://docs.microsoft.com/en-us/office/vba/api/excel.xlapplicationinternational
	
	xl.DecimalSeparator := dsep
	xl.ThousandsSeparator := tsep
}

; excel_paste(excel_win_id, byref cb){
	; temp:=clipboard
	; clipboard:=cb
	; ControlSend
	; clipboard:=temp
; }

excel_preProcess(byref cb){
	
	cb_removeHorizontalLines(cb)
	
	;better solution might be to convert single | to tabs
	;even better is to the use the header line to determine the 
	;positions of the table bars and replace them specifically
	cb_replaceSQLConcat(cb)
	cb_removeWhiteSpace(cb)
	cb_removeLeadingBar(cb)
	
}