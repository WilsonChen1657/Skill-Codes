;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 11/11/2020 - _Derek20201111
; Introduction: add testpoint aid tool
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init_Derek20201111()
	setq( _unit car( axlDBGetDesignUnits()))
	setq( _mil_by_mm 39.37)
	
	setq( _form_filename "add_testpoint.form")
	setq( _form_key_data_grid "data_grid")
	setq( _form_key_data_grid_net_col 1)
	
	setq( _form_key_status_fillin "status_fillin")
	setq( _form_key_no_tp_cnt_fillin "no_tp_cnt_fillin")
	setq( _form_key_total_net_fillin "total_net_fillin")
	setq( _form_key_go_to_net_button "go_to_net_button")
	setq( _form_key_drop_button "drop_button")
	setq( _form_key_next_button "next_button")
	setq( _form_key_add_no_test_button "add_no_test_button")
	setq( _form_key_highlight_button "highlight_button")
	setq( _form_key_close "close")
	
	setq( _default_dropped_netname_ls nil)
	setq( _user_dropped_netname_ls nil)
	setq( _no_test_netname_ls nil)
	setq( _remain_netname_ls nil)
	
	setq( _current_netname nil)
	setq( _current_tp_data_ls nil)
	setq( _current_tp_th 0)
	;;;;; default start from row 1
	setq( _current_grid_row 1)
	
	;;;;; data used in program globally
	
	setq( _system_id 0)
	
	setq( _etch_top "ETCH/TOP")
	setq( _etch_bottom "ETCH/BOTTOM")
	setq( _pin_top "PIN/TOP")
	setq( _pin_bottom "PIN/BOTTOM")
	setq( _via_top "VIA CLASS/TOP")
	setq( _via_bottom "VIA CLASS/BOTTOM")
	setq( _etch_surface_ls list( _etch_top _etch_bottom))
	setq( _top_layer_ls list( _etch_top _pin_top _via_top))
	setq( _bottom_layer_ls list( _etch_bottom _via_bottom _pin_bottom))
	
	setq( _min_tp_on_clineseg_len if( _unit == "mils" 20.0 20.0 / _mil_by_mm))
	setq( _string_length 35)
	setq( _no_test_prop 'NO_TEST)
	setq( _highlighting nil)
	setq( _max_tp_on_path 5)
	setq( _max_tp_on_via 5)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_form_button_Derek20201111( out_port field name x y button_width @optional (button_height 2))
	let( ()
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" name button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
	)
)

procedure( write_form_grid_Derek20201111( out_port field x y width height @optional (top_size 2) (side_size 5))
	let( ()
		fprintf( out_port "GRID %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "FSIZE %d %d\n" width height)
		fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
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

procedure( write_form_text_Derek20201111( out_port name x y)
	let( ()
		fprintf( out_port "TEXT \"%s\" \n" "Completed Percentage:")
		fprintf( out_port "FLOC %d %d\n" start_x y)
		fprintf( out_port "ENDTEXT\n")
	)
)

procedure( write_form_strfillin_Derek20201111( out_port field x y fillin_length)
	let( ()
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" x y)
		fprintf( out_port "STRFILLIN %d %d\n" fillin_length fillin_length  * 2)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( write_form_Derek20201111()
	prog( ( out_port)
		a = lambda( (x) x+1)
		out_port = outfile( _form_filename "w")
		unless( outportp( out_port) println( "ERROR: write_form()  - Fail to create form write port") return( nil))
		;;
		
		form_width = 40
		form_height = 100
		
		grid_width = form_width - 2
		grid_height = 30
		
		start_x = 1
		y = 1
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" form_width form_height)
		fprintf( out_port "HEADER \"%s\"\n" "Add Testpoint")
		fprintf( out_port "TILE\n")
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		write_form_grid_Derek20201111( out_port _form_key_data_grid start_x y grid_width grid_height)
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		y = y + grid_height
		
		fillin_x = 18
		fillin_length = 20
		
		write_form_text_Derek20201111( out_port "Completed Percentage:" start_x y)
		write_form_strfillin_Derek20201111( out_port _form_key_status_fillin fillin_x y fillin_length)
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		y += 3
		
		grid_width_d2 = grid_width / 2
		grid_width_d3 = grid_width / 3
		grid_width_2d3 = grid_width * 2 / 3
		
		write_form_button_Derek20201111( out_port _form_key_go_to_net_button "Go to Net" start_x y grid_width_d3)
		write_form_button_Derek20201111( out_port _form_key_next_button "Next Net" (start_x + grid_width_d3 + 1) y (grid_width_2d3 + 1))
		
		y += 4
		
		write_form_button_Derek20201111( out_port _form_key_add_no_test_button "Add NO_TEXT Prop" start_x y grid_width_d2)
		write_form_button_Derek20201111( out_port _form_key_drop_button "Drop Selected Net" (start_x + grid_width_d2 + 1) y grid_width_d2)
		
		y += 4
		
		write_form_button_Derek20201111( out_port _form_key_highlight_button "Highlight / DeHighlight" start_x y grid_width_2d3)
		write_form_button_Derek20201111( out_port _form_key_close "Close" (start_x + grid_width_2d3 + 1) y (grid_width_d3 + 1))
		
		;;;;; ---------------------------------------------------------------------------------------------------------------------
		
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( set_form_grid_text_col_Derek20201111( out_form field head_text @optional (col_width nil))
	let( ( options)
		options = make_formGridCol()
		options->colWidth = col_width
		options->headText = head_text
		
		options->fieldType = 'TEXT
		options->fieldLength = _string_length
		
		axlFormGridInsertCol( out_form field options)
	)
)

procedure( insert_form_grid_cell_Derek20201111( out_form grid_field row value @optional (col _form_key_data_grid_net_col))
	let( ( cell)
		cell = axlFormGridNewCell()
		cell->row = row
		cell->col = col
		cell->value = value
		
		axlFormSetField( out_form grid_field cell)
		
		cell = axlFormGridNewCell()
		cell->row = row
		cell->col = 0
		cell->value = row
		
		axlFormSetField( out_form grid_field cell)
		
		axlFormGridUpdate( out_form grid_field)
	)
)

procedure( set_form_status_Derek20201111( out_form)
	let( ( total_ls total remain percentage status_line)
		total_ls = mapcar( 'length list( _default_dropped_netname_ls _user_dropped_netname_ls _no_test_netname_ls _remain_netname_ls))
		total = apply( 'plus total_ls)
		remain = length( _remain_netname_ls)
		
		percentage = 100 - float( remain) / total * 100
		
		sprintf( status_line "%.2f%% - Remain(%d/%d)" percentage remain total)
		
		axlFormSetField( out_form _form_key_status_fillin status_line)
	)
)

procedure( new_form_grid_rows_Derek20201111( out_form)
	let( ()
		set_netname_Derek20201111()
		clear_form_grid_rows_Derek20201111( out_form)
		insert_form_grid_rows_Derek20201111( out_form)
		
		set_form_status_Derek20201111( out_form)
	)
)

procedure( clear_form_grid_rows_Derek20201111( out_form)
	let( ( total_row)
		total_row = length( _remain_netname_ls) + 1
		axlFormGridDeleteRows( out_form _form_key_data_grid 1 total_row)
		
		axlFormGridUpdate( out_form _form_key_data_grid)
	)
)

procedure( insert_form_grid_rows_Derek20201111( out_form)
	let( ( total_row net_name)
		total_row = length( _remain_netname_ls)
		
		axlFormGridInsertRows( out_form _form_key_data_grid 1 total_row)
		
		for( row 1 total_row
			net_name = nth( sub1( row) _remain_netname_ls)
			insert_form_grid_cell_Derek20201111( out_form _form_key_data_grid row net_name)
		)
		
		axlFormGridUpdate( out_form _form_key_data_grid)
	)
)

procedure( set_form_Derek20201111( out_form)
	let( ()
		axlFormDefaultButton( out_form _form_key_go_to_net_button)
		
		set_form_grid_text_col_Derek20201111( out_form _form_key_data_grid "Net Name")
		
		set_netname_Derek20201111()
		insert_form_grid_rows_Derek20201111( out_form)
		
		axlFormSetFieldEditable( out_form _form_key_status_fillin nil)
		
		axlFormGridEvents( out_form _form_key_data_grid 'mrowselect)
		
		axlFormGridUpdate( out_form _form_key_data_grid)
		
		set_form_status_Derek20201111( out_form)
	)
)

procedure( get_current_netname_Derek20201111()
	prog( ( net_name)
		net_name = nth( sub1( _current_grid_row) _remain_netname_ls)
		return( net_name)
	)
)

procedure( select_form_grid_row_Derek20201111( out_form)
	prog( ( net_name)
		net_name = get_current_netname_Derek20201111()
		unless( stringp( net_name) return( nil))
		printf( "INFO: select_form_grid_row() - You are activating net[%s]\n" net_name)
		
		axlFormGridSetSelectRows( out_form _form_key_data_grid 1 length( _remain_netname_ls) nil)
		axlFormGridSetSelectRows( out_form _form_key_data_grid _current_grid_row _current_grid_row t)
	)
)

procedure( run_form_close_Derek20201111( out_form)
	let( ()
		printf( "INFO: run_form_close() - Form is closed")
		
		axlFormClose( out_form)
		axlFinishEnterFun()
	)
)

procedure( form_action_Derek20201111( out_form)
	; axlFormGridSelected( out_form _form_key_data_grid)
	prog( ( field net_name net_id)
		_current_grid_row = car( axlFormGridSelected( out_form _form_key_data_grid)) || _current_grid_row
		field = out_form->curField
		
		when( field == _form_key_close
			run_form_close_Derek20201111( out_form)
		)
		
		select_form_grid_row_Derek20201111( out_form)
		
		net_name = get_current_netname_Derek20201111()
		unless( stringp( net_name)
			printf( "WARNING: form_action() - No net name is remained. Please re-open and check the dropped net, otherwise, you are done with TP adding session")
			return( nil)
		)
		
		set_form_status_Derek20201111( out_form)
		
		cond(
			( field == _form_key_data_grid
				printf( "INFO: form_action() - You are activating net[%s]\n" net_name)
			)
			( field == _form_key_go_to_net_button
				present_tp_data_Derek20201111( net_name)
				
				printf( "INFO: form_action() - Pressing net[%s] in grid" net_name)
			)
			( field == _form_key_next_button
				if( _current_grid_row < length( _remain_netname_ls)
					_current_grid_row++
					_current_grid_row = 1
				)
				
				select_form_grid_row_Derek20201111( out_form)
			)
			( field == _form_key_add_no_test_button
				net_id = axlDBFindByName( 'net net_name)
				axlDBAddProp( net_id list( _no_test_prop t))
				
				new_form_grid_rows_Derek20201111( out_form)
				
				select_form_grid_row_Derek20201111( out_form)
				
				printf( "INFO: form_action() - Added property[%s] to net[%s]. Net Name List has been updated\n" _no_test_prop net_name)
			)
			( field == _form_key_drop_button
				_user_dropped_netname_ls = append1( _user_dropped_netname_ls net_name)
				
				new_form_grid_rows_Derek20201111( out_form)
				
				printf( "INFO: form_action() - Drop net[%s]. Net Name List has been updated\n" net_name)
			)
			( field == _form_key_highlight_button
				highlight_nets_Derek20201111()
			)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_uni_system_id_Derek20201111()
	prog( ( id)
		sprintf( id "id_%d" _system_id++)
		id = stringToSymbol( id)
		
		return( id)
	)
)

procedure( get_subclass_Derek20201111( layer)
	prog( ( subclass)
		unless( stringp( layer) return( "TOP"))
		
		subclass = cadr( parseString( layer "/"))
		
		return( subclass)
	)
)

procedure( get_tp_via_data_Derek20201111( via_id)
	prog( ( data box subclass message)
		unless( via_id return( nil))
		;;
		
		box = via_id->bBox
		subclass = get_subclass_Derek20201111( car( via_id->startEnd))
		sprintf( message "You may want to set TP on the picked via on net[%s] on %s at %L" _current_netname subclass via_id->xy)
		
		data = get_uni_system_id_Derek20201111()
		data->box = box
		data->subclass = subclass
		data->message = message
		
		return( data)
	)
)

procedure( get_tp_path_data_Derek20201111( path_id)
	prog( ( data box subclass message)
		unless( path_id return( nil))
		;;
		
		box = path_id->bBox
		subclass = get_subclass_Derek20201111( path_id->layer)
		sprintf( message "You may want  to set TP on the picked cline segment on net[%s] on %s at %L" _current_netname subclass path_id->startEnd)
		
		data = get_uni_system_id_Derek20201111()
		data->box = box
		data->subclass = subclass
		data->message = message
		
		return( data)
	)
)

procedure( get_tp_pin_data_Derek20201111( pin_id)
	prog( ( data box subclass message)
		unless( pin_id return( nil))
		;;
		
		box = pin_id->bBox
		subclass = get_subclass_Derek20201111( car( pin_id->startEnd))
		sprintf( message "You may want to set TP on the picked pin peripheral on net[%s] on %s at %L" _current_netname subclass pin_id->xy)
		
		data = get_uni_system_id_Derek20201111()
		data->box = box
		data->subclass = subclass
		data->message = message
		
		return( data)
	)
)

procedure( get_seg_for_tp_Derek20201111( path_ls)
	prog( ( seg_ls cnt seg_id data_seg_ls)
		path_ls = setof( x path_ls member( x->layer _etch_surface_ls))
		
		foreach( path_id path_ls
			seg_ls = append( seg_ls path_id->segments)
		)
		
		;;;;; filter out
		seg_ls = setof( x seg_ls axlDistance( car( x->startEnd) cadr( x->startEnd)) > _min_tp_on_clineseg_len)
		seg_ls = setof( x seg_ls x->objType != "arc")
		
		seg_ls = sort( seg_ls lambda( (a b) axlDBGetLength( a) > axlDBGetLength( b)))
		
		cnt = 0
		while( cnt++ < _max_tp_on_path && dtpr( seg_ls)
			seg_id = car( seg_ls)
			data_seg_ls = append1( data_seg_ls seg_id)
			
			seg_ls = cdr( seg_ls)
		)
		
		return( data_seg_ls)
	)
)

procedure( get_via_for_tp_Derek20201111( via_ls pin_id)
	prog( ( pin_xy cnt via_id data_via_ls )
		pin_xy = pin_id->xy
		;via_ls = setof( x via_ls x->isThrough)
		
		via_ls = sort( via_ls lambda( (a b) axlDistance( a->xy pin_xy) > axlDistance( b->xy pin_xy)))
		
		cnt = 0
		while( cnt++ < _max_tp_on_via && dtpr( via_ls)
			via_id = car( via_ls)
			data_via_ls = append1( data_via_ls via_id)
			
			via_ls = cdr( via_ls)
		)
		
		return( data_via_ls)
	)
)

procedure( set_tp_data_Derek20201111( net_name)
	; net_id = car( axlGetSelSet())
	; _current_tp_data_ls: [[<box>,<message>], ...]
	prog( ( net_id children pin_ls path_ls via_ls tp_on_path_ls tp_on_via_ls tp_data_ls)
		when( net_name == _current_netname
			return( t)
		)
		
		_current_tp_th = 0
		_current_netname = net_name
		
		net_id = axlDBFindByName( 'net _current_netname)
		children = get_children_Derek20201111( net_id)
		
		;;;;;
		pin_ls = setof( x children x->objType == "pin")
		path_ls = setof( x children x->objType == "path")
		via_ls = setof( x children x->objType == "via")
		
		tp_on_path_ls = get_seg_for_tp_Derek20201111( path_ls)
		tp_on_via_ls = get_via_for_tp_Derek20201111( via_ls car( pin_ls))
		
		if( or( dtpr( tp_on_path_ls) dtpr( tp_on_via_ls)) then
			tp_on_path_ls = mapcar( 'get_tp_path_data_Derek20201111 tp_on_path_ls)
			tp_on_via_ls = mapcar( 'get_tp_via_data_Derek20201111 tp_on_via_ls)
			tp_data_ls = append( tp_on_path_ls tp_on_via_ls)
		else
			tp_data_ls = mapcar( 'get_tp_pin_data_Derek20201111 pin_ls)
		)
		
		_current_tp_data_ls = tp_data_ls
		
		printf( "INFO: set_tp_data() - There are [%d] possible spot for TP has been found\n" length( _current_tp_data_ls))
		
		return( t)
	)
)

procedure( get_tp_data_Derek20201111()
	prog( ( data)
		unless( _current_tp_data_ls return( nil))
		;;
		
		data = nth( _current_tp_th++ _current_tp_data_ls)
		
		when( _current_tp_th == length( _current_tp_data_ls)
			_current_tp_th = 0
		)
		
		return( data)
	)
)

procedure( display_layer_Derek20201111( subclass)
	let( ()
		when( subclass == "TOP"
			foreach( layer _top_layer_ls axlVisibleLayer( layer t))
			foreach( layer _bottom_layer_ls axlVisibleLayer( layer nil))
			
			axlVisibleUpdate( t)
		)
		
		when( subclass == "BOTTOM"
			foreach( layer _top_layer_ls axlVisibleLayer( layer nil))
			foreach( layer _bottom_layer_ls axlVisibleLayer( layer t))
			
			axlVisibleUpdate( t)
		)
	)
)

procedure( zoom_to_box_Derek20201111( box)
	let( ()
		axlZoomPoints( 0 car( box) cadr( box))
		axlZoomCenter( 0 axlMidPointLine( box))
	)
)

procedure( present_tp_data_Derek20201111( net_name)
	let( ( data box message th)
		set_tp_data_Derek20201111( net_name)
		
		;;;;;
		data = get_tp_data_Derek20201111()
		
		display_layer_Derek20201111( data->subclass)
		zoom_to_box_Derek20201111( data->box)
		
		th = if( zerop( _current_tp_th) length( _current_tp_data_ls) _current_tp_th)
		printf( "INFO: present_tp_data() - composition: (%d/%d)\n" th length( _current_tp_data_ls))
		printf( "\t%s\n" data->message)
	)
)

procedure( highlight_nets_Derek20201111()
	let( ( net_ls)
		net_ls = mapcar( lambda( (x) axlDBFindByName( 'net x)) _remain_netname_ls)
		
		_highlighting = !_highlighting
		
		if( _highlighting then
			axlHighlightObject( net_ls)
		else
			axlDehighlightObject( net_ls)
		)
	)
)

procedure( get_children_Derek20201111( net_id)
	; net_id = car( net_ls)
	; net_id = car( axlGetSelSet())
	prog( ( children)
		foreach( branch net_id->branches
			children = append( children branch->children)
		)
		
		return( children)
	)
)

procedure( is_contain_prop_Derek20201111( obj_id key)
	prog( ( properties key_value value)
		properties = axlDBGetProperties( obj_id)
		key_value = assq( key properties)
		value = cadr( key_value)
		
		return( value)
	)
)

procedure( set_netname_Derek20201111()
	let( ()
		set_dropped_netname_Derek20201111()
		set_no_test_netname_Derek20201111()
		set_without_tp_netname_Derek20201111()
	)
)

procedure( set_dropped_netname_Derek20201111()
	let( ( not_net_ls net_ls)
		not_net_ls = axlDBGetDesign()->nets
		
		;not_net_ls = setof( x not_net_ls !index( x->name || "GND" "GND"))
		;not_net_ls = setof( x not_net_ls !index( x->name || "PWR" "PWR"))
		;not_net_ls = setof( x not_net_ls !exists( y get_children_Derek20201111( x) y->objType == "shape"))
		not_net_ls = setof( x not_net_ls !exists( y get_children_Derek20201111( x) stringp( y->testPoint)))
		not_net_ls = setof( x not_net_ls !zerop( x->nBranches))
		
		net_ls = axlDBGetDesign()->nets
		net_ls = setof( x net_ls !memq( x not_net_ls))
		
		_default_dropped_netname_ls = sort( net_ls~>name 'alphalessp)
	)
)

procedure( set_no_test_netname_Derek20201111()
	let( ( net_ls)
		net_ls = axlDBGetDesign()->nets
		
		net_ls = setof( x net_ls is_contain_prop_Derek20201111( x _no_test_prop))
		
		_no_test_netname_ls = sort( net_ls~>name 'alphalessp)
	)
)

procedure( set_without_tp_netname_Derek20201111()
	; a = car( axlGetSelSet())
	let( ( net_ls)
		net_ls = axlDBGetDesign()->nets
		
		;;;;; without NO_TEST prop
		net_ls = setof( x net_ls !member( x->name _no_test_netname_ls))
		
		;;;;; remove the dropped net
		net_ls = setof( x net_ls !member( x->name _default_dropped_netname_ls))
		net_ls = setof( x net_ls !member( x->name _user_dropped_netname_ls))
		
		_remain_netname_ls = sort( net_ls~>name 'alphalessp)
	)
)

procedure( add_testpoint_main_Derek20201111()
	prog( ()
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		
		when( zerop( length( axlDBGetDesign()->nets))
			printf( "ERROR: add_testpoint_main() - No net has been found on this board")
		)
		
		init_Derek20201111()
		
		write_form_Derek20201111()
		out_form = axlFormCreate( gensym() _form_filename '("east" "outer") 'form_action_Derek20201111 t)
		set_form_Derek20201111( out_form)
		axlFormDisplay( out_form)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "add_testpoint" 'add_testpoint_main_Derek20201111)
; add_testpoint_main_Derek20201111()
; skill (encrypt "c:/skill/add_testpoint_v1.il" "c:/skill/add_testpoint_v1.ile")
; (load "add_testpoint_v1.ile")
; (load "add_testpoint_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup