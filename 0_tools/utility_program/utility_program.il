/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/03/31                                                      #
#  Reference:                                                                  #
#  Purpose:                                                                    #
#       Utility programs for global usage                                      #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable
setq( _allegro_version axlVersion( 'version))
setq( _allegro_unit car( axlDBGetDesignUnits()))
setq( _allegro_path getWorkingDir())
setq( _skill_package_path "W:/footprint_building_aid_skill/1-0_skill_package/")

setq( _month_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
setq( _alphabet_total 26)
setq( _alphabet_ls list( nil 'A 'B 'C 'D 'E 'F 'G 'H 'I 'J 'K 'L 'M 'N 'O 'P 'Q 'R 'S 'T 'U 'V 'W 'X 'Y 'Z))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Trim_utilityprogram( str @optional (target " "))
	prog( ( tmp)
		if( str == nil then
			return( str)
		else
			if( strlen( str) == 0 then
				return( str)
			else
				tmp = str
				; printf("str is |||%s|||\n" tmp)
				while( substring( tmp 1 1) == target
					; printf("str is |||%s|||\n" tmp)
					if( strlen( tmp) == 1 then
						if( tmp == target then
							return( "")
						else
							return( tmp)
						)
					else
						tmp = substring( tmp 2 strlen( tmp))
					)
				)
				
				while( substring( tmp strlen( tmp) 1) == target
					; printf("str is |||%s|||\n" tmp)
					if( strlen(tmp) == 1 then
						if( tmp == target then
							return( "")
						else
							return( tmp)
						)
						else
						tmp = substring( tmp 1 strlen( tmp)-1)
					)
				)
				
				str = tmp
				return( str)
			)
		)
	) ; End Prog
) ; End Procedure


procedure( GetUnitValueByMils_utilityprogram( mil_value)
	prog( ( value)
		unless( numberp( mil_value)
			return( 0.0)
		)
		
		_allegro_unit = car( axlDBGetDesignUnits())
		value = 0.0
		case( _allegro_unit
			( "mils"
				value = mil_value
			)
			( "millimeters"
				value = axlMKSConvert( mil_value "MILS" "MM")
				;_mil_by_mm = 39.37
				;value = mil_value / _mil_by_mm
			)
		)
		
		return( value)
	)
)

procedure( GetUnitValueByMM_utilityprogram( mm_value)
	prog( ( value)
		unless( numberp( mm_value)
			return( 0.0)
		)
		
		_allegro_unit = car( axlDBGetDesignUnits())
		value = 0.0
		case( _allegro_unit
			( "mils"
				value = axlMKSConvert( mm_value "MM" "MILS")
			)
			( "millimeters"
				value = mm_value
			)
		)
		
		return( value)
	)
)

procedure( GetSchematicName_utilityprogram()
	; symbol = car( axlGetSelSet())
	prog( ( symbol_ls symbol schematic_name)
		symbol_ls = axlDBGetDesign()->symbols
		symbol = car( exists( s symbol_ls stringp( car( s->component->functions)->prop->LOGICAL_PATH)))
		unless( symbol
			return( "*Fail to find the schematic name*")
		)
		
		schematic_name = car( symbol->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		return( schematic_name)
	)
)

procedure( ReadCSVLine_utilityprogram( csv_filename @optional (skip_row 1))
	prog( ( in_port data_line_ls)
		in_port = infile( csv_filename)
		unless( inportp( in_port)
			printf( "ERROR: ReadCSVLine() - Fail to read csv [%s]\n" csv_filename)
			return( nil)
		)
		
		;;;;; normally, skip back link and title
		for( i 1 skip_row
			gets( data_line in_port)
		)
		
		;;;; get the content until the end
		while( gets( data_line in_port)
			when( stringp( data_line)
				data_line_ls = append1( data_line_ls data_line)
			)
		)
		
		close( in_port)
		return( data_line_ls)
	)
)

procedure( ReadTable_utilityprogram( table_filename table_name)
	prog( ( in_port table)
		unless( symbolp( table_name)
			println( "ArgErr: ReadTable() - table_name is not a symbol")
			return( nil)
		)
		
		unless( stringp( table_filename)
			println( "ArgErr: ReadTable() - table_filename is not a string")
			return( nil)
		)
		
		unless( isFile( table_filename)
			println( "ArgErr: ReadTable() - table_filename is not a file")
			return( nil)
		)
		
		in_port = infile( table_filename)
		unless( inportp( in_port)
			println( "ArgErr: ReadTable() - Fail to read table_filename")
			return( nil)
		)

		table = makeTable( table_name nil)
		
		while( gets( data_line in_port)
			when( and( index( data_line ",") stringp( data_line))
				data_ls = axlStringCSVParse( data_line ",")
				key = car( data_ls)
				val = buildString( cdr( data_ls) ",")
				;;
				if( and( index( key "[") index( key "]")) then
					key = substring( key 2 ( strlen( key) - 2))
					table[ key] = val
				else
					printf( "WARNING: ReadTable() - Fail to manipulate data_line[%s] in [%s]\n" data_line table_filename)
				)
			)
		)
		
		close( in_port)
		return( table)
	)
)

procedure( GetTableValue_utilityprogram( table row col data_type)
	prog( ( value_col cell value err_msg)		
		sprintf( cell "%s%d" col row)
		value = table[ cell]
		
		sprintf( err_msg "WARNING: GetDesignParamValue() - Fail to get value[%L] on row[%d] of sheet[Design_Param]" value row)
		value = CheckDataType_utilityprogram( value data_type err_msg)
		
		return( value)
	)
)

procedure( CheckDataType_utilityprogram( data type err_msg)
	prog( ( num unit result)
		unless( or( stringp( data) dtpr( data))
			printf( "ArgErr: CheckDataType() - data[%L] is not a string or a dtpr\n" data)
			printf( "\t%s\n" err_msg)
			return( nil)
		)
		
		unless( symbolp( type)
			println( "ArgErr: CheckDataType() - type is not a symbol")
			return( nil)
		)
		
		allow_pad_pad_conn_opts = list( "ALL_ALLOWED" "VIAS_PINS_ONLY" "VIAS_VIAS_ONLY" "MICROVIAS_MICROVIAS_ONLY" 
										"MICROVIAS_MICROVIAS_COINCIDENT_ONLY" "NOT_ALLOWED")
		allow_ts_opts = list( "NOT_ALLOWED" "ANYWHERE" "PINS_ONLY" "VIAS_PINS_ONLY")
		unit_ls = list( "MIL" "MM" "DEGREE" "INCH" "MICROMS" "CENTIMETER")
		yes_no = list( "YES" "NO")
		on_off = list( "ON" "OFF")
		true_false = list( "TRUE" "FALSE")
		smt_thru = list( "SMT TESTPAD" "THRU VIA")
		drc_ther = list( "DRC" "THERMAL/ANTI")
		artwork_type = list( "GERBER4X00" "GERBER6X00" "GERBER RS274X" "BARCO DPF" "MDA" "NON-GERBER")
		acute_angle_trim_control = list( "ROUND" "CHAMFERED" "FULL_ROUND")
		rou_squ = list( "Round" "Square")
		
		caseq( type
			( 'unit
				if( member( upperCase( data) unit_ls) then
					result = data
				else
					println( err_msg)
				)
			)
			( 'pin_voids
				; if data is 0.0, then individually present. if data is greater than 0.0, then in-line present
				result = atof( data)
				unless( floatp( result)
					println( err_msg)
					result = nil
				)
			)
			( 'trim_control
				if( member( data acute_angle_trim_control) then
					result = data
				else
					println( err_msg)
				)
			)
			( 'corner_style
				result = car( mapcan( lambda( (x) when( upperCase( x) == upperCase( data) list( x))) rou_squ))
				unless( result
					println( err_msg)
				)
			)
			( 'float
				result = atof( data)
				unless( floatp( result)
					println( err_msg)
					result = nil
				)
			)
			( 'not_minus_float
				result = atof( data)
				if( floatp( result)
					when( (minusp result)
						result = nil
						println( err_msg)
					)
					
					println( err_msg)
				)
			)
			( 'plus_float
				result = atof( data)
				unless( plusp( result)
					println( err_msg)
					result = nil
				)
			)
			( 'content
				when( zerop( strlen( data))
					println( err_msg)
					result = nil
				)
			)
			( 'padpadconn
				result = upperCase( data)
				unless( member( result allow_pad_pad_conn_opts)
					println( err_msg)
					result = nil
				)
			)
			( 'yesno
				result = upperCase( data)
				if( member( result yes_no) then
					result = equal( "YES" result)
				else
					println( err_msg)
					result = nil
				)
			)
			( 'onoff
				result = upperCase( data)
				if( member( result on_off) then
					result = equal( "ON" result)
				else
					println( err_msg)
					result = nil
				)
			)
			( 'truefalse_string
				result = upperCase( data)
				unless( member( result true_false)
					println( err_msg)
					result = nil
				)
			)
			( 'onoff_sym
				result = upperCase( data)
				if( member( result on_off) then
					result = stringToSymbol( lowerCase( result))
				else
					println( err_msg)
					result = nil
				)
			)
			( 'num_unit
				rexCompile( "^\\([0-9]+\\) \\([a-zA-Z]+\\)$")
				
				when( rexExecute( data)
					num = rexSubstitute( "\\1")
					unit = rexSubstitute( "\\2")
				)
				
				;;
				if( and( stringp( num) stringp( unit) plusp( atoi( num)) member( upperCase( unit) unit_ls)) then
					result = data
				else
					println( err_msg)
					result = nil
				)
			)
			( 'drc_ther
				result = upperCase( data)
				unless( member( result drc_ther)
					println( err_msg)
					result = nil
				)
			)
			( 'xy
				if( and( pairp( data) floatp( atof( car( data))) floatp( atof( cadr( data)))) then
					result = mapcar( 'atof data)
				else
					println( err_msg)
					result = nil
				)
			)
			( 'int
				result = atoi( data)
				unless( integerp( result)
					println( err_msg)
					result = nil
				)
			)
			( 'not_minus_int
				result = atoi( data)
				if( integerp( result) then
					when( (minusp result)
						result = nil
						println( err_msg)
					)
				else
					println( err_msg)
					result = nil
				)
			)
			( 'plus_int
				result = atoi( data)
				unless( plusp( result)
					println( err_msg)
					result = nil
				)
			)
			( 'allowts
				result = upperCase( data)
				unless( member( result allow_ts_opts)
					println( err_msg)
					return( nil)
				)
			)
			( 'vias_colon
				result = parseString( data ":")
				if( forall( x result axlLoadPadstack( x)) then
					result = data
				else
					println( err_msg)
					result = nil
				)
				
				;;; remove all the via which is not used in anywhere
				axlPurgePadstacks( 'via nil)
			)
			( t
				printf( "ERROR: correct_data_type() - Yet to support type[%s] to identify data[%s]\n" type data)
				result = nil
			)
		)
		
		return( result)
	)
)

procedure( GetLatestFileAddr_utilityprogram( directory filename_pattern)
	prog( (file_ls date_file_ls filename file_addr)
		file_ls = getDirFiles( directory)
		
		rexCompile( filename_pattern)
		foreach( file_name file_ls
			when( rexExecute( file_name)
				date = atoi( rexSubstitute( "\\1"))
				date_file_ls = append1( date_file_ls list( date file_name))
			)
		)
		unless( dtpr( date_file_ls)
			printf( "ERROR: Fail to find file at %s%s\n" directory filename_pattern)
			return( nil)
		)
		
		date_file_ls = sortcar( date_file_ls 'greaterp)
		filename = cadar( date_file_ls)
		file_addr = strcat( directory filename)
		return( file_addr)
	)
)

procedure( RemoveDuplicate_utilityprogram( data_ls)
	prog( ()
		data_ls = maplist( lambda( (xs) if( exists( x cdr( xs) x == car( xs)) nil car( xs))) data_ls)
		data_ls = remq( nil data_ls)
		
		return( data_ls)
	)
)

procedure( CheckIsCallable_utilityprogram( function_name file_name)
	prog( ()
		unless( isCallable( function_name)
			printf( "Please load [%s] to proceed\n" file_name)
			return( nil)
		)
		
		return( t)
	)
)

unless( isCallable( 'mapcon)
	defun( mapcon (fn @rest args)
		let( ((buf (ncons nil)))
			apply( map (lambda (@rest args) lconc( buf apply( fn args))) args)
			car( buf)
		)
	)
)

defun( UniqueList_utilityprogram ( data)
    foreach( mapcon data data
		unless( member( car( data) cdr( data))
			ncons( car( data))
		)
	)
)

procedure( CreateMeter_utilityprogram( title @optional (info_str ""))
	prog( ( result)
		result = axlMeterCreate( title info_str t)
		return( result)
	)
)

procedure( UpdateMeter_utilityprogram( meter_count meter_total @optional (info_str "") (info_str2 ""))
	let( ()
		unless( axlMeterIsCancelled()
			axlMeterUpdate( (100 * meter_count / meter_total) info_str info_str2)
		)
	)
)

procedure( HighLightObject_utilityprogram( obj_ls @key (color 1))
	let( ()
		; only "Groups" "Symbols" "Functions" "Nets" "Pins" "Vias" "Fingers" "DRC errors" can permanent highlight
		perm_highlight_ls = setof( x obj_ls member( x->objType list( "symbol" "net" "pin" "via")))
		temp_highlight_ls = setof( x obj_ls !member( x perm_highlight_ls))
		
		axlDBControl( 'highlightColor color)
		axlHighlightObject( perm_highlight_ls t)
		axlHighlightObject( temp_highlight_ls)
	)
)

procedure( ZoomIn_utilityprogram( xy @optional (tolerance 100))
	let( ( target_box zoom_box)
		axlZoomFit( 0)
		axlZoomCenter( nil xy)
		
		target_box = list( axlMXYAdd( xy -tolerance:-tolerance) axlMXYAdd( xy tolerance:tolerance))
		zoom_box = axlZoomBbox( nil)
		while( !axlIsPointInsideBox( nth( 0 zoom_box) target_box) && !axlIsPointInsideBox( nth( 1 zoom_box) target_box)
			axlZoomInOut( 0 1 xy)
			zoom_box = axlZoomBbox( nil)
		)
		
		axlZoomInOut( 0 -3 xy)
	)
)

procedure( SumNumbers_utilityprogram( numbers)
	let( ()
		apply( 'plus 0 0 numbers)
	)
)

procedure( RunReport_utilityprogram( cmd_format @optional (on_html nil))
	; cmd_format = %CDSROOT%\share\pcb\batchhelp\report.txt
	let( ( html_option cmd)
		html_option = if( on_html " -H" "")
		sprintf( cmd "report -v%s %s %%s" html_option cmd_format)
		axlRunBatchDBProgram( "report" cmd ?silent t)
	)
)

procedure( GetLogSeperator_utilityprogram( @optional (title "") (total_length 120))
	let( ( line_count seperator)
		unless( blankstrp( title)
			sprintf( title " %s " title)
		)
		
		line_count = total_length - strlen( title)
		seperator = ""
		for( i 1 (line_count / 2)
			seperator = strcat( seperator "=")
		)
		
		sprintf( seperator "%s%s%s\n" seperator title seperator)
	)
)

procedure( CreateShapeByPoints_utilityprogram( points layer)
	prog( ( path shape)
		; add the first point to complete the shape
		path = axlPathStart( append1( points car( points)))
		shape = car( axlDBCreateShape( path t layer))
		
		return( shape)
	)
)

procedure( OpenHelpFile_utilityprogram( target_file_name)
	let( ( help_path)
		help_path = "W:/footprint_building_aid_skill/0-0_Help/"
		OpenFile_utilityprogram( help_path target_file_name ".pdf")
	)
)

procedure( OpenFile_utilityprogram( file_path target_file_name extension)
	let( ( file_ls file_name)
		when( and( stringp( file_path) !blankstrp( file_path))
			file_ls = cddr( getDirFiles( file_path))
			file_name = car( setof( x file_ls and( index( x extension) index( x target_file_name))))
			when( file_name
				shell( strcat( file_path file_name))
			)
		)
	)
)

procedure( CreatePopup_utilityprogram()
	let( ( display_popup)
		display_popup = axlUIPopupDefine( nil list( list( "Done" 'axlFinishEnterFun) list( "Cancel" 'axlCancelEnterFun)))
		axlUIPopupSet( display_popup)
	)
)

procedure( CheckOKToProceed_utilityprogram()
	prog( ()
		unless( axlOKToProceed() 
			println( "Please done current function to use this program")
			return( nil)
		)
		
		return( t)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Parse datetime
;;; parse yyyyMMdd to Dec 28 16:57:06 1996
procedure( ParseDate_utilityprogram( date_str)
	prog( ( year month day month_v month_str base_time)
		unless( strlen( date_str) == 8
			println( "ERROR: Date format incorrect !! yyyyMMdd")
			return( nil)
		)
		
		year = substring( date_str 1 4)
		month = substring( date_str 5 2)
		day = substring( date_str 7 2)
		
		month_v = listToVector( _month_ls)
		month_str = month_v[ atoi( month)]
		
		; format : Dec 28 16:57:06 1996
		base_time = stringToTime( sprintf( nil "%s %s 00:00:00 %s" month_str day year))
		return( base_time)
	)
)
;;; input 'time' format using stringToTime
;;; return yyyy.MM.dd hh:mm:ss
procedure( ParseDateTimeToString_utilityprogram( date_time)
	prog( (date_time_str)
		date_time_str = timeToString( date_time)
		return( ParseDateTimeStrToFormat_utilityprogram( date_time_str))
	)
)
;;; input 'string' format using timeToString
;;; return yyyy.MM.dd hh:mm:ss
procedure( ParseDateTimeStrToFormat_utilityprogram( date_time_str)
	prog( (date time year month day hour minute second)
		sscanf( date_time_str "%s %d %d:%d:%d %d" month day hour minute second year)
		
		sprintf( date "%.4d.%.2d.%.2d" year listnindex( _month_ls month) day)
		sprintf( time "%.2d:%.2d:%.2d" hour minute second)

		result_str = strcat( date " " time)
		return( result_str)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Parse datetime

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Output CSV

procedure( OutputCSV_utilityprogram( csv_filename cell_table)
	prog( ( out_port key_ls max_row max_col row col csv_line_ls csv_ls csv_line char cell )
		unless( stringp( csv_filename) 
			println( "ArgErr: output_csv() - csv_filename is not a string") 
			return( nil)
		)
		
		unless( tablep( cell_table) 
			println( "ArgErr: output_csv() - cell_table is not a table") 
			return( nil)
		)

		key_ls = cell_table->?
		max_row = GetMaxRow_utilityprogram( key_ls)
		max_col = GetMaxCol_utilityprogram( key_ls)

		row = 1
		csv_line_ls = nil
		while( (row <= max_row)
			col = 1
			csv_ls = nil

			while( (col <= max_col)
				char = GetAlphabetByNumber_utilityprogram( col++)

				if( symbolp( char) then
					sprintf( key "%s%d" char row)
					cell = cell_table[key]

					unless( stringp( cell) 
						cell = ""
					)
					
					when( index( cell ",") 
						sprintf( cell "\"%s\"" cell)
					)
					
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
		when( isFile( csv_filename) 
			deleteFile( csv_filename)
		)
		
		out_port = outfile( csv_filename "w")
		unless( outportp( out_port) 
			println( "ERROR: output_csv() - Fail to write file") 
			return( nil)
		)
		
		foreach( line csv_line_ls 
			fprintf( out_port "%s\n" line)
		)
		
		close( out_port)
		return( t)
	)
)

procedure( GetMaxRow_utilityprogram( key_ls)
	prog( ( row max_row)
		unless( dtpr( key_ls) 
			println( "ArgErr: get_max_row_from_table() - key_ls is not a dtpr") 
			return( nil)
		)
		
		unless( forall( k key_ls stringp( k)) 
			println( "ArgErr: get_max_row_from_table() - key_ls is not a string list") 
			return( nil)
		)

		max_row = 0
		rexCompile( "^[A-Z]+\\([0-9]+\\)$")
		foreach( key key_ls
			when( rexExecute( key)
				row = rexSubstitute( "\\1")
				row = atoi( row)

				when( (row > max_row) 
					max_row = row
				)
			)
		)
		
		when( zerop( max_row) 
			(max_row = nil)
		)
		
		return( max_row)
	)
)

procedure( GetMaxCol_utilityprogram( key_ls)
	prog( ( col char max_col)
		unless( dtpr( key_ls) 
			println( "ArgErr: get_max_col_from_table() - key_ls is not a dtpr") 
			return( nil)
		)
		
		unless( forall( k key_ls stringp( k)) 
			println( "ArgErr: get_max_col_from_table() - key_ls is not a string list") 
			return( nil)
		)

		max_col = 0
		rexCompile( "^\\([A-Z]+\\)[0-9]+$")
		foreach( key key_ls
			when( rexExecute( key)
				char = rexSubstitute( "\\1")
				char = stringToSymbol( char)
				col = GetNumberByAlphabet_utilityprogram( char)

				if( plusp( col) then
					when( (col > max_col) 
						max_col = col
					)
				else
					return( nil)
				)
			)
		)
		
		when( zerop( max_col) 
			max_col = nil
		)
		
		return( max_col)
	)
)

procedure( GetAlphabetByNumber_utilityprogram( number)
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

procedure( GetNumberByAlphabet_utilityprogram( word)
	prog( ( str_len left right result)
		unless( or( stringp( word) symbolp( word)) 
			println( "ArgErr: get_number_by_alphabet() - word is not a symbol or string") 
			return( nil)
		)
		
		when( symbolp( word) 
			word = symbolToString( word)
		)
		
		str_len = strlen( word)
		when( (str_len > 2) 
			printf( "ArgErr: get_number_by_alphabet() - length of word[%s] has to be less equal than 2\n" word) 
			return( nil)
		)
		
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Output CSV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Find Filter

procedure( GetTextList_utilityprogram( layer)
	prog( ( text_ls)
		text_ls = GetFindFilter_utilityprogram( layer '(text))
		return( text_ls)
	)
)

procedure( GetViaList_utilityprogram( layer)
	prog( ( via_ls)
		via_ls = GetFindFilter_utilityprogram( layer '(vias))
		return( via_ls)
	)
)

procedure( GetPinList_utilityprogram( layer)
	prog( ( pin_ls)
		pin_ls = GetFindFilter_utilityprogram( layer '(pins))
		return( pin_ls)
	)
)

procedure( GetLineList_utilityprogram( layer)
	prog( ( line_ls)
		line_ls = GetFindFilter_utilityprogram( layer '(lines))
		return( line_ls)
	)
)

procedure( GetCLineList_utilityprogram( layer)
	prog( ( cline_ls)
		cline_ls = GetFindFilter_utilityprogram( layer '(clines clinesegs))
		return( cline_ls)
	)
)

procedure( GetShapeList_utilityprogram( layer)
	prog( ( shape_ls)
		shape_ls = GetFindFilter_utilityprogram( layer '(shapes))
		return( shape_ls)
	)
)

procedure( GetSymbolList_utilityprogram( layer)
	prog( ( symbol_ls)
		symbol_ls = GetFindFilter_utilityprogram( layer '(symbols))
		return( symbol_ls)
	)
)

procedure( GetFindFilter_utilityprogram( layer filter)
	prog( ( visible_list selected)
		visible_list = axlVisibleGet()
		axlVisibleDesign( nil)
		axlVisibleLayer( layer t)
		when( filter == '(vias)
			subclass = cadr( parseString( layer "/"))
			axlVisibleLayer( strcat( "VIA CLASS/" subclass) t)
		)
		
		SetFindFilter_utilityprogram( filter)
		axlAddSelectAll()
		selected = axlGetSelSet()
		; clear select, reset filter and visibility
		axlClearSelSet()
		ResetFindFilter_utilityprogram()
		axlVisibleSet( visible_list)
		
		return( selected)
	)
)

procedure( SetFindFilter_utilityprogram( filter)
	prog( ()
		filter = append( '(noall) filter)
		return( axlSetFindFilter( ?enabled filter ?onButtons filter))
	)
)

procedure( ResetFindFilter_utilityprogram()
	prog( ()
		axlSetFindFilter( ?enabled '(noall) ?onButtons '(noall))
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Find filter

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Log

procedure( SetUpLog_utilityprogram( log_name @key (mode "w") (log_time nil))
	prog( ( log_dir year month date hour minute second log_file_name log_path out_port)	
		unless( axlGetVariable( "ads_sdlog")
			axlSetVariable( "ads_sdlog" "log")
		)
		
		log_dir = axlGetVariable( "ads_sdlog") || ""
		unless( or( zerop( strlen( log_dir)) isDir( log_dir))
			createDir( log_dir)
		)
		
		if( mode == "a" && log_time
			sscanf( log_time "%s %d %d:%d:%d %d" month date hour minute second year)
			sscanf( getCurrentTime() "%s %d %d:%d:%d %d" month date hour minute second year)
		)
		
		sprintf( log_file_name "%s-%.4d%s%.2d-%.2d%.2d%.2d.log" log_name year month date hour minute second)
		sprintf( log_path "%s/%s" log_dir log_file_name)
		
		out_port = outfile( log_path mode)
		unless( outportp( out_port)
			println( "ERROR: Main() - Fail to write log")
			return( nil)
		)
		
		return( list( out_port log_path))
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Log

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( NewForm_utilityprogram( file_name header port_width port_height @optional ( start_title t))
	prog( ( out_port)
		out_port = outfile( file_name "w")
		unless( outportp( out_port)
			println( "ERROR: NewForm_utilityprogram() - Fail to write form")
			return( nil)
		)
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")
		fprintf( out_port "FORM WINDOW\n")
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" port_width port_height)
		fprintf( out_port "HEADER \"%s\"\n" header)
		when( start_title
			fprintf( out_port "TILE\n")
		)
		
		return( out_port)
	)
)

procedure( EndForm_utilityprogram( out_port)
	let( ()
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
	)
)
procedure( WriteFormGroup_utilityprogram( out_port name x y width height)
	let( ()
		fprintf( out_port "GROUP \"%s\"\n" name)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "TSSIZE %d %d\n" width height)
		fprintf( out_port "ENDGROUP\n\n")
	)
)

procedure( WriteFormButton_utilityprogram( out_port field content x y width height)
	let( ()
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" content width height)
		fprintf( out_port "ENDFIELD\n\n")
	)
)

procedure( WriteFormText_utilityprogram( out_port text x y)
	let( ()
		fprintf( out_port "TEXT \"%s\" \n" text)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "ENDTEXT\n")
	)
)

procedure( WriteFormStrFillin_utilityprogram( out_port field x y width field_length @key (info_only nil))
	let( ()
		; textbox
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "STRFILLIN %d %d\n" width field_length)
		when( info_only
			fprintf( out_port "INFO_ONLY\n")
		)
		
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormIntFillin_utilityprogram( out_port field x y width field_length @key (info_only nil))
	let( ()
		; numeric textbox
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "INTFILLIN %d %d\n" width field_length)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormRealFillin_utilityprogram( out_port field x y width field_length @key (decimal 2) (min nil) (max nil) (info_only nil))
	let( ()
		; numeric textbox (floating point numbers)
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "REALFILLIN %d %d\n" width field_length)
		fprintf( out_port "DECIMAL %d\n" decimal)
		when( min
			fprintf( out_port "MIN %f\n" min)
		)
		
		when( max
			fprintf( out_port "MAX %f\n" max)
		)
		
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormCheckList_utilityprogram( out_port field content x y @optional ( argument nil))
	let( ()
		; CheckBox
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		if( argument then
			fprintf( out_port "CHECKLIST \"%s\" \"%s\"\n" content argument)
		else
			fprintf( out_port "CHECKLIST \"%s\"\n" content)
		)
		
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormEnumSet_utilityprogram( out_port field x y width @optional ( height 0) ( pop_name nil))
	let( ()
		; ComboBox
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "ENUMSET %d %d\n" width height)
		; prettyprint – make text more read-able using upper/lower case
		; ownerdrawn – provided to support color swatches next.to subclass names
		fprintf( out_port "OPTIONS prettyprint ownerdrawn\n")
		unless( pop_name
			pop_name = field
		)
		
		fprintf( out_port "POP \"%s\"\n" pop_name)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormPopup_utilityprogram( out_port name option_ls)
	let( ()
		option = ParseFormPopupOption_utilityprogram( option_ls)
		fprintf( out_port "POPUP <%s> %s\n" name option)
	)
)

procedure( ParseFormPopupOption_utilityprogram( option_ls)
	prog( ( options option)
		options = mapcar( lambda( (x) sprintf( nil "\"%s\" \"%s\" " x x)) option_ls)
		option = buildString( options ",")
		option = strcat( option ".")
		
		return( option)
	)
)

procedure( WriteFormGrid_utilityprogram( out_port field x y width height @key ( top_size 2) ( side_size 5))
	let( ()
		fprintf( out_port "GRID %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "FSIZE %d %d\n" width height)
		;fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		fprintf( out_port "OPTIONS HLINES VLINES\n")
		fprintf( out_port "GHEAD TOP\n")
		fprintf( out_port "HEADSIZE %d\n" top_size)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "GHEAD SIDE\n")
		fprintf( out_port "HEADSIZE %d\n" side_size)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "ENDGRID\n\n")
	)
)

procedure( CreateMessageBox_utilityprogram( msg title @optional ( button_info_ls list( list( 'yes "Yes") list( 'no "No"))) ( def_key 'yes))
	prog( ( file_name port_width port_height out_port context_x context_y button_width button_height button_x y_end form)
		file_name = "msg_box.form"
		group_width = 60
		
		port_width = group_width + 2
		port_height = 30
		out_port = NewForm_utilityprogram( file_name title port_width port_height)
		unless( out_port
			return( nil)
		)
		
		group_x = 1
		group_y = 1
		
		context_x = 3
		
		y_end = group_y
		
		WriteFormText_utilityprogram( out_port msg context_x y_end)
		
		y_end = y_end + 2
		WriteFormGroup_utilityprogram( out_port "" group_x group_y group_width y_end)
		
		button_width = 20
		button_height = 2
		
		button_x = context_x
		y_end = y_end + 2
		
		foreach( button_info button_info_ls
			key = car( button_info)
			content = cadr( button_info)
			WriteFormButton_utilityprogram( out_port key content button_x y_end button_width button_height)
			button_x = button_x + button_width
		)
		
		EndForm_utilityprogram( out_port)
		
		close( out_port)
		
		form = axlFormCreate( gensym() file_name '( "east" "outer") 'MessageBoxFormActions_utilityprogram nil)
		
		axlFormDefaultButton( form def_key)
		axlFormDisplay( form)
		; to handle after message box close
		axlUIWBlock( form)
		return( _msg_box_result)
	)
)

procedure( MessageBoxFormActions_utilityprogram( form)
	prog( ( cur_field)
		unless( axlIsFormType( form)
			println( "ArgErr: FormActions() - form_id is not in form type")
			return( nil)
		)
		
		_msg_box_result = nil
		unless( blankstrp( form->curField)
			_msg_box_result = stringToSymbol( form->curField)
		)
		
		axlFormClose( form)
		return( t)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

/*
(encrypt "c:/skill/utility_program_v2d6.il" "c:/skill/utility_program_v2d6.ile")
(load "utility_program_v2d6.il")
(load "utility_program_v2d6.ile")
*/