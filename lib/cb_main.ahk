/*
	Contains clipboard processing-related functions
*/


cb_removeInitialHeader(byref cb_with_newlines){
	/*
		if there is a header such as:
		
		2019.04.29                     Dynamic List Display                            1
		--------------------------------------------------------------------------------
		
		Then remove it here
	*/
	
	static needle:="^.*Dynamic List Display *\d\r\n-------*\r\n"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, "", 1)
}

cb_removeTrailingPage(byref cb_with_newlines){
	static needle:="\r\nPage: *\d*$"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle)
}

cb_getTableStartEndHeader(byref cb_array, byref start_i_out, byref end_i_out, byref header_i_out){
/*
	WIP
*/
	appendLog("looking for the start and end of a table")
	
	start_i_out := -1, end_i_out := -1
	
	;don't like enumeration loops, we might need to alter our index manually
	i := 1, cb_rows := cb_array.MaxIndex()
	while (i <= cb_rows){
		
		line := cb_array[i]
		len := StrLen(line)
		
		if InStr(line, "----") = 1
		AND InStr(line, "----", false, len - 5){
		
			appendLog("potential border found at " . i)
			
			;found a potential table border
			;the next line must begin with a bar '|' to be part of the table
			
			
			
			i := cb_array.MaxIndex()
		
		}
		
		
		
		
		
		i++
	}
	
	
	
}

cb_detectNumberFormat(byref cb_with_newlines, byref dec_separator, byref thou_separator){

/*
	Assumes:
	> numbers have a comma or a dot as the decimal separator
	> numbers are optionally formatted in groups of 3 digits separated by a dot/comma
	
	To increase robustness, we determine the separator by popular occurrence
	(dot_count and comma_count)
	If a single cell contains comma as the separator and appears first, it spoils 
	the whole data set
*/

	appendLog("starting number format search in cb_detectNumberFormat")

/*
	Because our tables are read row1.col1 -> row1.col2 -> row1.col3 ..... rown.colm
	(i.e. left to right) we read over a variety of different data
	It's more performant to maintain a single complex regex than to break it down
*/	
/*
	This is our initial number finder regex, we use this to identify cells which contain
	numbers
	> look for zero or more spaces followed by 1 to 3 digits
	> look behind us for a bar (tells us we're in a table cell)
	> look for any number of groups of 3 digits optionally preceeded by a thousand separator
	> look for a decimal portion; a decimal separator followed by any number of digits
	> look for an ANSI exponential
	> look for zero or more spaces then look ahead for a bar
*/
	static num_needle := "O)(?<=\|) *(\d{1,3}(?:[,.]?\d{3})*(?:[,.]\d++)?+(?:E\+\d+)?) *(?=\|)"
	
	
	static format_needle := "O)"
/*
	two commas/periods separated by three numbers reveal the number format
	> look for a comma/period
	> look backwards for 3 digits and a comma or period (either)
	> check the first and second matched subexpression to determine the separators
	> the first match is always the thousands separator
*/
	. "(?:(?<=(,|\.)\d{3})(,|\.))"
/*
	> Find a comma or a period
	> look behind for one digit
	> look ahead and make sure there ISN'T three numbers and a non-number
	> look ahead for at least one number followed by a non-number
	> Matches 1.11  and  1.1111   but not  1.111  as this is ambiguous
	(?<=\d[^,.\d])
*/
	. "|"
	. "(?:(?<=\d)(,|\.)(?!\d{3} *$)(?=\d+ *$))"
/*
	ANSI exponentials
	N.NNNNNNE+12   and  N,NNE+15
*/
	. "|"
	. "(?:(?<=\d)(\.|,)(?=\d*E\+\d+))"
	
	;IPv4 addresses can give us a false positive if all octets are three digits
	ignore_ip_add := "\d{3}\.\d{3}\.\d{3}\.\d{3}"
	
	
	;output variables
	dec_separator := ""
	thou_separator := ""
	
	position := 1			;current position in the input string
	num_count := 0			;count of numbers in the input string
	dot_count := 0			;count of numbers with a dot as the separator
	comma_count := 0		;count of numbers with a comma as the separator
	static threshold := 100	;dot_count or comma_count must reach this 
							;value to be considered the winner
	
	start_time := A_TickCount
	
	;TODO? Add a timeout here?
	while (	position != 0 
			AND dot_count < threshold 
			AND comma_count < threshold){
			
		;look for numbers
		position := RegexMatch(cb_with_newlines, num_needle, num_mo, position)
		
		;MsgBox % position . "`r`n'" . num_mo.0 . "'"
		
		if (position){
			
			;found a match, make sure it's not an exception
			if (RegexMatch(num_mo.0, ignore_ip_add)){
				position += StrLen(num_mo.0)
				continue
			}
			
			;found a valid number
			num_count++
			
			;found a number, check its format
			if (RegexMatch(num_mo.0, format_needle, mo)){
				ErrorLevel := 0
				if (mo.1)
					;the thousands separator is always the left one
					(mo.1 = ",") ? dot_count++ : comma_count++
				
				else if (mo.3)
					(mo.3 = ".") ? dot_count++ : comma_count++
				
				else if (mo.4)
					(mo.4 = ".") ? dot_count++ : comma_count++
				
				/*
				MsgBox % "position = " . position
				. "`r`nmain = " . mo.0
				. "`r`n$1 = " . mo.1 
				. "`r`n$2 = " . mo.2 
				. "`r`n$3 = " . mo.3 
				. "`r`n$4 = " . mo.4
				. "`r`n$5 = " . mo.5
				. "`r`n$6 = " . mo.6
				. "`r`n$7 = " . mo.7
				. "`r`n$8 = " . mo.8
				*/
			}
			;advance past the number we found
			position += StrLen(num_mo.0)
		}
		
	}
	
	if (dot_count = comma_count){
		;inconclusive from the input data
		ErrorLevel := 2
		return
	}
	
	dec_separator := dot_count > comma_count ? "." : ","
	thou_separator := dec_separator = "." ? "," : "."
	
	runtime := A_TickCount - start_time
	appendLog(num_count . " numbers processed; decimal separator = '" 
	. dec_separator . "' in " . runtime . " ms in cb_detectNumberFormat")
	
	;MsgBox % dot_count . ", " . comma_count
}

cb_repairWideTable(byref cb_with_newlines){
/*
	ALVGrid exports which are very wide lead to rows being broken up with a newline
	This often happens when exporting the SQL cursor/plan caches of various DBs in DBACOCKPIT
	
	Not completely certain what the max row width is.
	I think it's 1023, however, a column itself won't be broken, and the max column width is 255
	Therefore, broken rows will be  [(1023 - 255) = 768] characters long before the break
*/
	

/*
	The regex logic is:
	> Look for a newline end with \r\n
	> Look backwards and check for a column divider '|'
	> Look forwards something that is not a column divider
	> Look backwards for a really long line -> increases our confidence the row has been broken
	> If we found a broken line, include the newline `r`n in the match so it can be removed
*/
	static needle := "(?<=\|)\r\n(?!\|)(?<=.{768}\r\n)"
	
	;time this as it could give us performance problems
	;but turns out autohotkey is much much faster at this regex than notepad++
	start_time := A_TickCount
	
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, "", cnt)
	
	runtime := A_TickCount - start_time
	appendLog("made " . cnt . " replacements in " . runtime . " ms in cb_repairWideTable")
}

cb_repairNewLineInTableCell(byref cb_with_newlines){
	
	;some of the cell contents use UNIX line endings (i.e. only \n)
	;so make the \r quantifier "zero or one"
	static needle:="(?<!\|)(?<!-------)\r?\n(?!\|)(?!-------)"
	cb_with_newlines:=RegexReplace(cb_with_newlines, needle, " ", cnt)
	appendLog("made " . cnt . " replacements in cb_repairNewLineInTableCell")
}


cb_removeWhiteSpace(byref cb_with_newlines){
	static needle:=" *\| *"
	
	start_time := A_TickCount
	
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, "|", rep_cnt)
	
	runtime := A_TickCount - start_time
	appendLog("made " . rep_cnt . " replacements in " . runtime . " ms in cb_removeWhiteSpace")
}

cb_removeLeadingBar(byref cb_with_newlines){
	static needle:="((?<=\r\n)\|)|(^\|)"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle)
}

cb_removeHorizontalLines(byref cb_with_newlines){
	static needle := "-------*-------\r\n"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle)
	
}

cb_replaceSQLConcat(byref cb){
/*
	SQL cache ouput may contain strings with concat operators -> ||
	this messes with Excel's delimiting
*/
	static needle:="\|\|"
	static rep:="++"
	cb:=RegexReplace(cb, needle, rep)
}


cb_formatSimple(byref cb_with_newlines){
/*
	Here we're just going to change the date format, remove the whitespace, and the horizontal bars from the table
*/
	
	
	cb_array := StrSplit(cb_with_newlines, "`r`n")
	
	;cb_getTableStartEnd(cb_array, start_i, end_i)
	
	
	;remove empty lines at the end
	while (cb_array[cb_array.MaxIndex()] = "")
		cb_array.pop()
	
	for i, line in cb_array{
		cb_array[i] := RegExreplace(line, " *\| *", "|")
	}
	
	new_str :=
	for i, line in cb_array{
		new_str .= line . "`r`n"
	}

	
	cb_with_newlines := new_str
}
