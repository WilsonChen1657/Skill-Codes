/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/04/20                                                      #
#  Reference: utility_program                                                  #
#  Purpose:                                                                    #
#       Get symbol of 0402 and 0201, and create a route keepout area in center.#
#       Only if symbol name is 0402 or 0201, and prefix is C, R, or L,         #
#       and it's pins has no properties or DYN_THERMAL_CON_TYPE = Full_contact #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_createfullcontactrteko()
	setq( _layer_rte_ko_bottom "ROUTE KEEPOUT/BOTTOM")
	setq( _layer_pin_top "PIN/TOP")
	setq( _layer_pin_bottom "PIN/BOTTOM")
	setq( _symbol_ls list( "0402" "0201"))
	setq( _symbol_term_ls list( "C" "L" "R"))
	
	setq( _count 0)
	setq( _via_filter '(noall vias))
	setq( _shape_filter '(noall shapes))
	setq( _cline_filter '(noall clines clinesegs))
	setq( _angle list( 0.00 90.00 180.00 270.00))
	setq( _create_full_contact_route_keepout_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_createfullcontactrteko()
	prog( ( top_pin_ls bottom_pin_ls pin_ls target_pin_ls need_keepout_ls created_ls time_start time_end)
		Init_createfullcontactrteko()
		
		; shape dynamic fill set to disabled
		axlDBControl( 'dynamicFillMode nil)
		; disabled on-line DRC
		axlDBControl( 'drcEnable nil)
		
		top_pin_ls = GetPinList_utilityprogram( _layer_pin_top)
		bottom_pin_ls = GetPinList_utilityprogram( _layer_pin_bottom)
		pin_ls = setof( x append( top_pin_ls bottom_pin_ls) ( x->objType == "symbol" && exists( y _symbol_ls index( x->parent->name y)) && exists( y _symbol_term_ls index( x->parent->name y))))
		
		;pin_ls = setof( x append( top_pin_ls bottom_pin_ls) exists( y append( _0402_list _0201_list) ( y == x->parent->name)))
		; only if prop is nil or prop->DYN_THERMAL_CON_TYPE == "Full_contact" and x->parent->name is in symbol_name_list
		target_pin_ls = setof( x pin_ls ( x->prop == nil || x->prop->DYN_THERMAL_CON_TYPE == "Full_contact"))
		foreach( pin target_pin_ls
			unless( exists( x need_keepout_ls ( x == pin->parent))
				need_keepout_ls = append1( need_keepout_ls pin->parent)
			)
		)
		
		printf( "Total symbol count : %d\n" length( need_keepout_ls))
		
		time_start = getCurrentTime()
		foreach( item need_keepout_ls
			sprintf( layer "ROUTE KEEPOUT/%s" item->layer)
			keepout_ls = setof( x item->children ( x->objType == "shape" && x->layer == layer))
			; if there are 2 keepout in list means it has added keepout
			unless( length( keepout_ls) == 2
				CreateRectangle_createfullcontactrteko( item layer)
				created_ls = append1( created_ls item)
				_count++
			)
		)
		
		time_end = getCurrentTime()
		ProcessTime_createfullcontactrteko( "Create keepout" time_start time_end)
		printf( "Created keepout count : %d\n" _count)
		
		; Log
		WriteCreateLog_createfullcontactrteko( created_ls)
		
		; shape dynamic fill set to smooth
		axlDBControl( 'dynamicFillMode 'wysiwyg)
		; Enable on-line DRC
		axlDBControl( 'drcEnable t)
		
		if( axlUIYesNo( "Do you want to update to smooth and update DRCs?") then
			println( "Start updating to smooth")
			time_start = getCurrentTime()
			; update dynamic shapes
			axlDBDynamicShapes( t)
			time_end = getCurrentTime()
			println( "Finish updating to smooth")
			ProcessTime_createfullcontactrteko( "Update to smooth" time_start time_end)
		
			println( "Start updating DRCs")
			time_start = getCurrentTime()
			; update DRC
			axlShell( "drc update")
			time_end = getCurrentTime()
			println( "Finish updating DRCs")
			ProcessTime_createfullcontactrteko( "Update to smooth" time_start time_end)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CreateRectangle_createfullcontactrteko( symbol layer)
	prog( ( angle rectangle points path shape)
		points = GetSymbolKeepoutPoints_createfullcontactrteko( symbol)
		box = list( nth( 1 points) nth( 2 points))
		rectangle = axlDBCreateRectangle( box t layer nil symbol)
		
		angle = symbol->rotation
		when( angle
			axlTransformObject( rectangle ?angle angle)
		)
		
		return( rectangle)
	)
)

procedure( GetSymbolKeepoutPoints_createfullcontactrteko( symbol)
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

procedure( GetSymbolKeepoutRotatePoints_createfullcontactrteko( symbol)
	prog( (left_bot_pt right_top_pt)
		center_xy = symbol->xy
		points = GetSymbolKeepoutPoints_createfullcontactrteko( symbol)
		
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

procedure( ProcessTime_createfullcontactrteko( title time_start time_end)
	time_passed_seconds = compareTime( time_end time_start)
	tm = timeToTm( time_passed_seconds)
	printf( "%s process time : %d min %d sec\n" title tm->tm_min tm->tm_sec)
)

;;;;;;;;;;;;;;;;;;;;;;;;; Log

procedure( WriteCreateLog_createfullcontactrteko( created_ls)
	prog( (log_info out_port)
		log_info = SetUpLog_utilityprogram( "create_full_contact_route_keepout")
		unless( log_info
			return( nil)
		)
		
		out_port = nth( 0 log_info)
		_create_full_contact_route_keepout_logname = nth( 1 log_info)
		
		LogBasicInfo_createfullcontactrteko( out_port "To create ROUTE KEEPOUT for symbol 0402 & 0201." "Create ROUTE KEEPOUT between symbol's two pin.")
		fprintf( out_port "Created ROUTE KEEPOUT count %d\n" length( created_ls))
		when( dtpr(created_ls)
			format = "%-10s,%-15s,%-15s,%s\n"
			fprintf( out_port format "layer" "symbol" "refdes" "Location")
			foreach( item created_ls
				layer = sprintf( nil "[%s]" substring( item->layer 1 3))
				symbol = item->name
				refdes = item->refdes
				xy = sprintf( nil "%L" item->xy)
				fprintf( out_port format layer symbol refdes xy)
				axlHighlightObject( item)
			)
		)
		
		close( out_port)
		axlUIViewFileCreate( _create_full_contact_route_keepout_logname "Create full contact ROUTE KEEPOUT for 0402 & 0201 report" nil)
	)
)

procedure( LogBasicInfo_createfullcontactrteko( out_port introduction sub_introduction)
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

(axlCmdRegister "create_full_contact_rte_ko" 'Main_createfullcontactrteko)
/*
(encrypt "C:/skill/create_full_contact_rte_ko_v1d1.il" "C:/skill/create_full_contact_rte_ko_v1d1.ile")
(load "create_full_contact_rte_ko_v1d1.il")
(load "create_full_contact_rte_ko_v1d1.ile")
*/