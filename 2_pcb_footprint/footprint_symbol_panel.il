/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/05/24                                                      #
#  Reference: locker, utility_program, manipulate_xlsx                         #
#  Purpose:                                                                    #
#       Display all footprint symbol create and check program in a form        #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global variable

procedure( Init_footprintsymbolpanel()
	setq( _symbol_struct_ls nil)
	defstruct( symbol_struct group name create_command check_command logs message argument)
	defstruct( spacing_struct func value)
	setq( _footprint_panel_path "W:/footprint_building_aid_skill/2-0_pcb_footprint/1-1_Footprint_Panel/")
	setq( _symbol_ls_addr strcat( _footprint_panel_path "footprint_symbol_list.csv"))
	
	;;;;; get last board init data
	setq( _default_symbol_init_file_pattern "^symbol_init_vWilson-\\([0-9]+\\).xlsx")
	setq( _default_symbol_init_addr GetLatestFileAddr_utilityprogram( _footprint_panel_path _default_symbol_init_file_pattern))
	
	;;;;; form
	setq( _form_term_divider "-")
	setq( _form_create_term strcat( _form_term_divider "create"))
	setq( _form_check_term strcat( _form_term_divider "check"))
	setq( _form_view_term strcat( _form_term_divider "view"))
	setq( _form_log_term strcat( _form_term_divider "log"))
	setq( _form_name "footprint_symbol_panel.form")
	setq( _form_key_init 'symbol_init)
	setq( _form_key_pack_up 'pack_up)
	setq( _form_key_close 'close)
	
	setq( _group_item_ls nil)
	setq( _group_item_table makeTable( 'group_item nil))
	setq( _valid_cmd_table makeTable( 'valid_cmd nil))
	setq( _executed_cmd_table makeTable( 'executed_cmd nil))
	
	;;;;; Excel
	setq( _sht_nm_des "Design_param")
	setq( _sht_nm_txt "Textblock")
	setq( _sht_nm_modes "Analysis_modes")
	setq( _sht_nm_spacing "Spacing")
	setq( _sheet_name_ls list( _sht_nm_des _sht_nm_txt _sht_nm_modes _sht_nm_spacing))
	setq( _total_sheet_num length( _sheet_name_ls))
	setq( _init_csv_table makeTable( "fnm_csv" nil))
	for( th 0 sub1( _total_sheet_num) 
		_init_csv_table[ nth( th _sheet_name_ls)] = sprintf( nil "Excel_sheet[%d].csv" th)
	)
	
	setq( _init_table makeTable( "fnm_table" nil))
	for( th 0 sub1( _total_sheet_num) 
		_init_table[ nth( th _sheet_name_ls)] = sprintf( nil "Excel_sheet[%d].table" th)
	)
	
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _check_item_panel_dir "footprint_symbol_panel-%s" _date_time)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_footprintsymbolpanel()
	prog( ( form_name out_port)
		unless( axlOKToProceed() 
			println ("Please done current function to use this program")
			return( nil)
		)
		
		unless( locker_main_Derek20210929()
			return( nil)
		)
		
		Init_footprintsymbolpanel()
		
		;;;;; init symbol list by file saved in cloud
		unless( isFile( _symbol_ls_addr)
			printf( "ERROR: Main() - Fail to find file: %s\n" _symbol_ls_addr)
			return( nil)
		)
		
		unless( ReadSymbolList_footprintsymbolpanel() 
			return( nil)
		)
		
		;;;;; check all the command is callable
		CheckCommand_footprintsymbolpanel()
		unless( dtpr( _valid_cmd_table->?)
			printf( "INFO: Main() - None of command is loaded. Please check this out")
			DeleteEmptyDir_footprintsymbolpanel( _check_item_panel_dir)
			return( nil)
		)
		
		;;;;; display form
		form_name = "footprint_symbol_panel.form"
		unless( CreateForm_footprintsymbolpanel( form_name)
			return( nil)
		)
		
		out_port = axlFormCreate( gensym() form_name '("east" "outer") 'FormActions_footprintsymbolpanel nil)
		InitForm_footprintsymbolpanel( out_port)
		axlFormDisplay( out_port)
		
		return( t)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( CreateForm_footprintsymbolpanel( form_name)
	prog( ( out_port group_width group_x row_height start_y last_y)
		group_width = 90
		group_x = 1
		row_height = 2
		start_y = 1
		
		button_width = 20
		button_height = 2
		
		out_port = NewForm_utilityprogram( form_name "Footprint symbol Panel" add1( group_width) 100)
		unless( out_port
			return( nil)
		)
		
		last_y = start_y
		WriteFormButton_utilityprogram( out_port _form_key_init "Symbol Initialize" group_x last_y button_width button_height)
		
		last_y = last_y + 4
		
		group_name_table = GetGroupNameTable_footprintsymbolpanel()
		group_ls = GetUnifiedList_footprintsymbolpanel( _symbol_struct_ls~>group)
		foreach( group group_ls
			last_y = WriteFormGroupContent_footprintsymbolpanel( out_port group group_name_table[group] 
															  last_y group_x group_width row_height)
		)

		last_y = last_y + row_height
		WriteFormButton_utilityprogram( out_port _form_key_pack_up "Pack Up" group_x last_y button_width button_height)
		
		position_x = group_x + button_width + 2
		WriteFormButton_utilityprogram( out_port _form_key_close "Close" position_x last_y button_width button_height)

		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		return( t)
	)
)

procedure( GetGroupNameTable_footprintsymbolpanel()
	prog( ( group_name_table group name)
		group_name_table = makeTable( "group_name" nil)
		
		foreach( item _symbol_struct_ls
			group = item->group
			name = item->name
			group_name_table[group] = append1( group_name_table[group] name)
		)
		
		return( group_name_table)
	)
)

procedure( GetUnifiedList_footprintsymbolpanel( data_ls)
	prog( ( new_data_ls)
		new_data_ls = maplist( lambda( (xs) unless( member( car( xs) cdr( xs)) car( xs))) data_ls)
		new_data_ls = remq( nil new_data_ls)
		
		return( new_data_ls)
	)
)

procedure( WriteFormGroupContent_footprintsymbolpanel( out_port group_name check_name_ls last_y group_x group_width row_height)
	prog( ( group_start_y)
		group_start_y = last_y
				
		foreach( name check_name_ls
			last_y = last_y + row_height
			WriteFormEntry_footprintsymbolpanel( out_port name last_y)
		)
		
		last_y = last_y + row_height + 1
		group_title = GetKeyTitle_footprintsymbolpanel( group_name)
		
		group_height = last_y - group_start_y
		WriteFormGroup_utilityprogram( out_port group_title group_x group_start_y group_width group_height)
		
		return( last_y)
	)
)

procedure( WriteFormEntry_footprintsymbolpanel( out_port item last_y @optional (content_x 3) (button_width 8) (button_height 1) (text_size 36))
	let( ( title_key create_item_key check_item_key view_item_key log_item_key)
		title_key = GetKeyTitle_footprintsymbolpanel( item)
		WriteFormText_utilityprogram( title_key content_x last_y)
		
		content_x = content_x + 18
		create_item_key = GetFormItemButtonKey_footprintsymbolpanel( item _form_create_term)
		WriteFormButton_utilityprogram( out_port create_item_key "CREATE" content_x last_y button_width button_height)
		
		content_x = content_x + 10
		check_item_key = GetFormItemButtonKey_footprintsymbolpanel( item _form_check_term)
		WriteFormButton_utilityprogram( out_port check_item_key "CHECK" content_x last_y button_width button_height)
		
		content_x = content_x + 10
		view_item_key = GetFormItemButtonKey_footprintsymbolpanel( item _form_view_term)
		WriteFormButton_utilityprogram( out_port view_item_key "VIEW" content_x last_y button_width button_height)
		
		content_x = content_x + 10
		log_item_key = GetFormItemButtonKey_footprintsymbolpanel( item _form_log_term)
		WriteFormStrFillin_utilityprogram( out_port log_item_key content_x last_y text_size text_size * 2)
	)
)

procedure( GetKeyTitle_footprintsymbolpanel( key)
	; key = 'group_report_and_drc
	prog( ( key_iter)
		key = symbolToString( key)
		;;;; remove first section: key
		key_iter = parseString( key "_")
		key = buildString( key_iter " ")
		
		return( key)
	)
)

procedure( FormActions_footprintsymbolpanel( out_port)
	let( ( current_field name)
		current_field = out_port->curField
		
		cond(
			( current_field == symbolToString( _form_key_init)
				SymbolInit_footprintsymbolpanel()
			)
			( current_field == symbolToString( _form_key_pack_up)
				CopyLogToDir_footprintsymbolpanel( _check_item_panel_dir)
			)
			( current_field == symbolToString( _form_key_close)
				axlFormClose( out_port)
				DeleteEmptyDir_footprintsymbolpanel( _check_item_panel_dir)
			)
			( index( current_field _form_create_term)
				name = GetItemByButtonKey_footprintsymbolpanel( current_field)
				RunFormCommand_footprintsymbolpanel( name t)
			)
			( index( current_field _form_check_term)
				name = GetItemByButtonKey_footprintsymbolpanel( current_field)
				RunFormCommand_footprintsymbolpanel( name)
				SetFormMessage_footprintsymbolpanel( out_port name)
			)
			( index( current_field _form_view_term)
				name = GetItemByButtonKey_footprintsymbolpanel( current_field)
				ViewFormItemLog_footprintsymbolpanel( name)
			)
		)
	)
)

procedure( RunFormCommand_footprintsymbolpanel( name @optional ( is_create nil))
	prog( ( check_item command argument)
		check_item = _valid_cmd_table[ name]
		if( is_create then
			command = check_item->create_command
		else
			command = check_item->check_command
		)
		
		argument = check_item->argument
		unless( command
			printf( "WARNING: RunCommand() - Please load command[%s] before using this function\n" name)
		)
		
		apply( command argument)
		return( t)
	)
)

procedure( SetFormMessage_footprintsymbolpanel( out_port name)
	prog( ( item log_var log_name content log_item_key)
		item = car( setof( x _symbol_struct_ls x->name == name))
		unless( item 
			printf( "ERROR: SetFormMessage() - Fail to get item[%s] in %L\n" name _symbol_struct_ls~>name)
			return( nil)
		)
		
		log_var = car( item->logs)
		log_name = evalstring( log_var)
		
		content = GetFormLogContent_footprintsymbolpanel( log_name)
		
		log_item_key = GetFormItemButtonKey_footprintsymbolpanel( name _form_log_term)
		
		printf( "INFO: SetFormMessage() - Set log of [%s] to %s\n" name content)
		log_name_ls = mapcar( 'evalstring item->logs)
		_executed_cmd_table[ name] = log_name_ls
		
		axlFormSetField( out_port log_item_key content)
	)
)

procedure( GetFormLogContent_footprintsymbolpanel( log_name)
	prog( ( content)
		if( index( log_name "/")
			content = cadr( parseString( log_name "/"))
			content = log_name
		)
		
		;;;; remove .log
		content = car( parseString( content "."))
		
		return( content)
	)
)

procedure( CopyLogToDir_footprintsymbolpanel( dir_name)
	; logname = "log/log/check_emn_footprint_mapping-2020Aug17-152418.log"
	prog( ( log_name_ls log_name exist_log_name_ls file_des file_addr)
		foreach( name _executed_cmd_table->?
			log_name_ls = _executed_cmd_table[ name]
			when( dtpr( log_name_ls)
				exist_log_name_ls = append( exist_log_name_ls log_name_ls)
			)
		)
		
		unless( dtpr( exist_log_name_ls)
			printf( "INFO: CopyLogToDir() - None of item has been checked\n")
			return( nil)
		)
		
		printf( "INFO: CopyLogToDir() - All last log names: %L\n" exist_log_name_ls)
		
		when( isDir( dir_name)
			axlRecursiveDelete( dir_name)
		)
		
		createDir( dir_name)
		
		foreach( log_name exist_log_name_ls
			file_des = rindex( log_name "/")
			file_addr = strcat( dir_name file_des)
			axlOSFileCopy( log_name file_addr nil)
		)
		
		PromptDir_footprintsymbolpanel( dir_name)
		return( t)
	)
)

procedure( PromptDir_footprintsymbolpanel( dir_name)
	let( ( cmd)
		sprintf( cmd "start %s" dir_name)
		shell( cmd)
	)
)

procedure( ViewFormItemLog_footprintsymbolpanel( name)
	prog( ( item log_var_ls log_name_ls)
		item = car( setof( x _symbol_struct_ls x->name == name))
		unless( item
			return( nil)
		)
		
		log_var_ls = item->logs
		log_name_ls = mapcar( 'evalstring log_var_ls)
		
		unless( dtpr( log_name_ls)
			printf( "WARNING: ViewFormItemLog() - Please check item[%s] before using this function\n" name)
			return( nil)
		)
		
		printf( "INFO: ViewFormItemLog() - Open logs of [%s]:  %L\n" name log_name_ls)
		
		foreach( log_name log_name_ls
			axlUIViewFileCreate( log_name log_name nil)
		)
		
		return( t)
	)
)

procedure( InitForm_footprintsymbolpanel( out_port)
	let( ( item_key)
		;;;; disable the text input on the right side
		foreach( item _symbol_struct_ls
			item_key = GetFormItemButtonKey_footprintsymbolpanel( item->name _form_log_term)
			axlFormSetFieldEditable( out_port item_key nil)
		)
		
		;;;; set default button
		axlFormDefaultButton( out_port _form_key_pack_up)
		
		;;;; message
		foreach( item _symbol_struct_ls
			message = item->message
			when( stringp( message)
				item_key = GetFormItemButtonKey_footprintsymbolpanel( item->name _form_log_term)
				axlFormSetField( out_port item_key message)
			)
		)
	)
)

procedure( GetFormItemButtonKey_footprintsymbolpanel( item term)
	; item = 'testpoint
	prog( ( button_key)
		sprintf( button_key "%s%s%s" item _form_term_divider term)
		
		return( button_key)
	)
)

procedure( GetItemByButtonKey_footprintsymbolpanel( button_key)
	; button_key =  "testpoint-check"
	prog( ( item)
		item = car( parseString( button_key _form_term_divider))
		item = stringToSymbol( item)
		
		return( item)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Initialize

procedure( SymbolInit_footprintsymbolpanel()
	prog( ( accuracy unit result valid x y width height box analysis_modes design_value modes smd_pin_spacing smd_pin_ls)
		;;;; remove the exists csv and table files
		foreach( num _init_csv_table
			when( isFile( _init_csv_table[ num])
				deleteFile( _init_csv_table[ num])
			)
		)
		
		foreach( num _init_table
			when( isFile( _init_table[ num])
				deleteFile( _init_table[ num])
			)
		)
		
		manipulate_xlsx_main_Derek06122018( ?xlsx_addr _default_symbol_init_addr ?global_sheets _sheet_name_ls)
		
		unless( and( forall( f _init_csv_table isFile( _init_csv_table[ f])) forall( f _init_table isFile( _init_table[ f])))
			println( "ERROR: write_sheets() - Fail to get certain files from symbol_init.xlsx")
			return( nil)
		)

		LoadDesignParameters_footprintsymbolpanel()
		LoadConstraints_footprintsymbolpanel()
		
		msg = "Symbol init Finished"
		axlUIConfirm( msg)
		println( msg)
	)
)

procedure( LoadDesignParameters_footprintsymbolpanel()
	prog( ( row result valid unit accuracy x y width height)
		filename = _init_table[ _sht_nm_des]
		table = ReadTable_utilityprogram( filename 'design_param)
		row = 2
		; User units
		value_col = "E"
		unit = GetTableValue_utilityprogram( table row++ value_col 'unit)
		accuracy = GetTableValue_utilityprogram( table row++ value_col 'plus_int)
		result = axlDBChangeDesignUnits( unit accuracy)
		valid = GetValidResult_footprintsymbolpanel( result)
		printf( "Info: LoadDesignParameters() - %s to update [User units] to %s, [Accuracy] to %d\n" valid unit accuracy)
		
		; Extents
		x = GetTableValue_utilityprogram( table row++ value_col 'float)
		y = GetTableValue_utilityprogram( table row++ value_col 'float)
		width = GetTableValue_utilityprogram( table row++ value_col 'float)
		height = GetTableValue_utilityprogram( table row++ value_col 'float)
		box = list( list( x y) list( ( x + width) ( y + height)))
		result = axlDBChangeDesignExtents( box)
		valid = GetValidResult_footprintsymbolpanel( result)
		printf( "Info: LoadDesignParameters() - %s to update [Extents] to %L %L\n" valid list( x y) box)
		
		; Textblock
		filename = _init_csv_table[ _sht_nm_txt]
		data_line_ls = ReadCSVLine_utilityprogram( filename)
		foreach( data_line data_line_ls
			data_ls = axlStringCSVParse( data_line)
			
			text_id = atoi( nth( 1 data_ls))
			width = GetUnitValueByMils_utilityprogram( atof( nth( 2 data_ls)))
			height = GetUnitValueByMils_utilityprogram( atof( nth( 3 data_ls)))
			line_space = GetUnitValueByMils_utilityprogram( atof( nth( 4 data_ls)))
			photo = GetUnitValueByMils_utilityprogram( atof( nth( 5 data_ls)))
			char = GetUnitValueByMils_utilityprogram( atof( nth( 6 data_ls)))
			
			if( and( plusp( text_id) numberp( width) numberp( height) numberp( line_space) numberp( photo) numberp( char)) then
				sprintf( text_name "paramTextBlock:%d" text_id)
				param = axlGetParam( text_name)
				
				if( stringp( param->name) then
					param->width = width
					param->height = height
					param->lineSpace = line_space
					param->photoWidth = photo
					param->charSpace = char
					axlSetParam( param)
				else
					axlDBTextBlockCreate( text_id ?width width ?height height ?lineSpace line_space ?photoWidth photo ?charSpace char)
				)
			else
				printf( "WARNING: LoadDesignParameters() - Illegal data textblock[%L] width[%L] height[%L] lineSpace[%L] photoWidth[%L] charSpace[%L]\n"
						text_id width height line_space photo char)
			)
		)
		
		return( t)
	)
)

procedure( GetValidResult_footprintsymbolpanel( result)
	prog( ( valid)
		valid = if( result "Success" "Fail")
		return( valid)
	)
)

procedure( LoadConstraints_footprintsymbolpanel()
	prog( ( result valid filename table row value_col design_spacing soldermask_modes smd_pin_spacing)
		; Analysis modes
		filename = _init_csv_table[ _sht_nm_modes]
		csv_line_ls = ReadCSVLine_utilityprogram( filename)
		category_col = 1
		title_col = 3
		value_col = 4
		mode_col = 5
		func_col = 6
		
		foreach( csv_line csv_line_ls
			csv_ls = axlStringCSVParse( csv_line t)
			
			category = upperCase( nth( category_col csv_ls))
			title = nth( title_col csv_ls)
			val = atof( nth( value_col csv_ls))
			unless( floatp( val)
				val = 0
			)
			
			mode = lowerCase( nth( mode_col csv_ls))
			unless( blankstrp( mode)
				mode = stringToSymbol( mode)
			)
			
			func = nth( func_col csv_ls)
			unless( blankstrp( func)
				func = stringToSymbol( func)
			)
			
			axlCNSDesignModeSet( func mode)
			axlCNSDesignValueSet( func val)
		)
		
		; Spacing
		filename = _init_csv_table[ _sht_nm_spacing]
		csv_line_ls = ReadCSVLine_utilityprogram( filename)
		title_col = 2
		value_col = 3
		func_col = 4
		
		def_spacing = 0.222
		spacing_struct_ls = nil
		foreach( csv_line csv_line_ls
			csv_ls = axlStringCSVParse( csv_line t)
			title = upperCase( nth( title_col csv_ls))
			
			val = atof( nth( value_col csv_ls))
			unless( floatp( val)
				val = 0
			)
			
			func = nth( func_col csv_ls)
			unless( blankstrp( func)
				func = stringToSymbol( func)
			)
			
			if( title == "DEFAULT" then
				def_spacing = val
			else
				spacing = make_spacing_struct( ?func func ?value val)
				spacing_struct_ls = append1( spacing_struct_ls spacing)
			)
		)

		cns_ls = axlCNSGetSpacing(nil nil nil)
		foreach( cns cns_ls
			if( memq( cns spacing_struct_ls~>func) then
				spacing = car( setof( x spacing_struct_ls ( x->func == cns)))->value
			else
				spacing = def_spacing
			)
			
			result = axlCNSSetSpacing( nil nil cns spacing)
			valid = GetValidResult_footprintsymbolpanel( result)
			printf( "Info: LoadConstraints() - %s to update [Spacing] %L to %L\n" valid cns spacing)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Initialize

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CheckCommand_footprintsymbolpanel()
	let( ( name create_command check_command)
		foreach( item _symbol_struct_ls
			name = item->name
			create_command = item->create_command
			check_command = item->check_command
			
			if( isCallable( create_command) && isCallable( check_command) then
				printf( "INFO: CheckCommand() - Successfully get command: %s\n" name)
				_valid_cmd_table[ name] = item
			else
				unless( isCallable( create_command)
					printf( "WARNING: CheckCommand() - Unbound create command: %s\n" name)
				)
				
				unless( isCallable( check_command)
					printf( "WARNING: CheckCommand() - Unbound check command: %s\n" name)
				)
			)
		)
	)
)

procedure( DeleteEmptyDir_footprintsymbolpanel( dir_name)
	prog( ()
		unless( isDir( dir_name) 
			return( nil)
		)

		unless( dtpr( getDirFiles( dir_name))
			printf( "INFO: DeleteEmptyDir() - Remove empty dir: %L\n" dir_name)
			deleteDir( dir_name)
		)
		
		return( t)
	)
)

procedure( ReadSymbolList_footprintsymbolpanel()
	prog( ( in_port)
		in_port = infile( _symbol_ls_addr)
		unless( inportp( in_port)
			println( "ERROR: ReadSymbolList() - Fail to read file")
			return( nil)
		)
		
		;;;;; skip header
		gets( csv_line in_port)
		
		while( gets( csv_line in_port)
			parts = axlStringCSVParse( csv_line t)
			
			group = nth( 0 parts)
			name = nth( 1 parts)
			create_command = nth( 2 parts)
			check_command = nth( 3 parts)
			logs_line = nth( 4 parts)
			message = nth( 5 parts) || ""
			argument = nth( 6 parts) || nil
			; argument should be a list
			when( argument
				argument = list( argument)
			)
			
			if( group && name && create_command && check_command && logs_line then
				group = stringToSymbol( upperCase( group))
				name = stringToSymbol( name)
				create_command = stringToSymbol( create_command)
				check_command = stringToSymbol( check_command)
				logs = parseString( logs_line "|")
				
				item_stru = make_symbol_struct( ?group group ?name name ?create_command create_command ?check_command check_command ?logs logs ?message message ?argument argument)
				_symbol_struct_ls = append1( _symbol_struct_ls item_stru)
			else
				printf( "ERROR: ReadSymbolList() - Fail to initialize symbol list. group[%L] name[%L] command[%L] command[%L] logs[%L]\n" group name logs create_command check_command)
			)
		)
		
		close( in_port)
		
		println( "INFO: ReadSymbolList() - Data in default setting")
		foreach( item _symbol_struct_ls
			printf( "%L\n" item->??)
		)
		
		return( t)
	)
)

procedure( GetSymbolInitAddr_footprintsymbolpanel()
	let( (file_ls date_file_ls)
		file_ls = getDirFiles( _footprint_panel_path)
		
		rexCompile( _default_symbol_init_file_pattern)
		foreach( file_name file_ls
			when( rexExecute( file_name)
				date = atoi( rexSubstitute( "\\1"))
				date_file_ls = append1( date_file_ls list( date file_name))
			)
		)
		unless( dtpr( date_file_ls)
			printf( "ERROR: Fail to find file at %s%s\n" _footprint_panel_path _default_symbol_init_file_pattern)
			return( nil)
		)
		
		date_file_ls = sortcar( date_file_ls 'greaterp)
		_default_symbol_init_filename = cadar( date_file_ls)
		_default_symbol_init_addr = strcat( _footprint_panel_path _default_symbol_init_filename)
		
		printf( "INFO: get_default_board_init_addr() - Get board init reference: %L\n" _default_board_init_addr)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

(axlCmdRegister "footprint_symbol_panel" 'Main_footprintsymbolpanel ?cmdType "general")
/*
(encrypt "C:/skill/footprint_symbol_panel_v1d1.il" "C:/skill/footprint_symbol_panel_v1d1.ile")
(load "footprint_symbol_panel_v1d1.il")
(load "footprint_symbol_panel_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup