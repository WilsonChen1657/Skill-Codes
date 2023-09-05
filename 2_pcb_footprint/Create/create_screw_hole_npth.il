/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/31                                                      #
#  Reference: locker, utility_program, footprint_utility_program               #
#  Purpose:                                                                    #
#       To create screw hole(NPTH) symbol according to DATASHEET and PAD       #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_createscrewholenpth()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	setq( _create_setting_table makeTable( "create_setting" nil))
	setq( _delete_setting_table makeTable( "delete_setting" nil))
	
	setq( _form_key_pbtb "setup_place_bound_top_bot")
	setq( _form_key_nptb "setup_no_probe_top_bot")
	setq( _form_key_rka "setup_route_keepout_all")
	setq( _form_key_pkg_ko_t "setup_package_keepout_top")
	setq( _form_key_pkg_ko_b "setup_package_keepout_bot")
	setq( _form_key_ref_layer "setup_ref_layer")
	setq( _form_key_ref_types "setup_ref_types")
	setq( _form_key_symbol_note "setup_symbol_note")
	setq( _form_key_ls list( _form_key_pbtb _form_key_nptb _form_key_rka _form_key_pkg_ko_t _form_key_pkg_ko_b _form_key_ref_layer _form_key_symbol_note))
	
	setq( _run_create nil)
	setq( _run_delete nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_createscrewholenpth()
	prog( ()
		unless( axlOKToProceed() 
			println( "Please done current function to use this program")
			return nil
		)
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		Init_createscrewholenpth()
		
		LoadForm_createscrewholenpth()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Create_createscrewholenpth()
	prog( ( visible_ls pin_ls zero1_mils layer_ls)
		visible_ls = axlVisibleGet()
		pin_ls = axlDBGetDesign()->pins
		zero1_mils = GetUnitValueByMils_utilityprogram( 0.1)
		when( _create_setting_table[ _form_key_pbtb]
			layer_ls = list( _layer_pkg_pbt _layer_pkg_pbb)
			CreateShapeOnPin_footprintutilityprogram( pin_ls layer_ls ?height_max zero1_mils)
		)
		
		when( _create_setting_table[ _form_key_nptb]
			layer_ls = list( _layer_manu_npt _layer_manu_npb)
			CreateShapeOnPin_footprintutilityprogram( pin_ls layer_ls ?expand_mils 15)
		)
		
		when( _create_setting_table[ _form_key_rka]
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_rte_ko_a ?expand_mils 12)
		)
		
		when( _create_setting_table[ _form_key_pkg_ko_t]
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_pkg_ko_t ?expand_mils 200 ?height_min zero1_mils)
		)
		
		when( _create_setting_table[ _form_key_pkg_ko_b]
			CreateShapeOnPin_footprintutilityprogram( pin_ls _layer_pkg_ko_b ?expand_mils 100 ?height_min zero1_mils)
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

procedure( Delete_createscrewholenpth()
	let( ()
		when( _delete_setting_table[ _form_key_pbtb]
			layer_ls = list( _layer_pkg_pbt _layer_pkg_pbb)
			DeleteShapesOnLayer_footprintutilityprogram( layer_ls)
		)
		
		when( _delete_setting_table[ _form_key_nptb]
			layer_ls = list( _layer_manu_npt _layer_manu_npb)
			DeleteShapesOnLayer_footprintutilityprogram( layer_ls)
		)
		
		when( _delete_setting_table[ _form_key_rka]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_rte_ko_a)
		)
		
		when( _delete_setting_table[ _form_key_pkg_ko_t]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_pkg_ko_t)
		)
		
		when( _delete_setting_table[ _form_key_pkg_ko_b]
			DeleteShapesOnLayer_footprintutilityprogram( _layer_pkg_ko_b)
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

procedure( LoadForm_createscrewholenpth()
	prog( ( file_name form)
		file_name = "create_screw_hole_npth.form"
		WriteForm_createscrewholenpth( file_name)
		form = axlFormCreate( gensym() file_name '( "east" "outer") 'FormActions_createscrewholenpth nil)
		
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

procedure( WriteForm_createscrewholenpth( file_name)
	prog( ( out_port group_width content_x sub_content_x group_x port_width port_height group_y y_start y_end 
	         button_width button_height button_x)
		group_width = 36
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		;;; header
		port_width = group_width + 2
		port_height = 120
		
		out_port = NewForm_utilityprogram( file_name "Create Screw hole (NPTH)" port_width port_height)
		unless( out_port
			return( nil)
		)
		
		;;; popup
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_ref_types)
		
		;;; control panel
		group_y = 1
		y_end = group_y
		
		WriteFormText_utilityprogram( out_port "Screw hole (NPTH)" content_x y_end)
		
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
		WriteFormCheckList_utilityprogram( out_port _form_key_pbtb "PLACE_BOUND_TOP/BOT " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_nptb "NO_PROBE_TOP/BOT " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_rka "Rte KO/ALL " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pkg_ko_t "Pkg KO/TOP " content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pkg_ko_b "Pkg KO/BOT " content_x y_end)
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

procedure( FormActions_createscrewholenpth( form)
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
				Create_createscrewholenpth()
				
			)
			( equal( cur_field symbolToString( _form_key_delete))
				unless( axlUIYesNo( "Delete checked items?" "Delete items")
					return( nil)
				)
				
				GetFieldValues_footprintutilityprogram( form _form_key_ls _delete_setting_table)
				
				_run_delete = t
				Delete_createscrewholenpth()
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

axlCmdRegister( "create_screw_hole_npth" 'Main_createscrewholenpth ?cmdType "general")
/*
(encrypt "c:/skill/create_screw_hole_npth_v1d1.il" "c:/skill/create_screw_hole_npth_v1d1.ile")
(load "create_screw_hole_npth_v1d1.il")
(load "create_screw_hole_npth_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup