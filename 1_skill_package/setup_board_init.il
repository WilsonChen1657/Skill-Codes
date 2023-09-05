;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsi
; Starting Date: 06/06/2019 - _Derek06062019
; introduction:
;	1. to initlize a board file by date in certain excel file
;	2. content of excel
;		1. New_Obj
;		2. Analysis_Mode
;		3. Design_Param
;		4. Textblock
;		5. CM_Default
;		6. DFA_Min_Top
;		7. DFA_Min_Bot
;		8. DFA_Rec_Top
;		9. DFA_Rec_Bot
;		10. Testprep
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek06062019()
	setq( _allegro_path getWorkingDir())
	setq( _allegro_unit upperCase( car( axlDBGetDesignUnits())))
	setq( _allegro_version axlVersion( 'version))
	setq( _allegro_pversion axlVersion( 'pVersion))
	setq( _allegro_path getWorkingDir())
	setq( _board_init_xlsx_addr "")
	
	;;; setup global variable for trigger import
	setq( _setup_board_init_table makeTable( "setup_board_init" nil))
	setq( _is_rec_dfa t)
	setq( _to_run nil)

	setq( _allow_pad_pad_conn_opts list( "ALL_ALLOWED" "VIAS_PINS_ONLY" "VIAS_VIAS_ONLY" "MICROVIAS_MICROVIAS_ONLY" "MICROVIAS_MICROVIAS_COINCIDENT_ONLY" "NOT_ALLOWED"))
	setq( _allow_ts_opts list( "NOT_ALLOWED" "ANYWHERE" "PINS_ONLY" "VIAS_PINS_ONLY"))
	setq( _unit_ls list( "MIL" "MM" "DEGREE"))
	setq( _yes_no list( "YES" "NO"))
	setq( _on_off list( "ON" "OFF"))
	setq( _true_false list( "TRUE" "FALSE"))
	setq( _smt_thru list( "SMT TESTPAD" "THRU VIA"))
	setq( _drc_ther list( "DRC" "THERMAL/ANTI"))
	
	setq( _tmp_prm_name "setup_board_init.prm")
	setq( _tmp_dfa_name "setup_board_init.dfa")
	setq( _tmp_scr_name "setup_board_init.scr")
	setq( _tmp_tcf_name "setup_board_init.tcf")
	setq( _form_filename "setup_board_init.form")
	setq( _form_handle 'board_init_form_handle)
	setq( _default_board_init_addr "T:/Layout/SOP/0_Board_Setup/board_init_vDerek.xlsx")
	setq( _figure_num_ls list( '("TRIANGLE" 18)
								'("SQUARE" 5)
								'("DAIMOND" 7)
								'("OCTAGON" 3)
								'("HEXAGON Y" 16)
								'("HEXAGON X" 15)
								'("RECTANGLE" 6)
								'("OBLONG X" 11)
								'("OBLONG Y" 12)))
	
	setq( _tmp_scr_addr strcat( _allegro_path "/" _tmp_scr_name))

	setq( _class_ls axlClasses())
	
	setq( _title_testprep_setting "SETTING")
	setq( _title_testprep_padstack "PADSTACK SELECTION")
	setq( _title_testprep_probe "PROBE TYPES")
	
	setq( _sht_nm_new "New_Obj")
	setq( _sht_nm_ana if( ( _allegro_version > 17.0) "Analysis_Mode_17" "Analysis_Mode_16"))
	setq( _sht_nm_des "Design_Param")
	setq( _sht_nm_txt "Textblock")
	setq( _sht_nm_cmd "CM_Default")
	setq( _sht_nm_dfr "DFA_Rec")
	setq( _sht_nm_dfm "DFA_Min")
	setq( _sht_nm_tst "Testprep")
	setq( _sheet_name_ls list( _sht_nm_new _sht_nm_ana _sht_nm_des _sht_nm_txt _sht_nm_cmd _sht_nm_dfr _sht_nm_dfm _sht_nm_tst))
	setq( _total_sheet_num length( _sheet_name_ls))
	
	setq( _fnm_csv_table makeTable( "fnm_csv" nil))
	for( th 0 sub1( _total_sheet_num) (_fnm_csv_table[ nth( th _sheet_name_ls)] = sprintf( nil "Excel_sheet[%d].csv" th)))
	
	setq( _fnm_table_table makeTable( "fnm_table" nil))
	for( th 0 sub1( _total_sheet_num) (_fnm_table_table[ nth( th _sheet_name_ls)] = sprintf( nil "Excel_sheet[%d].table" th)))
	
	;;;; used in excel format
	setq( _key_func "[func]")
	
	;;;; used in form
	setq( _key_all "ctrl_all")
	setq( _key_non "ctrl_none")
	setq( _key_no "setup_no")
	setq( _key_am "setup_am")
	setq( _key_dp "setup_dp")
	setq( _key_tb "setup_tb")
	setq( _key_cd "setup_cd")
	setq( _key_dt "setup_dt")
	setq( _key_tp "setup_tp")
	setq( _key_dt_rec "setup_dt_rec")
	setq( _key_dt_min "setup_dt_min")
	setq( _key_run "run")
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_form_Derek06062019()
	prog( ( contents group_width content_x group_x y_start y_end)
		out_port = outfile( _form_filename "w")
		unless( outportp( out_port) println( "ERROR: write_form() - Fail to write file") return( nil))
		
		group_width = 20
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		;;; headr
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" (group_width + 2) 100)
		fprintf( out_port "HEADER \"Gerber Package Selector\"\n")
		fprintf( out_port "TILE\n")
		
		;;; control panel
		
		group_y = 1
		y_start = group_y
		y_end = y_start
		
		fprintf( out_port "FIELD %s\n" _key_all)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" 'All 'ctrl)
		fprintf( out_port "ENDFIELD\n")

		fprintf( out_port "FIELD %s\n" _key_non)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" 'None 'ctrl)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "GROUP \"%s\"\n" 'Control)
		fprintf( out_port "FLOC %d %d\n" group_x group_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width (y_end - y_start + 2))
		fprintf( out_port "ENDGROUP\n")
		
		;;; selection of the setup package
		
		group_y = y_end + 2
		y_start = group_y
		y_end = y_start
		
		fprintf( out_port "FIELD %s\n" _key_dp)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Design Parameter")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_tb)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Textblock")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_no)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " New Objective")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_am)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Analysis Mode")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_cd)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Cmgr Default")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_dt)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " DFA Table")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_dt_rec)
		fprintf( out_port "FLOC %d %d\n" sub_content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" 'Recommend 'dfa)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_dt_min)
		fprintf( out_port "FLOC %d %d\n" sub_content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" 'Minimum 'dfa)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _key_tp)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Testprep")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "GROUP \"%s\"\n" 'Setup)
		fprintf( out_port "FLOC %d %d\n" group_x group_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width (y_end - y_start + 2))
		fprintf( out_port "ENDGROUP\n")
		
		;;; button for run
		
		group_y = y_end + 1
		y_start = group_y
		y_end = y_start
		
		fprintf( out_port "FIELD %s\n" _key_run)
		fprintf( out_port "FLOC %d %d\n" group_x (y_end = (y_end + 2)))
		fprintf( out_port "MENUBUTTON \"RUN\" %d %d\n" group_width 2)
		fprintf( out_port "ENDFIELD\n\n")
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		;;; tail
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( set_form_options_Derek06062019( form_id no am dp tb cd dt tp)
	prog( ( )
		unless( axlIsFormType( form_id) println( "ArgErr: set_form_options() - form_id is not in form type") return( nil))
		unless( booleanp( no) println( "ArgErr: set_form_options() - no is not a boolean") return( nil))
		unless( booleanp( am) println( "ArgErr: set_form_options() - am is not a boolean") return( nil))
		unless( booleanp( dp) println( "ArgErr: set_form_options() - dp is not a boolean") return( nil))
		unless( booleanp( tb) println( "ArgErr: set_form_options() - tb is not a boolean") return( nil))
		unless( booleanp( cd) println( "ArgErr: set_form_options() - cd is not a boolean") return( nil))
		unless( booleanp( dt) println( "ArgErr: set_form_options() - dt is not a boolean") return( nil))
		unless( booleanp( tp) println( "ArgErr: set_form_options() - tp is not a boolean") return( nil))
		;;
		
		axlFormSetField( form_id _key_no no)
		axlFormSetField( form_id _key_am am)
		axlFormSetField( form_id _key_dp dp)
		axlFormSetField( form_id _key_tb tb)
		axlFormSetField( form_id _key_cd cd)
		axlFormSetField( form_id _key_dt dt)
		axlFormSetField( form_id _key_tp tp)
		
		axlFormSetFieldEditable( form_id _key_dt_rec dt)
		axlFormSetFieldEditable( form_id _key_dt_min dt)
		
		return( t)
	)
)

procedure( set_form_Derek06062019( form_id)
	prog( ()
		unless( axlIsFormType( form_id) println( "ArgErr: set_form() - form_id is not in form type") return( nil))
		;;
		
		axlFormSetField( form_id _key_all t)
		
		set_form_options_Derek06062019( form_id t t t t t t t)
		
		axlFormSetField( form_id _key_dt_rec t)
		
		axlFormDefaultButton( form_id _key_run)
		
		return( t)
	)
)

procedure( form_action_Derek06062019( form_id)
	prog( ( cur_field status)
		unless( axlIsFormType( form_id) println( "ArgErr: form_action() - form_id is not in form type") return( nil))
		;;
		
		cur_field = form_id->curField
		
		cond( 
			( equal( cur_field _key_all)
				set_form_options_Derek06062019( form_id t t t t t t t)
			)
			( equal( cur_field _key_non)
				set_form_options_Derek06062019( form_id nil nil nil nil nil nil nil)
			)
			( equal( cur_field _key_dt)
				status = not( axlFormIsFieldEditable( form_id _key_dt_rec))
				axlFormSetFieldEditable( form_id _key_dt_rec status)
				axlFormSetFieldEditable( form_id _key_dt_min status)
			)
			( equal( cur_field _key_run)
				status = axlFormGetField( form_id _key_no)
				_setup_board_init_table[ _key_no] = status
				
				status = axlFormGetField( form_id _key_am)
				_setup_board_init_table[ _key_am] = status
				
				status = axlFormGetField( form_id _key_dp)
				_setup_board_init_table[ _key_dp] = status
				
				status = axlFormGetField( form_id _key_tb)
				_setup_board_init_table[ _key_tb] = status
				
				status = axlFormGetField( form_id _key_cd)
				_setup_board_init_table[ _key_cd] = status
				
				status = axlFormGetField( form_id _key_dt)
				_setup_board_init_table[ _key_dt] = status
				_is_rec_dfa = axlFormGetField( form_id _key_dt_rec)
				
				status = axlFormGetField( form_id _key_tp)
				_setup_board_init_table[ _key_tp] = status
				
				axlFormClose( form_id)
				_to_run = t
			)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( create_layer_Derek06062019( layer)
	prog( ( class subclass )
		unless( stringp( layer) println( "ArgErr: create_layer() - layer is not a string") return( nil))
		unless( index( layer "/") println( "ArgErr: create_layer() - layer does not include '/'") return( nil))
		class = car( parseString( layer "/"))
		subclass = cadr( parseString( layer "/"))
		unless( member( class _class_ls) printf( "ERROR: create_layer() - class[%s] of layer does not exists\n" class) return( nil))
		when( equal( "" subclass) printf( "ERROR: create_layer() - subclass can not be \"\"") return( nil))
		;;
		
		if( axlIsLayer( layer) then
			printf( "create_layer() - Exists layer [%s]\n" layer)
		else
			axlLayerCreateNonConductor( layer)
			printf( "create_layer() - Create layer [%s]\n" layer)
		)
		
		return( t)
	)
)

procedure( load_symbol_Derek06062019( sym_nm)
	;; sym_nm = "flex_pcb_form_v1"
	prog( ( sym_id type result)
		unless( stringp( sym_nm) println( "ArgErr: load_symbol() - sym_nm is not a string") return( nil))
		;;
		
		unless( sym_id
			type = "PACKAGE"
			sym_id = axlLoadSymbol( type sym_nm)
		)
		unless( sym_id
			type = "MECHANICAL"
			sym_id = axlLoadSymbol( type sym_nm)
		)
		unless( sym_id
			type = "FORMAT"
			sym_id = axlLoadSymbol( type sym_nm)
		)
		
		when( sym_id (result = list( sym_id type)))
		
		return( result)
	)
)

procedure( create_symbol_Derek06062019( sym_nm center_xy)
	;; sym_nm = "flex_pcb_form_v1"
	prog( ( up_sym_nm sym_id msg to_create result)
		unless( dtpr( center_xy) println( "ArgErr: create_symbol() - center_xy is not a dtpr") return( nil))
		unless( stringp( sym_nm) println( "ArgErr: create_symbol() - sym_nm is not a string") return( nil))
		
		;;;;
		up_sym_nm = upperCase( sym_nm)
		sym_ls = axlDBGetDesign()->symbols
		sym_ls = setof( x sym_ls equal( up_sym_nm x->name))
		when( and( dtpr( sym_ls) onep( length( sym_ls))) (sym_id = car( sym_ls)))
		
		to_create = t
		when( sym_id
			sprintf( msg "symbol [%s] is loaded. Do you want to reload it?" sym_nm)
			to_create = axlUIYesNo( msg "Reload Symbol Confirm" 'yes)
			when( to_create axlDeleteObject( sym_id))
		)
		
		;;;; load targer symbol from library
		when( to_create
			unless( result (result = axlDBCloak( 'axlDBCreateSymbol( list( sym_nm "FORMAT") center_xy) '(shape ignoreFixed))))
			unless( result (result = axlDBCloak( 'axlDBCreateSymbol( list( sym_nm "PACKAGE") center_xy) '(shape ignoreFixed))))
			unless( result (result = axlDBCloak( 'axlDBCreateSymbol( list( sym_nm "MECHANICAL") center_xy) '(shape ignoreFixed))))
			
			axlVisibleUpdate( t)
			printf( "create_symbol() - Create symbol [%s] at %L\n" sym_nm center_xy)
		)
		
		when( dtpr( result) (result = car( result)))
		
		return( result)
	)
)

procedure( import_new_obj_Derek06062019( csv_filename)
	prog( ( in_port  curr_cat category category_col content_col layer_ls sym_ls region_ls center_xy)
		unless( stringp( csv_filename) println( "ArgErr: import_new_obj() - csv_filename is not a string") return( nil))
		unless( isFile( csv_filename) println( "ArgErr: import_new_obj() - csv_filename is not a file") return( nil))
		in_port = infile( csv_filename)
		unless( inportp( in_port) println( "ArgErr: import_new_obj() - Fail to read file") return( nil))
		;;
		
		category_col = 1
		content_col = 2
		
		;;;; skip the first line, first line BACK function
		gets( csv_line in_port)
		
		;;;; skip the second line for header
		gets( csv_line in_port)
		
		;;; loop through the file
		curr_cat = category = ""
		while( gets( csv_line in_port)
			when( stringp( csv_line)
				csv_ls = axlStringCSVParse( csv_line t)
				;;
				
				category = upperCase( nth( category_col csv_ls))
				unless( equal( "" category) (curr_cat = category))
				
				;;
				case( curr_cat
					( "LAYER"
						content = nth( content_col csv_ls)
						unless( equal( "" content) (layer_ls = append1( layer_ls content)))
					)
					( "SYMBOL"
						content = nth( content_col csv_ls)
						unless( equal( "" content) (sym_ls = append1( sym_ls content)))
					)
					( "REGION"
						content = nth( content_col csv_ls)
						unless( equal( "" content) (region_ls = append1( region_ls content)))
					)
					( t
						printf( "Warning: import_new_obj() - Yet to define category [%s]\n" curr_cat)
					)
				)
			)
		)
		close( in_port)
		
		;;; create layer
		foreach( layer layer_ls create_layer_Derek06062019( layer))
		
		;;; create symbol
		center_xy = list( 0 0)
		foreach( sym_nm sym_ls create_symbol_Derek06062019( sym_nm center_xy))
		
		;;; create region
		foreach( region region_ls axlRegionCreate( region))
		
		return( t)
	)
)

procedure( import_analysis_mode_Derek06062019( csv_filename)
	;; des_ls: list of design options
	;; ele_ls: list of electrical options
	;; phy_ls: list of physical options
	;; spac_ls: list of spacing
	;; smd_ls: list of smd pin
	;; same_ls: list of same net spacing
	prog( ( in_port category_col func_col value_col curr_cat category
			csv_line csv_ls func val err_msg result title)
		unless( stringp( csv_filename) println( "ArgErr: import_analysis_mode() - csv_filename is not a string") return( nil))
		unless( isFile( csv_filename) println( "ArgErr: import_analysis_mode() - csv_filename is not a file") return( nil))
		in_port = infile( csv_filename)
		unless( inportp( in_port) println( "ArgErr: import_analysis_mode() - Fail to read file") return( nil))
		;;
		
		;;
		category_col = 1
		title_col = 3
		value_col = 4
		func_col = 5
		
		;;;; skip the first line, first line or BACK function
		gets( csv_line in_port)
		
		;;;; skip the second line, header
		gets( csv_line in_port)
		
		;;
		curr_cat = category = ""
		while( stringp( gets( csv_line in_port))
			csv_ls = axlStringCSVParse( csv_line t)
			;;
			
			;;;
			func = nth( func_col csv_ls)
			when( and( stringp( func) not( equal( "" func))) (func = stringToSymbol( func)))
			
			;;; get the value of current title
			title = nth( title_col csv_ls)
			
			;;; get the value of current entry
			val = upperCase( nth( value_col csv_ls))
			
			;;;
			category = upperCase( nth( category_col csv_ls))
			unless( equal( "" category) (curr_cat = category))
			
			;;
			sprintf( err_msg "Warning: import_analysis_mode() - Fail to get [%L][%L] value[%L](on/off)" curr_cat title val)
			case( curr_cat
				( ("DESIGN MODES" "SMD PIN MODES" "DESIGN")
					val = correct_data_type_Derek06062019( val 'onoff_sym err_msg)
					when( val (result = axlCNSDesignModeSet( func val)))
				)
				( ("DESIGN OPTIONS" "DESIGN VALUE")
					sprintf( err_msg "Warning: import_analysis_mode() - Fail to get [%s][%s] value[%s](<number> <unit>)" curr_cat title val)
					val = correct_data_type_Derek06062019( val 'num_unit err_msg)
					when( val (result = axlCNSDesignValueSet( func val)))
				)
				( ("ELECTRICAL MODES" "ELECTRICAL")
					func = symbolToString( func)
					if( index( func _key_func) then
						func = substring( func add1( strlen( _key_func)))
						func = stringToSymbol( func)
						val = correct_data_type_Derek06062019( val 'onoff err_msg)
						result = funcall( func val)
					else
						func = stringToSymbol( func)
						val = correct_data_type_Derek06062019( val 'onoff_sym err_msg)
						when( val (result = axlCNSEcsetModeSet( func val)))
					)
				)
				( ("PHYSICAL MODES" "PHYSICAL")
					val = correct_data_type_Derek06062019( val 'onoff_sym err_msg)
					when( val (result = axlCNSPhysicalModeSet( func val)))
				)
				( ("SPACING MODES" "SPACING")
					val = correct_data_type_Derek06062019( val 'onoff_sym err_msg)
					when( val (result = axlCNSSpacingModeSet( func val)))
				)
				( ("SAME NET SPACING MODES" "SAME NET SPACING")
					val = correct_data_type_Derek06062019( val 'onoff_sym err_msg)
					when( val (result = axlCNSSameNetModeSet( func val)))
				)
				( "ASSEMBLY"
					val = correct_data_type_Derek06062019( val 'onoff_sym err_msg)
					when( val (result = axlCNSAssemblyModeSet( func val)))
				)
				( t
					printf( "Warning: import_analysis_mode() - Yet to define category [%s]\n" curr_cat)
				)
			)
			;;
			unless( result printf( "\tWarning: import_analysis_mode() - Fail to setup [%s][%s]\n" curr_cat title))
		)
		close( in_port)
		
		return( t)
	)
)

procedure( correct_data_type_Derek06062019( data type err_msg)
	prog( ( num unit result)
		unless( or( stringp( data) dtpr( data))
			printf( "ArgErr: correct_data_type() - data[%L] is not a string or a dtpr\n" data)
			printf( "\t%s\n" err_msg)
			return( nil)
		)
		unless( symbolp( type) println( "ArgErr: correct_data_type() - type is not a symbol") return( nil))
		;;
		
		caseq( type
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
				unless( member( result _allow_pad_pad_conn_opts)
					println( err_msg)
					result = nil
				)
			)
			( 'yesno
				result = upperCase( data)
				if( member( result _yes_no) then
					result = equal( "YES" result)
				else
					println( err_msg)
					result = nil
				)
			)
			( 'onoff
				result = upperCase( data)
				if( member( result _on_off) then
					result = equal( "ON" result)
				else
					println( err_msg)
					result = nil
				)
			)
			( 'truefalse_string
				result = upperCase( data)
				unless( member( result _true_false)
					println( err_msg)
					result = nil
				)
			)
			( 'onoff_sym
				result = upperCase( data)
				if( member( result _on_off) then
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
				if( and( stringp( num) stringp( unit) plusp( atoi( num)) member( upperCase( unit) _unit_ls)) then
					result = data
				else
					println( err_msg)
					result = nil
				)
			)
			( 'drc_ther
				result = upperCase( data)
				unless( member( result _drc_ther)
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
				unless( member( result _allow_ts_opts)
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
			(t
				printf( "ERROR: correct_data_type() - Yet to support type[%s] to identify data[%s]\n" type data)
				result = nil
			)
		)
		
		return( result)
	)
)

procedure( read_table_Derek06062019( table_filename table_name)
	prog( ( in_port table csv_ls key val)
		unless( symbolp( table_name) println( "ArgErr: read_table() - table_name is not a symbol") return( nil))
		unless( stringp( table_filename) println( "ArgErr: read_table() - table_filename is not a string") return( nil))
		unless( isFile( table_filename) println( "ArgErr: read_table() - table_filename is not a file") return( nil))
		in_port = infile( table_filename)
		unless( inportp( in_port) println( "ArgErr: read_table() - Fail to read table_filename") return( nil))
		;;
		
		table = makeTable( table_name nil)
		
		while( gets( csv_line in_port)
			when( and( index( csv_line ",") stringp( csv_line))
				csv_ls = axlStringCSVParse( csv_line ",")
				key = car( csv_ls)
				val = buildString( cdr( csv_ls) ",")
				;;
				if( and( index( key "[") index( key "]")) then
					key = substring( key 2 (strlen( key) - 2))
					table[ key] = val
				else
					printf( "Warning: read_table() - Fail to manipulate csv_line[%s] in [%s]\n" csv_line table_filename)
				)
			)
		)
		close( in_port)
		
		return( table)
	)
)

procedure( get_gds_xml_contents_Derek06062019( type)
	;;; get global dynamic shape xml content
	;;; result
	;<dynfill_parm_type>
	;	<rev>1</rev>
	;	<pin_control>
	;		<clearance>1</clearance>
	;	</pin_control>
	;</dynfill_parm_type>
	prog( ( type_num contents)
		unless( stringp( type) println( "ArgErr: get_gds_xml_contents() - type is not a string") return( nil))
		;;
		
		case( type
			( "THERMAL/ANTI" (type_num = 1))
			( "DRC" (type_num = 0))
			( t
				printf( "ERROR: get_gds_xml_contents() - Fail to define type[%s] for global dynamic shape parameter [thru_pin_clearance]\n" type)
				return( nil)
			)
		)
		
		;;
		contents = list( "<dynfill_parm_type>"
						"\t<rev>1</rev>"
						"\t<pin_control>"
						sprintf( nil "\t\t<clearance>%d</clearance>" type_num)
						"\t</pin_control>"
						"</dynfill_parm_type>"
						)
		
		return( contents)
	)
)

procedure( get_tcf_script_Derek06062019( filename)
	prog( ( contents)
		unless( stringp( filename) println( "ArgErr: get_tcf_script() - filename is not a string") return( nil))
		unless( isFile( filename) println( "ArgErr: get_tcf_script() - filename is not a file") return( nil))
		;;
		
		contents = list( "setwindow pcb"
					"generaledit"
					"techfile in"
					"setwindow form.tech_in"
					"FORM tech_in browse"
					sprintf( nil "fillin \"%s\"" filename)
					"FORM tech_in drc NO"
					"FORM tech_in execute"
					"setwindow pcb"
					"setwindow form.tech_in"
					"FORM tech_in cancel"
					"setwindow pcb"
					"generaledit")
		return( contents)
	)
)

procedure( import_design_param_Derek06062019( table_filename)
	;; csv_line = [B1],Class
	prog( ( value_col cell cell_sub table val width height box xml_line_ls param err_msg x y)
		unless( stringp( table_filename) println( "ArgErr: import_design_param() - table_filename is not a string") return( nil))
		;;
		
		value_col = "D"
		table = read_table_Derek06062019( table_filename 'design_param)
		
		;;;; setup global dynamic shape parameter by xml function
		sprintf( cell "%s%d" value_col 3)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get [global dynamic param] value[%L](drc/thermal)" val)
		val = correct_data_type_Derek06062019( val 'drc_ther err_msg)
		when( val
			xml_line_ls = get_gds_xml_contents_Derek06062019( val)
			xml_line_ls = append_xml_head_tail_Derek06062019( xml_line_ls)
			
			write_file_Derek06062019( _tmp_prm_name xml_line_ls)
			when( isFile( _tmp_prm_name) axlImportXmlDBRecords( _tmp_prm_name))
		)
		
		;;; handle
		axlUIConfirm( "Global Dynamic Shape Variable has been updated. Press OK to continue")
		
		;;;; setup design parameter
		sprintf( cell "%s%d" value_col 4)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get [width] value[%L](float)" val)
		width = correct_data_type_Derek06062019( val 'float err_msg)
		
		;;;;
		sprintf( cell "%s%d" value_col 5)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get height value[%L](float)" val)
		height = correct_data_type_Derek06062019( val 'float err_msg)
		
		;;;;
		sprintf( cell "%s%d" value_col 6)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get x value[%L](float)" val)
		x = correct_data_type_Derek06062019( val 'float err_msg)
		
		;;;;
		sprintf( cell "%s%d" value_col 7)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get y value[%L](float)" val)
		y = correct_data_type_Derek06062019( val 'float err_msg)
		
		when( and( x y width height)
			;printf( "\tWarning: import_design_param() - Not support extension. xy:[%L] width:[%.2f] height:[%.2f]\n" list( x y) width height)
			box = list( list( x y) list( (x + width) (y + height)))
			result = axlDBChangeDesignExtents( box)
			status = if( result "Successful" "Fail")
			printf( "Info: import_design_param() - %s to update extents to %L/%L\n" status list( x y) box)
		)
		
		;;;; setup display parameter
		sprintf( cell "%s%d" value_col 8)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get [display plated holes] value[%L](yesno)" val)
		val = correct_data_type_Derek06062019( val 'yesno err_msg)
		when( val
			func = 'platedHolesEnable
			result = axlDBDisplayControl( func val)
			status = if( result "Successful" "Fail")
			printf( "Info: import_design_param() - %s to update [%s] to %s\n" status func val)
		)
		
		;;;;
		sprintf( cell "%s%d" value_col 9)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get [display non plated holes] value[%L](yesno)" val)
		val = correct_data_type_Derek06062019( val 'yesno err_msg)
		when( val
			func = 'nonPlatedHolesEnable
			result = axlDBDisplayControl( func val)
			status = if( result "Successful" "Fail")
			printf( "Info: import_design_param() - %s to update [%s] to %s\n" status func val)
		)
		
		;;;;
		sprintf( cell "%s%d" value_col 10)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get [display thermal] value[%L](yesno)" val)
		val = correct_data_type_Derek06062019( val 'yesno err_msg)
		when( val
			func = 'thermalPadEnable
			result = axlDBDisplayControl( func val)
			status = if( result "Successful" "Fail")
			printf( "Info: import_design_param() - %s to update [%s] to %s\n" status func val)
		)
		
		;;;;
		sprintf( cell "%s%d" value_col 11)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get [long name size] value[%L](plus_int)" val)
		val = correct_data_type_Derek06062019( val 'plus_int err_msg)
		when( val
			func = 'maxNameLength
			result = axlDBControl( func val)
			status = if( result "Successful" "Fail")
			printf( "Info: import_design_param() - %s to update [%s] to %d\n" status func val)
		)
		
		;;;;
		sprintf( cell "%s%d" value_col 12)
		val = table[ cell]
		sprintf( err_msg "Warning: import_design_param() - Fail to get [accuracy] value[%L](plus_int)" val)
		val = correct_data_type_Derek06062019( val 'plus_int err_msg)
		when( val
			result = axlDBChangeDesignUnits( nil val)
			status = if( result "Successful" "Fail")
			printf( "Info: import_design_param() - %s to update [Unit] to %d\n" status val)
		)
		
		return( t)
	)
)

procedure( import_textblock_Derek06062019( csv_filename)
	prog( ( in_port csv_line csv_ls text_id width height line_space photo char text_name param)
		unless( stringp( csv_filename) println( "ArgErr: import_textblock() - csv_filename is not a string") return( nil))
		unless( isFile( csv_filename) println( "ArgErr: import_textblock() - csv_filename is not a file") return( nil))
		in_port = infile( csv_filename)
		unless( inportp( in_port) println( "ArgErr: import_textblock() - Fail to read file") return( nil))
		;;
		
		;;;; skip the first row, BACK function
		gets( csv_line in_port)
		
		;;;; skip the second line, header
		gets( csv_line in_port)
		
		while( gets( csv_line in_port)
			csv_ls = axlStringCSVParse( csv_line)
			
			;;; first column is blank for "BACK"
			text_id = atoi( nth( 1 csv_ls))
			width = atof( nth( 2 csv_ls))
			height = atof( nth( 3 csv_ls))
			line_space = atof( nth( 4 csv_ls))
			photo = atof( nth( 5 csv_ls))
			char = atof( nth( 6 csv_ls))
			
			if( and( plusp( text_id) numberp( width) numberp( height) numberp( line_space) numberp( photo) numberp( char)) then
				;;
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
				
				printf( "Creating text[%d]:\twidth[%.2f]\theight[%.2f]\tlineSpace[%.2f]\tphotoWidth[%.2f]\tcharSpace[%.2f]\n"
						text_id width height line_space photo char)
			else
				printf( "Warning: import_textblock() - Illegal data textblock[%L] width[%L] height[%L] lineSpace[%L] photoWidth[%L] charSpace[%L]\n"
						text_id width height line_space photo char)
			)
		)
		
		close( in_port)
		
		return( nil)
	)
)

procedure( set_phy_cns( func val)
	prog( ( err_msg check_type)
		unless( symbolp( func) println( "ArgErr: set_phy_cns() - func is not a symbol") return( nil))
		unless( stringp( val) println( "ArgErr: set_phy_cns() - val is not a string") return( nil))
		;;
		
		caseq( func
			( 'width_min (check_type = 'not_minus_float))
			( 'width_max (check_type = 'not_minus_float))
			( 'neckwidth_min (check_type = 'not_minus_float))
			( 'necklength_max (check_type = 'not_minus_float))
			( 'dp_min_gap (check_type = 'not_minus_float))
			( 'dp_primary_gap (check_type = 'not_minus_float))
			( 'dp_neck_gap (check_type = 'not_minus_float))
			( 'dp_coupled_plus (check_type = 'not_minus_float))
			( 'dp_coupled_minus (check_type = 'not_minus_float))
			( 'vias (check_type = 'vias_colon))
			( 'bbvia_stagger_min (check_type = 'not_minus_float))
			( 'bbvia_stagger_max (check_type = 'not_minus_float))
			( 'allow_padconnect (check_type = 'padpadconn))
			( 'allow_etch (check_type = 'truefalse_string))
			( 'allow_ts	(check_type = 'allowts))
			( t
				printf( "Warning: set_phy_cns() - Yet to support function[%s] with value[%s]\n" func val)
			)
		)
		
		result = symbolp( check_type)
		
		;;
		when( result
			sprintf( err_msg "Warning: set_phy_cns() - Fail to get [%L] value[%L](%s)" func val check_type)
			val = correct_data_type_Derek06062019( val check_type err_msg)
			when( val axlCNSSetPhysical( "" nil func val))
		)
		
		
		return( result)
	)
)

procedure( import_cm_default_Derek06062019( csv_filename)
	prog( ( in_port category_col name_col min_col max_col csv_line curr_cat category csv_ls )
		unless( stringp( csv_filename) println( "ArgErr: import_cm_default() - csv_filename is not a string") return( nil))
		unless( isFile( csv_filename) println( "ArgErr: import_cm_default() - csv_filename is not a file") return( nil))
		in_port = infile( csv_filename)
		unless( inportp( in_port) println( "ArgErr: import_cm_default() - Fail to read file") return( nil))
		;;
		
		category_col = 1
		func_col = 2
		title_col = 3
		value_col = 4
		
		;;;; skip the first row for BACK function
		gets( csv_line in_port)
		
		;;;; skip the second row for header
		gets( csv_line in_port)
		
		;;;
		curr_cat = category = ""
		while( gets( csv_line in_port)
			csv_ls = axlStringCSVParse( csv_line)
			
			;;
			category = upperCase( nth( category_col csv_ls))
			unless( equal( "" category) (curr_cat = category))
			
			;;
			func = nth( func_col csv_ls)
			when( and( stringp( func) not( equal( "" func))) (func = stringToSymbol( func)))
			
			title = nth( title_col csv_ls)
			
			val = nth( value_col csv_ls)
			
			;;
			if( and( symbolp( func) stringp( title) stringp( val)) then
				case( curr_cat
					( "PHYSICAL"
						set_phy_cns( func val)
					)
					( "SPACING"
						sprintf( err_msg "Warning: import_cm_default() - Fail to get [%L][%L] value[%L](plus_float)" curr_cat title val)
						val = correct_data_type_Derek06062019( val 'plus_float err_msg)
						when( val axlCNSSetSpacing( "" nil func val))
					)
					( "SAME NET SPACING"
						sprintf( err_msg "Warning: import_cm_default() - Fail to get [%L][%L] value[%L](plus_float)" curr_cat title val)
						val = correct_data_type_Derek06062019( val 'plus_float err_msg)
						when( val axlCNSSetSameNet( "" nil func val))
					)
					( t printf( "Warning: import_cm_default() - Fail to define category[%s] for [%s]\n" category csv_line))
				)
			else
				printf( "Warning: import_cm_default() - Incompleted data Cat[%L] Func[%L] Title[%L] Val[%L]\n" curr_cat func title val)
			)
		)
		close( in_port)
		
		;;; update constraint
		axlCNSMapUpdate()
		
		
		return( t)
	)
)

procedure( read_dfa_table_Derek06062019( csv_filename table_name)
	prog( ( line layer csv_ls csv_line contents in_port is_end row)
		unless( stringp( csv_filename) println( "ArgErr: read_dfa_table() - csv_filename is not a string") return( nil))
		unless( isFile( csv_filename) println( "ArgErr: read_dfa_table() - csv_filename is not a file") return( nil))
		unless( symbolp( table_name) println( "ArgErr: read_dfa_table() - table_name is not a symbol") return( nil))
		;;
		
		row = 0
		
		;;; create the content
		sprintf( line "DFA_TABLE_NAME=%s.dfa" table_name)
		contents = list( line "READONLY=NO" "UNITS=MILLIMETER")
		
		;;; start reading file
		in_port = infile( csv_filename)
		unless( inportp( in_port) println( "ArgErr: read_dfa_table() - Fail to read top dfa file") return( nil))
		
		;;; skip the first line
		++row
		gets( csv_line in_port)
		
		;;;;; ------------------------------------------------------------------- import TOP TABLE
		
		contents = append1( contents "TAB=Top")
		
		;;; get top header
		++row
		gets( csv_line in_port)
		csv_ls = axlStringCSVParse( csv_line ",")
		
		;;; check whether the first table is TOP
		layer = cadr( csv_ls)
		unless( equal( "TOP" layer) println( "ERROR: read_dfa_table() - Cell[B2] has to be [TOP]") close( in_port) return( nil))
		
		;;; get DFA category without [B1] and [TOP]
		csv_ls = cddr( csv_ls)
		line = strcat( "\t" buildString( csv_ls "\t"))
		contents = append( contents list( line "GROUP"))
		
		while( and( not( is_end) gets( csv_line in_port))
			++row
			csv_ls = axlStringCSVParse( csv_line)
			csv_ls = setof( x csv_ls not( equal( "" x)))
			if( dtpr( csv_ls) then
				line = buildString( csv_ls "\t")
				contents = append1( contents line)
			else
				is_end = t
			)
		)
		
		contents = append( contents list( "ENDGROUP" "ENDTAB"))
		
		;;;;; ------------------------------------------------------------------- import BOTTOM TABLE
		
		contents = append1( contents "TAB=Bottom")
		
		;;; get BOTTOM header
		++row
		gets( csv_line in_port)
		csv_ls = axlStringCSVParse( csv_line ",")
		
		;;; check whether the first table is BOTTOM
		layer = cadr( csv_ls)
		unless( equal( "BOTTOM" layer)
			printf( "ERROR: read_dfa_table() - Cell[B%d] has to be [BOTTOM]\n" row)
			close( in_port)
			return( nil)
		)
		
		;;; get DFA category without [B1] and [BOTTOM]
		csv_ls = cddr( csv_ls)
		line = strcat( "\t" buildString( csv_ls "\t"))
		contents = append( contents list( line "GROUP"))
		
		while( gets( csv_line in_port)
			csv_ls = axlStringCSVParse( csv_line)
			csv_ls = setof( x csv_ls not( equal( "" x)))
			when( dtpr( csv_ls)
				line = buildString( csv_ls "\t")
				contents = append1( contents line)
			)
		)
		
		contents = append( contents list( "ENDGROUP" "ENDTAB"))
		
		close( in_port)
		
		
		return( contents)
	)
		
)

procedure( get_dfa_script_contents_Derek06062019()
	let( ( line contents)
		if( (_allegro_version > 17.0) then
			sprintf( line "QtFillin \"%s\"" _tmp_dfa_name)
			contents = list( "version 17.2"
							"setwindow pcb"
							"placementedit"
							"dfa_spreadsheet"
							"QtSignal DFAMainWindow m_actionOpen triggered"
							line
							"QtSignal m_sprdSheetGrp m_spcValLineEdit editingFinished 0.25:0.25:0.25:0.25"
							"QtSignal DFAMainDialog m_okBtn clicked"
							"QtSignal MainCanvas DFAMainDialog closed"
							"placementedit")
		else
			sprintf( line "dfa open \"%s\"" _tmp_dfa_name)
			contents = list( "version 16.6"
							"setwindow pcb"
							"dfa_spreadsheet"
							"setwindow dfa.dialog"
							"dfa read_from_design"
							line
							"dfa attach_to_design"
							"dfa okay"
							"setwindow pcb")
		)
		
		contents
	)
)

procedure( import_dfa_table_Derek06062019( csv_filename table_name)
	prog( ( line contents out_port)
		unless( stringp( csv_filename) println( "ArgErr: import_dfa_table() - csv_filename is not a string") return( nil))
		unless( symbolp( table_name) println( "ArgErr: import_dfa_table() - table_name is not a symbol") return( nil))
		
		;;; read dfa file
		contents = read_dfa_table_Derek06062019( csv_filename table_name)
		write_file_Derek06062019( _tmp_dfa_name contents)
		
		;;; write script file
		contents = get_dfa_script_contents_Derek06062019()
		write_file_Derek06062019( _tmp_scr_name contents)
		
		;;; execute script to run dfa
		if( and( isFile( _tmp_dfa_name) isFile( _tmp_scr_addr)) then
			replay_scr_Derek06062019( _tmp_scr_addr)
		else
			printf( "\tWarning: import_dfa_table() - Fail to create [%s] and [%s]\n" _tmp_dfa_name _tmp_scr_name)
		)
		
		return( t)
	)
)

procedure( get_row_by_table_value_Derek06062019( table val)
	prog( ( content row)
		unless( tablep( table) println( "ArgErr: get_row_by_table_value() - table is not a table") return( nil))
		unless( stringp( val) println( "ArgErr: get_row_by_table_value() - val is not a string") return( nil))
		;;
		
		rexCompile( "\\([0-9]+\\)")
		foreach( key table->?
			content = table[key]
			;;
			when( and( equal( val content) rexExecute( key))
				row = rexSubstitute( "\\1")
				row = atoi( row)
			)
		)
		
		return( row)
	)
)

procedure( get_ps_xml_content_Derek06062019( via_nm top_tp_nm bot_tp_nm)
	;;; get padstack selection content
	;;; result:
	;<probe_parm1_type>
    ;	<rev>1</rev>
    ;	<flags>1</flags>
    ;	<existingPadstack>SMT Testpad</existingPadstack>
    ;	<topReplacementPadstack>TP-C30TMP</topReplacementPadstack>
    ;	<botReplacementPadstack>TP-C30BMP</botReplacementPadstack>
	;</probe_parm1_type>
	prog( ( data_ls contents)
		data_ls = list( via_nm top_tp_nm bot_tp_nm)
		unless( forall( x data_ls stringp( x)) printf( "ArgErr: get_ps_xml_content() -  dataset contains non-string thing. %L\n" data_ls) return( nil))
		top_tp_nm = upperCase( top_tp_nm)
		bot_tp_nm = upperCase( bot_tp_nm)
		unless( or( member( upperCase( via_nm) _smt_thru) axlLoadPadstack( via_nm))
			printf( "ArgErr: get_ps_xml_content() - Fail to load via_nm[%s]\n" via_nm)
			return( nil)
		)
		unless( axlLoadPadstack( top_tp_nm) printf( "ArgErr: Fail to load top_tp_nm[%s]\n" top_tp_nm) return( nil))
		unless( axlLoadPadstack( bot_tp_nm) printf( "ArgErr: Fail to load bot_tp_nm[%s]\n" bot_tp_nm) return( nil))
		;;
		
		;;; start of the block
		sprintf( line "<probe_parm%d_type>" 1)
		contents = append1( contents line)
		
		sprintf( line "\t<rev>%d</rev>" 1)
		contents = append1( contents line)
		
		sprintf( line "\t<flags>%d</flags>" 1)
		contents = append1( contents line)
		
		;;; define exists via
		sprintf( line "\t<existingPadstack>%s</existingPadstack>" via_nm)
		contents = append1( contents line)
		
		;;; define top side testpoint
		sprintf( line "\t<topReplacementPadstack>%s</topReplacementPadstack>" top_tp_nm)
		contents = append1( contents line)
		
		;;; define bottom side testpoint
		sprintf( line "\t<botReplacementPadstack>%s</botReplacementPadstack>" bot_tp_nm)
		contents = append1( contents line)
		
		;;; end of block
		contents = append1( contents "</probe_parm1_type>\n")
		
		return( contents)
	)
)

procedure( convert_ps_table_to_xml_Derek06062019( table enable_col via_col tp_top_col tp_bot_col start_row)
	;;; convert padstack selection form to xml format
	prog( ( cell row via_nm top_tp_nm bot_tp_nm contents ps_line_ls)
		unless( tablep( table) println( "ArgErr: convert_ps_table_to_xml() - table is not a table") return( nil))
		unless( stringp( enable_col) println( "ArgErr: enable_col is not a string") return( nil))
		unless( stringp( via_col) println( "ArgErr: via_col is not a string") return( nil))
		unless( stringp( tp_top_col) println( "ArgErr: tp_top_col is not a string") return( nil))
		unless( stringp( tp_bot_col) println( "ArgErr: tp_bot_col is not a string") return( nil))
		unless( plusp( start_row) println( "ArgErr: start_row is not a non-zero positive number") return( nil))
		;;
		
		;;; initlize the row, the starting row is also the starting of the content
		row = start_row
		
		;;; iterate the content of the table
		sprintf( cell "%s%d" enable_col row)
		while( stringp( table[ cell])
			;;; get via type
			sprintf( cell "%s%d" via_col row)
			via_nm = table[ cell]
			
			;;; get top side testpoint
			sprintf( cell "%s%d" tp_top_col row)
			top_tp_nm = table[ cell]
			
			;;; get bottom side testpoint
			sprintf( cell "%s%d" tp_bot_col row)
			bot_tp_nm = table[ cell]
			
			;;; check and store
			contents = get_ps_xml_content_Derek06062019( via_nm top_tp_nm bot_tp_nm)
			when( dtpr( contents) (ps_line_ls = append( ps_line_ls contents)))
			
			;;; iterate to the next one until the value is nil
			sprintf( cell "%s%d" enable_col ++row)
		)
		
		return( ps_line_ls)
	)
)

procedure( get_pt_xml_content_Derek06062019( probe_type probe_spac figure)
	;;; get probe type data in xml format
	;;; result
	;<probe_parm2_type>
	;	<rev>1</rev>
	;	<flags>1</flags>
	;	<probeType>30</probeType>
	;	<probeSpacing>50.00 MIL</probeSpacing>
	;	<probeFigure>18</probeFigure>
	;</probe_parm2_type>
	prog( ( data_ls contents line g_figure_ls figure_num)
		data_ls = list( probe_type probe_spac figure)
		unless( forall( x data_ls stringp( x))
			printf( "ArgErr: get_pt_xml_content() - dataset contains non-string thing. %L\n" data_ls)
			return( nil)
		)
		probe_type = atoi( probe_type)
		probe_spac = atof( probe_spac)
		figure = upperCase( figure)
		
		;;
		g_figure_ls = mapcar( 'car _figure_num_ls)
		unless( member( figure g_figure_ls) printf( "ERROR: get_pt_xml_content() - No figure[%s] for probe type\n" figure) return( nil))
		unless( plusp( probe_type) printf( "ERROR: get_pt_xml_content() - non-positive number of probe type for Probe Types\n") return( nil))
		unless( plusp( probe_spac) printf( "ERROR: get_pt_xml_content() - non-positive number of probe spacing for Probe Types\n") return( nil))
		;;
		
		;;; start of the block
		sprintf( line "<probe_parm%d_type>" 2)
		contents = append1( contents line)
		
		sprintf( line "\t<rev>%d</rev>" 1)
		contents = append1( contents line)
		
		sprintf( line "\t<flags>%d</flags>" 1)
		contents = append1( contents line)
		
		;;; define exists via
		sprintf( line "\t<probeType>%d</probeType>" probe_type)
		contents = append1( contents line)
		
		;;; define top side testpoint
		sprintf( line "\t<probeSpacing>%.2f MIL</probeSpacing>" probe_spac)
		contents = append1( contents line)
		
		;;; define bottom side testpoint
		figure_num = cadar( setof( x _figure_num_ls equal( figure car( x))))
		sprintf( line "\t<probeFigure>%d</probeFigure>" figure_num)
		contents = append1( contents line)
		
		;;; end of block
		contents = append1( contents "</probe_parm2_type>\n")
		
		return( contents)
	)
)

procedure( convert_pt_table_to_xml_Derek06062019( table enable_col probe_type_col probe_spec_col figure_col start_row)
	;;; convert probe type form to xml
	prog( ( row cell probe_type probe_spac figure contents ps_line_ls)
		unless( tablep( table) println( "ArgErr: convert_pt_table_to_xml() - table is not a table") return( nil))
		unless( stringp( enable_col) println( "ArgErr: convert_pt_table_to_xml() - enable_col is not a string") return( nil))
		unless( stringp( probe_type_col) println( "ArgErr: convert_pt_table_to_xml() - probe_type_col is not a string") return( nil))
		unless( stringp( probe_spec_col) println( "ArgErr: convert_pt_table_to_xml() - probe_spec_col is not a string") return( nil))
		unless( stringp( figure_col) println( "ArgErr: convert_pt_table_to_xml() - figure_col is not a string") return( nil))
		;;
		
		;;; initlize the starting row, this starting row is also the starting of the content
		row = start_row
		
		;;; iterate the content of the table
		sprintf( cell "%s%d" enable_col row)
		while( stringp( table[ cell])
			;;; get via type
			sprintf( cell "%s%d" probe_type_col row)
			probe_type = table[ cell]
			
			;;; get top side testpoint
			sprintf( cell "%s%d" probe_spec_col row)
			probe_spac = table[ cell]
			
			;;; get bottom side testpoint
			sprintf( cell "%s%d" figure_col row)
			figure = table[ cell]
			
			;;; check and store
			contents = get_pt_xml_content_Derek06062019( probe_type probe_spac figure)
			when( dtpr( contents) (ps_line_ls = append( ps_line_ls contents)))
			
			;;; iterate to the next one until the value is nil
			sprintf( cell "%s%d" enable_col ++row)
		)
		
		return( ps_line_ls)
	)
)

procedure( append_xml_head_tail_Derek06062019( xml_line_ls)
	prog( ( version_xml headers contents tails result)
		unless( dtpr( xml_line_ls) println( "ArgErr: append_xml_head_tail() - xml_line_ls is not a dtpr") return( nil))
		unless( forall( x xml_line_ls stringp( x)) println( "ArgErr: append_xml_head_tail() - xml_line_ls contains non-string thing") return( nil))
		;;
		
		;;
		headers = list( "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>"
						"<CadenceAllegroParameter xmlns=\"\">"
						"\t<parameter_header>"
						sprintf( nil "\t\t<version>%s</version>" _allegro_pversion)
						"\t</parameter_header>")
		contents = mapcar( lambda( (x) strcat( "\t" x)) xml_line_ls)
		tails = list( "</CadenceAllegroParameter>")
		
		;;
		result = append( result headers)
		result = append( result contents)
		result = append( result tails)
		
		return( result)
	)
)

procedure( write_file_Derek06062019( filename contents)
	prog( ( out_port)
		unless( stringp( filename) println( "ArgErr: write_file() - filename is not a string") return( nil))
		unless( dtpr( contents) println( "ArgErr: write_file() - contents is not a dtpr") return( nil))
		unless( forall( x contents stringp( x))
			println( "ArgErr: write_file() - contents contain non-string thing")
			foreach( line contents println( line))
			return( nil)
		)
		;;
		
		when( isFile( filename) deleteFile( filename))
		
		out_port = outfile( filename "w")
		unless( outportp( out_port) println( "ERROR: write_file() - Fail to write file") return( nil))
		
		foreach( line contents fprintf( out_port "%s\n" line))
		
		close( out_port)
		
		return( t)
	)
)

procedure( set_testprep_Derek06062019( pad_size_cell rep_via_cell)
	prog( ( param val )
		unless( stringp( pad_size_cell) println( "ArgErr: set_testprep() - pad_size_cell is not a string") return( nil))
		unless( stringp( pad_size_cell) println( "ArgErr: set_testprep() - rep_via_cell is not a string") return( nil))
		;;
		
		param = axlGetParam( "testprep")
		
		;;; setup minPadSize
		val = table[ pad_size_cell]
		sprintf( err_msg "Warning: import_testprep() - Fail to get [minPadSize] value[%L](float)" val)
		val = correct_data_type_Derek06062019( val 'float err_msg)
		when( val (param->minPadSize = val))
		
		;;; setup replace via
		val = table[ rep_via_cell]
		sprintf( err_msg "Warning: import_testprep() - Fail to get [replaceVias] value[%L](float)" val)
		val = correct_data_type_Derek06062019( val 'onoff err_msg)
		when( val (param->replaceVias = val))
		
		axlSetParam( param)
		
		
		return( t)
	)
)

procedure( import_testprep_Derek06062019( table_filename)
	prog( ( table param val row key contents line_ls xml_line_ls err_msg
			enable_col value_col via_col tp_top_col tp_bot_col probe_type_col probe_spec_col figure_col pad_size_cell rep_via_cell start_row)
		unless( stringp( table_filename) println( "ArgErr: import_cm_default() - table_filename is not a string") return( nil))
		;;
		
		enable_col = "B"
		value_col = via_col = probe_type_col = "C"
		tp_top_col = probe_spec_col = "D"
		tp_bot_col = figure_col = "E"
		table = read_table_Derek06062019( table_filename 'testprep)
		
		
		;;;; setup testprep
		sprintf( pad_size_cell "%s%d" value_col 4)
		sprintf( rep_via_cell "%s%d" value_col 5)
		set_testprep_Derek06062019( pad_size_cell rep_via_cell)
		
		;;; setup padstack selection
		start_row = get_row_by_table_value_Derek06062019( table _title_testprep_padstack)
		when( plusp( start_row)
			;;; add 2 to skip the current lien and the next sub-header line
			start_row = start_row + 2
			
			line_ls = convert_ps_table_to_xml_Derek06062019( table enable_col via_col tp_top_col tp_bot_col start_row)
			xml_line_ls = append( xml_line_ls line_ls)
		)
		
		;;; setup probeType
		start_row = get_row_by_table_value_Derek06062019( table _title_testprep_probe)
		when( plusp( start_row)
			;;; add 2 to skip the current lien the next sub-header
			start_row = start_row + 2
			
			line_ls = convert_pt_table_to_xml_Derek06062019( table enable_col probe_type_col probe_spec_col figure_col start_row)
			xml_line_ls = append( xml_line_ls line_ls)
		)
		
		;;; add head and tail xml data
		xml_line_ls = append_xml_head_tail_Derek06062019( xml_line_ls)
		
		;;; save to file
		write_file_Derek06062019( _tmp_prm_name xml_line_ls)
		
		;;; import to the board
		when( isFile( _tmp_prm_name) axlImportXmlDBRecords( _tmp_prm_name))
		
		
		return( t)
	)
)

procedure( replay_scr_Derek06062019( file_addr)
	prog( ( cmd cmd_nm msg)
		unless( stringp( file_addr) println( "ArgErr: replay_scr() - file_addr is not a string") return( nil))
		unless( isFile( file_addr) println( "ArgErr: replay_scr() - script file is not found") return( nil))
		unless( index( file_addr "/") println( "ArgErr: replay_scr() - file_addr is not a address") return( nil))
		;;
		
		;;;; replay the exists script file
		sprintf( cmd "replay \"%s\"" file_addr)
		axlShell( cmd)
		
		return( t)
	)
)

procedure( get_dfa_drc_mode_on_script_Derek06062019( )
	prog( ( cmd contents out_port)
		unless( isFile( _tmp_scr_name) deleteFile( _tmp_scr_addr))
		
		if( (_allegro_version > 17.0) then
			contents = list( "setwindow pcb"
							"dfa_spreadsheet"
							"QtSignal m_drcmodGrp m_drcOnButton toggled on"
							"QtSignal DFAMainDialog m_okBtn clicked"
							"QtSignal MainCanvas DFAMainDialog closed"
							"generaledit")
		else
			contents = list( "setwindow pcb"
							"dfa_spreadsheet"
							"setwindow dfa.dialog"
							"dfa constraints on"
							"dfa okay"
							"setwindow pcb"
							"generaledit")
		)
		
		return( contents)
	)
)

procedure( import_sheets_Derek06062019()
	let( ( contents csv_filename table_filename)
		
		;;; Design_Param
		when( _setup_board_init_table[ _key_dp]
			println( "import_sheets() - Importing 'Design Parameter'")
			table_filename = _fnm_table_table[ _sht_nm_des]
			import_design_param_Derek06062019( table_filename)
		)
		
		;;; Textblock
		when( _setup_board_init_table[ _key_tb]
			println( "import_sheets() - Importing 'Textblock'")
			csv_filename = _fnm_csv_table[ _sht_nm_txt]
			import_textblock_Derek06062019( csv_filename)
		)
		
		;;; New_Obj
		when( _setup_board_init_table[ _key_no]
			println( "import_sheets() - Importing 'New Objective'")
			csv_filename = _fnm_csv_table[ _sht_nm_new]
			import_new_obj_Derek06062019( csv_filename)
		)
		
		;;; Analysis_Mode
		when( _setup_board_init_table[ _key_am]
			println( "import_sheets() - Importing 'Analysis Mode'")
			csv_filename = _fnm_csv_table[ _sht_nm_ana]
			import_analysis_mode_Derek06062019( csv_filename)
		)
		
		;;; CM_Default
		when( _setup_board_init_table[ _key_cd]
			println( "import_sheets() - Importing 'Cmgr Default'")
			csv_filename = _fnm_csv_table[ _sht_nm_cmd]
			import_cm_default_Derek06062019( csv_filename)
		)
		
		;;; DFA
		when( _setup_board_init_table[ _key_dt]
			contents = get_dfa_drc_mode_on_script_Derek06062019()
			write_file_Derek06062019( _tmp_scr_addr contents)
			replay_scr_Derek06062019( _tmp_scr_addr)
			
			if( _is_rec_dfa then
				;;; DFA_Rec
				println( "import_sheets() - Importing 'Recommend DFA Table'")
				csv_filename = _fnm_csv_table[ _sht_nm_dfr]
				table_name = 'DFA_Standard_Recommed
			else
				;;; DFA_Min
				println( "import_sheets() - Importing 'Minimum DFA Table'")
				csv_filename = _fnm_csv_table[ _sht_nm_dfm]
				table_name = 'DFA_Standard_Minimum
			)
			;;
			import_dfa_table_Derek06062019( csv_filename table_name)
		)
		
		;;; Testprep
		when( _setup_board_init_table[ _key_tp]
			println( "import_sheets() - Importing 'Testprep'")
			table_filename = _fnm_table_table[ _sht_nm_tst]
			import_testprep_Derek06062019( table_filename)
		)
	)
)

procedure( write_sheets_Derek06062019( board_init_xlsx_addr)
	prog( ( result )
		;;;; asking for setup board init xlsx
		unless( or( null( board_init_xlsx_addr) and( stringp( board_init_xlsx_addr) isFile( board_init_xlsx_addr)))
			printf( "ERROR: write_sheets() - Fail to get board_init_xlsx_addr [%s]\n" board_init_xlsx_addr)
			return( nil)
		)
		
		;;;; select which excel to use
		unless( stringp( board_init_xlsx_addr)
			result = axlUIYesNoCancel( "Do you want to use default board_init data? (Yes to use default data in T)" "Board Init Data Confirm" 'yes)
			caseq( result
				( 0
					board_init_xlsx_addr = axlDMFileBrowse( nil nil ?title "Please select a customized board_init xlsx file" ?optFilters "All xlsx files|*.xlsx|")
					unless( stringp( board_init_xlsx_addr) return( nil))
				)
				( 1
					board_init_xlsx_addr = _default_board_init_addr
				)
				( 2
					return( nil)
				)
			)
		)
		
		;;;; remove the exists csv and table files
		foreach( nm _fnm_csv_table when( isFile( _fnm_csv_table[ nm]) deleteFile( _fnm_csv_table[ nm])))
		foreach( nm _fnm_table_table when( isFile( _fnm_table_table[ nm]) deleteFile( _fnm_table_table[ nm])))
		
		;;;; extract sheets from target xlsx
		manipulate_xlsx_main_Derek06122018( ?xlsx_addr board_init_xlsx_addr ?global_sheets _sheet_name_ls)
		
		unless( and( forall( f _fnm_csv_table isFile( _fnm_csv_table[ f]))
					forall( f _fnm_table_table isFile( _fnm_table_table[ f])))
			println( "ERROR: write_sheets() - Fail to get certain files from Board_init.xlsx")
			return( nil)
		)
		
		return( t)
	)
)

procedure( setup_board_init_main_Derek06062019( @key (board_init_xlsx_addr nil))
	prog( ( contents form_id result)
		;;; the necessary data to trigger 'write sheet' function
		init_Derek06062019()
		
		;;;; before anything started, check the certain items
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		unless( isCallable( 'manipulate_xlsx_main_Derek06122018)
			println( "ERROR: Fail to call 'manipulate_xlsx' function. Please import it first")
			return( nil)
		)
		unless( isFile( _default_board_init_addr)
			printf( "ERROR: setup_board_init_main() - Fail to get [%s]. Please check the connection of T disk or the target file is missing")
			return( nil)
		)
		unless( equal( "MILS" _allegro_unit) println( "ERROR: setup_board_init_main() - Support 'MILS' only. Process halt") return( nil))
		
		;;; get all the sheet file by calling xlsx_manipulate
		result = write_sheets_Derek06062019( board_init_xlsx_addr)
		unless( result return( nil))
		
		;;; to initlize the global value of the program
		init_Derek06062019()
		
		;;;; create form
		when( and( forall( f _fnm_csv_table isFile( _fnm_csv_table[f])) forall( f _fnm_table_table isFile( _fnm_table_table[f])))
			write_form_Derek06062019()
			form_id = axlFormCreate( _form_handle _form_filename '("east" "outer") 'form_action_Derek06062019 nil)
			set_form_Derek06062019( form_id)
			axlFormDisplay( form_id)
		)
		
		;;; import data to board
		when( _to_run
			import_sheets_Derek06062019()
			;;
			
			axlUIConfirm( "This board has been initlized. Please check this out")
			println( "This board has been initlized. Please check this out")
		)
		
		;;; delete csv file and table
		foreach( nm _fnm_csv_table when( isFile( _fnm_csv_table[ nm]) deleteFile( _fnm_csv_table[ nm])))
		foreach( nm _fnm_table_table when( isFile( _fnm_table_table[ nm]) deleteFile( _fnm_table_table[ nm])))
		when( isFile( _tmp_prm_name) deleteFile( _tmp_prm_name))
		when( isFile( _tmp_dfa_name) deleteFile( _tmp_dfa_name))
		when( isFile( _tmp_scr_name) deleteFile( _tmp_scr_name))
		when( isFile( _tmp_tcf_name) deleteFile( _tmp_tcf_name))
		when( isFile( _form_filename) deleteFile( _form_filename))
		
		;;;
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup
; (load "manipulate_xlsx_v3.ile")
(axlCmdRegister "setup_board_init" 'setup_board_init_main_Derek06062019)
; (setup_board_init_main_Derek06062019)
; skill (encrypt "c:/skill/setup_board_init_v1.il" "c:/skill/setup_board_init_v1.ile")
; (load "setup_board_init_v1.ile")
; (load "setup_board_init_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup