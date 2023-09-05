;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
;Developer: Derek Hsu
;Starting Date: 09/09/2019 - _Derel09092019
;Purpose: create via optimization by board file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( get_form_popup_option_string( option_ls)
	prog( ( content form_popup_string)
		foreach( option option_ls
			sprintf( content "\"%s\" \"%s\" " option option)
			
			if( stringp( form_popup_string)
				form_popup_string = strcat( form_popup_string "," content)
				form_popup_string = content
			)
		)
		
		when( stringp( form_popup_string)
			form_popup_string = strcat( form_popup_string ".")
		)
		
		return( form_popup_string)
	)
)

procedure( init()
	setq( _etch_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _etch_total axlGetParam( "paramLayerGroup:ETCH")->nChildren)
	setq( _top "TOP")
	setq( _bottom  "BOTTOM")
	setq( _soldermask_top "SOLDERMASK_TOP")
	setq( _soldermask_bottom "SOLDERMASK_BOTTOM")
	setq( _default_internal "DEFAULT INTERNAL")
	setq( _all "ALL")
	
	setq( _layer_thru 0)
	setq( _layer_top_to_1 1)
	setq( _layer_top_to_2 2)
	setq( _layer_bot_to_1 -1)
	setq( _layer_bot_to_2 -2)
	setq( _laser_layer_ls list( _layer_top_to_1 _layer_top_to_2 _layer_bot_to_1 _layer_bot_to_2))
	
	;;;;
	setq( _form_filename "create_via_optimization.form")
	setq( _form_handle 'create_via_optimization)
	setq( _form_key_prog_name "project_name")
	setq( _form_key_grid_padstack "padstack")
	setq( _form_key_grid_structure "structure")
	setq( _form_key_grid_via_opt "via_opt")
	setq( _form_key_apply "apply")
	setq( _form_key_create "create")
	setq( _form_key_close "close")
	setq( _form_key_popup_option "popup_options")
	setq( _form_key_popup_shape "popup_shapes")
	setq( _form_key_popup_via_type "popup_via_types")
	
	setq( _form_popup_option_ls list( "1" "2" "3"))
	setq( _form_max_row length( _form_popup_option_ls))
	setq( _form_popup_option_string get_form_popup_option_string( _form_popup_option_ls))
	
	setq( _oblong "OBLONG")
	setq( _rectangle "RECTANGLE")
	setq( _form_popup_shape_ls list( _oblong _rectangle))
	setq( _form_popup_shape_string get_form_popup_option_string( _form_popup_shape_ls))
	
	setq( _through "THROUGH")
	setq( _laser "LASER")
	setq( _form_popup_via_type list( _through _laser))
	setq( _form_popup_via_type_string get_form_popup_option_string( _form_popup_via_type))
	
	setq( _form_grid_col_item 0)
	setq( _form_grid_col_name 1)
	setq( _form_grid_col_type 2)
	setq( _form_grid_col_fh 3)
	setq( _form_grid_col_pad 4)
	setq( _form_grid_col_anti 5)
	setq( _form_grid_col_sm 6)
	setq( _form_grid_col_rt_kp_out 2)
	setq( _form_grid_col_svia_p 3)
	setq( _form_grid_col_gvia_px 4)
	setq( _form_grid_col_gvia_py 5)
	setq( _form_grid_col_padstack 2)
	setq( _form_grid_col_structure 3)
	setq( _form_grid_col_ohm 4)
	setq( _form_grid_col_board 5)
	
	setq( _unit "mil")
	setq( _project_name "flex")
	
	;;;; via10_p20_anti40
	setq( _padstack_thru_default "via?_p?_anti?")
	setq( _padstack_thru_name_form "via%s_p%s_anti%s%s")
	
	;;;; lv10c22_1-2_anti32_sm16
	setq( _padstack_lsr_default "lv?c?_*-*_anti?")
	setq( _padstack_lsr_name_form "lv%sc%s_*-*_anti%s%s")
	setq( _padstack_lsr_finish_form "lv%sc%s_%%d-%%d_anti%s%s")
	
	;;;; oblong_10_20_30
	setq( _structure_default "?_?_?_?")
	setq( _structure_name_form "%s_%s_%s_%s")
	
	;;;; v10_tb_mb_85dp
	setq( _via_opt_thru_default "v?_?_?dp")
	setq( _via_opt_thru_name_form "v%s_%s_%sdp")
	
	;;;; lv1-2_tb_mb_85dp
	setq( _via_opt_lsr_default "lv*-*_?_?dp")
	setq( _via_opt_lsr_name_form "lv*-*_%s_%sdp")
	setq( _via_opt_lsr_finish_form "lv%%d-%%d_%s_%sdp")
	
	setq( _sm "_sm")
	
	;;;;;
	setq( _month_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _today_time "%.4d%.2d%.2d-%.2d%.2d%.2d" _year listnindex( _month_ls _month) _date _hour _minute _second)
	sprintf( _via_opt_dir "create_via_optimization-%s" _today_time)
	setq( _via_opt_to_path strcat( _allegro_path _via_opt_dir "/"))
	
	;;;;;
	setq( _allegro_dir getWorkingDir())
	setq( _allegro_path strcat( _allegro_dir "/"))
	setq( _allegro_addr axlGetDrawingName())
	
	setq( _import_xsection_techfile_scr strcat( _allegro_path "import_xsection_techfile.scr"))
	setq( _xsection_techfile "xsection.tcf")
	
	setq( _via_opt_dra_name "via_opt_template.dra")
	setq( _via_opt_dra_from_path "T:/Layout/SOP/skill_tool_by_Derek/2-7_Create_via_optimization/")
	setq( _via_opt_dra_from_addr strcat( _via_opt_dra_from_path _via_opt_dra_name))
	setq( _via_opt_dra_to_addr strcat( _allegro_path _via_opt_dra_name))
	
	setq( _prop_via_route list( list( "ROUTES_ALLOWED" t) list( "VIAS_ALLOWED" t)))
	setq( _prop_nodrc5 list( "REGION_NAME" "NODRC_5"))
	
	setq( _drill_figure_ls (list (list 3.0 "ie") (list 4.0 "ar") (list 5.0 "im") (list 6.0 "hl") (list 7.0 "hb") (list 8.0 "aq") (list 8.5 "hm")
							(list 9.0 "gh") (list 10.0 "3") (list 11.0 "gz") (list 12.0 "4") (list 12.5 "hj") (list 14.0 "5") (list 14.1 "fx")
							(list 14.2 "ib") (list 14.5 "fs") (list 14.6 "hy") (list 15.0 "fj") (list 15.3 "he") (list 15.4 "hx")
							(list 15.7 "gb") (list 15.8 "ij")))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( write_form()
	prog( ()
		out_port = outfile( _form_filename "w")
		unless( outportp( out_port) println( "ERROR: write_form()  - Fail to create form write port") return( nil))
		;;
		
		button_width = 8
		button_height = 2
		
		form_width = 70
		form_height = 100
		
		group_width = form_width - 2
		group_height = 12
		
		grid_width = group_width - 2
		grid_height = group_height - 2
		
		start_x = 1
		block_y = 1
		
		grid_x = start_x + 1
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" form_width form_height)
		fprintf( out_port "HEADER \"Create Via Optimization\"\n")
		fprintf( out_port "POPUP <%s> %s\n\n" _form_key_popup_option _form_popup_option_string)
		fprintf( out_port "POPUP <%s> %s\n\n" _form_key_popup_shape _form_popup_shape_string)
		fprintf( out_port "POPUP <%s> %s\n\n" _form_key_popup_via_type _form_popup_via_type_string)
		fprintf( out_port "TILE\n")
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		fprintf(out_port "TEXT \"%s\" \n" "Project Name:")
		fprintf(out_port "FLOC %d %d\n" start_x block_y)
		fprintf(out_port "ENDTEXT\n")
		
		block_x = start_x + 11
		string_length = 7
		
		fprintf(out_port "FIELD %s\n" _form_key_prog_name)
		fprintf(out_port "FLOC %d %d\n" block_x block_y)
		fprintf(out_port "STRFILLIN %d %d\n" string_length string_length)
		fprintf(out_port "ENDFIELD\n")
		
		block_x = block_x + string_length + 5
		
		fprintf(out_port "TEXT \"%s\" \n" "Unit: Mil")
		fprintf(out_port "FLOC %d %d\n" block_x block_y)
		fprintf(out_port "ENDTEXT\n")
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		group_y = block_y + 2
		block_y = group_y + 2
		
		fprintf( out_port "GRID %s\n" _form_key_grid_padstack)
		fprintf( out_port "FLOC %d %d\n" grid_x block_y)
		fprintf( out_port "FSIZE %d %d\n" grid_width grid_height)
		fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		fprintf( out_port "GHEAD TOP\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "GHEAD SIDE\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "ENDGRID\n\n")
		
		fprintf( out_port "GROUP \"%s\"\n" "Padstack")
		fprintf( out_port "FLOC %d %d\n" start_x group_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width group_height)
		fprintf( out_port "ENDGROUP\n\n")
		
		block_y = block_y + grid_height - 2
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		group_y = block_y + 2
		block_y = group_y + 2
		
		fprintf( out_port "GRID %s\n" _form_key_grid_structure)
		fprintf( out_port "FLOC %d %d\n" grid_x block_y)
		fprintf( out_port "FSIZE %d %d\n" grid_width grid_height)
		fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		fprintf( out_port "GHEAD TOP\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "GHEAD SIDE\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "ENDGRID\n\n")
		
		fprintf( out_port "GROUP \"%s\"\n" "Structure")
		fprintf( out_port "FLOC %d %d\n" start_x group_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width group_height)
		fprintf( out_port "ENDGROUP\n\n")
		
		block_y = block_y + grid_height - 2
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		group_y = block_y + 2
		block_y = group_y + 2
		
		fprintf( out_port "GRID %s\n" _form_key_grid_via_opt)
		fprintf( out_port "FLOC %d %d\n" grid_x block_y)
		fprintf( out_port "FSIZE %d %d\n" grid_width grid_height)
		fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		fprintf( out_port "GHEAD TOP\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "GHEAD SIDE\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "ENDGRID\n\n")
		
		fprintf( out_port "GROUP \"%s\"\n" "Via Optimization")
		fprintf( out_port "FLOC %d %d\n" start_x group_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width group_height)
		fprintf( out_port "ENDGROUP\n\n")
		
		block_y = block_y + grid_height - 2
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		button_x = start_x + 2
		block_y = block_y + 3
		
		fprintf( out_port "FIELD %s\n" _form_key_apply)
		fprintf( out_port "FLOC %d %d\n" button_x block_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "APPLY" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_x = button_x + button_width + 4
		
		fprintf( out_port "FIELD %s\n" _form_key_create)
		fprintf( out_port "FLOC %d %d\n" button_x block_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "Create Via Opt" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_x = button_x + button_width + 12
		
		fprintf( out_port "FIELD %s\n" _form_key_close)
		fprintf( out_port "FLOC %d %d\n" button_x block_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "Close" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( set_form_grid_col( out_form field field_type head_text col_width @optional popup)
	prog( ( options )
		options = make_formGridCol()
		options->colWidth = col_width
		options->headText = head_text
		
		caseq( field_type
			( 'TEXT
				options->fieldType = field_type
				options->fieldLength = col_width
			)
			( 'STRING
				options->fieldType = field_type
				options->fieldLength = col_width
			)
			( 'REAL
				options->fieldType = field_type
				options->decimals = 2
				options->min = 0.0
				options->max = 200.0
			)
			( 'LONG
				options->fieldType = field_type
				options->min = 0.0
				options->max = 200.0
			)
			( 'ENUMSET
				options->fieldType = field_type
				options->popup = popup
			)
			( t
				printf( "ERROR: set_form_grid_col() - Yet to define field typr[%s]\n" field_type)
			)
		)
		
		axlFormGridInsertCol( out_form field options)
	)
)

procedure( set_form_grid_cell( out_form field row col value @optional (is_popup nil))
	prog( ( cell)
		cell = axlFormGridNewCell()
		cell->row = row
		cell->col = col
		if( is_popup
			cell->popup = value
			cell->value = value
		)
		cell->noEdit = nil
		
		axlFormSetField( out_form field cell)
		
		axlFormGridUpdate( out_form field)
		
		
		return( t)
	)
)

procedure( set_form_grid_padstack( out_form)
	let( ()
		set_form_grid_col( out_form _form_key_grid_padstack 'TEXT "Name" 12)
		set_form_grid_col( out_form _form_key_grid_padstack 'ENUMSET "Type" 4 _form_key_popup_via_type)
		set_form_grid_col( out_form _form_key_grid_padstack 'REAL "FH" 4)
		set_form_grid_col( out_form _form_key_grid_padstack 'REAL "Pad" 4)
		set_form_grid_col( out_form _form_key_grid_padstack 'REAL "Anti-Pad" 4)
		set_form_grid_col( out_form _form_key_grid_padstack 'REAL "Soldermask" 4)
		
		axlFormGridInsertRows( out_form _form_key_grid_padstack 1 _form_max_row)
		
		set_form_grid_cell( out_form _form_key_grid_padstack 1 _form_grid_col_item 1)
		set_form_grid_cell( out_form _form_key_grid_padstack 2 _form_grid_col_item 2)
		set_form_grid_cell( out_form _form_key_grid_padstack 3 _form_grid_col_item 3)
		
		axlFormGridEvents( out_form _form_key_grid_padstack 'change)
		
		axlFormGridUpdate( out_form _form_key_grid_padstack)
	)
)

procedure( set_form_grid_structure( out_form)
	let( ()
		set_form_grid_col( out_form _form_key_grid_structure 'TEXT "Name" 12)
		set_form_grid_col( out_form _form_key_grid_structure 'ENUMSET "Rt Kp Out" 4 _form_key_popup_shape)
		set_form_grid_col( out_form _form_key_grid_structure 'REAL "Svia-Pitch" 4)
		set_form_grid_col( out_form _form_key_grid_structure 'REAL "Gvia-Pitch-X" 4)
		set_form_grid_col( out_form _form_key_grid_structure 'REAL "Gvia-Pitch-Y" 4)
		
		axlFormGridInsertRows( out_form _form_key_grid_structure 1 _form_max_row)
		
		set_form_grid_cell( out_form _form_key_grid_structure 1 _form_grid_col_item 1)
		set_form_grid_cell( out_form _form_key_grid_structure 2 _form_grid_col_item 2)
		set_form_grid_cell( out_form _form_key_grid_structure 3 _form_grid_col_item 3)
		
		axlFormGridEvents( out_form _form_key_grid_structure 'change)
		
		axlFormGridUpdate( out_form _form_key_grid_structure)
	)
)

procedure( set_form_grid_via_opt( out_form)
	let( ()
		set_form_grid_col( out_form _form_key_grid_via_opt 'TEXT "Name" 12)
		set_form_grid_col( out_form _form_key_grid_via_opt 'ENUMSET "Padstack" 4 _form_key_popup_option)
		set_form_grid_col( out_form _form_key_grid_via_opt 'ENUMSET "Structure" 4 _form_key_popup_option)
		set_form_grid_col( out_form _form_key_grid_via_opt 'REAL "Ohm" 4)
		set_form_grid_col( out_form _form_key_grid_via_opt 'STRING "Board" 4)
		
		axlFormGridInsertRows( out_form _form_key_grid_via_opt 1 _form_max_row)
		
		set_form_grid_cell( out_form _form_key_grid_via_opt 1 _form_grid_col_item 1)
		set_form_grid_cell( out_form _form_key_grid_via_opt 2 _form_grid_col_item 2)
		set_form_grid_cell( out_form _form_key_grid_via_opt 3 _form_grid_col_item 3)
		
		axlFormGridEvents( out_form _form_key_grid_via_opt 'change)
		
		axlFormGridUpdate( out_form _form_key_grid_via_opt)
	)
)

procedure( convert_float_string( number)
	prog( ( natural reminder result)
		natural = int( number)
		reminder = number - natural
		
		if( zerop( reminder) then
			sprintf( result "%d" natural)
		else
			if( eqv( (int( number * 10) * 10) int( number * 100))
				sprintf( result "%dd%d" natural int( reminder * 10))
				sprintf( result "%dd%d" natural int( reminder * 100))
			)
		)
		
		
		return( result)
	)
)

procedure( get_form_grid_cell_value( out_form field row col @optional (to_string nil))
	prog( ( cell grid_cell value)
		cell = axlFormGridNewCell()
		cell->row = row
		cell->col = col
		grid_cell = axlFormGridGetCell( out_form field cell)
		value = grid_cell->value
		
		when( to_string
			cond(
				( integerp( value)
					sprintf( value "%d" value)
				)
				( floatp( value)
					value = convert_float_string( value)
				)
				( stringp( value))
				( t
					value = ""
				)
			)
		)
		
		return( value)
	)
)

procedure( get_form_padstack_name( out_form row @optional (is_finish nil))
	prog( ( type fh pad anti sm result)
		type = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_type t)
		fh = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_fh t)
		pad = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_pad t)
		anti = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_anti t)
		sm = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_sm t)
		sm = if( member( sm list( "" "0")) "" strcat( _sm sm))
		
		if( or( equal( "" type) equal( "" fh) equal( "" pad) equal( "" anti)) then
			result = if( equal( _laser type) _padstack_lsr_default _padstack_thru_default)
		else
			if( equal( _laser type) then
				if( is_finish
					sprintf( result _padstack_lsr_finish_form fh pad anti sm)
					sprintf( result _padstack_lsr_name_form fh pad anti sm)
				)
			else
				sprintf( result _padstack_thru_name_form fh pad anti sm)
			)
		)
		
		
		return( result)
	)
)

procedure( get_form_structure_name( out_form row)
	prog( ( shape svia_pitch gvia_pitch_x gvia_pitch_y)
		shape = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_rt_kp_out t)
		svia_pitch = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_svia_p t)
		gvia_pitch_x = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_gvia_px t)
		gvia_pitch_y = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_gvia_py t)
		
		if( or( equal( "" shape) equal( "" svia_pitch) equal( "" gvia_pitch_x) equal( "" gvia_pitch_y)) then
			result = _structure_default
		else
			sprintf( result _structure_name_form shape svia_pitch gvia_pitch_x gvia_pitch_y)
		)
		
		
		return( result)
	)
)

procedure( get_form_via_opt_name( out_form row @optional ( is_finish nil))
	prog( ( padstack_row padstack structure_row structure ohm board project_name type fh result)
		padstack = "?"
		padstack_row = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_padstack)
		when( stringp( padstack_row)
			padstack_row = atoi( padstack_row)
			padstack = get_form_grid_cell_value( out_form _form_key_grid_padstack padstack_row _form_grid_col_name t)
		)
		
		structure = "?"
		structure_row = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_structure)
		when( stringp( structure_row)
			structure_row = atoi( structure_row)
			structure = get_form_grid_cell_value( out_form _form_key_grid_structure structure_row _form_grid_col_name t)
		)
		
		ohm = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_ohm t)
		
		board = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_board t)
		_project_name = axlFormGetField( out_form _form_key_prog_name)
		project_name = if( equal( "" board) _project_name strcat( _project_name "_" board))
		
		if( or( index( padstack "?") index( structure "?") equal( "" padstack) equal( "" structure) equal( "" ohm)) then
			result = _via_opt_thru_default
		else
			type = get_form_grid_cell_value( out_form _form_key_grid_padstack padstack_row _form_grid_col_type)
			
			if( equal( _through type) then
				fh = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_fh t)
				sprintf( result _via_opt_thru_name_form fh project_name ohm)
			else
				if( is_finish
					sprintf( result _via_opt_lsr_finish_form project_name ohm)
					sprintf( result _via_opt_lsr_name_form project_name ohm)
				)
			)
		)
		
		
		return( result)
	)
)

procedure( set_form( out_form)
	prog( ( row name)
		;;;;; --------------------------------------------------------------------------------------------------------------------- setup grid
		set_form_grid_padstack( out_form)
		set_form_grid_structure( out_form)
		set_form_grid_via_opt( out_form)
		
		;;;;; --------------------------------------------------------------------------------------------------------------------- default
		axlFormSetField( out_form _form_key_prog_name _project_name)
		axlFormDefaultButton( out_form _form_key_apply)
		
		;;;;; --------------------------------------------------------------------------------------------------------------------- a sample
		row = 1
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_type _through)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_fh 10.0)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_pad 20.0)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_anti 40.0)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_sm 16.0)
		name = get_form_padstack_name( out_form row)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_name name)
		
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_rt_kp_out _oblong)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_svia_p 10.0)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_gvia_px 20.0)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_gvia_py 40.0)
		name = get_form_structure_name( out_form row)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_name name)
		
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_padstack "1")
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_structure "1")
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_ohm 85)
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_board "mb")
		name = get_form_via_opt_name( out_form row)
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_name name)
		
		row = 2
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_type _laser)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_fh 10.0)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_pad 20.0)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_anti 40.0)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_sm 0.0)
		name = get_form_padstack_name( out_form row)
		set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_name name)
		
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_rt_kp_out _rectangle)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_svia_p 10.0)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_gvia_px 20.0)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_gvia_py 0.0)
		name = get_form_structure_name( out_form row)
		set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_name name)
		
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_padstack "2")
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_structure "2")
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_ohm 85)
		name = get_form_via_opt_name( out_form row)
		set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_name name)
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		axlFormGridUpdate( out_form _form_key_grid_padstack)
		axlFormGridUpdate( out_form _form_key_grid_structure)
		axlFormGridUpdate( out_form _form_key_grid_via_opt)
		
		
		return( t)
	)
)

procedure( update_form_via_opt_name( out_form)
	prog( ( name)
		for( row 1 _form_max_row
			name = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_name t)
			unless( equal( "" name)
				name = get_form_via_opt_name( out_form row)
				set_form_grid_cell( out_form _form_key_grid_via_opt row _form_grid_col_name name)
			)
		)
		
		axlFormGridUpdate( out_form _form_key_grid_via_opt)
		
		
		return( t)
	)
)

procedure( display_via_opt( out_form)
	prog( ( name padstack_row padstack structure_row structure)
		println( "-----------------------------------------------------------------------------------------------------------------------------------------")
		
		for( row 1 _form_max_row
			name = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_name t)
			unless( or( equal( "" name) index( name "?"))
				padstack_row = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_padstack)
				padstack_row = atoi( padstack_row)
				padstack = get_form_grid_cell_value( out_form _form_key_grid_padstack padstack_row _form_grid_col_name)
				
				structure_row = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_structure)
				structure_row = atoi( structure_row)
				structure = get_form_grid_cell_value( out_form _form_key_grid_structure structure_row _form_grid_col_name)
				
				printf( "INFO: display_via_opt() - via optimization[%s]\n\tPadstack[%s]\n\tStructure[%s]\n" name padstack structure)
			)
		)
		
		
		return( t)
	)
)

procedure( get_via_opt_data( out_form)
	prog( ( name via_opt padstack type fh pad anti sm padstack_data structure shape svia_pitch gvia_pitch_x gvia_pitch_y structure_data via_opt_data via_opt_data_ls)
		for( row 1 _form_max_row
			name = get_form_grid_cell_value( out_form _form_key_grid_via_opt row _form_grid_col_name t)
			unless( or( equal( "" name) index( name "?"))
				via_opt = get_form_via_opt_name( out_form row t)
				
				padstack = get_form_padstack_name( out_form row t)
				type = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_type)
				fh = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_fh)
				pad = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_pad)
				anti = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_anti)
				sm = get_form_grid_cell_value( out_form _form_key_grid_padstack row _form_grid_col_sm)
				padstack_data = list( padstack type fh pad anti sm)
				
				structure = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_name)
				shape = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_rt_kp_out)
				svia_pitch = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_svia_p)
				gvia_pitch_x = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_gvia_px)
				gvia_pitch_y = get_form_grid_cell_value( out_form _form_key_grid_structure row _form_grid_col_gvia_py)
				structure_data = list( structure shape svia_pitch gvia_pitch_x gvia_pitch_y)
				
				via_opt_data = list( via_opt padstack_data structure_data)
				via_opt_data_ls = append1( via_opt_data_ls via_opt_data)
			)
		)
		
		
		return( via_opt_data_ls)
	)
)

procedure( move_files( filename_ls to_path)
	prog( ( from_addr to_addr result)
		result = t
		foreach( filename filename_ls
			from_addr = strcat( _allegro_path filename)
			to_addr = strcat( to_path filename)
			
			if( isFile( from_addr) then
				axlOSFileMove( from_addr to_addr)
				unless( isFile( to_addr)
					printf( "ERROR: move_files() - Fail to move file[%s]\n" from_addr)
					result = nil
				)
			else
				printf( "ERROR: move_files() - Fail to find file[%s]\n" from_addr)
				result = nil
			)
		)
		
		
		return( result)
	)
)

procedure( create_dir( dir_path)
	prog( ( result)
		when( isDir( dir_path)
			axlRecursiveDelete( dir_path)
		)
		
		createDir( dir_path)
		
		result = isDir( dir_path)
		
		
		return( result)
	)
)

procedure( form_action( out_form)
	prog( ( row field filename_ls via_opt_to_path)
		row = out_form->row
		field = out_form->curField
		
		cond(
			( equal( _form_key_prog_name field)
				update_form_via_opt_name( out_form)
			)
			( equal( _form_key_grid_padstack field)
				name = get_form_padstack_name( out_form row)
				set_form_grid_cell( out_form _form_key_grid_padstack row _form_grid_col_name name)
				
				update_form_via_opt_name( out_form)
			)
			( equal( _form_key_grid_structure field)
				name = get_form_structure_name( out_form row)
				set_form_grid_cell( out_form _form_key_grid_structure row _form_grid_col_name name)
				
				update_form_via_opt_name( out_form)
			)
			( equal( _form_key_grid_via_opt field)
				update_form_via_opt_name( out_form)
			)
			( equal( _form_key_apply field)
				display_via_opt( out_form)
			)
			( equal( _form_key_create field)
				display_via_opt( out_form)
				
				;;;; create via optimization
				via_opt_data_ls = get_via_opt_data( out_form)
				when( dtpr( via_opt_data_ls)
					filename_ls = create_via_opt( via_opt_data_ls)
					println( "INFO: form_action() - Via optimization creating process is done. Start moving files to certain dir")
					
					create_dir( _via_opt_to_path)
					move_files( filename_ls _via_opt_to_path)
					
					via_opt_to_path = axlOSBackSlash( _via_opt_to_path)
					sprintf( cmd "start \"\" \"%s\" " via_opt_to_path)
					sh( cmd)
				)
				
				axlFormClose( out_form)
				axlFinishEnterFun()
			)
			( equal( _form_key_close field)
				axlFormClose( out_form)
				axlFinishEnterFun()
			)
		)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( get_lsr_via_opt_data( lsr_via_opt_finish laser_layer_ls)
	prog( ( via_opt_form padstack_form_data padstack_data structure_data padstack_form start end via_opt padstack via_opt_data via_opt_data_ls)
		via_opt_form = car( lsr_via_opt_finish)
		padstack_form_data = cadr( lsr_via_opt_finish)
		structure_data = caddr( lsr_via_opt_finish)
		
		padstack_form = car( padstack_form_data)
		
		foreach( layer_num laser_layer_ls
			cond(
				( equal( _layer_top_to_1 layer_num)
					start = 1
					end = start + _layer_top_to_1
				)
				( equal( _layer_top_to_2 layer_num)
					start = 1
					end = start + _layer_top_to_2
				)
				( equal( _layer_bot_to_1 layer_num)
					start = _etch_total + _layer_bot_to_1
					end = _etch_total
				)
				( equal( _layer_bot_to_2 layer_num)
					start = _etch_total + _layer_bot_to_2
					end = _etch_total
				)
			)
			
			sprintf( via_opt via_opt_form start end)
			sprintf( padstack padstack_form start end)
			
			padstack_data = append( list( padstack) cdr( padstack_form_data))
			
			via_opt_data = list( via_opt padstack_data structure_data)
			via_opt_data_ls = append1( via_opt_data_ls via_opt_data)
		)
		
		
		return( via_opt_data_ls)
	)
)

procedure( get_rt_kp_out_layer_ls( layer_num)
	; layer_num
	;	0: top bottom internal
	;	1: top second_layer
	;	2. top third_layer
	;	-1: bottom second_from_last
	;	-2 bottom third_from_last
	prog( ( subclass_ls layer_ls)
		cond(
			( eqv( _layer_thru layer_num)
				subclass_ls = list( _all)
			)
			( eqv( _layer_top_to_1 layer_num)
				subclass_ls = list( _top cadr( _etch_ls))
			)
			( eqv( _layer_top_to_2 layer_num)
				subclass_ls = list( _top cadr( _etch_ls) caddr( _etch_ls))
			)
			( eqv( _layer_bot_to_1 layer_num)
				subclass_ls = list( cadr( reverse( _etch_ls)) _bottom)
			)
			( eqv( _layer_bot_to_2 layer_num)
				subclass_ls = list( caddr( reverse( _etch_ls)) cadr( reverse( _etch_ls)) _bottom)
			)
			( t
				printf( "INFO: get_rt_kp_out_layer_ls() - Yet to define layer_num[%d]\n" layer_num)
				return( nil)
			)
		)
		
		when( dtpr( subclass_ls)
			layer_ls = mapcar( lambda( (x) strcat( "ROUTE KEEPOUT/" x)) subclass_ls)
		)
		
		return( layer_ls)
	)
)

procedure( get_padstack_layer_ls( layer_num non_sm)
	; layer_num
	;	0: top bottom internal
	;	1: top second_layer
	;	2. top third_layer
	;	-1: bottom second_from_last
	;	-2 bottom third_from_last
	prog( ( layer_ls)
		cond(
			( eqv( _layer_thru layer_num)
				layer_ls = list( _top _default_internal _bottom)
				unless( non_sm
					layer_ls = append( layer_ls list( _soldermask_top _soldermask_bottom))
				)
			)
			( eqv( _layer_top_to_1 layer_num)
				layer_ls = list( _top cadr( _etch_ls))
				unless( non_sm
					layer_ls = append1( layer_ls _soldermask_top)
				)
			)
			( eqv( _layer_top_to_2 layer_num)
				layer_ls = list( _top cadr( _etch_ls) caddr( _etch_ls))
				unless( non_sm
					layer_ls = append1( layer_ls _soldermask_top)
				)
			)
			( eqv( _layer_bot_to_1 layer_num)
				layer_ls = list( cadr( reverse( _etch_ls)) _bottom)
				unless( non_sm
					layer_ls = append1( layer_ls _soldermask_bottom)
				)
			)
			( eqv( _layer_bot_to_2 layer_num)
				layer_ls = list( caddr( reverse( _etch_ls)) cadr( reverse( _etch_ls)) _bottom)
				unless( non_sm
					layer_ls = append1( layer_ls _soldermask_bottom)
				)
			)
			( t
				printf( "INFO: get_padstack_layer_ls() - Yet to define layer_num[%d]\n" layer_num)
				return( nil)
			)
		)
		
		
		return( layer_ls)
	)
)

procedure( create_padstack( padstack_data layer_num filename)
	; padstack_data = list( padstack type fh pad anti sm)
	; layer_num
	;	0: top bottom internal
	;	1: top second_layer
	;	2. top third_layer
	;	-1: bottom second_from_last
	;	-2 bottom third_from_last
	prog( ( padstack type fh pad sm non_sm layer_ls pad_id pad_ls char toler padstack_drill padstack_id result)
		padstack = nth( 0 padstack_data)
		type = nth( 1 padstack_data)
		fh = nth( 2 padstack_data)
		pad = nth( 3 padstack_data)
		anti = nth( 4 padstack_data)
		sm = nth( 5 padstack_data)
		
		axlPurgePadstacks( 'padstacks nil)
		when( isFile( filename) deleteFile( filename))
		
		;;;;
		non_sm = zerop( sm)
		layer_ls = get_padstack_layer_ls( layer_num non_sm)
		
		;;;; create regular pad
		foreach( layer layer_ls
			if( member( layer list( _soldermask_top _soldermask_bottom))
				pad_id = make_axlPadStackPad( ?layer layer ?type 'REGULAR ?figure 'CIRCLE ?figureSize sm:sm)
				pad_id = make_axlPadStackPad( ?layer layer ?type 'REGULAR ?figure 'CIRCLE ?figureSize pad:pad)
			)
			pad_ls = append1( pad_ls pad_id)
		)
		
		;;;; create thermal
		foreach( layer layer_ls
			pad_id = nil
			unless( member( layer list( _soldermask_top _soldermask_bottom))
				pad_id = make_axlPadStackPad( ?layer layer ?type 'THERMAL)
			)
			when( pad_id (pad_ls = append1( pad_ls pad_id)))
		)
		
		;;;; create anti
		foreach( layer layer_ls
			pad_id = nil
			unless( member( layer list( _soldermask_top _soldermask_bottom))
				pad_id = make_axlPadStackPad( ?layer layer ?type 'ANTIPAD ?figure 'CIRCLE ?figureSize anti:anti)
			)
			when( pad_id (pad_ls = append1( pad_ls pad_id)))
		)
		
		;;;; create padstack
		char = cadar( setof( x _drill_figure_ls axlGeoEqual( fh car( x))))
		toler = if( (fh >= 10.0) list( 3.0 3.0) list( 0 fh))
		padstack_drill = make_axlPadStackDrill( ?drillDiameter fh
										?figure 'SQUARE
										?figureSize 50:50
										?plating 'PLATED
										?drillChar char
										?holeTolerance toler)
		padstack_id = axlDBCreatePadStack( padstack padstack_drill pad_ls t)
		axlPadstackToDisk( padstack)
		
		result = isFile( filename)
		if( result
			printf( "INFO: create_padstack() - Successful to create padstack[%s] to disk\n" filename)
			printf( "ERROR: create_padstack() - Fail to create padstack[%s] to disk\n" filename)
		)
		
		
		return( result)
	)
)

procedure( create_via_structure( type padstack_id structure_data)
	prog( ( structure shape svia_pitch gvia_pitch_x gvia_pitch_y svia_pitch_d2 xy)
		structure = nth( 0 structure_data)
		shape = nth( 1 structure_data)
		svia_pitch = nth( 2 structure_data)
		gvia_pitch_x = nth( 3 structure_data)
		gvia_pitch_y = nth( 4 structure_data)
		
		svia_pitch_d2 = svia_pitch / 2.0
		
		;;;;
		xy = list( svia_pitch_d2 0.0)
		axlDBCreateVia( padstack_id xy)
		
		xy = list( -svia_pitch_d2 0.0)
		axlDBCreateVia( padstack_id xy)
		
		when( equal( _through type)
			xy = list( (svia_pitch_d2 + gvia_pitch_x) -gvia_pitch_y)
			axlDBCreateVia( padstack_id xy)
			
			xy = list( -(svia_pitch_d2 + gvia_pitch_x) -gvia_pitch_y)
			axlDBCreateVia( padstack_id xy)
		)
		
		return( t)
	)
)

procedure( create_shape_oblong( layer filled prop side radius)
	prog( ( side_d2 xy1 xy2 path shape_id)
		side_d2 = side / 2.0
		
		xy1 = list( -side_d2 radius)
		xy2 = list( side_d2 radius)
		path = axlPathStart( list( xy1 xy2))
		
		xy1 = list( side_d2 0.0)
		xy2 = list( side_d2 -radius)
		axlPathArcCenter( path nil xy2 t xy1)
		
		xy2 = list( -side_d2 -radius)
		axlPathLine( path nil xy2)
		
		xy1 = list( -side_d2 0.0)
		xy2 = list( -side_d2 radius)
		axlPathArcCenter( path nil xy2 t xy1)
		
		shape_id = car( axlDBCreateShape( path filled layer))
		when( prop (shape_id = caar( axlDBAddProp( shape_id prop))))
		
		
		return( shape_id)
	)
)

procedure( create_shape_rectangle( layer filled prop hor ver)
	prog( ( hor_d2 ver_d2 xy1 xy2 xy3 xy4 path shape_id )
		hor_d2 = hor / 2.0
		ver_d2 = ver / 2.0
		
		xy1 = list( -hor_d2 ver_d2)
		xy2 = list( hor_d2 ver_d2)
		xy3 = list( hor_d2 -ver_d2)
		xy4 = list( -hor_d2 -ver_d2)
		
		path = axlPathStart( list( xy1 xy2 xy3 xy4 xy1))
		
		shape_id = car( axlDBCreateShape( path filled layer))
		when( prop (shape_id = caar( axlDBAddProp( shape_id prop))))
		
		
		return( shape_id)
	)
)

procedure( create_shape_t( layer filled prop top_side bot_side height radius)
	prog( ( adjacent opposite radians up_angle down_angle top_side_d2 bot_side_d2 xy1 xy2 path shape_id)
		adjacent = (bot_side - top_side) / 2
		opposite = height
		radians = atan( opposite / adjacent)
		
		up_angle = radians * 180.0 / axlPI
		down_angle = 180.0 - up_angle
		
		top_side_d2 = top_side / 2.0
		bot_side_d2 = bot_side / 2.0
		
		xy1 = list( -top_side_d2 radius)
		xy2 = list( top_side_d2 radius)
		path = axlPathStart( list( xy1 xy2))
		
		xy1 = list( top_side_d2 0.0)
		xy2 = axlGeoRotatePt( -up_angle xy2 xy1)
		axlPathArcCenter( path nil xy2 t xy1)
		
		xy2 = axlMXYAdd( xy2 list( adjacent -height))
		axlPathLine( path nil xy2)
		
		xy1 = list( bot_side_d2 -height)
		xy2 = list( bot_side_d2 -(height + radius))
		axlPathArcCenter( path nil xy2 t xy1)
		
		xy2 = list( -bot_side_d2 -(height + radius))
		axlPathLine( path nil xy2)
		
		xy1 = list( -bot_side_d2 -height)
		xy2 = axlGeoRotatePt( -down_angle xy2 xy1)
		axlPathArcCenter( path nil xy2 t xy1)
		
		xy2 = axlMXYAdd( xy2 list( adjacent height))
		axlPathLine( path nil xy2)
		
		xy1 = list( -top_side_d2 0.0)
		xy2 = list( -top_side_d2 radius)
		axlPathArcCenter( path nil xy2 t xy1)
		
		shape_id = car( axlDBCreateShape( path filled layer))
		when( prop (shape_id = caar( axlDBAddProp( shape_id prop))))
		
		
		return( shape_id)
	)
)

procedure( create_shape( layer filled prop shape side radius @optional (gvia_pitch_x 0) (gvia_pitch_y 0))
;	shape:
;		oblong:
;			side1: svia_pitch for side
;			side2: anti for radius
;		?:
;			side1: svia_pitch for top side
;			side2: anti for bottom side
;			side3: gvia_pitch_x: for bottom side
;			side4: gvia_pitch_y: for height
;		rectangle:
;			side1: svia_pitch for side
;			side2: anti for height
	prog( ( side1 side2 side3 side4 result )
		cond(
			( not( zerop( gvia_pitch_y))
				;;;; create T shape
				side1 = side
				side2 = side + gvia_pitch_x * 2
				side3 = gvia_pitch_y
				side4 = radius
				
				result = create_shape_t( layer filled prop side1 side2 side3 side4)
			)
			( equal( _oblong shape)
				;;;; create oblong shape
				side1 = side + gvia_pitch_x * 2
				side2 = radius
				
				result = create_shape_oblong( layer filled prop side1 side2)
			)
			( equal( _rectangle shape)
				;;;; create rectangle
				side1 = side + radius * 2
				side2 = radius * 2
				
				result = create_shape_rectangle( layer filled prop side1 side2)
			)
			( t
				printf( "ERROR: create_shape() - Yet to define shape[%s]\n" shape)
				return( nil)
			)
		)
		
		
		return( result)
	)
)

procedure( create_shape_structure( layer_num pad anti structure_data)
	prog( ( structure shape svia_pitch gvia_pitch_x gvia_pitch_y pad_d2 )
		structure = nth( 0 structure_data)
		shape = nth( 1 structure_data)
		svia_pitch = nth( 2 structure_data)
		gvia_pitch_x = nth( 3 structure_data)
		gvia_pitch_y = nth( 4 structure_data)
		
		;;;; if it's through type via optimization, then ignore gvia_pitch_y
		unless( eqv( _layer_thru layer_num) (gvia_pitch_x = gvia_pitch_y = 0))
		
		;;;;
		radius = anti / 2.0
		side = svia_pitch
		rt_kp_out_layer_ls = get_rt_kp_out_layer_ls( layer_num)
		foreach( layer rt_kp_out_layer_ls
			create_shape( layer t _prop_via_route shape side radius)
		)
		
		;;;;
		radius = pad / 2.0
		side = svia_pitch
		create_shape( "CONSTRAINT REGION/ALL" nil _prop_nodrc5 _oblong side radius gvia_pitch_x gvia_pitch_y)
		
		
		return( t)
	)
)

procedure( create_via_opt_util( layer_num via_opt_data dra_filename bsm_filename)
	; via_opt_data = list( via_opt padstack_data structure_data)
	; structure_data = list( structure shape svia_pitch gvia_pitch_x gvia_pitch_y)
	; padstack_data = list( padstack type fh pad anti sm)
	prog( ( via_opt padstack_data structure_data padstack anti padstack_id result)
		via_opt = nth( 0 via_opt_data)
		padstack_data = nth( 1 via_opt_data)
		structure_data = nth( 2 via_opt_data)
		
		padstack = nth( 0 padstack_data)
		type = nth( 1 padstack_data)
		pad = nth( 3 padstack_data)
		anti = nth( 4 padstack_data)
		
		;;;; purge padstack
		axlPurgePadstacks( 'padstacks nil)
		
		;;;; load padstack
		padstack_id = axlLoadPadstack( padstack)
		unless( padstack_id printf( "ERROR: create_via_opt_util() - Fail to load padstack[%s]\n" padstack) return( nil))
		
		;;;; place via padstack
		create_via_structure( type padstack_id structure_data)
		
		;;;; create shape
		create_shape_structure( layer_num pad anti structure_data)
		
		;;;; save via optimization to disk
		axlSaveDesign( ?design via_opt ?mode "nocheck" ?noConfirm t ?writeModel t)
		axlCompileSymbol( ?symbol via_opt ?type "MECHANICAL")
		
		result = and( isFile( dra_filename) isFile( bsm_filename))
		
		
		return( result)
	)
)

procedure( write_xsection_techfile()
	prog( ( cmd_name cmd msg)
		;; -q - quiet mode, continue with warnings
		
		cmd_name = "xsection_techfile"
		sprintf( cmd "techfile -w -q -i x \"%s\" \"%s\" " _allegro_addr _xsection_techfile)
		msg = "INFO: write_xsection_techfile() - Start writing xsection by a tech file"
		
		axlRunBatchDBProgram( cmd_name cmd ?startMsg msg ?silent t)
		
		
		return( t)
	)
)

procedure( write_import_xsection_techfile_scr()
	prog( ( out_port line_ls)
		out_port = outfile( _import_xsection_techfile_scr "w")
		unless( outportp( out_port) println( "ERROR: write_import_xsection_techfile_scr() - Fail to write script file") return( nil))
		
		;;;;
		line_ls = list( "setwindow pcb"
						"generaledit"
						"techfile in"
						"setwindow form.tech_in"
						"generaledit"
						"techfile in"
						"setwindow form.tech_in"
						"FORM tech_in browse"
						sprintf( nil "fillin \"%s\" " _xsection_techfile)
						"FORM tech_in execute"
						"setwindow pcb"
						"setwindow form.tech_in"
						"FORM tech_in cancel"
						"setwindow pcb"
						"generaledit")
		
		foreach( line line_ls fprintf( out_port "%s\n" line))
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( read_xsection_techfile()
	prog( ( cmd)
		write_import_xsection_techfile_scr()
		
		sprintf( cmd "replay \"%s\" " _import_xsection_techfile_scr)
		axlShell( cmd)
		
		return( t)
	)
)

procedure( delete_all_objective()
	prog( ( obj_ls)
		axlSetFindFilter( ?enabled list( "ALL") ?onButtons list( "ALL"))
		
		axlVisibleDesign( t)
		axlVisibleUpdate( t)
		
		axlAddSelectAll()
		obj_ls = axlGetSelSet()
		
		axlClearSelSet()
		axlSetFindFilter( ?enabled list( "NOALL") ?onButtons list( "NOALL"))
		
		axlDeleteObject( obj_ls)
		
		
		return( t)
	)
)

procedure( create_via_opt( via_opt_data_ls)
	; "lv10c20_%d-%d_anti40_sm0"
	; "lv%d-%d_flex_85dp" 
	prog( ( filename1 filename2 filename_ls)
		;;;; separate data
		thru_via_opt_data_ls = mapcan( lambda( (x) when( equal( _through cadadr( x)) list( x))) via_opt_data_ls)
		thru_padstack_data_ls = mapcar( lambda( (x) cadr( x)) thru_via_opt_data_ls)
		
		lsr_via_opt_finish_ls = mapcan( lambda( (x) when( equal( _laser cadadr( x)) list( x))) via_opt_data_ls)
		
		;;;; go to dra
		axlOSFileCopy( _via_opt_dra_from_addr _via_opt_dra_to_addr nil)
		axlOpenDesignForBatch( _via_opt_dra_to_addr "wf")
		
		;;;; create through padstack
		foreach( padstack_data thru_padstack_data_ls
			sprintf( filename1 "%s.pad" car( padstack_data))
			create_padstack( padstack_data _layer_thru filename1)
			
			filename_ls = append1( filename_ls filename1)
		)
		
		;;;; create through via optimization
		foreach( via_opt_data thru_via_opt_data_ls
			sprintf( filename1 "%s.dra" car( via_opt_data))
			sprintf( filename2 "%s.bsm" car( via_opt_data))
			
			delete_all_objective()
			create_via_opt_util( _layer_thru via_opt_data filename1 filename2)
			
			filename_ls = append( filename_ls list( filename1 filename2))
		)
		
		unless( dtpr( lsr_via_opt_finish_ls)
			axlOpenDesignForBatch( _allegro_addr "wf")
			return( filename_ls)
		)
		
		;;;; import xsection
		write_xsection_techfile()
		read_xsection_techfile()
		
		;;;; create laser via optimization
		foreach( lsr_via_opt_finish lsr_via_opt_finish_ls
			lsr_via_opt_data_ls = get_lsr_via_opt_data( lsr_via_opt_finish _laser_layer_ls)
			foreach( (via_opt_data layer_num) lsr_via_opt_data_ls _laser_layer_ls
				via_opt = car( via_opt_data)
				padstack_data = cadr( via_opt_data)
				
				;;;; create padstack
				sprintf( filename1 "%s.pad" car( padstack_data))
				create_padstack( padstack_data layer_num filename1)
				filename_ls = append1( filename_ls filename1)
				
				;;;; create via optimization
				sprintf( filename1 "%s.dra" via_opt)
				sprintf( filename2 "%s.bsm" via_opt)
				
				delete_all_objective()
				create_via_opt_util( layer_num via_opt_data filename1 filename2)
			
				filename_ls = append( filename_ls list( filename1 filename2))
			)
		)
		
		;;;; go back to board
		axlOpenDesignForBatch( _allegro_addr "wf")
		
		return( filename_ls)
	)
)

procedure( create_via_optimization_main()
	prog( ( result )
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		
		init()
		
		;;;; check
		unless( isFile( _via_opt_dra_from_addr)
			printf( "ERROR: create_via_optimization_main() - Fail to find following file. Please place one on it\n\t%s" _via_opt_dra_from_addr)
			return( nil)
		)
		
		;;;; create form
		result = write_form()
		unless( result println( "ERROR: create_via_optimization_main() - Fail to create form content file\n") return( nil))
		out_form = axlFormCreate( gensym() _form_filename '("east" "outer") 'form_action t)
		set_form( out_form)
		axlFormDisplay( out_form)
		
		;;;; remove the extra form
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup
; (load "create_via_optimization_v1.ile")

(axlCmdRegister "create_via_optimization" 'create_via_optimization_main)
 create_via_optimization_main()
; skill (encrypt "c:/skill/create_via_optimization_v1d1.il" "c:/skill/create_via_optimization_v1d1.ile")
; (load "create_via_optimization_v1d1.ile")
; (load "create_via_optimization_v1d1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup