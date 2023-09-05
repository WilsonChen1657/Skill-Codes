/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/18                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To create BGA symbol according to DATASHEET and PAD                    #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_createbga()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	setq( _create_setting_table makeTable( "create_setting" nil))
	setq( _delete_setting_table makeTable( "delete_setting" nil))
	
	setq( _form_key_st "setup_silkscreen_top")
	setq( _form_key_pbt "setup_place_bound_top")
	setq( _form_key_dfabt "setup_dfa_bound_top")
	setq( _form_key_npt "setup_no_probe_top")
	setq( _form_key_ref_layer "setup_ref_layer")
	setq( _form_key_ref_types "setup_ref_types")
	setq( _form_key_pin1_mark "setup_pin1_mark")
	setq( _form_key_pin1_mark_size "setup_pin1_mark_size")
	setq( _form_key_pin_note "setup_pin_note")
	setq( _form_key_symbol_note "setup_symbol_note")
	setq( _form_key_pin_number "setup_pin_number")
	setq( _form_key_ls list( _form_key_st _form_key_pbt _form_key_dfabt _form_key_npt
								_form_key_ref_layer _form_key_pin1_mark _form_key_pin_note _form_key_symbol_note))
	
	setq( _run_create nil)
	setq( _run_delete nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_createbga()
	prog( ()
		unless( axlOKToProceed() 
			println( "Please done current function to use this program")
			return nil
		)
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		Init_createbga()
		
		LoadForm_createbga()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Create_createbga()
	prog( ( visible_ls result)
		visible_ls = axlVisibleGet()
		result = CheckSymbol_footprintutilityprogram()
		when( result
			when( _create_setting_table[ _form_key_st]
				CreateOnSilkscreenTop_footprintutilityprogram()
				CreateOnSilkscreenTop_footprintutilityprogram( 88)
			)
			
			when( _create_setting_table[ _form_key_pbt]
				CreateOnPlaceBoundTop_footprintutilityprogram()
			)
			
			when( _create_setting_table[ _form_key_dfabt]
				CreateOnDFABoundTop_footprintutilityprogram()
			)
			
			when( _create_setting_table[ _form_key_npt]
				CreateOnNoProbeTop_footprintutilityprogram()
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
				CreatePinNote_footprintutilityprogram( ?placement 'horizontal)
				CreatePinNote_footprintutilityprogram( ?placement 'vertical)
			)
			
			when( _create_setting_table[ _form_key_symbol_note]
				CreateSymbolNote_footprintutilityprogram()
			)
		)
		
		println( "Finished")
		axlVisibleSet( visible_ls)
	)
)

procedure( Delete_createbga()
	let( ()
		when( _delete_setting_table[ _form_key_st]
			DeleteOnSilkscreenTop_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_pbt]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_pkg_pbt)
		)
		
		when( _delete_setting_table[ _form_key_dfabt]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_pkg_dfabt)
		)
		
		when( _delete_setting_table[ _form_key_npt]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_manu_npt)
		)
		
		when( _delete_setting_table[ _form_key_ref_layer]
			DeleteRefLayer_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_pin1_mark]
			DeletePin1Mark_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_pin_note]
			DeletePinNote_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_symbol_note]
			DeleteSymbolNote_footprintutilityprogram()
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( LoadForm_createbga()
	prog( ( file_name form)
		file_name = "create_bga.form"
		WriteForm_createbga( file_name)
		form = axlFormCreate( gensym() file_name '( "east" "outer") 'FormActions_createbga nil)
		
		; default settings
		unless( axlIsFormType( form)
			println( "ERROR: ShowForm() - form_id is not in form type")
			return( nil)
		)
		
		axlFormSetField( form _form_key_all t)
		SetAllFormOptions_footprintutilityprogram( form _form_key_ls t)
		axlFormDefaultButton( form _form_key_create)
		
		axlFormBuildPopup( form _form_key_ref_types _ref_type_ls)
		axlFormSetField( form _form_key_ref_types "U*")
		axlFormSetField( form _form_key_pin1_mark_size 1)
		
		axlFormDisplay( form)
		return( t)
	)
)

procedure( WriteForm_createbga( file_name)
	prog( ( out_port group_width content_x sub_content_x group_x port_width port_height group_y y_start y_end 
	         button_width button_height button_x)
		group_width = 36
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		button_width = group_width / 3
		button_height = 2
		
		;;; header
		port_width = group_width + 2
		port_height = 120
		
		out_port = NewForm_utilityprogram( file_name "Create BGA" port_width port_height)
		unless( out_port
			return( nil)
		)
		
		;;; popup
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_ref_types)
		
		;;; control panel
		group_y = 1
		y_end = group_y
		
		WriteFormText_utilityprogram( out_port "BGA" content_x y_end)
		
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
		WriteFormCheckList_utilityprogram( out_port _form_key_st "SILKSCREEN_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pbt "PLACE_BOUND_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_dfabt "DFA_BOUND_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_npt "NO_PROBE_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_ref_layer "Ref layers" content_x y_end)
		y_end = y_end + 2
		WriteFormEnumSet_utilityprogram( out_port _form_key_ref_types ( content_x + 4) y_end 12)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pin1_mark "PIN1 mark" content_x y_end)
		y_end = y_end + 2
		WriteFormText_utilityprogram( out_port "Size" ( content_x + 4) y_end)
		WriteFormIntSlideBar_utilityprogram( out_port _form_key_pin1_mark_size ( content_x + 8) y_end 5 2 ?min_value 1.0 ?max_value 10.0)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pin_note "PIN notes" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_symbol_note "Symbol notes" content_x y_end)
		
		WriteFormGroup_utilityprogram( out_port 'Setup group_x group_y group_width (y_end - y_start + 4))
		
		;;;;; button field
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

procedure( FormActions_createbga( form)
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
			( equal( cur_field _form_key_pin_number)
				CreatePinNumber_footprintutilityprogram()
			)
			( equal( cur_field symbolToString( _form_key_create))
				form_key_ls = append( _form_key_ls list( _form_key_ref_types _form_key_pin1_mark_size))
				GetFieldValues_footprintutilityprogram( form form_key_ls _create_setting_table)
				
				_run_create = t
				Create_createbga()
				
			)
			( equal( cur_field symbolToString( _form_key_delete))
				msg = "Delete checked items?"
				unless( axlUIYesNo( msg "Delete items")
					return( nil)
				)
				
				GetFieldValues_footprintutilityprogram( form _form_key_ls _delete_setting_table)
				
				_run_delete = t
				Delete_createbga()
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

axlCmdRegister( "create_bga" 'Main_createbga ?cmdType "general")
/*
(encrypt "c:/skill/create_bga_v1d1.il" "c:/skill/create_bga_v1d1.ile")
(load "create_bga_v1d1.il")
(load "create_bga_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup