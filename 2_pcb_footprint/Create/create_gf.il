/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/04/19                                                      #
#  Reference: locker, utility_program, footprint_utility_program               #
#  Purpose:                                                                    #
#       To create Gold Finger symbol according to DATASHEET and PAD            #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_creategf()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	setq( _create_setting_table makeTable( "create_setting" nil))
	setq( _delete_setting_table makeTable( "delete_setting" nil))
	
	setq( _form_key_pb "setup_place_bound")
	setq( _form_key_sm "setup_soldermask")
	setq( _form_key_np "setup_no_probe")
	setq( _form_key_via_ko "setup_via_ko")
	setq( _form_key_pkg_ko "setup_pkg_ko")
	setq( _form_key_an "setup_assembly_notes")
	setq( _form_key_an_angle "setup_assembly_notes_angle")
	setq( _form_key_an_angle_tol_plus "setup_assembly_notes_angle_tolernace_plus")
	setq( _form_key_an_angle_tol_minus "setup_assembly_notes_angle_tolernace_minus")
	setq( _form_key_an_bevel_length "setup_assembly_notes_bevel_length")
	setq( _form_key_an_bevel_tol_plus "setup_assembly_notes_bevel_length_tolernace_plus")
	setq( _form_key_an_bevel_tol_minus "setup_assembly_notes_bevel_length_tolernace_minus")
	setq( _form_key_an_thickness "setup_assembly_notes_thickness")
	setq( _form_key_an_thickness_tol_plus "setup_assembly_notes_thickness_tolernace_plus")
	setq( _form_key_an_thickness_tol_minus "setup_assembly_notes_thickness_tolernace_minus")

	setq( _form_key_an_unit "setup_assembly_notes_unit")
	setq( _form_key_ref_layer "setup_ref_layer")
	setq( _form_key_ref_types "setup_ref_types")
	setq( _form_key_pin1_mark "setup_pin1_mark")
	setq( _form_key_pin1_mark_size "setup_pin1_mark_size")
	setq( _form_key_pin_note "setup_pin_note")
	setq( _form_key_pin_note_layer "pin_note_layers")
	setq( _form_key_symbol_note "setup_symbol_note")
	setq( _form_key_pin_number "setup_pin_number")
	setq( _form_option_key_ls list( _form_key_pb _form_key_sm _form_key_np _form_key_via_ko _form_key_pkg_ko _form_key_an _form_key_ref_layer 
								_form_key_pin1_mark _form_key_pin_note _form_key_symbol_note))
	setq( _form_all_key_ls append( _form_option_key_ls list( _form_key_an_unit _form_key_an_angle _form_key_an_angle_tol_plus _form_key_an_angle_tol_minus 
										_form_key_an_bevel_length _form_key_an_bevel_tol_plus _form_key_an_bevel_tol_minus
										_form_key_an_thickness _form_key_an_thickness_tol_plus _form_key_an_thickness_tol_minus
										_form_key_ref_types _form_key_pin1_mark_size _form_key_pin_note_layer)))

	setq( _run_create nil)
	setq( _run_delete nil)
	setq( _prop_title "gf_title")
	setq( _prop_angle "gf_angle")
	setq( _prop_bevel "gf_bevel_length")
	setq( _prop_thickness "gf_thickness")
	setq( _prop_bevel_sub "gf_bevel_length_sub")
	setq( _prop_thickness_sub "gf_thickness_sub")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_creategf()
	prog( ( result)
		unless( Main_footprintlocker()
			return( nil)
		)
		
		Init_creategf()
		LoadForm_creategf()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CheckPCBEdgeNote_creategf()
	prog( ( layer target_text result)
		layer = _layer_pcb_edge
		printf( _check_msg_format "PCB Edge Note")
		
		result = axlVisibleLayer( layer t)
		if( result then
			line_id = GetPcbEdgeLine_creategf()
			result = line_id->bBox
			unless( result
				sprintf( msg "PCB_EDGE line not found on layer:%s\n" _layer_pcb_edge)
			)

			when( result
				pcb_edge_center = axlMidPointLine( line_id->bBox)
				pin_box = axlDBGetExtents( axlDBGetDesign()->pins nil)
				pin_center = axlMidPointLine( pin_box)
				; pin box mid point must lower then pcb_edge box mid point
				; pin box must smaller then pcb_edge box
				result = and( greaterp( cadr( pcb_edge_center) cadr( pin_center))
							GreaterBox_creategf( line_id->bBox pin_box))
				unless( result
					msg_ls = nil
					msg_ls = append1( msg_ls "PCB_EDGE line's box should bigger then PIN's box,")
					msg_ls = append1( msg_ls "and PIN's center should lower then PDB_EDGE box's center.")
					msg_ls = append1( msg_ls "Please check again!")
					msg = buildString( msg_ls "\n")
					printf( msg)
					axlUIConfirm( msg)
					return( nil)
				)
			)
		else
			sprintf( msg "Layer:%s not found\n" _layer_pcb_edge)
		)

		unless( result
			msg = strcat( msg "Do you want to load PCB_EDGE.clp?")
			when( axlUIYesNo( msg)
				CreatePCBEdge_footprintutilityprogram()
			)		
		)
		
		return( result)
	)
)

procedure( GreaterBox_creategf( box_a box_b)
	prog( ( a_point_1 a_point_2 b_point_1 b_point_2)
		a_point_1 = car( box_a)
		a_point_2 = cadr( box_a)
		b_point_1 = car( box_b)
		b_point_2 = cadr( box_b)
		result = and( lessp( car( a_point_1) car( b_point_1))
					lessp( cadr( a_point_1) cadr( b_point_1))
					greaterp( car( a_point_2) car( b_point_2))
					greaterp( cadr( a_point_2) cadr( b_point_2)))
		return( result)
	)
)
/*
	1----------------2
	|                |
	|                |
	4----------------3
*/
procedure( GetPlaceBoundPoints_creategf()
	prog( ( line_id point_1 point_2 point_3 point_4 point_ls pin_box)
		line_id = GetPcbEdgeLine_creategf()
		point_4 = car( line_id->bBox)
		point_3 = list( car( cadr( line_id->bBox)) cadr( point_4))
		pin_box = axlDBGetExtents( axlDBGetDesign()->pins nil)
		point_1 = list( car( point_4) cadr( cadr( pin_box)))
		point_2 = list( car( point_3) cadr( cadr( pin_box)))
		point_ls = list( point_1 point_2 point_3 point_4)
		return( point_ls)
	)
)

procedure( GetNoPorbPoints_creategf()
	prog( ( line_id point_1 point_2 point_3 point_4 point_ls)
		line_id = GetPcbEdgeLine_creategf()
		point_2 = cadr( line_id->bBox)
		point_4 = car( line_id->bBox)
		point_1 = list( car( point_4) cadr( point_2))
		point_3 = list( car( point_2) cadr( point_4))
		point_ls = list( point_1 point_2 point_3 point_4)
		return( point_ls)
	)
)

procedure( GetViaKOPoints_creategf()
	prog( ( pin_box point_1 point_2 point_3 point_4 point_ls)
		line_id = GetPcbEdgeLine_creategf()
		axlVisibleDesign( nil)
		axlVisibleLayer( _layer_pin_top t)
		pin_box = axlDBGetExtents( axlDBGetDesign()->pins t)
		point_4 = list( car( car( line_id->bBox)) cadr( cadr( pin_box)))
		point_3 = list( car( cadr( line_id->bBox)) cadr( cadr( pin_box)))
		offset = GetUnitValueByMils_utilityprogram( 10)
		point_1 = axlMXYAdd( point_4 0:offset)
		point_2 = axlMXYAdd( point_3 0:offset)
		point_ls = list( point_1 point_2 point_3 point_4)
		return( point_ls)
	)
)

procedure( GetPkgKOPoints_creategf()
	prog( ( line_id point_1 point_2 point_3 point_4 point_ls pin_box)
		line_id = GetPcbEdgeLine_creategf()
		point_2 = cadr( line_id->bBox)
		point_1 = list( car( car( line_id->bBox)) cadr( point_2))
		pin_box = axlDBGetExtents( axlDBGetDesign()->pins nil)
		point_4 = list( car( point_1) cadr( cadr( pin_box)))
		point_3 = list( car( point_2) cadr( cadr( pin_box)))
		point_ls = list( point_3 point_2 point_1 point_4)
		return( point_ls)
	)
)

procedure( GetPcbEdgeLine_creategf()
	let( ( line_ls line_id)
		line_ls = GetLineList_utilityprogram( _layer_pcb_edge)
		line_id = car( setof( x line_ls axlGeoEqual( axlPathGetWidth( axlDB2Path( x)) 0.0)))
		;line_id = car( sort( line_ls lambda( (a b) greaterp( axlDBGetLength( a) axlDBGetLength( b)))))
	)
)

procedure( Create_creategf()
	prog( ( visible_ls result)
		result = CheckPCBEdgeNote_creategf()
		unless( result
			return( nil)
		)
		
		visible_ls = axlVisibleGet()
		when( _create_setting_table[ _form_key_pb]
			CreatePlaceBound_creategf()
		)
		
		when( _create_setting_table[ _form_key_sm]
			CreateSoldermask_creategf()
		)
		
		when( _create_setting_table[ _form_key_np]
			CreateNoProbe_creategf()
		)

		when( _create_setting_table[ _form_key_via_ko]
			CreateViaKeepout_creategf()
		)

		when( _create_setting_table[ _form_key_pkg_ko]
			CreatePkgKeepout_creategf()
		)

		when( _create_setting_table[ _form_key_an]
			CreateAssemblyNotes_creategf()
		)
		
		when( _create_setting_table[ _form_key_ref_layer]
			value = _create_setting_table[ _form_key_ref_types]
			CreateRefLayer_footprintutilityprogram( value)
		)
		
		when( _create_setting_table[ _form_key_pin1_mark]
			value = _create_setting_table[ _form_key_pin1_mark_size]
			CreatePin1Mark_footprintutilityprogram( value)
		)
		
		when( _create_setting_table[ _form_key_pin_note]
			is_top = _create_setting_table[ _form_key_pin_note_layer] == "TOP"
			CreatePinNote_footprintutilityprogram( ?is_top is_top)
		)
		
		when( _create_setting_table[ _form_key_symbol_note]
			CreateSymbolNote_footprintutilityprogram()
		)
		
		println( "Finished")
		axlVisibleSet( visible_ls)
	)
)
;;; Package Geometry > Place_Bound_Top  & Place_Bound _Bottom : 
;;; Shape依照Pcb Edge大小並包到Pad 的soldermask 上邊緣(y軸), 高度只需設Max 0.0025mm=0.1mils.
procedure( CreatePlaceBound_creategf()
	let( ( layer_ls height_max point_ls)
		layer_ls = list( _layer_pkg_pbt _layer_pkg_pbb)
		height_max = GetUnitValueByMils_utilityprogram( 0.1)
		info( _create_msg_format sprintf( nil "%L" layer_ls))
		point_ls = GetPlaceBoundPoints_creategf()
		foreach( layer layer_ls
			shape_id = CreateShapeByPoints_utilityprogram( point_ls layer)
			axlDBAddProp( shape_id list( "PACKAGE_HEIGHT_MAX" height_max))
		)
	)
)

procedure( CreateSoldermask_creategf()
	let( ( point_ls layer_ls)
		layer_ls = list( _layer_pkg_smt _layer_pkg_smb)
		info( _create_msg_format sprintf( nil "%L" layer_ls))
		point_ls = GetPlaceBoundPoints_creategf()
		foreach( layer layer_ls
			CreateShapeByPoints_utilityprogram( point_ls layer)
		)
	)
)

procedure( CreateNoProbe_creategf()
	let( ( point_ls layer_ls)
		layer_ls = list( _layer_manu_npt _layer_manu_npb)
		info( _create_msg_format sprintf( nil "%L" layer_ls))
		point_ls = GetNoPorbPoints_creategf()
		foreach( layer layer_ls
			CreateShapeByPoints_utilityprogram( point_ls layer)
		)
	)
)

procedure( CreateViaKeepout_creategf()
	let( ( point_ls)
		info( _create_msg_format _layer_via_ko_a)
		point_ls = GetViaKOPoints_creategf()
		CreateShapeByPoints_utilityprogram( point_ls _layer_via_ko_a)
	)
)

procedure( CreatePkgKeepout_creategf()
	let( ( point_ls)
		info( _create_msg_format _layer_pkg_ko_a)
		point_ls = GetPkgKOPoints_creategf()
		CreateShapeByPoints_utilityprogram( point_ls _layer_pkg_ko_a)
	)
)

procedure( CreateAssemblyNotes_creategf()
	let( ( layer note_ls text_ls angle_text_ls
		angle_str bevel_text_ls bevel_str thickness_text_ls thickness_str)
		layer = _layer_bg_an
		info( _create_msg_format layer)
		unless( axlIsLayer( layer)
			CreateLayer_footprintutilityprogram( layer)
		)

		LoadClp_footprintutilityprogram( strcat( _footprint_clp_path "gf.clp"))
		note_ls = list( _create_setting_table[ _form_key_an_angle] _create_setting_table[ _form_key_an_bevel_length] _create_setting_table[ _form_key_an_thickness])
		when( forall( x note_ls !blankstrp( x))
			; change text
			text_ls = GetTextList_utilityprogram( layer)
			text_ls = setof( x text_ls and( x->prop->COMMENT index( x->prop->COMMENT "gf_")))

			angle_text_ls = setof( x text_ls equal( x->prop->COMMENT _prop_angle))
			angle_str = GetAssemblyNotes_creategf( _prop_angle)
			ChangeText_creategf( angle_text_ls angle_str)

			bevel_text_ls = setof( x text_ls equal( x->prop->COMMENT _prop_bevel))
			bevel_str = GetAssemblyNotes_creategf( _prop_bevel)
			ChangeText_creategf( bevel_text_ls bevel_str)

			thickness_text_ls = setof( x text_ls equal( x->prop->COMMENT _prop_thickness))
			thickness_str = GetAssemblyNotes_creategf( _prop_thickness)
			ChangeText_creategf( thickness_text_ls thickness_str)

			bevel_text_ls = setof( x text_ls equal( x->prop->COMMENT _prop_bevel_sub))
			bevel_str = GetAssemblyNotes_creategf( _prop_bevel_sub)
			ChangeText_creategf( bevel_text_ls bevel_str)

			thickness_text_ls = setof( x text_ls equal( x->prop->COMMENT _prop_thickness_sub))
			thickness_str = GetAssemblyNotes_creategf( _prop_thickness_sub)
			ChangeText_creategf( thickness_text_ls thickness_str)
		)
	)
)

procedure( GetAssemblyNotes_creategf( key)
	prog( ( data_unit is_sub data_key tol_plus_key tol_minus_key data tol_plus tol_minus tol_str)
		data_unit = _create_setting_table[ _form_key_an_unit]
		is_sub = index( key "sub")
		cond(
			( index( key _prop_angle)
				data_key = _form_key_an_angle
				tol_plus_key = _form_key_an_angle_tol_plus
				tol_minus_key = _form_key_an_angle_tol_minus
				data_unit = "degree"
			)
			( index( key _prop_bevel)
				data_key = _form_key_an_bevel_length
				tol_plus_key = _form_key_an_bevel_tol_plus
				tol_minus_key = _form_key_an_bevel_tol_minus
			)
			( index( key _prop_thickness)
				data_key = _form_key_an_thickness
				tol_plus_key = _form_key_an_thickness_tol_plus
				tol_minus_key = _form_key_an_thickness_tol_minus
			)
		)

		data = _create_setting_table[ data_key]
		tol_plus = _create_setting_table[ tol_plus_key]
		tol_minus = _create_setting_table[ tol_minus_key]
		when( or( index( tol_plus "%") index( tol_minus "%"))
			unless( and( index( tol_plus "%") index( tol_minus "%"))
				printf( "Error : GetAssemblyNotes() - %s tolerance unit different [+%s] [-%s]" data_key tol_plus tol_minus)	
				tol_plus = ""
				tol_minus = ""
			)
		)
		
		when( is_sub
			data = ConvertMMInch_creategf( data_unit data)
			unless( index( tol_plus "%")
				tol_plus = ConvertMMInch_creategf( data_unit tol_plus)
				tol_minus = ConvertMMInch_creategf( data_unit tol_minus)
			)
			
			data_unit = if( equal( lowerCase( data_unit) "mm") "inch" "mm")
		)
		
		tol_str = ""
		unless( or( blankstrp( tol_plus) blankstrp( tol_minus))
			if( equal( tol_plus tol_minus)
				tol_str = strcat( "+/-" tol_plus)
				tol_str = strcat( "+" tol_plus "/-" tol_minus)
			)
		)

		if( index( tol_str "%")
			note = strcat( data data_unit tol_str)
			note = strcat( data tol_str data_unit)
		)
		
		when( is_sub
			note = strcat( "[" note "]")
		)

		return( note)
	)
)

procedure( ChangeText_creategf( text_ls new_text)
	let( ()
		when( and( text_ls dtpr( text_ls) equal( text_ls->objType "text"))
			text_ls = list( text_ls)
		)
		
		foreach( text_id text_ls
			axlDBChangeText( text_id new_text)
		)
	)
)

procedure( ConvertMMInch_creategf( source_unit value)
	prog( ( result to_unit)
		when( blankstrp( value)
			return( "")
		)
		
		unless( floatp( value)
			value = atof( value)
		)
		
		to_unit = if( equal( lowerCase( source_unit) "mm") "inch" "mm")
		when( (result = axlMKSConvert( value source_unit to_unit))
			return( sprintf( nil "%.3f" result))
		)
	)
)

procedure( Delete_creategf()
	let( ()
		when( _delete_setting_table[ _form_key_pb]
			DeleteShapesOnLayer_footprintutilityprogram( list( _layer_pkg_pbt _layer_pkg_pbb))
		)
		
		when( _delete_setting_table[ _form_key_sm]
			DeleteShapesOnLayer_footprintutilityprogram( list( _layer_pkg_smt _layer_pkg_smb))
		)
		
		when( _delete_setting_table[ _form_key_np]
			DeleteShapesOnLayer_footprintutilityprogram( list( _layer_manu_npt _layer_manu_npb))
		)

		when( _delete_setting_table[ _form_key_via_ko]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_via_ko_a)
		)

		when( _delete_setting_table[ _form_key_pkg_ko]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_pkg_ko_a)
		)

		when( _delete_setting_table[ _form_key_an]
			DeleteTextsOnLayer_footprintutilityprogram( _layer_bg_an)
			DeleteLinesOnLayer_footprintutilityprogram( _layer_bg_an)
		)

		when( _delete_setting_table[ _form_key_ref_layer]
			DeleteRefLayer_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_pin1_mark]
			DeletePin1Mark_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_pin_note]
			is_top = _delete_setting_table[ _form_key_pin_note_layer] == "TOP"
			DeletePinNote_footprintutilityprogram( ?is_top is_top)
		)
		
		when( _delete_setting_table[ _form_key_symbol_note]
			DeleteSymbolNote_footprintutilityprogram()
		)
	)
)

;region Form

procedure( LoadForm_creategf()
	prog( ( file_name form)
		file_name = "create_gf.form"
		WriteForm_creategf( file_name)
		form = axlFormCreate( gensym() file_name '( "east" "outer") 'FormActions_creategf nil)
		
		; default settings
		unless( axlIsFormType( form)
			println( "ERROR: LoadForm() - form_id is not in form type")
			return( nil)
		)
		
		axlFormSetField( form _form_key_all t)
		SetAllFormOptions_footprintutilityprogram( form _form_option_key_ls t)
		axlFormDefaultButton( form _form_key_create)
		
		SetRefTypeList_footprintutilityprogram( form _form_key_ref_types)
		axlFormSetField( form _form_key_pin1_mark_size 1)

		axlFormBuildPopup( form _form_key_pin_note_layer list( "TOP" "BOTTOM"))
		axlFormSetField( form _form_key_pin_note_layer "TOP")

		axlFormBuildPopup( form _form_key_an_unit list( "mm" "inch"))
		axlFormSetField( form _form_key_an_unit "mm")

		axlFormDisplay( form)
		return( t)
	)
)

procedure( WriteForm_creategf( file_name)
	prog( ( out_port group_width content_x sub_content_x group_x port_width port_height group_y y_start y_end 
	         button_width button_height button_x)
		group_width = 37
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		button_height = 2

		;;; header
		port_width = group_width + 2
		port_height = 120
		
		out_port = NewForm_utilityprogram( file_name "Create GF" port_width port_height)
		unless( out_port
			return( nil)
		)
		
		;;; popup
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_an_unit)
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_ref_types)
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_pin_note_layer)
		
		;;; control panel
		group_y = 1
		y_end = group_y
		
		WriteFormText_utilityprogram( out_port "Gold Finger" content_x y_end)
		
		group_y = y_end + 2
		y_end = group_y
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_all 'All content_x y_end 'ctrl)
		WriteFormCheckList_utilityprogram( out_port _form_key_none 'None ( content_x + 8) y_end 'ctrl)
		
		WriteFormGroup_utilityprogram( out_port 'Control group_x group_y group_width y_end)
		
		y_end = y_end + 3
		WriteFormButton_utilityprogram( out_port _form_key_pin_number "Resize Pin number" group_x y_end group_width button_height)

		;;; selection of the setup package
		group_y = y_end + 3
		y_start = group_y
		y_end = y_start

        y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pb "PLACE_BOUND_TOP/BOT " content_x y_end)
        y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_sm "SOLDERMASK_TOP/BOT " content_x y_end)
        y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_np "NO_PROBE_TOP/BOT " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_via_ko "Via KO/ALL " content_x y_end)
        y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pkg_ko "Pkg KO/ALL " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_an "ASSEMBLY_NOTES " content_x y_end)
		WriteFormEnumSet_utilityprogram( out_port _form_key_an_unit (content_x + 18) y_end 8)

		y_end = y_end + 2
		WriteAssemblyNoteItem_creategf( out_port content_x y_end "Angle" _form_key_an_angle _form_key_an_angle_tol_plus _form_key_an_angle_tol_minus)
		y_end = y_end + 2
		WriteAssemblyNoteItem_creategf( out_port content_x y_end "Bevel" _form_key_an_bevel_length _form_key_an_bevel_tol_plus _form_key_an_bevel_tol_minus)
		y_end = y_end + 2
		WriteAssemblyNoteItem_creategf( out_port content_x y_end "Thick" _form_key_an_thickness _form_key_an_thickness_tol_plus _form_key_an_thickness_tol_minus)

		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_ref_layer "Ref layers " content_x y_end)
		y_end = y_end + 2
		WriteFormEnumSet_utilityprogram( out_port _form_key_ref_types sub_content_x y_end 5)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pin1_mark "PIN1 mark " content_x y_end)
		y_end = y_end + 2
		WriteFormText_utilityprogram( out_port "Size" sub_content_x y_end)
		WriteFormIntSlideBar_utilityprogram( out_port _form_key_pin1_mark_size (sub_content_x + 4) y_end 5 2 ?min_value 1.0 ?max_value 10.0)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pin_note "PIN notes " content_x y_end)
		y_end = y_end + 2
		WriteFormEnumSet_utilityprogram( out_port _form_key_pin_note_layer sub_content_x y_end 6)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_symbol_note "Symbol notes " content_x y_end)
		
		WriteFormGroup_utilityprogram( out_port 'Setup group_x group_y group_width (y_end - y_start + 4))
		
		;;;;; button field
		button_width = group_width / 3
		
		y_end = y_end + 3
		button_x = group_x
		WriteFormButton_utilityprogram( out_port _form_key_create "Create" button_x y_end button_width button_height)
		
		button_x = button_x + button_width
		WriteFormButton_utilityprogram( out_port _form_key_delete "Delete" button_x y_end button_width button_height)
		
		button_x = button_x + button_width
		WriteFormButton_utilityprogram( out_port _form_key_close "Close" button_x y_end button_width button_height)
		
		EndForm_utilityprogram( out_port)
		
		close( out_port)
		return( t)
	)
)

procedure( WriteAssemblyNoteItem_creategf( out_port content_x y_end content key_1 key_2 key_3)
	let( ( sub_content_x input_1_x tol_p_x input_2_x tol_m_x input_3_x)
		textbox_width = 5
		textbox_length = 7
		sub_content_x = content_x + 2
		input_1_x = sub_content_x + 5
		tol_p_x = input_1_x + 7
		input_2_x = tol_p_x + 5
		tol_m_x = input_2_x + 7
		input_3_x = tol_m_x + 2
		WriteFormText_utilityprogram( out_port strcat( content ":") sub_content_x y_end)
		WriteFormStrFillin_utilityprogram( out_port key_1 input_1_x y_end textbox_width textbox_length)
		WriteFormText_utilityprogram( out_port "TOL:+" tol_p_x y_end)
		WriteFormStrFillin_utilityprogram( out_port key_2 input_2_x y_end textbox_width textbox_length)
		WriteFormText_utilityprogram( out_port "/-" tol_m_x y_end)
		WriteFormStrFillin_utilityprogram( out_port key_3 input_3_x y_end textbox_width textbox_length)
	)
)

procedure( FormActions_creategf( form)
	prog( ( cur_field)
		_run_create = nil
		_run_delete = nil
		unless( axlIsFormType( form)
			println( "ArgErr: FormActions() - form_id is not in form type")
			return( nil)
		)
		
		cur_field = form->curField
		cond( 
			( equal( cur_field _form_key_all)
				SetAllFormOptions_footprintutilityprogram( form _form_option_key_ls t)
			)
			( equal( cur_field _form_key_none)
				SetAllFormOptions_footprintutilityprogram( form _form_option_key_ls)
			)
			( equal( cur_field _form_key_pin_number)
				CreatePinNumber_footprintutilityprogram()
			)
			( equal( cur_field _form_key_an_angle_tol_plus)
				axlFormSetField( form _form_key_an_angle_tol_minus axlFormGetField( form cur_field))
			)
			( equal( cur_field _form_key_an_bevel_tol_plus)
				axlFormSetField( form _form_key_an_bevel_tol_minus axlFormGetField( form cur_field))
			)
			( equal( cur_field _form_key_an_thickness_tol_plus)
				axlFormSetField( form _form_key_an_thickness_tol_minus axlFormGetField( form cur_field))
			)
			( equal( cur_field symbolToString( _form_key_create))
				unless( CheckOKToProceed_utilityprogram()
					return( nil)
				)
				
				GetFieldValues_footprintutilityprogram( form _form_all_key_ls _create_setting_table)
				
				_run_create = t
				Create_creategf()
			)
			( equal( cur_field symbolToString( _form_key_delete))
				unless( CheckOKToProceed_utilityprogram()
					return( nil)
				)
				
				unless( axlUIYesNo( "Delete checked items?" "Delete items")
					return( nil)
				)
				
				GetFieldValues_footprintutilityprogram( form _form_all_key_ls _delete_setting_table)
				
				_run_delete = t
				Delete_creategf()
			)
			( equal( cur_field symbolToString( _form_key_close))
				axlFormClose( form)
			)
		)
		
		return( t)
	)
)

;endregion

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "create_gf" 'Main_creategf ?cmdType "general")
/*
(encrypt "c:/skill/create_gf_v1d1.il" "c:/skill/create_gf_v1d1.ile")
(load "create_gf_v1d1.il")
(load "create_gf_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup