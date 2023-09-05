;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; description
;
; Developer: Derek Hsu
; Starting date: 2/26/2021 - _Derek02262021
; Description:
;	1. check whether the degree of 2 clinesegs is less or equal then a degree (default is 90)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of description

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init_Derek02262021()
	setq( _default_clineseg_degree 90.0)
	
	defstruct( clineseg2_struct netname layer start_end1 start_end2 degree)
	
	;;;;; log
	setq( _log_var_key "ads_sdlog")
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _log_filename "check_90degree_route-%s.log" _date_time)
	unless( axlGetVariable( _log_var_key) axlSetVariable( _log_var_key "log"))
	setq( _log_dir (axlGetVariable( _log_var_key) || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _check_90degree_route_logname "%s/%s" _log_dir _log_filename)
	setq( _schematic_name get_schematic_name_Derek02262021())
)

procedure( get_schematic_name_Derek02262021()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls stringp( car( s->component->functions)->prop->LOGICAL_PATH)))
		unless( sym_id return( "*Fail to find the schema name*"))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_path_in_net_Derek02262021( net_id)
	prog( ( path_ls)
		foreach( branch net_id->branches
			foreach( child branch->children
				when( child->objType == "path"
					path_ls = append1( path_ls child)
				)
			)
		)
		
		return( path_ls)
	)
)

procedure( get_pairs_Derek02262021( path_ls)
	; net_id = car( axlGetSelSet())
	prog( ( seg_ls pair_len child1 child2 pair pair_ls)
		foreach( path_id path_ls
			seg_ls = path_id->segments
			pair_len = length( seg_ls) - 2
			
			for( i 0 pair_len
				child1 = nth( i seg_ls)
				child2 = nth( add1( i) seg_ls)
				
				pair = list( child1 child2)
				pair_ls = append1( pair_ls pair)
			)
		)
		
		return( pair_ls)
	)
)

procedure( get_clineseg_pairs_on_board_Derek02262021()
	prog( ( net_ls path_ls pair_ls clineseg_pair_ls)
		net_ls = axlDBGetDesign()->nets
		
		foreach( net_id net_ls
			path_ls = get_path_in_net_Derek02262021( net_id)
			pair_ls = get_pairs_Derek02262021( path_ls)
			clineseg_pair_ls = append( clineseg_pair_ls pair_ls)
		)
		
		return( clineseg_pair_ls)
	)
)

procedure( get_degree_by_sss_Derek02262021( center_xy a_xy b_xy)
	prog( ( a_side b_side c_side rad angle degree)
		c_side = axlDistance( a_xy b_xy)
		a_side = axlDistance( center_xy b_xy)
		b_side = axlDistance( center_xy a_xy)
		
		rad = (a_side**2 + b_side**2 - c_side**2) / (2 * a_side * b_side)
		angle = acos( rad)
		degree = axlRadToDeg( angle)
		
		return( degree)
	)
)

procedure( get_degree_between_2lines_Derek02262021( start_end1 start_end2)
	prog( ( a_xy1 a_xy2 b_xy1 b_xy2 center_xy a_xy b_xy degree)
		a_xy1 = car( start_end1)
		a_xy2 = cadr( start_end1)
		b_xy1 = car( start_end2)
		b_xy2 = cadr( start_end2)
		
		cond(
			( axlGeoPointsEqual( a_xy1 b_xy1)
				center_xy = a_xy1
				a_xy = a_xy2
				b_xy = b_xy2
			)
			( axlGeoPointsEqual( a_xy2 b_xy2)
				center_xy = a_xy2
				a_xy = a_xy1
				b_xy = b_xy1
			)
			( axlGeoPointsEqual( a_xy2 b_xy1)
				center_xy = a_xy2
				a_xy = a_xy1
				b_xy = b_xy2
			)
			( axlGeoPointsEqual( a_xy1 b_xy2)
				center_xy = a_xy1
				a_xy = a_xy2
				b_xy = b_xy1
			)
		)
		unless( center_xy return( 0.0))
		
		degree = get_degree_by_sss_Derek02262021( center_xy a_xy b_xy)
		
		return( degree)
	)
)

procedure( get_subclass_by_layer_Derek02262021( layer)
	prog( ( parts subclass)
		unless( layer return( ""))
		
		parts = parseString( layer "/")
		subclass = cadr( parts)
		
		return( subclass)
	)
)

procedure( get_clinesegs_in_degree_Derek02262021( min_degree)
	; clineseg_pair = axlGetSelSet()
	prog( ( clineseg_pair_ls clineseg1_id clineseg2_id start_end1 start_end2 degree netname subclass clineseg2_stru clineseg2_stru_ls)
		clineseg_pair_ls = get_clineseg_pairs_on_board_Derek02262021()
		
		foreach( clineseg_pair clineseg_pair_ls
			clineseg1_id = car( clineseg_pair)
			clineseg2_id = cadr( clineseg_pair)
			
			start_end1 = clineseg1_id->startEnd
			start_end2 = clineseg2_id->startEnd
			
			degree = get_degree_between_2lines_Derek02262021( start_end1 start_end2)
			;println( list( degree start_end1 start_end2))
			when( degree <= min_degree
				netname = clineseg1_id->net->name
				subclass = get_subclass_by_layer_Derek02262021( clineseg1_id->layer)
				
				clineseg2_stru = make_clineseg2_struct( ?netname netname
													?layer subclass 
													?start_end1 start_end1 
													?start_end2 start_end2 
													?degree degree)
				clineseg2_stru_ls = append1( clineseg2_stru_ls clineseg2_stru)
			)
		)
		
		return( clineseg2_stru_ls)
	)
)

procedure( write_log_Derek02262021( clineseg2_stru_ls clineseg_degree)
	prog( ( out_port)
		out_port = outfile( _check_90degree_route_logname "w")
		unless( outportp( out_port)
			println( "ERROR: write_log() - Fail to write file")
			return( nil)
		)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: Check whether the degree of 2 connected cline segments are less or equal to following degree\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=================================================================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Standard degree: %f\n" clineseg_degree)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=================================================================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Incorrect cline segment pair data:\n\n")
		format = "%-30s,%-10s,%-8s,%-50s,%s\n"
		fprintf( out_port format "Netname" "Layer" "Degree" "Line1" "Line2")
		foreach( clineseg2_stru clineseg2_stru_ls
			netname = clineseg2_stru->netname || ""
			layer = clineseg2_stru->layer || ""
			sprintf( degree "%.2f" clineseg2_stru->degree)
			sprintf( start_end1 "%L" clineseg2_stru->start_end1)
			sprintf( start_end2 "%L" clineseg2_stru->start_end2)
			
			fprintf( out_port format netname layer degree start_end1 start_end2)
		)
		
		fprintf( out_port "\n\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( check_90degree_route_main_Derek02262021()
	prog( ()
		unless( axlOKToProceed() (println "Please done current function to use this program") (return nil))
		;;
		init_Derek02262021()
		
		;;;;;
		clineseg_degree = _default_clineseg_degree
		
		;;;;;
		clineseg2_stru_ls = get_clinesegs_in_degree_Derek02262021( clineseg_degree)
		
		;;;;;
		write_log_Derek02262021( clineseg2_stru_ls clineseg_degree)
		
		axlUIViewFileCreate( _check_90degree_route_logname "Check 90 Degree Route Report" nil)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_90degree_route" 'check_90degree_route_main_Derek02262021)
; (check_90degree_route_main_Derek02262021)
; skill encrypt( "C:/skill/check_90degree_route_v1.il" "C:/skill/check_90degree_route_v1.ile")
; (load "check_90degree_route_v1.ile")
; (load "check_90degree_route_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup