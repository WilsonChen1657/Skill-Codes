/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/11/10                                                      #
#  Reference: locker, utility_program, footprint_utility_program               #
#  Purpose:                                                                    #
#       To create LOGO symbol according to DATASHEET and PAD                   #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_createlogo()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	setq( _create_setting_table makeTable( "create_setting" nil))
	setq( _delete_setting_table makeTable( "delete_setting" nil))
	
	setq( _form_key_scale_logo "scale_logo")
	setq( _form_key_scale_selected "scale_selected")
	setq( _form_key_logo_scale_size "setup_logo_scale_size")
	setq( _form_key_load_clp "setup_load_clp")
	setq( _form_key_symbol_note "setup_symbol_note")
	setq( _form_key_ls list( _form_key_load_clp _form_key_symbol_note))
	
	setq( _run_create nil)
	setq( _run_delete nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_createlogo()
	prog( ()
		unless( axlOKToProceed() 
			println( "Please done current function to use this program")
			return nil
		)
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		Init_createlogo()
		
		LoadForm_createlogo()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Create_createlogo()
	prog( ( visible_ls)
		visible_ls = axlVisibleGet()
		when( _create_setting_table[ _form_key_load_clp]
			logo_clp_file_name = axlDMFileBrowse( nil nil ?title "Please select a logo clp" ?optFilters "All clp files(*.clp)")
			LoadClp_footprintutilityprogram( logo_clp_file_name)
		)
		
		when( _create_setting_table[ _form_key_symbol_note]
			CreateSymbolNote_footprintutilityprogram()
		)
		
		println( "Finished")
		axlVisibleSet( visible_ls)
	)
)

procedure( Delete_createlogo()
	let( ()
		when( _delete_setting_table[ _form_key_symbol_note]
			DeleteSymbolNote_footprintutilityprogram()
		)
	)
)

procedure( ScaleLogo_createlogo( scale_size)
	let( ( layer line_ls)
		layer = _layer_pkg_skt
		shape_ls = GetShapeList_utilityprogram( layer)
		foreach( shape_id shape_ls
			poly = car( axlPolyFromDB( shape_id))
			CreatePathByPoly_footprintutilityprogram( poly layer)
		)
		
		line_ls = GetLineList_utilityprogram( layer)
		ScaleObjects_createlogo( line_ls scale_size)
		axlDeleteObject( shape_ls)
	)
)

procedure( ScaleObjects_createlogo( obj_ls scale_size @optional (center '(0 0)))
	let( ( layer logo_box file_name point)
		layer = _layer_pkg_skt
		logo_box = axlDBGetExtents( obj_ls nil)
		file_name = "logo.plt"
		axlDetailSave( file_name logo_box obj_ls)
		
		;axlLayerCreateNonConductor( layer)
		;axlVisibleDesign( nil)
		axlVisibleLayer( layer t)
		axlSetActiveLayer( layer)
		
		width = abs( car( cadr( logo_box)) - car( car( logo_box))) * scale_size
		height = abs( cadr( cadr( logo_box)) - cadr( car( logo_box))) * scale_size
		
		left_down = list( (car( center) - (width / 2)) (cadr( center) - (height / 2)))
		right_up = list( (car( center) + (width / 2)) (cadr( center) + (height / 2)))
		new_box = list( left_down right_up)
		
		design_box = axlDBGetDesign()->bBox
		if( and( (car( left_down) >= car( car( design_box))) (cadr( left_down) >= cadr( car( design_box)))
					(car( right_up) <= car( cadr( design_box))) (cadr( right_up) <= cadr( cadr( design_box)))) then
			axlDetailLoad( file_name left_down scale_size 0 nil)
			axlDeleteObject( obj_ls)
		else
			axlUIConfirm( "Can't scale bigger, scale size is bigger than design!!")
		)
	)
)

procedure( ClosedLineToShape_createlogo()
	let( ( layer line_ls line_poly_ls logo_poly_ls)
		layer = _layer_pkg_skt
		line_ls = GetLineList_utilityprogram( layer)
		
		
		
		
		expand_width = GetUnitValueByMM_utilityprogram( 0.09)
		;foreach( line_id line_ls poly = axlPolyFromDB( line_id ?endCapType 'OCTAGON ?line2poly t) poly = axlPolyExpand( poly expand_width 'NONE) line_poly_ls = append( line_poly_ls poly) )
		foreach( line_id line_ls
			poly = axlPolyFromDB( line_id ?endCapType 'ROUND ?line2poly t)
			poly = axlPolyExpand( poly expand_width 'NONE)
			line_poly_ls = append( line_poly_ls poly)
		)
		
		logo_poly_ls = axlPolyOperation( car( line_poly_ls) cdr( line_poly_ls) 'OR)
		foreach( poly logo_poly_ls
			poly_ls = axlPolyExpand( poly -expand_width 'NONE)
			foreach( poly poly_ls
				axlDBCreateShape( poly t layer)
			)
		)
		
		axlDeleteObject( line_ls)
		
		shape_poly_ls = nil
		shape_ls = GetShapeList_utilityprogram( layer)
		foreach( shape_id shape_ls poly = axlPolyFromDB( shape_id) shape_poly_ls = append( shape_poly_ls poly) )
		
		logo_poly_ls = axlPolyOperation( car( shape_poly_ls) cdr( shape_poly_ls) 'OR)
		foreach( poly logo_poly_ls axlDBCreateShape( poly t layer) )
		
		axlDeleteObject( shape_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( LoadForm_createlogo()
	prog( ( file_name form)
		file_name = "create_logo.form"
		WriteForm_createlogo( file_name)
		form = axlFormCreate( gensym() file_name '( "east" "outer") 'FormActions_createlogo nil)
		
		; default settings
		unless( axlIsFormType( form)
			println( "ERROR: ShowForm() - form_id is not in form type")
			return( nil)
		)
		
		axlFormSetField( form _form_key_logo_scale_size 2.0)
		axlFormSetField( form _form_key_all t)
		SetAllFormOptions_footprintutilityprogram( form _form_key_ls t)
		axlFormDefaultButton( form _form_key_create)
		
		axlFormDisplay( form)
		return( t)
	)
)

procedure( WriteForm_createlogo( file_name)
	prog( ( out_port group_width content_x sub_content_x group_x port_width port_height group_y y_start y_end 
	         button_width button_height button_x)
		group_width = 36
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		button_height = 2
		
		;;; header
		port_width = group_width + 2
		port_height = 120
		
		out_port = NewForm_utilityprogram( file_name "Create LOGO" port_width port_height)
		unless( out_port
			return( nil)
		)
		
		;;; control panel
		group_y = 1
		y_end = group_y
		
		WriteFormText_utilityprogram( out_port "LOGO" content_x y_end)
		
		group_y = y_end + 2
		y_end = group_y
		
		y_end = y_end + 2
		WriteFormText_utilityprogram( out_port "Scaling size" content_x y_end)
		WriteFormRealFillin_utilityprogram( out_port _form_key_logo_scale_size ( content_x + 9) y_end 5 5 ?decimal 2 ?min_value 0.01 ?max_value 10.0)
		
		y_end = y_end + 3
		WriteFormButton_utilityprogram( out_port _form_key_scale_logo "Scale logo" group_x y_end group_width button_height)
		y_end = y_end + 3
		WriteFormButton_utilityprogram( out_port _form_key_scale_selected "Scale selected" group_x y_end group_width button_height)

		WriteFormGroup_utilityprogram( out_port 'Scale_logo group_x group_y group_width y_end)
		
		group_y = y_end + 3
		y_end = group_y
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_all 'All content_x y_end 'ctrl)
		WriteFormCheckList_utilityprogram( out_port _form_key_none 'None ( content_x + 8) y_end 'ctrl)
		
		WriteFormGroup_utilityprogram( out_port 'Control group_x group_y group_width y_end)
		
		;;; selection of the setup package
		group_y = y_end + 2
		y_start = group_y
		y_end = y_start

		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_load_clp "Load clp" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_symbol_note "Symbol notes" content_x y_end)
		
		WriteFormGroup_utilityprogram( out_port 'Setup group_x group_y group_width (y_end - y_start + 4))
		
		;;;;; button field
		button_width = group_width / 3
		
		button_x = group_x
		y_end = y_end + 3
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

procedure( FormActions_createlogo( form)
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
				SetAllFormOptions_footprintutilityprogram( form _form_key_ls t)
			)
			( equal( cur_field _form_key_none)
				SetAllFormOptions_footprintutilityprogram( form _form_key_ls)
			)
			( equal( cur_field _form_key_scale_logo)
				scale_size = axlFormGetField( form _form_key_logo_scale_size)
				ScaleLogo_createlogo( scale_size)
			)
			( equal( cur_field _form_key_scale_selected)
				scale_size = axlFormGetField( form _form_key_logo_scale_size)
				obj_ls = SelectObjectByUser_footprintutilityprogram( '(lines shapes))
				box = axlDBGetExtents( obj_ls nil)
				center = list( ((car( car( box)) + car( cadr( box))) / 2) ((cadr( car( box)) + cadr( cadr( box))) / 2))
				ScaleObjects_createlogo( obj_ls scale_size center)
			)
			( equal( cur_field symbolToString( _form_key_create))
				GetFieldValues_footprintutilityprogram( form _form_key_ls _create_setting_table)
				
				_run_create = t
				Create_createlogo()
			)
			( equal( cur_field symbolToString( _form_key_delete))
				unless( axlUIYesNo( "Delete checked items?" "Delete items")
					return( nil)
				)
				
				GetFieldValues_footprintutilityprogram( form _form_key_ls _delete_setting_table)
				
				_run_delete = t
				Delete_createlogo()
			)
			( equal( cur_field symbolToString( _form_key_close))
				axlFormClose( form)
			)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "create_logo" 'Main_createlogo ?cmdType "general")
/*
(encrypt "c:/skill/create_logo_v1d1.il" "c:/skill/create_logo_v1d1.ile")
(load "create_logo_v1d1.il")
(load "create_logo_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup