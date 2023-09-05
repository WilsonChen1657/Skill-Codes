/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/20                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To create symbols according to DATASHEET and PAD                       #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable
setq( _allegro_unit car( axlDBGetDesignUnits()))
setq( _pcb_footprint_path "W:/footprint_building_aid_skill/2-0_pcb_footprint/")
setq( _footprint_clp_path "W:/footprint_building_aid_skill/0-0_Clip/")
when( _is_test_mode
	_footprint_clp_path = "W:/footprint_building_aid_skill/test/0-0_Clip/"
)

setq( _layer_pkg_at "PACKAGE GEOMETRY/ASSEMBLY_TOP")
setq( _layer_pkg_skt "PACKAGE GEOMETRY/SILKSCREEN_TOP")
setq( _layer_pkg_pbt "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
setq( _layer_pkg_pbb "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
setq( _layer_pkg_dfabt "PACKAGE GEOMETRY/DFA_BOUND_TOP")
setq( _layer_pkg_dfabb "PACKAGE GEOMETRY/DFA_BOUND_BOTTOM")
setq( _layer_pkg_bc "PACKAGE GEOMETRY/BODY_CENTER")
setq( _layer_pkg_pn "PACKAGE GEOMETRY/PIN_NUMBER")
setq( _layer_manu_npt "MANUFACTURING/NO_PROBE_TOP")
setq( _layer_manu_npb "MANUFACTURING/NO_PROBE_BOTTOM")
setq( _layer_rte_ko_a "ROUTE KEEPOUT/ALL")
setq( _layer_rte_ko_b "ROUTE KEEPOUT/BOTTOM")
setq( _layer_pkg_ko_b "PACKAGE KEEPOUT/BOTTOM")
setq( _layer_pkg_ko_t "PACKAGE KEEPOUT/TOP")
setq( _layer_pin_top "PIN/TOP")
setq( _layer_pkg_pin_num "PACKAGE GEOMETRY/PIN_NUMBER")
setq( _layer_pcb_edge "BOARD GEOMETRY/PCB_EDGE")
setq( _layer_ref_at "REF DES/ASSEMBLY_TOP")
setq( _layer_ref_st "REF DES/SILKSCREEN_TOP")
setq( _layer_com_dt "COMPONENT VALUE/DISPLAY_TOP")

setq( _assembly_top_poly nil)
setq( _pin_poly_table makeTable( 'pin_poly nil))

setq( _note_padstack_name "padstack name:")
setq( _note_rev "rev:(recommend)")
setq( _note_date "date:")

setq( _create_setting_table makeTable( "create_setting" nil))
setq( _delete_setting_table makeTable( "delete_setting" nil))
setq( _form_key_all "control_all")
setq( _form_key_none "control_none")

;; execution button
setq( _form_key_create 'create)
setq( _form_key_delete 'delete)
setq( _form_key_close 'close)
setq( _create_msg_format "Create on %s\n")
setq( _check_msg_format "Check %s\n")

setq( _ref_type_ls list( "J*" "R*" "K*" "L*" "U*" "H*" "Q*" "Y*" "F*" "D*" "C*" "SW*" "EC*" "LED*" "LBL*" "MH*"))

setq( _expand_tolerance 2)
setq( _merge_expand_mils axlMKSConvert( (1.5 / 2) "MM" "MILS"))

defstruct( merge_data_struct shape poly)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

; PACKAGE GEOMETRY/ASSEMBLY_TOP :
; 依照 DATASHEET 建立
procedure( CheckSymbol_footprintutilityprogram( @optional (check_pin t))
	prog( ( result layer)
		result = t
		;;; check datasheet on assembly_top
		layer = _layer_pkg_at
		unless( axlIsLayer( layer)
			warn( "%s not found!!\n" layer)
			result = nil
		)
		
		when( result
			at_outline = GetAssemblyTopOutline_footprintutilityprogram()
			unless( at_outline
				warn( "Main outline not found on %s!!\n" layer)
				result = nil
			)			
		)
		
		;;; check PAD
		when( and( result check_pin)
			pin_ls = axlDBGetDesign()->pins
			unless( dtpr( pin_ls)
				warn( "PIN not found on %s!!\n" layer)
				result = nil
			)
		)
		
		return( result)
	)
)

; PACKAGE GEOMETRY/SILKSCREEN_TOP :
; 依照 ASSEMBLY_TOP 外框大小往外推 8mils
; 第二層再外推 80mils ( BGA only )
; 再將線寬變成 0.1524=6mils
; 遇到白漆壓到 PAD 一定要切掉線段避免壓在 PAD 上
; 白漆距離 PAD 要有 6mils 以上
procedure( CreateOnSilkscreenTop_footprintutilityprogram( @optional (expand_mils 8))
	let( ( at_outline expand_points layer visible_ls pin_ls pin_box_ls line_ls need_delete_line_ls)
		layer = _layer_pkg_skt
		info( _create_msg_format layer)
		
		expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
		at_outline = GetAssemblyTopOutline_footprintutilityprogram()
		line_width = GetUnitValueByMils_utilityprogram( 6)
		CreateExpandPath_footprintutilityprogram( at_outline layer expand_width ?line_width line_width)
		
		pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
		
		line_ls = GetLineList_utilityprogram( layer)
		line_id = car( setof( x line_ls !member( x pin1_mark_ls)))
		line_poly = axlPolyFromDB( line_id ?endCapType 'ROUND ?line2poly t)
		
		; check overlap
		pin_poly_ls = nil
		; pad soldermask is pad expand 2mils
		pin_expand_width = GetUnitValueByMils_utilityprogram( 6)
		line_half_width = line_width / 2
		foreach( pin_id axlDBGetDesign()->pins
			pin_poly = car( axlPolyFromDB( pin_id))
			pin_poly = car( axlPolyExpand( pin_poly pin_expand_width 'NONE))
			pin_poly_ls = append1( pin_poly_ls pin_poly)
		)
		
		delete_data_ls = nil
		foreach( pin_poly pin_poly_ls
			overlap_poly = car( axlPolyOperation( pin_poly line_poly 'AND))
			when( overlap_poly
				point = car( overlap_poly->bBox)
				pin_box = car( axlPolyExpand( pin_poly line_half_width 'NONE))->bBox
				delete_data_ls = append1( delete_data_ls list( point pin_box))
				; to make sure it can select all line segments to delete
				point = cadr( overlap_poly->bBox)
				delete_data_ls = append1( delete_data_ls list( point pin_box))
				point = axlMidPointLine( overlap_poly->bBox)
				delete_data_ls = append1( delete_data_ls list( point pin_box))
			)
		)
		
		axlVisibleDesign( nil)
		axlVisibleLayer( layer t)
		foreach( data delete_data_ls
			point = car( data)
			pin_box = cadr( data)
			DeleteByRectangle_footprintutilityprogram( point pin_box)
		)
		
		axlClearSelSet()
		axlShell( "done")
		
		line_ls = GetLineList_utilityprogram( _layer_pkg_skt)
		pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
		line_ls = setof( x line_ls !member( x pin1_mark_ls))
		target_length = GetUnitValueByMM_utilityprogram( 1.5) - GetUnitValueByMils_utilityprogram( 6) * 2
		SetFindFilter_utilityprogram( '(lines))
		need_delete_line_ls = append( need_delete_line_ls setof( x line_ls ( axlDBGetLength( x) < target_length 
																				&& axlSingleSelectBox( x->bBox) 
																				&& length( axlGetSelSet()) == 1)))
		ResetFindFilter_utilityprogram()
		
		when( dtpr( need_delete_line_ls)
			msg = "Do you want to delete line on SILKSCREEN_TOP where pin to pin gap is smaller than 1.5mm?"
			when( axlUIYesNo( msg "Delete line")
				; delete where length smaller than 1.5mm
				axlDeleteObject( need_delete_line_ls)
			)
		)

		axlClearSelSet()
	)
)

; PACKAGE GEOMETRY/PLACE_BOUND_TOP :
; SHAPE 依照 ASSEMBLY_TOP 大小
; 除非 PAD 的 soldermask 超過外框大小就依照 PAD 的大小為基準點外推 5mils 包住整個 PAD
; PACKAGE_HEIGHT_MAX 自行輸入
procedure( CreateOnPlaceBoundTop_footprintutilityprogram( @key (height_max nil))
	let( ( layer at_outline main_poly soldermask_expand_width pin_expand_mils main_shape_id pin_shape_ls result_shape)
		layer = _layer_pkg_pbt
		info( _create_msg_format layer)
		at_outline = GetAssemblyTopOutline_footprintutilityprogram()
		main_poly = car( axlPolyFromDB( axlDB2Path( at_outline)))
		
		soldermask_expand_width = GetUnitValueByMils_utilityprogram( 2)
		pin_expand_mils = 5
		foreach( pin_id axlDBGetDesign()->pins
			pin_poly = car( axlPolyFromDB( pin_id))
			soldermask_poly = car( axlPolyExpand( pin_poly soldermask_expand_width 'NONE))
			overlap_poly = car( axlPolyOperation( soldermask_poly main_poly 'AND))
			if( axlGeoEqual( overlap_poly->area soldermask_poly->area)
				expand_mils = _merge_expand_mils
				expand_mils = _merge_expand_mils + pin_expand_mils
			)
			
			expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
			pin_poly = car( axlPolyExpand( pin_poly expand_width 'NONE))
			pin_shape_id = car( axlDBCreateShape( pin_poly t layer))
			pin_shape_ls = append1( pin_shape_ls pin_shape_id)
		)
		
		main_shape_id = car( axlDBCreateShape( main_poly t layer))
		if( dtpr( pin_shape_ls)
			result_shape = MergeShapesWithMain_footprintutilityprogram( main_shape_id pin_shape_ls _merge_expand_mils)
			result_shape = main_shape_id
		)
		
		if( height_max
			height_max = GetUnitValueByMils_utilityprogram( height_max)
			height_max = axlUIPrompt( sprintf( nil "%s\nPACKAGE_HEIGHT_MAX (%s)" layer _allegro_unit))
		)
		
		axlDBAddProp( result_shape list( "PACKAGE_HEIGHT_MAX" height_max))
	)
)

; PACKAGE GEOMETRY/DFA_BOUND_TOP :
; 同上與 PLACE_BOUND_TOP 一樣
procedure( CreateOnDFABoundTop_footprintutilityprogram()
	let( ( shape_ls place_bound_top_shpae place_bound_top_poly)
		info( _create_msg_format _layer_pkg_pbt)
		shape_ls = GetShapeList_utilityprogram( _layer_pkg_pbt)
		when( dtpr( shape_ls) && onep( length( shape_ls))
			place_bound_top_shpae = car( shape_ls)
			place_bound_top_poly = car( axlPolyFromDB( place_bound_top_shpae))
			
			axlDBCreateShape( place_bound_top_poly t _layer_pkg_dfabt)
		)
	)
)
; MANUFACTURING/NO_PROBE_TOP :
; SHAPE 依照 ASSEMBLY_TOP 大小除非 pad 超過外框大小就依照 PAD 的大小用沿著 PAD 框起
; 並跟外框大小合併為一個 SHAPE 再往外推 0.381mm = 15mils
procedure( CreateOnNoProbeTop_footprintutilityprogram()
	let( ( layer base_expand_mils at_outline main_poly main_shape_id pin_shape_ls)
		layer = _layer_manu_npt
		info( _create_msg_format layer)
		base_expand_mils = 15
		at_outline = GetAssemblyTopOutline_footprintutilityprogram()
		main_poly = car( axlPolyFromDB( axlDB2Path( at_outline)))
		pin_ls = setof( x axlDBGetDesign()->pins x->bBox != list( '(0.0 0.0) '(0.0 0.0)))
		when( dtpr( pin_ls)
			pin_expand_width = GetUnitValueByMils_utilityprogram( _merge_expand_mils)
			foreach( pin_id axlDBGetDesign()->pins
				pin_poly = car( axlPolyFromDB( pin_id))
				pin_poly = car( axlPolyExpand( pin_poly pin_expand_width 'NONE))
				pin_shape_id = car( axlDBCreateShape( pin_poly t layer))
				pin_shape_ls = append1( pin_shape_ls pin_shape_id)
			)
		)
		
		main_shape_id = car( axlDBCreateShape( main_poly t layer))
		if( dtpr( pin_shape_ls)
			result_shape = MergeShapesWithMain_footprintutilityprogram( main_shape_id pin_shape_ls _merge_expand_mils)
			result_shape = main_shape_id
		)
		
		result_poly = car( axlPolyFromDB( result_shape))
		result_poly = car( axlPolyExpand( result_poly GetUnitValueByMils_utilityprogram( base_expand_mils) 'NONE))
		axlDBCreateShape( result_poly t layer)
		axlDeleteObject( result_shape)
	)
)

; PACKAGE GEOMETRY/ PLACE_BOUND_BOT :
; 每個 PIN 上加 SHAPE
; 大小依照 PAD 的大小 & 形狀
; PACKAGE_HEIGHT_MAX 固定為 0.1 mil
procedure( CreateOnPlaceBoundBottom_footprintutilityprogram()
	let( ( layer dip_pin_ls height_max)
		layer = _layer_pkg_pbb
		info( _create_msg_format layer)
		dip_pin_ls = GetThroughPinList_footprintutilityprogram()
		height_max = GetUnitValueByMils_utilityprogram( 0.1)
		CreateShapeOnPin_footprintutilityprogram( dip_pin_ls layer ?height_max height_max)
	)
)

; ROUTE KEEPOUT/ALL :
; 在 NPTH(不吃錫) 的 PIN 上加 SHAPE
; 大小依照 PAD 的大小 & 形狀 單邊加 12 mils 總共加 24 mils
procedure( CreateOnRouteKeepoutAll_footprintutilityprogram()
	let( ( layer expand_width pin_ls)
		layer = _layer_rte_ko_a
		info( _create_msg_format layer)
		dip_pin_ls = GetThroughPinList_footprintutilityprogram()
		npth_pin_ls = setof( x dip_pin_ls x->definition->plating == "NON_PLATED")
		CreateShapeOnPin_footprintutilityprogram( npth_pin_ls layer ?expand_mils 12)
	)
)

; PACKAGE KEEPOUT/BOTTOM :
; 在 PTH(吃錫) 的 PIN 上加 SHAPE
; 大小依照 PAD 的大小 & 形狀 單邊加 200 mils 總共加 400 mils
; PACKAGE_HEIGHT_MIN 固定為 0.1 mil
procedure( CreateOnPackageKeepoutBottom_footprintutilityprogram()
	let( ( layer dip_pin_ls pth_pin_ls height_min shape_ls)
		layer = _layer_pkg_ko_b
		info( _create_msg_format layer)
		; merge shape will have very small difference, will cause check error, so expand 2 mils more
		dip_pin_ls = GetThroughPinList_footprintutilityprogram()
		pth_pin_ls = setof( x dip_pin_ls x->definition->plating == "PLATED")
		height_min = GetUnitValueByMils_utilityprogram( 0.1)
		CreateShapeOnPin_footprintutilityprogram( pth_pin_ls layer ?expand_mils 200 ?height_min height_min)
		
		MergeShapesOnlayer_footprintutilityprogram( layer)
		; set property
		
		shape_ls = GetShapeList_utilityprogram( layer)
		foreach( shape_id shape_ls
			axlDBAddProp( shape_id list( "PACKAGE_HEIGHT_MIN" height_min))
		)
	)
)

; PACKAGE KEEPOUT/TOP :
; 在 PTH(吃錫) 的 PIN 上加 SHAPE
; 大小依照 PAD 的大小 & 形狀 單邊加 200 mils 總共加 400 mils
; PACKAGE_HEIGHT_MIN 固定為 0.1 mil
; 切除與 PACKAGE GEOMETRY/PLACE_BOUND_TOP 重疊的區域
procedure( CreateOnPackageKeepoutTop_footprintutilityprogram()
	prog( ( layer pbt_shape_id pbt_poly pth_pin_ls height_min shape_ls)
		layer = _layer_pkg_ko_t
		info( _create_msg_format layer)
		pbt_shape_id = car( GetShapeList_utilityprogram( _layer_pkg_pbt))
		unless( pbt_shape_id
			axlUIConfirm( sprintf( nil "Create shape on %s first!" _layer_pkg_pbt))
			return( nil)
		)
		
		pbt_poly = car( axlPolyFromDB( pbt_shape_id))
		
		pth_pin_ls = setof( x axlDBGetDesign()->pins x->definition->plating == "PLATED")
		height_min = GetUnitValueByMils_utilityprogram( 0.1)
		CreateShapeOnPin_footprintutilityprogram( pth_pin_ls layer ?expand_mils 200 ?height_min height_min)
		
		; delete PLACE_BOUND_TOP area on pin shape first then merge shape
		shape_ls = GetShapeList_utilityprogram( layer)
		foreach( shape_id shape_ls
			poly = car( axlPolyFromDB( shape_id))
			poly = car( axlPolyOperation( poly pbt_poly 'ANDNOT))
			when( poly
				axlDBCreateShape( poly t layer)
			)
		)
		
		axlDeleteObject( shape_ls)
		
		MergeShapesOnlayer_footprintutilityprogram( layer)
		
		; set property
		shape_ls = GetShapeList_utilityprogram( layer)
		foreach( shape_id shape_ls
			axlDBAddProp( shape_id list( "PACKAGE_HEIGHT_MIN" height_min))
		)
	)
)

; 板邊零件都需要建 PCB EDGE
; 在 BOARD GEOMETRY/PCB_EDGE 建立文字 PCB EDGE (optional)
procedure( CreatePCBEdge_footprintutilityprogram()
	let( ( layer)
		layer = _layer_pcb_edge
		info( _create_msg_format layer)
		unless( axlIsLayer( layer)
			CreateLayer_footprintutilityprogram( layer)
		)
		
		LoadClp_footprintutilityprogram( strcat( _footprint_clp_path "PCB_EDGE.clp"))
	)
)

; REF DES 3 個層面 填入 REF DES 類型 :
; REF DES/ASSEMBLY_TOP 及 REF DES/SILKSCREEN_TOP 及 COMPONENT VALUE/DISPLAY_TOP
procedure( CreateRefLayer_footprintutilityprogram( value)
	let( ( orient text_height location)
		info( _create_msg_format "REF DES layers")
		
		orient = make_axlTextOrientation( ?textBlock "1" ?justify "center")
		text_height = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))->height * 1.6
		location = 0:( -text_height / 4)
		
		axlDBCreateText( value location orient _layer_ref_at)
		axlDBCreateText( value location orient _layer_ref_st)
		axlDBCreateText( value location orient _layer_com_dt)
	)
)

; 零件的第一 PIN 要在 PACKAGE GEOMETRY/ASSEMBLY_TOP 及 PACKAGE GEOMETRY/SILKSCREEN_TOP 
; 加三角形 mark 指向第一 PIN 中心
procedure( CreatePin1Mark_footprintutilityprogram( value)
	let( ( pin1_id)
		info( "Create Pin 1 mark\n")
		pin1_id = SetPkgPinOne_footprintutilityprogram()
		
		CreatePin1MarkPath_footprintutilityprogram( pin1_id->xy ?size value)
		LoadClp_footprintutilityprogram( strcat( _footprint_clp_path "mark.clp"))
	)
)

; 每個零件都要在第一 PIN 跟最後一 PIN 標示排 PIN 的文字
; 在 PACKAGE GEOMETRY/ASSEMBLY_TOP & PACKAGE GEOMETRY/SILKSCREEN_TOP (optional)
procedure( CreatePinNote_footprintutilityprogram( @optional (placement nil))
	prog( ( orient text_height prompt pin_ls expand_distance)
		info( "Create Pin note\n")
		orient = make_axlTextOrientation( ?textBlock "1" ?justify "center")
		text_height = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))->height * 1.6
		
		sprintf( prompt "Right-click \"Temp Group\" and select pins to add pin note and right-click \"Complete\" then right-click \"Done\"")
		when( placement
			sprintf( msg "Select %s pins\n" symbolToString( placement))
			prompt = strcat( msg prompt)
		)
		
		axlUIConfirm( prompt)
		axlVisibleLayer( _layer_pin_top t)
		axlVisibleLayer( _layer_pkg_pin_num t)
		
		at_outline = GetAssemblyTopOutline_footprintutilityprogram()
		outline_left_down = car( at_outline->bBox)
		outline_right_up = cadr( at_outline->bBox)
		
		pin_ls = SelectObjectByUser_footprintutilityprogram( '(pins) ?prompt prompt)
		unless( dtpr( pin_ls)
			return( nil)
		)
		
		expand_distance = GetUnitValueByMils_utilityprogram( 33)
		
		cond( 
			( placement == 'horizontal
				rexCompile( "[A-Z]")
				pin_numbers = UniqueList_utilityprogram( mapcar( lambda( (x) rexReplace(x "" 0)) pin_ls~>number))
				when( length( pin_numbers) != length( pin_ls)
					rexCompile( "[0-9]")
				)
				
				text_y = cadr( outline_right_up)
				pin_y = cadr( car( pin_ls)->xy)
				if( abs( pin_y - text_y) > abs( pin_y - cadr( outline_left_down)) then
					text_y = cadr( outline_left_down)
					text_y = text_y - expand_distance - (text_height / 2)
				else
					text_y = text_y + expand_distance
				)
				
				foreach( pin_id pin_ls
					number = rexReplace( pin_id->number "" 0)
					location = list( car( pin_id->xy) text_y)
					axlDBCreateText( number location orient _layer_pkg_at)
					axlDBCreateText( number location orient _layer_pkg_skt)
				)
			)
			( placement == 'vertical
				rexCompile( "[0-9]")
				pin_numbers = UniqueList_utilityprogram( mapcar( lambda( (x) rexReplace(x "" 0)) pin_ls~>number))
				when( length( pin_numbers) != length( pin_ls)
					rexCompile( "[A-Z]")
				)
				
				text_placement_fix = text_height / 3
				text_x = car( outline_left_down) - expand_distance - text_placement_fix
				foreach( pin_id pin_ls
					number = rexReplace( pin_id->number "" 0)
					location = list( text_x (cadr( pin_id->xy) - text_placement_fix))
					axlDBCreateText( number location orient _layer_pkg_at)
					axlDBCreateText( number location orient _layer_pkg_skt)
				)
			)
			( t
				location = cadr( at_outline->bBox)
				location = axlMXYAdd( location text_height:0)
				foreach( pin_id pin_ls
					location = axlMXYAdd( location 0:text_height)
					axlDBCreateText( pin_id->number location orient _layer_pkg_at)
					axlDBCreateText( pin_id->number location orient _layer_pkg_skt)
				)
			)
		)
		
		return( t)
	)
)

; 每顆零件都要加 NOTE 在零件下方: 
; 在 PACKAGE GEOMETRY/BODY_CENTER
; 文字大小要用 TEXT_BLOCK #10 (height: 0.7620, width: 0.5080, line spacing: 0.7620)
; 數字大小固定
procedure( CreateSymbolNote_footprintutilityprogram()
	let( ( orient location layer pin_names)
		info( "Create Symbol note\n")
		orient = make_axlTextOrientation( ?textBlock "10" ?justify "left")
		text_height = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))->height * 1.6
		
		axlVisibleDesign( t)
		SetFindFilter_utilityprogram( '(shapes))
		axlAddSelectAll()
		shape_ls = axlGetSelSet()
		axlClearSelSet()
		shape_id = car( sort( shape_ls lambda( (a b) cadr( car( a->bBox)) < cadr( car( b->bBox)))))
		
		location = axlMXYAdd( car( shape_id->bBox) 0:-text_height)
		layer = _layer_pkg_bc
		
		;;; padstack name
		pin_names = ""
		foreach( pin_id axlDBGetDesign()->pins
			unless( index( pin_names pin_id->name)
				unless( blankstrp( pin_names)
					pin_names = strcat( pin_names ",")
				)
				
				pin_names = strcat( pin_names pin_id->name)
			)
		)
		
		unless( blankstrp( pin_names)
			padstack_name = strcat( _note_padstack_name lowerCase( pin_names))
			axlDBCreateText( padstack_name location orient layer)
			location = axlMXYAdd( location 0:-text_height)
		)
		;;; rev
		axlDBCreateText( _note_rev location orient layer)
		location = axlMXYAdd( location 0:-text_height)
		
		;;; date
		datetime = ParseDateTimeStrToFormat_utilityprogram( getCurrentTime())
		date = strcat( _note_date substring( datetime 1 10))
		axlDBCreateText( date location orient layer)
	)
)

; 設定 pth pin 的屬性
; LEAD_DIAMETER & BACKDRILL_MIN_PIN_PTH
; 依照 drillDiameter 分別設定
procedure( SetupPinProperties_footprintutilityprogram()
	let( ( pth_pin_ls drill_size_ls drill_size_table)
		info( "Set pth pin properties\n")
		pth_pin_ls = setof( x axlDBGetDesign()->pins x->definition->plating == "PLATED")
		drill_size_ls = UniqueList_utilityprogram( pth_pin_ls~>definition~>drillDiameter)
		drill_size_table = makeTable( "drill_size" nil)
		foreach( drill_size drill_size_ls
			sprintf( msg "Pin's drill size : %L\n" drill_size)
			lead_diameter = axlUIPrompt( strcat( msg "LEAD_DIAMETER"))
			backdrill = axlUIPrompt( strcat( msg "BACKDRILL_MIN_PIN_PTH"))
			drill_size_table[ drill_size] = list( lead_diameter backdrill)
		)
		
		foreach( pin_id pth_pin_ls
			data = drill_size_table[ pin_id->definition->drillDiameter]
			lead_diameter = car( data)
			backdrill = cadr( data)
			axlDBAddProp( pin_id list( "LEAD_DIAMETER" lead_diameter))
			axlDBAddProp( pin_id list( "BACKDRILL_MIN_PIN_PTH" backdrill))
		)
		
		RefreshPins_footprintutilityprogram()
	)
)

; 將中心點移至 pin 1
procedure( SetPin1AsCenterOrigin_footprintutilityprogram()
	let( ( pin_ls pin1_id)
		info( "Set pin1 as center origin\n")
		pin_ls = axlDBGetDesign()->pins
		pin1_id = car( setof( x pin_ls x->prop->PKG_PIN_ONE))
		if( pin1_id then
			; to get current xy
			pin1_id = axlDBRefreshId( pin1_id)
			if( pin1_id->xy == '(0 0) then
				result = axlUIYesNo( "Select another pin as pin1?")
				when( result
					pin1_id = SetPkgPinOne_footprintutilityprogram()
					MoveOrigin_footprintutilityprogram( pin1_id->xy)
				)
			else
				MoveOrigin_footprintutilityprogram( pin1_id->xy)
			)
		else
			pin1_id = SetPkgPinOne_footprintutilityprogram()
			MoveOrigin_footprintutilityprogram( pin1_id->xy)
		)
		
		RefreshPins_footprintutilityprogram()
		info( "Finish\n")
	)
)

; PACKAGE GEOMETRY/PIN_NUMBER ( for BGA )
; 文字大小要用 TEXT_BLOCK #11 (height: 0.2mm, width: 0.1mm, line spacing: 0.1mm)
; 數字大小固定
procedure( CreatePinNumber_footprintutilityprogram()
	let( ( layer main_orient)
		info( "Create Pin number\n")
		layer = _layer_pkg_pn
		
		text_ls = GetTextList_utilityprogram( layer)
		wrong_text_ls = setof( x text_ls x->textBlock != "11")~>text
		unless( dtpr( wrong_text_ls)
			; nothing wrong
			return( t)
		)
		
		main_orient = make_axlTextOrientation( ?textBlock "11" ?justify "center")
		wrong_pin_ls = setof( x axlDBGetDesign()->pins member( x->number wrong_text_ls))
		foreach( pin_id wrong_pin_ls
			orient = main_orient
			unless( zerop( pin_id->rotation)
				orient = make_axlTextOrientation( ?textBlock "11" ?justify "center" ?rotation pin_id->rotation)
			)
			
			axlDBCreateText( pin_id->number pin_id->xy orient layer pin_id)
		)
		
		; delete wrong text
		text_ls = GetTextList_utilityprogram( layer)
		wrong_text_ls = setof( x text_ls x->textBlock != "11")
		axlDeleteObject( wrong_text_ls)
	)
)

procedure( CreatePathOnPin_footprintutilityprogram( pin_id layer)
	let( ( pin_poly vertices start path)
		printf( "Create path on Pin on %s\n" layer)
		pin_poly = car( axlPolyFromDB( pin_id))
		CreatePathByPoly_footprintutilityprogram( pin_poly layer)
	)
)

procedure( CreatePathByPoly_footprintutilityprogram( poly layer @key (line_width 0.0))
	let( ( shape_id shape_path_obj path_segments start result_path)
		; create a expanded shape and turn into path
		shape_id = car( axlDBCreateShape( poly t layer))
		shape_path_obj = axlDB2Path( shape_id)
		path_segments = axlPathGetPathSegs( shape_path_obj)
		start = car( path_segments)
		path_segments = remq( start path_segments)
		
		result_path = axlPathStart( list( axlPathSegGetEndPoint( start)) line_width)
		foreach( path_seg path_segments
			if( axlPathSegGetArcCenter( path_seg)
				result_path = axlPathArcCenter( result_path line_width axlPathSegGetEndPoint( path_seg) axlPathSegGetArcClockwise( path_seg) axlPathSegGetArcCenter( path_seg))
				result_path = axlPathLine( result_path line_width axlPathSegGetEndPoint( path_seg))
			)
		)
		
		axlDBCreatePath( result_path layer)
		axlDeleteObject( shape_id)
	)
)

procedure( CreateExpandPath_footprintutilityprogram( path_id layer expand_width @key (line_width 0.0))
	let( ( path_obj path_poly shape_id shape_path_obj path_segments start result_path)
		path_obj = axlDB2Path( path_id)
		path_poly = car( axlPolyFromDB( path_obj))
		path_poly = car( axlPolyExpand( path_poly expand_width 'NONE))
		
		CreatePathByPoly_footprintutilityprogram( path_poly layer ?line_width line_width)
	)
)

procedure( CreateShapeOnPin_footprintutilityprogram( pin_ls layer_ls @key (expand_mils 0) (height_min nil) (height_max nil) (pin_layer nil))
	prog( ( expand_width)
		unless( dtpr( pin_ls)
			return( nil)
		)
		
		when( and( layer_ls !dtpr( layer_ls))
			layer_ls = list( layer_ls)
		)
		
		when( and( height_min axlGeoEqual( height_min 0.0))
			height_min = axlUIPrompt( sprintf( nil "%s\nPACKAGE_HEIGHT_MIN (%s)" layer_ls _allegro_unit)) || "0"
			height_min = atof( height_min)
		)
		
		when( and( height_max axlGeoEqual( height_max 0.0))
			height_max = axlUIPrompt( sprintf( nil "%L\nPACKAGE_HEIGHT_MAX (%s)" layer_ls _allegro_unit)) || "0"
			height_max = atof( height_max)
		)
		
		expand_width = 0.0
		when( and( numberp( expand_mils) !zerop( expand_mils))
			expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
		)
		
		foreach( layer layer_ls
			printf( "Create shape on Pin on %s\n" layer)
			foreach( pin_id pin_ls
				pin_poly = car( axlPolyFromDB( pin_id ?layer pin_layer))
				when( and( numberp( expand_width) !zerop( expand_width))
					pin_poly = car( axlPolyExpand( pin_poly expand_width 'NONE))
				)
				
				shape_id = car( axlDBCreateShape( pin_poly t layer))
				when( and( height_min !axlGeoEqual( height_min 0.0))
					axlDBAddProp( shape_id list( "PACKAGE_HEIGHT_MIN" height_min))
				)
				
				when( and( height_max !axlGeoEqual( height_max 0.0))
					axlDBAddProp( shape_id list( "PACKAGE_HEIGHT_MAX" height_max))
				)
			)
		)
		
		return( t)
	)
)

procedure( CreateShapeCircle_footprintutilityprogram( center_xy radius layer @key (height_min nil))
	prog( ( top_point right_point bot_point left_point path shape_id)
		top_point = axlMXYAdd( center_xy 0:radius)
		right_point = axlMXYAdd( center_xy radius:0)
		bot_point = axlMXYAdd( center_xy 0:-radius)
		left_point = axlMXYAdd( center_xy -radius:0)
		
		path = axlPathStart( list( top_point))
		axlPathArcCenter( path nil right_point t center_xy)
		axlPathArcCenter( path nil bot_point t center_xy)
		axlPathArcCenter( path nil left_point t center_xy)
		axlPathArcCenter( path nil top_point t center_xy)
		
		shape_id = car( axlDBCreateShape( path t layer))
		when( and( height_min !axlGeoEqual( height_min 0.0))
			axlDBAddProp( shape_id list( "PACKAGE_HEIGHT_MIN" height_min))
		)
		
		return( shape_id)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Create

;;;;;;;;;;;;;;;;;;;;;;;;; Delete

procedure( DeleteOnSilkscreenTop_footprintutilityprogram()
	let( ( line_ls pin1_mark_ls)
		line_ls = GetLineList_utilityprogram( _layer_pkg_skt)
		pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
		line_ls = setof( x line_ls !member( x pin1_mark_ls))
		axlDeleteObject( line_ls)
	)
)

procedure( DeleteShapesOnLayer_footprintutilityprogram( layer_ls)
	let( ( delete_shape_ls)
		when( and( layer_ls !dtpr( layer_ls))
			layer_ls = list( layer_ls)
		)
		
		foreach( layer layer_ls
			shape_ls = GetShapeList_utilityprogram( layer)
			delete_shape_ls = append( delete_shape_ls shape_ls)
		)
		
		axlDeleteObject( delete_shape_ls)
	)
)

procedure( DeleteTextsOnLayer_footprintutilityprogram( layer)
	let( ( text_ls)
		text_ls = GetTextList_utilityprogram( layer)
		axlDeleteObject( text_ls)
	)
)

procedure( DeleteLinesOnLayer_footprintutilityprogram( layer)
	let( ( line_ls)
		line_ls = GetLineList_utilityprogram( layer)
		axlDeleteObject( line_ls)
	)
)

procedure( DeleteRefLayer_footprintutilityprogram()
	let( ()
		DeleteTextsOnLayer_footprintutilityprogram( _layer_ref_at)
		DeleteTextsOnLayer_footprintutilityprogram( _layer_ref_st)
		DeleteTextsOnLayer_footprintutilityprogram( _layer_com_dt)
	)
)

procedure( DeletePin1Mark_footprintutilityprogram()
	let( ( pin1_mark_ls)
		pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
		axlDeleteObject( pin1_mark_ls)
	)
)

procedure( DeletePinNote_footprintutilityprogram()
	let( ()
		DeleteTextsOnLayer_footprintutilityprogram( _layer_pkg_at)
		DeleteTextsOnLayer_footprintutilityprogram( _layer_pkg_skt)
	)
)

procedure( DeletePCBEdge_footprintutilityprogram()
	let( ( layer)
		layer = _layer_pcb_edge
		DeleteTextsOnLayer_footprintutilityprogram( layer)
		DeleteLinesOnLayer_footprintutilityprogram( layer)
	)
)

procedure( DeleteSymbolNote_footprintutilityprogram()
	let( ()
		DeleteTextsOnLayer_footprintutilityprogram( _layer_pkg_bc)
	)
)

procedure( DeletePinProperties_footprintutilityprogram( prop_ls)
	let( ( pin_ls)
		pin_ls = axlDBGetDesign()->pins
		axlDBDeleteProp( pin_ls prop_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Delete

;;;;;;;;;;;;;;;;;;;;;;;;; Check

procedure( InitCheckBaseData_footprintutilityprogram( @optional (only_pin nil))
	let( ( at_outline path)
		unless( only_pin
			at_outline = GetAssemblyTopOutline_footprintutilityprogram()
			path = axlDB2Path( at_outline)
			when( axlGeoPointsEqual( axlPathSegGetEndPoint( car( axlPathGetPathSegs( path))) axlPathSegGetEndPoint( axlPathGetLastPathSeg( path)))
				_assembly_top_poly = car( axlPolyFromDB( path))
			)
		)
		
		foreach( pin_id axlDBGetDesign()->pins
			pin_poly = car( axlPolyFromDB( pin_id ?padType "REGULAR"))
			_pin_poly_table[ pin_id] = pin_poly
		)
	)
)

; 1.PACKAGE GEOMETRY/ASSEMBLY_TOP :
; 依照 DATASHEET 建立
procedure( CheckPkgAssemblyTop_footprintutilityprogram( out_port @optional (pin_mode nil))
	prog( ( result layer)
		result = t
		layer = _layer_pkg_at
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		if( pin_mode then
			fprintf( out_port "* Should create outline according to PAD\n")
		else
			fprintf( out_port "* Should create outline according to DATASHEET\n")
			fprintf( out_port "* Skill only check if outline exists\n")
		)
		
		fprintf( out_port "\n")
		result = CheckLayerExists_footprintutilityprogram( layer out_port)
		when( result
			at_outline = GetAssemblyTopOutline_footprintutilityprogram()
			if( at_outline then
				when( pin_mode
					at_poly = car( axlPolyFromDB( axlDB2Path( at_outline)))
					pin_id = car( axlDBGetDesign()->pins)
					pin_poly = car( axlPolyFromDB( pin_id))
					result = IsSamePoly_footprintutilityprogram( at_poly pin_poly)
					unless( result
						fprintf( out_port "\tASSEMBLY_TOP is different from pad size\n")
					)
				)
			else
				fprintf( out_port "\t%s is empty!!\n" layer)
				result = nil
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result layer out_port)
		return( result)
	)
)

; PACKAGE GEOMETRY/SILKSCREEN_TOP :
; 依照 ASSEMBLY_TOP 外框大小往外推 8mils
; 第二層再外推 80mils ( BGA only )
; 再將線寬變成 0.1524=6mils
; 遇到白漆壓到 PAD 一定要切掉線段避免壓在 PAD 上
; 白漆距離 PAD 要有 6mils 以上
procedure( CheckPkgSilkscreenTop_footprintutilityprogram( out_port @optional (is_bga nil))
	prog( ( result width_result gap_result overlap_result layer pin1_mark_ls 
			line_ls line_width_error error_line_width line_width
			assembly_top_line_seg line_seg distance target_distance pin_ls visible_ls)
		result = t
		layer = _layer_pkg_skt
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Base on %s outline, expand 8mils and line thickness should be 6mils\n" _layer_pkg_at)
		when( is_bga
			fprintf( out_port "* Second SILKSCREEN should expand 88mils\n")
		)
		fprintf( out_port "  White paint should not overlap on PAD 5mils")
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_footprintutilityprogram( layer out_port)
		when( result
			fprintf( out_port "\n")
			
			line_ls = GetLineList_utilityprogram( layer)
			; exclude PIN1 mark
			pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
			line_ls = setof( x line_ls !member( x pin1_mark_ls))
			unless( dtpr( line_ls)
				fprintf( out_port "\tSilkscreen not found\n")
				result = nil
			)
			
			when( result
				;;;;; check silkscreen line width
				line_width = GetUnitValueByMils_utilityprogram( 6.0)
				fprintf( out_port "\t(1). Check line width (%L %s)\n" line_width _allegro_unit)
				width_result = t
				foreach( line_id line_ls
					line_width_error = nil
					if( line_id->isSameWidth then
						path_id = axlDB2Path( line_id)
						width = axlPathGetWidth( path_id)
						;width = car( line_id->segments)->width
						unless( axlGeoEqual( width line_width)
							start_end =  list( axlPathSegGetEndPoint( car( axlPathGetPathSegs( path_id))) axlPathSegGetEndPoint( axlPathGetLastPathSeg( path_id)))
							fprintf( out_port "\t\t%L Line width : %L %s\n" start_end width _allegro_unit)
							width_result = nil
						)
					else
						foreach( line_seg line_id->segments
							;;; check line width
							width = line_seg->width
							unless( axlGeoEqual( width line_width)
								fprintf( out_port "\t\t%L Line width : %L %s\n" line_seg>startEnd width _allegro_unit)
								width_result = nil
							)
						)
					)
				)
				
				fprintf( out_port "\t     %s Line width\n" GetResultMsg_footprintutilityprogram( width_result))
				unless( width_result
					result = nil
				)
				;;;;;
				
				;;;;; check gap
				fprintf( out_port "\t(2). Check gap between %s & %s\n" _layer_pkg_at layer)
				gap_result = t
				at_outline = GetAssemblyTopOutline_footprintutilityprogram()
				; expand width - line width
				target_distance = GetUnitValueByMils_utilityprogram( 8.0) - GetUnitValueByMils_utilityprogram( 3.0)
				second_distance = GetUnitValueByMils_utilityprogram( 88.0) - GetUnitValueByMils_utilityprogram( 3.0)
				
				error_line_data_ls = nil
				if( is_bga then
					foreach( line_id line_ls
						distance = GetDistanceBetweenLines_footprintutilityprogram( at_outline line_id)
						unless( or( axlGeoEqual( distance target_distance) axlGeoEqual( distance second_distance))
							error_line_data_ls = append1( error_line_data_ls list( line_id distance))
							gap_result = nil
						)
					)
				else
					foreach( line_id line_ls
						distance = GetDistanceBetweenLines_footprintutilityprogram( at_outline line_id)
						unless( axlGeoEqual( distance target_distance)
							error_line_data_ls = append1( error_line_data_ls list( line_id distance))
							gap_result = nil
						)
					)
				)
				
				unless( gap_result
					foreach( data error_line_data_ls
						line_id = car( data)
						distance = cadr( data)
						path_id = axlDB2Path( line_id)
						start_end =  list( axlPathSegGetEndPoint( car( axlPathGetPathSegs( path_id))) axlPathSegGetEndPoint( axlPathGetLastPathSeg( path_id)))
						fprintf( out_port "\t\t%L Line's gap with ASSEMBLY_TOP is %L %s\n" start_end distance _allegro_unit)
					)
					
					result = nil
				)
				
				fprintf( out_port "\t     %s Gap\n" GetResultMsg_footprintutilityprogram( gap_result))
				;;;;;
			
				;;;;; check any silkscreen overlap pad
				fprintf( out_port "\t(3). Check overlap on pad\n")
				overlap_result = t
				line_poly_ls = mapcar( lambda( (x) car( axlPolyFromDB( x))) line_ls)
				foreach( pin_id axlDBGetDesign()->pins
					pin_poly = car( axlPolyFromDB( pin_id))
					overlap_poly = car( axlPolyOperation( pin_poly line_poly_ls 'AND))
					when( overlap_poly
						fprintf( out_port "\t\tThere's line overlap on PAD : %s %L\n" pin_id->name pin_id->xy)
						overlap_result = nil
					)
				)
				
				ResetFindFilter_utilityprogram()
				
				fprintf( out_port "\t     %s Overlap\n" GetResultMsg_footprintutilityprogram( overlap_result))
				unless( overlap_result
					result = nil
				)
				;;;;;
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result layer out_port)
		return( result)
	)
)

; 3.PACKAGE GEOMETRY/PLACE_BOUND_TOP :
;   SHAPE 依照 ASSEMBLY_TOP 大小除非 PAD 超過外框大小就依照 PAD 的大小用 GRID 5 MIL 框住
;   並跟外框大小合併為一個 SHAPE
procedure( CheckPkgPlaceBoundTop_footprintutilityprogram( out_port)
	prog( ( result layer pbt_shape_id pbt_poly overlap_poly pin_expand_width)
		result = t
		layer = _layer_pkg_pbt
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* %s outline and PAD outline(if overlap with %s outline) expand 5mils then merge outlines to shape\n" _layer_pkg_at _layer_pkg_at)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_footprintutilityprogram( layer out_port)
		when( result
			pbt_shape_id = car( GetShapeList_utilityprogram( layer))
			unless( pbt_shape_id
				result = nil
			)
			
			when( result
				pbt_poly = car( axlPolyFromDB( pbt_shape_id))
				overlap_poly = car( axlPolyOperation( pbt_poly _assembly_top_poly 'AND))
				when( and( overlap_poly !axlGeoEqual( overlap_poly->area _assembly_top_poly->area))
					fprintf( out_port "\tShape is not same with ASSEMBLY_TOP\n")
					result = nil
				)
				
				; check pin distance with place_bound_top
				soldermask_expand_width = GetUnitValueByMils_utilityprogram( 2)
				pin_expand_width = GetUnitValueByMils_utilityprogram( 5)
				foreach( pin_id axlDBGetDesign()->pins
					pin_poly = _pin_poly_table[ pin_id]
					soldermask_poly = car( axlPolyExpand( pin_poly soldermask_expand_width 'NONE))
					overlap_poly = car( axlPolyOperation( soldermask_poly _assembly_top_poly 'AND))
					unless( axlGeoEqual( overlap_poly->area soldermask_poly->area)
						pin_poly = car( axlPolyExpand( pin_poly pin_expand_width 'NONE))
					)
					
					overlap_poly = car( axlPolyOperation( pin_poly pbt_poly 'AND))
					when( and( overlap_poly !axlGeoEqual( overlap_poly->area pin_poly->area))
						fprintf( out_port "\tShape at %s%L is incorrect, it should >= %L %s of PAD size\n" pin_id->name pin_id->xy pin_expand_width _allegro_unit)
						result = nil
					)
				)
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result layer out_port)
		return( result)
	)
)

; 4.PACKAGE GEOMETRY/DFA_BOUND_TOP :
;   同上與 PLACE_BOUND_TOP 一樣
procedure( CheckPkgDFABoundTop_footprintutilityprogram( out_port)
	prog( ( result layer place_bound_top_shape dfa_bound_top_shape distance)
		result = t
		layer = _layer_pkg_dfabt
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Shape should same with %s" _layer_pkg_pbt)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_footprintutilityprogram( layer out_port)
		when( result
			pbt_shape_id = car( GetShapeList_utilityprogram( _layer_pkg_pbt))
			dfa_shape_id = car( GetShapeList_utilityprogram( layer))
			unless( IsSameShape_footprintutilityprogram( pbt_shape_id dfa_shape_id)
				fprintf( out_port "\tShape is different with %s.\n" _layer_pkg_pbt)
				result = nil
			)
			
			when( dfa_shape_id->prop->PACKAGE_HEIGHT_MAX
				fprintf( out_port "\tShape should not have property \"PACKAGE_HEIGHT_MAX\"\n")
				result = nil
			)
		)

		PrintCheckResult_footprintutilityprogram( result layer out_port)
		return( result)
	)
)

; 5.MANUFACTURING/NO_PROBE_TOP :
;   SHAPE 依照 ASSEMBLY_TOP 大小除非 PAD 超過外框大小就依照 PAD 的大小用沿著 PAD 框起
;   並跟外框大小合併為一個 SHAPE 再往外推 0.381mm = 15mil
procedure( CheckManufacturingNoProbeTop_footprintutilityprogram( out_port)
	prog( ( result layer no_probe_shape_id no_probe_poly expand_width assembly_top_poly overlap_poly)
		result = t
		layer = _layer_manu_npt
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* %s outline and PAD outline(if overlap with %s outline) expand 15mils then merge outlines to shape\n" _layer_pkg_at _layer_pkg_at)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_footprintutilityprogram( layer out_port)
		when( result
			no_probe_shape_id = car( GetShapeList_utilityprogram( layer))
			unless( no_probe_shape_id
				result = nil
			)
			
			when( result
				no_probe_poly = car( axlPolyFromDB( no_probe_shape_id))
				expand_width = GetUnitValueByMils_utilityprogram( 15)
				assembly_top_poly = car( axlPolyExpand( _assembly_top_poly expand_width 'NONE))
				overlap_poly = car( axlPolyOperation( no_probe_poly assembly_top_poly 'AND))
				when( and( overlap_poly !axlGeoEqual( overlap_poly->area assembly_top_poly->area))
					fprintf( out_port "\tShape should >= %L %s of ASSEMBLY_TOP size\n" expand_width _allegro_unit)
					result = nil
				)
				
				; check pin distance
				foreach( pin_id axlDBGetDesign()->pins
					pin_poly = _pin_poly_table[ pin_id]
					overlap_poly = car( axlPolyOperation( pin_poly assembly_top_poly 'AND))
					when( and( overlap_poly !axlGeoEqual( overlap_poly->area pin_poly->area))
						pin_poly = car( axlPolyExpand( pin_poly expand_width 'NONE))
						overlap_poly = car( axlPolyOperation( pin_poly no_probe_poly 'AND))
						when( and( overlap_poly !axlGeoEqual( overlap_poly->area pin_poly->area))
							fprintf( out_port "\tShape at %s%L is incorrect, it should >= %L %s of PAD size\n" pin_id->name pin_id->xy expand_width _allegro_unit)
							result = nil
						)
					)
				)
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result layer out_port)
		return( result)
	)
)

procedure( CheckPlaceBoundBottom_footprintutilityprogram( out_port)
	prog( ( result layer)
		result = t
		layer = _layer_pkg_pbb
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Each pin should have shape with same size on %s" layer)
		fprintf( out_port "\n\n")
		dip_pin_ls = GetThroughPinList_footprintutilityprogram()
		result = CheckShapeOnPin_footprintutilityprogram( out_port dip_pin_ls layer)
		return( result)
	)
)

procedure( CheckRouteKeepoutAll_footprintutilityprogram( out_port)
	prog( ( result layer)
		result = t
		layer = _layer_rte_ko_a
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Npth pin should have shape on %s (size: pin expand 12 mils on each side)" layer)
		fprintf( out_port "\n\n")
		dip_pin_ls = GetThroughPinList_footprintutilityprogram()
		npth_pin_ls = setof( x dip_pin_ls x->definition->plating == "NON_PLATED")
		result = CheckShapeOnPin_footprintutilityprogram( out_port npth_pin_ls layer ?expand_mils 12)
		return( result)
	)
)

procedure( CheckPackageKeepoutBottom_footprintutilityprogram( out_port)
	prog( ( result layer)
		result = t
		layer = _layer_pkg_ko_b
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Pth pin should have shape on %s (size: pin expand 199.5 mils on each side and merge shapes)" layer)
		fprintf( out_port "\n\n")
		
		expand_width = GetUnitValueByMils_utilityprogram( 199.5)

		shape_id = car( GetShapeList_utilityprogram( layer))
		unless( shape_id
			fprintf( out_port "\tShape not found on %s\n" layer)
			result = nil
		)
		
		when( result
			shape_poly = car( axlPolyFromDB( shape_id))
			
			dip_pin_ls = GetThroughPinList_footprintutilityprogram()
			pth_pin_ls = setof( x dip_pin_ls x->definition->plating == "PLATED")
			foreach( pin_id pth_pin_ls
				pin_poly = _pin_poly_table[ pin_id]
				pin_poly = car( axlPolyExpand( pin_poly expand_width 'NONE))
				overlap_poly = car( axlPolyOperation( pin_poly shape_poly 'AND))
				when( and( overlap_poly->area !axlGeoEqual( pin_poly->area overlap_poly->area))
					different = pin_poly->area - overlap_poly->area
					sprintf( xy "%L" pin_id->xy)
					fprintf( out_port "\tShape at PIN [%s] %-15s is incorrect, difference:%.4f\n" pin_id->name xy different)
					result = nil
				)
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result layer out_port)
		return( result)
	)	
)

procedure( CheckPackageKeepoutTop_footprintutilityprogram( out_port)
	prog( ( result layer)
		result = t
		layer = _layer_pkg_ko_t
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Pth pin should have shape on %s (size: pin expand 199.5 mils on each side and merge shapes)\n" layer)
		fprintf( out_port "  when shape overlap with %s's shape, should delete overlap area" _layer_pkg_pbt)
		fprintf( out_port "\n\n")
		
		expand_width = GetUnitValueByMils_utilityprogram( 199.5)

		shape_id = car( GetShapeList_utilityprogram( layer))
		unless( shape_id
			fprintf( out_port "\tShape not found on %s\n" layer)
			result = nil
		)
		
		pbt_shape_id = car( GetShapeList_utilityprogram( _layer_pkg_pbt))
		unless( pbt_shape_id
			fprintf( out_port "\tShape not found on %s\n" _layer_pkg_pbt)
			result = nil
		)
		
		when( result
			shape_poly = car( axlPolyFromDB( shape_id))
			pbt_poly = car( axlPolyFromDB( pbt_shape_id))
			
			pth_pin_ls = setof( x axlDBGetDesign()->pins x->definition->plating == "PLATED")
			foreach( pin_id pth_pin_ls
				pin_poly = _pin_poly_table[ pin_id]
				pin_poly = car( axlPolyExpand( pin_poly expand_width 'NONE))
				andnot_poly = car( axlPolyOperation( pin_poly pbt_poly 'ANDNOT))
				overlap_poly = car( axlPolyOperation( andnot_poly shape_poly 'AND))
				when( and( overlap_poly->area !axlGeoEqual( andnot_poly->area overlap_poly->area))
					different = andnot_poly->area - overlap_poly->area
					sprintf( xy "%L" pin_id->xy)
					fprintf( out_port "\tShape at PIN [%s] %-15s is incorrect, difference:%.4f\n" pin_id->name xy different)
					result = nil
				)
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result layer out_port)
		return( result)
	)	
)

; 檢查 pin 屬性
; pin 1 需要設定 "PKG_PIN_ONE"
; pth pin 需要設定 "LEAD_DIAMETER" 及 "BACKDRILL_MIN_PIN_PTH" 但如果是 POWER 的不用設定 "BACKDRILL_MIN_PIN_PTH"
procedure( CheckPinProperties_footprintutilityprogram( out_port)
	prog( ( result title pth_pin_ls error_pin_ls)
		result = t
		sprintf( title _check_msg_format "pin properties")
		printf( title)
		fprintf( out_port title)
		fprintf( out_port "* Pth pin should have \"LEAD_DIAMETER\" and \"BACKDRILL_MIN_PIN_PTH\" property,\n")
		fprintf( out_port "  but if pin is POWER don't need \"BACKDRILL_MIN_PIN_PTH\"\n")
		fprintf( out_port "* Pin 1 should have property \"PKG_PIN_ONE\"")
		fprintf( out_port "\n\n")
		
		pin_ls = axlDBGetDesign()->pins
		pth_pin_ls = setof( x pin_ls x->definition->plating == "PLATED")
		error_pin_ls = setof( x pth_pin_ls or( x->prop->LEAD_DIAMETER == nil x->prop->BACKDRILL_MIN_PIN_PTH == nil))
		when( dtpr( error_pin_ls)
			result = nil		
			foreach( pin_id error_pin_ls
				missing_prop = ""
				cond(
					( and( pin_id->prop->LEAD_DIAMETER == nil pin_id->prop->BACKDRILL_MIN_PIN_PTH == nil)
						missing_prop = "\"LEAD_DIAMETER\" & \"BACKDRILL_MIN_PIN_PTH\""
					)
					( pin_id->prop->LEAD_DIAMETER == nil
						missing_prop = "\"LEAD_DIAMETER\""
					)
					( pin_id->prop->BACKDRILL_MIN_PIN_PTH == nil
						missing_prop = "\"BACKDRILL_MIN_PIN_PTH\""
					)
				)
				
				fprintf( out_port "\tMissing property %s on Pin: %s, %s %L\n" missing_prop pin_id->name pin_id->number pin_id->xy)
			)
		)
		
		pin1_id = car( setof( x pin_ls x->prop->PKG_PIN_ONE))
		unless( pin1_id
			fprintf( out_port "\t\"PKG_PIN_ONE\" not found\n")
			result = nil
		)
		
		PrintCheckResult_footprintutilityprogram( result "Pin properties" out_port)
		return( result)
	)
)

; REF 3 個層面 :
; REF DES/ASSEMBLY_TOP, REF DES/SILKSCREEN_TOP, COMPONENT VALUE/DISPLAY_TOP
procedure( CheckRefDes_footprintutilityprogram( out_port)
	prog( ( result key msg layer text_ls text_id)
		result = t
		printf( _check_msg_format "REF layers")
		fprintf( out_port _check_msg_format "REF layers")
		fprintf( out_port "* layer %s & %s & %s" _layer_ref_at _layer_ref_st _layer_com_dt)
		fprintf( out_port "\n\n")
		axlVisibleDesign( nil)
		key = "*"
		msg = "\tRef type not found on layer [%s]!\n"
		
		layer = _layer_ref_at
		text_ls = GetTextList_utilityprogram( layer)
		when( dtpr( text_ls)
			text_id = setof( x text_ls index( x->text key))
		)
		
		unless( text_id
			fprintf( out_port msg layer)
			result = nil
		)
		
		text_id = nil
		
		layer = _layer_ref_st
		text_ls = GetTextList_utilityprogram( layer)
		when( dtpr( text_ls)
			text_id = setof( x text_ls index( x->text key))
		)
		
		unless( text_id
			fprintf( out_port msg layer)
			result = nil
		)
		
		text_id = nil
		
		layer = _layer_com_dt
		text_ls = GetTextList_utilityprogram( layer)
		when( dtpr( text_ls)
			text_id = setof( x text_ls index( x->text key))
		)
		
		unless( text_id
			fprintf( out_port msg layer)
			result = nil
		)
		
		PrintCheckResult_footprintutilityprogram( result "REF DES layers" out_port)
		return( result)
	)
)

; 零件的第 1 PIN 中心都要加三角形 MARK
; 在 PACKAGE GEOMETRY/ ASSEMBLY_TOP 層面及 PACKAGE GEOMETRY/SILKSCREEN_TOP 層面也需要三角形 MARK 指向第一 PIN
procedure( CheckPin1Mark_footprintutilityprogram( out_port)
	prog( ( assembly_result silkscreen_result)
		printf( _check_msg_format "PIN1 mark")
		fprintf( out_port _check_msg_format "PIN1 mark")
		fprintf( out_port "* Line on %s & %s\n" _layer_pkg_at _layer_pkg_skt)
		fprintf( out_port "  with line property MARKING_USAGE set to PIN_ONE")
		fprintf( out_port "\n\n")
		
		assembly_result = CheckPin1MarkByLayer_footprintutilityprogram( _layer_pkg_at out_port)
		silkscreen_result = CheckPin1MarkByLayer_footprintutilityprogram( _layer_pkg_skt out_port)
		
		result = and( assembly_result silkscreen_result)
		PrintCheckResult_footprintutilityprogram( result "PIN1 mark" out_port)
		return( result)
	)
)

; 每個零件都要標示排 PIN 的文字在第一 PIN 跟最後一 PIN :
; PACKAGE GEOMETRY/SILKSCREEN_TOP & PACKAGE GEOMETRY/ASSEMBLY_TOP 層面
procedure( CheckPinNote_footprintutilityprogram( out_port)
	prog( ( result first_pin last_pin)
		result = t
		printf( _check_msg_format "PIN note")
		fprintf( out_port _check_msg_format "PIN note")
		fprintf( out_port "* There should at least 2 PIN note each on %s & %s" _layer_pkg_skt _layer_pkg_at)
		fprintf( out_port "\n\n")
		
		skt_text_ls = GetTextList_utilityprogram( _layer_pkg_skt)
		at_text_ls = GetTextList_utilityprogram( _layer_pkg_at)
		
		text_ls = UniqueList_utilityprogram( append( skt_text_ls~>text at_text_ls~>text))
		foreach( text text_ls
			skt_text_id = car( setof( x skt_text_ls x->text == text))
			layer_ls = nil
			text_xy = nil
			if( skt_text_id then
				text_xy = skt_text_id->xy
				layer_ls = append1( layer_ls skt_text_id->layer)
			else
				result = nil
			)
			
			at_text_id = car( setof( x at_text_ls x->text == text))
			if( at_text_id then
				text_xy = at_text_id->xy
				layer_ls = append1( layer_ls at_text_id->layer)
			else
				result = nil
			)
			
			fprintf( out_port "\t%s %L %L\n" text text_xy layer_ls)
		)
		
		when( result
			result = length( text_ls) >= 2
		)
		
		PrintCheckResult_footprintutilityprogram( result "PIN note" out_port)
		return( result)
	)
)

; 板邊零件都需要建 PCB EDGE :
; BOARD GEOMETRY/PCB_EDGE 層面
; 要有 PCB EDGE 字樣
procedure( CheckPCBEdgeNote_footprintutilityprogram( out_port)
	prog( ( result layer target_text text_ls note)
		result = t
		layer = _layer_pcb_edge
		target_text = "PCB EDGE"
		printf( _check_msg_format "PCB Edge Note")
		fprintf( out_port _check_msg_format "PCB Edge Note")
		fprintf( out_port "* Text \"%s\" on %s" target_text layer)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_footprintutilityprogram( layer out_port)
		when( result
			text_ls = GetTextList_utilityprogram( layer)

			;;; check text exist
			note = setof( x text_ls rexMatchp( target_text upperCase( x->text)))
			unless( note
				fprintf( out_port "\tNote [%s] not found!\n" target_text)
				result = nil
			)
			
			when( result
				result = CheckTextBlock_footprintutilityprogram( out_port text_ls "1")
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result "PCB edge note" out_port)
		return( result)
	)
)

; 每顆零件都要加 NOTE 在零件下方 :
; PACKAGE GEOMETRY/BODY_CENTER 層面
; 文字大小要用 TEXT_BLOCK# 10, (height: 0.7620, width: 0.5080, line spacing: 0.7620),
; 數字大小固定
procedure( CheckNote_footprintutilityprogram( out_port)
	prog( ( result text_ls msg padstack rev date)
		result = t
		layer = _layer_pkg_bc
		no_pin = !dtpr( axlDBGetDesign()->pins)
		printf( "Check Symbol Notes on %s\n" layer)
		fprintf( out_port "Check Symbol Notes on %s\n" layer)
		fprintf( out_port "* Contains following notes\n")
		if( no_pin
			fprintf( out_port "  %s\n  %s" _note_rev _note_date)
			fprintf( out_port "  %s\n  %s\n  %s" _note_padstack_name _note_rev _note_date)
		)
		
		fprintf( out_port "\n\n")
		
		text_ls = GetTextList_utilityprogram( layer)
		
		;;; check text exist
		msg = "\tNote [%s] not found!\n"
		unless( no_pin
			text_padstack = setof( x text_ls rexMatchp( _note_padstack_name lowerCase( x->text)))
			unless( text_padstack
				fprintf( out_port msg _note_padstack_name)
				result = nil
			)
		)
		
		text_rev = setof( x text_ls rexMatchp( _note_rev x->text))
		unless( text_rev
			fprintf( out_port msg _note_rev)
			result = nil
		)
		
		text_date = setof( x text_ls rexMatchp( _note_date x->text))
		unless( text_date
			fprintf( out_port msg _note_date)
			result = nil
		)
		
		when( result
			result = CheckTextBlock_footprintutilityprogram( out_port text_ls "10")
		)
		
		PrintCheckResult_footprintutilityprogram( result "Symbol notes" out_port)
		return( result)
	)
)

; PACKAGE GEOMETRY/PIN_NUMBER ( for BGA )
; 文字大小要用 TEXT_BLOCK #11 (height: 0.2mm, width: 0.1mm, line spacing: 0.1mm)
; 數字大小固定
procedure( CheckPinNumber_footprintutilityprogram( out_port)
	prog( ( result layer text_ls)
		layer = _layer_pkg_pn
		printf( "Check pin number on %s\n" layer)
		fprintf( out_port "Check pin number on %s\n" layer)
		fprintf( out_port "* Textblock should be #11\n")
		fprintf( out_port "\n\n")
		
		text_ls = GetTextList_utilityprogram( layer)
		result = CheckTextBlock_footprintutilityprogram( out_port text_ls "11")
		
		PrintCheckResult_footprintutilityprogram( result "Pin number" out_port)
		return( result)
	)
)

; 不同 PAD size 有不同 ball size 來檢查是否在範圍內
; PAD size 應該 > ball size * 0.8 ; < ball size * 1.2
procedure( CheckPadSize_footprintutilityprogram( out_port)
	prog( ( result pin_name_ls ball_size_ls)
		result = t
		printf( "Check PAD size\n")
		fprintf( out_port "Check PAD size\n")
		fprintf( out_port "* PAD size should be between ball size(mm) * 0.8 and ball size(mm) * 1.2\n")
		pin_name_ls = UniqueList_utilityprogram( axlDBGetDesign()->pins~>name)
		foreach( pin_name pin_name_ls
			sprintf( msg "%s\nBall size(mm)" pin_name)
			ball_size = axlUIPrompt( msg)
			ball_size = atof( ball_size)
			unless( ball_size
				axlUIConfirm( "Please input ball size and check again")
				result = nil
			)
			
			ball_size_ls = append1( ball_size_ls ball_size)
		)
		
		; check pad size 
		foreach( (pin_name ball_size) pin_name_ls ball_size_ls
			when( ball_size
				min_size = ball_size * 0.8
				max_size = ball_size * 1.2
				rexCompile( "^[A-Z]")
				size = rexReplace( pin_name "" 0)
				size = atoi( size)
				when( numberp( size)
					size = axlMKSConvert( size "MILS" "MM")
					unless( and( size >= min_size size <= max_size)
						fprintf( out_port "\tPAD \"%s\" size:%L mm, ball size:%L mm, should between %L mm and %L mm\n" 
											pin_name size ball_size min_size max_size)
						result = nil
					)
				)
			)
		)
		
		PrintCheckResult_footprintutilityprogram( result "PAD size" out_port)
		return( result)
	)
)

procedure( CheckLayerExists_footprintutilityprogram( layer out_port)
	prog( ( result)
		result = axlVisibleLayer( layer t)
		if( result
			fprintf( out_port "\t%s exists\n" layer)
			fprintf( out_port "\t%s not found!!\n" layer)
		)
		
		return( result)
	)
)

procedure( CheckPin1MarkByLayer_footprintutilityprogram( layer out_port)
	prog( ( result pin1_mark_ls)
		result = t
		pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
		
		unless( dtpr( setof( x pin1_mark_ls ( x->layer == layer)))
			fprintf( out_port "\tPIN1 mark not found on %s!\n" layer)
			result = nil
		)
		
		return( result)
	)
)

procedure( CheckPinNoteByLayer_footprintutilityprogram( layer out_port)
	prog( ( result text_ls)
		result = t
		text_ls = GetTextList_utilityprogram( layer)
		if( dtpr( text_ls) then
			foreach( text_id text_ls
				fprintf( out_port "\t%s [%s] %L\n" text_id->text text_id->layer text_id->xy)
			)
			
			when( length( text_ls) < 2
				result = nil
			)
		else
			result = nil
		)
		
		return( result)
	)
)

procedure( PrintCheckResult_footprintutilityprogram( result msg out_port)
	let( ()
		fprintf( out_port "\n%s %s\n" GetResultMsg_footprintutilityprogram( result) msg)
		
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
	)
)

procedure( GetResultMsg_footprintutilityprogram( result)
	prog( ( msg)
		if( result
			msg = "Pass"
			msg = "Fail"
		)
		
		return( sprintf( nil "[%s]" msg))
	)
)

procedure( CheckTextBlock_footprintutilityprogram( out_port text_ls target_textblock)
	let( ( result)
		result = t
		error_ls = setof( x text_ls x->textBlock != target_textblock)
		when( dtpr( error_ls)
			fprintf( out_port "\tFormat incorrect:\n")
			foreach( text_id error_ls
				fprintf( out_port "\t  Note [%s] textblock:%s %L\n" text_id->text text_id->textBlock text_id->xy)
				result = nil
			)
		)
		
		result
	)
)

procedure( CheckShapeOnPin_footprintutilityprogram( out_port pin_ls layer_ls @key (expand_mils 0.0) (pin_layer nil))
	prog( ( expand_width result)
		when( and( pin_ls !dtpr( pin_ls))
			pin_ls = list( pin_ls)
		)
		
		unless( dtpr( pin_ls)
			return( nil)
		)
		
		when( and( layer_ls !dtpr( layer_ls))
			layer_ls = list( layer_ls)
		)
		
		expand_width = 0
		when( and( numberp( expand_mils) !zerop( expand_mils))
			expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
		)
		
		result = t
		foreach( layer layer_ls
			axlVisibleDesign( nil)
			axlVisibleLayer( layer t)
			SetFindFilter_utilityprogram( '(shapes))
			foreach( pin_id pin_ls
				if( axlSingleSelectPoint( pin_id->xy) then
					shape_id = car( axlGetSelSet())
					axlClearSelSet()
					shape_poly = car( axlPolyFromDB( shape_id))
					
					pin_poly = car( axlPolyFromDB( pin_id ?layer pin_layer))
					when( expand_width != 0
						pin_poly = car( axlPolyExpand( pin_poly expand_width 'NONE))
					)
					
					overlap_poly = car( axlPolyOperation( pin_poly shape_poly 'AND))
					unless( IsSamePoly_footprintutilityprogram( pin_poly overlap_poly)
						fprintf( out_port "\tshape on %s is incorrect (should expand %L %s), Pin: %s, %s %L\n" layer expand_width _allegro_unit pin_id->name pin_id->number pin_id->xy)
						result = nil
					)
				else
					fprintf( out_port "\tMissing shape on %s, Pin: %s, %s %L\n" layer pin_id->name pin_id->number pin_id->xy)
					result = nil
				)
			)
		)
		
		ResetFindFilter_utilityprogram()
		sprintf( layer_str "%L" layer_ls)
		PrintCheckResult_footprintutilityprogram( result layer_str out_port)
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Check

;###########################################################################

procedure( GetDfaDevClass_footprintutilityprogram()
	let( ( dfa_dev_class)
		; DFA_DEV_CLASS
		axlClearSelSet()
		SetFindFilter_utilityprogram( '(alltypes))
		axlSingleSelectName( "component" "U1")
		props = axlDBGetProperties( car( axlGetSelSet()) '( "user" "allegro"))
		dfa_dev_class = car( setof( x props car( x) == 'DFA_DEV_CLASS))
		axlClearSelSet()
		
		cadr( dfa_dev_class)
	)
)

procedure( GetAssemblyTopOutline_footprintutilityprogram()
	prog( ( at_line_ls pin1_mark_ls outline)
		at_line_ls = GetLineList_utilityprogram( _layer_pkg_at)
		pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
		at_line_ls = setof( x at_line_ls !member( x pin1_mark_ls))
		when( and( dtpr( at_line_ls) length( at_line_ls) > 1)
			result = ConnectLinesOnAssemblyTop_footprintutilityprogram()
			when( result
				axlUIConfirm( sprintf( nil "Connect all lines at %s complete!!" _layer_pkg_at))
			)
		)
		
		at_line_ls = GetLineList_utilityprogram( _layer_pkg_at)
		outline = car( setof( x at_line_ls !member( x pin1_mark_ls)))
		unless( outline
			error( "ASSEMBLY_TOP outline not found!!")
		)
		
		return( outline)
	)
)

procedure( ConnectLinesOnAssemblyTop_footprintutilityprogram()
	let( ( line_ls pin1_mark_ls new_path_ls start_path last_line_id)
		line_ls = GetLineList_utilityprogram( _layer_pkg_at)
		pin1_mark_ls = GetPin1MarkList_footprintutilityprogram()
		line_ls = setof( x line_ls !member( x pin1_mark_ls))
		
		path_ls = mapcar( lambda( (x) axlDB2Path( x)) line_ls)
		
		start_path = car( path_ls)
		path_ls = remq( start_path path_ls)
		
		last_path = start_path
		while( path_ls
			end_point = axlPathSegGetEndPoint( axlPathGetLastPathSeg( last_path))
			path = car( setof( x path_ls axlPathSegGetEndPoint( car( axlPathGetPathSegs( x))) == end_point))
			when( path
				last_path = path
				path_ls = remq( path path_ls)
				new_path_ls = append1( new_path_ls path)
			)
		)
		
		new_path_ls = append( new_path_ls path_ls)
		foreach( path new_path_ls
			foreach( path_seg axlPathGetPathSegs( path)
				if( axlPathSegGetArcCenter( path_seg)
					start_path = axlPathArcCenter( start_path 0.0 axlPathSegGetEndPoint( path_seg) nil axlPathSegGetArcCenter( path_seg))
					start_path = axlPathLine( start_path 0.0 axlPathSegGetEndPoint( path_seg))
				)
			)
		)
		
		result = axlDBCreatePath( start_path _layer_pkg_at)
		when( result
			; Delete old paths
			line_ls = GetLineList_utilityprogram( _layer_pkg_at)
			line_ls = setof( x line_ls !member( x pin1_mark_ls))
			delete_line_ls = setof( x line_ls !axlGeoPointsEqual( axlPathSegGetEndPoint( car( axlPathGetPathSegs( axlDB2Path( x)))) axlPathSegGetEndPoint( axlPathGetLastPathSeg( axlDB2Path( x)))))
			axlDeleteObject( delete_line_ls)
		)
		
		result
	)
)

procedure( GetThroughPinList_footprintutilityprogram()
	prog( ( pin_ls)
		pin_ls = setof( x axlDBGetDesign()->pins x->definition->type == "through")
		pin_ls = setof( x pin_ls x->bBox != list( '(0.0 0.0) '(0.0 0.0)))
		return( pin_ls)
	)
)

procedure( GetPin1MarkList_footprintutilityprogram()
	prog( ( line_ls pin1_mark_ls)
		line_ls = append( GetLineList_utilityprogram( _layer_pkg_at) GetLineList_utilityprogram( _layer_pkg_skt))
		pin1_mark_ls = setof( x line_ls ( ( x->prop != nil && x->prop->MARKING_USAGE == "PIN_ONE")
											|| ( x->layer == _layer_pkg_at && car( x->segments)->width > 0)))
		return( pin1_mark_ls)
	)
)

procedure( GetPinBox_footprintutilityprogram( pin)
	prog( ( pad left_bot right_top)
		; because pin->bBox will include soldermask outline, so it will 2mils bigger
		pad = car( setof( x pin->pads ( x->layer == "ETCH/TOP" && x->figureName != "NULL")))
		; box = left bottom : right top
		left_bot = axlMXYAdd( pin->xy nth( 0 pad->bBox))
		right_top = axlMXYAdd( pin->xy nth( 1 pad->bBox))
		
		return( list( left_bot right_top))
	)
)

procedure( GetPointsByBox_footprintutilityprogram( box @optional ( expand_mils 0))
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

procedure( GetExpandPoints_footprintutilityprogram( path @optional ( expand_mils 0))
	prog( ( poly_ls poly)
		; path or shape
		poly_ls = axlPolyFromDB( path)
		if( expand_mils == 0 then
			; to make sure poly->vertices has correct points
			poly = car( axlPolyExpand( poly_ls 0.1 'NONE))
			poly = car( axlPolyExpand( poly -0.1 'NONE))
		else
			expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
			poly = car( axlPolyExpand( poly_ls expand_width 'NONE))
		)
		
		return( mapcar( 'lambda( (x) car(x)) poly->vertices))
	)
)

procedure( CreateShapeByPoints_footprintutilityprogram( points layer)
	prog( ( path shape_id)
		; add the first point to complete the shape
		path = axlPathStart( append1( points car( points)))
		shape_id = car( axlDBCreateShape( path t layer))
		
		return( shape_id)
	)
)

procedure( CreateLayer_footprintutilityprogram( layer)
	prog( ( result)
		result = axlLayerCreateNonConductor( layer)
		unless( result
			warn( "%s is not created!!\n" layer)
		)
		
		return( result)
	)
)

procedure( LoadClp_footprintutilityprogram( file_full_name)
	prog( ()
		_clpFormid = nil
		_clpPinText = nil
		_clpSeverityLevel = nil
		_clpPasteContext = nil
		unless( isFile( file_full_name)
			warn( "LoadClp() - %s not found!!" file_full_name)
			return( nil)
		)
		
		load( file_full_name)
	)
)

procedure( MergeShapesWithMain_footprintutilityprogram( main_shape_id shape_ls @optional (expand_mils nil))
	let( ( layer shape_count)
		; add property to identify main shape
		axlDBAddProp( main_shape_id list( "COMMENT" "main"))
		
		layer = main_shape_id->layer
		MergeShapesOnlayer_footprintutilityprogram( layer)
		; reget pin shape list
		shape_ls = GetShapeList_utilityprogram( layer)
		unless( main_shape_id->objType
			main_shape_id = car( setof( x shape_ls x->prop->COMMENT == "main"))
		)
		
		shape_ls = remq( main_shape_id shape_ls)
		
		when( expand_mils
			expand_width = GetUnitValueByMils_utilityprogram( expand_mils)
			; shrink pin shape
			foreach( shape_id shape_ls
				poly = car( axlPolyFromDB( shape_id))
				poly = car( axlPolyExpand( poly -expand_width 'NONE))
				axlDBCreateShape( poly t layer)
			)
			
			axlDeleteObject( shape_ls)
		)
		
		; reget pin shape list
		shape_ls = GetShapeList_utilityprogram( layer)
		unless( main_shape_id->objType
			main_shape_id = car( setof( x shape_ls x->prop->COMMENT == "main"))
		)
		
		shape_ls = remq( main_shape_id shape_ls)
		
		axlShapeMerge( main_shape_id shape_ls 'quiet)
		result_shape_id = car( GetShapeList_utilityprogram( layer))
		; remove prop
		axlDBDeleteProp( result_shape_id "COMMENT")
		
		result_shape_id
	)
)

procedure( MergeShapesOnlayer_footprintutilityprogram( layer)
	let( ( shape_ls poly_ls or_poly_ls)
		shape_ls = GetShapeList_utilityprogram( layer)
		shape_ls = setof( x shape_ls x->prop->COMMENT != "main")
		foreach( shape_id shape_ls
			poly = car( axlPolyFromDB( shape_id))
			poly_ls = append1( poly_ls poly)
		)
		
		or_poly_ls = axlPolyOperation( car( poly_ls) cdr( poly_ls) 'OR)
		foreach( or_poly or_poly_ls
			; if merged poly has hole in it
			if( dtpr( or_poly->holes) then
				hole_poly_ls = nil
				foreach( hole_poly or_poly->holes
					hole_poly_ls = append( hole_poly_ls axlPolyFromHole( hole_poly))
				)
				
				poly = car( axlPolyOperation( or_poly hole_poly_ls 'OR))
			else
				poly = or_poly
			)
			
			axlDBCreateShape( poly t layer)
		)
		
		axlDeleteObject( shape_ls)
		
		shape_ls = GetShapeList_utilityprogram( layer)
		shape_ls = setof( x shape_ls x->prop->COMMENT != "main")
		foreach( shape_id shape_ls
			axlShapeDeleteVoids( shape_id)
		)
	)
)

procedure( GetDistanceBetweenLines_footprintutilityprogram( main_line_id line_id)
	prog( ( result)
		; path to path airgap doesn't work on 16.6
		unless( main_line_id && line_id
			return( nil)
		)
		
		if( _allegro_version < 17 then
			foreach( main_line_seg main_line_id->segments
				foreach( line_seg line_id->segments
					distance = axlAirGap( main_line_seg line_seg nil 'anyLayer)
					when( result == nil || result > distance
						result = distance
					)
				)
			)
		else		
			distance = axlAirGap( main_line_id line_id nil 'anyLayer)
			when( result == nil || result > distance
				result = distance
			)
		)
		
		return( result)
	)
)

procedure( IsSameShape_footprintutilityprogram( shape1 shape2)
	let( ( poly1 poly2 result)
		poly1 = car( axlPolyFromDB( shape1))
		poly2 = car( axlPolyFromDB( shape2))
		IsSamePoly_footprintutilityprogram( poly1 poly2)
	)
)

procedure( IsSamePoly_footprintutilityprogram( poly1 poly2)
	let( ( overlap_poly result)
		overlap_poly = car( axlPolyOperation( poly1 poly2 'AND))
		and( overlap_poly axlGeoEqual( overlap_poly->area poly1->area) axlGeoEqual( overlap_poly->area poly2->area))
	)
)

procedure( SetPkgPinOne_footprintutilityprogram()
	prog( ( obj_ls pin1_id)
		axlVisibleLayer( _layer_pin_top t)
		axlVisibleLayer( _layer_pkg_pin_num t)
		prompt = "Select a pin to set \"PKG_PIN_ONE\""
		axlUIConfirm( prompt)
		pin_ls = SelectObjectByUser_footprintutilityprogram( '(pins) ?prompt prompt)
		when( length( pin_ls) == 1
			pin1_id = car( pin_ls)
			; set property
			axlDBAddProp( pin1_id list( "PKG_PIN_ONE" t))
		)
		
		RefreshPins_footprintutilityprogram()
		pin1_id = car( setof( x axlDBGetDesign()->pins x->prop->PKG_PIN_ONE))
		return( pin1_id)
	)
)

procedure( SelectObjectByUser_footprintutilityprogram( filter @key (prompt nil))
	prog( ( obj_ls)
		SetFindFilter_utilityprogram( filter)
		CreatePopup_utilityprogram()
		while( axlSelect( ?prompt prompt)
			obj_ls = axlGetSelSet()
		)
		
		axlClearSelSet()
		axlUIPopupSet( nil)
		when( obj_ls
			ResetFindFilter_utilityprogram()
		)
		
		return( obj_ls)
	)
)

procedure( CreatePin1MarkPath_footprintutilityprogram( center_xy @key (size 1))
	let( ( width path_prop radius_y radius_x)
		; triangle
		; center (16.6715 9.8224)
		; top    (16.6715 9.8528)
		; right  (16.7256 9.7920)
		; left   (16.6174 9.7920)
		
		width = GetUnitValueByMils_utilityprogram( 3)
		path_prop = list( "MARKING_USAGE" "PIN_ONE")
		radius_x = 0.0541
		radius_y = 0.0304
		
		top_point = axlMXYAdd( center_xy 0:radius_y)
		right_point = axlMXYAdd( top_point radius_x:-(radius_y * 2))
		left_point = axlMXYAdd( right_point -(radius_x * 2):0)
		points = list( top_point right_point left_point)
		path = axlPathStart( append1( points car( points)) width)
		axlDBCreatePath( path _layer_pkg_at nil nil path_prop)
		when( size > 1
			expand_mils = 1.8
			for( i 2 size
				points = GetExpandPoints_footprintutilityprogram( path expand_mils)
				path = axlPathStart( append1( points car( points)) width)
				axlDBCreatePath( path _layer_pkg_at nil nil path_prop)
			)
		)
	)
)

procedure( DeleteByRectangle_footprintutilityprogram( pick_point delete_box)
	let( ( cmd)
		when( isBoxp( delete_box)
			sprintf( cmd "delete by rectangle;pick %L;pick %L;pick %L" pick_point car( delete_box) cadr( delete_box))
			axlShell( cmd)
			axlShell( "done")
		)
	)
)

procedure( MoveOrigin_footprintutilityprogram( xy)
	let( ( x y point)
		x = car( xy)
		y = cadr( xy)
		point = list( -x -y)
		axlDBChangeDesignOrigin( point)
	)
)

procedure( RefreshPins_footprintutilityprogram()
	let( ()
		foreach( pin_id axlDBGetDesign()->pins
			axlDBRefreshId( pin_id)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( SetAllFormOptions_footprintutilityprogram( form form_key_ls @optional ( value nil))
	let( ()
		unless( booleanp( value)
			println( "ArgErr: SetAllFormOptions() - no is not a boolean")
			value = nil
		)
		
		foreach( form_key form_key_ls
			axlFormSetField( form form_key value)
		)
	)
)

procedure( GetFieldValues_footprintutilityprogram( form form_key_ls setting_table)
	let( ()
		foreach( form_key form_key_ls
			valid = axlFormGetField( form form_key)
			setting_table[ form_key] = valid
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup
/*
(encrypt "c:/skill/footprint_utility_program_v1d1.il" "c:/skill/footprint_utility_program_v1d1.ile")
(load "footprint_utility_program_v1d1.il")
(load "footprint_utility_program_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup