/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/26                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To create DIP symbol according to DATASHEET and PAD                    #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_createdip()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	setq( _create_setting_table makeTable( "create_setting" nil))
	setq( _delete_setting_table makeTable( "delete_setting" nil))
	
	setq( _form_key_st "setup_silkscreen_top")
	setq( _form_key_pbt "setup_place_bound_top")
	setq( _form_key_pbb "setup_place_bound_bottom")
	setq( _form_key_rka "setup_route_keepout_all")
	setq( _form_key_pkb "setup_package_keepout_bottom")
	setq( _form_key_dfabt "setup_dfa_bound_top")
	setq( _form_key_npt "setup_no_probe_top")
	setq( _form_key_ref_layer "setup_ref_layer")
	setq( _form_key_ref_types "setup_ref_types")
	setq( _form_key_pin1_mark "setup_pin1_mark")
	setq( _form_key_pin1_mark_size "setup_pin1_mark_size")
	setq( _form_key_pin_note "setup_pin_note")
	setq( _form_key_pcb_edge "setup_pcb_edge")
	setq( _form_key_symbol_note "setup_symbol_note")
	setq( _form_key_ls list( _form_key_st _form_key_pbt _form_key_pbb _form_key_rka _form_key_pkb _form_key_dfabt _form_key_npt
								_form_key_ref_layer _form_key_pin1_mark _form_key_pin_note _form_key_pcb_edge
								_form_key_symbol_note))
	
	setq( _run_create nil)
	setq( _run_delete nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_createdip()
	prog( ()
		unless( CheckOKToProceed_utilityprogram()
			return( nil)
		)
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		Init_createdip()
		
		LoadForm_createdip()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Create_createdip()
	prog( ( visible_ls result)
		visible_ls = axlVisibleGet()
		result = CheckSymbol_footprintutilityprogram()
		when( result
			when( _create_setting_table[ _form_key_st]
				CreateOnSilkscreenTop_footprintutilityprogram()
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
			
			when( _create_setting_table[ _form_key_pbb]
				CreateOnPlaceBoundBottom_footprintutilityprogram()
			)
			
			when( _create_setting_table[ _form_key_rka]
				CreateOnRouteKeepoutAll_footprintutilityprogram()
			)
			
			when( _create_setting_table[ _form_key_pkb]
				CreateOnPackageKeepoutBottom_footprintutilityprogram()
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
				CreatePinNote_footprintutilityprogram()
			)
			
			when( _create_setting_table[ _form_key_pcb_edge]
				CreatePCBEdge_footprintutilityprogram()
			)
			
			when( _create_setting_table[ _form_key_symbol_note]
				CreateSymbolNote_footprintutilityprogram()
			)
		)
		
		println( "Finished")
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Delete

procedure( Delete_createdip()
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
		
		when( _delete_setting_table[ _form_key_pbb]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_pkg_pbb)
		)
		
		when( _delete_setting_table[ _form_key_rka]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_rte_ko_a)
		)
		
		when( _delete_setting_table[ _form_key_pkb]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_pkg_ko_b)
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
		
		when( _delete_setting_table[ _form_key_pcb_edge]
			DeletePCBEdge_footprintutilityprogram()
		)
		
		when( _delete_setting_table[ _form_key_symbol_note]
			DeleteSymbolNote_footprintutilityprogram()
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( LoadForm_createdip()
	prog( ( file_name form)
		file_name = "create_dip.form"
		WriteForm_createdip( file_name)
		form = axlFormCreate( gensym() file_name '( "east" "outer") 'FormActions_createdip nil)
		
		; default settings
		unless( axlIsFormType( form)
			println( "ERROR: ShowForm() - form_id is not in form type")
			return( nil)
		)
		
		axlFormSetField( form _form_key_all t)
		SetAllFormOptions_footprintutilityprogram( form _form_key_ls t)
		axlFormDefaultButton( form _form_key_create)
		; to disable npth when no npth pin on dra
		unless( dtpr( setof( x axlDBGetDesign()->pins x->definition->plating == "NON_PLATED"))
			axlFormSetFieldEditable( form _form_key_rka nil)
		)
		
		axlFormBuildPopup( form _form_key_ref_types _ref_type_ls)
		axlFormSetField( form _form_key_ref_types car( _ref_type_ls))
		axlFormSetField( form _form_key_pin1_mark_size 1)
		
		axlFormDisplay( form)
		return( t)
	)
)

procedure( WriteForm_createdip( file_name)
	prog( ( out_port group_width content_x sub_content_x group_x port_width port_height group_y y_start y_end 
	         button_width button_height button_x)
		group_width = 36
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		;;; header
		port_width = group_width + 2
		port_height = 120
		
		out_port = NewForm_utilityprogram( file_name "Create DIP" port_width port_height)
		unless( out_port
			return( nil)
		)
		
		;;; popup
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_ref_types)
		
		;;; control panel
		group_y = 1
		y_end = group_y
		
		WriteFormText_utilityprogram( out_port "DIP" content_x y_end)
		
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
		WriteFormCheckList_utilityprogram( out_port _form_key_st "SILKSCREEN_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pbt "PLACE_BOUND_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_dfabt "DFA_BOUND_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_npt "NO_PROBE_TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pbb "PLACE_BOUND_BOT " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_rka "Rte KO/ALL (npth) " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pkb "Pkg KO/BOT (pth) " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pcb_edge "PCB Edge" content_x y_end)
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
		button_width = group_width / 3
		button_height = 2
		
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

procedure( FormActions_createdip( form)
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
				unless( CheckOKToProceed_utilityprogram()
					return( nil)
				)
				
				form_key_ls = append( _form_key_ls list( _form_key_ref_types _form_key_pin1_mark_size))
				GetFieldValues_footprintutilityprogram( form form_key_ls _create_setting_table)
				
				_run_create = t
				Create_createdip()
				
			)
			( equal( cur_field symbolToString( _form_key_delete))
				unless( CheckOKToProceed_utilityprogram()
					return( nil)
				)
				
				unless( axlUIYesNo( "Delete checked items?" "Delete items")
					return( nil)
				)
				
				GetFieldValues_footprintutilityprogram( form _form_key_ls _delete_setting_table)
				
				_run_delete = t
				Delete_createdip()
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

axlCmdRegister( "create_dip" 'Main_createdip ?cmdType "general")
/*
(encrypt "c:/skill/create_dip_v1d1.il" "c:/skill/create_dip_v1d1.ile")
(load "create_dip_v1d1.il")
(load "create_dip_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup