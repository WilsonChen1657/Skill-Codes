/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/04/20                                                      #
#  Reference: utility_program                                                  #
#  Purpose:                                                                    #
#       Check symbol 0402 and 0201 if there is any via or shape                #
#           between two pins.                                                  #
#       Only if symbol name is 0402 or 0201, and prefix is C, R, or L, and     #
#           it's pins has no properties or DYN_THERMAL_CON_TYPE = Full_contact #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkfullcontact()
	setq( _layer_route_keepout_bottom "ROUTE KEEPOUT/BOTTOM")
	setq( _layer_pin_top "PIN/TOP")
	setq( _layer_pin_bottom "PIN/BOTTOM")
	
	setq( _symbol_ls list( "0402" "0201"))
	setq( _symbol_term_ls list( "L" "R" "C"))
	setq( _0402_keepout_width 11.8)
	setq( _0402_keepout_height 20)
	setq( _0402_half_keepout_width ( _0402_keepout_width / 2))
	setq( _0402_half_keepout_height ( _0402_keepout_height / 2))
	setq( _0201_keepout_width 9.8)
	setq( _0201_keepout_height 13.1)
	setq( _0201_half_keepout_width ( _0201_keepout_width / 2))
	setq( _0201_half_keepout_height ( _0201_keepout_height / 2))
	
	setq( _count 0)
	setq( _via_filter '(noall vias))
	setq( _shape_filter '(noall shapes))
	setq( _cline_filter '(noall clines clinesegs))
	
	setq( _angle list( 0.00 90.00 180.00 270.00))
	setq( _check_full_contact_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkfullcontact()
	prog( (log_info out_port introduction sub_introduction
		   via_filter shape_filter cline_filter angle
		   top_symbol_ls top_target_symbol_ls top_via_overlap_ls top_shape_overlap_ls top_cline_overlap_ls
		   bottom_symbol_ls bottom_target_symbol_ls bottom_via_overlap_ls bottom_shape_overlap_ls bottom_cline_overlap_ls)
		Init_checkfullcontact()
		
		log_info = SetUpLog_utilityprogram( "check_full_contact")
		unless( log_info
			return( nil)
		)
		
		out_port = nth( 0 log_info)
		_check_full_contact_logname = nth( 1 log_info)
		
		introduction = "To check route keepout for symbol 0402 & 0201."
		sub_introduction = "Check if any shape, via, or cline between symbol's two pin. "
		sub_introduction = sprintf( nil "%s\n\n%s" sub_introduction "Caution : When symbol rotation isn't 90, 180, or 270, need to check manually.")
		LogBasicInfo_checkfullcontact( out_port introduction sub_introduction)

		check_symbol_ls = GetCheckList_checkfullcontact()

		ManualCheckOverlap_checkfullcontact( out_port check_symbol_ls)
		
		CheckKeepout_checkfullcontact( out_port check_symbol_ls)
		
		close( out_port)
		axlUIViewFileCreate( _check_full_contact_logname "Check full contact report" nil)
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( GetSymbolKeepoutPoints_checkfullcontact( symbol)
	prog( (left_bot_pt right_top_pt)
		center_xy = symbol->xy
		
		;if( exists( x _0402_list ( x == symbol->name)) then
		if( index( symbol->name "0402") then
			half_keepout_width = _0402_half_keepout_width
			half_keepout_height = _0402_half_keepout_height
		else
			half_keepout_width = _0201_half_keepout_width
			half_keepout_height = _0201_half_keepout_height
		)
		
		left_top_pt = axlMXYAdd( center_xy -half_keepout_width:half_keepout_height)
		left_bot_pt = axlMXYAdd( center_xy -half_keepout_width:-half_keepout_height)
		right_top_pt = axlMXYAdd( center_xy half_keepout_width:half_keepout_height)
		right_bot_pt = axlMXYAdd( center_xy half_keepout_width:-half_keepout_height)
		
		return( list( left_top_pt left_bot_pt right_top_pt right_bot_pt))
	)
)

procedure( GetSymbolKeepoutRotatePoints_checkfullcontact( symbol)
	prog( (left_bot_pt right_top_pt)
		center_xy = symbol->xy
		points = GetSymbolKeepoutPoints_checkfullcontact( symbol)
		
		left_top_pt = nth( 0 points)
		left_bot_pt = nth( 1 points)
		right_top_pt = nth( 2 points)
		right_bot_pt = nth( 3 points)
		; Rotate
		left_top_pt = axlGeoRotatePt( symbol->rotation left_top_pt center_xy)
		left_bot_pt = axlGeoRotatePt( symbol->rotation left_bot_pt center_xy)
		right_top_pt = axlGeoRotatePt( symbol->rotation right_top_pt center_xy)
		right_bot_pt = axlGeoRotatePt( symbol->rotation right_bot_pt center_xy)
		
		return( list( left_top_pt left_bot_pt right_top_pt right_bot_pt))
	)
)

procedure( CheckKeepout_checkfullcontact( out_port check_symbol_ls)
	prog( ( top_check_ls bottom_check_ls)
		; get no special angle
		check_symbol_ls = setof( x check_symbol_ls exists( y _angle ( x->rotation == y)))
		
		fprintf( out_port "Something inside symbol's keepout.\n\n")
		
		top_check_ls = setof( x check_symbol_ls (x->layer == "TOP"))
		bottom_check_ls = setof( x check_symbol_ls (x->layer == "BOTTOM"))
		
		CheckAllOverlap_checkfullcontact( out_port "TOP" top_check_ls)
		CheckAllOverlap_checkfullcontact( out_port "BOTTOM" bottom_check_ls)
		
		;printf( "%s Separate %d\n" subclass length( bottom_via_overlap_ls) + length( bottom_shape_overlap_ls) + length( bottom_cline_overlap_ls))
	)
)

procedure( GetCheckList_checkfullcontact()
	prog( ( symbol_ls check_symbol_ls)
		top_symbol_ls = GetSymbolList_utilityprogram( _layer_pin_top)
		bottom_symbol_ls = GetSymbolList_utilityprogram( _layer_pin_bottom)
		symbol_ls = append( top_symbol_ls bottom_symbol_ls)
		check_symbol_ls = setof( x symbol_ls ( exists( y _symbol_ls index( x->name y)) && exists( y _symbol_term_ls index( x->name y))))
		return( check_symbol_ls)
	)
)

procedure( ManualCheckOverlap_checkfullcontact( out_port check_symbol_ls)
	prog( ( manual_check_ls)
		manual_check_ls = setof( x check_symbol_ls !exists( y _angle ( x->rotation == y)))
		unless( dtpr( manual_check_ls)
			return( nil)
		)
		
		fprintf( out_port "Angle not 90, 180, or 270, need check manually.\n\n")
		
		top_check_ls = setof( x manual_check_ls (x->layer == "TOP"))
		bottom_check_ls = setof( x manual_check_ls (x->layer == "BOTTOM"))
		
		CheckAllOverlap_checkfullcontact( out_port "TOP" top_check_ls)
		CheckAllOverlap_checkfullcontact( out_port "BOTTOM" bottom_check_ls)
		
		fprintf( out_port "\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
	)
)

procedure( CheckAllOverlap_checkfullcontact( out_port subclass check_ls)
	prog( ( via_overlap_ls shape_overlap_ls cline_overlap_ls)
		via_overlap_ls = CheckOverlap_checkfullcontact( subclass _via_filter check_ls)
		WriteCheckLog_checkfullcontact( out_port "Via" via_overlap_ls)
		
		when( dtpr( via_overlap_ls)
			fprintf( out_port "\n")
		)
		
		shape_overlap_ls = CheckOverlap_checkfullcontact( subclass _shape_filter check_ls)
		WriteCheckLog_checkfullcontact( out_port "Shape" shape_overlap_ls)
		
		when( dtpr( shape_overlap_ls)
			fprintf( out_port "\n")
		)
		
		/*
		cline_overlap_ls = CheckOverlap_checkfullcontact( subclass _cline_filter check_ls)
		WriteCheckLog_checkfullcontact( out_port "Cline" cline_overlap_ls)
		
		when( dtpr( cline_overlap_ls)
			fprintf( out_port "\n")
		)
		*/
	)
)

procedure( CheckOverlap_checkfullcontact( subclass filter symbol_ls)
	prog( ( visible_list overlap_ls temp_shape_ls)
		visible_list = axlVisibleGet()
		axlVisibleDesign( nil)
		axlVisibleLayer( sprintf(nil "ETCH/%s" subclass ) t)
		axlVisibleLayer( sprintf(nil "VIA CLASS/%s" subclass ) t)
		;filter = '(noall clines clinesegs shapes vias)
		axlSetFindFilter( ?enabled filter ?onButtons filter)
		/*
		if( filter == _cline_filter then
			; cline to shape
			axlAddSelectAll()
			selected_clines = axlGetSelSet()
			foreach( cline selected_clines
				poly = axlPolyFromDB( cline ?endCapType "ROUND")
				temp_shape = axlDBCreateShape( car( poly) t cline->layer)
				temp_shape_ls = append1( temp_shape_ls temp_shape)
			)
			
			axlSetFindFilter( ?enabled _shape_filter ?onButtons _shape_filter)
		)
		*/
		foreach( symbol symbol_ls
			points = GetSymbolKeepoutRotatePoints_checkfullcontact( symbol)
			box = list( nth( 1 points) nth( 2 points))
			if( axlSingleSelectBox( box) && !exists( x overlap_ls ( x == symbol)) then
				overlap_ls = append1( overlap_ls symbol)
			)
		)
		
		if( dtpr( temp_shape_ls) then
			axlDeleteObject( temp_shape_ls)
		)
		
		axlSetFindFilter( ?enabled '(noall) ?onButtons '(noall))
		axlVisibleSet( visible_list)
		return( overlap_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Log

procedure( WriteCheckLog_checkfullcontact( out_port title overlap_ls @optional (show_header nil))
	prog( ( format)
		unless( dtpr( overlap_ls)
			return( nil)
		)
		
		fprintf( out_port "%s overlap with symbol count : %d\n" title length( overlap_ls))
		format = "%-10s,%-15s,%-15s,%s\n"
		;if( show_header then
			fprintf( out_port format "layer" "symbol" "refdes" "Location")
		;)
		
		foreach( item overlap_ls
			layer = sprintf( nil "[%s]" substring( item->layer 1 3))
			symbol = item->name
			refdes = item->refdes
			xy = sprintf( nil "%L" item->xy)
			fprintf( out_port format layer symbol refdes xy)
			axlHighlightObject( item)
		)
		
		return( t)
	)
)

procedure( LogBasicInfo_checkfullcontact( out_port introduction sub_introduction)
	fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
	fprintf( out_port "Schematic name: %s\n" GetSchematicName_utilityprogram())
	fprintf( out_port "Date-time: %L\n" getCurrentTime())
	fprintf( out_port "\n\n")
	
	fprintf( out_port "Introduction: %s\n" introduction)
	
	fprintf( out_port "\t%s\n" sub_introduction)
	fprintf( out_port "\n\n")
		
	fprintf( out_port "\tSymbol name with prefix: %L\n" _symbol_term_ls)
	fprintf( out_port "\tSymbol name with suffix: %L\n" _symbol_ls)
	
	fprintf( out_port "\n\n")
	fprintf( out_port "=====================================================================================================\n")
	fprintf( out_port "\n\n")
)

;;;;;;;;;;;;;;;;;;;;;;;;; End of Log

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

(axlCmdRegister "check_full_contact" 'Main_checkfullcontact)
/*
(encrypt "C:/skill/check_full_contact_v1d1.il" "C:/skill/check_full_contact_v1d1.ile")
(load "check_full_contact_v1d1.il")
(load "check_full_contact_v1d1.ile")
*/