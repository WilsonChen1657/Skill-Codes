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

;region Global Variable
setq( _wilson_init_flag t)
setq( _allegro_version axlVersion( 'version))
setq( _allegro_unit nil)
unless( boundp( '_flex_host_dir)
	_flex_host_dir = "W:/"
)
; this will reset at skill_package_tdc_flex when in test mode
setq( _skill_package_path strcat( _flex_host_dir "footprint_building_aid_skill/official/Skill_package/"))

setq( _month_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
setq( _alphabet_total 26)
setq( _alphabet_ls list( nil 'A 'B 'C 'D 'E 'F 'G 'H 'I 'J 'K 'L 'M 'N 'O 'P 'Q 'R 'S 'T 'U 'V 'W 'X 'Y 'Z))
setq( _utpg_selected_obj_ls nil)
;endregion

;region Function

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
		return( GetUnitValue_utilityprogram( mil_value "MILS"))
	)
)

procedure( GetUnitValueByMM_utilityprogram( mm_value)
	prog( ( value)
		return( GetUnitValue_utilityprogram( mm_value "MM"))
	)
)

procedure( GetUnitValue_utilityprogram( value source_unit)
	prog( ( result_value)
		unless( and( numberp( value) stringp( source_unit))
			return( nil)
		)
		
		_allegro_unit = car( axlDBGetDesignUnits())
		result_value = axlMKSConvert( value source_unit _allegro_unit)
		return( result_value)
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
	prog( ( msg_title in_port table)
		msg_title = "ReadTable()"
		unless( symbolp( table_name)
			PrintMsg_utilityprogram( "table_name is not a symbol" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( stringp( table_filename)
			PrintMsg_utilityprogram( "table_filename is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( isFile( table_filename)
			PrintMsg_utilityprogram( "table_filename is not a file" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( inportp( in_port = infile( table_filename))
			PrintMsg_utilityprogram( "Fail to read table_filename" ?title msg_title ?level 'error)
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
					sprintf( msg "Fail to manipulate data_line[%s] in [%s]\n" data_line table_filename)
					PrintMsg_utilityprogram( msg ?title msg_title ?level 'warn)
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
		
		sprintf( err_msg "Fail to get value[%L] on row[%d] of sheet[Design_Param]" value row)
		value = CheckDataType_utilityprogram( value data_type err_msg)
		
		return( value)
	)
)

procedure( CheckDataType_utilityprogram( data type err_msg)
	prog( ( num unit result)
		msg_title = "CheckDataType()"
		unless( or( stringp( data) dtpr( data))
			sprintf( msg "data[%L] is not a string or a dtpr\n\t%s" data err_msg)
			PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( symbolp( type)
			PrintMsg_utilityprogram( "[type] is not a symbol" ?title msg_title ?level 'error)
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
				sprintf( msg "Yet to support type[%s] to identify data[%s]\n" type data)
				PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
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
			sprintf( msg "Fail to find file at %s%s\n" directory filename_pattern)
			PrintMsg_utilityprogram( msg ?title "GetLatestFileAddr()" ?level 'error)
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
			sprintf( msg "Please load [%s] to proceed\n" file_name)
			PrintMsg_utilityprogram( msg ?title "CheckIsCallable()" ?level 'error)
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

procedure( ListDuplicated_utilityprogram( data_ls)
	let( ()
		when( data_ls
			if( member( car(data_ls) cdr(data_ls))
				cons( car(data_ls) ListDuplicated_utilityprogram( remove( car(data_ls) cdr(data_ls))))
				ListDuplicated_utilityprogram( remove( car(data_ls) cdr(data_ls)))
			)
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
	let( ( perm_highlight_ls temp_highlight_ls)
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

procedure( RunReport_utilityprogram( cmd_format file_name @optional (on_html nil))
	; cmd_format = %CDSROOT%\share\pcb\batchhelp\report.txt
	let( ( html_option cmd)
		html_option = if( on_html " -H" "")
		sprintf( cmd "report -v%s %s %%s" html_option cmd_format)
		axlRunBatchDBProgram( "report" cmd ?silent t)
		if( isFile( file_name) then
			axlUIViewFileCreate( file_name title nil)
			axlOSFileCopy( file_name axlGetVariable( "ads_sdlog") nil)
		else
			sprintf( msg "Fail to create %s" file_name)	
			PrintMsg_utilityprogram( msg ?level 'warn)
		)
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

procedure( OpenHelpFile_utilityprogram( file_name @optional (extension ".pdf"))
	let( ( help_path)
		help_path = strcat( _flex_host_dir "footprint_building_aid_skill/Help/")
		OpenFile_utilityprogram( help_path file_name extension)
	)
)

procedure( OpenFile_utilityprogram( dir file_name extension)
	let( ( file_ls result)
		when( and( stringp( dir) !blankstrp( dir))
			file_ls = cddr( getDirFiles( dir))
			result = car( setof( x file_ls and( index( x extension) index( x file_name))))
			when( result
				unless( equal( substring( dir strlen( dir) 1) "/")
					dir = strcat( dir "/")
				)

				shell( strcat( dir result))
			)
		)
	)
)

procedure( CreateDoneCancelPopup_utilityprogram()
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

procedure( SpeedUp_utilityprogram( @optional (enable nil))
	let( ( msg_title)
		; shape dynamic fill set to disabled
		if( enable
			axlDBControl( 'dynamicFillMode 'wysiwyg)
			axlDBControl( 'dynamicFillMode enable)
		)
		
		; disabled on-line DRC
		axlDBControl( 'drcEnable enable)

		msg_title = "SpeedUp()"
		when( and( enable axlUIYesNo( "Do you want to update to smooth and DRCs?"))
			PrintMsg_utilityprogram( "Starting update to smooth" ?title msg_title)
			;time_start = getCurrentTime()
			; update dynamic shapes
			axlDBDynamicShapes( t)
			;time_end = getCurrentTime()
			PrintMsg_utilityprogram( "Finish update to smooth" ?title msg_title)
			;ProcessTime_createfullcontactroutekeepout( "Update to smooth" time_start time_end)
		
			PrintMsg_utilityprogram( "Starting update DRCs" ?title msg_title)
			;time_start = getCurrentTime()
			; update DRC
			axlShell( "drc update")
			;time_end = getCurrentTime()
			PrintMsg_utilityprogram( "Finish update DRCs" ?title msg_title)
			;ProcessTime_createfullcontactroutekeepout( "Update DRCs" time_start time_end)
		)
	)
)

procedure( UpdateDRC_utilityprogram()
	let( ( time_start time_end)
		; shape dynamic fill set to smooth
		axlDBControl( 'dynamicFillMode 'wysiwyg)
		; Enable on-line DRC
		axlDBControl( 'drcEnable t)
		if( axlUIYesNo( "Do you want to update to smooth and update DRCs?") then
			println( "Start updating to smooth")
			time_start = getCurrentTime()
			; update dynamic shapes
			axlDBDynamicShapes( t)
			time_end = getCurrentTime()
			println( "Finish updating to smooth")
			PrintProcessTime_utilityprogram( "Update to smooth" time_start time_end)
		
			println( "Start updating DRCs")
			time_start = getCurrentTime()
			; update DRC
			axlShell( "drc update")
			time_end = getCurrentTime()
			println( "Finish updating DRCs")
			PrintProcessTime_utilityprogram( "Update to smooth" time_start time_end)
		)
	)
)

procedure( PrintProcessTime_utilityprogram( title time_start time_end)
	time_passed_seconds = compareTime( time_end time_start)
	tm = timeToTm( time_passed_seconds)
	printf( "%s process time : %d min %d sec\n" title tm->tm_min tm->tm_sec)
)

procedure( OpenDirectory_utilityprogram( dir)
	let( ( cmd)
		sprintf( cmd "start \"\" \"%s\" " dir)
		sh( cmd)
	)
)

procedure( SelectObjectByUser_utilityprogram( filter @key (prompt nil))
	prog( ( display_popup)
		SetFindFilter_utilityprogram( filter)
		display_popup = axlUIPopupDefine( nil list( list( "Done" 'Done_utilityprogram) list( "Cancel" 'Cancel_utilityprogram)))
		axlUIPopupSet( display_popup)
		;axlClearSelSet()
		_utpg_selected_obj_ls = nil
		while( axlSelect( ?prompt prompt)
			_utpg_selected_obj_ls = axlGetSelSet()
		)
		
		axlClearSelSet()
		axlUIPopupSet( nil)
		when( _utpg_selected_obj_ls
			ResetFindFilter_utilityprogram()
		)
		
		return( _utpg_selected_obj_ls)
	)
)

procedure( Done_utilityprogram()
    axlClearDynamics()
    axlFinishEnterFun()
    axlUIPopupSet( nil)
)

procedure( Cancel_utilityprogram()
    axlClearDynamics()
    axlCancelEnterFun()
    _utpg_selected_obj_ls = nil
    axlUIPopupSet( nil)
)

procedure( DeleteLayer_utilityprogram( layer_ls)
	prog( ( layer_id_ls)
		msg_title = "DeleteLayer()"
		when( and( layer_ls !dtpr( layer_ls))
			layer_ls = list( layer_ls)
		)
		
		unless( forall( x layer_ls axlIsLayer( x))
			sprintf( msg "\"%L\" not layer" layer_ls)
			PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
			return( nil)
		)
		
		foreach( layer layer_ls
			layer_id = axlLayerGet( layer)
			unless( layer_id
				sprintf( msg "Fail to get layer id: %s" layer)
				PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
				return( nil)
			)
			
			obj_ls = GetAll_utilityprogram( layer)
			axlDeleteObject( obj_ls)
			axlDeleteObject( layer_id)
		)
		
		return( t)
	)
)

procedure( FlattenList_utilityprogram( data_list)
	foreach( mapcan data data_list
		if( listp( data)
			FlattenList_utilityprogram(data)
			list( data)
		)
	)
)

; <cdsroot>/share/pcb/examples/skill/cmds/cns-design.il
;----------------------------------------------------------------
; The next three items support interactive command processing
;       We are told to done ourself so another cmd can start
procedure( _AcDesignDone( fw)
    when( fw && fw->_change
        ; hide form so user can access stop button
        axlUIWShow( fw 'hide)
        _AcDesignDoit( fw)
		fw->_change = nil       ; prevents double from axlEnterEvent
    )

    _AcDesignCancel( fw)
)

procedure( _AcDesignCancel( fw)
    when(fw
        axlFormClose( fw)
    )
)

; basically a dummy event processor so we can autodone the form
; in case the user starts another command. Maybe someday we can
; support selecting nets this way
;
; Autodone will always send in a done so check if done or cancel
; form should be called to save overhead of drc checking
;
; Use global form variable to avoid problem with form being closed
; via a form button which results in the DONE/CANCEL events being
; generated.

; To fix issue below
; Code works fine when started from skill prompt, but when started from allegro prompt the dbid's are removed right after the main procedure has finished.
procedure( _AcDesignEvent( out_form)
    let( ( event loop)
		loop = t
		while( loop
			event = axlEnterEvent( '(PICK) "" nil)
			caseq( event->type
				( DONE
					_AcDesignDone( out_form)
					loop = nil
				)
				( CANCEL
					_AcDesignCancel( out_form)
					loop = nil
				)
			)
		)
	)
)

procedure( PrintMsg_utilityprogram( msg @key (title "") (level 'info) (show_info nil) (show_warn t))
	let( ( (title_str "") level_str)
		unless( blankstrp( title)
			title_str = strcat( title " - ")
		)

		level_str = upperCase( symbolToString( level))
		printf( strcat( "*" level_str "* " title_str msg "\n"))
		when( or( equal( level 'error) 
				and( equal( level 'info) show_info)
				and( equal( level 'warn) show_warn))
			axlUIConfirm( msg level)
		)
	)
)


procedure( CreateSymbol_utilityprogram( sym_nm @key (center_xy (0:0)) (check_term t))
	;; sym_nm = "flex_pcb_form_v1"
	prog( ( msg_title up_sym_term msg sym_ls to_create result)
		msg_title = "CreateSymbol()"
		unless( stringp( sym_nm)
			PrintMsg_utilityprogram( "[sym_nm] is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( dtpr( center_xy)
			PrintMsg_utilityprogram( "[center_xy] is not a list" ?title msg_title ?level 'error)
			return( nil)
		)
		
		to_create = t
		if( check_term then
			up_sym_term = upperCase( sym_nm)
			up_sym_term = substring( up_sym_term 1 ( strlen( up_sym_term) - strlen( rindex( up_sym_term "_"))))
			sym_ls = setof( x axlDBGetDesign()->symbols and( x->name index( x->name up_sym_term)))
			sprintf( msg "Found symbols%L by term[%s] are loaded. Do you want to load [%s]?" sym_ls~>name up_sym_term sym_nm)
		else
			sym_ls = setof( x axlDBGetDesign()->symbols and( x->name equal( upperCase( x->name) upperCase( sym_nm))))
			sprintf( msg "Found %d symbols with same name. Do you want to reload [%s]?" length( sym_ls) sym_nm)
		)

		when( dtpr( sym_ls)
			to_create = axlUIYesNo( msg "Reload Symbol" 'yes)
			when( to_create
				axlDeleteObject( sym_ls)
			)
		)

		;;;; load target symbol from library
		when( to_create
			mode = '(shape ignoreFixed)
			symbol_type_ls = list( "FORMAT" "PACKAGE" "MECHANICAL")
			while( and( null( result) dtpr( symbol_type_ls))
				sym_type = car( symbol_type_ls)
				result = axlDBCloak( 'axlDBCreateSymbol( list( sym_nm sym_type) center_xy) mode)
				sprintf( msg "Create symbol[%s] by %s: %L" sym_nm sym_type result)
				PrintMsg_utilityprogram( msg ?title msg_title)
				symbol_type_ls = remq( sym_type symbol_type_ls)
			)
			
			axlVisibleUpdate( t)
			if( result then
				sprintf( msg "Symbol [%s] created at %L" sym_nm center_xy)
				PrintMsg_utilityprogram( msg ?title msg_title)
			else
				sprintf( msg "Fail to create symbol [%s] at %L" sym_nm center_xy)
				PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
			)
		)
		
		when( dtpr( result)
			result = car( result)
		)
		
		return( result)
	)
)


procedure( MoveObjects_utilityprogram( obj_ls delta_xy)
	let( ()
		foreach( obj_id obj_ls
			axlTransformObject( obj_id ?move delta_xy)
			axlDBRefreshId( obj_id)		
		)
	)
)

procedure( ExtractFile_utilityprogram( archive_name output_dir @optional (file_filter ""))
	prog( ( msg_title msg cmd)
		msg_title = "ExtractFile()"
		unless( stringp( archive_name)
			PrintMsg_utilityprogram( "[archive_name] is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( isFile( archive_name)
			sprintf( msg "archive_name:[%L] is not a file" archive_name)
			PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
			return( nil)
		)
		
		sprintf( cmd "\"C:\\Program Files\\7-Zip\\7z\" e %s -o%s %s" archive_name output_dir file_filter)
		unless( sh( cmd)
			sprintf( msg "Fail to extract file: %s" archive_name)
			PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
			return( nil)
		)
		
		return( t)
	)
)

procedure( CompareListContent_utilityprogram( list_a list_b)
	let( ( (content_count makeTable( 'counts 0)))
		foreach( item list_a
			content_count[item] = content_count[item] + 1
		)
		
		foreach( item list_b
			content_count[item] = content_count[item] - 1
		)
		
		forall( x content_count zerop( content_count[x]))
	)
)

procedure( StartFile_utilityprogram( file_path)
	prog( ()
		if( index( file_path " ") then
			PrintMsg_utilityprogram( "Please remove spaces in file path!" ?title "StartFile()" ?level 'error)
			return( nil)
		else
			shell( strcat( "start " file_path))
		)

		return( t)
	)
)

;endregion

;region Parse datetime
;;; parse yyyyMMdd to Dec 28 16:57:06 1996
procedure( ParseDate_utilityprogram( date_str)
	prog( ( year month day month_v month_str base_time)
		unless( strlen( date_str) == 8
			PrintMsg_utilityprogram( "Date format should be \"yyyyMMdd\"" ?title "ParseDate()" ?level 'error)
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

procedure( GetTimeStamp_utilityprogram( @optional (date_time nil))
	let( ( date time time_stamp)
		unless( date_time
			date_time = getCurrentTime()
		)

		sscanf( date_time "%s %d %d:%d:%d %d" month day hour minute second year)
		sprintf( date "%.4d%.2d%.2d" year listnindex( _month_ls month) day)
		sprintf( time "%.2d%.2d%.2d" hour minute second)
		time_stamp = strcat( date "_" time)
	)
)

;endregion

;region Output CSV

procedure( OutputCSV_utilityprogram( csv_filename cell_table)
	prog( ( out_port key_ls max_row max_col row col csv_line_ls csv_ls csv_line char cell )
		msg_title = "OutputCSV()"
		unless( stringp( csv_filename) 
			PrintMsg_utilityprogram( "csv_filename is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( tablep( cell_table) 
			PrintMsg_utilityprogram( "cell_table is not a table" ?title msg_title ?level 'error)
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
			PrintMsg_utilityprogram( "Fail to write file" ?title "OutputCSV()" ?level 'error)
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
		msg_title = "GetMaxRow()"
		unless( dtpr( key_ls) 
			PrintMsg_utilityprogram( "key_ls is not a dtpr" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( forall( k key_ls stringp( k)) 
			PrintMsg_utilityprogram( "key_ls is not a string list" ?title msg_title ?level 'error)
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
		msg_title = "GetMaxRow()"
		unless( dtpr( key_ls) 
			PrintMsg_utilityprogram( "key_ls is not a dtpr" ?title msg_title ?level 'error)
			return( nil)
		)
		
		unless( forall( k key_ls stringp( k)) 
			PrintMsg_utilityprogram( "key_ls is not a string list" ?title msg_title ?level 'error)
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
		msg_title = "GetAlphabetByNumber()"
		unless( and( plusp( number) integerp( number)) 
			PrintMsg_utilityprogram( "Number is not a plus integer" ?title msg_title ?level 'error)
			return( nil)
		)
		
		if( (number > _alphabet_total) then
			left = number / _alphabet_total
			right = remainder( number _alphabet_total)
			cond(
				( (left > _alphabet_total)
					sprintf( msg "Fail to define number[%d]" number)
					PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
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
		msg_title = "GetAlphabetByNumber()"
		unless( or( stringp( word) symbolp( word)) 
			PrintMsg_utilityprogram( "word is not a symbol or string" ?title msg_title ?level 'error)
			return( nil)
		)
		
		when( symbolp( word) 
			word = symbolToString( word)
		)
		
		str_len = strlen( word)
		when( str_len > 2
			sprintf( msg "length of word[%s] has to be less equal than 2" word)
			PrintMsg_utilityprogram( msg ?title msg_title ?level 'error)
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

;endregion

;region Find Filter

procedure( GetTextList_utilityprogram( layer)
	prog( ( text_ls)
		text_ls = GetFindFilter_utilityprogram( layer '(text))
		text_ls = setof( x text_ls x->objType == "text")
		return( text_ls)
	)
)

procedure( GetViaList_utilityprogram( layer)
	prog( ( via_ls)
		via_ls = GetFindFilter_utilityprogram( layer '(vias))
		via_ls = setof( x via_ls x->objType == "via")
		return( via_ls)
	)
)

procedure( GetPinList_utilityprogram( layer)
	prog( ( pin_ls)
		pin_ls = GetFindFilter_utilityprogram( layer '(pins))
		pin_ls = setof( x pin_ls x->objType == "pin")
		return( pin_ls)
	)
)

procedure( GetLineList_utilityprogram( layer)
	prog( ( line_ls)
		line_ls = GetFindFilter_utilityprogram( layer '(lines))
		line_ls = setof( x line_ls x->objType == "path")
		return( line_ls)
	)
)

procedure( GetCLineList_utilityprogram( layer)
	prog( ( cline_ls)
		cline_ls = GetFindFilter_utilityprogram( layer '(clines clinesegs))
		cline_ls = setof( x cline_ls x->objType == "cline")
		return( cline_ls)
	)
)

procedure( GetShapeList_utilityprogram( layer)
	prog( ( shape_ls)
		shape_ls = GetFindFilter_utilityprogram( layer '(shapes))
		shape_ls = setof( x shape_ls x->objType == "shape")
		return( shape_ls)
	)
)

procedure( GetSymbolList_utilityprogram( layer)
	prog( ( symbol_ls)
		symbol_ls = GetFindFilter_utilityprogram( layer '(symbols))
		symbol_ls = setof( x symbol_ls x->objType == "symbol")
		return( symbol_ls)
	)
)

procedure( GetAll_utilityprogram( layer_ls)
	prog( ( obj_ls)
		unless( dtpr( layer_ls)
			layer_ls = list( layer_ls)
		)

		obj_ls = GetFindFilter_utilityprogram( layer_ls nil)
		obj_ls = setof( x obj_ls member( x->layer layer_ls))
		return( obj_ls)
	)
)

procedure( GetFindFilter_utilityprogram( layer_ls filter)
	prog( ( visible_list selected)
		visible_list = axlVisibleGet()
		axlVisibleDesign( nil)
		unless( dtpr( layer_ls)
			layer_ls = list( layer_ls)
		)
		
		foreach( layer layer_ls
			axlVisibleLayer( layer t)
			when( filter == '(vias)
				subclass = cadr( parseString( layer "/"))
				axlVisibleLayer( strcat( "VIA CLASS/" subclass) t)
			)
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
		if( filter
			filter = append( '(noall) filter)
			filter = '(all)
		)
		
		return( axlSetFindFilter( ?enabled filter ?onButtons filter))
	)
)

procedure( ResetFindFilter_utilityprogram()
	prog( ()
		axlSetFindFilter( ?enabled '(noall) ?onButtons '(noall))
	)
)

;endregion

;region Log

procedure( SetUpLog_utilityprogram( log_name @key (mode "w") (log_time nil))
	prog( ( log_dir year month date hour minute second log_file_name log_path out_port)	
		unless( axlGetVariable( "ads_sdlog")
			axlSetVariable( "ads_sdlog" "log")
		)
		
		log_dir = axlGetVariable( "ads_sdlog") || ""
		unless( or( zerop( strlen( log_dir)) isDir( log_dir))
			createDir( log_dir)
		)
		
		sprintf( log_file_name "%s-%s.log" log_name GetTimeStamp_utilityprogram( log_time))
		sprintf( log_path "%s/%s" log_dir log_file_name)
		
		out_port = outfile( log_path mode)
		unless( outportp( out_port)
			PrintMsg_utilityprogram( "Fail to write log" ?title "SetUpLog()" ?level 'error)
			return( nil)
		)
		
		return( list( out_port log_path))
	)
)

;endregion

;region Form

procedure( NewForm_utilityprogram( file_name header port_width port_height @optional (start_title t))
	prog( ( out_port)
		out_port = outfile( file_name "w")
		unless( outportp( out_port)
			PrintMsg_utilityprogram( "Fail to write form" ?title "NewForm()" ?level 'error)
			return( nil)
		)
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")
		fprintf( out_port "FORM \n")
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" port_width port_height)
		fprintf( out_port "HEADER \"%s\"\n" header)
		when( start_title
			fprintf( out_port "TILE\n")
		)
		
		WriteFormText_utilityprogram( out_port header 1 0 ?option "bold")

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

procedure( WriteFormText_utilityprogram( out_port text x y @key (width 0) (height 0) (option nil))
	let( ()
		fprintf( out_port "TEXT \"%s\" \n" text)
		fprintf( out_port "FLOC %d %d\n" x y)
		;fprintf( out_port "FSIZE %s %d\n" width height)
		when( option
			fprintf( out_port "OPTIONS %s\n" option)
		)
		
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
		when( info_only
			fprintf( out_port "INFO_ONLY\n")
		)
		
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormIntSlideBar_utilityprogram( out_port field x y width field_length @key (min_value 1.0) (max_value 100.0))
	let( ()
		; numeric textbox with up/down control
		unless( and( min_value max_value numberp( min_value) numberp( max_value)) 
			error( "INTSLIDEBAR must input min & max value")
		)
		
		; convert to float
		min_value = atof( sprintf( min_value "%L" min_value))
		max_value = atof( sprintf( max_value "%L" max_value))
		
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "INTSLIDEBAR %d %d\n" width field_length)
		fprintf( out_port "MIN %f\n" min_value)
		fprintf( out_port "MAX %f\n" max_value)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormRealFillin_utilityprogram( out_port field x y width field_length @key (decimal 2) (min_value nil) (max_value nil) (info_only nil))
	let( ()
		; numeric textbox (floating point numbers)
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "REALFILLIN %d %d\n" width field_length)
		fprintf( out_port "DECIMAL %d\n" decimal)
		when( min_value
			fprintf( out_port "MIN %f\n" min_value)
		)
		
		when( max_value
			fprintf( out_port "MAX %f\n" max_value)
		)
		
		when( info_only
			fprintf( out_port "INFO_ONLY\n")
		)
		
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormThumbnail_utilityprogram( out_port field x y width height)
	let( ()
		fprintf( out_port "FIELD %sPicture\n" field)
		fprintf( out_port "THUMBNAIL %s\n" field)
		fprintf( out_port "OPTIONS %s\n" "stretch")
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "FSIZE %d %d\n" width height)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormCheckList_utilityprogram( out_port field content x y @optional (argument nil))
	let( ()
		; CheckBox
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		; add space after content to avoid content to be cut off
		content = strcat( " " content " ")
		if( argument
			fprintf( out_port "CHECKLIST \"%s\" \"%s\"\n" content argument)
			fprintf( out_port "CHECKLIST \"%s\"\n" content)
		)
		
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( WriteFormEnumSet_utilityprogram( out_port field x y width @optional (height 0) (pop_name nil))
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
	let( ( option)
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

procedure( WriteFormGrid_utilityprogram( out_port field x y width height @key (top_size 2) (side_size 5))
	let( ()
		fprintf( out_port "GRID %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "FSIZE %d %d\n" width height)
		;fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		fprintf( out_port "OPTIONS HLINES VLINES\n")
		fprintf( out_port "GHEAD TOP\n")
		fprintf( out_port "HEADSIZE %d\n" top_size)
		fprintf( out_port "OPTIONS 3D\n")
		fprintf( out_port "ENDGHEAD\n")
		when( side_size
			fprintf( out_port "GHEAD SIDE\n")
			fprintf( out_port "HEADSIZE %d\n" side_size)
			fprintf( out_port "OPTIONS 3D\n")
			fprintf( out_port "ENDGHEAD\n")
		)
		
		fprintf( out_port "ENDGRID\n\n")
	)
)

procedure( CreateFormCol_utilityprogram( out_form grid_key type text label @key (col_width 8) (align 'left) (popup nil) (decimals nil) (field_length nil))
	let( ( col)
		col = make_formGridCol()
		col->fieldType = type
		col->headText = text
		col->scriptLabel = label
		col->colWidth = col_width
		col->align = align
		col->popup = popup
		col->decimals = decimals
		col->fieldLength = field_length
		axlFormGridInsertCol( out_form grid_key col)
	)
)

procedure( CreateGridCell_utilityprogram( out_form grid_key row col @key (value nil) (check nil) (no_edit t) (back_color nil))
	let( ( cell)
		cell = axlFormGridNewCell()
		cell->row = row
		cell->col = col
		cell->value = value
		cell->check = check
		cell->noEdit = no_edit
		when( symbolp( back_color)
			cell->backColor = back_color
		)
		
		axlFormSetField( out_form grid_key cell)
	)
)

procedure( SetFieldValues_utilityprogram( out_form form_key_ls @optional (value t))
	let( ()
		foreach( form_key form_key_ls
			axlFormSetField( out_form form_key value)
		)
	)
)

procedure( GetFieldValues_utilityprogram( out_form form_key_ls table)
	let( ()
		foreach( form_key form_key_ls
			valid = axlFormGetField( out_form form_key)
			table[ form_key] = valid
		)
	)
)

procedure( UpdateFormData_utilityprogram( out_form grid_key grid_col row_ls @key (value nil) (check nil))
	let( ( cell)
		cell = axlFormGridNewCell()
		cell->col = grid_col
		cell->value = value
		cell->check = check
		foreach( row row_ls
			cell->row = row
			axlFormSetField( out_form grid_key cell)
		)
		
		axlFormGridUpdate( out_form grid_key)
	)
)

procedure( GetGridChecked_utilityprogram( out_form grid_key check_col_index data_col_index)
	prog( ( cell data_ls)
		cell = axlFormGridNewCell()
		foreach( row _total_row_ls
			cell->row = row
			; get check value on current row
			cell->col = check_col_index
			is_checked = axlFormGridGetCell( out_form grid_key cell)->check
			when( is_checked
				; get data on current row
				cell->col = data_col_index
				data = axlFormGridGetCell( out_form grid_key cell)->value
				data_ls = append1( data_ls data)
			)
		)
		
		return( data_ls)
	)
)

procedure( CreateMessageBox_utilityprogram( msg title @optional (button_info_ls list( list( 'yes "Yes") list( 'no "No"))) (def_key 'yes))
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
		group_y = 0
		
		context_x = 3
		y_end = group_y + 2
		WriteFormText_utilityprogram( out_port msg context_x y_end)
		
		y_end = y_end + 3
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
	prog( ()
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

;endregion

;region XML

procedure( GetXmlSections_utilityprogram( element file_addr)
	prog( (in_port header tailer start_getting sect_ls)
		msg_title = "GetXmlSections()"
		unless( stringp( element)
			PrintMsg_utilityprogram( "element is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		unless( isFile( file_addr)
			PrintMsg_utilityprogram( "file_addr is not a file" ?title msg_title ?level 'error)
			return( nil)
		)
		unless( inportp( in_port = infile( file_addr))
			PrintMsg_utilityprogram( "Fail to read file" ?title msg_title ?level 'error)
			return( nil)
		)
		
		; file_addr = "D:/Footprint_Check/self_create/351_derek/ic_sdram-ddr4_78p_mt40a1g8.xml"
		sprintf( header "<%s>" element)
		sprintf( tailer "</%s>" element)
		stack_line = ""
		while( stringp( gets( line in_port))
			when( and( start_getting index( line tailer))
				line = strcat( "<" car( parseString( cadr( parseString( line "<")) ">")) ">")
				stack_line = strcat( stack_line line)
				sect_ls = append1( sect_ls stack_line)
				stack_line = ""
				start_getting = nil
			)

			when( start_getting
				line = strcat( "<" car( parseString( cadr( parseString( line "<")) ">")) ">")
				stack_line = strcat( stack_line line)
			)

			when( and( null( start_getting) index( line header))
				line = strcat( "<" car( parseString( cadr( parseString( line "<")) ">")) ">")
				stack_line = line
				start_getting = t
			)
		)
		
		close( in_port)
		return( sect_ls)
	)
)

procedure( GetXmlContent_utilityprogram( section element)
	;;; the format of the xml:
	;;;		section: <element>content<element/>
	prog( (sect_ls content)
		msg_title = "GetXmlContent()"
		unless( stringp( section)
			PrintMsg_utilityprogram( "section is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		unless( stringp( element)
			PrintMsg_utilityprogram( "element is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		unless( index( section element)
			PrintMsg_utilityprogram( "element is not in section" ?title msg_title ?level 'error)
			return( nil)
		)
		unless( ((strlen( element) * 2) < strlen( section))
			PrintMsg_utilityprogram( "Length of section has to be larger than elements twice" ?title msg_title ?level 'error)
			return( nil)
		)
		
		;;; get the content between 2 element
		sect_ls = parseString( section "<>")
		sect_ls = cdr( exists( x sect_ls index( x element)))
		sect_ls = reverse( cdr( exists( x reverse( sect_ls) index( x element))))
		content = strcat( "<" buildString( sect_ls "><") ">")
		return( content)
	)
)

procedure( GetXmlAttribute_utilityprogram( section key @optional (pattern ".*"))
	prog( (attribute_pattern val)
		msg_title = "GetXmlAttribute()"
		unless( stringp( section)
			PrintMsg_utilityprogram( "section is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		unless( stringp( key)
			PrintMsg_utilityprogram( "key is not a string" ?title msg_title ?level 'error)
			return( nil)
		)
		unless( index( section key)
			PrintMsg_utilityprogram( "key is not in section" ?title msg_title ?level 'error)
			return( nil)
		)
		
		sprintf( attribute_pattern "%s=\"\\(%s\\)\" " key pattern)
		rexCompile( attribute_pattern)
		when( rexExecute( section)
			val = rexSubstitute( "\\1")
		)
		
		return( val)
	)
)

;endregion

/*
(encrypt "c:/skill/utility_program_v4d2.il" "c:/skill/utility_program_v4d2.ile")
(load "utility_program_v4d2.il")
(load "utility_program_v4d2.ile")
*/