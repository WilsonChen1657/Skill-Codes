;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 04/23/2020 - _Derek04232020
;Introduction: update selected multiple via optimization symbol's routing keepout shape to a new fit which matches the standard of 16G
;	update shape:
;		1. single routing keepout all shape exists: create number of routing keepout shapes and remove the routing keepout all shape
;		2. multiple routing keepout shapes are exists: update them all accordingly
;	the type of shape:
;		1. the internal of the signal, including route outing layer: 2 circle shape, with Anti diameter
;		2. the outer of the signal: oblong shape just like original one
;	else:
;		1. the fit of routing keepout shape may be in oblong or rectangle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek04232020()
	;;;;; common
	setq( _unit car( axlDBGetDesignUnits()))
	
	;;;; log filename
	setq( _month_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _today_time "%.4d%.2d%.2d-%.2d%.2d%.2d" _year listnindex( _month_ls _month) _date _hour _minute _second)
	sprintf( _log_filename "check_testpoint-%s.log" _today_time)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	
	;;;;; create log folder
	if( stringp( axlGetVariable( "ads_sdlog")) then
		sprintf( _log_path "./%s/" axlGetVariable( "ads_sdlog"))
		createDir( _log_path)
	else
		setq( _log_path nil)
	)
	
	;;;;; create log file
	if( stringp( _log_path)
		sprintf( _log_addr "%s%s" _log_path _log_filename)
		setq( _log_addr nil)
	)
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	setq( _rko_operation nil)
	setq( _rko_to_16g 0)
	setq( _rko_to_all 1)
	
	setq( _plane "PLANE")
	setq( _region_16g "16G")
	setq( _region_nodrc5 "NODRC_5")
	setq( _cset_16g "16G_VIA_OPT")
	setq( _layer_cons_reg_all "CONSTRAINT REGION/ALL")
	setq( _prop_shape_16g list( "REGION_NAME" _region_16g))
	setq( _16g_circle_radius nil)
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	setq( _etch_subclass_ls axlGetParam("paramLayerGroup:ETCH")->groupMembers)
	setq( _etch_layer_ls mapcar( lambda( (subclass) strcat( "ETCH/" subclass)) _etch_subclass_ls))
	
	setq( _gnd "GND")
	setq( _class_rko "ROUTE KEEPOUT")
	setq( _class_cons_reg "CONSTRAINT REGION")
	setq( _layer_rko_all "ROUTE KEEPOUT/ALL")
	setq( _prop_shape_rko_ls list( list( "VIAS_ALLOWED" t) list( "ROUTES_ALLOWED" t)))
	
	setq( _popup axlUIPopupDefine( nil list( list( "Done" 'axlFinishEnterFun))))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( is_viaOpt_Derek04232020( sym_id)
	; sym_id =  car( axlGetSelSet())
	; a = car( axlGetSelSet())
	prog( ( sym_xy etch_children via_sig_ls children)
		sym_xy = sym_id->xy
		unless( equal( "MECHANICAL" sym_id->type) printf( "WARNING: symbol on [%L] is not in mechanical type\n" sym_xy) return( nil))
		
		etch_children = sym_id->etchChildren
		via_sig_ls = setof( x etch_children !index( x->net->name "GND"))
		unless( dtpr( etch_children) printf( "WARNING: symbol on [%L] has no via\n" sym_xy) return( nil))
		unless( forall( x etch_children~>objType equal( "via" x)) printf( "WARNING: symbol on [%L] has non-via etch children\n" sym_xy) return( nil))
		unless( forall( x etch_children~>isThrough x) printf( "WARNING: symbol on [%L] has no thru via\n" sym_xy) return( nil))
		unless( eqv( 2 length( via_sig_ls)) printf( "WARNING: symbol on [%L] has > or < 2 signal vias\n" sym_xy) return( nil))
		
		return( t)
	)
)

procedure( get_viaOpt_bySelect_Derek04232020()
	prog( ( viaOpt_ls)
		axlUIConfirm( "Please select thru via optimizations to update the Route Keepout shapes")
		
		;;;;; set find filter
		axlSetFindFilter( ?enabled list( "NOALL" "SYMBOLS") ?onButtons list( "NOALL" "SYMBOLS"))
		
		;;;;; select symbols
		axlUIPopupSet( _popup)
		while( axlSelect()
			;;;; remove non via optimization
			not_viaOpt_ls = setof( x axlGetSelSet() !is_viaOpt_Derek04232020( x))
			when( dtpr( not_viaOpt_ls)
				axlSubSelectObject( not_viaOpt_ls)
			)
			
			;;;; get via opt
			viaOpt_ls = axlGetSelSet()
			sprintf( message "INFO: get_viaOpt_bySelect() - There are [%d] via optimizations has been selected. For updating route keepout shape, please right-click [Done]" axlGetSelSetCount())
			axlUIConfirm( message)
		)
		
		
		;;;;; reset fing filter
		axlSetFindFilter( ?enabled list( "NOALL") ?onButtons list( "NOALL"))
		axlUIPopupSet( nil)
		
		
		return( viaOpt_ls)
	)
)

procedure( get_radius_from_antipad_Derek04232020( padstack_id pad_type)
	; padstack_id = car( axlGetSelSet())
	prog( ( padstack_name layer antipad_id box diameter radius)
		layer = car( padstack_id->startEnd)
		antipad_id = axlDBGetPad( padstack_id layer pad_type)
		box = antipad_id->bBox
		diameter = abs( caar( box) - caadr( box))
		radius = diameter / 2.0
		
		return( radius)
	)
)

procedure( get_cline_with_xy_Derek04232020( cline_ls xy)
	; cline_id = car( axlGetSelSet())
	prog( ( paths path_start_xy path_end_xy cline_with_xy_ls)
		foreach( cline_id cline_ls
			paths = axlDB2Path( cline_id)
			
			cline_start_xy = car( paths->_pathList)->_endPoint
			cline_end_xy = lastelem( paths->_pathList)->_endPoint
			
			when( or( axlGeoPointsEqual( xy cline_start_xy) axlGeoPointsEqual( xy cline_end_xy))
				cline_with_xy_ls = append1( cline_with_xy_ls cline_id)
			)
		)
		
		
		return( cline_with_xy_ls)
	)
)

procedure( get_2cline_from_via_Derek04232020( via_id)
	;; via_id = car( axlGetSelSet())
	prog( ( children cline_ls xy_via path_ls)
		children = via_id->branch~>children
		cline_ls = setof( x children equal( "path" x->objType))
		
		xy_via = via_id->xy
		path_ls = get_cline_with_xy_Derek04232020( cline_ls xy_via)
		
		
		return( path_ls)
	)
)

procedure( get_net_in_via_layers_Derek04232020( via_id)
	; via_id = car( axlGetSelSet())
	prog( ( net_in_layer_ls)
		clineseg_ls = get_2cline_from_via_Derek04232020( via_id)
		unless( eqv( 2 length( clineseg_ls)) printf( "ERROR: get_net_in_via_layers() - [%L] has > or < 2 clineseg connected\n" via_id->xy) return( nil))
		
		layer_2 = clineseg_ls~>layer
		layer_serial_2 = mapcar( lambda( (x) listnindex( _etch_layer_ls x)) layer_2)
		
		if( ( cadr( layer_serial_2) > car( layer_serial_2)) then
			start = car( layer_serial_2)
			end = cadr( layer_serial_2)
		else
			start = cadr( layer_serial_2)
			end = car( layer_serial_2)
		)
		
		for( i start end
			net_in_layer_ls = append1( net_in_layer_ls nth( i _etch_layer_ls))
		)
		
		return( net_in_layer_ls)
	)
)

procedure( get_cross_distance_vector_Derek04232020( xy_2 distance)
	prog( ( xy1 xy2 vect vect_x uni_distance)
		xy1 = car( xy_2)
		xy2 = cadr( xy_2)
		
		;;;;;
		unless( dtpr( xy1) printf( "ERROR: get_cross_distance_vector() - xy1 is not a coordination") return( nil))
		unless( dtpr( xy2) printf( "ERROR: get_cross_distance_vector() - xy2 is not a coordination") return( nil))
		unless( plusp( distance) printf( "ERROR: get_cross_distance_vector() - distance is not a positive number") return( nil))
		
		cond(
			( axlGeoEqual( car( xy1) car( xy2))
				vect_x = distance:0.0
			)
			( axlGeoEqual( cadr( xy1) cadr( xy2))
				vect_x = 0.0:distance
			)
			( t
				vect = axlMXYSub( xy1 xy2)
				vect_x = list( -cadr( vect) car( vect))
				
				uni_distance = distance / sqrt( car( vect_x)**2 + cadr( vect_x)**2)
				vect_x = axlMXYMult( vect_x uni_distance)
			)
		)
		
		
		return( vect_x)
	)
)

procedure( create_poly_by_paths_Derek04232020( path_main path_ls)
	; path_main = path_rect
	; path_ls = list( path_cir1 path_cir2)
	prog( ( paths poly_ls polies poly)
		paths = append( list( path_main) path_ls)
		poly_ls = mapcar( lambda( (x) car( axlPolyFromDB( x))) paths)
		
		polies = axlPolyOperation( car( poly_ls) cdr( poly_ls) 'OR)
		poly = car( polies)
		
		
		return( poly)
	)
)

procedure( create_oblong_poly_Derek04232020( xy_2 radius)
	;; poly = create_oblong_poly(  list(0.0:0.0 0.0:5.0) 3.0)
	;; axlDBCreateShape( poly t "etch/top" nil)
	prog( ( vector_a vector_b xy1 xy2 xy1_a xy1_b xy2_a xy2_b path_rect path_cir1 path_cir2 poly)
		vector_a = get_cross_distance_vector_Derek04232020( xy_2 radius)
		unless( vector_a println( "ERROR: create_oblong_poly() - Fail to get vector from 2 xy") return( nil))
		
		vector_b = axlMXYMult( vector_a -1.0)
		
		xy1 = car( xy_2)
		xy2 = cadr( xy_2)
		xy1_a = axlMXYAdd( xy1 vector_a)
		xy1_b = axlMXYAdd( xy1 vector_b)
		xy2_a = axlMXYAdd( xy2 vector_a)
		xy2_b = axlMXYAdd( xy2 vector_b)
		
		;;;;; create 3 component
		path_rect = create_rect_path_Derek04232020( list( xy1_a xy2_a xy2_b xy1_b))
		path_cir1 = create_circle_path_Derek04232020( xy1 radius)
		path_cir2 = create_circle_path_Derek04232020( xy2 radius)
		
		poly = create_poly_by_paths_Derek04232020( path_rect list( path_cir1 path_cir2))
		
		return( poly)
	)
)

procedure( create_rect_path_Derek04232020( xy_4)
	prog( ( xy_5 path)
		xy_5 = append1( xy_4 car( xy_4))
		path = axlPathStart( xy_5)
		
		
		return( path)
	)
)

procedure( create_circle_path_Derek04232020( xy_center radius)
	prog( ( xy path)
		xy = axlMXYAdd( xy_center list( radius 0))
		path = axlPathStart( list( xy))
		
		axlPathArcCenter( path 0.0 xy t xy_center)
		
		return( path)
	)
)

procedure( create_all_util_Derek04232020( viaOpt_id via_sig_ls radius_reg radius_anti)
	prog( ( poly_oblong)
		via_xy_2 = via_sig_ls~>xy
		;;;;; create region for pair of signal vias
		poly_oblong = create_oblong_poly_Derek04232020( via_xy_2 radius_anti)
		result = create_shape_Derek04232020( poly_oblong t _layer_rko_all viaOpt_id _prop_shape_rko_ls)
		
		;;;;; create constraint region for ground via
		via_gnd_ls = setof( x viaOpt_id->etchChildren index( x->net->name _gnd))
		via_xy_2 = via_gnd_ls~>xy
		poly_oblong = create_oblong_poly_Derek04232020( via_xy_2 radius_reg)
		result = create_void_shape_with_region( poly_oblong viaOpt_id _layer_cons_reg_all _region_nodrc5)

		
		return( t)
	)
)

procedure( create_shape_Derek04232020( path filled layer sym_id prop)
	; shape_id = car( axlGetSelSet())
	prog( ( result_ls shape_id)
		result_ls = axlDBCreateShape( path filled layer nil sym_id)
		shape_id = car( result_ls)
		unless( shape_id printf( "ERROR: create_rko_shape() - Fail to create RKO shape on [%s] on [%L]\n" layer sym_id->xy) return( nil))
		
		when( prop
			result_ls = axlDBAddProp( shape_id prop)
			shape_id = car( result_ls)
		)
		
		
		return( shape_id)
	)
)

procedure( create_rko_16g_Derek04232020( viaOpt_id via_xy_2 radius_cir radius_obl net_in_layer_ls)
	; mapcar( 'axlDBGetLayerType _etch_layer_ls)
	prog( ( poly_oblong path_circle1 path_circle2 layer_rko)
		poly_oblong = create_oblong_poly_Derek04232020( via_xy_2 radius_obl)
		path_circle1 = create_circle_path_Derek04232020( car( via_xy_2) radius_cir)
		path_circle2 = create_circle_path_Derek04232020( cadr( via_xy_2) radius_cir)
		
		;;;;; create circle shape for all layer
		create_shape_Derek04232020( path_circle1 t _layer_rko_all viaOpt_id _prop_shape_rko_ls)
		create_shape_Derek04232020( path_circle2 t _layer_rko_all viaOpt_id _prop_shape_rko_ls)
		
		foreach( (layer subclass) _etch_layer_ls _etch_subclass_ls
			unless( member( layer net_in_layer_ls)
				layer_rko = strcat( _class_rko "/" subclass)
				create_shape_Derek04232020( poly_oblong t layer_rko viaOpt_id _prop_shape_rko_ls)
			)
		)
		
		
		return( t)
	)
)

procedure( remove_shape_from_symbol_Derek04232020( sym_id shape_term)
	; sym_id = car( axlGetSelSet())
	prog( ( shape_rko_ls shape_reg_ls shape_ls)
		println( sym_id->children~>layer) ;; apple
		shape_ls = setof( x sym_id->children index( (x->layer || "") shape_term))
		
		if( dtpr( shape_ls) then
			axlDeleteObject( shape_ls)
			printf( "INFO: remove_shape_from_symbol() - The shape with [%s] has been removed from [%s]\n" shape_term sym_id->name)
		else
			printf( "INFO: remove_shape_from_symbol() - None of shpae with [%s] has been removed from [%s]\n" shape_term sym_id->name)
		)
		
		
		return( t)
	)
)

procedure( create_constraint_16g()
	;;;;; region is a kind of group in REGION type
	;;;;; you can execute region relative function as common group
	;;;;; the spacing reference cset can be edit as a property
	; region_id = car( axlGetSelSet())
	prog( ( region_id)
		;;;;; create a new region if it's not exist
		unless( exists( x axlDBGetDesign()->region~>name equal( _region_16g x))
			axlRegionCreate( _region_16g)
			axlSaveDesign( ?mode "nocheck" ?noConfirm t ?writeModel t)
			;axlUIConfirm( "Region in spacing constraint has been created")
		)
		unless( exists( x axlDBGetDesign()->region~>name equal( _region_16g x))
			printf( "ERROR: create_constraint_16g() - Fail to create region: %s\n" _region_16g)
			return( nil)
		)
		
		;;;;; create a spacing cset 
		unless( exists( x axlCnsList( 'spacing) equal( _cset_16g x))
			axlCNSCreate( 'spacing _cset_16g nil)
			axlCNSSetSpacing( _cset_16g nil 'via_shape 0.0)
			axlCNSSetSpacing( _cset_16g nil 'hole_shape 0.0)
			axlSaveDesign( ?mode "nocheck" ?noConfirm t ?writeModel t)
			;axlUIConfirm( "Spacing Cset has been created")
		)
		unless( exists( x axlCnsList( 'spacing) equal( _cset_16g x))
			printf( "ERROR: create_constraint_16g() - Fail to create spacing cset: %s\n" _cset_16g)
			return( nil)
		)
		
		;;;;; assign cset to region
		region_id = car( setof( x axlDBGetDesign()->groups equal( _region_16g x->name)))
		unless( exists( x region_id->parentGroups~>name equal( _region_16g x))
			region_id = caar( axlDBAddProp( region_id list( 'SPACING_CONSTRAINT_SET _cset_16g)))
			axlSaveDesign( ?mode "nocheck" ?noConfirm t ?writeModel t)
		)
		
		
		return( t)
	)
)

procedure( create_void_shape_with_region( path viaOpt_id region_layer region_name)
	prog( ( shape_id region_id result)
		shape_id = create_shape_Derek04232020( path nil region_layer viaOpt_id nil)
		
		;;;;; get 16g region
		region_id = car( setof( x axlDBGetDesign()->groups equal( region_name x->name)))
		
		;;;;; add the net of the via into the region
		result = axlRegionAdd( region_id shape_id)
		
		
		return( result)
	)
)

procedure( create_16g_util( viaOpt_id via_sig_ls radius_reg radius_anti)
	; axlDBGetDesign()->
	prog( ( via_xy_2 poly_oblong region_id shape_id net_in_layer_ls)
		;;; create oblong constraint region for pair of signal vias shape
		via_xy_2 = via_sig_ls~>xy
		poly_oblong = create_oblong_poly_Derek04232020( via_xy_2 radius_reg)
		result = create_void_shape_with_region( poly_oblong viaOpt_id _layer_cons_reg_all _region_16g)
		
		;;;;; get net in via layers
		net_in_layer_ls = get_net_in_via_layers_Derek04232020( car( via_sig_ls))
		unless( dtpr( net_in_layer_ls) printf( "ERROR: update_rko_on_viaOpt() - [%s] has no net passing through it") return( nil))
		printf( "INFO: net passed from [%s] to [%s]\n" car( net_in_layer_ls) lastelem(net_in_layer_ls))
		
		;;;;;
		result = create_rko_16g_Derek04232020( viaOpt_id via_xy_2 _16g_circle_radius radius_anti net_in_layer_ls)
		
		;;;;; create 2 via constraint  region
		via_gnd_ls = setof( x viaOpt_id->etchChildren index( x->net->name _gnd))
		via_xy_2 = via_gnd_ls~>xy
		path_circle1 = create_circle_path_Derek04232020( car( via_xy_2) radius_reg)
		path_circle2 = create_circle_path_Derek04232020( cadr( via_xy_2) radius_reg)
		
		result = create_void_shape_with_region( path_circle1 viaOpt_id _layer_cons_reg_all _region_nodrc5)
		result = create_void_shape_with_region( path_circle2 viaOpt_id _layer_cons_reg_all _region_nodrc5)
		
		return( t)
	)
)

procedure( update_rko_on_viaOpt_Derek04232020( viaOpt_id)
	; viaOpt_id = car( axlGetSelSet())
	; v = car( via_sig_ls)
	prog( ( sym_name via_sig_ls via_xy_2 radius_anti radius_reg rko_shape_ls radius_16g_radius)
		sym_name = viaOpt_id->name
		
		;;;;; get 2 signal via
		via_sig_ls = setof( x viaOpt_id->etchChildren !index( x->net->name _gnd))
		unless( eqv( 2 length( via_sig_ls)) printf( "ERROR: update_rko_on_viaOpt() - [%s] has no 2 signal via\n") return( nil))
		
		via_xy_2 = via_sig_ls~>xy
		radius_anti = get_radius_from_antipad_Derek04232020( car( via_sig_ls) "ANTI")
		radius_reg = get_radius_from_antipad_Derek04232020( car( via_sig_ls) "REGULAR")
		printf( "\nProcessing [%s]- 2Vias:%L - anti-reg Radius:[%f] - anti-pad Radius:[%f]\n" sym_name via_xy_2 radius_reg radius_anti)
		
		;;;;; remove RKO from current via opt 
		result = remove_shape_from_symbol_Derek04232020( viaOpt_id _class_rko)
		result = remove_shape_from_symbol_Derek04232020( viaOpt_id _class_cons_reg)
		
		;;;;; direct to create RKO option
		cond(
			( eqv( _rko_to_all _rko_operation)
				result = create_all_util_Derek04232020( viaOpt_id via_sig_ls radius_reg radius_anti)
			)
			( eqv( _rko_to_16g _rko_operation)
				;;;;; create 16g region
				result = create_16g_util( viaOpt_id via_sig_ls radius_reg radius_anti)
			)
		)
		
		
		return( t)
	)
)

procedure( select_operation_Derek04232020()
	let( ( answer mode)
		answer = axlUIMultipleChoice( "Please choose a Route Keepout shape type you want" list( "16G" "ALL") "Update Route Keepout shape on via optimization")
		cond(
			( eqv( 0 answer)
				_rko_operation = _rko_to_16g
				mode = "16G"
			)
			( eqv( 1 answer)
				_rko_operation = _rko_to_all
				mode = "THRU ALL"
			)
			( t
				printf( "ERROR: select_operation() - Undefined operation")
			)
		)
		
		when( stringp( mode)
			printf( "INFO: select_operation() - Processing [%s] mode\n" mode)
		)
	)
)

procedure( enter_float( msg)
	prog( ( answer number)
		while( !number
			answer = axlEnterString( ?prompts msg)
			unless( answer (number = ""))
			unless( equal( "" number)
				number = atof( answer)
				unless( number axlUIConfirm( "Warning: Input data is illegal. Please enter again!"))
			)
		)
		
		when( equal( "" number) (number = nil))
		
		
		return( number)
	)
)

procedure( update_viaOpt_v1_main_Derek04232020()
	prog( ( diameter viaOpt_ls)
		unless( axlOKToProceed() println( "Please done current function to use this program") return( nil))
		unless( onep( axlUIYesNoCancel( "Board file will be saved in the process. Would you like to keep continue?" "Saving Confirm" 'yes))
			println( "Process halt")
			return( nil)
		)
		;;
		
		init_Derek04232020()
		unless( stringp( _log_addr) println( "ERROR: update_viaOpt_v1_main() - Fail to create log file address") return( nil))
		
		;;;;; choose the operation
		select_operation_Derek04232020()
		unless( _rko_operation return( nil))
		
		;;;;; create 16g region constraint relative before anything else, otherwise save command will removed the stored dbid
		when( eqv( _rko_to_16g _rko_operation)
			println( "Creating the 16G relative constraint...")
			create_constraint_16g()
		)
		
		;;;;; get the radius of the circle of the mode is 16g
		when( eqv( _rko_to_16g _rko_operation)
			diameter = enter_float( "Please enter the diameter of the circle Route Keepout")
			unless( diameter println( "Process Halt") return( nil))
			_16g_circle_radius = diameter / 2
		)
		
		;;;;; select via opt by user
		viaOpt_ls = get_viaOpt_bySelect_Derek04232020()
		unless( dtpr( viaOpt_ls) println( "INFO: update_viaOpt_v1_main() - No via optimization has been selected. Process halt") return( nil))
		
		;;;; deal with all of those via opt
		foreach( viaOpt_id viaOpt_ls
			result = update_rko_on_viaOpt_Derek04232020( viaOpt_id)
			if( result
				printf( "INFO: Successfully create RKO shape on via opt at [%L]\n" viaOpt_id->xy)
				printf( "ERROR: Fail create RKO shape on via opt at [%L]\n" viaOpt_id->xy)
			)
		)
		
		;;;;; for some reason, i can't choose plane layer by layer to do the update
		;;;;; auto-generated shape seems like not a kind of dynamix shape
		axlShapeDynamicUpdate( nil t)
		
		axlUIConfirm( "Via optimizations have been updated. Please check this out!")
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "update_viaOpt" 'update_viaOpt_v1_main_Derek04232020)
; update_viaOpt_v1_main_Derek04232020()
; skill (encrypt "c:/skill/update_viaOpt_v1.il" "c:/skill/update_viaOpt_v1.ile")
; (load "update_viaOpt_v1.ile")
; (load "update_viaOpt_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup