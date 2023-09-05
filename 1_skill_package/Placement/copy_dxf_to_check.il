/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/02/02                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To copy dxf layers in BOARD GEOMETRY to DXF_CHECK_TOP/BOTTOM           #
#  Memo:                                                                       #
#       source: original dxf class name                                        #
#       date:                                                                  #
#       description: pcb part number                                           #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global variable

procedure( Init_copydxftocheck()
	setq( _layer_bg_dct "BOARD GEOMETRY/DXF_CHECK_TOP")
	setq( _layer_bg_dcb "BOARD GEOMETRY/DXF_CHECK_BOTTOM")
	setq( _layer_bg_brd_form_key "BOARD GEOMETRY/BOARD_FORM_KEY")
	setq( _layer_pcb_fab "DRAWING FORMAT/PCB_FAB")
	
	setq( _bg_subclass_ls axlGetParam( "paramLayerGroup:BOARD GEOMETRY")->groupMembers)
	setq( _selected_dxft nil)
	setq( _selected_dxfb nil)
	
	setq( _form_key_dxf_top_popup 'dxf_top_layer_popup)
	setq( _form_key_dxf_bot_popup 'dxf_bot_layer_popup)
	setq( _form_key_dxf_layer_top "dxf_layer_top")
	setq( _form_key_dxf_layer_bot "dxf_layer_bottom")
	setq( _form_key_ok "key_ok")
	setq( _form_key_cancel "key_cancel")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_copydxftocheck()
	prog( ()
		unless( Main_locker()
			return( nil)
		)
		
		Init_copydxftocheck()
		LoadForm_copydxftocheck()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CopyDxf_copydxftocheck()
	let( ( dxft_result dxfb_result)
		CheckDxf_copydxftocheck( _layer_bg_dct)
		CheckDxf_copydxftocheck( _layer_bg_dcb)
		
		dxft_subclass = GetSubclassInNote_copydxftocheck( _selected_dxft)
		dxfb_subclass = GetSubclassInNote_copydxftocheck( _selected_dxfb)
		dxft_result = CopyLayer_copydxftocheck( _selected_dxft _layer_bg_dct blankstrp( dxft_subclass))
		dxfb_result = CopyLayer_copydxftocheck( _selected_dxfb _layer_bg_dcb blankstrp( dxfb_subclass))
		when( and( dxft_result dxfb_result)
			delete_layer_ls = list( _selected_dxft _selected_dxfb)
			printf( "INFO: CopyDxf() - Deleting layers %L\n" delete_layer_ls)
			DeleteLayer_utilityprogram( delete_layer_ls)
			msg = "DXF copy Complete!!"
			axlUIConfirm( msg)
			printf( "%s\n" msg)
		)
	)
)

procedure( CheckDxf_copydxftocheck( layer)
	prog( ( obj_ls dxf_subclass old_dxf_layer dxf_result)
		if( axlIsLayer( layer) then
			; recover old version dxf
			obj_ls = GetAll_utilityprogram( layer)
			when( dtpr( obj_ls)
				dxf_subclass = GetSubclassInNote_copydxftocheck( layer)
				when( dxf_subclass
					old_dxf_layer = strcat( "BOARD GEOMETRY/" dxf_subclass)
				)
			)
			
			cond(
				( !dtpr( obj_ls)
					printf( "INFO: CheckDxf() - %s is empty\n" layer)
					axlDeleteByLayer( layer)
				)
				( blankstrp( dxf_subclass)
					sprintf( msg "\"Source:\" not found on %s and therefore unable to recover old dxf" layer)
					printf( "WARN: CheckDxf() - %s\n" msg)
					axlUIConfirm( msg)
					axlDeleteByLayer( layer)
				)
				( axlIsLayer( old_dxf_layer)
					printf( "INFO: CheckDxf() - %s exist\n" old_dxf_layer)
					axlDeleteByLayer( layer)
				)
				( t
					axlLayerCreateNonConductor( old_dxf_layer)
					printf( "INFO: CheckDxf() - %s created\n" old_dxf_layer)
					dxf_result = CopyLayer_copydxftocheck( layer old_dxf_layer nil)
					when( dxf_result
						axlDeleteByLayer( layer)
					)
				)
			)
		else
			axlLayerCreateNonConductor( layer)
			printf( "INFO: CheckDxf() - %s created\n" layer)
		)
		
		return( t)
	)
)

procedure( CopyLayer_copydxftocheck( source_layer target_layer @optional (add_note t))
	prog( ( obj_ls copy_obj_ls result)
		printf( "INFO: CopyLayer() - Copying layer %s\n" source_layer)
		obj_ls = GetAll_utilityprogram( source_layer)
		when( obj_ls
			copy_obj_ls = axlCopyObject( obj_ls ?move '0.0:0.0)
			result = axlChangeLayer( copy_obj_ls target_layer)
			when( and( result add_note)
				AddNotes_copydxftocheck( source_layer target_layer)
			)
		)
		
		return( result)
	)
)

procedure( AddNotes_copydxftocheck( source_layer target_layer)
	let( ( orient text_height obj_ls dxf_box location soruce datetime date)
		printf( "INFO: AddNotes() - Create note on %s\n" target_layer)
		orient = make_axlTextOrientation( ?textBlock "10" ?justify "left")
		text_height = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))->height * 1.6
		; get dxf box
		obj_ls = GetAll_utilityprogram( source_layer)
		dxf_box = axlDBGetExtents( obj_ls nil)
		location = axlMXYAdd( car( dxf_box) 0:-text_height)
		
		;;; source
		source_subclass = cadr( parseString( source_layer "/"))
		soruce = strcat( "source:" source_subclass)
		axlDBCreateText( soruce location orient target_layer)
		location = axlMXYAdd( location 0:-text_height)
		
		;;; date
		datetime = ParseDateTimeStrToFormat_utilityprogram( getCurrentTime())
		date = strcat( "date:" substring( datetime 1 10))
		axlDBCreateText( date location orient target_layer)
		location = axlMXYAdd( location 0:-text_height)
		
		;;; description
		description = "description:"
		brd_form_key_text_ls = GetTextList_utilityprogram( _layer_bg_brd_form_key)
		pn_key_text_id = car( setof( x brd_form_key_text_ls x->text == "[pn]"))
		pcb_fab_text_ls = GetTextList_utilityprogram( _layer_pcb_fab)
		pn_text_id = car( setof( x pcb_fab_text_ls x->xy == pn_key_text_id->xy))
		if( pn_text_id
			description = strcat( description pn_text_id->text)
			printf( "WARN: AddNotes() - PCB part number not found on %s\n" _layer_bg_brd_form_key)
		)
		
		axlDBCreateText( description location orient target_layer)
	)
)

procedure( GetDxfLayerBindingList_copydxftocheck( dxf_key)
	prog( ( subclass_ls layer_ls binding_ls)
		subclass_ls = setof( x _bg_subclass_ls index( x dxf_key))
		layer_ls = nil
		foreach( subclass subclass_ls
			layer_ls = append1( layer_ls strcat( "BOARD GEOMETRY/" subclass))
		)
		
		binding_ls = mapcar( 'list subclass_ls layer_ls)
		return( binding_ls)
	)
)

procedure( GetSubclassInNote_copydxftocheck( layer)
	prog( ( text_ls text_soruce_id result)
		text_ls = GetTextList_utilityprogram( layer)
		text_soruce_id = car( setof( x text_ls rexMatchp( "source:" x->text)))
		when( text_soruce_id
			rexCompile( "source:")
			result = rexReplace( text_soruce_id->text "" 0)
		)
		
		return( result || "")
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( LoadForm_copydxftocheck()
	prog( ( dxft_binding_ls dxfb_binding_ls msg file_name form)
		dxft_binding_ls = GetDxfLayerBindingList_copydxftocheck( "DXFT")
		dxfb_binding_ls = GetDxfLayerBindingList_copydxftocheck( "DXFB")
		unless( and( dxft_binding_ls dxfb_binding_ls)
			cond(
				( !and( dxft_binding_ls dxfb_binding_ls)
					msg = "\"dxft\" and \"dxfb\""
				)
				( dxft_binding_ls
					msg = "\"dxft\""
				)
				( dxfb_binding_ls
					msg = "\"dxfb\""
				)
			)
			
			axlUIConfirm( sprintf( nil "Subclass with %s not found !!" msg))
			return( nil)
		)
		
		file_name = "copy_dxf_to_check.form"
		WriteForm_copydxftocheck( file_name)
		form = axlFormCreate( gensym() file_name '(east outer) 'FormAction_copydxftocheck nil)
		; default settings
		unless( axlIsFormType( form)
			println( "ERROR: LoadForm() - form_id is not in form type")
			return( nil)
		)
		
		axlFormBuildPopup( form _form_key_dxf_layer_top dxft_binding_ls)
		axlFormBuildPopup( form _form_key_dxf_layer_bot dxfb_binding_ls)
		
		axlFormDisplay( form)
		return( t)
	)
)

procedure( WriteForm_copydxftocheck( file_name)
	prog( ( port_width port_height out_port option_ls content_x y_end button_width button_height button_x)
		port_width = 40
		port_height = 50
		
		out_port = NewForm_utilityprogram( file_name "Copy Dxf to DXF_CHECK" port_width port_height nil)
		unless( out_port
			return( nil)
		)
		
		option_ls = list( "subclass" "layer")
		WriteFormPopup_utilityprogram( out_port _form_key_dxf_top_popup option_ls)
		WriteFormPopup_utilityprogram( out_port _form_key_dxf_bot_popup option_ls)
		fprintf( out_port "TILE\n")
		
		content_x = 1
		y_end = 1
		enum_width = port_width - 3
		;;;;; DXF TOP
		WriteFormText_utilityprogram( out_port "Select a subclass to copy to DXF_CHECK_TOP" content_x y_end)
		y_end = y_end + 2
		WriteFormEnumSet_utilityprogram( out_port _form_key_dxf_layer_top content_x y_end enum_width 0 _form_key_dxf_top_popup)
		
		;;;;; DXF BOTTOM
		y_end = y_end + 2
		WriteFormText_utilityprogram( out_port "Select a subclass to copy to DXF_CHECK_BOTTOM" content_x y_end)
		y_end = y_end + 2
		WriteFormEnumSet_utilityprogram( out_port _form_key_dxf_layer_bot content_x y_end enum_width 0 _form_key_dxf_bot_popup)
		
		;;;;; button
		button_width = 10
		button_height = 2
		
		button_x = content_x
		y_end = y_end + 3
		WriteFormButton_utilityprogram( out_port _form_key_ok "OK" button_x y_end button_width button_height)
		
		button_x = button_x + 13
		WriteFormButton_utilityprogram( out_port _form_key_cancel "Cancel" button_x y_end button_width button_height)
		
		EndForm_utilityprogram( out_port)
		
		close( out_port)
		return( t)
	)
)

procedure( FormAction_copydxftocheck( form)
	prog( ( cur_field)
		unless( axlIsFormType( form)
			println( "ArgErr: FormActions() - form_id is not in form type")
			return( nil)
		)
		
		cur_field = form->curField
		cond( 
			( equal( cur_field _form_key_dxf_layer_top)
				_selected_dxft = form->curValue
			)
			( equal( cur_field _form_key_dxf_layer_bot)
				_selected_dxfb = form->curValue
			)
			( equal( cur_field _form_key_ok)
				axlFormClose( form)
				CopyDxf_copydxftocheck()
			)
			( equal( cur_field _form_key_cancel)
				_selected_dxft = nil
				_selected_dxfb = nil
				axlFormClose( form)
			)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "copy_dxf_to_check" 'Main_copydxftocheck ?cmdType "general")
/*
(encrypt "C:/skill/copy_dxf_to_check_v1d1.il" "C:/skill/copy_dxf_to_check_v1d1.ile")
(load "copy_dxf_to_check_v1d1.il")
(load "copy_dxf_to_check_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup