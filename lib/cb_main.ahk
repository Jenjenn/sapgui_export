/*
	Contains clipboard processing-related functions
*/


cb_removeInitialHeader(byref cb_with_newlines)
{
	/*
		if there is a header such as:
		
		2019.04.29                     Dynamic List Display                            1
		--------------------------------------------------------------------------------
		
		Then remove it here
	*/
	
	static needle := "^.*Dynamic List Display *\d\r\n-------*\r\n"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, , , 1)
}

cb_removeTrailingPage(byref cb_with_newlines)
{
	static needle := "\r\nPage: *\d*$"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle)
}

cb_detectNumberFormat(byref cb_with_newlines, byref dec_separator, byref thou_separator)
{

/*
	TODO: Some screens output a space as the thousands separator...

	Assumes:
	> numbers have a comma or a dot as the decimal separator
	> numbers are optionally formatted in groups of 3 digits separated by a dot/comma
	
	To increase robustness, we determine the separator by popular occurrence
	(dot_count and comma_count)
	If a single cell contains comma as the separator and appears first, it spoils 
	the whole data set
*/

	appendLog("starting number format search")

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
	static num_needle := "(?<=\|) *(\d{1,3}(?:[,.]?\d{3})*(?:[,.]\d++)?+(?:E\+\d+)?) *(?=\|)"
	
	; we pull the 1st sub match (match 0 = the whole expression)
	
	static format_needle := ""
/*
	two commas/periods separated by three numbers reveal the number format
	> look for a comma/period
	> look backwards for 3 digits and a comma or period (either)
	> check the first and second matched subexpression to determine the separators
	> the first match is always the thousands separator
	> these are matches 1 and 2
*/
	. "(?:(?<=(,|\.)\d{3})(,|\.))"
/*
	> Find a comma or a period
	> look behind for at least one digit
	> look ahead and make sure there ISN'T three numbers and a non-number
	> look ahead for at least one number followed by a non-number
	> Matches 1.11  and  1.1111   but not  1.111  as this is ambiguous
	> this is match 3
*/
	. "|"
	. "(?:(?<=\d)(,|\.)(?!\d{3}$)(?=\d+$))"
/*
	> Find a comma or a period
	> look behind for a zero with no other digits
	> the comma/period is the decimal separator
	this is match 4
*/
	. "|"
	. "(?:(?<=^0)(,|\.))"
/*
	ANSI exponentials
	N.NNNNNNE+12   and  N,NNE+15
	this is match 5
*/
	. "|"
	. "(?:(?<=\d)(\.|,)(?=\d*E\+\d+))"
	
	; IPv4 addresses can give us a false positive if all octets are three digits
	ignore_ip_add := "^\d{3}\.\d{3}\.\d{3}\.\d{3}$"
	
	
	; output variables
	dec_separator := ""
	thou_separator := ""
	
	position := 1			; current position in the input string
	num_count := 0			; count of numbers in the input string
	static max_nums := 8000 ; a timeout in case the number format search takes too long
	dot_count := 0			; count of numbers with a dot as the separator
	comma_count := 0		; count of numbers with a comma as the separator
	static threshold := 100	; dot_count or comma_count must reach this value to be considered the winner
	
	start_time := A_TickCount
	
	; TODO: Add a timeout here?
	while (	position != 0 
			AND dot_count < threshold 
			AND comma_count < threshold){
			
		; look for numbers
		position := RegexMatch(cb_with_newlines, num_needle, num_mo, position)
		
		;MsgBox % position . "`r`n'" . num_mo.0 . "'"
		
		if (position){
			
			; we check for number format against match 1, but add to position based on match 0
			
			; found a match, make sure it's not an exception
			if (RegexMatch(num_mo.1, ignore_ip_add)){
				position += StrLen(num_mo.0)
				continue
			}
			
			; found a valid number
			num_count++
			
			;MsgBox % num_mo.1
			
			; found a number, check its format
			if (RegexMatch(num_mo.1, format_needle, mo)){
				ErrorLevel := 0
				
				if (mo.1)			; three digits surrounded by two dots/commas
					; the thousands separator is always the left one
					(mo.1 = ",") ? dot_count++ : comma_count++
				
				else if (mo.3)		; decimal separator followed by {1,2,4,5,...} digits
					(mo.3 = ".") ? dot_count++ : comma_count++
				
				else if (mo.4)		; decimal separator preceeded by exactly one zero
					(mo.4 = ".") ? dot_count++ : comma_count++
				
				else if (mo.5)		; exponential
					(mo.5 = ".") ? dot_count++ : comma_count++
				
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
			; advance past the number we found
			position += StrLen(num_mo.0)
		}
		
		if (num_count > max_nums){
			appendLog("looked at " . max_nums " numbers, breaking")
			break
		}
		
	}
	
	if (dot_count = comma_count){
		appendLog("number format is ambiguous")
		ErrorLevel := 2
		return
	}
	
	dec_separator := dot_count > comma_count ? "." : ","
	thou_separator := dec_separator = "." ? "," : "."
	
	runtime := A_TickCount - start_time
	appendLog(num_count . " numbers processed in " . runtime . " ms; decimal separator = ' "  . dec_separator . " '")
	
	;MsgBox % dot_count . ", " . comma_count

}  ; cb_detectNumberFormat

cb_repairWideTable(byref cb_with_newlines)
{
/*
	ALVGrid exports which are very wide lead to rows being broken up with a newline
	This often happens when exporting the SQL cursor/plan caches of various DBs in DBACOCKPIT
	
	Not completely certain what the max row width is.
	I think it's 1023, however, a column itself won't be broken, and the max column width is 255
	Therefore, broken rows will be at least [(1023 - 255) = 768] characters long before the break
*/
	

/*
	The regex logic is:
	> Look for a newline end with \r\n
	> Look backwards and check for a column divider '|'
	> Look forwards something that is not a column divider
	> Look forwards for something that is not a divider line
	> Look backwards for a really long line -> increases our confidence the row has been broken
	> If we found a broken line, include the newline `r`n in the match so it can be removed
*/
	static needle := "("
	. "(?<=\|)\r\n(?!\|)(?!-------)(?<=.{768}\r\n)"
	. ")|("
/*
	Do the same but backwards
*/
	. "(?<!\|)(?<!-------)\r\n(?=\|)(?<=.{768}\r\n)"
	. ")"
	
	start_time := A_TickCount
	
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, "", cnt)
	
	runtime := A_TickCount - start_time
	appendLog(cnt . " replacements in " . runtime . " ms in cb_repairWideTable")

}  ; cb_repairWideTable


cb_repairNewLineInTableCell(byref cb_with_newlines)
{
	
	; some of the cell contents use UNIX line endings (i.e. only \n)
	; so make the \r quantifier "zero or one"
	static needle := "(?<!\|)(?<!-------)\r?\n(?!\|)(?!-------)"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, " ", cnt)
	appendLog(cnt . " replacements in cb_repairNewLineInTableCell")
}


cb_removeWhiteSpace(byref cb_with_newlines)
{
	static needle := " *\| *"
	
	start_time := A_TickCount
	
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, "|", rep_cnt)
	
	runtime := A_TickCount - start_time
	appendLog(rep_cnt . " replacements in " . runtime . " ms")
}

cb_removeLeadingBar(byref cb_with_newlines)
{
	
	start_time := A_TickCount

	static needle := "((?<=\r\n)\|)|(^\|)"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, "", rep_cnt)
	
	runtime := A_TickCount - start_time
	appendLog(rep_cnt . " removals in " . runtime . " ms")
}

cb_removeHorizontalLines(byref cb_with_newlines)
{

	start_time := A_TickCount
	
	static needle := "------*-----\r\n"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle, "", cnt1)
	
	static needle2 := "------*-----$"
	cb_with_newlines := RegexReplace(cb_with_newlines, needle2, "", cnt2)
	
	rep_cnt := cnt1 + cnt2
	
	runtime := A_TickCount - start_time
	appendLog(rep_cnt . " removals in " . runtime . " ms")
	
}

cb_removeBlankLines(byref cb_with_newlines)
{

	start_time := A_TickCount
	
	static needle1 := "\r\n(?=\r\n)"
	static needle2 := "^\r\n"
	static needle3 := "\r\n$"
	
	cb_with_newlines := RegExReplace(cb_with_newlines, needle1, "", cnt1)
	cb_with_newlines := RegExReplace(cb_with_newlines, needle2, "", cnt2)
	cb_with_newlines := RegExReplace(cb_with_newlines, needle3, "", cnt3)
	
	rep_cnt := cnt1 + cnt2 + cnt3
	
	runtime := A_TickCount - start_time
	appendLog("made " . rep_cnt . " removals in " . runtime . " ms")
	
}

cb_convertDateToNA(byref cb)
{
	static needle := "(\d\d)\.(\d\d)\.(\d\d\d\d)"
	cb := RegExReplace(cb, needle, "$3/$2/$1")
}

cb_replaceSQLConcat(byref cb)
{
/*
	SQL cache ouput may contain strings with concat operators -> ||
	this messes with Excel's delimiting
*/
	static needle := "\|\|"
	static rep := "++"
	cb := RegexReplace(cb, needle, rep)
}

cb_replaceCharAtPos(byref cb, position, newchar)
{
	cb := RegexReplace(cb, ".", newchar, , 1, position)
}