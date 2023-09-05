/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/05/16                                                      #
#  Reference: utility_program                                                  #
#  Purpose:                                                                    #
#       To create SMD symbol according to DATASHEET and PAD                    #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_createsmd()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	setq( _layer_pkg_assembly_top "PACKAGE GEOMETRY/ASSEMBLY_TOP")
	setq( _layer_pkg_silkscreen_top "PACKAGE GEOMETRY/SILKSCREEN_TOP")
	setq( _layer_pkg_place_bound_top "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
	setq( _layer_pkg_dfa_bound_top "PACKAGE GEOMETRY/DFA_BOUND_TOP")
	setq( _layer_pkg_body_center "PACKAGE GEOMETRY/BODY_CENTER")
	setq( _layer_manufacturing_no_probe_top "MANUFACTURING/NO_PROBE_TOP")
	setq( _layer_pin_top "PIN/TOP")
	setq( _layer_pin_soldermask_top "PIN/SOLDERMASK_TOP")
	setq( _layer_for_temp_shape "ROUTE KEEPOUT/TOP")
	setq( _layer_pcb_edge "BOARD GEOMETRY/PCB_EDGE")

	setq( _note_padstack_name "padstack name:")
	setq( _note_rev "rev:(recommend)")
	setq( _note_date "date:")
	
	setq( _create_setting_table makeTable( "create_setting" nil))
	setq( _delete_setting_table makeTable( "delete_setting" nil))
	setq( _form_key_all "control_all")
	setq( _form_key_none "control_none")
	setq( _form_key_silkscreen "setup_silkscreen_top")
	setq( _form_key_place_bound "setup_place_bound_top")
	setq( _form_key_dfa_bound "setup_dfa_bound_top")
	setq( _form_key_no_probe "setup_no_probe_top")
	setq( _form_key_ref_layer "setup_ref_layer")
	setq( _form_key_ref_types "setup_ref_types")
	setq( _form_key_pin1_mark "setup_pin1_Mark")
	setq( _form_key_pin_note "setup_pin_note")
	setq( _form_key_pcb_edge "setup_pcb_edge")
	setq( _form_key_symbol_note "setup_symbol_note")
	;; execution button
	setq( _form_key_create 'create)
	setq( _form_key_delete 'delete)
	
	setq( _ref_type_ls list( "J*" "R*" "K*" "L*" "U*" "H*" "Q*" "Y*" "F*" "D*" "C*" "SW*" "EC*" "LED*" "LBL*" "MH*"))
	
	setq( _run_create nil)
	setq( _run_delete nil)
	
	setq( _check_smd_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_createsmd()
	prog( ()
		unless( axlOKToProceed() 
			println( "Please done current function to use this program")
			return nil
		)
		
		Init_createsmd()
		
		ShowForm_createsmd()
		/*
		if( _run_create then
			Create_createsmd()
		else if( _run_delete then
			Delete_createsmd()
		))
		*/
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Create_createsmd()
	prog( ( result)
		result = CheckSymbol_createsmd()
		when( result
			when( _create_setting_table[ _form_key_silkscreen]
				CreateOnSilkscreenTop_createsmd()
			)
			
			when( _create_setting_table[ _form_key_place_bound]
				CreateOnPlaceBoundTop_createsmd()
			)
			
			when( _create_setting_table[ _form_key_dfa_bound]
				CreateOnDFABoundTop_createsmd()
			)
			
			when( _create_setting_table[ _form_key_no_probe]
				CreateOnNoProbeTop_createsmd()
			)
			
			when( _create_setting_table[ _form_key_ref_layer]
				CreateRefLayer_createsmd()
			)
			
			when( _create_setting_table[ _form_key_pin1_mark]
				CreatePin1Mark_createsmd()
			)
			
			when( _create_setting_table[ _form_key_pin_note]
				CreatePinNote_createsmd()
			)
			
			when( _create_setting_table[ _form_key_pcb_edge]
				CreatePCBEdge_createsmd()
			)
			
			when( _create_setting_table[ _form_key_symbol_note]
				CreateSymbolNote_createsmd()
			)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Create

; 1. PACKAGE GEOMETRY/ASSEMBLY_TOP :
;    依照 DATASHEET 建立
procedure( CheckSymbol_createsmd()
	prog( ( result layer)
		result = t
		;;; check datasheet on assembly_top
		layer = _layer_pkg_assembly_top
		unless( axlIsLayer( layer)
			printf( "%s not found!!\n" layer)
			result = nil
		)
		
		when( result
			assembly_top_outline = GetAssemblyTopOutline_createsmd()
			unless( assembly_top_outline
				printf( "Main outline not found on %s!!\n" layer)
				result = nil
			)			
		)
		
		;;; check PAD
		when( result
			layer = _layer_pin_top
			unless( axlIsLayer( layer)
				printf( "%s not found!!\n" layer)
				result = nil
			)
			
			when( result
				pin_ls =  GetPinList_utilityprogram( layer)
				unless( dtpr( pin_ls)
					printf( "PIN not found on %s!!\n" layer)
					result = nil
				)
			)
		)
		
		return( result)
	)
)

; 2. PACKAGE GEOMETRY/SILKSCREEN_TOP :
;    依照 ASSEMBLY_TOP 外框大小往外推 8mils, 再將線寬變成 0.1524=6mils, 
;    遇到白漆壓到 PAD 一定要切掉線段避免壓在 PAD 上
;    白漆距離 PAD 要有 6mils 以上
procedure( CreateOnSilkscreenTop_createsmd()
	prog( ( assembly_top_outline expand_points layer visible_ls pin_ls pin_box_ls line_ls pin1_mark_ls)
		println( "2. PACKAGE GEOMETRY/SILKSCREEN_TOP")
		
		assembly_top_outline = GetAssemblyTopOutline_createsmd()
		expand_points = GetExpandPoints_createsmd( assembly_top_outline 8)
		
		layer = _layer_pkg_silkscreen_top
		
		axlDBCreateLine( append1( expand_points car( expand_points)) GetUnitValueByMils_utilityprogram( 6) layer)
		
		; check overlap
		visible_ls = axlVisibleGet()
		axlVisibleDesign( nil)
		axlVisibleLayer( layer t)
		pin_ls = GetPinList_utilityprogram( _layer_pin_top)
		foreach( pin pin_ls 
			; because line width, so add 1 mils to let silkscreen with pin gap 6 mils
			target_points = GetPointsByBox_createsmd( pin->bBox ( 6 + 1))
			pin_box = list( nth( 0 target_points) nth( 2 target_points))
			pin_box_ls = append1( pin_box_ls pin_box)
		)
		
		foreach( pin_box pin_box_ls
			axlSetFindFilter( ?enabled '(noall lines) ?onButtons '(noall lines))
			when( axlSingleSelectBox( pin_box)
				overlap_line_ls = axlGetSelSet()
				pick_item_point_ls = nil
				foreach( line overlap_line_ls
					; get second segment to make sure selected point can get target line to cut
					pick_item_point = cadr( nth( 0 line->segments)->startEnd)
					pick_item_point_ls = append1( pick_item_point_ls pick_item_point)
				)
				
				foreach( point pick_item_point_ls
					; cut line
					sprintf( command "delete by rectangle;pick %L;pick %L;pick %L" point car( pin_box) cadr( pin_box))
					axlShell( command)
					axlShell( "done")
				)
			)
		)
		
		axlShell( "done")
		axlClearSelSet()
		axlSetFindFilter( ?enabled '(noall) ?onButtons '(noall))
		axlVisibleSet( visible_ls)
		
		line_ls = GetLineList_utilityprogram( layer)
		pin1_mark_ls = GetPin1MarkList_createsmd()
		line_ls = setof( x line_ls !member( x pin1_mark_ls))
		axlSetFindFilter( ?enabled '(noall lines) ?onButtons '(noall lines))
		target_length = GetUnitValueByMM_utilityprogram( 1.5) - GetUnitValueByMils_utilityprogram( 6) * 2
		need_delete_line_ls = setof( x line_ls ( axlDBGetLength( x) < target_length && axlSingleSelectBox( x->bBox) && length( axlGetSelSet()) == 1))
		
		unless( !dtpr( need_delete_line_ls)
			msg = "Do you want to delete line on SILKSCREEN_TOP where pin to pin gap is smaller than 1.5mm?"
			when( axlUIYesNo( msg "Delete line")
				; delete where length smaller than 1.5mm
				axlDeleteObject( need_delete_line_ls)
			)
		)

		axlClearSelSet()
		println( "2. Finished")
		return( t)
	)
)

; 3. PACKAGE GEOMETRY/PLACE_BOUND_TOP :
;    SHAPE 依照 ASSEMBLY_TOP 大小
;    除非 PAD 超過外框大小就依照 PAD 的大小為基準點外推 5mils 包住整個 PAD
procedure( CreateOnPlaceBoundTop_createsmd()
	prog( ( layer expand_mils assembly_top_outline assembly_top_points 
	main_shape pin_ls pin_shape_ls merged_shape result_points result_shape)
		println( "3. PACKAGE GEOMETRY/PLACE_BOUND_TOP")
		layer = _layer_pkg_place_bound_top
		expand_mils = axlMKSConvert( (1.5 / 2) "MM" "MILS")
		assembly_top_outline = GetAssemblyTopOutline_createsmd()
		assembly_top_points = GetExpandPoints_createsmd( assembly_top_outline expand_mils)
		main_shape = CreateShape_createsmd( assembly_top_points layer)
		
		visible_ls = axlVisibleGet()
		axlVisibleDesign( nil)
		axlVisibleLayer( _layer_pkg_assembly_top t)
		pin_ls = GetPinList_utilityprogram( _layer_pin_top)
		axlSetFindFilter( ?enabled '(noall lines) ?onButtons '(noall lines))
		foreach( pin pin_ls
			box = GetPinBox_createsmd( pin)
			; to merge shape when pin gap smaller then 1.5mm
			; expand 15 mils then shrink 10 mils to get 5 mils expand
			
			; check if pin overlap on assembly_top
			if( axlSingleSelectBox( box) && car( axlGetSelSet()->segments)->width == 0 then
				pin_expand_mils = 5
			else
				pin_expand_mils = 0
			)
			
			pin_points = GetPointsByBox_createsmd( box ( pin_expand_mils + expand_mils))
			pin_shape = CreateShape_createsmd( pin_points layer)
			pin_shape_ls = append1(pin_shape_ls pin_shape)
		)
		
		axlClearSelSet()
		axlSetFindFilter( ?enabled '(noall) ?onButtons '(noall))
		axlVisibleSet( visible_ls)

		axlShapeMerge( main_shape pin_shape_ls 'quiet)
		merged_shape = car( GetShapeList_utilityprogram( layer))
		; shrink expanded mils
		result_points = GetExpandPoints_createsmd( merged_shape -expand_mils)
		result_shape = CreateShape_createsmd( result_points layer)
		axlDeleteObject( merged_shape)
		
		; set property
		height_max = axlUIPrompt( "PACKAGE_HEIGHT_MAX")
		height_min = axlUIPrompt( "PACKAGE_HEIGHT_MIN")
		when( stringp( height_max) && !blankstrp( height_max)
			printf( "Set PACKAGE_HEIGHT_MAX to %s\n" height_max)
			axlDBAddProp( result_shape list( "PACKAGE_HEIGHT_MAX" atof( height_max)))
		)
		
		when( stringp( height_min) && !blankstrp( height_min)
			printf( "Set PACKAGE_HEIGHT_MIN to %s\n" height_min)
			axlDBAddProp( result_shape list( "PACKAGE_HEIGHT_MIN" atof( height_min)))
		)
		
		println( "3. Finished")
		return( t)
	)
)

; 4. PACKAGE GEOMETRY/DFA_BOUND_TOP :
;    同上與 PLACE_BOUND_TOP 一樣
procedure( CreateOnDFABoundTop_createsmd()
	prog( ( place_bound_top_shpae place_bound_top_poly)
		println( "4. PACKAGE GEOMETRY/DFA_BOUND_TOP")
		shape_ls = GetShapeList_utilityprogram( _layer_pkg_place_bound_top)
		when( dtpr( shape_ls) && onep( length( shape_ls))
			place_bound_top_shpae = car( shape_ls)
			place_bound_top_poly = car( axlPolyFromDB( place_bound_top_shpae))
			
			axlDBCreateShape( place_bound_top_poly t _layer_pkg_dfa_bound_top)
			println( "4. Finished")
			return( t)
		)
		
		return( nil)
	)
)
; 5. MANUFACTURING/NO_PROBE_TOP :
;    SHAPE 依照 ASSEMBLY_TOP 大小除非 pad 超過外框大小就依照 PAD 的大小用沿著 PAD 框起
;    並跟外框大小合併為一個 SHAPE 再往外推 0.381mm = 15mils
procedure( CreateOnNoProbeTop_createsmd()
	prog( ( layer assembly_top_outline assembly_top_points main_shape pin_ls pin_shape_ls
			merged_shape result_points)
		println( "5. MANUFACTURING/NO_PROBE_TOP")
		layer = _layer_manufacturing_no_probe_top
		expand_mils = axlMKSConvert( (1.5 / 2) "MM" "MILS")
		assembly_top_outline = GetAssemblyTopOutline_createsmd()
		assembly_top_points = GetExpandPoints_createsmd( assembly_top_outline ( 15 + expand_mils))
		main_shape = CreateShape_createsmd( assembly_top_points layer)
		
		pin_ls = GetPinList_utilityprogram( _layer_pin_top)
		foreach( pin pin_ls
			box = GetPinBox_createsmd( pin)
			pin_points = GetPointsByBox_createsmd( box ( 15 + expand_mils))
			
			pin_shape = CreateShape_createsmd( pin_points layer)
			pin_shape_ls = append1(pin_shape_ls pin_shape)
		)
		
		axlShapeMerge( main_shape pin_shape_ls 'quiet)
		merged_shape = car( GetShapeList_utilityprogram( layer))
		; shrink expanded mils
		result_points = GetExpandPoints_createsmd( merged_shape -expand_mils)
		CreateShape_createsmd( result_points layer)
		axlDeleteObject( merged_shape)
		
		println( "5. Finished")
		return( t)
	)
)

; 6. REF DES 3 個層面 填入 REF DES 類型 :
;    REF DES/ASSEMBLY_TOP
;    REF DES/SILKSCREEN_TOP
;    COMPONENT VALUE/DISPLAY_TOP
procedure( CreateRefLayer_createsmd()
	prog( ( result layer)
		println( "6. REF 3 layers")
		result = t
		orient = make_axlTextOrientation( ?textBlock "1" ?justify "center")
		text_height = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))->height * 1.6
		location = 0:( -text_height / 4)
		value = _create_setting_table[ _form_key_ref_types]
		
		layer = "REF DES/ASSEMBLY_TOP"
		axlDBCreateText( value location orient layer)
		
		layer = "REF DES/SILKSCREEN_TOP"
		axlDBCreateText( value location orient layer)
		
		layer = "COMPONENT VALUE/DISPLAY_TOP"
		axlDBCreateText( value location orient layer)
		
		println( "6. Finished")
		return( result)
	)
)

; 7. 零件的第一 PIN 要在 PACKAGE GEOMETRY/ASSEMBLY_TOP 及 PACKAGE GEOMETRY/SILKSCREEN_TOP 
;    加三角形 mark 指向第一 PIN 中心
procedure( CreatePin1Mark_createsmd()
	prog( ( file)
		println( "7. PIN mark")
		LoadClp_createsmd( "W:/footprint_building_aid_skill/0-0_Clip/mark.clp")
		println( "7. Finished")
		return( t)
	)
)

; 8. 每個零件都要在第一 PIN 跟最後一 PIN 標示排 PIN 的文字
;    在 PACKAGE GEOMETRY/ASSEMBLY_TOP & PACKAGE GEOMETRY/SILKSCREEN_TOP (optional)
procedure( CreatePinNote_createsmd()
	prog( ( pin_ls pin_count last_pin_str orient first_location last_location layer)
		println( "8. PIN note")
		pin_ls = GetPinList_utilityprogram( _layer_pin_top)
		pin_count = length( pin_ls)
		sprintf( last_pin_str "%d" pin_count)
		
		orient = make_axlTextOrientation( ?textBlock "1")
		text_height = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))->height * 1.6
		shape = car( GetShapeList_utilityprogram( _layer_manufacturing_no_probe_top))
		first_location = cadr( shape->bBox)
		last_location = axlMXYAdd( first_location text_height:0)
		
		layer = _layer_pkg_assembly_top
		axlDBCreateText( "1" first_location orient layer)
		axlDBCreateText( last_pin_str last_location orient layer)
		
		layer = _layer_pkg_silkscreen_top
		axlDBCreateText( "1" first_location orient layer)
		axlDBCreateText( last_pin_str last_location orient layer)
		
		println( "8. Finished")
		return( t)
	)
)

; 9. 板邊零件都需要建 PCB EDGE
;    在 BOARD GEOMETRY/PCB_EDGE 建立文字 PCB EDGE (optional)
procedure( CreatePCBEdge_createsmd()
	prog( ( layer orient)
		println( "9. PCB edge")
		layer = _layer_pcb_edge
		unless( axlIsLayer( layer)
			CreateLayer_createsmd( layer)
		)
		
		LoadClp_createsmd( "W:/footprint_building_aid_skill/0-0_Clip/PCB_EDGE.clp")
		
		println( "9. Finished")
		return( t)
	)
)

; 10. 每顆零件都要加 NOTE 在零件下方: 
;     在 PACKAGE GEOMETRY/BODY_CENTER
;     文字大小要用 TEXT_BLOCK #10 (height: 0.7620, width: 0.5080, line spacing: 0.7620)
;     數字大小固定
procedure( CreateSymbolNote_createsmd()
	prog( ( orient location layer pin_names pin_ls text)
		println( "10. Symbol note")
		orient = make_axlTextOrientation( ?textBlock "10" ?justify "left")
		text_height = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))->height * 1.6
		shape = car( GetShapeList_utilityprogram( _layer_manufacturing_no_probe_top))
		location = axlMXYAdd( car( shape->bBox) 0:-text_height)
		layer = _layer_pkg_body_center
		
		;;; padstack name
		pin_names = ""
		pin_ls = GetPinList_utilityprogram( _layer_pin_top)
		foreach( pin pin_ls
			unless( index( pin_names pin->name)
				unless( blankstrp( pin_names)
					pin_names = strcat( pin_names ",")
				)
				
				pin_names = strcat( pin_names pin->name)
			)
		)
		
		padstack_name = strcat( _note_padstack_name lowerCase( pin_names))
		axlDBCreateText( padstack_name location orient layer)
		location = axlMXYAdd( location 0:-text_height)
		
		;;; rev
		axlDBCreateText( _note_rev location orient layer)
		location = axlMXYAdd( location 0:-text_height)
		
		;;; date
		datetime = ParseDateTimeStrToFormat_utilityprogram( getCurrentTime())
		date = strcat( _note_date substring( datetime 1 10))
		axlDBCreateText( date location orient layer)
		
		println( "10. Finished")
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Create

;;;;;;;;;;;;;;;;;;;;;;;;; Delete

procedure( Delete_createsmd()
	prog( ( result)
		when( _delete_setting_table[ _form_key_silkscreen]
			DeleteOnSilkscreenTop_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_place_bound]
			DeleteOnPlaceBoundTop_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_dfa_bound]
			DeleteOnDFABoundTop_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_no_probe]
			DeleteOnNoProbeTop_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_ref_layer]
			DeleteRefLayer_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_pin1_mark]
			DeletePin1Mark_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_pin_note]
			DeletePinNote_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_pcb_edge]
			DeletePCBEdge_createsmd()
		)
		
		when( _delete_setting_table[ _form_key_symbol_note]
			DeleteSymbolNote_createsmd()
		)
	)
)

procedure( DeleteOnSilkscreenTop_createsmd()
	prog( ( line_ls)
		line_ls = GetLineList_utilityprogram( _layer_pkg_silkscreen_top)
		pin1_mark_ls = GetPin1MarkList_createsmd()
		line_ls = setof( x line_ls !member( x pin1_mark_ls))
		axlDeleteObject( line_ls)
	)
)

procedure( DeleteOnPlaceBoundTop_createsmd()
	prog( ( shape_ls)
		shape_ls = GetShapeList_utilityprogram( _layer_pkg_place_bound_top)
		axlDeleteObject( shape_ls)
	)
)

procedure( DeleteOnDFABoundTop_createsmd()
	prog( ( shape_ls)
		shape_ls = GetShapeList_utilityprogram( _layer_pkg_dfa_bound_top)
		axlDeleteObject( shape_ls)
	)
)

procedure( DeleteOnNoProbeTop_createsmd()
	prog( ( shape_ls)
		shape_ls = GetShapeList_utilityprogram( _layer_manufacturing_no_probe_top)
		axlDeleteObject( shape_ls)
	)
)

procedure( DeleteRefLayer_createsmd()
	prog( ( layer text_ls)
		layer = "REF DES/ASSEMBLY_TOP"
		text_ls = GetTextList_utilityprogram( layer)
		
		layer = "REF DES/SILKSCREEN_TOP"
		text_ls = append( text_ls GetTextList_utilityprogram( layer))
		
		layer = "COMPONENT VALUE/DISPLAY_TOP"
		text_ls = append( text_ls GetTextList_utilityprogram( layer))
		axlDeleteObject( text_ls)
	)
)

procedure( DeletePin1Mark_createsmd()
	prog( ( line_ls)
		line_ls = append( GetLineList_utilityprogram( _layer_pkg_assembly_top) GetLineList_utilityprogram( _layer_pkg_silkscreen_top))
		pin1_mark_ls = GetPin1MarkList_createsmd()
		axlDeleteObject( pin1_mark_ls)
	)
)

procedure( DeletePinNote_createsmd()
	prog( ( text_ls)
		text_ls = GetTextList_utilityprogram( _layer_pkg_assembly_top)
		text_ls = append( text_ls GetTextList_utilityprogram( _layer_pkg_silkscreen_top))
		axlDeleteObject( text_ls)
	)
)

procedure( DeletePCBEdge_createsmd()
	prog( ( text_ls line_ls)
		text_ls = GetTextList_utilityprogram( _layer_pcb_edge)
		axlDeleteObject( text_ls)
		
		line_ls = GetLineList_utilityprogram( _layer_pcb_edge)
		axlDeleteObject( line_ls)
	)
)

procedure( DeleteSymbolNote_createsmd()
	prog( ( text_ls)
		text_ls = GetTextList_utilityprogram( _layer_pkg_body_center)
		axlDeleteObject( text_ls)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;; End of Delete

;###########################################################################

procedure( GetAssemblyTopOutline_createsmd()
	prog( ( line_ls pin1_mark_ls assembly_top_outline)
		line_ls = GetLineList_utilityprogram( _layer_pkg_assembly_top)
		pin1_mark_ls = GetPin1MarkList_createsmd()
		assembly_top_outline = car( setof( x line_ls !member( x pin1_mark_ls)))
		return( assembly_top_outline)
	)
)

procedure( GetPin1MarkList_createsmd()
	prog( ( line_ls pin1_mark_ls)
		line_ls = append( GetLineList_utilityprogram( _layer_pkg_assembly_top) GetLineList_utilityprogram( _layer_pkg_silkscreen_top))
		pin1_mark_ls = setof( x line_ls ( ( x->prop != nil && x->prop->MARKING_USAGE == "PIN_ONE")
											|| ( x->layer == _layer_pkg_assembly_top && car( x->segments)->width > 0)))
		return( pin1_mark_ls)
	)
)

procedure( GetPinBox_createsmd( pin)
	prog( ( pad left_bot right_top)
		; because pin->bBox will include soldermask outline, so it will 2mils bigger
		pad = car( setof( x pin->pads ( x->layer == "ETCH/TOP" && x->figureName != "NULL")))
		; box = left bottom : right top
		left_bot = axlMXYAdd( pin->xy nth( 0 pad->bBox))
		right_top = axlMXYAdd( pin->xy nth( 1 pad->bBox))
		
		return( list( left_bot right_top))
	)
)

procedure( GetPointsByBox_createsmd( box @optional ( expand_mils 0))
	prog( ( left_bot right_top left_top right_bot)
		; box = left bottom : right top
		left_bot = nth( 0 box)
		right_top = nth( 1 box)
		left_top = list( nth( 0 left_bot) nth( 1 right_top))
		right_bot = list( nth( 0 right_top) nth( 1 left_bot))
		
		unless( expand_mils == 0
			expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
			left_bot = axlMXYAdd( left_bot -expand_width:-expand_width)
			right_top = axlMXYAdd( right_top expand_width:expand_width)
			left_top = axlMXYAdd( left_top -expand_width:expand_width)
			right_bot = axlMXYAdd( right_bot expand_width:-expand_width)
		)
		
		return( list( left_bot left_top right_top right_bot))
	)
)

procedure( GetExpandPoints_createsmd( path @optional ( expand_mils 0))
	prog( ( poly expand_points)
		; path or shape
		poly = car( axlPolyFromDB( path))
		if( expand_mils == 0 then
			; to make sure poly->vertices has correct points
			poly = car( axlPolyExpand( poly 1 'NONE))
			poly = car( axlPolyExpand( poly -1 'NONE))
		else
			expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
			poly = car( axlPolyExpand( poly expand_width 'NONE))
		)
		
		foreach( vertice poly->vertices
			expand_points = append1( expand_points car( vertice))
		)
		
		return( expand_points)
	)
)

procedure( CreateShape_createsmd( points layer)
	prog( ( path shape)
		; add the first point to complete the shape
		path = axlPathStart( append1( points car( points)))
		shape = car( axlDBCreateShape( path t layer))
		
		return( shape)
	)
)

procedure( CreateLayer_createsmd( layer)
	prog( ( result)
		result = axlLayerCreateNonConductor( layer)
		unless( result
			printf( "%s is not created!!\n" layer)
		)
		
		return( result)
	)
)

procedure( LoadClp_createsmd( file_full_name)
	prog( ()
		_clpFormid = nil
		_clpPinText = nil
		_clpSeverityLevel = nil
		_clpPasteContext = nil
		unless( isFile( file_full_name)
			printf( "ERROR: CreatePin1Mark() - %s not found!!" file_full_name)
			return( nil)
		)
		
		load( file_full_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( ShowForm_createsmd()
	prog( ( file_name form)
		file_name = "create_smd.form"
		LoadForm_createsmd( file_name)
		form = axlFormCreate( gensym() file_name '("east" "outer") 'FormActions_createsmd nil)
		
		; default settings
		unless( axlIsFormType( form)
			println( "ERROR: ShowForm() - form_id is not in form type")
			return( nil)
		)
		
		axlFormSetField( form _form_key_all t)
		SetAllFormOptions_createsmd( form t)
		axlFormDefaultButton( form _form_key_create)
		
		axlFormBuildPopup( form _form_key_ref_types _ref_type_ls)
		axlFormSetField( form _form_key_ref_types car( _ref_type_ls))
		
		axlFormDisplay( form)
		return( t)
	)
)

procedure( LoadForm_createsmd( file_name)
	prog( ( out_port group_width content_x sub_content_x group_x port_width port_height group_y y_start y_end 
	         button_width button_height button_x)
		group_width = 24
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		;;; header
		port_width = group_width + 2
		port_height = 120
		
		out_port = NewForm_utilityprogram( file_name "Create SMD" port_width port_height)
		unless( out_port
			return( nil)
		)
		
		;;; popup
		fprintf( out_port "POPUP <%s>\"a\"\"a\".\n" _form_key_ref_types)
		
		;;; control panel
		group_y = 1
		y_start = group_y
		y_end = y_start
		
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_all 'All content_x y_end 'ctrl)
		WriteFormCheckList_utilityprogram( out_port _form_key_none 'None ( content_x + 8) y_end 'ctrl)
		
		y_end = y_end + 2
		WriteFormGroup_utilityprogram( out_port 'Control group_x group_y group_width y_end)
		
		;;; selection of the setup package
		group_y = y_end + 2
		y_start = group_y
		y_end = y_start

		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_silkscreen "SILKSCREEN TOP" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_place_bound "PLACE BOUND TOP" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_dfa_bound "DFA BOUND TOP" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_no_probe "NO PROBE TOP" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_ref_layer "Ref layers" content_x y_end)
		y_end = y_end + 2
		WriteFormEnumSet_utilityprogram( out_port _form_key_ref_types ( content_x + 4) y_end 12)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pin1_mark "PIN1 mark" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pin_note "PIN notes" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_pcb_edge "PCB Edge" content_x y_end)
		y_end = y_end + 2
		WriteFormCheckList_utilityprogram( out_port _form_key_symbol_note "Symbol notes" content_x y_end)
		
		WriteFormGroup_utilityprogram( out_port 'Setup group_x group_y group_width (y_end - y_start + 4))
		
		;;;;; button field
		button_width = group_width / 2
		button_height = 2
		
		;;; button for run
		y_end = y_end + 3
		button_x = group_x
		WriteFormButton_utilityprogram( out_port _form_key_create "Create" button_x y_end button_width button_height)
		
		;;; button for close
		button_x = group_x + button_width
		WriteFormButton_utilityprogram( out_port _form_key_delete "Delete" button_x y_end button_width button_height)
		
		;;; tail
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		return( t)
	)
)

procedure( FormActions_createsmd( form)
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
				SetAllFormOptions_createsmd( form t)
			)
			( equal( cur_field _form_key_none)
				SetAllFormOptions_createsmd( form)
			)
			( equal( cur_field symbolToString( _form_key_create))
				valid = axlFormGetField( form _form_key_silkscreen)
				_create_setting_table[ _form_key_silkscreen] = valid
				
				valid = axlFormGetField( form _form_key_place_bound)
				_create_setting_table[ _form_key_place_bound] = valid
				
				valid = axlFormGetField( form _form_key_dfa_bound)
				_create_setting_table[ _form_key_dfa_bound] = valid
				
				valid = axlFormGetField( form _form_key_no_probe)
				_create_setting_table[ _form_key_no_probe] = valid
				
				valid = axlFormGetField( form _form_key_ref_layer)
				_create_setting_table[ _form_key_ref_layer] = valid
				
				valid = axlFormGetField( form _form_key_ref_types)
				_create_setting_table[ _form_key_ref_types] = valid
				
				valid = axlFormGetField( form _form_key_pin1_mark)
				_create_setting_table[ _form_key_pin1_mark] = valid
				
				valid = axlFormGetField( form _form_key_pin_note)
				_create_setting_table[ _form_key_pin_note] = valid
				
				valid = axlFormGetField( form _form_key_pcb_edge)
				_create_setting_table[ _form_key_pcb_edge] = valid
				
				valid = axlFormGetField( form _form_key_symbol_note)
				_create_setting_table[ _form_key_symbol_note] = valid
				
				_run_create = t
				Create_createsmd()
				;axlFormClose( form)
			)
			( equal( cur_field symbolToString( _form_key_delete))
				msg = "Delete checked items?"
				unless( axlUIYesNo( msg "Delete items")
					return( nil)
				)
				
				valid = axlFormGetField( form _form_key_silkscreen)
				_delete_setting_table[ _form_key_silkscreen] = valid
				
				valid = axlFormGetField( form _form_key_place_bound)
				_delete_setting_table[ _form_key_place_bound] = valid
				
				valid = axlFormGetField( form _form_key_dfa_bound)
				_delete_setting_table[ _form_key_dfa_bound] = valid
				
				valid = axlFormGetField( form _form_key_no_probe)
				_delete_setting_table[ _form_key_no_probe] = valid
				
				valid = axlFormGetField( form _form_key_ref_layer)
				_delete_setting_table[ _form_key_ref_layer] = valid
				
				valid = axlFormGetField( form _form_key_ref_types)
				_delete_setting_table[ _form_key_ref_types] = valid
				
				valid = axlFormGetField( form _form_key_pin1_mark)
				_delete_setting_table[ _form_key_pin1_mark] = valid
				
				valid = axlFormGetField( form _form_key_pin_note)
				_delete_setting_table[ _form_key_pin_note] = valid
				
				valid = axlFormGetField( form _form_key_pcb_edge)
				_delete_setting_table[ _form_key_pcb_edge] = valid
				
				valid = axlFormGetField( form _form_key_symbol_note)
				_delete_setting_table[ _form_key_symbol_note] = valid
				
				_run_delete = t
				Delete_createsmd()
				;axlFormClose( form)
			)
		)
		
		return( t)
	)
)

procedure( SetAllFormOptions_createsmd( form @optional ( value nil))
	prog( ()
		unless( booleanp( value)
			println( "ArgErr: set_form_options() - no is not a boolean")
			value = nil
		)
		
		axlFormSetField( form _form_key_silkscreen value)
		axlFormSetField( form _form_key_place_bound value)
		axlFormSetField( form _form_key_dfa_bound value)
		axlFormSetField( form _form_key_no_probe value)
		axlFormSetField( form _form_key_ref_layer value)
		axlFormSetField( form _form_key_pin1_mark value)
		axlFormSetField( form _form_key_pin_note value)
		axlFormSetField( form _form_key_pcb_edge value)
		axlFormSetField( form _form_key_symbol_note value)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "create_smd" 'Main_createsmd ?cmdType "general")
/*
(encrypt "c:/skill/create_smd_v1d1.il" "c:/skill/create_smd_v1d1.ile")
(load "create_smd_v1d1.il")
(load "create_smd_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup