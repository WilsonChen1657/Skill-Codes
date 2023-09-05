/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/11/01                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To create STDF symbol according to DATASHEET and PAD                   #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_createstdf()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	setq( _create_setting_table makeTable( "create_setting" nil))
	setq( _delete_setting_table makeTable( "delete_setting" nil))
	
	setq( _form_key_at "setup_assembly_top")
	setq( _form_key_st "setup_silkscreen_top")
	setq( _form_key_pbtb "setup_place_bound_top_bot")
	setq( _form_key_dfabtb "setup_dfa_bound_top_bot")
	setq( _form_key_nptb "setup_no_probe_top_bot")
	setq( _form_key_ref_layer "setup_ref_layer")
	setq( _form_key_ref_types "setup_ref_types")
	setq( _form_key_symbol_note "setup_symbol_note")
	setq( _form_key_ls list( _form_key_at _form_key_st _form_key_pbtb _form_key_dfabtb _form_key_nptb _form_key_ref_layer _form_key_symbol_note))
	
	setq( _run_create nil)
	setq( _run_delete nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_createstdf()
	prog( ()
		unless( axlOKToProceed() 
			println( "Please done current function to use this program")
			return nil
		)
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		Init_createstdf()
		
		LoadForm_createstdf()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Create_createstdf()
	prog( ( visible_ls pin_ls layer_ls)
		visible_ls = axlVisibleGet()
		pin_ls = axlDBGetDesign()->pins
		pin_id = car( pin_ls)
		when( _create_setting_table[ _form_key_at]
			CreatePathOnPin_footprintutilityprogram( pin_id _layer_pkg_at)
		)
		
		when( _create_setting_table[ _form_key_st]
			CreateOnSilkscreenTop_footprintutilityprogram()
		)
		
		when( _create_setting_table[ _form_key_pbtb]
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_pkg_pbt ?height_max 0.0 ?pin_layer "PIN/TOP")
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_pkg_pbb ?pin_layer "PIN/BOTTOM")
		)
		
		when( _create_setting_table[ _form_key_dfabtb]
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_pkg_dfabt ?pin_layer "PIN/TOP")
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_pkg_dfabb ?pin_layer "PIN/BOTTOM")
		)
		
		when( _create_setting_table[ _form_key_nptb]
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_manu_npt ?expand_mils 15 ?pin_layer "PIN/TOP")
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_manu_npb ?expand_mils 15 ?pin_layer "PIN/BOTTOM")
		)
		
		when( _create_setting_table[ _form_key_ref_layer]
			value = _create_setting_table[ _form_key_ref_types]
			CreateRefLayer_footprintutilityprogram( value)
		)
		
		when( _create_setting_table[ _form_key_symbol_note]
			CreateSymbolNote_footprintutilityprogram()
		)
		
		println( "Finished")
		axlVisibleSet( visible_ls)
	)
)

procedure( Delete_createstdf()
	let( ()
		when( _delete_setting_table[ _form_key_at]
			DeleteLinesOnLayer_footprintutilityprogram( _layer_pkg_at)
		)
		
		when( _delete_setting_table[ _form_key_st]
			DeleteOnSilkscreenTop_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_pbtb]
			layer_ls = list( _layer_pkg_pbt _layer_pkg_pbb)
			DeleteShapesOnLayer_footprintutilityprogram( layer_ls)
		)
		
		when( _delete_setting_table[ _form_key_dfabtb]
			layer_ls = list( _layer_pkg_dfabt _layer_pkg_dfabb)
			DeleteShapesOnLayer_footprintutilityprogram( layer_ls)
		)
		
		when( _delete_setting_table[ _form_key_nptb]
			layer_ls = list( _layer_manu_npt _layer_manu_npb)
			DeleteShapesOnLayer_footprintutilityprogram( layer_ls)
		)
		
		when( _delete_setting_table[ _form_key_ref_layer]
			DeleteRefLayer_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_symbol_note]
			DeleteSymbolNote_footprintutilityprogram()
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( LoadForm_createstdf()
	prog( ( file_name form)
		file_name = "create_stdf.form"
		WriteForm_createstdf( file_name)
		form = axlFormCreate( gensym() file_name '( "east" "outer") 'FormActions_createstdf nil)
		
		; default settings
		unless( axlIsFormType( form)
			println( "ERROR: ShowForm() - form_id is not in form type")
			return( nil)
		)
		
		axlFormSetField( form _form_key_all t)
		SetAllFormOptions_footprintutilityprogram( form _form_key_ls t)
		axlFormDefaultButton( form _form_key_create)
		
		axlFormBuildPopup( form _form_key_ref_types _ref_type_ls)
		axlFormSetField( form _form_key_ref_types "MH*")
		
		axlFormDisplay( form)
		return( t)
	)
)

procedure( WriteForm_createstdf( file_name)
	prog( ( out_port group_width content_x sub_content_x group_x port_width port_height group_y y_start y_end 
	         button_width button_height button_x)
		group_width = 36
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		;;; header
		port_width = group_width + 2
		port_height = 120
		
		out_port = NewForm_utilityprogram( file_name "Create STDF" port_width port_height)
		unless( out_port
			return( nil)
		)
		
		;;; popup
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_ref_types)
		
		;;; control panel
		group_y = 1
		y_end = group_y
		
		WriteFormText_utilityprogram( out_port "STDF" content_x y_end)
		
		group_y = y_end + 2
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
		WriteFormCheckList_utilityprogram( out_port _form_key_at "ASSEMBLY_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_st "SILKSCREEN_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pbtb "PLACE_BOUND_TOP/BOT " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_dfabtb "DFA_BOUND_TOP/BOT " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_nptb "NO_PROBE_TOP/BOT " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_ref_layer "Ref layers" content_x y_end)
		y_end = y_end + 2
		WriteFormEnumSet_utilityprogram( out_port _form_key_ref_types ( content_x + 4) y_end 12)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_symbol_note "Symbol notes" content_x y_end)
		
		WriteFormGroup_utilityprogram( out_port 'Setup group_x group_y group_width (y_end - y_start + 4))
		
		;;;;; button field
		button_width = group_width / 3
		button_height = 2
		
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

procedure( FormActions_createstdf( form)
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
			( equal( cur_field symbolToString( _form_key_create))
				form_key_ls = append( _form_key_ls list( _form_key_ref_types))
				GetFieldValues_footprintutilityprogram( form form_key_ls _create_setting_table)
				
				_run_create = t
				Create_createstdf()
				
			)
			( equal( cur_field symbolToString( _form_key_delete))
				unless( axlUIYesNo( "Delete checked items?" "Delete items")
					return( nil)
				)
				
				GetFieldValues_footprintutilityprogram( form _form_key_ls _delete_setting_table)
				
				_run_delete = t
				Delete_createstdf()
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

axlCmdRegister( "create_stdf" 'Main_createstdf ?cmdType "general")
/*
(encrypt "c:/skill/create_stdf_v1d1.il" "c:/skill/create_stdf_v1d1.ile")
(load "create_stdf_v1d1.il")
(load "create_stdf_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup