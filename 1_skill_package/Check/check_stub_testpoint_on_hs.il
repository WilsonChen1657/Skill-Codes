;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; 1. Developer: Derek Hsu
; 2. Starting Date: 2019/8/26 - _Derek20190826
; 3. Purpose: check the testpoint protruding out from pin or via on high speed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( check_value_Derek20190826( err_type func_nm val_nm val type)
	prog( ( result)
		unless( symbolp( type) println( "ArgErr: check_value() - [type] is not a symbol") return( nil))
		unless( symbolp( err_type) println( "ArgErr: check_value() - [err_type] is not a symbol") return( nil))
		unless( symbolp( func_nm) println( "ArgErr: check_value() - [func_nm] is not a symbol") return( nil))
		unless( symbolp( val_nm) println( "ArgErr: check_value() - [val_nm] is not a symbol") return( nil))
		;;
		
		caseq( type
			( '_v_testpoint
				result = member( val->testPoint list( "ETCH/TOP" "ETCH/BOTTOM"))
			)
			( '_v_net
				result = equal( "net" val->objType)
			)
			( '_v_dbid
				result = stringp( val->objType)
			)
			( '_v_shape_objtype
				result = equal( "shape" val->objType)
			)
			( '_v_shape_or_polygon_objtype
				result = or( equal( "shape" val->objType) equal( "polygon" val->objType))
			)
			( '_v_shape_or_polygon_objtype_dtpr
				result = and( dtpr( val) forall( x val or( equal( "shape" x->objType) equal( "polygon" x->objType))))
			)
			( '_v_shape_dtpr
				result = and( dtpr( val) forall( x val equal( "shape" x->objType)))
			)
			( '_v_text_objtype
				result = equal( "text" val->objType)
			)
			( '_v_form_objtype
				result = equal( "form" val->objType)
			)
			( '_v_via_name
				result = and( stringp( val) member( val axlGetAllViaList()~>name))
			)
			( '_v_number
				result = numberp( val)
			)
			( '_v_number_positive
				result = and( numberp( val) (val >= 0))
			)
			( '_v_natural_number
				;; 1 2 3 4 5 6 7 8 9
				result = and( integerp( val) (val > 0))
			)
			( '_v_natural_number_or_string
				;; 1 2 3 4 5 6 7 8 9 ""
				result = or( and( integerp( val) (val > 0)) stringp( val))
			)
			( '_v_natural_number_or_nil
				;; 1 2 3 4 5 6 7 8 9
				result = or( and( integerp( val) (val > 0)) null( val))
			)
			( '_v_bool
				result = booleanp( val)
			)
			( '_v_symbol_or_string
				result = or( symbolp( val) stringp( val))
			)
			( '_v_symbol_objtype
				result = equal( "symbol" val->objType)
			)
			( '_v_symbol_objtype_dtpr
				result = and( dtpr( val) forall( x val equal( "symbol" x->objType)))
			)
			( '_v_symbol_objtype_or_nil
				if( null( val)
					result = t
					result = equal( "symbol" val->objType)
				)
			)
			( '_v_symbol
				result = symbolp( val)
			)
			( '_v_string
				result = stringp( val)
			)
			( '_v_string_or_nil
				result = or( null( val) stringp( val))
			)
			( '_v_string_or_bool
				result = or( booleanp( val) stringp( val))
			)
			( '_v_string_or_bool_or_natural_number
				result = or( booleanp( val) stringp( val) and( integerp( val) (val > 0)))
			)
			( '_v_list
				result = listp( val)
			)
			( '_v_dtpr
				result = dtpr( val)
			)
			( '_v_box
				result = and( pairp( val) pairp( car( val)) pairp( cadr( val)))
				when( result (result = and( forall( x car( val) numberp( x)) forall( x cadr( val) numberp( x)))))
			)
			( '_v_string_dtpr
				result = and( dtpr( val) forall( x val stringp( x)))
			)
			( '_v_string_dtpr_or_string
				result = or( stringp( val) and( dtpr( val) forall( x val stringp( x))))
			)
			( '_v_string_list_or_string
				result = or( null( val) stringp( val) and( dtpr( val) forall( x val stringp( x))))
			)
			( '_v_table_or_nil
				result = or( null( val) tablep( val))
			)
			( '_v_outport
				result = outportp( val)
			)
			( '_v_inport
				result = inportp( val)
			)
			( '_v_filename
				result = and( stringp( val) isFile( val))
			)
			( '_v_table
				result = tablep( val)
			)
			( '_v_alphabet
				when( or( symbolp( val) stringp( val))
					(result = rexMatchp( "[a-zA-Z]+" val))
				)
			)
			( '_v_xy
				result = and( pairp( val) numberp( car( val)) numberp( cadr( val)))
			)
			( '_v_xy_or_nil
				if( null( val)
					result = t
					result = and( pairp( val) numberp( car( val)) numberp( cadr( val)))
				)
			)
			( '_v_path_objtype
				result = equal( "path" val->objType)
			)
			( '_v_path
				result = dtpr( val->_pathList)
			)
			( '_v_text_objtype_dtpr
				result = and( dtpr( val) forall( x val equal( "text" x->objType)))
			)
			( '_v_text_objtype_list
				if( null( val)
					result = t
					result = and( dtpr( val) forall( x val equal( "text" x->objType)))
				)
			)
			( '_v_seg_objtype_dtpr
				result = and( dtpr( val) forall( x val or( equal( "line" x->objType) equal( "arc" x->objType))))
			)
			( '_v_seg_objtype_list
				if( null( val)
					result = t
					result = and( dtpr( val) forall( x val or( equal( "line" x->objType) equal( "arc" x->objType))))
				)
			)
			( t
				printf( "ERROR: check_value_Derek20190826() - Yet to define type[%s] for value[%s] in function[%s]\n" type val_nm val_nm func_nm)
			)
		)
		
		unless( result printf( "%s: %s() - [%s][%L] is not a %s\n" err_type func_nm val_nm val type))
		
		return( result)
	)
)

procedure( init_Derek20190826()
	;;;; Allegro data
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	setq( _log_variable "ads_sdlog")
	unless( stringp( axlGetVariable( _log_variable)) axlSetVariable( _log_variable "log"))
	
	;;;; program usage data
	setq( _top_bot_ly list( "ETCH/TOP" "ETCH/BOTTOM"))
	setq( _orign_visible nil)
	setq( _path "path")
	setq( _via "via")
	
	setq( _box_side_d2 if( equal( "mils" _allegro_unit) 4 0.1))
	
	;;;; user define data
	;setq( _not_hs_term_ls list( "I2C" "IIC" "CLK" "GND" "PWR" "SCL" "SDA"))
	setq( _not_hs_term_ls list( "GND" "PWR"))
	
	setq( _month_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	setq( _now_time sprintf( nil "%d%.2d%.2d-%.2d%.2d%.2d" _year listnindex( _month_ls _month) _date _hour _minute _second))
	setq( _log_filename sprintf( nil "check_stub_testpoint_%s.log" _now_time))
	
	setq( _log_path axlGetVariable( _log_variable))
	setq( _log_addr strcat( _log_path "/" _log_filename))
	
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_path_start_end( path_id)
	; path_id = car( axlGetSelSet())
	prog( ( seg_ls seg_start seg_end start_xy end_xy result)
		unless( check_value_Derek20190826( 'ArgErr 'get_path_start_end 'path_id path_id '_v_path_objtype) return( nil))
		;;
		
		seg_ls = path_id->segments
		
		if( onep( length( seg_ls)) then
			start_xy = car( car( seg_ls)->startEnd)
			end_xy = cadr( car( seg_ls)->startEnd)
		else
			end_xy = cadr( car( seg_ls)->startEnd)
			start_xy = car( cadr( seg_ls)->startEnd)
			if( axlGeoPointsEqual( end_xy start_xy) then
				start_xy = car( car( seg_ls)->startEnd)
				end_xy = cadr( lastelem( seg_ls)->startEnd)
			else
				start_xy = cadr( car( seg_ls)->startEnd)
				end_xy = car( lastelem( seg_ls)->startEnd)
			)
		)
		result = list( start_xy end_xy)
		
		return( result)
	)
)

procedure( get_single_link_tp_Derek20190826( tp_id)
	; tp_id = car( axlGetSelSet())
	prog( ( path_cnt tp_xy branches branch children obj_ls path_ls path_id start_end result)
		unless( check_value_Derek20190826( 'ArgErr 'get_single_link_tp 'tp_id tp_id '_v_testpoint) return( nil))
		;;
		
		path_cnt = 0
		tp_xy = tp_id->xy
		branches = tp_id->net->branches
		foreach( branch branches
			children = branch->children
			obj_ls = setof( x children equal( _path x->objType))
			path_ls = append( path_ls obj_ls)
		)
		;; path_id = car( path_ls)
		foreach( path_id path_ls
			start_end = get_path_start_end( path_id)
			when( exists( xy start_end axlGeoPointsEqual( tp_xy xy)) path_cnt++)
		)
		
		result = when( onep( path_cnt) list( tp_id))
		
		return( result)
	)
)

procedure( get_tp_from_net_Derek20190826( net_id)
	; net_id = car( axlGetSelSet())
	prog( ( branches children tp_ls)
		unless( check_value_Derek20190826( 'ArgErr 'get_tp_from_net 'net_id net_id '_v_net) return( nil))
		;;
		
		branches = net_id->branches
		children = mapcan( lambda( (x) x->children) branches)
		tp_ls = setof( x children and( equal( _via x->objType) x->testPoint))
		
		return( tp_ls)
	)
)

procedure( get_fail_tp_contents_Derek20190826( fail_tp_ls)
	prog( ( line contents tp_id layer testpoint net_name tp_xy)
		unless( check_value_Derek20190826( 'ArgErr 'get_fail_tp_contents 'fail_tp_ls fail_tp_ls '_v_dtpr) return( nil))
		;;
		
		
		line = "LAYER,NET_NAME,TESTPOINT,XY"
		contents = list( line)
		
		fail_tp_ls = sort( fail_tp_ls lambda( (a b) alphalessp( b->testPoint a->testPoint)))
		foreach( tp_id fail_tp_ls
			layer = tp_id->testPoint
			testpoint = tp_id->name
			net_name = tp_id->net->name
			tp_xy = tp_id->xy
			
			sprintf( line "%s,%s,%s,%L" layer net_name testpoint tp_xy)
			contents = append1( contents line)
		)
		
		return( contents)
	)
)

procedure( write_log_Derek20190826( contents)
	prog( ( out_port line)
		unless( check_value_Derek20190826( 'ArgErr 'write_log 'contents contents '_v_dtpr) return( nil))
		;;
		
		out_port = outfile( _log_addr "w")
		unless( check_value_Derek20190826( 'ArgErr 'write_log 'out_port out_port '_v_outport) return( nil))
		
		foreach( line contents fprintf( out_port "%s\n" line))
		
		close( out_port)
		
		return( t)
	)
)

procedure( perform_status_Derek20190826( option)
	setq( _orign_visible nil)
	prog( ()
		unless( check_value_Derek20190826( 'ArgErr 'perform_status 'option option '_v_bool) return( nil))
		;;
		
		if( option then
			;;; end of a process
			axlVisibleSet( _orign_visible)
			axlVisibleUpdate( t)
		else
			;;; begining of a process
			_orign_visible = axlVisibleGet()
		)
		
		;;;;
		axlDBControl( 'drcEnable option)
		axlDBControl( 'busRats option)
		axlDBControl( 'ratnestDistance option)
		axlDBMemoryReclaim()
		
		
		return( t)
	)
)

procedure( get_hs_net_ls_Derek20190826()
	let( ( diffpair df_net_ls total)
		diffpair = axlDBGetDesign()->diffpair
		df_net_ls = mapcan( lambda( (x) x->groupMembers) diffpair)
		
		total = length( df_net_ls)
		printf( "INFO: get_hs_net_ls() - Current number of net in diffpair: %d\n" total)
		
		df_net_ls = setof( net df_net_ls not( exists( term _not_hs_term_ls index( net->name term))))
		
		total = length( df_net_ls)
		printf( "INFO: get_hs_net_ls() - Reserved number of net in diffpair: %d\n" total)
		
		df_net_ls
	)
)

procedure( check_stub_testpoint_main_Derek20190826()
	prog( ( net_ls tp_ls fail_tp_ls contents msg)
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		;;
		
		;;;;
		init_Derek20190826()
		perform_status_Derek20190826( nil)
		
		;;;; get high speed
		net_ls = get_hs_net_ls_Derek20190826()
		
		;;;; get testpoint on highspeed
		tp_ls = mapcan( lambda( (net) get_tp_from_net_Derek20190826( net)) net_ls)
		
		;;;; get illegal testpoint list
		fail_tp_ls = mapcan( lambda( (tp) get_single_link_tp_Derek20190826( tp)) tp_ls)
		
		;;;; write log
		contents = get_fail_tp_contents_Derek20190826( fail_tp_ls)
		write_log_Derek20190826( contents)
		
		;;;;
		perform_status_Derek20190826( t)
		
		;;;;
		if( isFile( _log_addr) then
			msg = "The process of check_stub_testpoint is done. Please check this out"
			println( msg)
			axlUIConfirm( msg 'INFO)
			axlUIViewFileCreate( _log_addr "Check_stub_testpoint.log" nil)
		else
			msg = "The process of check_stub_testpoint is done. No illegal testpoint has been found"
			println( msg)
			axlUIConfirm( msg 'INFO)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of functino

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_stub_testpoint" 'check_stub_testpoint_main_Derek20190826)
; (check_stub_testpoint_main_Derek20190826)
; skill encrypt("c:/skill/check_stub_testpoint_on_hs_v1.il" "c:/skill/check_stub_testpoint_on_hs_v1.ile")
;; (load "check_stub_testpoint_on_hs_v1.il")
;; (load "check_stub_testpoint_on_hs_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup