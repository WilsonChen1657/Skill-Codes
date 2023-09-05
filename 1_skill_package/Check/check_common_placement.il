/*
################################################################################
#                                                                              #
#  Developer: Derek Hsu, Wilson Chen                                           #
#  Start Date: 2020/06/01                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       1. Fiducial:                                                           #
#            It should have at least 3 fiducial on the top and bottom side     #
#            individually                                                      #
#       2. Tooling hole:                                                       #
#            It should have at least 3 footprint of "tl_3d18_nph" or           #
#            "tl_2d36_nph"                                                     #
#       3. Label:                                                              #
#            It should have at least 1 refdes is LABEL* or LBL*                #
#       4. Note 5:                                                             #
#            It should have 1 "LBL_VENDER"                                     #
#       5. Part number & Board number:                                         #
#            It should have Part number & Board number text on board           #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global variable

procedure( Init_checkcommonplacement()
	setq( _etch_subclass_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _layer_top "ETCH/TOP")
	setq( _layer_bottom "ETCH/BOTTOM")
	
	setq( _layer_bg_silk_top "BOARD GEOMETRY/SILKSCREEN_TOP")
	setq( _layer_bg_silk_bottom "BOARD GEOMETRY/SILKSCREEN_BOTTOM")
	
	setq( _layer_pg_silk_top "PACKAGE GEOMETRY/SILKSCREEN_TOP")
	setq( _layer_pg_silk_bottom "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM")
	
	setq( _layer_rd_silk_top "REF DES/SILKSCREEN_TOP")
	setq( _layer_rd_silk_bottom "REF DES/SILKSCREEN_BOTTOM")
	
	setq( _layer_bg_brd_form_key "BOARD GEOMETRY/BOARD_FORM_KEY")
	setq( _layer_pcb_fab "DRAWING FORMAT/PCB_FAB")
	
	setq( _fiducial_top_ls nil)
	setq( _fiducial_bot_ls nil)
	setq( _tooling_hole_ls nil)
	setq( _label_ls nil)
	setq( _note_5_ls nil)
	setq( _bn_text_ls nil)
	setq( _pn_text_ls nil)
	setq( _error_press_fit_pin_ls nil)
	setq( _error_mh_pin_ls nil)
	setq( _error_dip_pin_ls nil)
	
	;;;;; log filename
	;setq( _fiducial_logname "")
	setq( _check_common_placement_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkcommonplacement()
	prog( ()
		unless( Main_locker()
			return( nil)
		)
		
		Init_checkcommonplacement()
		
		CheckFiducial_checkcommonplacement()
		CheckToolingHole_checkcommonplacement()
		CheckLabel_checkcommonplacement()
		CheckNote5_checkcommonplacement()
		CheckPNandBN_checkcommonplacement()
		;CheckPadstack_checkcommonplacement()
		
		WriteLog_checkcommonplacement()
		axlUIViewFileCreate( _check_common_placement_logname "Check common placement Report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CheckFiducial_checkcommonplacement()
	let( ( footprint_name_ls sym_ls)
		_fiducial_top_ls = GetFiducialByLayer_checkcommonplacement( _layer_top)
		_fiducial_bot_ls = GetFiducialByLayer_checkcommonplacement( _layer_bottom)
	)
)

procedure( CheckToolingHole_checkcommonplacement()
	let( ( footprint_name_ls sym_ls)
		footprint_name_ls = list( "tl_3d18_nph" "tl_2d36_nph")
		sym_ls = axlDBGetDesign()->symbols
		_tooling_hole_ls = setof( x sym_ls member( lowerCase( x->name) footprint_name_ls))
	)
)

procedure( CheckLabel_checkcommonplacement()
	let( ( refdes_ls sym_ls)
		refdes_ls = list( "LABEL" "LBL")
		sym_ls = axlDBGetDesign()->symbols
		_label_ls = setof( x sym_ls and( x->refdes index( upperCase( x->refdes) "LABEL")))
	)
)

procedure( CheckNote5_checkcommonplacement()
	let( ( sym_ls)
		sym_ls = axlDBGetDesign()->symbols
		_note_5_ls = setof( x sym_ls equal( upperCase( x->name) "LBL_VENDER"))
	)
)

procedure( CheckPNandBN_checkcommonplacement()
	let( ( brd_form_key_text_ls des1_key_text_id pn_key_text_id pcb_fab_text_ls bn_text_id pn_text_id text_layer_ls)
		; check part number & board number
		brd_form_key_text_ls = GetTextList_utilityprogram( _layer_bg_brd_form_key)
		des1_key_text_id = car( setof( x brd_form_key_text_ls x->text == "[des1]"))
		pn_key_text_id = car( setof( x brd_form_key_text_ls x->text == "[pn]"))
		
		pcb_fab_text_ls = GetTextList_utilityprogram( _layer_pcb_fab)
		bn_text_id = car( setof( x pcb_fab_text_ls x->xy == des1_key_text_id->xy))
		pn_text_id = car( setof( x pcb_fab_text_ls x->xy == pn_key_text_id->xy))
		
		board_num = nth( 2 axlStringCSVParse( bn_text_id->text ","))
		part_num = pn_text_id->text
		
		_bn_text_ls = nil
		_pn_text_ls = nil
		text_layer_ls = list( _layer_bg_silk_top _layer_bg_silk_bottom _layer_pg_silk_top _layer_pg_silk_bottom _layer_rd_silk_top _layer_rd_silk_bottom)
		foreach( layer text_layer_ls
			text_ls = GetTextList_utilityprogram( layer)
			result_text_ls = setof( x text_ls index( x->text board_num))
			when( result_text_ls
				_bn_text_ls = append( _bn_text_ls result_text_ls)
			)
			
			result_text_ls = setof( x text_ls x->text == part_num)
			when( result_text_ls
				_pn_text_ls = append( _pn_text_ls result_text_ls)
			)
		)
	)
)

procedure( CheckPadstack_checkcommonplacement()
	let( ( all_pin_ls press_fit_pin_ls dip_pin_ls)
		foreach( sym_id axlDBGetDesign()->symbols
			all_pin_ls = append( all_pin_ls sym_id->pins)
		)
		
		; press fit must be Full_contact
		press_fit_pin_ls = setof( x all_pin_ls memq( 'LEAD_DIAMETER x->prop->?))
		_error_press_fit_pin_ls = setof( x press_fit_pin_ls or( x->prop->DYN_THERMAL_CON_TYPE == nil !index( lowerCase( x->prop->DYN_THERMAL_CON_TYPE) "full_contact")))
		
		
		all_pin_ls = setof( x all_pin_ls !exists( y press_fit_pin_ls x == y))
		dip_pin_ls = setof( x all_pin_ls and( x->plating != "NON_PLATED" !zerop( x->definition->drillDiameter)))
		
		mh_pin_ls = setof( x dip_pin_ls and( x->parent->refdes rexMatchp( "^MH" x->parent->refdes)))
		
		_error_mh_pin_ls = setof( x mh_pin_ls or( x->prop->DYN_THERMAL_CON_TYPE == nil !index( lowerCase( x->prop->DYN_THERMAL_CON_TYPE) "full_contact")))
		
		;pin_id = car( setof( x dip_pin_ls x->xy == '(3515.749 2860.237)))
		;parseString( "full_contact" ";")
		; DIAGONAL ?
		
		thermal_con_type_ls = '( "full_contact")
		inner_thermal_con_type_ls = '( "orthogonal" "diagonal")
		; DIP pin has to be Full_contact or Thermal relief
		foreach( pin_id dip_pin_ls
			if( pin_id->prop->DYN_THERMAL_CON_TYPE then
				con_type_ls = parseString( pin_id->prop->DYN_THERMAL_CON_TYPE ";")
				foreach( con_type con_type_ls
					data = parseString( con_type ":")
					layer = car( data)
					type = cdr( data)
					if( length( data) == 1 || member( layer '( "TOP" "BOTTOM")) then
						unless( member( car( data) thermal_con_type_ls)
							_error_dip_pin_ls = append1( _error_dip_pin_ls pin_id)
						)
					else					
						unless( member( car( data) inner_thermal_con_type_ls)
							_error_dip_pin_ls = append1( _error_dip_pin_ls pin_id)
						)
					)
				)
			else
				_error_dip_pin_ls = append1( _error_dip_pin_ls pin_id)
			)
		)
		
		_error_dip_pin_ls = setof( x dip_pin_ls or( x->prop->DYN_THERMAL_CON_TYPE == nil and( !index( lowerCase( x->prop->DYN_THERMAL_CON_TYPE) "full_contact") 
																										!index( lowerCase( x->prop->DYN_THERMAL_CON_TYPE) "orthogonal"))))
	)
)

procedure( GetFiducialByLayer_checkcommonplacement( layer)
	prog( ( sym_ls)
		sym_ls = axlDBGetDesign()->symbols
		
		;;;; one pin only
		sym_ls = setof( s sym_ls onep( length( s->pins)))
		
		;;;;; is smd
		sym_ls = setof( s sym_ls !car( s->pins)->isThrough)
		
		;;;; no net name on pin
		sym_ls = setof( s sym_ls equal( "" (car( s->pins)->net->name || "")))
		
		;;;; no via
		sym_ls = setof( s sym_ls !exists( s sym_ls member( "via" s->childen~>objType)))
		
		;;;; on layer
		sym_ls = setof( s sym_ls equal( layer car( car( s->pins)->startEnd)))
		
		return( sym_ls)
	)
)

procedure( WriteLog_checkcommonplacement()
	prog( ( log_info out_port result format)
		log_info = SetUpLog_utilityprogram( "check_common_placement")
		unless( log_info
			return( nil)
		)
		
		out_port = nth( 0 log_info)
		_check_common_placement_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" GetSchematicName_utilityprogram())
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port GetLogSeperator_utilityprogram( "Fiducial"))
		fprintf( out_port "It should have at least 3 fiducial on Top and Bottom individually\n\n")
		format = "\t[%s]: %L\n"
		fiducial_top_count = length( _fiducial_top_ls)
		fiducial_bot_count = length( _fiducial_bot_ls)
		fprintf( out_port "fiducial on Top: [%d]\n" length( _fiducial_top_ls))
		foreach( sym_id _fiducial_top_ls
			fprintf( out_port format sym_id->name sym_id->xy)
		)
		
		fprintf( out_port "fiducial on Bot: [%d]\n" length( _fiducial_bot_ls))
		foreach( sym_id _fiducial_bot_ls
			fprintf( out_port format sym_id->name sym_id->xy)
		)
		
		fprintf( out_port "\n")
		
		result = and( (fiducial_top_count > 2) (fiducial_bot_count > 2))
		fprintf( out_port "%s\n" GetResultString_checkcommonplacement( result))
		
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram( "Tooling hole"))
		fprintf( out_port "\n\n")
		
		fprintf( out_port "There should have at least 3 \"tl_3d18_nph\" or \"tl_2d36_nph\" type of tooling hole footprint\n\n")
		
		format = "%-10s,%-20s,%-20s,%s\n"
		fprintf( out_port format "Subclass" "Footprint" "Refdes" "XY")
		if( _tooling_hole_ls then
			foreach( sym_id _tooling_hole_ls
				sprintf( xy "%L" sym_id->xy)
				fprintf( out_port format sym_id->layer sym_id->name sym_id->refdes xy)
			)
		else
			fprintf( out_port "\tNone\n")
		)
		
		fprintf( out_port "\n")
		result = length( _tooling_hole_ls) >= 3
		fprintf( out_port "%s\n" GetResultString_checkcommonplacement( result))
		
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram( "Label"))
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Symbol's refdes should have at least 1 \"LABEL\" or \"LBL\", but not \"LABEL*\" or \"LBL*\"\n\n")
		
		result = length( _label_ls) >= 1
		
		format = "%-10s,%-20s,%-20s,%s\n"
		fprintf( out_port format "Subclass" "Footprint" "Refdes" "XY")
		if( _label_ls then
			foreach( sym_id _label_ls
				sprintf( xy "%L" sym_id->xy)
				fprintf( out_port format sym_id->layer sym_id->name sym_id->refdes xy)
				when( result && member( sym_id->refdes '( "LABEL*" "LBL*"))
					result = nil
				)
			)
		else
			fprintf( out_port "\tNone\n")
		)
		
		fprintf( out_port "\n")
		fprintf( out_port "%s\n" GetResultString_checkcommonplacement( result))
		
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram( "Note 5"))
		fprintf( out_port "\n\n")
		
		result = t
		fprintf( out_port "There should have at least 1 \"LBL_VENDER\" footprint\n\n")
		
		format = "%-10s,%-20s,%s\n"
		fprintf( out_port format "Subclass" "Footprint" "XY")
		if( _note_5_ls then
			foreach( sym_id _note_5_ls
				sprintf( xy "%L" sym_id->xy)
				fprintf( out_port format sym_id->layer sym_id->name xy)
			)
		else
			fprintf( out_port "\tNone\n")
		)
		
		fprintf( out_port "\n")
		result = length( _note_5_ls) >= 1
		fprintf( out_port "%s\n" GetResultString_checkcommonplacement( result))
		
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram( "Part number & Board number"))
		fprintf( out_port "\n\n")
		
		result = t
		fprintf( out_port "There should have text of board number and part number on [%s]\n\n" _layer_pcb_fab)
		
		format = "%-30s,%-30s,%s\n"
		fprintf( out_port format "Subclass" "Text" "XY")
		text_ls = append( _bn_text_ls _pn_text_ls)
		if( text_ls then
			foreach( text_id text_ls
				sprintf( xy "%L" text_id->xy)
				fprintf( out_port format text_id->layer text_id->text xy)
			)
		else
			fprintf( out_port "\tNone\n")
		)
		
		fprintf( out_port "\n")
		result = length( _bn_text_ls) >= 1
		fprintf( out_port "Board Number %s\n" GetResultString_checkcommonplacement( result))
		result = length( _pn_text_ls) >= 1
		fprintf( out_port "Part Number %s\n" GetResultString_checkcommonplacement( result))
		
		close( out_port)
		return( t)
	)
)

procedure( GetResultString_checkcommonplacement( result)
	let( ()
		if( result
			"[Pass]"
			"[Fail]"
		)
	)
)

procedure( DisplayPinCheckResult_checkcommonplacement( out_port pin_ls)
	let( ()
		if( pin_ls then
			pin_ls = sort( pin_ls 'SortByName_checkcommonplacement)
			foreach( pin_id pin_ls
				sprintf( pin_xy "%L" pin_id->xy)
				fprintf( out_port format pin_id->name pin_xy pin_id->prop->DYN_THERMAL_CON_TYPE)
			)
		else
			fprintf( out_port "\tNone\n")
		)
	)
)

procedure( SortByName_checkcommonplacement( a b)
	let( ()
		!alphalessp( a->name b->name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_common_placement" 'Main_checkcommonplacement)
/*
(encrypt "C:/skill/check_common_placement_v1d0.il" "C:/skill/check_common_placement_v1d0.ile")
(load "check_common_placement_v1d0.il")
(load "check_common_placement_v1d0.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of setup