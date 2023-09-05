;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 06052020 - _Derek06052020
;introduction: 0201/0402/0603(optional)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek06052020()
	;;;;; use data define
	setq( _symbol_with_thermal_ls list( "0201" "0402"))
	setq( _thermal_prop_k_ls list( 'DYN_FIXED_THERM_WIDTH_ARRAY 'DYN_THERMAL_CON_TYPE))
	
	;;;;; create log folder
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _log_filename "check_thermal_relief-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	sprintf( _check_symbol_thermal_relief_logname "%s/%s" _log_dir _log_filename)
	
	;;;;;
	setq( _schematic_name get_schematic_name_Derek06052020())
)

procedure( get_schematic_name_Derek06052020()
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_pwr_net_with_shape_Derek06052020()
	;;; expect all the net with shape without GND term is our target
	prog( ( net_ls)
		net_ls = axlDBGetDesign()->nets
		
		;;;;; all the net with shape
		net_ls = mapcan( lambda( (n) when( exists( b n->branches exists( c b->children equal( "shape" c->objType))) list( n))) net_ls)
		
		
		;;;;; all the net is not ground
		net_ls = mapcan( lambda( (n) unless( index( n->name "GND") list( n))) net_ls)
		
		
		return( net_ls)
	)
)

procedure( is_fullname_in_term_list_Derek06052020( fullname @optional (term_ls _symbol_with_thermal_ls))
	; is_fullname_in_term_list_Derek06052020( "CMC_2P_7066" _symbol_with_thermal_ls)
	prog( ()
		return( exists( x term_ls index( fullname x)))
	)
)

procedure( get_thermal_sym_Derek06052020( net_id)
	; net_id = car( axlGetSelSet())
	; sym_id = car( axlGetSelSet())
	prog( ( pin_ls thermal_sym_ls)
		pin_ls = axlPinsOfNet( net_id 'pin)
		
		sym_ls = pin_ls~>parent
		thermal_sym_ls = mapcan( lambda( (s)
			when( or( is_fullname_in_term_list_Derek06052020( s->name) 
				is_fullname_in_term_list_Derek06052020( s->component->deviceType)) list( s))) sym_ls)
		
		
		return( thermal_sym_ls)
	)
)

procedure( get_thermal_pin_without_thermal_prop_Derek06052020( sym_id)
	; pin_id = car( axlGetSelSet())
	prog( ( thermal_pin_without_thermal_prop_ls)
		pin_ls = setof( p sym_id->pins !index( p->net->name "GND"))
		foreach( pin_id pin_ls
			prop_k_ls = mapcar( 'car axlDBGetProperties( pin_id))
			unless( exists( a _thermal_prop_k_ls exists( b prop_k_ls eq( a b)))
				thermal_pin_without_thermal_prop_ls = append1( thermal_pin_without_thermal_prop_ls pin_id)
			)
		)
		
		
		return( thermal_pin_without_thermal_prop_ls)
	)
)

procedure( compare_thermal_pin_data_Derek06052020( a b)
	prog( ()
		;;;; TOP is stringly shorter than BOTTOM
		unless( equal( car( a) car( b))
			return( strlen( car( a)) < strlen( car( b)))
		)
		
		;;;; sort net name
		unless( equal( cadr( a) cadr( b))
			return( alphalessp( cadr( a) cadr( b)))
		)
		
		;;;;  compare footprint name
		unless( equal( caddr( a) caddr( b))
			return( alphalessp( caddr( a) caddr( b)))
		)
		
		
		return( t)
	)
)

procedure( get_thermal_pin_data_Derek06052020( thermal_pin_without_thermal_prop_ls)
	prog( (ly_net_ft_pin_xy_prop_ls)
		foreach( pin_id thermal_pin_without_thermal_prop_ls
			subclass = cadr( parseString( car( pin_id->startEnd) "/"))
			net_name = pin_id->net->name
			footprint_name = pin_id->parent->name
			pin_name = axlDbidName( pin_id)
			sprintf( xy "(%.2f %.2f)" car( pin_id->xy) cadr( pin_id->xy))
			sprintf( prop "%L" mapcar( 'car axlDBGetProperties( pin_id)))
			
			ly_net_ft_pin_xy_prop = list( subclass net_name footprint_name pin_name xy prop)
			ly_net_ft_pin_xy_prop_ls = append1( ly_net_ft_pin_xy_prop_ls ly_net_ft_pin_xy_prop)
		)
		
		;;;;; sort top to bottom
		ly_net_ft_pin_xy_prop_ls = sort( ly_net_ft_pin_xy_prop_ls 'compare_thermal_pin_data_Derek06052020)
		
		return( ly_net_ft_pin_xy_prop_ls)
	)
)

procedure( write_log_Derek06052020( ly_net_ft_pin_xy_prop_ls)
	prog( ( out_port)
		out_port = outfile( _check_symbol_thermal_relief_logname "w")
		unless( outportp( out_port) println( "ERROR: Fail to write log file") return( nil))
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: This program is used to detect whether there is any pin on following symbols on power shape without thermal properties\n%L\n" _symbol_with_thermal_ls)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "To-be-identified thermal properties: %L\n" _thermal_prop_k_ls)
		
		fprintf( out_port "\n\n")
		
		format = "%-8s,%-25s,%-12s,%-17s,%-21s,%s\n"
		fprintf( out_port format "LAYER" "NET" "FOOTPRINT" "PIN" "XY" "PROPERTIES")
		foreach( ly_net_ft_pin_xy_prop ly_net_ft_pin_xy_prop_ls
			subclass = car( ly_net_ft_pin_xy_prop)
			net_name = cadr( ly_net_ft_pin_xy_prop)
			footprint_name = caddr( ly_net_ft_pin_xy_prop)
			pin_name = nth( 3 ly_net_ft_pin_xy_prop)
			xy = nth( 4 ly_net_ft_pin_xy_prop)
			prop = nth( 5 ly_net_ft_pin_xy_prop)
			
			fprintf( out_port format subclass net_name footprint_name pin_name xy prop)
		)
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( check_thermal_relief_main_Derek06052020()
	prog( ()
		unless( axlOKToProceed() println( "Please done current commend to use this function") return( nil))
		
		;;;;; initial the variable and log file name
		init_Derek06052020()
		
		;;;;; 0603 confirm
		answer = axlUIYesNo( "Do you want to check thermal pin on 0603?" "Check Thermal pin Confirm" 'no)
		when( answer (_symbol_with_thermal_ls = append1( _symbol_with_thermal_ls "0603")))
		
		;;;;; 
		pwr_net_with_shape_ls = get_pwr_net_with_shape_Derek06052020()
		printf( "INFO: Number of net with shape rather then GND: %d\n" length( pwr_net_with_shape_ls))
		
		;;;;;
		thermal_sym_ls = mapcan( lambda( (n) get_thermal_sym_Derek06052020( n)) pwr_net_with_shape_ls)
		printf( "INFO: Number of symbol should have thermal property: %d\n" length( thermal_sym_ls))
		
		;;;;;
		thermal_pin_without_thermal_prop_ls = mapcan( lambda( (s) get_thermal_pin_without_thermal_prop_Derek06052020( s)) thermal_sym_ls)
		printf( "INFO: Number of thermal pin on power net without thermal properties: %d\n" length( thermal_pin_without_thermal_prop_ls))
		
		ly_net_ft_pin_xy_prop_ls = get_thermal_pin_data_Derek06052020( thermal_pin_without_thermal_prop_ls)
		
		;;;;;
		write_log_Derek06052020( ly_net_ft_pin_xy_prop_ls)
		
		;;;;; display log file
		axlUIViewFileCreate( _check_symbol_thermal_relief_logname "Check Symbol Thermal Report" nil)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_thermal_relief" 'check_thermal_relief_main_Derek06052020)
; (check_thermal_relief_main_Derek06052020)
; skill (encrypt "c:/skill/check_thermal_relief_v1.il" "c:/skill/check_thermal_relief_v1.ile")
; (load "check_thermal_relief_v1.ile")
; (load "check_thermal_relief_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup