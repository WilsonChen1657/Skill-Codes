/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/03/30                                                      #
#  Reference: utility_program, create_smd                                      #
#  Purpose:                                                                    #
#       To check SMD files                                                     #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checksmd()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	setq( _layer_pkg_assembly_top "PACKAGE GEOMETRY/ASSEMBLY_TOP")
	setq( _layer_pkg_silkscreen_top "PACKAGE GEOMETRY/SILKSCREEN_TOP")
	setq( _layer_pkg_place_bound_top "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
	setq( _layer_pkg_dfa_bound_top "PACKAGE GEOMETRY/DFA_BOUND_TOP")
	setq( _layer_pkg_body_center "PACKAGE GEOMETRY/BODY_CENTER")
	setq( _layer_manufacturing_no_probe_top "MANUFACTURING/NO_PROBE_TOP")
	setq( _layer_pin_top "PIN/TOP")
	setq( _layer_pin_soldermask_top "PIN/SOLDERMASK_TOP")
	setq( _layer_pcb_edge "BOARD GEOMETRY/PCB_EDGE")
	setq( _layer_for_temp_shape "BOARD GEOMETRY/TEMP_USE")
	unless( axlIsLayer( _layer_for_temp_shape)
		axlLayerCreateNonConductor( _layer_for_temp_shape)
	)
	
	setq( _note_padstack_name "padstack name:")
	setq( _note_rev "rev:(recommend)")
	setq( _note_date "date:")

	setq( _check_smd_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main
procedure( Main_checksmd()
	prog( ( log_info out_port)
		Init_checksmd()
		
		log_info = SetUpLog_utilityprogram( "check_smd_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_smd_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check smd symbols are created according to SOP\n")
		;fprintf( out_port "\t%s\n")
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Manual check: ")
		fprintf( out_port "1. Pad size\n%-14s2. PIN Pitch\n%-14s3. PIN number\n" "" "")
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		CheckPackageGeometry_checksmd( out_port)
		CheckManufacturingNoProbeTop_checksmd( out_port)
		CheckRefDes_checksmd( out_port)
		CheckPin1Mark_checksmd( out_port)
		CheckPinNote_checksmd( out_port)
		CheckPCBEdgeNote_checksmd( out_port)
		CheckNote_checksmd( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_smd_logname "Check smd report" nil)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CheckPackageGeometry_checksmd( out_port)
	CheckPkgAssemblyTop_checksmd( out_port)
	CheckPkgSilkscreenTop_checksmd( out_port)
	CheckPkgPlaceBoundTop_checksmd( out_port)
	CheckPkgDFABoundTop_checksmd( out_port)
)

; 1.PACKAGE GEOMETRY/ASSEMBLY_TOP :
; 依照 DATASHEET 建立
procedure( CheckPkgAssemblyTop_checksmd( out_port)
	prog( ( result layer line_ls)
		result = t
		layer = _layer_pkg_assembly_top
		printf( "1. Check %s\n" layer)
		fprintf( out_port "1. Check %s\n" layer)
		fprintf( out_port "* Create outline according to DATASHEET")
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_checksmd( layer out_port)
		
		when( result
			assembly_top_outline = GetAssemblyTopOutline_checksmd()
			unless( assembly_top_outline
				fprintf( out_port "\t%s is empty!!\n" layer)
				result = nil
			)
		)
		
		PrintCheckResult_checksmd( result layer out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		return( result)
	)
)

; 2. PACKAGE GEOMETRY/SILKSCREEN_TOP :
;    依照 ASSEMBLY_TOP 外框大小往外推 8mil, 再將線寬變成 0.1524=6mils, 
;    遇到白漆壓到 PAD 一定要切掉線段避免壓在 PAD 上
procedure( CheckPkgSilkscreenTop_checksmd( out_port)
	prog( (result width_result gap_result overlap_result layer pin1_mark_ls 
			line_ls line_width_error error_line_width line_width
			assembly_top_line_seg line_seg distance target_distance pin_ls visible_ls)
		result = t
		layer = _layer_pkg_silkscreen_top
		printf( "2. Check %s\n" layer)
		fprintf( out_port "2. Check %s\n" layer)
		fprintf( out_port "* Base on %s outline, expand 8mils and change line thickness to 6mils\n" _layer_pkg_assembly_top)
		fprintf( out_port "  White paint should not overlap on PAD 5mils" _layer_pkg_assembly_top)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_checksmd( layer out_port)
		
		when( result
			fprintf( out_port "\n")
			
			line_ls = GetLineList_utilityprogram( layer)
			; exclude PIN1 mark
			pin1_mark_ls = GetPin1MarkList_createsmd()
			line_ls = setof( x line_ls !member( x pin1_mark_ls))
			unless( dtpr( line_ls)
				fprintf( out_port "\tSilkscreen not found\n")
				result = nil
			)
			
			when( result
				;;;;; check silkscreen line width
				fprintf( out_port "\t(1). Check line width\n")
				width_result = t
				line_width = GetUnitValueByMils_utilityprogram( 6)
				foreach( line line_ls
					line_width_error = nil
					if( line->isSameWidth then
						width = car( line->segments)->width
						unless( width == line_width
							line_width_error = t
							error_line_width = width
						)
					else
						foreach( line_seg path->segments
							;;; check line width
							width = line_seg->width
							unless( width == line_width
								line_width_error = t
								error_line_width = width
							)
						)
					)
					
					if( line_width_error then
						fprintf( out_port "\t\tLine width should be %L, not %L %s\n" line_width error_line_width _allegro_unit)
						width_result = nil
					)
				)
				
				fprintf( out_port "\t     %s Line width\n" GetResultMsg_checksmd( width_result))
				unless( width_result
					result = nil
				)
				;;;;;
				
				;;;;; check gap
				fprintf( out_port "\t(2). Check gap between %s & %s\n" _layer_pkg_assembly_top layer)
				
				distance = GetDistanceBetweenLines_checksmd( list( GetAssemblyTopOutline_checksmd()) line_ls)
				unless( distance
					fprintf( out_port "\tGet distance fail!\n")
				)
				
				gap_result = t
				target_distance = GetUnitValueByMils_utilityprogram( 8) - GetUnitValueByMils_utilityprogram( 3)
				unless( distance >= target_distance
					fprintf( out_port "\t\tGap = %L %s\n" distance _allegro_unit)
					fprintf( out_port "\t\tGap between ASSEMBLY_TOP and SILKSCREEN_TOP should be %L %s\n" target_distance _allegro_unit)
					fprintf( out_port "\t\t( 8mils(gap)-3mils(silkscreen line width/2) = 5mils )\n")
					gap_result = nil
				)
				
				fprintf( out_port "\t     %s Gap\n" GetResultMsg_checksmd( gap_result))
				unless( gap_result
					result = nil
				)
				;;;;;
			
				;;;;; check any silkscreen overlap pad
				fprintf( out_port "\t(3). Check overlap on pad\n")
				overlap_result = t
				pin_ls = GetPinList_utilityprogram( _layer_pin_top)

				visible_ls = axlVisibleGet()
				; hide all items
				axlVisibleDesign( nil)
				; display layer
				axlVisibleLayer( layer t)
				; filter need to right before axlSingleSelectBox
				axlSetFindFilter( ?enabled '(noall lines) ?onButtons '(noall lines))
				foreach( pin pin_ls
					when( axlSingleSelectBox( pin->bBox)
						fprintf( out_port "\t\tThere's line overlap on PAD : %s %L\n" pin->name pin->xy)
						overlap_result = nil
					)
				)
				
				axlSetFindFilter( ?enabled '(noall) ?onButtons '(noall))
				axlVisibleSet( visible_ls)
				
				fprintf( out_port "\t     %s Overlap\n" GetResultMsg_checksmd( overlap_result))
				unless( overlap_result
					result = nil
				)
				;;;;;
			)
		)
		
		PrintCheckResult_checksmd( result layer out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		return( result)
	)
)

; 3.PACKAGE GEOMETRY/PLACE_BOUND_TOP :
;   SHAPE 依照 ASSEMBLY_TOP 大小除非 PAD 超過外框大小就依照 PAD 的大小用 GRID 5 MIL 框住
;   並跟外框大小合併為一個 SHAPE
procedure( CheckPkgPlaceBoundTop_checksmd( out_port)
	prog( ( result layer assembly_top_outline assembly_top_points temp_shape pin_ls temp_pin_shape_ls
			merged_shape result_points temp_shpae target_shape distance)
		result = t
		layer = _layer_pkg_place_bound_top
		printf( "3. Check %s\n" layer)
		fprintf( out_port "3. Check %s\n" layer)
		fprintf( out_port "* Merge %s outline with PAD expand 5mils\n" _layer_pkg_assembly_top)
		fprintf( out_port "  Create a temp shape in %s, and remove it after comparing size" _layer_for_temp_shape)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_checksmd( layer out_port)
		
		when( result
			expand_mils = axlMKSConvert( ( 1.5 / 2) "MM" "MILS")
			assembly_top_outline = GetAssemblyTopOutline_checksmd()
			assembly_top_points = GetExpandPoints_checksmd( assembly_top_outline expand_mils)
			temp_shape = CreateShape_checksmd( assembly_top_points _layer_for_temp_shape)
			
			visible_ls = axlVisibleGet()
			axlVisibleDesign( nil)
			axlVisibleLayer( _layer_pkg_assembly_top t)			
			pin_ls = GetPinList_utilityprogram( _layer_pin_top)
			foreach( pin pin_ls
				box = GetPinBox_checksmd( pin)
				; check if pin overlap on assembly_top
				if( axlSingleSelectBox( box) && car( axlGetSelSet()->segments)->width == 0 then
					pin_expand_mils = 5
				else
					pin_expand_mils = 0
				)
				
				pin_points = GetPointsByBox_checksmd( box ( pin_expand_mils + expand_mils))
				
				temp_pin_shape = CreateShape_checksmd( pin_points _layer_for_temp_shape)
				temp_pin_shape_ls = append1(temp_pin_shape_ls temp_pin_shape)
			)
			
			axlClearSelSet()
			axlSetFindFilter( ?enabled '(noall) ?onButtons '(noall))
			axlVisibleSet( visible_ls)
		
			axlShapeMerge( temp_shape temp_pin_shape_ls 'quiet)
			; get shape after ShapeMerge 
			merged_shape = car( GetShapeList_utilityprogram( _layer_for_temp_shape))
			; shrink expanded mils
			result_points = GetExpandPoints_createsmd( merged_shape -expand_mils)
			temp_shape = CreateShape_createsmd( result_points _layer_for_temp_shape)
			axlDeleteObject( merged_shape)
			
			target_shape = car( GetShapeList_utilityprogram( layer))
			unless( IsSameShape_checksmd( target_shape temp_shape)
				fprintf( out_port "\tShape is incorrect\n")
				result = nil
			)
		
			axlDeleteObject( temp_shape)
		)
		
		PrintCheckResult_checksmd( result layer out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		return( result)
	)
)

; 4.PACKAGE GEOMETRY/DFA_BOUND_TOP :
;   同上與 PLACE_BOUND_TOP 一樣
procedure( CheckPkgDFABoundTop_checksmd( out_port)
	prog( ( result layer place_bound_top_shape dfa_bound_top_shape distance)
		result = t
		layer = _layer_pkg_dfa_bound_top
		printf( "4. Check %s\n" layer)
		fprintf( out_port "4. Check %s\n" layer)
		fprintf( out_port "* Shape should same with %s" _layer_pkg_place_bound_top)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_checksmd( layer out_port)
		
		when( result
			place_bound_top_shape = car( GetShapeList_utilityprogram( _layer_pkg_place_bound_top))
			dfa_bound_top_shape = car( GetShapeList_utilityprogram( layer))
			unless( IsSameShape_checksmd( place_bound_top_shape dfa_bound_top_shape)
				fprintf( out_port "\tShape is different with %s.\n" _layer_pkg_place_bound_top)
				result = nil
			)
		)

		PrintCheckResult_checksmd( result layer out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		return( result)
	)
)

; 5.MANUFACTURING/NO_PROBE_TOP :
;   SHAPE 依照 ASSEMBLY_TOP 大小除非 PAD 超過外框大小就依照 PAD 的大小用沿著 PAD 框起
;   並跟外框大小合併為一個 SHAPE 再往外推 0.381mm = 15mil
procedure( CheckManufacturingNoProbeTop_checksmd( out_port)
	prog( ( result layer assembly_top_outline assembly_top_points temp_shape pin_ls temp_pin_shape_ls
			temp_merge_shpae target_shape distance)
		result = t
		layer = _layer_manufacturing_no_probe_top
		printf( "5. Check %s\n" layer)
		fprintf( out_port "5. Check %s\n" layer)
		fprintf( out_port "* %s and PAD outline expand 15mils then merge outlines to shape\n" _layer_pkg_assembly_top)
		fprintf( out_port "  Create a temp shape in %s, and remove it after comparing size" _layer_for_temp_shape)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_checksmd( layer out_port)
		
		when( result
			expand_mils = axlMKSConvert( ( 1.5 / 2) "MM" "MILS")
			assembly_top_outline = GetAssemblyTopOutline_checksmd()
			assembly_top_points = GetPointsByBox_checksmd( assembly_top_outline->bBox ( 15 + expand_mils))
			temp_shape = CreateShape_checksmd( assembly_top_points _layer_for_temp_shape)
			
			pin_ls = GetPinList_utilityprogram( _layer_pin_top)
			foreach( pin pin_ls
				box = GetPinBox_checksmd( pin)
				pin_points = GetPointsByBox_checksmd( box ( 15 + expand_mils))
				
				temp_pin_shape = CreateShape_checksmd( pin_points _layer_for_temp_shape)
				temp_pin_shape_ls = append1(temp_pin_shape_ls temp_pin_shape)
			)
			
			axlShapeMerge( temp_shape temp_pin_shape_ls 'quiet)
			; get shape after ShapeMerge 
			merged_shape = car( GetShapeList_utilityprogram( _layer_for_temp_shape))
			; shrink expanded mils
			result_points = GetExpandPoints_createsmd( merged_shape -expand_mils)
			temp_shape = CreateShape_createsmd( result_points _layer_for_temp_shape)
			axlDeleteObject( merged_shape)

			target_shape = car( GetShapeList_utilityprogram( layer))
			
			unless( IsSameShape_checksmd( target_shape temp_shape)
				fprintf( out_port "\tShape is incorrect\n")
				result = nil
			)
		
			axlDeleteObject( temp_shape)
		)
		
		PrintCheckResult_checksmd( result layer out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		return( result)
	)
)

; 6.REF 3 個層面 :
;   (REF DES/ASSEMBLY_TOP ) , (REF DES/SILKSCREEN_TOP) , (COMPONENT VALUE/DISPLAY_TOP)
procedure( CheckRefDes_checksmd( out_port)
	prog( ( layer result)
		result = t
		printf( "6. Check REF layers\n")
		fprintf( out_port "6. Check REF layers\n")
		fprintf( out_port "* layer %s & %s & %s" "REF DES/ASSEMBLY_TOP" "REF DES/SILKSCREEN_TOP" "COMPONENT VALUE/DISPLAY_TOP")
		fprintf( out_port "\n\n")
		
		key = "*"
		msg = "\tRef type not found on layer [%s]!\n"
		
		layer = "REF DES/ASSEMBLY_TOP"
		text_ls = GetTextList_utilityprogram( layer)
		text = setof( x text_ls index( lowerCase( x->text) key))
		unless( text
			fprintf( out_port msg layer)
			result = nil
		)
		
		layer = "REF DES/SILKSCREEN_TOP"
		text_ls = GetTextList_utilityprogram( layer)
		text = setof( x text_ls index( lowerCase( x->text) key))
		unless( text
			fprintf( out_port msg layer)
			result = nil
		)
		
		layer = "COMPONENT VALUE/DISPLAY_TOP"
		text_ls = GetTextList_utilityprogram( layer)
		text = setof( x text_ls index( lowerCase( x->text) key))
		unless( text
			fprintf( out_port msg layer)
			result = nil
		)
		
		PrintCheckResult_checksmd( result "REF DES layers" out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
	)
)

; 7.零件的第 1 PIN 中心都要加三角形 MARK
;   在 PACKAGE GEOMETRY/ ASSEMBLY 層面及 PACKAGE GEOMETRY/SILKSCREEN_TOP 層面也需要三角形 MARK 指向第一 PIN
procedure( CheckPin1Mark_checksmd( out_port)
	prog( ( assembly_result silkscreen_result)
		printf( "7. Check PIN1 mark\n")
		fprintf( out_port "7. Check PIN1 mark\n")
		fprintf( out_port "* Line on %s & %s\n" _layer_pkg_place_bound_top _layer_pkg_silkscreen_top)
		fprintf( out_port "  with line property MARKING_USAGE set to PIN_ONE")
		fprintf( out_port "\n\n")
		
		assembly_result = CheckPin1MarkByLayer_checksmd( _layer_pkg_assembly_top out_port)
		silkscreen_result = CheckPin1MarkByLayer_checksmd( _layer_pkg_silkscreen_top out_port)
		
		PrintCheckResult_checksmd( (assembly_result && silkscreen_result) "PIN1 mark" out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
	)
)

; 8.每個零件都要標示排 PIN 的文字在第一 PIN 跟最後一 PIN :
;   PACKAGE GEOMETRY/SILKSCREEN_TOP & PACKAGE GEOMETRY/ASSEMBLY_TOP 層面
procedure( CheckPinNote_checksmd( out_port)
	prog( ( result first_pin last_pin)
		result = t
		printf( "8. Check PIN note\n")
		fprintf( out_port "8. Check PIN note\n")
		fprintf( out_port "* First and last PIN note on %s & %s" _layer_pkg_silkscreen_top _layer_pkg_assembly_top)
		fprintf( out_port "\n\n")
		
		pin_ls = GetPinList_utilityprogram( _layer_pin_top)
		pin_count = sprintf( nil "%d" length( pin_ls))
		
		silkscreen_top_result = CheckFisrtLastPinNote_checksmd( _layer_pkg_silkscreen_top pin_count out_port)
		assembly_top_result = CheckFisrtLastPinNote_checksmd( _layer_pkg_assembly_top pin_count out_port)
		
		PrintCheckResult_checksmd( ( silkscreen_top_result && assembly_top_result) "PIN note" out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		return( result)
	)
)

; 9.板邊零件都需要建 PCB EDGE :
;   BOARD GEOMETRY/PCB_EDGE 層面
;   要有 PCB EDGE 字樣
procedure( CheckPCBEdgeNote_checksmd( out_port)
	prog( ( result layer target_text text_ls note)
		result = t
		layer = _layer_pcb_edge
		target_text = "PCB EDGE"
		printf( "9. Check PCB Edge Note\n")
		fprintf( out_port "9. Check PCB Edge Note\n")
		fprintf( out_port "* Text \"%s\" on %s" target_text layer)
		fprintf( out_port "\n\n")
		
		result = CheckLayerExists_checksmd( layer out_port)
		
		when( result
			text_ls = GetTextList_utilityprogram( layer)

			;;; check text exist
			note = setof( x text_ls rexMatchp( target_text upperCase( x->text)))
			unless( note
				fprintf( out_port "\tNote [%s] not found!\n" target_text)
				result = nil
			)
			
			;;; check textBlock is "1"
			foreach( item text_ls
				unless( item->textBlock == "1"
					fprintf( out_port "\tNote format incorrect! [%s]\n" item->text)
					result = nil
				)
			)
		)
		
		PrintCheckResult_checksmd( result "PCB edge note" out_port)
		
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		return( result)
	)
)

; 10.每顆零件都要加 NOTE 在零件下方 :
;   PACKAGE GEOMETRY/BODY_CENTER 層面
;   文字大小要用 TEXT_BLOCK# 10, (height: 0.7620, width: 0.5080, line spacing: 0.7620),
;   數字大小固定
procedure( CheckNote_checksmd( out_port)
	prog( ( result text_ls msg padstack rev date)
		result = t
		printf( "10. Check Symbol Notes on %s\n" _layer_pkg_body_center)
		fprintf( out_port "10. Check Symbol Notes on %s\n" _layer_pkg_body_center)
		fprintf( out_port "* Contains following notes\n")
		fprintf( out_port "  %s\n  %s\n  %s" _note_padstack_name _note_rev _note_date)
		fprintf( out_port "\n\n")
		
		text_ls = GetTextList_utilityprogram( _layer_pkg_body_center)
		
		;;; check text exist
		msg = "\tNote [%s] not found!\n"
		text_padstack = setof( x text_ls rexMatchp( _note_padstack_name lowerCase( x->text)))
		unless( text_padstack
			fprintf( out_port msg _note_padstack_name)
			result = nil
		)
		
		text_rev = setof( x text_ls ( x->text == _note_rev))
		unless( text_rev
			fprintf( out_port msg _note_rev)
			result = nil
		)
		
		text_date = setof( x text_ls rexMatchp( _note_date x->text))
		unless( text_date
			fprintf( out_port msg _note_date)
			result = nil
		)
		
		;;; check textBlock is "10"
		foreach( item text_ls
			unless( item->textBlock == "10"
				fprintf( out_port "\tNote [%s] format incorrect!\n" item->text)
				result = nil
			)
		)

		PrintCheckResult_checksmd( result "Symbol notes" out_port)
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Log

procedure( CheckLayerExists_checksmd( layer out_port)
	prog( ( result)
		result = axlVisibleLayer( layer t)
		
		if( result then
			fprintf( out_port "\t%s exists\n" layer)
		else
			fprintf( out_port "\t%s not found!!\n" layer)
		)
		
		return( result)
	)
)

procedure( CheckPin1MarkByLayer_checksmd( layer out_port)
	prog( ( result pin1_mark_ls)
		result = t
		pin1_mark_ls = GetPin1MarkList_createsmd()
		
		unless( dtpr( setof( x pin1_mark_ls ( x->layer == layer)))
			fprintf( out_port "\tPIN1 mark not found on %s!\n" layer)
			result = nil
		)
		
		return( result)
	)
)

procedure( CheckFisrtLastPinNote_checksmd( layer pin_count out_port)
	prog( ( result text_ls first_pin last_pin)
		result = t
		text_ls = GetTextList_utilityprogram( layer)
		;;; check text exist
		first_pin = setof( x text_ls ( x->text == "1"))
		unless( first_pin
			fprintf( out_port "\tFirst PIN note not found on %s!\n" layer)
			result = nil
		)
		
		last_pin = setof( x text_ls ( x->text == pin_count))
		unless( last_pin
			fprintf( out_port "\tLast PIN note not found on %s!\n" layer)
			result = nil
		)
		
		return( result)
	)
)

procedure( PrintCheckResult_checksmd( result msg out_port)
	fprintf( out_port "\n%s %s\n" GetResultMsg_checksmd( result) msg)
)

procedure( GetResultMsg_checksmd( result)
	prog( ( msg)
		if( result then
			msg = "Pass"
		else
			msg = "Fail"
		)
		
		return( sprintf( nil "[%s]" msg))
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Log

;;;;;;;;;;;;;;;;;;;;;;;;; Get data

procedure( GetAssemblyTopOutline_checksmd()
	prog( ( line_ls pin1_mark_ls assembly_top_outline)
		line_ls = GetLineList_utilityprogram( _layer_pkg_assembly_top)
		pin1_mark_ls = GetPin1MarkList_createsmd()
		assembly_top_outline = car( setof( x line_ls !member( x pin1_mark_ls)))
		return( assembly_top_outline)
	)
)

procedure( GetDistanceBetweenLines_checksmd( line_ls_1 line_ls_2)
	prog( ( result)
		unless( dtpr( line_ls_1) && dtpr( line_ls_2)
			return( nil)
		)
		
		result = nil
		foreach( line_1 line_ls_1
			foreach( line_2 line_ls_2
				distance = axlAirGap( line_1 line_2 nil 'anyLayer)
				when( result == nil || result > distance
					result = distance
				)
			)
		)
		
		return( result)
	)
)

procedure( GetPinBox_checksmd( pin)
	prog( ( pad left_bot right_top)
		; because pin->bBox will include soldermask outline, so it will 2mils bigger
		pad = car( setof( x pin->pads ( x->layer == "ETCH/TOP" && x->figureName != "NULL")))
		; box = left bottom : right top
		left_bot = axlMXYAdd( pin->xy nth( 0 pad->bBox))
		right_top = axlMXYAdd( pin->xy nth( 1 pad->bBox))
		
		return( list( left_bot right_top))
	)
)

procedure( GetExpandPoints_checksmd( path @optional ( expand_mils 0))
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

procedure( GetPointsByBox_checksmd( box @optional ( expand_mils 0))
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

procedure( CreateShape_checksmd( points layer)
	prog( ( path shape)
		; add the first point to complete the shape
		path = axlPathStart( append1( points car( points)))
		shape = car( axlDBCreateShape( path t layer))
		
		return( shape)
	)
)

procedure( IsSameShape_checksmd( shape1 shape2)
	prog( ( poly1 poly2 result)
		poly1 = car( axlPolyFromDB( shape1))
		poly2 = car( axlPolyFromDB( shape2))
		
		unless( length( poly1->vertices) == length( poly2->vertices)
			return( nil)
		)
		
		result = setof( x poly1->vertices member( x poly2->vertices))
		if( length( result) == length( poly1->vertices) then
			return( t)
		else
			return( nil)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Get data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_smd" 'Main_checksmd)
/*
(encrypt "c:/skill/check_smd_v1d1.il" "c:/skill/check_smd_v1d1.ile")
(load "check_smd_v1d1.il")
(load "check_smd_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup