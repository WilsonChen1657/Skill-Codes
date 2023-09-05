;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; developer: Derek Hsu
; Starting Date: 03/11/2021 - _Derek03112021
; introduction: orient text, which is in the selected layer, to 2 adjacent directions.
; guideline:
;	1. selectable layers: ref des/[top/bottom], package geometry[top/bottom], board geometry[top/bottom]
;	2. direction: up-left, left-down, down-right, right-up
;	3. ignore the angle out of 0,90,180,270
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init_Derek03112021()
	;; common
	setq( _refdes_silk_top_ly "REF DES/SILKSCREEN_TOP")
	setq( _refdes_silk_bot_ly "REF DES/SILKSCREEN_BOTTOM")
	setq( _brdgeo_silk_top_ly "BOARD GEOMETRY/SILKSCREEN_TOP")
	setq( _brdgeo_silk_bot_ly "BOARD GEOMETRY/SILKSCREEN_BOTTOM")
	setq( _pkggeo_silk_top_ly "PACKAGE GEOMETRY/SILKSCREEN_TOP")
	setq( _pkggeo_silk_bot_ly "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM")
	
	setq( _text_on_sym_ly_ls list( _refdes_silk_top_ly _refdes_silk_bot_ly _pkggeo_silk_top_ly _pkggeo_silk_bot_ly))
	setq( _text_on_brd_ly_ls list( _brdgeo_silk_top_ly _brdgeo_silk_bot_ly))
	
	setq( _dire_up 0.0)
	setq( _dire_left 90.0)
	setq( _dire_down 180.0)
	setq( _dire_right 270.0)
	
	sprintf( _dire_up_left "%3.0f - %3.0f" _dire_left _dire_up)
	sprintf( _dire_left_down "%3.0f - %3.0f" _dire_left _dire_down)
	sprintf( _dire_down_right "%3.0f - %3.0f" _dire_down _dire_right)
	sprintf( _dire_right_up "%3.0f - %3.0f" _dire_up _dire_right)
	
	;; form	
	setq( _form_name "check_orient_text.form")
	
	setq( _form_lkey_rst "refdes_silk_top")
	setq( _form_lkey_rsb "refdes_silk_bot")
	setq( _form_lkey_bst "brd_silk_top")
	setq( _form_lkey_bsb "brd_silk_bot")
	setq( _form_lkey_pst "pkg_silk_top")
	setq( _form_lkey_psb "pkg_silk_bot")
	
	setq( _form_dkey_ul "up_left")
	setq( _form_dkey_ld "left_down")
	setq( _form_dkey_dr "down_right")
	setq( _form_dkey_ru "right_up")
	
	setq( _form_bkey_check "check")
	setq( _form_bkey_run "run")
	setq( _form_bkey_close "close")
	
	;; user choice
	setq( _user_layer_ls nil)
	setq( _user_dire nil)
	; either check the direction of texts or orient the text
	setq( _user_check_text nil)
	
	;; log
	defstruct( log_message from_degree to_degree text xy layer)
	setq( _log_msg_ls nil)
	
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _log_filename "check_orient_text-%s.log" _date_time)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _orient_text_logname "%s/%s" _log_dir _log_filename)
	sprintf( _check_orient_text_logname "%s/check-%s" _log_dir _log_filename)
	setq( _schematic_name get_schematic_name_Derek03112021())
)

procedure( init1_Derek03112021()
	setq( _form_lkey_table makeTable( 'lkey nil))
	setq( _lkey_order_ls list( _form_lkey_rst _form_lkey_rsb _form_lkey_bst _form_lkey_bsb _form_lkey_pst _form_lkey_psb))
	
	_form_lkey_table[_form_lkey_rst] = _refdes_silk_top_ly
	_form_lkey_table[_form_lkey_rsb] = _refdes_silk_bot_ly
	_form_lkey_table[_form_lkey_bst] = _brdgeo_silk_top_ly
	_form_lkey_table[_form_lkey_bsb] = _brdgeo_silk_bot_ly
	_form_lkey_table[_form_lkey_pst] = _pkggeo_silk_top_ly
	_form_lkey_table[_form_lkey_psb] = _pkggeo_silk_bot_ly
	
	setq( _form_dkey_table makeTable( 'dkey nil))
	setq( _dkey_order_ls list( _form_dkey_ul _form_dkey_ld _form_dkey_dr _form_dkey_ru))
	
	_form_dkey_table[_form_dkey_ul] = _dire_up_left
	_form_dkey_table[_form_dkey_ld] = _dire_left_down
	_form_dkey_table[_form_dkey_dr] = _dire_down_right
	_form_dkey_table[_form_dkey_ru] = _dire_right_up
	
	setq( _orient_table makeTable( 'orient nil))
	setq( _orient_all_ls list( _dire_up _dire_left _dire_down _dire_right))
	
	_orient_table[_form_dkey_ul] = list( _dire_up _dire_left)
	_orient_table[_form_dkey_ld] = list( _dire_left _dire_down)
	_orient_table[_form_dkey_dr] = list( _dire_down _dire_right)
	_orient_table[_form_dkey_ru] = list( _dire_right _dire_up)
)

procedure( get_schematic_name_Derek03112021()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls and( (length( s->pins) > 1))))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( set_user_layers_Derek03112021( out_form)
	let( ( checked layer)
		foreach( field _lkey_order_ls
			checked = axlFormGetField( out_form field)
			
			when( checked
				layer = _form_lkey_table[field]
				_user_layer_ls = append1( _user_layer_ls layer)
			)
		)
	)
)

procedure( set_user_orientation_Derek03112021( out_form)
	let( ( checked)
		foreach( field _form_dkey_table
			checked = axlFormGetField( out_form field)
			
			when( checked
				_user_dire = _orient_table[field]
			)
		)
	)
)

procedure( form_action_setup_Derek03112021( out_form)
	let( ()
		_log_msg_ls = nil
		_user_layer_ls = nil
		_user_dire = nil
		
		set_user_layers_Derek03112021( out_form)
		set_user_orientation_Derek03112021( out_form)
		
		printf( "INFO: form_action_setup() - Layers: %L\n" _user_layer_ls)
		printf( "INFO: form_action_setup() - Orientation: %L\n" _user_dire)
	)
)

procedure( form_action_Derek03112021( out_form)
	prog( (field)
		field = out_form->curField
		
		when( field == _form_bkey_check
			_user_check_text = t
				
			form_action_setup_Derek03112021( out_form)
			
			run_main_Derek03112021()
			
			axlUIViewFileCreate( _check_orient_text_logname "Chect Text Orientation Report" nil)
			
			return( t)
		)
		
		when( field == _form_bkey_run
			_user_check_text = nil
			
			form_action_setup_Derek03112021( out_form)
			
			axlCancelEnterFun()
			axlFormClose( out_form)
			
			run_main_Derek03112021()
			
			axlUIViewFileCreate( _orient_text_logname "Text Orientation Report" nil)
			
			return( t)
		)
		
		when( field == _form_bkey_close
			axlCancelEnterFun()
			axlFormClose( out_form)
			
			return( t)
		)
		
		return( nil)
	)
)

procedure( set_form_Derek03112021( out_form)
	let( ()
		foreach( field _form_lkey_table
			axlFormSetField( out_form field t)
		)
		
		axlFormSetField( out_form _form_dkey_ul t)
		
		axlFormDefaultButton( out_form _form_bkey_check)
	)
)

procedure( write_form_head_Derek03112021( out_port name window_width @optional (window_height 50))
	let( ()
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=%d\n" 1)   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" window_width window_height)
		fprintf( out_port "HEADER \"%s\"\n" name)
		fprintf( out_port "TILE\n")
		fprintf( out_port "\n")
	)
)

procedure( write_form_tail_Derek03112021( out_port)
	let( ()
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
	)
)

procedure( write_form_group_Derek03112021( out_port name start_x end_x start_y end_y)
	let( ()
		fprintf( out_port "GROUP \"%s\"\n" name)
		fprintf( out_port "FLOC %d %d\n" start_x start_y)
		fprintf( out_port "TSSIZE %d %d\n" (end_x - start_x) (end_y - start_y))
		fprintf( out_port "ENDGROUP\n\n")
	)
)

procedure( write_form_checklist_Derek03112021( out_port field name x y @optional (radio_label nil))
	let( ()
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		
		if( stringp( radio_label)
			fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" name radio_label)
			fprintf( out_port "CHECKLIST \" %s\" \n" name)
		)
		
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( write_form_button_Derek03112021( out_port field name x y @optional (width 12) (height 2))
	let( ()
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" name width height)
		fprintf( out_port "ENDFIELD\n\n")
	)
)

procedure( write_form_Derek03112021()
	prog( ()
		out_port = outfile( _form_name "w")
		unless( outportp( out_port)
			printf( "ERROR: write_form() - Fail to write file: %s\n" _form_name)
			return( nil)
		)
		
		window_width = 41
		
		;;;;; --------------------------------------------------------------------------------------------------
		
		write_form_head_Derek03112021( out_port "Orient Text to 2 Directions Panel" window_width)
		
		;;;;; --------------------------------------------------------------------------------------------------
		
		; write_form_group_Derek03112021( out_port "" start_x x start_y y)
		start_x = 1
		start_y = 1
		
		x = start_x + 2
		y = start_y
		foreach( field _lkey_order_ls
			y = y + 2
			name = _form_lkey_table[field]
			write_form_checklist_Derek03112021( out_port field name x y)
		)
		
		y = y + 2
		write_form_group_Derek03112021( out_port "Layer" start_x window_width start_y y)
		
		;;;;; --------------------------------------------------------------------------------------------------
		
		start_y = y
		
		y = y + 2
		x = start_x + 6
		field = _form_dkey_ul
		write_form_checklist_Derek03112021( out_port field _form_dkey_table[field] x y "orientation")
		
		x = window_width - 16
		field = _form_dkey_ru
		write_form_checklist_Derek03112021( out_port field _form_dkey_table[field] x y "orientation")
		
		x = start_x + 6
		y = y + 2
		field = _form_dkey_ld
		write_form_checklist_Derek03112021( out_port field _form_dkey_table[field] x y "orientation")
		
		x = window_width - 16
		field = _form_dkey_dr
		write_form_checklist_Derek03112021( out_port field _form_dkey_table[field] x y "orientation")
		
		y = y + 2
		write_form_group_Derek03112021( out_port "Orientation" start_x window_width start_y y)
		
		;;;;; --------------------------------------------------------------------------------------------------
		
		y = y + 1
		
		x = start_x
		write_form_button_Derek03112021( out_port _form_bkey_check "Check" x y)
		
		x = start_x + 14
		write_form_button_Derek03112021( out_port _form_bkey_run "Run" x y)
		
		x = window_width - 12
		write_form_button_Derek03112021( out_port _form_bkey_close "Close" x y)
		
		;;;;; --------------------------------------------------------------------------------------------------
		
		write_form_tail_Derek03112021( out_port)
		
		;;;;; --------------------------------------------------------------------------------------------------
		
		close( out_port)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_text_on_sym_Derek03112021( layer_ls)
	prog( ( sym_ls attached_text_ls ok_text_ls text_ls)
		sym_ls = axlDBGetDesign()->symbols
		
		foreach( sym_id sym_ls
			attached_text_ls = axlDBGetAttachedText( sym_id)
			ok_text_ls = setof( x attached_text_ls member( x->layer layer_ls))
			text_ls = append( text_ls ok_text_ls)
		)
		
		return( text_ls)
	)
)

procedure( get_text_on_board_Derek03112021( layer_ls)
	prog( ( text_ls)
		text_ls = axlDBGetDesign()->text
		
		text_ls = setof( x text_ls member( x->layer layer_ls))
		
		return( text_ls)
	)
)

procedure( get_texts_Derek03112021()
	prog( ( sym_ly_ls brd_ly_ls text_sym_ls text_brd_ls text_ls)
		sym_ly_ls = setof( x _user_layer_ls member( x _text_on_sym_ly_ls))
		brd_ly_ls = setof( x _user_layer_ls member( x _text_on_brd_ly_ls))
		
		text_sym_ls = get_text_on_sym_Derek03112021( sym_ly_ls)
		text_brd_ls = get_text_on_board_Derek03112021( brd_ly_ls)
		
		text_ls = append( text_sym_ls text_brd_ls)
			
		return( text_ls)
	)
)

procedure( is_in_2number_Derek03112021( num1 num2 data_num)
	prog( ( is_in)
		;; assume num1 - data_num - num2
		is_in = plusp( num1 - data_num) == plusp( data_num - num2)
		
		return( is_in)
	)
)

procedure( is_to_orient_Derek03112021( text_id)
	prog( ( rotation angle1 angle2 to_rotate)
		rotation = text_id->rotation
		unless( rotation
			printf( "WARNING: is_to_orient() - Fail to get rotation from %L\n" list( text_id->text text_id->layer text_id->xy))
			return( nil)
		)
		
		to_rotate = t
		
		when( exists( x _user_dire x == rotation)
			to_rotate = nil
		)
		
		unless( exists( x _orient_all_ls x == rotation)
			to_rotate = nil
		)
		
		return( to_rotate)
	)
)

procedure( get_to_degree_Derek03112021( rotation)
	prog( ( to_degree)
		if( zerop( remainder( int( rotation) 90)) then
			to_degree = rotation + 180.0
			when( to_degree >= 360.0
				to_degree = remainder( int( to_degree) 360)
			)
		else
			to_degree = rotation
		)

		;; if( zerop( remainder( int( rotation) 90)) then
		; angle1 = car( _user_dire)
		; angle2 = cadr( _user_dire)
		; to_degree = rotation
		; while( is_in_2number_Derek03112021( angle1 angle2 to_degree)
		;	to_degree = to_degree + 90.0
		;	to_degree = remainder( int( to_degree) 360)
		; )
		
		to_degree = float( to_degree)
		
		return( to_degree)
	)
)

procedure( add_log_Derek03112021( text_id from_degree to_degree)
	let( ( text xy layer log_msg_stru)
		text = text_id->text
		xy = text_id->xy
		layer = text_id->layer
		log_msg_stru = make_log_message( ?from_degree from_degree ?to_degree to_degree ?text text ?xy xy ?layer layer)
		
		_log_msg_ls = append1( _log_msg_ls log_msg_stru)
	)
)

procedure( get_4_xys_Derek03112021( xy radius)
	prog( ( xy1 xy2 xy3 xy4 xy_4)
		xy1 = axlMXYAdd( xy list( radius 0.0))
		xy2 = axlMXYAdd( xy list( -radius 0.0))
		xy3 = axlMXYAdd( xy list( 0.0 radius))
		xy4 = axlMXYAdd( xy list( 0.0 -radius))
		
		xy_4 = list( xy1 xy2 xy3 xy4)
		
		return( xy_4)
	)
)

procedure( get_max_box_from_xys_Derek03112021( xy_ls)
	prog( ( x_ls y_ls x_min x_max y_min y_max box)
		x_ls = mapcar( 'car xy_ls)
		y_ls = mapcar( 'cadr xy_ls)
		
		x_min = apply( 'min x_ls)
		x_max = apply( 'max x_ls)
		y_min = apply( 'min y_ls)
		y_max = apply( 'max y_ls)
		
		box = list( list( x_min y_min) list( x_max y_max))
		
		return( box)
	)
)

procedure( get_around_xys_on_text_Derek03112021( text_id)
	prog( ( path_ls_ls path_seg_ls radius xy xy_4 xy_ls)
		path_ls_ls = axlText2Lines( text_id)
		
		foreach( path_ls path_ls_ls
			foreach( path_id path_ls
				path_seg_ls = append( path_seg_ls path_id->_pathList)
				
				unless( radius
					radius = path_id->_width / 2
				)
			)
		)
		
		foreach( path_seg_id path_seg_ls
			xy = path_seg_id->_endPoint
			xy_4 = get_4_xys_Derek03112021( xy radius)
			xy_ls = append( xy_ls xy_4)
		)
		
		return( xy_ls)
	)
)

procedure( get_text_box_Derek03112021( text_id)
	; text_id = car( axlGetSelSet())
	prog( ()
		xy_ls = get_around_xys_on_text_Derek03112021( text_id)
		box = get_max_box_from_xys_Derek03112021( xy_ls)
		
		return( box)
	)
)

procedure( orient_text_utility_Derek03112021( text_id to_degree)
	let( ( angle box center_xy)
		angle = to_degree - text_id->rotation
		box = get_text_box_Derek03112021( text_id)
		center_xy = axlMidPointLine( box)
		
		axlDBCloak( 'axlTransformObject( text_id ?angle angle ?origin center_xy))
	)
)

procedure( orient_text_Derek03112021( text_id)
	; text_id = car( text_ls)
	prog( ( from_degree to_degree)
		from_degree = text_id->rotation
		to_degree = get_to_degree_Derek03112021( from_degree)
				
		unless( to_degree
			printf( "ERROR: orient_text() - Fail to get to_degree on %L\n" list( text_id->text text_id->layer text_id->xy))
			return( nil)
		)
		
		when( from_degree == to_degree
			return( nil)
		)
		
		orient_text_utility_Derek03112021( text_id to_degree)
		add_log_Derek03112021( text_id from_degree to_degree)
		
		return( t)
	)
)

procedure( check_tests_Derek03112021( text_ls)
	let( ( from_degree to_degree)
		foreach( text_id text_ls
			from_degree = text_id->rotation
			to_degree = text_id->rotation
			add_log_Derek03112021( text_id from_degree to_degree)
		)
	)
)

procedure( orient_texts_Derek03112021( text_ls)
	; text_id = car( text_ls)
	let( ()
		foreach( text_id text_ls
			orient_text_Derek03112021( text_id)
		)
	)
)

procedure( run_texts_Derek03112021( text_ls)
	let( ( to_orient_text_ls)
		to_orient_text_ls = setof( text_id text_ls is_to_orient_Derek03112021( text_id))
		
		if( _user_check_text then
			check_tests_Derek03112021( to_orient_text_ls)
		else
			orient_texts_Derek03112021( to_orient_text_ls)
		)
	)
)

procedure( run_form_Derek03112021()
	let( ( out_form)
		write_form_Derek03112021()
		
		out_form = axlFormCreate( gensym() _form_name '( "east" "outer") 'form_action_Derek03112021 nil)
		
		set_form_Derek03112021( out_form)
		
		axlFormDisplay( out_form)
	)
)

procedure( write_log_check_Derek03112021( out_port)
	let( ( format text layer xy from_degree to_degree)
		unless( outportp( out_port) return( nil))
		
		format = "%-10s,%-40s,%-20s,%-15s\n"
		fprintf( out_port format "Text" "Layer" "xy" "Degree")
		
		foreach( log_msg_stru _log_msg_ls
			text = log_msg_stru->text
			layer = log_msg_stru->layer
			sprintf( xy "%L" log_msg_stru->xy)
			sprintf( from_degree "%.2f" log_msg_stru->from_degree)
			
			fprintf( out_port format text layer xy from_degree)
		)
		
		unless( _log_msg_ls
			fprintf( out_port "\tNone\n")
		)
	)
)

procedure( write_log_orient_Derek03112021( out_port)
	let( ( format text layer xy from_degree to_degree)
		unless( outportp( out_port) return( nil))
		
		format = "%-10s,%-40s,%-20s,%-15s,%-15s\n"
		fprintf( out_port format "Text" "Layer" "xy" "From_degree" "To_degree")
		
		foreach( log_msg_stru _log_msg_ls
			text = log_msg_stru->text
			layer = log_msg_stru->layer
			sprintf( xy "%L" log_msg_stru->xy)
			sprintf( from_degree "%.2f" log_msg_stru->from_degree)
			sprintf( to_degree "%.2f" log_msg_stru->to_degree)
			
			fprintf( out_port format text layer xy from_degree to_degree)
		)
		
		unless( _log_msg_ls
			fprintf( out_port "\tNone\n")
		)
	)
)

procedure( write_log_Derek03112021()
	prog( ( logname out_port)
		if( _user_check_text then
			logname = _check_orient_text_logname
		else
			logname = _orient_text_logname
		)
	
		out_port = outfile( logname "w")
		unless( outportp( out_port)
			println( "ERROR: write_log() - Fail to write file")
			return( nil)
		)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		if( _user_check_text then
			introduction = "Check whether the text in selected layer fits the selected orientation"
		else
			introduction = "Orient the text in selected layer to corresponse orientation"
		)
		
		fprintf( out_port "Introduction: %s\n" introduction)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=================================================================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Summary\n")
		
		fprintf( out_port "\n")
		
		fprintf( out_port "\tSelected Layer:\n")
		foreach( layer _user_layer_ls
			fprintf( out_port "\t\t%s\n" layer)
		)
		
		fprintf( out_port "\n")
		
		fprintf( out_port "\tSelected Orientation:\n")
		fprintf( out_port "\t\t%L\n" _user_dire)
		
		fprintf( out_port "\n")
		
		fprintf( out_port "\tTotal Item: %d\n" length( _log_msg_ls))
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=================================================================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		if( _user_check_text then
			write_log_check_Derek03112021( out_port)
		else
			write_log_orient_Derek03112021( out_port)
		)
		
		fprintf( out_port "\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( sort_log_msg_Derek03112021()
	let( ( msg_ls)
		foreach( key _lkey_order_ls
			layer = _form_lkey_table[key]
			
			foreach( log_msg_stru _log_msg_ls
				when( layer == log_msg_stru->layer
					msg_ls = append1( msg_ls log_msg_stru)
				)
			)
		)
		
		_log_msg_ls = msg_ls
	)
)

procedure( run_main_Derek03112021()
	prog( ( text_ls)
		;;;;; check setup data
		unless( _user_dire return( nil))
		unless( _user_layer_ls
			println( "WARNING: run_main() - Please at least select a layer to use this program")
			return( nil)
		)
		
		;;;;; select all text fit the requirement 
		text_ls = get_texts_Derek03112021()
		
		;;;;; run through the text
		run_texts_Derek03112021( text_ls)
		
		;;;;; sort log message
		sort_log_msg_Derek03112021()
		
		;;;;; run log
		write_log_Derek03112021()
	)
)

procedure( check_orient_text_main_Derek03112021()
	prog( ()
		unless( axlOKToProceed() println( "Please done the current function to execute this function") (return nil))
		;;
		
		init_Derek03112021()
		init1_Derek03112021()
		
		;;;;; create form and operate it
		run_form_Derek03112021()
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_orient_text" 'check_orient_text_main_Derek03112021)
; check_orient_text_main_Derek03112021()
; skill (encrypt "C:/skill/check_orient_text_v1.il" "C:/skill/check_orient_text_v1.ile")
; (load "check_orient_text_v1.ile")
; (load "check_orient_text_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup