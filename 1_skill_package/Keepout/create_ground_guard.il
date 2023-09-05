;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 8/31/2020 - _Derek08312020
; Introduction:
;	1. create ground guard along with outline or line( other segments)
;	2. parameter:
;		1. net_name( GND relavent)
;		2. extension from line(+:append/-:shrink)
;		3. padstack: get ground padstack from grounf netclass via list
;		4. Max Pitch:
;		5. bandwidth: default value will be the pad diameter of padstack, otherwise, it has to be bigger
;	3. execution:
;		1. create by outline
;		2. create by line
;		3. remove GND guard
;		4. close
;	4. control:
;		1. all created object has property comment: "tool_create_ground_guard"
;		2. layers: all the conductor layer the selected padstack has been through
;	5. limitation:
;		1. wouldn't escape from pin/connector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek08312020()
	setq( _meter_count 0)
	setq( _meter_total 0)
	setq( _user_visible axlVisibleGet())
	
	;;;;;
	setq( _allegro_version axlVersion( 'version))
	setq( _outline_layer_16 "BOARD GEOMETRY/OUTLINE")
	setq( _outline_layer_17 "BOARD GEOMETRY/DESIGN_OUTLINE")
	setq( _outline_layer if( _allegro_version > 17 _outline_layer_17 _outline_layer_16))
	setq( _outline_object if( _allegro_version > 17 "SHAPES" "LINES"))
	
	setq( _cutout_layer_17 "BOARD GEOMETRY/CUTOUT")
	setq( _cutout_layer if( _allegro_version > 17 _cutout_layer_17 _outline_layer_16))
	setq( _cutout_object if( _allegro_version > 17 "SHAPES" "LINES"))
	
	;;;;;
	setq( _form_name "create_ground_guard.form")
	setq( _form_field_radio_outline "radio_outline")
	setq( _form_field_radio_cutout "radio_cutout")
	setq( _form_field_radio_shape "radio_shape")
	setq( _form_field_radio_line "radio_line")
	setq( _form_field_option_create_shape "option_create_shape")
	setq( _form_field_data_net_name "net_name")
	setq( _form_field_data_via "padstack")
	setq( _form_field_data_max_pitch "max_pitch")
	setq( _form_field_data_extension "extension")
	setq( _form_field_data_bandwidth "bandwidth")
	setq( _form_field_func_create "create")
	setq( _form_field_func_remove "remove_gnd_guard")
	setq( _form_field_func_close "close")
	
	
	setq( _form_popup_gnd_net_name "popup_gnd_net_name")
	setq( _form_popup_via_name "popup_padstack_name")
	
	setq( _form_popup_gnd_net_name_ls get_gnd_net_name_Derek08312020())
	setq( _form_popup_via_name_ls get_default_via_name_Derek08312020())
	
	;;;;;
	setq( _default_gap 20.0)
	setq( _this_create_stitch t)
	setq( _this_create_object _form_field_radio_outline)
	setq( _this_net_name car( _form_popup_gnd_net_name_ls))
	setq( _this_via_name car( _form_popup_via_name_ls))
	
	setq( _max_pitch_lbound _default_gap)
	setq( _this_max_pitch 55.0)
	setq( _max_pitch_ubound 120.0)
	
	setq( _bandwidth_lbound 6.0)
	setq( _this_bandwidth get_diameter_of_via_Derek08312020())
	setq( _bnadwidth_ubound 50.0)
	
	setq( _extension_lbound -100.0)
	setq( _this_extension get_extension_Derek08312020())
	setq( _extension_ubound 100.0)
	
	setq( _ground_guard_prop list( 'COMMENT "PRODUCT_OF_CREATE_GROUND_GUARD"))
	setq( _group_name_default "PRODUCT_OF_CREATE_GROUND_GUARD")
	setq( _group_name_format "PRODUCT_OF_CREATE_GROUND_GUARD[%s]")
	setq( _this_group_name_ls nil)
	
	;;;;;
	setq( _etch_class "ETCH")
	setq( _etch_subclass_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _etch_layer_ls mapcar( lambda( (x) strcat( _etch_class "/" x)) _etch_subclass_ls))
	
	;;;;;
	setq( _popup_done "Done")
	setq( _popup_cancel "Cancel")
	setq( _popup_method nil)
	setq( _cut_link_obj_pop axlUIPopupDefine( nil list( list( _popup_done 'popup_option_done_Derek08312020)
												list( _popup_cancel 'popup_option_cancel_Derek08312020))))
	
	
)

procedure( set_popup_Derek08312020( @key (no_cancel nil))
	prog( ( cut_link_obj_pop)
		axlUIPopupSet( nil)
		
		cut_link_obj_pop = _cut_link_obj_pop
		
		when( no_cancel
			cut_link_obj_pop = setof( x cut_link_obj_pop car( x) != _popup_cancel)
		)
		
		axlUIPopupSet( cut_link_obj_pop)
	)
)

procedure( popup_option_cancel_Derek08312020()
	let( ()
		_popup_method = _popup_cancel
		
		axlCancelEnterFun()
		
		axlUIAppMode( 'set "generaledit")
	)
)

procedure( popup_option_done_Derek08312020()
	let( ()
		_popup_method = _popup_done
		axlFinishEnterFun()
		
		axlUIPopupSet( nil)
		
		axlUIAppMode( 'set "generaledit")
	)
)

procedure( get_extension_Derek08312020( @key (bandwidth _this_bandwidth))
	prog( ( extension)
		extension = bandwidth / 2 + _default_gap
		extension = -extension
		
		return( extension)
	)
)

procedure( get_gnd_net_name_Derek08312020()
	prog( ( gnd_net_ls gnd_net_name_ls)
		gnd_net_ls = setof( x axlDBGetDesign()->nets index( x->name "GND"))
		gnd_net_name_ls = sort( gnd_net_ls~>name lambda( (a b) strlen( a) < strlen( b)))
		
		return( gnd_net_name_ls)
	)
)

procedure( get_default_via_name_Derek08312020()
	prog( ( via_name_ls via_id thru_via_name_ls)
		via_name_ls = axlCnsGetViaList( "DEFAULT")
		
		foreach( via_name via_name_ls
			via_id = axlLoadPadstack( via_name)
			when( via_id->isThrough
				thru_via_name_ls = append1( thru_via_name_ls via_name)
			)
		)
		
		return( thru_via_name_ls)
	)
)

procedure( get_diameter_of_via_Derek08312020( @key (via_name _this_via_name))
	; via_name = "VIA8_P22_ANTI30_SM14"
	prog( ( via_id pad_id box diameter)
		via_id = axlLoadPadstack( via_name)
		pad_id = axlDBGetPad( via_id "ETCH/TOP" "REGULAR")
		box = pad_id->bBox
		diameter = abs( caar( box) - caadr( box))
		
		return( diameter)
	)
)

procedure( to_speed_up_Derek08312020( yes)
	let( ()
		if( yes then
			axlDBControl( 'drcEnable nil)
			axlDBControl( 'dynamicFillMode nil)
		else
			axlDBControl( 'drcEnable t)
			axlDBControl( 'dynamicFillMode 'wysiwyg)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_form_fillin_Derek08312020( out_port title field last_y min_bound max_bound @key (start_x 2) (start_input_x 10) (input_length 16))
	let( ()
		fprintf( out_port "TEXT \"%s:\" \n" title)
		fprintf( out_port "FLOC %d %d\n" start_x last_y)
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" start_input_x last_y)
		fprintf( out_port "REALFILLIN %d %d\n" input_length input_length)
		fprintf( out_port "MIN %f\n" min_bound)
		fprintf( out_port "MAX %f\n" max_bound)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( write_form_enum_Derek08312020( out_port title field last_y pop_name @key (start_x 2) (start_input_x 10) (input_length 15))
	let( ()
		fprintf( out_port "TEXT \"%s:\" \n" title)
		fprintf( out_port "FLOC %d %d\n" start_x last_y)
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" start_input_x last_y)
		fprintf( out_port "ENUMSET %d\n" input_length)
		fprintf( out_port "OPTIONS prettyprint ownerdrawn\n")
		fprintf( out_port "POP \"%s\"\n" pop_name)
		fprintf( out_port "ENDFIELD\n")
	)
)

procedure( write_form_button_Derek08312020( out_port title field last_y @key (start_x 2) (button_width 26) (button_height 2))
	let( ()
		fprintf( out_port "FIELD %s\n" field)
		fprintf( out_port "FLOC %d %d\n" start_x last_y)
		fprintf( out_port "FSIZE %d %d\n" 50 50)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" title button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
	)
)

procedure( write_form_method_Derek01142019( out_port field name x y @optional (radio_label nil))
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

procedure( write_form_Derek08312020()
	prog( ( out_port)
		out_port = outfile( _form_name "w")
		unless( outportp( out_port) printf( "ERROR: write_form() - Fail to write file: %L\n" _form_name) return( nil))
		;;
		
		form_width = 29
		form_height = 100
		
		button_width = 26
		button_height = 2
		input_length = 16
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" form_width form_height)
		fprintf( out_port "HEADER \"Create GND Guard Panel\"\n")
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_popup_gnd_net_name)
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_popup_via_name)
		fprintf( out_port "TILE\n")
		
		start_x = 2
		start_input_x = 10
		last_y = 1
		
		radio_label = "create_object"
		radio_col1_x = start_x + 3
		radio_col2_x = start_x + 15
		
		last_y = last_y + 2
		
		write_form_method_Derek01142019( out_port _form_field_radio_outline "Outline" radio_col1_x last_y radio_label)
		write_form_method_Derek01142019( out_port _form_field_radio_cutout "Cutout" radio_col2_x last_y radio_label)
		
		last_y = last_y + 2
		
		write_form_method_Derek01142019( out_port _form_field_radio_shape "Shape" radio_col1_x last_y radio_label)
		write_form_method_Derek01142019( out_port _form_field_radio_line "Line" radio_col2_x last_y radio_label)
		
		last_y = last_y + 2
		
		write_form_method_Derek01142019( out_port _form_field_option_create_shape "GND Stitch" radio_col1_x last_y)
		
		last_y = last_y + 1
		
		group_width = button_width + 2
		fprintf( out_port "GROUP \"%s\"\n" "Create on Object")
		fprintf( out_port "FLOC %d %d\n" 1 1)
		fprintf( out_port "TSSIZE %d %d\n" group_width last_y)
		fprintf( out_port "ENDGROUP\n")
		
		last_y = last_y + 2
		
		write_form_enum_Derek08312020( out_port "Net Name" _form_field_data_net_name last_y _form_popup_gnd_net_name)
		
		last_y = last_y + 2
		
		write_form_enum_Derek08312020( out_port "Via Name" _form_field_data_via last_y _form_popup_via_name)
		
		last_y = last_y + 2
		
		write_form_fillin_Derek08312020( out_port "Max Pitch" _form_field_data_max_pitch last_y _max_pitch_lbound _max_pitch_ubound)
		
		last_y = last_y + 2
		
		write_form_fillin_Derek08312020( out_port "Bandwidth" _form_field_data_bandwidth last_y _bandwidth_lbound _bnadwidth_ubound)
		
		last_y = last_y + 2
		
		write_form_fillin_Derek08312020( out_port "Extension" _form_field_data_extension last_y _extension_lbound _extension_ubound)
		
		last_y = last_y + 3
		
		write_form_button_Derek08312020( out_port "Create / Select" _form_field_func_create last_y)
		
		last_y = last_y + 3
		
		;write_form_button_Derek08312020( out_port "Create by Segment" _form_field_func_create_by_segment last_y)
		;
		;last_y = last_y + 3
		
		write_form_button_Derek08312020( out_port "Remove All GND Guard" _form_field_func_remove last_y)
		
		last_y = last_y + 3
		
		write_form_button_Derek08312020( out_port "Close" _form_field_func_close last_y)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( set_form_Derek08312020( form)
	let( ()
		axlFormBuildPopup( form _form_popup_gnd_net_name _form_popup_gnd_net_name_ls)
		axlFormBuildPopup( form _form_popup_via_name _form_popup_via_name_ls)
		
		axlFormSetField( form _form_field_radio_outline t)
		axlFormSetField( form _form_field_option_create_shape _this_create_stitch)
		
		axlFormSetField( form _form_field_data_net_name _this_net_name)
		axlFormSetField( form _form_field_data_via _this_via_name)
		axlFormSetField( form _form_field_data_max_pitch _this_max_pitch)
		axlFormSetField( form _form_field_data_extension _this_extension)
		axlFormSetField( form _form_field_data_bandwidth _this_bandwidth)
		
		axlFormDefaultButton( form _form_field_func_create)
	)
)

procedure( update_gnd_shape_editable_Derek08312020( form editable)
	let( ()
		if( editable then
			axlFormSetFieldEditable( form _form_field_option_create_shape t)
			axlFormSetFieldEditable( form _form_field_data_bandwidth t)
			axlFormSetFieldEditable( form _form_field_data_extension t)
		else
			axlFormSetFieldEditable( form _form_field_option_create_shape nil)
			axlFormSetFieldEditable( form _form_field_data_bandwidth nil)
			axlFormSetFieldEditable( form _form_field_data_extension nil)
		)
	)
)

procedure( positive_extension_Derek08312020( form positive)
	let( ()
		_this_extension = if( positive abs( _this_extension) -abs( _this_extension))
		axlFormSetField( form _form_field_data_extension _this_extension)
	)
)

procedure( update_form_bandwidth_Derek08312020( form)
	let( ()
		_this_bandwidth = get_diameter_of_via_Derek08312020()
		axlFormSetField( form _form_field_data_bandwidth _this_bandwidth)
	)
)

procedure( update_form_extension_Derek08312020( form)
	let( ()
		_this_extension = get_extension_Derek08312020()
		axlFormSetField( form _form_field_data_extension _this_extension)
	)
)

procedure( get_group_name_Derek08312020()
	prog( ( group_name)
		cond(
			( zerop( length( _this_group_name_ls))
				return( _group_name_default)
			)
			( onep( length( _this_group_name_ls))
				group_name = car( _this_group_name_ls)
				return( group_name)
			)
			( t
				group_name = car( _this_group_name_ls)
				_this_group_name_ls = cdr( _this_group_name_ls)
				return( group_name)
			)
		)
	)
)

procedure( form_action_Derek08312020( form)
	let( ( field value)
		field = form->curField
		value = axlFormGetField( form field)
		
		cond(
			( field == _form_field_radio_outline && value
				_this_create_object = _form_field_radio_outline
				
				update_gnd_shape_editable_Derek08312020( form t)
				positive_extension_Derek08312020( form nil)
			)
			( field == _form_field_radio_cutout && value
				_this_create_object = _form_field_radio_cutout
				
				update_gnd_shape_editable_Derek08312020( form t)
				positive_extension_Derek08312020( form t)
			)
			( field == _form_field_radio_shape && value
				_this_create_object = _form_field_radio_shape
				
				update_gnd_shape_editable_Derek08312020( form t)
			)
			( field == _form_field_radio_line && value
				_this_create_object = _form_field_radio_line
				
				update_gnd_shape_editable_Derek08312020( form nil)
			)
			( field == _form_field_option_create_shape
				_this_create_stitch = value
			)
			;; ---------------------------------------------------------------------------------------------------------------------------
			( field == _form_field_data_net_name
				_this_net_name = value
			)
			( field == _form_field_data_via
				_this_via_name = value
				
				update_form_bandwidth_Derek08312020( form)
				update_form_extension_Derek08312020( form)
			)
			( field == _form_field_data_max_pitch
				_this_max_pitch = value
			)
			( field == _form_field_data_extension
				_this_extension = value
			)
			( field == _form_field_data_bandwidth
				_this_bandwidth = value
			)
			;; ---------------------------------------------------------------------------------------------------------------------------
			( field == _form_field_func_create
				printf( "INFO: form_action() - %s\n" field)
				to_speed_up_Derek08312020( t)
				
				poly_ls = create_polies_on_object_Derek08312020()
				foreach( poly poly_ls
					group_name = get_group_name_Derek08312020()
					create_ground_guard_on_object_Derek08312020( poly group_name)
				)
				
				axlVisibleLayer( "VIA CLASS/TOP" t)
				
				axlUIAppMode( 'set "generaledit")
			)
			( field == _form_field_func_remove
				printf( "INFO: form_action() - %s\n" field)
				
				delete_ground_guard_Derek08312020()
				
				axlUIAppMode( 'set "generaledit")
			)
			( field == _form_field_func_close
				printf( "INFO: form_action() - %s\n" field)
				to_speed_up_Derek08312020( nil)
				
				axlCancelEnterFun()
				axlFormClose( form)
			)
		)
		
		axlVisibleSet( _user_visible)
		printf( "INFO:- form_action() - Net: %s, Padstack: %s, Max Pitch: %f, Ext: %f, Bandwidth: %f\n"
				_this_net_name _this_via_name _this_max_pitch _this_extension _this_bandwidth)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( is_ground_prop_exists_Derek08312020( obj_id)
	prog( ( prop result)
		prop = car( axlDBGetProperties( obj_id))
		result = car( prop) == car( _ground_guard_prop) && car( prop) == car( _ground_guard_prop)
		
		return( result)
	)
)

procedure( delete_ground_guard_Derek08312020()
	let( ( obj_ls gnd_obj_ls)
		obj_ls = select_on_display_Derek08312020( "VIA CLASS/TOP" "VIAS" t)
		gnd_obj_ls = setof( x obj_ls is_ground_prop_exists_Derek08312020( x))
		
		axlDeleteObject( gnd_obj_ls)
		
		;conductor_layer_ls = get_conductor_layer_on_padstack( _this_via_name)
		obj_ls = select_on_display_Derek08312020( _etch_layer_ls "SHAPES" t)
		gnd_obj_ls = setof( x obj_ls is_ground_prop_exists_Derek08312020( x))
		
		axlDeleteObject( gnd_obj_ls)
		
		group_ls = setof( x axlDBGetDesign()->groups index( x->name _group_name_default))
		foreach( group_id group_ls
			printf( "INFO: delete_ground_guard() - delete group: %L\n" group_id->name)
			result = axlDBDisbandGroup( group_id)
		)
	)
)

procedure( get_poly_Derek08312020( object_id @key (extension _this_extension))
	; object_id = outline_id
	prog( ( poly)
		cond(
			( member( object_id->objType list( "polygon" "shape")) && extension
				poly = car( axlPolyFromDB( object_id))
				poly = car( axlPolyExpand( poly extension 'NONE))
			)
			( member( object_id->objType list( "polygon" "shape"))
				poly = car( axlPolyFromDB( object_id))
			)
			( object_id->objType == "path"
				path = axlDB2Path( object_id)
				poly = path
				; seg_ls = axlPathGetPathSegs( path)
				; xy_ls = mapcar( 'axlPathSegGetEndPoint seg_ls)
			)
		)
		
		return( poly)
	)
)

procedure( set_group_names_Derek08312020( obj_ls name_tag)
	let( ( group_distribution group_name type xy)
		_this_group_name_ls = nil
		unless( and( obj_ls name_tag) return( nil))
		
		name_tag = upperCase( name_tag)
		
		foreach( obj_id obj_ls
			xy = car( car( obj_id->segments)->startEnd)
			
			sprintf( group_distribution "%s:(%.0f %.0f)" name_tag car( xy) cadr( xy))
			sprintf( group_name _group_name_format group_distribution)
			_this_group_name_ls = append1( _this_group_name_ls group_name)
		)
	)
)

procedure( create_polies_on_object_Derek08312020()
	prog( ( obj_ls poly_ls)
		cond(
			( _this_create_object == _form_field_radio_outline
				obj_ls = select_on_display_Derek08312020( _outline_layer _outline_object t)
				set_group_names_Derek08312020( obj_ls "outline")
			)
			( _this_create_object == _form_field_radio_cutout
				obj_ls = select_on_display_Derek08312020( _cutout_layer _cutout_object t)
				set_group_names_Derek08312020( obj_ls "cutout")
			)
			( _this_create_object == _form_field_radio_shape
				axlUIConfirm( "Please select shapes and then right-click Done")
				obj_ls = select_on_display_Derek08312020( nil "SHAPES" nil)
				set_group_names_Derek08312020( obj_ls "shape")
			)
			( _this_create_object == _form_field_radio_line
				axlUIConfirm( "Please select lines and then right-click Done")
				obj_ls = select_on_display_Derek08312020( nil "LINES" nil)
				set_group_names_Derek08312020( obj_ls "line")
			)
		)
		
		unless( obj_ls
			printf( "INFO: create_polies_on_object_Derek08312020() - None of %s has been gotton on %s by %s\n" _this_create_object _outline_layer _outline_object)
			return( nil)
		)
		
		poly_ls = mapcar( 'get_poly_Derek08312020 obj_ls)
		
		return( poly_ls)
	)
)

procedure( get_xys_on_line_Derek08312020( xy_1 xy_2 max_pitch)
	; xy_1 = list(7952.756 196.850)
	; xy_2 = list(8267.717 196.850)
	; max_pitch = 55.0
	prog( ( distance number_of_pitch line_mid_xy pitch xy_ls uni_vector pitch_vector xy)
		distance = axlDistance( xy_1 xy_2)
		number_of_pitch = ceiling( distance / max_pitch)
		when( onep( number_of_pitch)
			line_mid_xy = axlGeoLineMidpoint( xy_1 xy_2)
			return( list( line_mid_xy))
		)
		
		pitch = distance / number_of_pitch
		
		xy_ls = list( xy_1)
		
		;;;;; first one and the last one will be set as xy_1 and xy_2
		uni_vector = axlMUniVector( xy_1 xy_2)
		pitch_vector = axlMXYMult( uni_vector pitch)
		xy = xy_1
		for( i 2 number_of_pitch
			xy = axlMXYAdd( xy pitch_vector)
			xy_ls = append1( xy_ls xy)
		)
		
		xy_ls = append1( xy_ls xy_2)
		
		return( xy_ls)
	)
)

procedure( is_xy_on_left_Derek08312020( left_xy right_xy)
	prog( ( is_left)
		is_left = car( left_xy) <= car( right_xy)
		
		return( is_left)
	)
)

procedure( get_arc_center_Derek08312020( xy_1 xy_2 radius)
	; when radius is positive: arc -> center
	; when radius is negative: center <- arc
	prog( ( abs_radius center_ls line_mid_xy center_xy)
		abs_radius = abs( radius)
		center_ls = axlGeoCircleCircleInt( xy_1 abs_radius xy_2 abs_radius)
		line_mid_xy = axlGeoLineMidpoint( xy_1 xy_2)
		 
		if( negativep( radius) then
			if( is_xy_on_left_Derek08312020( car( center_ls) line_mid_xy)
				center_xy = car( center_ls)
				center_xy = cadr( center_ls)
			)
		else
			if( is_xy_on_left_Derek08312020( line_mid_xy car( center_ls))
				center_xy = car( center_ls)
				center_xy = cadr( center_ls)
			)
		)
		
		return( center_xy)
	)
)

procedure( get_arc_degree_Derek08312020( xy_1 xy_2 center_xy is_cw)
	prog( ( start_radian end_radian start_degree end_degree degree)
		start_radian = axlGeoFindAngle( xy_1 center_xy)
		start_degree = axlRadToDeg( start_radian)
		
		end_radian = axlGeoFindAngle( xy_2 center_xy)
		end_degree = axlRadToDeg( end_radian)
		
		degree = end_degree - start_degree
		if( is_cw then
			;; clock-wise should present as negative degree
			when( degree > 0
				degree = 360.0 - degree
				degree = -degree
			)
		else
			;; counter-clock-wise should present as positive degree
			when( degree < 0
				degree = 360.0 + degree
			)
		)
		
		return( degree)
	)
)

procedure( get_arc_distance_Derek08312020( arc_degree radius)
	prog( ( circumference arc_distance)
		circumference = radius * 2 * axlPI
		arc_distance = circumference * arc_degree / 360.0
		
		arc_distance = abs( arc_distance)
		
		return( arc_distance)
	)
)

procedure( get_xys_on_arc_Derek08312020( xy_1 xy_2 radius max_pitch)
	;;;; do not create vias at the end of arc. 3 stands to 2 ends and a center xy, therefore, at least to have 3 number_of_xy to triger literation
	prog( ( center_xy arc_degree arc_distance number_of_xy pitch_degree is_cw xy xy_ls)
		center_xy = get_arc_center_Derek08312020( xy_1 xy_2 radius)
		is_cw = axlGeoIsShorterArcClockwise( xy_1 xy_2 center_xy)
		
		;;;;;
		arc_degree = get_arc_degree_Derek08312020( xy_1 xy_2 center_xy is_cw)
		arc_distance = get_arc_distance_Derek08312020( arc_degree radius)
		
		number_of_xy = ceiling( arc_distance / max_pitch)
		when( onep( number_of_xy) return( nil))
		pitch_degree = arc_degree / number_of_xy
		
		xy_ls = list( xy_1)
		xy = xy_1
		for( i 2 number_of_xy
			xy = axlGeoRotatePt( pitch_degree xy center_xy)
			xy_ls = append1( xy_ls xy)
		)
		xy_ls = append1( xy_ls xy_2)
		
		;printf( "apple get_xys_on_arc() - xy_1:%L xy_2:%L center_xy:%L is_cw:%L arc_degree:%L arc_distance:%L number_of_xy:%L pitch_degree:%L xy_ls:%L\n"
		;	xy_1 xy_2 center_xy  is_cw arc_degree arc_distance number_of_xy pitch_degree xy_ls)
		
		return( xy_ls)
	)
)

procedure( get_xys_on_poly_utility_Derek08312020( vertice_1 vertice_2 max_pitch)
	prog( ( xy_1 xy_2 radius xy_ls)
		xy_1 = car( vertice_1)
		xy_2 = car( vertice_2)
		radius = cadr( vertice_2)
		
		if( zerop( radius) then
			xy_ls = get_xys_on_line_Derek08312020( xy_1 xy_2 max_pitch)
		else
			xy_ls = get_xys_on_arc_Derek08312020( xy_1 xy_2 radius max_pitch)
		)
		
		return( xy_ls)
	)
)

procedure( remove_xy_less_distance_Derek08312020( xy_ls distance)
	prog( ( first_xy xy1 xy2 new_xy_ls )
		first_xy = car( xy_ls)
		
		while( dtpr( xy_ls)
			xy1 = car( xy_ls)
			xy2 = cadr( xy_ls)
			
			cond(
				( xy1 && xy2 && axlDistance( xy1 xy2) > distance
					new_xy_ls = append1( new_xy_ls xy1)
				)
				( xy1 && null( xy2) && axlDistance( xy1 first_xy) > distance
					new_xy_ls = append1( new_xy_ls xy1)
				)
			)
			
			xy_ls = cdr( xy_ls)
		)
		
		return( new_xy_ls)
	)
)

procedure( get_xys_on_poly_else_Derek08312020( poly)
	prog( ( vertice_ls total vertice_1 vertice_2 xy_ls total_xy_ls diameter)
		vertice_ls = poly->vertices
		total = length( vertice_ls) - 2
		
		for( i 0 total
			vertice_1 = nth( i vertice_ls)
			vertice_2 = nth( add1( i) vertice_ls)
			
			xy_ls = get_xys_on_poly_utility_Derek08312020( vertice_1 vertice_2 max_pitch)
			total_xy_ls = append( total_xy_ls xy_ls)
		)
		
		;;;;; do the last one
		vertice_1 = lastelem( vertice_ls)
		vertice_2 = car( vertice_ls)
		
		xy_ls = get_xys_on_poly_utility_Derek08312020( vertice_1 vertice_2 max_pitch)
		total_xy_ls = append( total_xy_ls xy_ls)
		
		return( total_xy_ls)
	)
)

procedure( is_circle_poly_Derek08312020( poly)
	prog( ( vertice_ls radius_ls is_circle)
		vertice_ls = poly->vertices
		unless( 4 == length( vertice_ls) return( nil))
		
		radius_ls = mapcar( lambda( (x) abs( cadr( x))) vertice_ls)
		
		;;;; this is a rectangle
		when( forall( x radius_ls zerop( x)) return( nil))
		
		is_circle = forall( x cdr( radius_ls) car( radius_ls) == x)
		
		return( is_circle)
	)
)

procedure( get_xys_on_poly_circle_Derek08312020( poly)
	prog( ( vertice_ls radius xy1 center_xy circumference number_of_xy pitch_degree xy xy_ls)
		vertice_ls = poly->vertices
		radius = cadar( vertice_ls)
		
		xy1 = caar( vertice_ls)
		xy3 = caaddr( vertice_ls)
		center_xy = axlGeoLineMidpoint( xy1 xy3)
		
		circumference = radius * 2 * axlPI
		number_of_xy = ceiling( circumference / _this_max_pitch)
		pitch_degree = 360.0 / number_of_xy
		
		xy = xy1
		for( i 1 number_of_xy
			xy = axlGeoRotatePt( pitch_degree xy center_xy)
			xy_ls = append1( xy_ls xy)
		)
		
		return( xy_ls)
	)
)

procedure( convert_path_to_vertices_Derek08312020( path)
	; path = axlDB2Path( car( axlGetSelSet()))
	prog( ( path_seg_ls xy center_xy radius clockwise vertice vertice_ls last_xy)
		path_seg_ls = axlPathGetPathSegs( path)
		
		foreach( path_seg path_seg_ls
			xy = path_seg->_endPoint
			center_xy = path_seg->_arcCenter
			
			if( center_xy then
				;;;; this is arc
				radius = axlDistance( xy center_xy)
				clockwise = path_seg->_arcClockwise
				arc_mid_xy = axlMidPointArc( list( last_xy xy) center_xy radius clockwise)
				
				when( is_xy_on_left_Derek08312020( center_xy arc_mid_xy)
					radius = -radius
				)
				
				vertice = list( xy radius)
			else
				;;;; this is line
				vertice = list( xy 0.0)
			)
			
			vertice_ls = append1( vertice_ls vertice)
			last_xy = xy
		)
		
		return( vertice_ls)
	)
)

procedure( get_xys_on_path_line_Derek08312020( path)
	prog( ( vertice_ls total vertice_1 vertice_2 xy_ls total_xy_ls)
		vertice_ls = convert_path_to_vertices_Derek08312020( path)
		total = length( vertice_ls) - 2
		
		for( i 0 total
			vertice_1 = nth( i vertice_ls)
			vertice_2 = nth( add1( i) vertice_ls)
			
			xy_ls = get_xys_on_poly_utility_Derek08312020( vertice_1 vertice_2 max_pitch)
			total_xy_ls = append( total_xy_ls xy_ls)
		)
		
		return( total_xy_ls)
	)
)

procedure( get_xys_on_poly_Derek08312020( poly @key (max_pitch _this_max_pitch))
	prog( ( vertice_ls total vertice_1 vertice_2 xy_ls total_xy_ls diameter)
		cond(
			( axlIsPolyType( poly)
				printf( "INFO: get_xys_on_poly() - generate xy list from poly object\n")
				total_xy_ls = get_xys_on_poly_else_Derek08312020( poly)
				
			)
			( is_circle_poly_Derek08312020( poly)
				printf( "INFO: get_xys_on_poly() - generate xy list from circle object\n")
				total_xy_ls = get_xys_on_poly_circle_Derek08312020( poly)
			)
			( t
				printf( "INFO: get_xys_on_poly() - generate xy list from path object\n")
				path = poly
				total_xy_ls = get_xys_on_path_line_Derek08312020( path)
			)
		)
		
		;;;; remove xy if the distance between each xy is less than pad diameter
		printf( "INFO: get_xys_on_poly() - via xy list: %L\n" total_xy_ls)
		
		diameter = get_diameter_of_via_Derek08312020()
		total_xy_ls = remove_xy_less_distance_Derek08312020( total_xy_ls diameter)
		
		return( total_xy_ls)
	)
)

procedure( patch_property_Derek08312020( obj_id)
	prog( ()
		unless( obj_id return( nil))
		obj_id = caar( axlDBAddProp( obj_id _ground_guard_prop))
		
		return( obj_id)
	)
)

procedure( run_meter_Derek08312020( stage message)
	let( ( percentage meter_message)
		caseq( stage
			( 'init
				when( zerop( _meter_total)
					_meter_total = message
				)
			)
			( 'start
				axlMeterCreate( message "" t)
			)
			( 'run
				(unless axlMeterIsCancelled()
					percentage = 100 * ++_meter_count / _meter_total
					sprintf( meter_message "[%.3d/%.3d] %s" _meter_count _meter_total message)
					axlMeterUpdate( percentage meter_message)
				)
			)
			( 'close
				axlMeterDestroy()
			)
		)
	)
)

procedure( get_meter_total_Derek08312020( total)
	prog( ()
		when( _this_create_stitch
			total += length( _etch_subclass_ls)
		)
		
		return( total)
	)
)

procedure( place_via_on_poly_Derek08312020( poly @key (via_name _this_via_name) (net_name _this_net_name))
	; poly = get_poly_Derek08312020( car( get_outline_Derek08312020()))
	; xy_ls = get_xys_on_poly_Derek08312020( poly)
	; path = axlPathStart( append1( xy_ls car( xy_ls)) 3.0)
	; axlDBCreatePath( path "BOARD GEOMETRY/SILKSCREEN_TOP" 'line )
	prog( ( xy_ls via_id new_via_ls)
		via_id = axlLoadPadstack( via_name)
		xy_ls = get_xys_on_poly_Derek08312020( poly)
		
		run_meter_Derek08312020( 'init get_meter_total_Derek08312020( length( xy_ls)))
		run_meter_Derek08312020( 'start "Create GND Guard Meter")
		
		foreach( xy xy_ls
			run_meter_Derek08312020( 'run sprintf( nil "Create via at %L" xy))
			
			new_via_id = car( axlDBCloak( 'axlDBCreateVia( via_id xy net_name)))
			new_via_ls = append1( new_via_ls new_via_id)
		)
		
		new_via_ls = mapcar( 'patch_property_Derek08312020 new_via_ls)
		
		return( new_via_ls)
	)
)

procedure( create_ring_shapes_Derek08312020( poly @key (bandwidth _this_bandwidth)
									(via_name _this_via_name)
									(net_name _this_net_name)
									(layer_ls _etch_layer_ls))
	prog( ( extension outer_poly inner_poly ring_poly conductor_layer_ls shape_id new_shape_ls)
		extension = bandwidth / 2
		outer_poly = car( axlPolyExpand( poly extension 'NONE))
		inner_poly = car( axlPolyExpand( poly -extension 'NONE))
		ring_poly = car( axlPolyOperation( outer_poly inner_poly 'ANDNOT))
		
		;conductor_layer_ls = get_conductor_layer_on_padstack( via_name)
		foreach( layer layer_ls
			run_meter_Derek08312020( 'run sprintf( nil "Create shape on %s" layer))
			
			shape_id = car( axlDBCloak( 'axlDBCreateShape( ring_poly t layer net_name) 'shape))
			new_shape_ls = append1( new_shape_ls shape_id)
		)
		
		new_shape_ls = mapcar( 'patch_property_Derek08312020 new_shape_ls)
		
		return( new_shape_ls)
	)
)

procedure( put_group_members_Derek08312020( group_name obj_ls)
	prog( ( group_id)
		printf( "INFO: put_group_members() - put members to a group: %L{%L}\n" group_name obj_ls~>objType)
		
		group_id = car( setof( x axlDBGetDesign()->groups group_name == x->name))
		if( group_id then
			result = axlDBAddGroupObjects( group_id obj_ls)
			unless( result printf( "WARNING: put_group_members() - Fail to add member to group: %L\n" group_name))
		else
			group_id = axlDBCreateGroup( group_name "generic" obj_ls)
		)
		
		axlDBRefreshId( nil)
		
		return( group_id)
	)
)

procedure( create_ground_guard_on_object_Derek08312020( poly group_name)
	let( ()
		cond(
			( _this_create_object == _form_field_radio_outline
				new_via_ls = place_via_on_poly_Derek08312020( poly)
				
				when( _this_create_stitch
					new_shape_ls = create_ring_shapes_Derek08312020( poly)
					put_group_members_Derek08312020( group_name new_shape_ls)
				)
			)
			( _this_create_object == _form_field_radio_cutout
				new_via_ls = place_via_on_poly_Derek08312020( poly)
				
				when( _this_create_stitch
					new_shape_ls = create_ring_shapes_Derek08312020( poly)
					put_group_members_Derek08312020( group_name new_shape_ls)
				)
			)
			( _this_create_object == _form_field_radio_shape
				new_via_ls = place_via_on_poly_Derek08312020( poly)
				
				when( _this_create_stitch
					new_shape_ls = create_ring_shapes_Derek08312020( poly)
					put_group_members_Derek08312020( group_name new_shape_ls)
				)
			)
			( _this_create_object == _form_field_radio_line
				new_via_ls = place_via_on_poly_Derek08312020( poly)
			)
		)
		
		put_group_members_Derek08312020( group_name new_via_ls)
		
		run_meter_Derek08312020( 'close nil)
	)
)

procedure( set_display_Derek08312020( layers)
	prog( ()
		unless( layers return( nil))
		when( stringp( layers) layers = list( layers))
		
		axlVisibleDesign( nil)
		foreach( layer layers
			axlVisibleLayer( layer t)
		)
		
		return( t)
	)
)

procedure( set_find_filter_Derek08312020( objects)
	let( ( option_ls)
		when( stringp( objects) objects = list( objects))
		
		option_ls = list( "NOALL")
		when( dtpr( objects)
			option_ls = append( option_ls objects)
		)
		
		axlSetFindFilter( ?enabled option_ls ?onButtons option_ls)
	)
)

procedure( select_on_display_Derek08312020( layers objects select_all)
	prog( ( obj_ls)
		when( layers set_display_Derek08312020( layers))
		when( objects set_find_filter_Derek08312020( objects))
		
		if( select_all then
			axlAddSelectAll()
			obj_ls = axlGetSelSet()
			axlClearSelSet()
		else
			set_popup_Derek08312020()
			
			while( axlSelect()
				set_popup_Derek08312020()
				obj_ls = axlGetSelSet()
				total = axlGetSelSetCount()
				;axlClearSelSet()
				
				printf( "INFO: select_on_display() - [%d] things have been selected per %L\n" total list( _this_create_object))
			)
			
			unless( _popup_method == _popup_done
				obj_ls = nil
			)
			
			axlUIPopupSet( nil)
		)
		
		set_find_filter_Derek08312020( nil)
		
		return( obj_ls)
	)
)

procedure( create_ground_guard_main_Derek08312020()
	prog( ()
		(unless axlOKToProceed() println( "Please done the current function to execute this function") (return nil))
		;;
		
		init_Derek08312020()
		unless( _allegro_version > 17
			printf( "HALT: create_ground_guard_main() - This tool does not support this Allegro version: %f\n" _allegro_version)
			return( nil)
		)
		
		unless( dtpr( _form_popup_gnd_net_name_ls)
			printf( "WARNING: create_ground_guard_main() - No GND net has been found")
			return( nil)
		)
		
		unless( dtpr( _form_popup_via_name_ls)
			printf( "WARNING: create_ground_guard_main() - No padstack has been defined in DEFAULT physical constraint set")
			return( nil)
		)
		
		;;;;;
		write_form_Derek08312020()
		form = axlFormCreate( gensym() _form_name '("east" "outer") 'form_action_Derek08312020 t)
		set_form_Derek08312020( form)
		axlFormDisplay( form)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "create_ground_guard" 'create_ground_guard_main_Derek08312020)
; create_ground_guard_main_Derek08312020()
; skill (encrypt "C:/skill/create_ground_guard_v1.il" "C:/skill/create_ground_guard_v1.ile")
; (load "create_ground_guard_v1.ile")
; (load "create_ground_guard_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup