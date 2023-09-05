;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 8/14/2020 - _Derek08142020
; introduction: collect the check program into one place
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek08142020()
	;;;;; ------------------------------------------------------------------------------------------------
	setq( _group_placement 'PLACEMENT)
	setq( _item_emn_footprint_mapping 'EMN_Footprint_Mapping)
	setq( _item_check_fiducial 'Check_Fiducial)
	
	;;;;; ------------------------------------------------------------------------------------------------
	setq( _group_report 'REPORT)
	setq( _item_check_report 'Check_Report)
	
	;;;;; ------------------------------------------------------------------------------------------------
	setq( _group_general 'GENERAL)
	setq( _item_segment_over_void 'Segment_Over_Void)
	setq( _item_purge_objective 'Purge_Objective)
	setq( _item_thermal_relief 'Thermal_Relief)
	setq( _item_length_match_by_cline 'Length_Match_By_Cline)
	
	;;;;; ------------------------------------------------------------------------------------------------
	setq( _group_via 'PADSTACK)
	setq( _item_drill_hole 'Drill_Hole)
	setq( _item_laser_gnd_via 'Laser_GND_Via)
	setq( _item_hs_via 'High_Speed_Via)
	setq( _item_check_drill_chart 'Check_Drill_Chart)
	
	;;;;; ------------------------------------------------------------------------------------------------
	setq( _group_testpoint 'TESTPOINT)
	setq( _item_testpoint 'Testpoint)
	setq( _item_stub_tp_on_hs 'Stub_TP_on_HS)
	
	;;;;; ------------------------------------------------------------------------------------------------
	setq( _group_silkscreen 'SILKSCREEN)
	setq( _item_silkscreen_overlap 'Silkscreen_Overlap)
	
	setq( _form_key_pack_up 'pack_up)
	setq( _form_key_close 'close)
	
	
	;;;;; form
	setq( _form_term_divider "-")
	setq( _form_check_term strcat( _form_term_divider "check"))
	setq( _form_view_term strcat( _form_term_divider "view"))
	setq( _form_log_term strcat( _form_term_divider "log"))
	setq( _form_name "check_item_panel.form")
	
	;;;;;
	setq( _group_item_ls list( _group_placement _group_general _group_via _group_testpoint _group_silkscreen _group_report))
	setq( _group_item_table makeTable( 'group_item nil))
	setq( _logname_table makeTable( 'logname nil))
	setq( _command_table makeTable( 'command nil))
	setq( _valid_cmd_table makeTable( 'valid_cmd nil))
	
	;;;;
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _check_item_panel_dir "check_item_panel-%s" _date_time)
)

procedure( get_form_item_button_key_Derek08142020( item term)
	; item = 'testpoint
	prog( ( button_key)
		sprintf( button_key "%s%s%s" item _form_term_divider term)
		
		return( button_key)
	)
)

procedure( get_item_by_button_key_Derek08142020( button_key)
	; button_key =  "testpoint-check"
	prog( ( item)
		item = car( parseString( button_key _form_term_divider))
		item = stringToSymbol( item)
		
		return( item)
	)
)

procedure( init_group_item_table_Derek08142020()
	prog( ()
		_group_item_table[ _group_placement] = list( _item_emn_footprint_mapping _item_check_fiducial)
		_group_item_table[ _group_report] = list( _item_check_report)
		_group_item_table[ _group_general] = list( _item_length_match_by_cline _item_purge_objective _item_thermal_relief _item_segment_over_void)
		_group_item_table[ _group_via] = list( _item_drill_hole _item_laser_gnd_via _item_hs_via _item_check_drill_chart)
		_group_item_table[ _group_testpoint] = list( _item_testpoint _item_stub_tp_on_hs)
		_group_item_table[ _group_silkscreen] = list( _item_silkscreen_overlap)
	)
)

procedure( set_logname_table_Derek08142020( item)
	let( ( logname_ls)
		cond(
			( item == _item_emn_footprint_mapping
				logname_ls = list( _check_emn_footprint_mapping_logname)
			)
			( item == _item_check_fiducial
				logname_ls = list( _fiducial_logname)
			)
			( item == _item_purge_objective
				logname_ls = list( _purge_objectives_logname)
			)
			( item == _item_check_report
				logname_ls = list( _check_db_rptname 
								_check_draw_rptname 
								_check_dangling_rptname 
								_check_netloop_rptname
								_check_symbol_library_path_rptname)
			)
			( item == _item_segment_over_void
				logname_ls = list( _seg_over_void_logname)
			)
			( item == _item_thermal_relief
				logname_ls = list( _check_symbol_thermal_relief_logname)
			)
			( item == _item_length_match_by_cline
				logname_ls = list( _check_length_match_by_cline_logname)
			)
			( item == _item_drill_hole
				logname_ls = list( _check_drill_hole_logname)
			)
			( item == _item_laser_gnd_via
				logname_ls = list( _check_laser_gnd_via_logname)
			)
			( item == _item_hs_via
				logname_ls = list( _check_hs_via_logname)
			)
			( item == _item_check_drill_chart
				logname_ls = list( _check_drill_chart_logname)
			)
			( item == _item_testpoint
				logname_ls = list( _check_testpoint_logname)
			)
			( item == _item_stub_tp_on_hs
				logname_ls = list( _check_stub_testpoint_logname)
			)
			( item == _item_silkscreen_overlap
				logname_ls = list( _check_silkscreen_over_logname)
			)
			( t
				printf( "ERROR: set_logname_table_Derek08142020() - Yet to define checking item: %L\n" item)
			)
		)
		
		when( dtpr( logname_ls)
			_logname_table[ item] = logname_ls
		)
	)
)

procedure( init_command_table_Derek08142020()
	let( ()
		_command_table[ _item_emn_footprint_mapping] = 'emn_map_main_Derek05262017
		_command_table[ _item_check_fiducial] = 'check_fiducial_main_derek06012020
		_command_table[ _item_purge_objective] = 'purge_objectives_main_Derek06022020
		_command_table[ _item_check_report] = 'check_report_main_Derek06032020
		_command_table[ _item_segment_over_void] = 'segments_over_void_main_Derek10122017
		_command_table[ _item_thermal_relief] = 'check_thermal_relief_main_Derek06052020
		_command_table[ _item_length_match_by_cline] = 'length_match_by_cline_main_Derek07072020
		_command_table[ _item_drill_hole] = 'checkDrillHoleMain_Derek04062020
		_command_table[ _item_laser_gnd_via] = 'check_laser_gnd_via_main_Derek10312017
		_command_table[ _item_hs_via] = 'check_hs_via_main_Derek05102019
		_command_table[ _item_check_drill_chart] = 'check_drill_chart_main_Derek06092020
		_command_table[ _item_testpoint] = 'testpoint_check_main_Derek02122019
		_command_table[ _item_stub_tp_on_hs] = 'check_stub_testpoint_main_Derek20190826
		_command_table[ _item_silkscreen_overlap] = 'silkscreen_over_check_main_Derek08042020
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_form_entry_Derek08142020( out_port item last_y @optional (content_x 3) (button_width 8) (button_height 1) (text_size 36))
	let( ( key check_item_key view_item_key log_item_key)
		key = get_key_title_Derek08142020( item)
		fprintf( out_port "TEXT \"%s\" \n" key)
		fprintf( out_port "FLOC %d %d\n" content_x last_y)
		fprintf( out_port "ENDTEXT\n")
		
		content_x += 18
		check_item_key = get_form_item_button_key_Derek08142020( item _form_check_term)
		fprintf( out_port "FIELD %s\n" check_item_key)
		fprintf( out_port "FLOC %d %d\n" content_x last_y)
		fprintf( out_port "MENUBUTTON \"CHECK\" %d %d\n" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		content_x += 10
		view_item_key = get_form_item_button_key_Derek08142020( item _form_view_term)
		fprintf( out_port "FIELD %s\n" view_item_key)
		fprintf( out_port "FLOC %d %d\n" content_x last_y)
		fprintf( out_port "MENUBUTTON \"VIEW\" %d %d\n" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		content_x += 10
		log_item_key = get_form_item_button_key_Derek08142020( item _form_log_term)
		fprintf( out_port "FIELD %s\n" log_item_key)
		fprintf( out_port "FLOC %d %d\n" content_x last_y)
		fprintf( out_port "STRFILLIN %d %d\n" text_size text_size * 2)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( get_key_title_Derek08142020( key)
	; key = 'group_report_and_drc
	prog( ( key_iter)
		key = symbolToString( key)
		;;;; remove first section: key
		key_iter = parseString( key "_")
		key = buildString( key_iter " ")
		
		return( key)
	)
)

procedure( write_form_group_content_Derek08142020( out_port group last_y group_x group_width row_height)
	prog( ( group_start_y )
		group_start_y = last_y
		
		foreach( item _group_item_table[ group]
			last_y += row_height
			write_form_entry_Derek08142020( out_port item last_y)
		)
		
		last_y = last_y + row_height + 1
		group = get_key_title_Derek08142020( group)
		fprintf( out_port "GROUP \"%s\"\n" group)
		fprintf( out_port "FLOC %d %d\n" group_x group_start_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width (last_y - group_start_y))
		fprintf( out_port "ENDGROUP\n")
		
		return( last_y)
	)
)

procedure( create_form_Derek08142020()
	prog( ( out_port group_width group_x row_height start_y last_y )
		out_port = outfile( _form_name "w")
		unless( outportp( out_port) println( "ERROR: create_form() - Fail to write form") return( nil))
		;;
		
		group_width = 80
		group_x = 1
		row_height = 2
		start_y = 1
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" add1( group_width) 100)
		fprintf( out_port "HEADER \"Gerber Package Selector\"\n")
		fprintf( out_port "TILE\n")
		
		;;;;;
		
		last_y = start_y
		foreach( group _group_item_ls
			last_y = write_form_group_content_Derek08142020( out_port group last_y group_x group_width row_height)
		)
		
		;;;;;
		button_width = 20
		button_height = 2
		
		last_y += row_height
		fprintf( out_port "FIELD %s\n" _form_key_pack_up)
		fprintf( out_port "FLOC %d %d\n" group_x last_y)
		fprintf( out_port "MENUBUTTON \"Pack Up\" %d %d\n" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		position_x = group_x + button_width + 2
		fprintf( out_port "FIELD %s\n" _form_key_close)
		fprintf( out_port "FLOC %d %d\n" position_x last_y)
		fprintf( out_port "MENUBUTTON \"Close\" %d %d\n" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( init_form_Derek08142020( out_form)
	let( ( item_key)
		;;;; disable the text fillin on the right side
		foreach( group _group_item_ls
			foreach( item _group_item_table[ group]
				item_key = get_form_item_button_key_Derek08142020( item _form_log_term)
				axlFormSetFieldEditable( out_form item_key nil)
			)
		)
		
		;;;; set default button
		axlFormDefaultButton( out_form _form_key_pack_up)
		
		;;;; message
		item_key = get_form_item_button_key_Derek08142020( _item_check_report _form_log_term)
		axlFormSetField( out_form item_key "Cautious: Analysis Mode will be reseted")
	)
)

procedure( get_form_log_content_Derek08142020( logname)
	prog( ( content)
		if( index( logname "/")
			content = cadr( parseString( logname "/"))
			content = logname
		)
		
		;;;; remove .log
		content = car( parseString( content "."))
		
		return( content)
	)
)

procedure( act_form_Derek08142020( out_form)
	let( ( current_field item)
		current_field = out_form->curField
		cond(
			( current_field == symbolToString( _form_key_pack_up)
				copy_log_to_dir_Derek08142020( _check_item_panel_dir)
			)
			( current_field == symbolToString( _form_key_close)
				axlFormClose( out_form)
				delete_empty_dir_Derek08142020( _check_item_panel_dir)
			)
			( index( current_field _form_check_term)
				item = get_item_by_button_key_Derek08142020( current_field)
				run_form_item_command_Derek08142020( out_form item)
			)
			( index( current_field _form_view_term)
				item = get_item_by_button_key_Derek08142020( current_field)
				view_form_item_log_Derek08142020( item)
			)
		)
	)
)

procedure( remove_file_from_dir_Derek08142020( dirname)
	prog( ()
		unless( isDir( dirname)
			printf( "ERROR: remove_file_from_dir() - Not found directory[%L]\n" dirname)
			return( nil)
		)
		;;
		
		printf( "INFO: remove_file_from_dir() - Removing files in directory[%L]\n" dirname)
		foreach( filename getDirFiles( dirname)
			sprintf( file_addr "%s/%s" dirname filename)
			when( isFile( file_addr)
				printf( "INFO: remove_file_from_dir() - Removing file: %s\n" file_addr)
				deleteFile( file_addr)
			)
		)
		
		return( t)
	)
)

procedure( prompt_dir_Derek08142020( dirname)
	let( ( cmd)
		sprintf( cmd "start %s" dirname)
		shell( cmd)
	)
)

procedure( copy_log_to_dir_Derek08142020( dirname)
	; logname = "log/log/check_emn_footprint_mapping-2020Aug17-152418.log"
	prog( (file_des file_addr)
		unless( dtpr( _logname_table->?)
			printf( "INFO: copy_log_to_dir() - None of item has been checked\n")
			return( nil)
		)
		
		if( isDir( dirname)
			remove_file_from_dir_Derek08142020( dirname)
			createDir( dirname)
		)
		
		foreach( item _logname_table->?
			foreach( logname _logname_table[ item]
				file_des = rindex( logname "/")
				file_addr = strcat( dirname file_des)
				axlOSFileCopy( logname file_addr nil)
			)
		)
		
		prompt_dir_Derek08142020( dirname)
		
		return( t)
	)
)

procedure( view_form_item_log_Derek08142020( item)
	prog( ( logname_ls)
		logname_ls = _logname_table[ item]
		unless( dtpr( logname_ls)
			printf( "WARNING: view_form_item_log() - Please check item[%s] before using this function\n" item)
			return( nil)
		)
		
		foreach( logname logname_ls
			axlUIViewFileCreate( logname logname nil)
		)
		
		return( t)
	)
)

procedure( run_form_item_command_Derek08142020( out_form item)
	prog( ( command logname content log_item_key)
		command = _valid_cmd_table[ item]
		unless( command
			printf( "WARNING: run_form_item_command() - Please load command[%s] before using this function\n" item)
		)
		
		apply( command nil)
		
		set_logname_table_Derek08142020( item)
		logname = car( _logname_table[ item])
		
		content = get_form_log_content_Derek08142020( logname)
		log_item_key = get_form_item_button_key_Derek08142020( item _form_log_term)
		axlFormSetField( out_form log_item_key content)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( check_command_Derek08142020()
	let( ( cmd)
		foreach( item _command_table
			cmd = _command_table[ item]
			if( isCallable( cmd) then
				printf( "INFO: check_command() - Successfully get commad: %s\n" item)
				_valid_cmd_table[ item] = cmd
			else
				printf( "WARNING: check_command() - Unbound command: %s\n" item)
			)
		)
	)
)

procedure( delete_empty_dir_Derek08142020( dirname)
	let( ()
		unless( isDir( dirname) return( nil))
		;;
		
		unless( dtpr( getDirFiles( dirname))
			printf( "INFO: delete_empty_dir() - Remove empty dir: %L\n" dirname)
			deleteDir( dirname)
		)
	)
)

procedure( check_item_panel_main_Derek08142020()
	prog( ( result)
		unless( axlOKToProceed() (println "Please done current function to use this program") (return nil))
		;;
		
		init_Derek08142020()
		init_group_item_table_Derek08142020()
		
		;;;;; check all the command is callable
		init_command_table_Derek08142020()
		check_command_Derek08142020()
		unless( dtpr( _valid_cmd_table->?)
			printf( "INFO: check_item_panel_main() - None of command is loaded. Please check this out")
			delete_empty_dir_Derek08142020( _check_item_panel_dir)
			return( nil)
		)
		
		;;;;; display form
		result = create_form_Derek08142020()
		unless( create_form_Derek08142020() return( nil))
		out_form = axlFormCreate( gensym() _form_name '("east" "outer") 'act_form_Derek08142020 t)
		init_form_Derek08142020( out_form)
		axlFormDisplay( out_form)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_item_panel" 'check_item_panel_main_Derek08142020)
; (check_item_panel_main_Derek08142020)
; skill encrypt( "C:/skill/check_item_panel_v1.il" "C:/skill/check_item_panel_v1.ile")
; (load "check_item_panel_v1.ile")
; (load "check_item_panel_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup