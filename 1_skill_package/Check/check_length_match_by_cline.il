;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 07/07/2020 - _Derek07072020
; Description: Show up the equalism condition by each layer
; Data format:
;	header -> net_name, diffpair_name, total, trace
;	abstraction -> net_name, diffpair_name, total, layer|xy|pin_delay+length, [layer|xy|length, ...], layer|xy|pin_delay+length
;	data     ->  net1name                                  
;	data     ->  net2name                                  
;	data     ->  pass                                        , pass|5|<>                                         ,[pass...]
;
; Usage: see guidline

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek07072020()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	setq( _velocity get_velocity_Derek07072020())
	setq( _etch_subclass_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _etch_layer_ls mapcar( lambda( (x) sprintf( nil "ETCH/%s" x)) _etch_subclass_ls))
	
	setq( _mil_by_mm 39.37)
	setq( _default_diffpair_tolerance if( equal( "mils" _allegro_unit) 5.0 5.0 / _mil_by_mm))
	
	setq( _result_diffpair_entity_ls nil)
	setq( _bad_children_ls nil)
	
	setq( _min_pins_of_sym 4)
	
	setq( _pass "PASS")
	setq( _fail "FAIL")
	setq( _broken "BROKEN")
	setq( _stub "STUB")
	setq( _stub_tp "STUB_TP")
	setq( _dumped "DUMPED")
	setq( _shape "SHAPE")
	setq( _head_sym_pin "HEAD_SYM_PIN")
	setq( _tee "TEE")
	setq( _bad_children_order list( _shape _tee _head_sym_pin _stub_tp _stub _broken _dumped))
	
	setq( _diffp_phase_tol 'DIFFP_PHASE_TOL)
	setq( _ecset 'ELECTRICAL_CONSTRAINT_SET)
	setq( _diffpair_phase_tol 'Differential_Pair_Phase_Tolerance)
	setq( _pin_delay 'PIN_DELAY)
	
	;;;;;
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _log_filename "check_length_match_by_cline-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _check_length_match_by_cline_logname "%s/%s" _log_dir _log_filename)
	setq( _schematic_name get_schematic_name_Derek07072020())
)

procedure( get_velocity_Derek07072020()
	prog( ( velocity unit)
		sscanf( axlCNSGetPinDelayPVF() "%f %s" velocity unit)
		unless( equal( "m/s" unit) printf( "WARNING: get_velocity() - the unit od speed of pinDelayPVF is not in m/s:[%L]\n" unit))
		
		return( velocity)
	)
)

procedure( get_schematic_name_Derek07072020()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls and( (length( s->pins) > 1))))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_length_by_time_Derek07072020( time unit)
	prog( ( time_coefficient distance_coefficient distance)
		cond(
			( equal( upperCase( unit) "NS")
				time_coefficient = 10**9
			)
			( t
				printf( "ERROR: get_length_by_time() - Yet to define time unit[%L]\n" unit)
				time_coefficient = -1
			)
		)
		
		cond(
			( equal( _allegro_unit "millimeters")
				distance_coefficient = 10**3
			)
			( equal( _allegro_unit "mils")
				distance_coefficient = 10**3 * _mil_by_mm
			)
			( t
				printf( "ERROR: get_length_by_time() - Yet to define distance unit[%L]\n" _allegro_unit)
				distance_coefficient = -1
			)
		)
		
		distance = time * _velocity * distance_coefficient / time_coefficient
		
		
		return( distance)
	)
)

procedure( get_length_Derek07072020( net_ids)
	prog( ( seg_ls seg_length total)
		total = 0.0
		unless( dtpr( net_ids) (net_ids = list( net_ids)))
		foreach( net_id net_ids
			seg_ls = net_id->groupMembers
			unless( dtpr( seg_ls) (seg_ls = list( net_id)))
			
			foreach( seg_id seg_ls
				seg_length = axlDBGetLength( seg_id) || 0.0
				total += seg_length
			)
		)
		
		
		return( total)
	)
)

procedure( get_head_symbol_Derek07072020( net_id)
	prog( ( pin_ls sym_ls pin_id sym_id bad_children_ls)
		pin_ls = axlPinsOfNet( net_id 'pin)
		sym_ls = pin_ls~>parent
		sym_ls = sort( sym_ls lambda( (a b) ( length( a->pins) > length( b->pins))))
		sym_id = car( sym_ls)
		
		if( ( length( sym_id->pins) > _min_pins_of_sym) then
			return( sym_id)
		else
			pin_id = car( exists( a pin_ls exists( b sym_id->pins eq( a b))))
			bad_children_ls = list( _head_sym_pin list( pin_id))
			_bad_children_ls = append1( _bad_children_ls bad_children_ls)
			
			return( nil)
		)
	)
)

procedure( get_path_start_end_Derek07072020( path_id)
	; net_id = car( car( axlDBGetDesign()->diffpair)->groupMembers)
	; path_id = cadr( car( car( net_id->groupMembers)->branches)->children)
	; path_id = car( path_ls)
	prog( ( xy_ls duplicated_xy_ls start_end)
		unless( equal( "path" path_id->objType) printf( "ERROR: get_path_start_end() - arg is not a path:%L\n" path_id) return( nil))
		
		foreach( seg_id path_id->segments
			xy_ls = append( xy_ls seg_id->startEnd)
		)
		
		duplicated_xy_ls = maplist( lambda( (xys) if( exists( xy cdr( xys) axlGeoPointsEqual( car( xys) xy)) car( xys) nil)) xy_ls)
		duplicated_xy_ls = remq( nil duplicated_xy_ls)
		
		;;;;; if there is no element in duplicated_xy_ls, then xy_ls is a unique list
		unless( dtpr( duplicated_xy_ls) return( xy_ls))
		;printf( "dog2: %L %L\n" xy_ls duplicated_xy_ls)
		start_end = setof( xy xy_ls !exists( dxy duplicated_xy_ls axlGeoPointsEqual( xy dxy)))
		
		
		return( start_end)
	)
)

procedure( is_point_Derek07072020( xy)
	prog( ()
		return( and( eqv( 2 length( xy)) floatp( car( xy)) floatp( cadr( xy))))
	)
)

procedure( get_paths_with_pad_Derek07072020( path_ls pad_id)
	prog( ( end_2 path_with_pad_ls)
		unless( forall( x path_ls equal( "path" x->objType)) printf( "ERROR: get_paths_with_pad() - Path_ls is not a path list: %L\n" path_ls~>objType) return( nil))
		unless( or( equal( "pin" pad_id->objType) equal( "via" pad_id->objType))
			printf( "ERROR: get_paths_with_pad() - Pad[%L] is not pin or via" pad_id->objType) return( nil))
		
		pad_xy = pad_id->xy
		pad_start_end = pad_id->startEnd
		foreach( path_id path_ls
			end_2 = get_path_start_end_Derek07072020( path_id)
			when( and( exists( end end_2 axlGeoPointsEqual( pad_xy end)) is_layers_overlap_Derek07072020( path_id->layer pad_start_end))
				path_with_pad_ls = append1( path_with_pad_ls path_id)
			)
		)
		
		return( path_with_pad_ls)
	)
)

procedure( get_second_last_pad_Derek07072020( pin_id children)
	prog( ( path_ls path_id rest_pad_ls path_start_end second_last_pad_xy second_last_pad_id)
		unless( equal( "pin" pin_id->objType) printf( "ERROR: get_second_last_pad() - pin_id is not a pin: %L\n" pin_id->??) return( nil))
		unless( exists( x children equal( "path" x->objType)) printf( "ERROR: get_second_last_pad() - children have no path:%L\n" children~>objType) return( nil))
		
		rest_pad_ls = remq( pin_id get_objectives_Derek07072020( children "path" t))
		path_ls = get_objectives_Derek07072020( children "path")
		path_ls = get_paths_with_pad_Derek07072020( path_ls pin_id)
		if( dtpr( path_ls) then
			unless( onep( length( path_ls)) return( nil)) ;;;; this pin should be always the end of a trail
			path_id = car( path_ls)
			path_start_end = get_path_start_end_Derek07072020( path_id)
			second_last_pad_xy = if( axlGeoPointsEqual( pin_id->xy car( path_start_end)) cadr( path_start_end) car( path_start_end))
			second_last_pad_id = car( setof( x rest_pad_ls and( axlGeoPointsEqual( second_last_pad_xy x->xy)
															is_layers_overlap_Derek07072020( path_id->layer x->startEnd))))
			
		else
			second_last_pad_id = car( setof( x rest_pad_ls and( axlGeoIsBoxOverlap( pin_id->bBox x->bBox)
															is_layers_overlap_Derek07072020( pin_id->startEnd x->startEnd))))
		)
		
		
		return( second_last_pad_id)
	)
)

procedure( is_stub_pin_Derek07072020( pin_id children)
	; pin_id = car( axlGetSelSet())
	;;;; if a pin is on a branch of a net, then it's considered a stub
	;;;; if this pin is the only end of a net, then it should not be considered as stub
	prog( ( pin_2 path_ls)
		unless( equal( "pin" pin_id->objType) printf( "ERROR: is_stub_pin() - pin_id is not a pin") return( nil))
		unless( exists( x children equal( "path" x->objType)) printf( "ERROR: is_stub_pin() - children have no path") return( nil))
		
		;;;;; stub pin condition will only be happened in passive component
		pin_2 = pin_id->parent->pins
		unless( eqv( 2 length( pin_2)) return( nil))
		
		;;;;; it is legal if the net goes in and out from a same pin
		path_ls = get_objectives_Derek07072020( children "path")
		paths_with_xy = get_paths_with_pad_Derek07072020( path_ls pin_id)
		when( (length( paths_with_xy) > 1) return( nil))
		;printf( "   overrrrrrrr %L %L\n" get_paths_with_pad_Derek07072020( path_ls pin_id) eqv( 2 get_paths_with_pad_Derek07072020( path_ls pin_id)))
		
		;;;;; it is illegal if a net goes in and stop in R
		when( eq( car( pin_2)->net->diffpair cadr( pin_2)->net->diffpair) return( nil))
		
		;;;;; if the second last pin/via has single net in/out, then this pin_id is the end of the net
		second_last_pad_id = get_second_last_pad_Derek07072020( pin_id children)
		when( second_last_pad_id
			paths_with_xy = get_paths_with_pad_Derek07072020( path_ls second_last_pad_id)
			when( ( 2 >= length( paths_with_xy)) return( nil))
		)
		
		
		return( t)
	)
)

procedure( is_stub_testpoint_Derek07072020( pad_id path_ls)
	prog( ( path_with_testpoint_ls)
		;;; if no layer is set in the pad_id, it is no way to be a testpoint
		unless( stringp( pad_id->testPoint) return( nil))
		
		;;;;; if the testpoint is on pin, it should net be removed
		when( ( length( pad_id->parent->pins) > 1) return( nil))
		
		path_with_testpoint_ls = get_paths_with_pad_Derek07072020( path_ls pad_id)
		when( onep( length( path_with_testpoint_ls)) return( t))
		
		
		return( nil)
	)
)

procedure( is_stub_via_Derek07072020( via_id path_ls)
	prog( ( paths_with_xy)
		paths_with_xy = get_paths_with_pad_Derek07072020( path_ls via_id)
		return( onep( length( paths_with_xy)))
	)
)

procedure( get_stub_trace_Derek07072020( pad_id children)
	prog( ( last_xy via_ls path_ls paths_with_xy path_with_xy end_2 via_id stub_trace)
		path_ls = get_objectives_Derek07072020( children "path")
		paths_with_xy = get_paths_with_pad_Derek07072020( path_ls pad_id)
		
		unless( onep( length( paths_with_xy)) return( nil))
		
		last_xy = pad_id->xy
		path_with_xy = car( paths_with_xy)
		while( path_with_xy
			;; remove the path from children
			stub_trace = append1( stub_trace path_with_xy)
			children = remq( path_with_xy children)
			
			;; find a stub via with xy
			end_2 = get_path_start_end_Derek07072020( path_with_xy)
			last_xy = if( axlGeoPointsEqual( last_xy car( end_2)) cadr( end_2) car( end_2))
			via_ls = get_objectives_Derek07072020( children "via")
			path_ls = get_objectives_Derek07072020( children "path")
			via_id = car( setof( x via_ls and( axlGeoPointsEqual( last_xy x->xy)
												is_stub_via_Derek07072020( x path_ls))))
			
			;; update the path_with_xy, if there is any stub via exists
			path_with_xy = nil
			when( via_id
				stub_trace = append1( stub_trace via_id)
				children = remq( via_id children)
				
				last_xy = via_id->xy
				path_with_xy = car( get_paths_with_pad_Derek07072020( path_ls via_id))
			)
		)
		
		
		return( stub_trace)
	)
)

procedure( remove_stub_testpoint_Derek07072020( children)
	prog( ( path_ls stub_testpoint_ls stub_ls stub_trace_ls stub_path_ls bad_children_ls)
		path_ls = get_objectives_Derek07072020( children "path")
		
		stub_testpoint_ls = setof( x children is_stub_testpoint_Derek07072020( x path_ls))
		when( dtpr( stub_testpoint_ls)
			foreach( tp_id stub_testpoint_ls
				stub_ls = get_stub_trace_Derek07072020( tp_id children)
				when( dtpr( stub_ls)
					stub_trace_ls = append( stub_trace_ls append( list( tp_id) stub_ls))
				)
			)
			
			;;;;; remove element from children
			children = setof( x children !memq( x stub_trace_ls))
			
			;;;; store and output on log file later
			bad_children_ls = list( _stub_tp stub_trace_ls)
			_bad_children_ls = append1( _bad_children_ls bad_children_ls)
		)
		
		
		return( children)
	)
)

procedure( remove_stub_pin_Derek07072020( children)
	prog( ( path_ls stub_pin_ls stub_ls stub_trace_ls stub_path_ls bad_children_ls)
		pin_ls = get_objectives_Derek07072020( children "pin")
		foreach( pin_id pin_ls
			when( is_stub_pin_Derek07072020( pin_id children)
				stub_pin_ls = append1( stub_pin_ls pin_id)
				children = remq( pin_id children)
			)
		)
		when( dtpr( stub_pin_ls)
			foreach( pin_id stub_pin_ls
				stub_ls = get_stub_trace_Derek07072020( pin_id children)
				when( dtpr( stub_ls)
					children = setof( x children !memq( x stub_ls))
					stub_trace_ls = append( stub_trace_ls append( list( pin_id) stub_ls))
				)
			)
			
			;;;; store and output on log file later
			bad_children_ls = if( dtpr( stub_trace_ls) list( _stub stub_trace_ls) list( _stub stub_pin_ls))
			_bad_children_ls = append1( _bad_children_ls bad_children_ls)
		)
		
		
		return( children)
	)
)

procedure( remove_exists_Derek07072020( children obj_type bad_children_key)
	prog( ( obj_ls bad_children_ls)
		obj_ls = get_objectives_Derek07072020( children obj_type)
		
		when( dtpr( obj_ls)
			bad_children_ls = list( bad_children_key obj_ls)
			_bad_children_ls = append1( _bad_children_ls bad_children_ls)
			
			return( nil)
		)
		
		
		return( children)
	)
)

procedure( get_children_from_net_Derek07072020( net_id)
	; net_id = car( axlGetSelSet())
	; net_id = net_id->xnet
	prog( ( seg_ls branch children)
		seg_ls = net_id->groupMembers
		unless( dtpr( seg_ls) (seg_ls = list( net_id)))
		
		unless( forall( seg_id seg_ls onep( seg_id->nBranches))
			printf( "WARNING: get_children_from_net() - more than a branch in this net: %L: %L\n" net_id->name seg_ls~>nBranches)
			return( nil)
		)
		
		foreach( seg_id seg_ls
			branch = car( seg_id->branches)
			children = append( children branch->children)
		)
		
		;;;; remove the net if the shape exists -----------------------------------------------------------------------------------------------------------------------------
		children = remove_exists_Derek07072020( children "shape" _shape)
		unless( exists( x children equal( "path" x->objType)) return( nil))
		
		;;;; remove the net if the tee is exists ------------------------------------------------------------------------------------------------------------------------------
		children = remove_exists_Derek07072020( children "tee" _tee)
		unless( exists( x children equal( "path" x->objType)) return( nil))
		
		;;;; remove testpoint and its trail ------------------------------------------------------------------------------------------------------------------------------------
		children = remove_stub_testpoint_Derek07072020( children)
		unless( exists( x children equal( "path" x->objType)) return( nil))
		
		;;;; remove stub and its trail ------------------------------------------------------------------------------------------------------------------------------------------
		children = remove_stub_pin_Derek07072020( children)
		unless( exists( x children equal( "path" x->objType)) return( nil))
		
		;;;; remove the testpoint directly if it is not in through type. remove hereby so that escape path connect path condition
		;children = setof( x children !and( equal( "via" x->objType) stringp( x->testPoint) equal( car( x->startEnd) cadr( x->startEnd))))
		
		
		return( children)
	)
)

procedure( is_layers_overlap_Derek07072020( start_end_layer1 start_end_layer2)
	prog( ( start1_th end1_th start2_th end2_th)
		when( stringp( start_end_layer1) (start_end_layer1 = list( start_end_layer1 start_end_layer1)))
		start1_th = listnindex( _etch_layer_ls car( start_end_layer1))
		end1_th = listnindex( _etch_layer_ls cadr( start_end_layer1))
		start2_th = listnindex( _etch_layer_ls car( start_end_layer2))
		end2_th = listnindex( _etch_layer_ls cadr( start_end_layer2))
		
		unless( and( start1_th end1_th start2_th end2_th) return( nil))
		
		return( or( axlIsBetween( start1_th start2_th end2_th) axlIsBetween( start2_th start1_th end1_th)
					axlIsBetween( end1_th start2_th end2_th) axlIsBetween( end2_th start1_th end1_th)))
	)
)

procedure( is_obj_Derek07072020( obj_ids obj_type)
	prog( ()
		if( dtpr( obj_ids) then
			return( forall( x obj_ids equal( obj_type x->objType)))
		else
			return( equal( obj_type obj_ids->objType))
		)
	)
)

procedure( get_objectives_Derek07072020( children obj_type @optional (none nil))
	prog( ( obj_ls)
		foreach( child children
			when( eq( is_obj_Derek07072020( child obj_type) !none)
				obj_ls = append1( obj_ls child)
			)
		)
		;return( setof( x children eq( equal( obj_type x->objType) !none)))
		
		return( obj_ls)
	)
)

procedure( get_head_pin_Derek07072020( children head_sym_id)
	prog( ( head_pin_ls path_ls head_pin_id)
		head_pin_ls = setof( x children eq( head_sym_id x->parent))
		
		;;; if a net connects 2 pins under the head symbol, then find the pin with less cline
		path_ls = get_objectives_Derek07072020( children "path")
		head_pin_ls = sort( head_pin_ls lambda( (a b)
							( length( get_paths_with_pad_Derek07072020( path_ls a)) < length( get_paths_with_pad_Derek07072020( path_ls b)))))
		
		head_pin_id = car( head_pin_ls)
		
		
		return( head_pin_id)
	)
)

procedure( get_trace_Derek07072020( head_sym_id net_id)
	; a = car( axlGetSelSet())
	prog( ( head_pin_id children obj_id last_id path_ls pad_ls end_2 trace_child_ls bad_children_ls)
		unless( and( head_sym_id net_id) return( nil))
		
		children = get_children_from_net_Derek07072020( net_id)
		unless( dtpr( children) return( nil))
		
		head_pin_id = get_head_pin_Derek07072020( children head_sym_id)
		unless( head_pin_id return( nil))
		
		trace_child_ls = list( head_pin_id)
		children = remq( head_pin_id children)
		last_xy = head_pin_id->xy
		while( dtpr( children)
			obj_id = nil
			last_id = lastelem( trace_child_ls)
			
			case( last_id->objType
				( "pin"
					;;;; from pin to net condition
					path_ls = get_objectives_Derek07072020( children "path")
					obj_id = car( get_paths_with_pad_Derek07072020( path_ls last_id))
					
					unless( obj_id
						;;;; go through R(2 pin symbol)
						obj_id = car( setof( x children eq( last_id->parent x->parent)))
					)
					
					;printf( "pin finds path: %L\n" obj_id)
					;;;;if no connected path is found, then check via-via/pin stack condition
					unless( obj_id
						pad_ls = get_objectives_Derek07072020( children "path" t)
						obj_id = car( setof( x pad_ls and( axlGeoIsBoxOverlap( x->bBox last_id->bBox)
													is_layers_overlap_Derek07072020( x->startEnd last_id->startEnd))))
						;printf( "pin find pin/via: %L %L\n" obj_id last_id->xy)
					)
				)
				( "path"
					pad_ls = get_objectives_Derek07072020( children "path" t)
					end_2 = get_path_start_end_Derek07072020( last_id)
					;printf( "mid: %L\n" end_2)
					this_xy = if( axlGeoPointsEqual( last_xy car( end_2)) cadr( end_2) car( end_2))
					;printf( "last: %L\n" last_xy)
					;printf( "mid: %L\n" this_xy)
					obj_id = car( setof( x pad_ls and( axlGeoPointsEqual( this_xy x->xy)
													is_layers_overlap_Derek07072020( last_id->layer x->startEnd))))
					;printf( "path finds pad: %L\n" obj_id)
				)
				( "via"
					path_ls = get_objectives_Derek07072020( children "path")
					path_ls = setof( x path_ls is_layers_overlap_Derek07072020( x->layer last_id->startEnd))
					
					;;;; simply get the first one. if more than one branches found, this net will be regarded as BROKEN
					obj_id = car( get_paths_with_pad_Derek07072020( path_ls last_id))
					
					;;;;if no connected path is found, then check via-via/pin stack condition
					unless( obj_id
						pad_ls = get_objectives_Derek07072020( children "path" t)
						obj_id = car( setof( x pad_ls and( axlGeoIsBoxOverlap( x->bBox last_id->bBox)
													is_layers_overlap_Derek07072020( x->startEnd last_id->startEnd))))
						;printf( "via find via: %L %L\n" obj_id last_id->xy)
					)
				)
				( t
					printf( "ERROR: get_trace() - Fail to define net[%s] child: %L in %L\n" net_id->name last_id->?? children~>objType)
				)
			)
			
			if( obj_id then
				trace_child_ls = append1( trace_child_ls obj_id)
				children = remq( obj_id children)
				when( dtpr( obj_id->xy) (last_xy = obj_id->xy))
				;printf( "obj_id: %L\n" obj_id->??)
			else
				bad_children_ls = list( _broken children)
				_bad_children_ls = append1( _bad_children_ls bad_children_ls)
				children = trace_child_ls = nil
			)
			;printf( "children:%L %L\n\n" children~>objType children~>xy)
		)
		;printf( "trace_child_ls: %L %L\n" trace_child_ls~>objType trace_child_ls~>xy)
		
		
		return( trace_child_ls)
	)
)

procedure( get_diffpair_entity_Derek07072020( diffpair_id)
	; abstraction -> net_name, diffpair_name, total, layer|xy|pin_delay+length, [layer|xy|length, ...], layer|xy|pin_delay+length
	; net_id = car( car( axlDBGetDesign()->diffpair)->groupMembers)
	; net1_id = car( car( axlDBGetDesign()->diffpair)->groupMembers)
	; diffpair_id = cadr( axlDBGetDesign()->diffpair)
	prog( ( net_2 net1_id net2_id net1_trace net2_trace head_sym1_id head_sym2_id diffpair_entity)
		net_2 = diffpair_id->groupMembers
		net1_id = car( net_2)
		net2_id = cadr( net_2)
		
		;;;; if one of the head symbol can't be found, then another one should be the same
		head_sym1_id = get_head_symbol_Derek07072020( net1_id)
		head_sym2_id = get_head_symbol_Derek07072020( net2_id)
		
		net1_trace = get_trace_Derek07072020( head_sym1_id net1_id)
		net2_trace = get_trace_Derek07072020( head_sym2_id net2_id)
		
		cond(
			( and( dtpr( net1_trace) dtpr( net2_trace))
				diffpair_entity = list( diffpair_id net1_trace net2_trace)
			)
			( dtpr( net1_trace)
				bad_children_ls = list( _dumped net1_trace)
				_bad_children_ls = append1( _bad_children_ls bad_children_ls)
			)
			( dtpr( net2_trace)
				bad_children_ls = list( _dumped net2_trace)
				_bad_children_ls = append1( _bad_children_ls bad_children_ls)
			)
			( t
				;; both of net1 and net2 have been wiped out from the previous stage
			)
		)
		
		return( diffpair_entity)
	)
)

procedure( get_pin_delay_Derek07072020( pin_id)
	; get_pin_delay_Derek07072020( car( axlGetSelSet()))
	; pin_id = car( axlGetSelSet())
	prog( ( pin_props pin_delay unit value)
		pin_props = axlDBGetProperties( pin_id)
		pin_delay = cadr( assq( _pin_delay pin_props))
		pin_delay = get_length_by_unit_Derek07072020( pin_delay 0.0)
		
		
		return( pin_delay)
	)
)

procedure( get_length_by_unit_Derek07072020( value_unit @optional (default_value 0.0))
	prog( ( distance value unit)
		unless( stringp( value_unit) return( default_value))
		
		sscanf( value_unit "%f %s" value unit)
		cond(
			( exists( x list( "millimeters" "mils") equal( unit x))
				distance = value
			)
			( equal( "NS" upperCase( unit))
				distance = get_length_by_time_Derek07072020( value unit)
			)
			( t
				distance = default_value
			)
		)
		
		
		return( distance)
	)
)

procedure( get_diffpair_tolerance_Derek07072020( diffpair_id)
	; diffpair_id = car( axlDBGetDesign()->diffpair)
	; diffpair_id = car( axlGetSelSet())->net->diffpair
	prog( ( tolerance value unit)
		diffpair_props = axlDBGetProperties( diffpair_id)
		tolerance = cadr( assq( _diffp_phase_tol diffpair_props))
		ecset = cadr( assq( _ecset diffpair_props))
		cond(
			( tolerance
				tolerance = get_length_by_unit_Derek07072020( tolerance _default_diffpair_tolerance)
			)
			( ecset
				tolerance = cadr( assq( _diffpair_phase_tol axlCNSEcsetGet( ecset)->members))
				tolerance = get_length_by_unit_Derek07072020( tolerance _default_diffpair_tolerance)
			)
			( t
				tolerance = _default_diffpair_tolerance
			)
		)
		
		
		return( tolerance)
	)
)

procedure( get_tolerance_form_Derek07072020( tolerance length1 length2)
	prog( ( distinctive distinctive_abs result result_form)
		distinctive = length1 - length2
		distinctive_abs = abs( distinctive)
		result = !(distinctive_abs > tolerance)
		result_form = list( result tolerance distinctive)
		
		
		return( result_form)
	)
)

procedure( get_cline_form_Derek07072020( xy cline_ids @key (start_pin_delay nil) (end_pin_delay nil))
	;  layer|xy|pin_delay+length, [layer|xy|length, ...], layer|xy|pin_delay+length
	prog( ( layer subclass cline_length cline_form)
		unless( cline_ids printf( "ERROR: get_cline_form() - Fail to get cline_ids with xy %L\n" xy) return( nil))
		unless( is_obj_Derek07072020( cline_ids "path")
			printf( "ERROR: get_cline_form() - cline_ids is not a path: %L\n" cline_ids~>objType || cline_ids->objType)
			return( nil)
		)
		
		layer = if( dtpr( cline_ids) car( cline_ids)->layer cline_ids->layer)
		subclass = cadr( parseString( layer "/"))
		cline_length = get_length_Derek07072020( cline_ids)
		
		cond(
			( and( numberp( start_pin_delay) numberp( end_pin_delay))
				sprintf( cline_form "%s|(%.2f %.2f)|%.2f+%.2f+%.2f" subclass car( xy) cadr( xy) start_pin_delay cline_length end_pin_delay)
			)
			( numberp( start_pin_delay)
				sprintf( cline_form "%s|(%.2f %.2f)|%.2f+%.2f" subclass car( xy) cadr( xy) start_pin_delay cline_length)
			)
			( numberp( end_pin_delay)
				sprintf( cline_form "%s|(%.2f %.2f)|%.2f+%.2f" subclass car( xy) cadr( xy) cline_length end_pin_delay)
			)
			( t
				sprintf( cline_form "%s|(%.2f %.2f)|%.2f" subclass car( xy) cadr( xy) cline_length)
			)
		)
		
		
		return( cline_form)
	)
)

procedure( get_net_entity_Derek07072020( net_trace net_length start_pin_delay end_pin_delay)
	;	abstraction -> net_name, diffpair_name, total, layer|xy|pin_delay+length, [layer|xy|length, ...], layer|xy|pin_delay+length
	prog( ( net_name diffpair_name total start_cline_form end_cline_form cline_form net_cline_form_ls net_entity)
		net_name = car( net_trace)->net->name
		diffpair_name = car( net_trace)->net->diffpair->name
		
		net_trace = get_objs_without_nonthru_tp_Derek07072020( net_trace nil)
		path_cnt = length( get_objectives_Derek07072020( net_trace "path"))
		
		cond(
			( onep( path_cnt)
				;;;;; this is a special case, it's composed by pin-cline-pin
				;printf( "ideal %L\n%L\n%L\n" net_trace~>objType net_trace~>xy net_trace~>bBox)
				first_id = car( net_trace)
				while( !is_obj_Derek07072020( car( net_trace) "path") (net_trace = cdr( net_trace)))
				first_path_id = car( net_trace)
				
				start_cline_form = get_cline_form_Derek07072020( first_id->xy first_path_id ?start_pin_delay start_pin_delay ?end_pin_delay end_pin_delay)
				net_cline_form_ls = list( start_cline_form)
			)
			( ( path_cnt > 1)
				;printf( "ideal %L\n%L\n%L\n" net_trace~>objType net_trace~>xy net_trace~>bBox)
				;;;;; pop the first pin and its connected trace
				first_id = car( net_trace)
				while( !is_obj_Derek07072020( car( net_trace) "path") (net_trace = cdr( net_trace)))
				first_path_id = car( net_trace)
				
				start_cline_form = get_cline_form_Derek07072020( first_id->xy first_path_id ?start_pin_delay start_pin_delay)
				net_trace = cdr( net_trace)
				
				;;;;; pop the last pin and its connected trace
				r_net_trace = reverse( net_trace)
				first_id = car( r_net_trace)
				while( !is_obj_Derek07072020( car( r_net_trace) "path") (r_net_trace = cdr( r_net_trace)))
				first_path_id = car( r_net_trace)
				
				end_cline_form = get_cline_form_Derek07072020( first_id->xy first_path_id ?end_pin_delay end_pin_delay)
				r_net_trace = cdr( r_net_trace)
				net_trace = reverse( r_net_trace)
				
				net_cline_form_ls = list( start_cline_form)
				while( dtpr( net_trace)
					first_id = car( net_trace)
					if( is_obj_Derek07072020( first_id "path") then
						cline_form = get_cline_form_Derek07072020( first_xy first_id)
						net_cline_form_ls = append1( net_cline_form_ls cline_form)
					else
						first_xy = first_id->xy
					)
					net_trace = cdr( net_trace)
				)
				net_cline_form_ls = append1( net_cline_form_ls end_cline_form)
			)
			( t
				printf( "WARNING: get_net_entity() - net[%s] has no path been found. it wouldn't be compared\n" net_name)
			)
		)
		;;;;;
		when( dtpr( net_cline_form_ls)
			net_entity = list( net_name diffpair_name net_length net_cline_form_ls)
		)
		
		
		return( net_entity)
	)
)


procedure( get_result_Derek07072020( result)
	prog( ()
		return( if( result _pass _fail))
	)
)

procedure( get_result_form_Derek07072020( result_data_3)
	prog( ( result tolerance distinctive result_form)
		result = get_result_Derek07072020( car( result_data_3))
		sprintf( tolerance "%.2f" cadr( result_data_3))
		sprintf( distinctive "%.2f" caddr( result_data_3))
		
		sprintf( result_form "%s|%s|%s" result tolerance distinctive)
		
		
		return( result_form)
	)
)

procedure( get_cline_length_Derek07072020( th total cline_ids start_pin_delay end_pin_delay)
	prog( ( cline_length)
		;;;; when a non-through testpoint via is on a net. adjacent cline will become a list
		cline_length = get_length_Derek07072020( cline_ids)
		
		cond(
			( onep( total)
				cline_length += start_pin_delay + end_pin_delay
			)
			( onep( th)
				cline_length += start_pin_delay
			)
			( eqv( th total)
				cline_length += end_pin_delay
			)
		)
		
		
		return( cline_length)
	)
)

procedure( get_objs_without_nonthru_tp_Derek07072020( net_trace no_pad)
	prog( ( cline_ls obj1 obj2 obj3 clines)
		while( dtpr( net_trace)
			obj1 = car( net_trace)
			if( equal( "path" obj1->objType) then
				obj2 = cadr( net_trace)
				obj3 = caddr( net_trace)
				if( and( equal( "via" obj2->objType) stringp( obj2->testPoint) forall( x obj2->startEnd equal( obj2->testPoint x))
						equal( "path" obj3->objType)) then
					clines = list( obj1 obj3)
					net_trace = cdddr( net_trace)
				else
					clines = obj1
					net_trace = cdr( net_trace)
				)
				
				cline_ls = append1( cline_ls clines)
			else
				unless( no_pad (cline_ls = append1( cline_ls obj1)))
				net_trace = cdr( net_trace)
			)
		)
		
		
		return( cline_ls)
	)
)

procedure( get_result_diffpair_entity_Derek07072020( diffpair_entity)
	;;; input: diffpair (net1trace) (net2trace)
	;;; output: (result trace_result) diffpair_name (net1name length trace_without_pad) (net2name length trace_without_pad)
	;	header -> net_name, diffpair_name, total, trace
	;	abstraction -> net_name, diffpair_name, total, layer|xy|pin_delay+length, [layer|xy|length, ...], layer|xy|pin_delay+length
	;	data     ->  net1name                                  
	;	data     ->  net2name                                  
	;	data     ->  pass                                        , pass|5|<>                                         ,[pass...]
	prog( ( diffpair_id net1_trace net2_trace net1_start_pin_delay net1_end_pin_delay net1_length
			net2_start_pin_delay net2_end_pin_delay net2_length tolerance total_result obj1_length obj2_length
			trace_result trace_result_ls final_result net1_entity net2_entity result result_diffpair_entity)
		unless( dtpr( diffpair_entity) return( nil))
		;printf( "apple %L\n" diffpair_entity)
		
		diffpair_id = car( diffpair_entity)
		net1_trace = cadr( diffpair_entity)
		net2_trace = caddr( diffpair_entity)
		
		first_pin_id = car( net1_trace)
		net1_start_pin_delay = get_pin_delay_Derek07072020( first_pin_id)
		net1_end_pin_delay = get_pin_delay_Derek07072020( lastelem( net1_trace))
		net1_length = get_length_Derek07072020( first_pin_id->net->xnet) + net1_start_pin_delay + net1_end_pin_delay
		
		first_pin_id = car( net2_trace)
		net2_start_pin_delay = get_pin_delay_Derek07072020( first_pin_id)
		net2_end_pin_delay = get_pin_delay_Derek07072020( lastelem( net2_trace))
		net2_length = get_length_Derek07072020( first_pin_id->net->xnet) + net2_start_pin_delay + net2_end_pin_delay
		
		;;;;; get total 
		tolerance = get_diffpair_tolerance_Derek07072020( diffpair_id)
		total_result = get_tolerance_form_Derek07072020( tolerance net1_length net2_length)
		
		cline1_ls = get_objs_without_nonthru_tp_Derek07072020( net1_trace t)
		cline2_ls = get_objs_without_nonthru_tp_Derek07072020( net2_trace t)
		
		total = if( length( cline1_ls) < length( cline2_ls) length( cline1_ls) length( cline2_ls))
		th = 0
		foreach( (cline1_ids cline2_ids) cline1_ls cline2_ls
			++th
			cline1_length = get_cline_length_Derek07072020( th total cline1_ids net1_start_pin_delay net1_end_pin_delay)
			cline2_length = get_cline_length_Derek07072020( th total cline2_ids net2_start_pin_delay net2_end_pin_delay)
			;printf( "length: %L %L\n" cline1_length cline2_length)
			
			trace_result = get_tolerance_form_Derek07072020( _default_diffpair_tolerance cline1_length cline2_length)
			;unless( car( trace_result) printf( "%s %n %n %L %f %f\n" diffpair_id->name th total trace_result cline1_length cline2_length))
			
			trace_result_ls = append1( trace_result_ls trace_result)
		)
		
		;;;;;
		final_result = and( car( total_result) forall( x trace_result_ls car( x)))
		final_result = get_result_Derek07072020( final_result)
		total_result = get_result_form_Derek07072020( total_result)
		trace_result_ls = mapcar( 'get_result_form_Derek07072020 trace_result_ls)
		result = list( final_result diffpair_id->name total_result trace_result_ls)
		;printf( "result: %L\n" result)
		
		;;;;;
		net1_entity = get_net_entity_Derek07072020( net1_trace net1_length net1_start_pin_delay net1_end_pin_delay)
		net2_entity = get_net_entity_Derek07072020( net2_trace net2_length net2_start_pin_delay net2_end_pin_delay)
		
		result_diffpair_entity = list( result net1_entity net2_entity)
		
		
		return( result_diffpair_entity)
	)
)

procedure( get_trace_form_Derek07072020( net_trace)
	prog( ()
		unless( forall( x net_trace stringp( x)) printf( "ERROR: get_trace_form() - net_trace is not a string list: %L\n" net_trace) return( nil))
		;;
		
		net_trace = mapcar( lambda( (x) sprintf( nil "%-45s" x)) net_trace)
		net_trace = buildString( net_trace ",")
		
		
		return( net_trace)
	)
)

procedure( write_log_Derek07072020()
	prog( ( out_port)
		out_port = outfile( _check_length_match_by_cline_logname "w")
		unless( outportp( out_port) println( "ERROR: write_log() - Fail to write log") return( nil))
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: For differential pair, compare the cline length. Likewise, the pin delay will be included on the head and the tail of the (x)net\n")
		fprintf( out_port "\tThe default tolerance is %.2f%s, otherwise, the value is in electrical constraint>differential pair>static phase>tolerance\n" _default_diffpair_tolerance _allegro_unit)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=====================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Summary:\n")
		fprintf( out_port "\tException:\n")
		fprintf( out_port "\t\t%-20s:%5n\n" _shape length( setof( x _bad_children_ls equal( _shape car( x)))))
		fprintf( out_port "\t\t%-20s:%5n\n" _tee length( setof( x _bad_children_ls equal( _tee car( x)))))
		fprintf( out_port "\t\t%-20s:%5n\n" _head_sym_pin length( setof( x _bad_children_ls equal( _head_sym_pin car( x)))))
		fprintf( out_port "\t\t%-20s:%5n\n" _stub_tp length( setof( x _bad_children_ls equal( _stub_tp car( x)))))
		fprintf( out_port "\t\t%-20s:%5n\n" _stub length( setof( x _bad_children_ls equal( _stub car( x)))))
		fprintf( out_port "\t\t%-20s:%5n\n" _broken length( setof( x _bad_children_ls equal( _broken car( x)))))
		fprintf( out_port "\t\t%-20s:%5n\n" _dumped length( setof( x _bad_children_ls equal( _dumped car( x)))))
		fprintf( out_port "\tStatus:\n")
		fprintf( out_port "\t\t%-20s:%5n\n" "Total diffpair" length( axlDBGetDesign()->diffpair))
		fprintf( out_port "\t\t%-20s:%5n\n" "Checked diffpair" length( _result_diffpair_entity_ls))
		fprintf( out_port "\t\t%-20s:%5n\n" "Unchecked diffpair" length( axlDBGetDesign()->diffpair) - length( _result_diffpair_entity_ls))
		fprintf( out_port "\n")
		fprintf( out_port "\t\t%-20s:%5n\n" "Total Pass" length( setof( x _result_diffpair_entity_ls index( caddar( x) _pass))))
		fprintf( out_port "\t\t%-20s:%5n\n" "Total Fail" length( setof( x _result_diffpair_entity_ls index( caddar( x) _fail))))
		fprintf( out_port "\n")
		fprintf( out_port "\t\t%-20s:%5n\n" "Final Pass" length( setof( x _result_diffpair_entity_ls equal( _pass caar( x)))))
		fprintf( out_port "\t\t%-20s:%5n\n" "Final Fail" length( setof( x _result_diffpair_entity_ls equal( _fail caar( x)))))
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=====================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "To eliminate pin/via/net because it is a stub or fail to compose to the trace\n")
		fprintf( out_port "\t*%s: Shape should not be exists while comparing net length\n" _shape)
		fprintf( out_port "\t*%s: Tee should not be exists while comparing net length\n" _tee)
		fprintf( out_port "\t*%s: The pin cound of head symbol should be greater than [%n]\n" _head_sym_pin _min_pins_of_sym)
		fprintf( out_port "\t*%s: the stub testpoint and its trail will be remove from net\n" _stub_tp)
		fprintf( out_port "\t*%s: the tail will be removed from the net\n" _stub)
		fprintf( out_port "\t*%s: Fail to compose the trace. ex: pin-path-pin\n" _broken)
		fprintf( out_port "\t*%s: While the paired net is %s, itself will also be dumped\n" _dumped _broken)
		
		fprintf( out_port "\n\n")
		
		foreach( result_children _bad_children_ls
			children = cadr( result_children)
			pad_id = car( get_objectives_Derek07072020( children "path" t))
			net_name = pad_id->net->name
			fprintf( out_port "%-15s: [%s] %s -\n\t\t" car( result_children) pad_id->net->diffpair->name pad_id->net->name)
			foreach( child children
				cond(
					( stringp( child->testPoint)
						subclass = cadr( parseString( child->testPoint "/"))
						fprintf( out_port "TP[%s]: %L " subclass child->xy)
					)
					( equal( "pin" child->objType)
						subclass = cadr( parseString( car( child->startEnd) "/"))
						fprintf( out_port "Pin[%s]: %L " subclass child->xy)
					)
					( equal( "via" child->objType)
						fprintf( out_port "Via:%L " child->xy)
					)
					( equal( "path" child->objType)
						subclass = cadr( parseString( child->layer "/"))
						fprintf( out_port "Path[%s]:%L " subclass get_path_start_end_Derek07072020( child))
					)
					( equal( "shape" child->objType)
						subclass = cadr( parseString( child->layer "/"))
						fprintf( out_port "Shape[%s]: %L " subclass axlMidPointLine( child->bBox))
					)
					( equal( "symbol" child->objType)
						;; child hereby is a pin
						subclass = cadr( parseString( child->parent->layer "/"))
						fprintf( out_port "Symbol[%s]: %L " subclass child->parent->xy)
					)
					( equal( "tee" child->objType)
						subclass = cadr( parseString( child->layer "/"))
						fprintf( out_port "Tee[%s]: %L " subclass child->xy)
					)
				)
			)
			fprintf( out_port "\n")
		)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=====================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Format of TRACE:\n")
		fprintf( out_port "\tResult:\n")
		fprintf( out_port "\t\tGeneral: <status>|<maximum tolerance>|<difference>\n")
		fprintf( out_port "\tNet:\n")
		fprintf( out_port "\t\tStart of net: <starting layer>|<pin xy>|<start pin delay>+<cline length>\n")
		fprintf( out_port "\t\tMiddle of net: <starting layer>|<pin xy>|<cline length>\n")
		fprintf( out_port "\t\tEnd of net: <end layer>|<pin xy>|<cline length>+<end pin delay>\n")
		fprintf( out_port "\t\t2pins & 1cline of net: <end layer>|<pin xy>|<start pin delay>+<cline length>+<end pin delay>\n")
		
		fprintf( out_port "\n\n")
		
		;	header -> net_name, diffpair_name, total, trace
	;	abstraction -> net_name, diffpair_name, total, layer|xy|pin_delay+length, [layer|xy|length, ...], layer|xy|pin_delay+length
		format = "%-8s,%-32s,%-30s,%-18s,%s\n"
		fprintf( out_port format "STATUS" "NET" "DIFFPAIR" "TOTAL" "TRACE")
		foreach( result_diffpair_entity _result_diffpair_entity_ls
			diffpair_result = car( result_diffpair_entity)
			net1_entity = cadr( result_diffpair_entity)
			net2_entity = caddr( result_diffpair_entity)
			;printf( "banana: %L\n" result_diffpair_entity)
			
			;;;; output result
			net_trace = get_trace_form_Derek07072020( cadddr( diffpair_result))
			when( stringp( net_trace)
				fprintf( out_port format car( diffpair_result) "" cadr( diffpair_result) caddr( diffpair_result) net_trace)
			)
			
			;;;; output diffpair 1
			sprintf( total "%.2f" caddr( net1_entity))
			net_trace = get_trace_form_Derek07072020( cadddr( net1_entity))
			when( stringp( net_trace)
				fprintf( out_port format "" car( net1_entity) cadr( net1_entity) total net_trace)
			)
			
			;;;; output diffpair 2
			sprintf( total "%.2f" caddr( net2_entity))
			net_trace = get_trace_form_Derek07072020( cadddr( net2_entity))
			when( stringp( net_trace)
				fprintf( out_port format "" car( net2_entity) cadr( net2_entity) total net_trace)
			)
			
			fprintf( out_port "\n")
		)
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( compare_result_diffpair_entity_Derek07072020( a b)
	prog( ( result_a result_b)
		result_a = car( a)
		result_b = car( b)
		
		;;;;; compare the final result pass/fail
		if( equal( result_a result_b) then
			;;;;; compare the total result pass/fail
			result_a = car( parseString( caddr( a) "|"))
			result_b = car( parseString( caddr( b) "|"))
			
			; compare diffpair
			if( equal( result_a result_b) then
				result_a = cadr( a)
				result_b = cadr( b)
				
				return( alphalessp( result_a result_b))
			else
				return( alphalessp( result_a result_b))
			)
		else
			return( alphalessp( result_a result_b))
		)
	)
)

procedure( compare_bad_children_Derek07072020( a b)
	prog( ( nth_a nth_b)
		nth_a = listnindex( _bad_children_order car( a))
		nth_b = listnindex( _bad_children_order car( b))
		
		if( eqv( nth_a nth_b) then
			return( alphalessp( caadr( a)->net->name caadr( b)->net->name))
		else
			return( nth_a < nth_b)
		)
	)
)

procedure( length_match_by_cline_main_Derek07072020()
	prog( ()
		(unless axlOKToProceed() (println "Please done current function to use this program") (return nil))
		;;
		
		init_Derek07072020()
		
		;;;;; get diffpair
		diffpair_ls = axlDBGetDesign()->diffpair
		;diffpair_ls = setof( x diffpair_ls equal( x->name "REG_P1V2_RS"))
		
		;;;;; get net info
		foreach( diffpair_id diffpair_ls
			diffpair_entity = get_diffpair_entity_Derek07072020( diffpair_id)
			when( dtpr( diffpair_entity)
				result_diffpair_entity = get_result_diffpair_entity_Derek07072020( diffpair_entity)
				_result_diffpair_entity_ls = append1( _result_diffpair_entity_ls result_diffpair_entity)
			)
		)
		
		;;;; sort the result
		_result_diffpair_entity_ls = sortcar( _result_diffpair_entity_ls 'compare_result_diffpair_entity_Derek07072020)
		_bad_children_ls = sort( _bad_children_ls 'compare_bad_children_Derek07072020)
		
		;;;; output log file
		write_log_Derek07072020()
		
		axlUIViewFileCreate( _check_length_match_by_cline_logname "Check Length Match by Cline Report" nil)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setting

; (length_match_by_cline_main_Derek07072020)
(axlCmdRegister "length_match_by_cline" 'length_match_by_cline_main_Derek07072020)
; skill encrypt( "C:/skill/length_match_by_cline_v1.il" "C:/skill/length_match_by_cline_v1.ile")
; (load "length_match_by_cline_v1.ile")
; (load "length_match_by_cline_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setting