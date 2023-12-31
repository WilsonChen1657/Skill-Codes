;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
;Developer: Derek Hsu
;Starting Date: 06/12/2018 - _Derek06122018
;Introduction: this skill program is used to read xlsx file by unzipping it to 4 files, which are
;	1. _rels directory
;	2. docProps directory
;	3. xl directory
;	4. [Content_Type].xml
;	
;	all of the raw data
;	1. Cells values are stored in xl>worksheets>sheet?.xml
;		1. if it is a number value, then it'll be stored in this sheet?.xml
;		2. if it is a string value, then it'll be stored in xl>sharedStrings.xml
;	2. Sheetnames have been stored in xl>workbook.xml
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( init_Derek06122018()
	setq( _to_run nil)
	setq( _sel_sheet_id nil)
	setq( _work_path getWorkingDir())
	setq( _sheet_file "workbook.xml")
	setq( _sharedstring_file "sharedStrings.xml")
	setq( _excel_form_name "Excel_Sheet_Selector.form")
;	setq( _excel_table_name "Excel_Sheet[0].table")
;	setq( _excel_csv_name "Excel_sheet[0].csv")
	setq( _excel_table_form "Excel_Sheet[%d].table")
	setq( _excel_csv_form "Excel_sheet[%d].csv")
	setq( _valid_ext_ls list( ".xlsx" ".xlsm"))
	
	setq( _sheet_addr strcat( _work_path "/" _sheet_file))
	setq( _sharedstring_addr strcat( _work_path "/" _sharedstring_file))
	
	setq( _alphabet_total 26)
	setq( _alphabet_ls list( nil 'A 'B 'C 'D 'E 'F 'G 'H 'I 'J 'K 'L 'M 'N 'O 'P 'Q 'R 'S 'T 'U 'V 'W 'X 'Y 'Z))
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( get_number_by_alphabet_Derek06122018( word)
	prog( ( str_len left right result)
		unless( or( stringp( word) symbolp( word)) 
			println( "ArgErr: get_number_by_alphabet() - word is not a symbol or string") 
			return( nil)
		)
		
		when( symbolp( word) (word = symbolToString( word)))
		
		str_len = strlen( word)
		when( (str_len > 2) printf( "ArgErr: get_number_by_alphabet() - length of word[%s] has to be less equal than 2\n" word) return( nil))
		word = upperCase( word)
		
		if( onep( str_len) then
			result = listnindex( _alphabet_ls getchar( word 1))
		else
			left = listnindex( _alphabet_ls getchar( word 1))
			right = listnindex( _alphabet_ls getchar( word 2))
			result = left * _alphabet_total + right
		)
		
		return( result)
	)
)

procedure( get_alphabet_by_number_Derek06122018( number)
	prog( ( left right result)
		unless( and( plusp( number) integerp( number)) 
			println( "ArgErr: get_alphabet_by_number() - Number is not a plus integer") 
			return( nil)
		)
		
		if( (number > _alphabet_total) then
			left = number / _alphabet_total
			right = remainder( number _alphabet_total)
			cond(
				( (left > _alphabet_total)
					printf( "ERROR: get_alphabet_by_number() - Fail to define number[%d]\n" number)
					return( nil)
				)
				( zerop( right)
					left = nth( --left _alphabet_ls)
					right = nth( _alphabet_total _alphabet_ls)
				)
				( t
					left = nth( left _alphabet_ls)
					right = nth( right _alphabet_ls)
				)
			)
			
			result = strcat( left right)
			result = stringToSymbol( result)
		else
			result = nth( number _alphabet_ls)
		)
		
		return( result)
	)
)

procedure( get_attr_val_Derek06122018( attr section)
	prog( ( start start_len start2 len tmp1 tmp2 found result)
		unless( stringp( attr) println( "ArgErr: get_attr_val() - attr is not a string") return( nil))
		unless( stringp( section) println( "ArgErr: get_attr_val() - section is not a string") return( nil))
		
		found = nil
		sprintf( start " %s=" attr)
		
		sect = index( section start)
		
		;;; go to value start
		when( stringp( sect) (tail1 = index( sect "\"")))
		
		;;; go to value end
		when( stringp( tail1) (tail2 = index( substring( tail1 2) "\"")))
		
		when( and( sect tail1 tail2)
			sect_len = strlen( sect)
			result = substring( sect add1( strlen( start)) ( strlen( tail1) - strlen( tail2) + 1))
		)
		
		return( result)
	)
)

procedure( get_tag_pos_Derek06122018( key sentence @optional (start_pos nil))
	prog( ( head pos1 pos2 pos3 pos4 pos_ls pos)
		unless( key && sentence return( nil))
		
		when( start_pos
			sentence = substring( sentence start_pos)
		)
		
		unless( sentence return( nil))
		
		;;; get things by next head tag
		sprintf( head "<%s " key)
		pos1 = nindex( sentence head)
		
		sprintf( head "<%s>" key)
		pos2 = nindex( sentence head)
		
		sprintf( head "</%s>" key)
		pos3 = nindex( sentence head)
		when( pos3
			pos3 = pos3 + strlen( head)
		)
		
		head = "/>"
		pos4 = nindex( sentence head)
		when( pos4
			pos4 = pos4 + strlen( head)
		)
		
		pos_ls = list( pos1 pos2 pos3 pos4)
		pos_ls = remq( nil pos_ls)
		when( dtpr( pos_ls)
			pos = apply( 'min pos_ls)
		)
		
		when( pos && start_pos
			pos = start_pos + pos - 1
		)
		
		return( pos)
	)
)

procedure( get_section_Derek06122018( key sentence @optional (pos nil))
	prog( ( pos_start pos_end result)
		pos_start = get_tag_pos_Derek06122018( key sentence pos)
		
		when( pos_start
			pos_end = get_tag_pos_Derek06122018( key sentence add1( pos_start))
		)
		
		when( pos_start && pos_end
			section_length = pos_end - pos_start
			result = substring( sentence pos_start section_length)
		)
		
		return( result)
	)
)

procedure( get_section_val_Derek06122018( section)
	prog( ( start end result)
		unless( stringp( section) println( "ArgErr: get_section_val() - section is not a string") return( nil))
		
		start = nindex( section ">")
		end = rindex( section "<")
		
		when( stringp( end) (end = ( strlen( section) - strlen( end))))
		when( and( integerp( start) integerp( end))
			result = substring( section add1( start) (end - start))
		)
		
		return( result)
	)
)

procedure( get_sheetnames_Derek06122018()
	prog( ( in_port line all_line key section nm result_ls)
		unless( isFile( _sheet_addr) printf( "ArgErr: get_sheetnames() - [%s] is not a file\n" _sheet_addr) return( nil))
		in_port = infile( _sheet_addr)
		unless( inportp( in_port) println( "ERROR: get_sheetnames() - Fail to write file") return( nil))
		
		all_line = line = ""
		key = "<sheet "
		
		while( gets( line in_port) (all_line = strcat( all_line line)))
		close( in_port)

		line = index( all_line key)
		while( stringp( line)
			section = get_section_Derek06122018( "sheet" line 1)
			nm = get_attr_val_Derek06122018( "name" section)
			result_ls = append1( result_ls nm)

			line = substring( line strlen( section))
			line = index( line key)
		)
		
		when( dtpr( result_ls) (result_ls = filter_data_ls_Derek06122018( result_ls)))
		
		return( result_ls)
	)
)

procedure( get_sharedstrings_Derek06122018()
	prog( ( in_port line all_line key1 key2 section sect sect1 sect2 pos pos1 tmp nm result_ls)
		unless( isFile( _sharedstring_addr) printf( "ArgErr: get_sharedstrings() - [%s] is not a file\n" _sharedstring_addr) return( nil))
		in_port = infile( _sharedstring_addr)
		unless( inportp( in_port) println( "ArgErr: get_sharedstrings() - Fail to write file") return( nil))
		
		all_line = line = ""
		key1 = "<t>"
		key2 = "<t "
		
		while( gets( line in_port) (all_line = strcat( all_line line)))
		close( in_port)

		section = index( all_line "<si>")
		while( stringp( section)
			nm = ""
			pos = nindex( section "</si>")
			sect = substring( section 1 (pos + 4)) ;; 4 is the strlen of </si>~~

			sect1 = index( sect key1)
			sect2 = index( sect key2)
			while( or( stringp( sect1) stringp( sect2))
				; printf("%L --- %L\n" list( sect1) list( sect2))
				cond(
					( and( null( sect1) stringp( sect2)) (sect = sect2))
					( and( stringp( sect1) null( sect2)) (sect = sect1))
					( and( stringp( sect1) stringp( sect2))
						sect = if( ( strlen( sect1) < strlen( sect2)) sect2 sect1)
					)
				)
				
				pos1 = nindex( sect "</t>")
				tmp = substring( sect 1 (pos1 + 3))
				nm = strcat( nm get_section_val_Derek06122018( tmp))
				
				sect = substring( sect pos1) ;; 5 is the strlen of </si>
				sect1 = index( sect key1)
				sect2 = index( sect key2)
			)

			section = substring( section (pos + 5))
			section = index( section "<si>")

			result_ls = append1( result_ls nm)
		)
		
		when( dtpr( result_ls) (result_ls = filter_data_ls_Derek06122018( result_ls)))
		
		return( result_ls)
	)
)

procedure( form_builder_Derek06122018()
	prog( ( out_port)
		out_port = outfile( _excel_form_name "w")
		unless( outportp( out_port) println( "ERROR: form_builder() - Fail to write file") return( nil))
	
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")
		fprintf( out_port "FORM TOOLWINDOW \n")
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" 24 50)
		fprintf( out_port "HEADER \"Excel Sheet Selector vDerek\"\n")
		fprintf( out_port "POPUP <sheet_name_pop>\"a\"\"a\".\n")
		fprintf( out_port "TILE\n")
		
		fprintf( out_port "TEXT \"Please Select a sheet in this excel\" \n")
		fprintf( out_port "FLOC %d %d\n" 1 1)
		fprintf( out_port "ENDTEXT\n")
		
		;;;;; list
		
		fprintf( out_port "FIELD sheetname_list\n")
		fprintf( out_port "FLOC %d %d\n" 1 3)
		fprintf( out_port "ENUMSET %d\n" 21)
		fprintf( out_port "OPTIONS prettyprint ownerdrawn\n")
		fprintf( out_port "POP \"sheet_name_pop\"\n") ;;;;; this section is used to reference the list
		fprintf( out_port "ENDFIELD\n")
		
		;;;;; button
		
		fprintf( out_port "FIELD ok\n")
		fprintf( out_port "FLOC %d %d\n" 1 6)
		fprintf( out_port "MENUBUTTON \"OK\" %d %d\n" 10 2)
		fprintf( out_port "ENDFIELD\n\n")
		
		fprintf( out_port "FIELD cancel\n")
		fprintf( out_port "FLOC %d %d\n" 14 6)
		fprintf( out_port "MENUBUTTON \"Cancel\" %d %d\n" 10 2)
		fprintf( out_port "ENDFIELD\n\n")
		
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( excel_form_action_Derek06122018(excel_sel_sheet_form)
	prog( (field)
		unless( axlIsFormType( excel_sel_sheet_form) println( "ArgErr: excel_form_action() - excel_sel_sheet_form is not a form") return( nil))

		field = excel_sel_sheet_form->curField
		
		(case field
			("sheetname_list"
				_sel_sheet_id = excel_sel_sheet_form->curValue
			)
			("ok"
				axlFormClose( excel_sel_sheet_form)
				_to_run = t
			)
			("cancel"
				_sel_sheet_id = nil
				axlFormClose( excel_sel_sheet_form)
			)
		)
	)
)

procedure( create_form_Derek06122018( sheetname_ls)
	prog( (excel_sel_sheet_form i num_ls total bind_ls)
		unless( dtpr( sheetname_ls) println( "ArgErr: create_form() - sheetname_ls is not a list") return( nil))
		unless( forall( x sheetname_ls stringp( x)) println( "ArgErr: create_form() - sheetname_ls contains non-string element") return( nil))

		form_builder_Derek06122018()
		
		excel_sel_sheet_form = (axlFormCreate (gensym) _excel_form_name '("east" "outer") 'excel_form_action_Derek06122018 nil)
		unless( axlIsFormType( excel_sel_sheet_form) println( "ERROR: create_form() - Fail to create form") return( nil))

		total = length( sheetname_ls)
		for( i 1 total (num_ls = append1( num_ls sprintf( nil "sheet%d" i))))
		bind_ls = mapcar( 'list sheetname_ls num_ls)
		axlFormBuildPopup( excel_sel_sheet_form "sheetname_list" bind_ls)

		axlFormDisplay( excel_sel_sheet_form)
		deleteFile( _excel_form_name)
		
		(return t)
	)
)

procedure( read_file_Derek06122018( filename)
	prog( ( all_line in_port)
		
		in_port = infile( filename)
		unless( inportp( in_port)
			printf( "ERROR: get_sheet_content() - Fail to read %s\n" filename)
			return( nil)
		)
		
		all_line = ""
		while( gets( line in_port)
			all_line = strcat( all_line line)
		)
		
		close( in_port)
		
		;printf( "INFO: read_file() - Get content in %s\n\t%L\n" filename all_line)
		
		return( all_line)
	)
)

procedure( get_value_from_section_Derek06122018( section tag)
	;;;;; "<v>23</v>" - get 23 from it
	prog( (parts total_parts part start_tag_pos value_pos value)
		; axlStringCSVParse will error in Cadence 16.6 - Wilson_20220324
		;parts = axlStringCSVParse( section t ">")
		parts = parseString( section ">")
		
		total_parts = length( parts) - 1
		for( i 0 total_parts
			part = nth( i parts)
					
			printf( "total parts %d" total_parts)
			when( index( part tag) && null( start_tag_pos)
				start_tag_pos = i
			)
		)

		
		when( numberp( start_tag_pos)
			value_pos = start_tag_pos + 1
			value = nth( value_pos parts)
			value = car( parseString( value "<"))
		)
		
		return( value)
	)
)

procedure( get_addr_from_section_Derek06122018( section)
	prog( ( addr)
		addr = get_attr_val_Derek06122018( "r" section)
		addr = substring( addr 2 ((strlen addr) - 2))
		
		return( addr)
	)
)

procedure( get_rc_from_addr_Derek06122018( addr)
	prog( ( col row col_text row_text)
	
		col = row =0
		
		rexCompile( "\\([A-Z]+\\)\\([0-9]+\\)")
		when( rexExecute( addr)
			col_text = rexSubstitute( "\\1")
			row_text = rexSubstitute( "\\2")
		)
		
		when( stringp( col_text)
			col = get_number_by_alphabet_Derek06122018( col_text)
		)
		
		when( stringp( row_text)
			row = atoi( row_text)
		)
		
		row_col = list( row col)
		
		
		return( row_col)
	)
)

procedure( get_sheet_content_Derek06122018( sharedstring_ls sheet_id row_limits col_limits)
	prog( ( file_addr cell_table in_port key tmp line all_line section nm addr pos row to_limit len_old len_new)
		unless( dtpr( sharedstring_ls) println( "ArgErr: get_sheet_content() - sharedstring_ls is not a dtpr") return( nil))
		unless( stringp( sheet_id) println( "ArgErr: get_sheet_content() - sheet_id is not a string") return( nil))
		unless( !minusp( row_limits) && integerp( row_limits)
			println( "ArgErr: get_sheet_content() - row_limits is not a plusp integer")
			return( nil)
		)
		unless( !minusp( col_limits) && integerp( col_limits)
			println( "ArgErr: get_sheet_content() - col_limits is not a plusp integer")
			return( nil)
		)

		sprintf( file_addr "%s/%s.xml" _work_path sheet_id)
		all_line = read_file_Derek06122018( file_addr)
		unless( stringp( all_line) return( nil))
		
		;;;;; reduce all line
		unless( zerop( row_limits)
			sprintf( row_section "<row r=\"%d\"" row_limits)
			pos = nindex( all_line row_section)
			when( integerp( pos)
				all_line = substring( all_line 1 sub1( pos))
			)
		)

		cell_table = makeTable( "cell_table" nil)

		to_limit = nil
		key = "<c "
		line = index( all_line key)
		while( and( stringp( line) null( to_limit))
			section = get_section_Derek06122018( "c" line)
			nm = get_section_Derek06122018( "v" section)

			if( stringp( nm) then
				;printf( "INFO: get_sheet_content() - value:[%L] section:[%L]\n" nm section)
				
				; nm = substring( nm 4 ((strlen nm) - 7))
				nm = get_value_from_section_Derek06122018( nm "v")
				when( nindex( section "t=\"s\"")
					nm = nth( atoi( nm) sharedstring_ls)
				)

				addr = get_addr_from_section_Derek06122018( section)
				row_col = get_rc_from_addr_Derek06122018( addr)
				row = car( row_col)
				col = cadr( row_col)
				
				when( zerop( row) || zerop( col)
					printf( "ERROR: get_sheet_content() - Failt to get address(row=%L col=&L) in section[%L]\n" row col section)
					to_limit = t
				)
				
				;;;;; data access process
				when( ( zerop( row_limits) || row <= row_limits) && ( zerop( col_limits) || col <= col_limits)
					cell_table[ addr] = nm
				)
				
				;;;;; stop and process
				when( !zerop( row_limits) && row > row_limits
					to_limit = t
				)
				
				;;;;; go to next section process
				if( !zerop( col_limits) && col > col_limits then
					line = index( line "<row")
				else
					;;;;; remove the current section, otherwise, it will always stay at the same location
					line = substring( line strlen( section))
					line = index( line key)
				)
			else
				;;;;; remove the current section, otherwise, it will always stay at the same location
				line = substring( line strlen( section))
				line = index( line key)
			)
		)

		unless( dtpr( cell_table->?)
			cell_table = nil
		)
		
		return( cell_table)
	)
)

procedure( sort_addr_Derek06122018(a b)
	prog( (a1 a2 b1 b2 result)
		unless( stringp( a) println( "ArgErr: sort_addr() - a is not a string") return( nil))
		unless( stringp( b) println( "ArgErr: sort_addr() - b is not a string") return( nil))
		
		a = upperCase( a)
		b = upperCase( b)

		rexCompile("[A-Z]+")
		unless( rexExecute( a) printf( "ERROR: Fail to get [A-Z] from [%s]\n" a) return( nil))
		a1 = rexSubstitute( "\\0")
		unless( rexExecute( b) printf( "ERROR: Fail to get [A-Z] from [%s]\n" b) return( nil))
		b1 = rexSubstitute( "\\0")

		a2 = substring( a add1( strlen( a1)))
		b2 = substring( b add1( strlen( b1)))
		
		;(return ((atoi a2) < (atoi b2)))
		
		result = if( equal( a2 b2) alphalessp( a1 b1) ( atoi( a2) < atoi( b2)))
		
		return( result)
	)
)

procedure( output_cell_table_Derek06122018( table_filename cell_table)
	prog( ( out_port key val_ls)
		unless( stringp( table_filename) println( "ArgErr: output_cell_table() - table_filename is not a string") return( nil))
		when( isFile( table_filename) deleteFile( table_filename))
		out_port = outfile( table_filename "w")
		unless( outportp( out_port) println( "ERROR: output_cell_table() - Fail to write cell table") return( nil))

		val_ls = tableToList( cell_table)
		val_ls = sortcar( val_ls 'sort_addr_Derek06122018)
	
		foreach( key val_ls fprintf(  out_port "[%s],%s\n" car( key) cadr( key)))
		
		close( out_port)
		
		return( t)
	)
)

procedure( get_max_row_from_table_Derek06122018( key_ls)
	prog( ( row max_row)
		unless( dtpr( key_ls) println( "ArgErr: get_max_row_from_table() - key_ls is not a dtpr") return( nil))
		unless( forall( k key_ls stringp( k)) println( "ArgErr: get_max_row_from_table() - key_ls is not a string list") return( nil))

		max_row = 0
		rexCompile( "^[A-Z]+\\([0-9]+\\)$")
		foreach( key key_ls
			when( rexExecute( key)
				row = rexSubstitute( "\\1")
				row = atoi( row)

				when( (row > max_row) (max_row = row))
			)
		)
		
		when( zerop( max_row) (max_row = nil))
		
		return( max_row)
	)
)

procedure( get_max_col_from_table_Derek06122018( key_ls)
	prog( ( col char max_col)
		unless( dtpr( key_ls) println( "ArgErr: get_max_col_from_table() - key_ls is not a dtpr") return( nil))
		unless( forall( k key_ls stringp( k)) println( "ArgErr: get_max_col_from_table() - key_ls is not a string list") return( nil))

		max_col = 0
		rexCompile( "^\\([A-Z]+\\)[0-9]+$")
		foreach( key key_ls
			when( rexExecute( key)
				char = rexSubstitute( "\\1")
				char = stringToSymbol( char)
				col = get_number_by_alphabet_Derek06122018( char)

				if( plusp( col) then
					when( (col > max_col) (max_col = col))
				else
					return( nil)
				)
			)
		)
		
		when( zerop( max_col) (max_col = nil))
		
		return( max_col)
	)
)

procedure( output_csv_Derek06122018( csv_filename cell_table)
	prog( ( out_port key_ls max_row max_col row col csv_line_ls csv_ls csv_line char cell )
		unless( stringp( csv_filename) println( "ArgErr: output_csv() - csv_filename is not a string") return( nil))
		unless( tablep( cell_table) println( "ArgErr: output_csv() - cell_table is not a table") return( nil))

		key_ls = cell_table->?
		max_row = get_max_row_from_table_Derek06122018( key_ls)
		max_col = get_max_col_from_table_Derek06122018( key_ls)

		row = 1
		csv_line_ls = nil
		while( (row <= max_row)
			col = 1
			csv_ls = nil

			while( (col <= max_col)
				char = get_alphabet_by_number_Derek06122018( col++)

				if( symbolp( char) then
					sprintf( key "%s%d" char row)
					cell = cell_table[key]

					unless( stringp( cell) (cell = ""))
					when( index( cell ",") sprintf( cell "\"%s\"" cell))
					
					csv_ls = append1( csv_ls cell)
				else
					return( nil)
				)
			)

			csv_line = buildString( csv_ls ",")
			csv_line_ls = append1( csv_line_ls csv_line)
			row++
		)

		;;; output to csv file
		when( isFile( csv_filename) deleteFile( csv_filename))
		out_port = outfile( csv_filename "w")
		unless( outportp( out_port) println( "ERROR: output_csv() - Fail to write file") return( nil))
		foreach( line csv_line_ls fprintf( out_port "%s\n" line))
		close( out_port)
	
		return( t)
	)
)

procedure( filter_data_ls_Derek06122018(string_ls)
	prog( (result)
		unless( dtpr( string_ls) println( "ArgErr: filter_data_ls() - string_ls is not a list") return( nil))
		unless( forall( x string_ls stringp( x)) println( "ArgErr: filter_data_ls() - string_ls contain non-string element") return( nil))
		
		result = string_ls
		
		;;;;; remove \"
		rexCompile( "\"")
		result = mapcar( lambda( (x) rexReplace(x "" 0)) result)
		
		;;;;; replace \n
		rexCompile( "\n")
		result = mapcar( lambda( (x) rexReplace(x "[enter]" 0)) result)
		
		;;;;; replace &amp;
		rexCompile( "&amp;")
		result = mapcar( lambda( (x) rexReplace(x "and" 0)) result)
		
		return( result)
	)
)

procedure( get_sheet_id_Derek06122018( sheetname_ls @optional (global_sheets nil))
	prog( ( number total result)
		unless( dtpr( sheetname_ls) println( "ArgErr: get_sheet_id() - sheetname_ls is not a list") return( nil))

		if( stringp( global_sheets) then
			rexCompile( "sheet\\([0-9]+\\)")
			
			if( rexExecute( global_sheets) then
				total = length( sheetname_ls)
				number = atoi( rexSubstitute( "\\1"))
				
				unless( (number > total)
					result = global_sheets
				)
			else
				number = listnindex( sheetname_ls global_sheets)
				
				unless( integerp( number)
					printf( "ERROR: get_sheet_id() - sheetname[%s] does not exists\n" global_sheets)
					return( nil)
				)
				
				sprintf( result "sheet%d" add1( number))
			)
		else
			if( onep( length( sheetname_ls)) then
				;;; if there is only one sheet in this excel, then get this one directly
				result = "sheet1"
			else
				;;; if there are more than one sheet in this excel, then select by user
				create_form_Derek06122018( sheetname_ls)
				if( _to_run
					result = _sel_sheet_id
					_sel_sheet_id = nil
				)
			)
		)
		
		return( result)
	)
)

procedure( add_double_quote_to_space_on_addr_Derek06122018( address)
	;; address = "D:/workspace/boards/brd jimba"
	prog( ( str_ls)
		unless( stringp( address) println( "ArgErr: add_double_quote_to_space_on_addr() - address is not a string") return( nil))

		str_ls = parseString( address "/")
		str_ls = mapcar( lambda( (x) if( index( x " ") strcat( "\"" x "\"") x)) str_ls)
		address = buildString( str_ls "/")
		
		return( address)
	)
)

procedure( extract_xlsx_Derek06122018( xlsx_addr question_to_select)
	prog( ( extension excel_name msg filter)
		unless( sh( "\"C:\\Program Files\\7-Zip\\7z\"") 
			println( "ERROR: extract_xlsx() - Please install 7-zip to C:\\Program Files\\7-Zip\\7z") 
			return( nil)
		)
		unless( or( null( question_to_select) stringp( question_to_select)) 
			println( "ERROR: extract_xlsx() - question_to_select is neither nil or string") 
			return( nil)
		)

		unless( xlsx_addr
			msg = if( stringp( question_to_select) question_to_select "Please select a xlsx file")
			if( default_xlsm
				filter = "All xlsm files(*.xlsm)|*.xlsm|All xlsm files(*.xlsm)|*.xlsm"
				filter = "All xlsx files(*.xlsx)|*.xlsx|All xlsx files(*.xlsx)|*.xlsx"
			)
			xlsx_addr = axlDMFileBrowse( nil nil ?title msg ?optFilters filter)
		)
		
		unless( stringp( xlsx_addr) return( nil))
		
		unless( isFile( xlsx_addr) println( "ERROR: extract_xlsx() - No file has been selected. program halt") (return nil))
		
		extension = substring( xlsx_addr ( strlen( xlsx_addr) - 4))
		unless( member( extension _valid_ext_ls)
			println("ERROR: extract_xlsx() - Please select a xlsx file")
			return( nil)
		)
		
		;; add " to the section having spacing
		excel_name = lastelem( parseString( xlsx_addr "/"))
		xlsx_addr = add_double_quote_to_space_on_addr_Derek06122018( xlsx_addr)
		xlsx_addr = axlOSBackSlash( xlsx_addr)

		sprintf( cmd "C:\\\"Program Files\"\\7-Zip\\7z e %s -y" xlsx_addr)
		unless( sh( cmd) println( "ERROR: extract_xlsx() - Fail to extract the excel file. Please close excel before using it") return( nil))
		
		return( excel_name)
	)
)

procedure( get_sheet_id_ls_Derek06122018( sheetname_ls global_sheets)
	prog( ( sheet_id sheet_get_opt sheet_id_ls )
		unless( dtpr( sheetname_ls)
			println( "ArgErr: get_sheet_id_ls() - sheetname_ls is not a dtpr")
			return( nil)
		)

		when( null( global_sheets) && onep( length( sheetname_ls))
			global_sheets = car( sheetname_ls)
		)
		
		cond(
			( global_sheets == ""
				sheet_id_ls = mapcar( lambda( (x) get_sheet_id_Derek06122018( sheetname_ls x)) sheetname_ls)
			)
			( stringp( global_sheets)
				sheet_id = get_sheet_id_Derek06122018( sheetname_ls global_sheets)
				when( stringp( sheet_id)
					sheet_id_ls = list( sheet_id)
				)
				sheet_get_opt = global_sheets
			)
			( dtpr( global_sheets)
				foreach( us global_sheets
					sheet_id = get_sheet_id_Derek06122018( sheetname_ls us)
					
					when( stringp( sheet_id)
						sheet_id_ls = append1( sheet_id_ls sheet_id)
					)
				)
				
				sheet_get_opt = global_sheets
			)
			( t
				sheet_id = get_sheet_id_Derek06122018( sheetname_ls)
				when( stringp( sheet_id) (sheet_id_ls = list( sheet_id)))
				sheet_get_opt = "form selection"
			)
		)
		
		unless( dtpr( sheet_id_ls)
			printf( "ERROR: Fail to get sheet ID by %L\n" sheet_get_opt)
			return( nil)
		)
		
		return( sheet_id_ls)
	)
)

procedure( write_sheets_Derek06122018( sheet_id_ls excel_name non_table non_csv row_limits col_limits)
	prog( ( cnt cell_table csv_filename table_filename)
		unless( dtpr( sheet_id_ls) println( "ArgErr: write_sheets() - sheet_id_ls is not a dtpr") return( nil))
		unless( stringp( excel_name) println( "ArgErr: write_sheets() - excel_name is not a string") return( nil))
		unless( booleanp( non_table) println( "ArgErr: write_sheets() - non_table is not a boolean") return( nil))
		unless( booleanp( non_csv) println( "ArgErr: write_sheets() - non_csv is not a boolean") return( nil))
		unless( !minusp( row_limits) && integerp( row_limits)
			println( "ArgErr: write_sheets() - row_limits is not a plusp integer")
			return( nil)
		)
		unless( !minusp( col_limits) && integerp( col_limits)
			println( "ArgErr: write_sheets() - col_limits is not a plusp integer")
			return( nil)
		)

		cnt = 0
		foreach( sheet_id sheet_id_ls
			when( stringp( sheet_id)
				;;;;; create dictionary by selected sheets
				cell_table = get_sheet_content_Derek06122018( sharedstring_ls sheet_id row_limits col_limits)
				;foreach( k cell_table printf( "[%s] - %s\n" k cell_table[k]))
				
				unless( tablep( cell_table)
					printf( "ERROR: write_sheets() - Fail to create [%s] cell_table\n" sheet_id)
					return( nil)
				)
				
				;;;;; output cell table
				unless( non_table
					sprintf( table_filename _excel_table_form cnt)
					output_cell_table_Derek06122018( table_filename cell_table)
				)
				
				;;;;; convert the table to csv
				unless( non_csv
					sprintf( csv_filename _excel_csv_form cnt)
					output_csv_Derek06122018( csv_filename cell_table)
				)

				cnt++
				cond(
					( null( or( non_table non_csv))
						printf( "Successfully extract excel[%s] to '%s' and '%s', please check this out\n" excel_name table_filename csv_filename)
					)
					( and( null( non_table) non_csv)
						printf( "Successfully extract excel[%s] to '%s', please check this out\n" excel_name table_filename)
					)
					( and( non_table null( non_csv))
						printf( "Successfully extract excel[%s] to '%s', please check this out\n" excel_name csv_filename)
					)
				)
			)
		)
		
		return( t)
	)
)

procedure( manipulate_xlsx_main_Derek06122018( @key (xlsx_addr nil)
													(global_sheets nil)
													(question_to_select nil)
													(non_table nil)
													(non_csv nil)
													(row_limits 1000)
													(col_limits 1000)
													(default_xlsm nil))
	; manipulate_xlsx_main_Derek06122018( nil nil)
	;;; global_sheets:
	;;;		"": export all sheet
	;;;		nil: if there is only one, get this one directly
	;;;		   : if there are more than one sheet, select by form
	;;;		"sheet1": get sheet1
	;;;		"sheet name": get sheet by name
	prog( ( excel_name old_file_ls new_file_ls sheet_id_ls result)
		when( and( non_table non_csv) println( "Both of non_table and non_csv are nil") return( nil))
		unless( locker_main_Derek20210929() return( nil))
		
		unless( !minusp( row_limits) && integerp( row_limits)
			printf( "ArgErr: MAIN() - row_limits has to be a integer >=0. row_limits=%L\n" row_limits)
			return( nil)
		)
		
		unless( !minusp( col_limits) && integerp( col_limits)
			printf( "ArgErr: MAIN() - col_limits has to be a integer >=0. col_limits=%L\n col_limits")
			return( nil)
		)

		init_Derek06122018()
		
		old_file_ls = getDirFiles( getWorkingDir())
		
		;;; extract xlsc to number of file. get the file name as the result
		excel_name = extract_xlsx_Derek06122018( xlsx_addr question_to_select)
		unless( stringp( excel_name) return( nil))
		
		;;;;; get new file list
		new_file_ls = getDirFiles( getWorkingDir())
		new_file_ls = setof( x new_file_ls not( member( x old_file_ls)))
		
		;;;;; get string list
		sharedstring_ls = get_sharedstrings_Derek06122018()
		unless( dtpr( sharedstring_ls)
			println( "ERROR: manipulate_xlsx_main() - Fail to get sharedstring")
			return( nil)
		)
		printf( "Info: manipulate_xlsx_main() - Length of Shared string: %d\n" length( sharedstring_ls))
		
		;;;;; get all sheetname
		_sheetname_ls = get_sheetnames_Derek06122018()
		unless( dtpr( _sheetname_ls)
			println( "ERROR: manipulate_xlsx_main() - Fail to get sheetname")
			return( nil)
		)
		printf( "Info: manipulate_xlsx_main() - Sheetnames: %L\n" _sheetname_ls)
		
		;;;;; ask which sheet the user wants / by form
		sheet_id_ls = get_sheet_id_ls_Derek06122018( _sheetname_ls global_sheets)
		unless( dtpr( sheet_id_ls)
			return( nil)
		)

		result = write_sheets_Derek06122018( sheet_id_ls excel_name non_table non_csv row_limits col_limits)
		unless( result return( nil))
		
		;;;;; delete unzipped files and dir
		foreach( file new_file_ls
			when( isFile( file)
				deleteFile( file)
			)
		)
		printf( "INFO: MAIN() - Deleting [%L]\n" new_file_ls)

		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

(axlCmdRegister "manipulate_xlsx" 'manipulate_xlsx_main_Derek06122018)
; manipulate_xlsx_main_Derek06122018(?xlsx_addr "D:/workspace/boards/brd_assign_cset_accerating/Green_Bay_Assign_Class_Ecset_V16-0914_EE_SI.xlsm" ?global_sheets "Impedance" ?row_limits 50 ?col_limits 200)
; manipulate_xlsx_main_Derek06122018()
; skill (encrypt "c:/skill/manipulate_xlsx_v3d6.il" "c:/skill/manipulate_xlsx_v3d6.ile")
; (load "manipulate_xlsx_v3d6.il")
; (load "manipulate_xlsx_v3d6.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup