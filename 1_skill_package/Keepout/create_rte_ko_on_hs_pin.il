/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/11/24                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To create Rte KO on each cline layer of connector symbol's pin         #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_rtekoonhspin()
	setq( _diffpair_ls GetNetsWithoutDuplicated_diffpairassociation())
	setq( _etch_subclass_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _check_rte_ko_on_hs_pin_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_rtekoonhspin()
	prog( ()
		unless( Main_locker()
			return( nil)
		)
		
		Init_rtekoonhspin()
		visible_ls = axlVisibleGet()
		SpeedUp_utilityprogram()
		result = CreateRteKO_rtekoonhspin()
		when( result
			axlUIConfirm( "Rte KO create complete!")
			UpdateDRC_utilityprogram()
		)
		
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CreateRteKO_rtekoonhspin()
	prog( ( msg sym_ls shape_width shape_height shape_prop_ls)
		msg = "Select symbol to create Rte KO on High Speed pin"
		axlUIConfirm( msg)
		sym_ls = SelectObjectByUser_utilityprogram( '(symbols) ?prompt msg)
		unless( dtpr( sym_ls)
			return( nil)
		)
		
		shape_width = axlUIPrompt( "Rte KO width ( one pin width )" "39.4")
		shape_height = axlUIPrompt( "Rte KO height ( two pin width )" "112")
		shape_width = atof( shape_width)
		shape_height = atof( shape_height)
		unless( and( shape_width shape_height)
			axlUIConfirm( "Input incorrect!")
			return( nil)
		)
		
		axlMeterCreate( "Create ROUTE KEEPOUT on HighSpeed pin Check Meter" "" t)
		meter_total = length( sym_ls)
		meter_count = 0
		one_section_percent = float( 100 * 1 / meter_total)
		current_percent = one_section_percent
		
		shape_prop_ls = list( list( "VIAS_ALLOWED" t) list( "PINS_ALLOWED" t))
		route_prop_ls = list( list( "ROUTES_ALLOWED" t) list( "PINS_ALLOWED" t))
		
		delete_routes_allowed = nil
		delete_vias_allowed = nil
		delete_pins_allowed = nil
		asked_result = nil
		
		foreach( sym_id sym_ls
			current_percent = current_percent + one_section_percent
			sprintf( msg "Creating %d / %d on %s" ++meter_count meter_total sym_id->refdes)
			axlMeterUpdate( current_percent msg)
			
			; delete ROUTE KEEPOUT Shapes with prop ROUTES_ALLOWED or VIAS_ALLOWED and PINS_ALLOWED
			SetFindFilter_utilityprogram( '(shapes))
			axlVisibleDesign( t)
			sym_box = axlDBGetExtents( sym_id->pins nil)
			axlAddSelectBox( sym_box)
			shape_ls = axlGetSelSet()
			axlClearSelSet()
			axlVisibleDesign( nil)
			shape_ls = setof( x shape_ls index( x->layer "ROUTE KEEPOUT/"))
			delete_shape_ls = nil
			route_shape_ls = setof( x shape_ls and( x->prop->ROUTES_ALLOWED x->prop->PINS_ALLOWED))
			when( and( dtpr( route_shape_ls) delete_routes_allowed == nil)
				result = axlUIYesNo( "Do you want to delete old ROUTE KEEPOUT with property \"ROUTES_ALLOWED\" & \"PINS_ALLOWED\"?")
				if( result
					delete_routes_allowed = 'delete
					delete_routes_allowed = 'no_delete
				)
			)
			
			when( delete_routes_allowed == 'delete
				delete_shape_ls = append( delete_shape_ls route_shape_ls)
			)
			
			other_shape_ls = setof( x shape_ls and( x->prop->VIAS_ALLOWED x->prop->PINS_ALLOWED))
			when( and( dtpr( other_shape_ls) delete_vias_allowed == nil)
				result = axlUIYesNo( "Do you want to delete old ROUTE KEEPOUT with property \"VIAS_ALLOWED\" & \"PINS_ALLOWED\"?")
				if( result
					delete_vias_allowed = 'delete
					delete_vias_allowed = 'no_delete
				)
			)
			
			when( delete_vias_allowed == 'delete
				delete_shape_ls = append( delete_shape_ls other_shape_ls)
			)
			
			when( dtpr( delete_shape_ls)
				axlDeleteObject( delete_shape_ls)
			)
			
			sym_layer_index = listnindex( _etch_subclass_ls sym_id->layer)
			diffpair_ls = GetDiffpairOnSymbol_rtekoonhspin( sym_id)
			
			foreach( diffpair_id diffpair_ls
				net_ls = diffpair_id->groupMembers
				net1_id = car( net_ls)
				net2_id = cadr( net_ls)
				pin1_id = car( setof( x sym_id->pins or( x->net->name == net1_id->name member( x->net->name net1_id->groupMembers~>name))))
				pin2_id = car( setof( x sym_id->pins or( x->net->name == net2_id->name member( x->net->name net2_id->groupMembers~>name))))
				pin_ls = list( pin1_id pin2_id)
				cline_ls = nil
				backdrill_data = nil
				foreach( pin_id pin_ls
					obj_ls = axlDBGetConnect( pin_id t)
					cline_id = car( setof( x obj_ls x->objType == "path"))
					cline_ls = append1( cline_ls cline_id)
					unless( backdrill_data
						backdrill_data = axlBackdrillGet( pin_id)
						when( backdrill_data
							backdrill_layer_index = listnindex( _etch_subclass_ls backdrill_data->topMustNotCutLayer)
							unless( backdrill_layer_index
								backdrill_layer_index = listnindex( _etch_subclass_ls backdrill_data->botMustNotCutLayer)
							)
						)
					)
				)
				
				target_layer = car( cline_ls)->layer
				target_subclass = cadr( parseString( target_layer "/"))
				layer_ls = list( strcat( "ROUTE KEEPOUT/" target_subclass))
				CreateShape_rtekoonhspin( pin_ls cline_ls layer_ls shape_width shape_height route_prop_ls)
				
				target_layer_index = listnindex( _etch_subclass_ls target_subclass)
				up_subclass = nth( target_layer_index - 1 _etch_subclass_ls)
				down_subclass = nth( target_layer_index + 1 _etch_subclass_ls)
				layer_ls = nil
				foreach( subclass remq( nil list( up_subclass down_subclass))
					layer_ls = append1( layer_ls strcat( "ROUTE KEEPOUT/" subclass))
				)
				
				CreateShape_rtekoonhspin( pin_ls cline_ls layer_ls shape_width shape_height shape_prop_ls t)
				
				layer_ls = nil
				if( sym_layer_index == 0 then
					start = sym_layer_index
					if( backdrill_layer_index
						end = backdrill_layer_index
						end = target_layer_index - 2
					)					
				else
					end = sym_layer_index
					if( backdrill_layer_index
						start = backdrill_layer_index
						start = target_layer_index + 2
					)
				)
				
				for( layer_index start end
					; to avoid routing layer, up layer, and down layer
					unless( member( layer_index list( (target_layer_index - 1) target_layer_index (target_layer_index + 1)))
						layer = strcat( "ROUTE KEEPOUT/" nth( layer_index _etch_subclass_ls))
						layer_ls = append1( layer_ls layer)
					)
				)
				
				CreateShape_rtekoonhspin( pin_ls cline_ls layer_ls shape_width shape_height shape_prop_ls)
			)
		)
		
		axlMeterDestroy()
		
		CheckRteKOOverlap_rtekoonhspin( sym_ls)
		return( t)
	)
)

procedure( GetDiffpairOnSymbol_rtekoonhspin( sym_id)
	prog( ( diffpair_ls)
		foreach( pin_id sym_id->pins
			diffpair_id = car( setof( x _diffpair_ls ( pin_id->net->diffpair->name == x->name)))
			when( diffpair_id
				diffpair_ls = append1( diffpair_ls diffpair_id)
			)
		)
		
		diffpair_ls = UniqueList_utilityprogram( diffpair_ls)
		return( diffpair_ls)
		;diffpair_id = car( setof( x _diffpair_ls x->name == "NODE2_I2C_0"))
		;setof( x diffpair_ls x->name == "SW1_NODE2_TO_NODE1_TX2_C")
		;setof( x sym_id->pins x->net->name == "SW1_NODE2_TO_NODE1_TX_DP2_C") "SW1_NODE2_TO_NODE1_TX_DP2" "SW1_NODE2_TO_NODE1_TX_DN2"
	)
)

procedure( CreateShape_rtekoonhspin( pin_ls cline_ls layer_ls width height @optional (prop_ls nil) (is_vcut nil))
	prog( ( center_xy radius circle_center_move rte_ko_poly)
		center_xy = axlMidPointLine( pin_ls~>xy)
		radius = width / 2
		circle_center_move = height / 2 - radius
		foreach( layer layer_ls
			circle_ls = nil
			delete_shape_ls = nil
			unless( rte_ko_poly->area
				; create circle by pin location
				foreach( xy pin_ls~>xy
					if( plusp( cadr( center_xy) - cadr( xy))
						center = axlMXYAdd( center_xy 0:-circle_center_move)
						center = axlMXYAdd( center_xy 0:circle_center_move)
					)
					
					shape_id = CreateShapeCircle_rtekoonhspin( center radius layer)
					circle_ls = append1( circle_ls shape_id)
				)
				; create rectangle
				left_down = axlMXYAdd( center_xy -radius:-circle_center_move)
				right_up = axlMXYAdd( center_xy radius:circle_center_move)
				box = list( left_down right_up)
				rect_shape_id = car( axlDBCreateRectangle( box t layer))
				delete_shape_ls = append1( circle_ls rect_shape_id)
				
				rect_poly = car( axlPolyFromDB( rect_shape_id))
				circle_poly_ls = nil
				foreach( circle circle_ls
					circle_poly_ls = append1( circle_poly_ls car( axlPolyFromDB( circle)))
				)
				
				; merge shapes
				rte_ko_poly = car( axlPolyOperation( rect_poly circle_poly_ls 'OR))
				
				route_direction = GetRouteDirection_rtekoonhspin( pin_ls~>xy car( cline_ls)->segments)
				
				; cut via by hole size
				SetFindFilter_utilityprogram( '(vias))
				axlVisibleDesign( nil)
				subclass = cadr( parseString( layer "/"))
				via_layer = strcat( "VIA CLASS/" subclass)
				axlVisibleLayer( via_layer t)
				axlAddSelectPoly( rte_ko_poly)
				via_ls = axlGetSelSet()
				axlClearSelSet()
				rte_ko_box = rte_ko_poly->bBox
				foreach( via_id via_ls
					diameter = via_id->definition->drillDiameter / 2
					left_down = axlMXYAdd( via_id->xy list( -diameter -diameter))
					right_up = axlMXYAdd( via_id->xy list( diameter diameter))
					case( route_direction
						( 'left
							when( car( cadr( rte_ko_box)) > car( right_up)
								right_up = list( car( cadr( rte_ko_box)) cadr( right_up))
							)
						)
						( 'right
							when( car( car( rte_ko_box)) < car( left_down)
								left_down = list( car( car( rte_ko_box)) cadr( left_down))
							)
						)
					)
					
					box = list( left_down right_up)
					via_shape_id = car( axlDBCreateRectangle( box t layer))
					delete_shape_ls = append1( delete_shape_ls via_shape_id)
					via_poly = car( axlPolyFromDB( via_shape_id))
					rte_ko_poly = car( axlPolyOperation( rte_ko_poly via_poly 'ANDNOT))
				)
				
				when( is_vcut
					v_cut_shape_id = CreateShapeTriangle_rtekoonhspin( pin_ls~>xy radius layer route_direction)
					delete_shape_ls = append1( delete_shape_ls v_cut_shape_id)
					v_cut_poly = car( axlPolyFromDB( v_cut_shape_id))
					rte_ko_poly = car( axlPolyOperation( rte_ko_poly v_cut_poly 'ANDNOT))
				)
			)
			
			rte_ko_shape_id = car( axlDBCreateShape( rte_ko_poly t layer))
			when( prop_ls
				foreach( prop prop_ls
					axlDBAddProp( rte_ko_shape_id prop)
				)
			)
			
			when( dtpr( delete_shape_ls)
				axlDeleteObject( delete_shape_ls)
			)
		)
	)
)

procedure( CreateShapeCircle_rtekoonhspin( center_xy radius layer)
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
		return( shape_id)
	)
)

procedure( CreateShapeTriangle_rtekoonhspin( pin_xy_ls radius layer route_direction)
	prog( ( center_xy top_point bot_point points path shape_id)
		center_xy = axlMidPointLine( pin_xy_ls)
		
		; for v cut direction, according to cline routing direction
		when( route_direction == 'left
			radius = -radius
		)
		
		top_point = axlMXYAdd( car( pin_xy_ls) radius:0)
		bot_point = axlMXYAdd( cadr( pin_xy_ls) radius:0)
		points = list( center_xy top_point bot_point center_xy)
		path = axlPathStart( points)
		shape_id = car( axlDBCreateShape( path t layer))
		return( shape_id)
	)
)

procedure( GetRouteDirection_rtekoonhspin( pin_xy_ls cline_seg_ls)
	prog( ( center_xy seg1 seg1_end seg2 seg2_end)
		center_xy = axlMidPointLine( pin_xy_ls)
		seg1 = car( setof( x cline_seg_ls or( member( car( x->startEnd) pin_xy_ls) member( cadr( x->startEnd) pin_xy_ls))))
		seg1_end = car( setof( x seg1->startEnd !member( x pin_xy_ls)))
		cline_seg_ls = remq( seg1 cline_seg_ls)
		seg2 = car( setof( x cline_seg_ls member( seg1_end x->startEnd)))
		seg2_end = car( setof( x seg2->startEnd x != seg1_end))
		if( plusp( car( center_xy) - car( seg2_end))
			return( 'left)
			return( 'right)
		)
	)
)

procedure( CheckRteKOOverlap_rtekoonhspin( sym_ls)
	prog( ( log_info out_port)
		log_info = SetUpLog_utilityprogram( "check_rte_ko_on_hs_pin")
		unless( log_info
			return( nil)
		)
		
		out_port = nth( 0 log_info)
		logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check ROUTE KEEPOUT shapes on highspeed pin has overlap\n")
		fprintf( out_port "\tShapes without property \"VIAS_ALLOWED\" and \"PINS_ALLOWED\" won't be automatically deleted.\n")
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Check ROUTE KEEPOUT overlap on highspeed pins\n")
		fprintf( out_port "\n")
		
		content_format = "%-10s,%s\n"
		SetFindFilter_utilityprogram( '(shapes))
		foreach( sym_id sym_ls
			fprintf( out_port "%-25s,%-20s,%L\n" sym_id->name sym_id->refdes sym_id->xy)
			fprintf( out_port content_format "Subclass" "shape location")
			has_overlap = nil
			pin_ls = setof( x sym_id->pins x->definition->plating != "NON_PLATED")
			;pin_ls = sym_id->pins
			sym_box = axlDBGetExtents( pin_ls nil)
			foreach( subclass _etch_subclass_ls
				axlVisibleDesign( nil)
				axlVisibleLayer( strcat( "ROUTE KEEPOUT/" subclass) t)
				axlAddSelectBox( sym_box)
				shape_ls = axlGetSelSet()
				axlClearSelSet()
				shape_ls = setof( x shape_ls x->nSegs > 1)
				shape_center_ls = mapcar( lambda( (x) axlMidPointLine( x->bBox)) shape_ls)
				duplicated_center_ls = ListDuplicated_utilityprogram( shape_center_ls)
				foreach( center duplicated_center_ls
					sprintf( location "%L" center)
					fprintf( out_port content_format subclass location)
					has_overlap = t
				)
			)
			
			unless( has_overlap
				fprintf( out_port "\tNone\n")
			)
			
			fprintf( out_port "\n")
		)
		
		close( out_port)
		axlUIViewFileCreate( logname "Check ROUTE KEEPOUT shapes on highspeed pin report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "rte_ko_on_hs_pin" 'Main_rtekoonhspin)
/*
(encrypt "c:/skill/rte_ko_on_hs_pin_v1d1.il" "c:/skill/rte_ko_on_hs_pin_v1d1.ile")
(load "rte_ko_on_hs_pin_v1d1.il")
(load "rte_ko_on_hs_pin_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup