;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 9/28/2020 - _Derek09282020
; Introduction: compare the testpoint between after board and before board
; Data format: net_name/layer/TP_after_name:xy/TP_before_name:xy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek09282020()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	setq( _after_design_name axlCurrentDesign())
	setq( _before_drawing_name nil)
	setq( _before_schematic_name nil)
	
	setq( _before "Before")
	setq( _after "After")
	
	setq( _total_add 0)
	setq( _total_remove 0)
	setq( _total_move 0)
	
	;;;;; log
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _log_filename "compare_testpoint-%s.log" _date_time)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _compare_testpoint_logname "%s/%s" _log_dir _log_filename)
	
	setq( _after_schematic_name get_schematic_name_Derek09282020())
)

procedure( get_schematic_name_Derek09282020()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls (length( s->pins) > 1)))
		unless( sym_id println( "ERROR: get_schematic_name() - Fail to get a symbol") return( nil))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end pof global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function



procedure( get_testpoint_from_net_Derek09282020( net_id)
	prog( ( testpoint_ls total_testpoint_ls)
		foreach( branch net_id->branches
			testpoint_ls = setof( x branch->children stringp( x->testPoint))
			
			when( dtpr( testpoint_ls)
				total_testpoint_ls = append( total_testpoint_ls testpoint_ls)
			)
		)
		
		return( total_testpoint_ls)
	)
)

procedure( get_testpoint_data_Derek09282020( testpoint_id)
	prog( ( subclass testpoint_data)
		; println( testpoint_id->testPoint)
		subclass = cadr( parseString( testpoint_id->testPoint "/"))
		sprintf( testpoint_data "%s,%s,%L" testpoint_id->name subclass testpoint_id->xy)
		
		return( testpoint_data)
	)
)

procedure( parse_testpoint_table_Derek09282020()
	prog( ( testpoint_table net_ls net_name testpoint_ls testpoint_data_ls)
		testpoint_table = makeTable( 'testpoint nil)
		net_ls = setof( x axlDBGetDesign()->nets (x->name != ""))
		
		foreach( net_id net_ls
			net_name = net_id->name
			testpoint_ls = get_testpoint_from_net_Derek09282020( net_id)
			
			when( dtpr( testpoint_ls)
				testpoint_data_ls = mapcar( 'get_testpoint_data_Derek09282020 testpoint_ls)
				testpoint_table[ net_name] = testpoint_data_ls
			)
		)
		
		return( testpoint_table)
	)
)

procedure( open_board_Derek09282020( board_addr)
	let( ()
		printf( "INFO: open_board() - Now is opening board file: %s\n" board_addr)
		axlOpenDesignForBatch( board_addr "wl")
	)
)

procedure( open_before_board_Derek09282020()
	prog( ( title)
		sprintf( title "Please select %s board to compare testpoint position" _before)
		_before_drawing_name = axlDMFileBrowse( "ALLEGRO_LAYOUT_DB" nil ?title title)
		unless( stringp( _before_drawing_name)
			println( "INFO: open_before_board() - No board has been selected")
			return( nil)
		)
		
		open_board_Derek09282020( _before_drawing_name)
		
		_before_schematic_name = get_schematic_name_Derek09282020()
		
		return( t)
	)
)

procedure( remove_duplicated_element_Derek09282020( element_ls)
	prog( ()
		element_ls = maplist( lambda( (xs) if( exists( x cdr( xs) car( xs) == x) nil car( xs))) element_ls)
		element_ls = remq( nil element_ls)
		
		return( element_ls)
	)
)

procedure( get_symmetric_difference_Derek09282020( ele_a_ls ele_b_ls)
	prog( ( or_ele_ls and_ele_ls and_not_ele_ls)
		or_ele_ls = remove_duplicated_element_Derek09282020( append( ele_a_ls ele_b_ls))
		and_ele_ls = setof( a ele_a_ls exists( b ele_b_ls a == b))
		and_not_ele_ls = setof( a or_ele_ls !exists( b and_ele_ls a == b))
		
		return( and_not_ele_ls)
	)
)

procedure( compare_testpoint_data_Derek09282020( after_tp_table before_tp_table)
	prog( ( compare_table total_net_ls after_tp_data_ls before_tp_data_ls difference_ls)
		compare_table = makeTable( 'compare nil)
		
		total_net_ls = append( after_tp_table->? before_tp_table->?)
		total_net_ls = remove_duplicated_element_Derek09282020( total_net_ls)
		
		foreach( net_name total_net_ls
			after_tp_data_ls = after_tp_table[ net_name]
			before_tp_data_ls = before_tp_table[ net_name]
			
			difference_ls = get_symmetric_difference_Derek09282020( after_tp_data_ls before_tp_data_ls)
			when( dtpr( difference_ls)
				after_different_tp_data_ls = setof( a after_tp_data_ls exists( b difference_ls a == b))
				before_different_tp_data_ls = setof( a before_tp_data_ls exists( b difference_ls a == b))
				compare_table[ net_name] = list( after_different_tp_data_ls before_different_tp_data_ls)
			)
		)
		
		return( compare_table)
	)
)

procedure( get_log_data_Derek09282020( testpoint_data)
	prog( ()
		if( stringp( testpoint_data) then
			testpoint_data_part_ls = axlStringCSVParse( testpoint_data)
			log_data = apply( 'lsprintf "%-15s:%-6s:%-20s" testpoint_data_part_ls)
		else
			log_data = "nil"
		)
		
		return( log_data)
	)
)

procedure( get_testpoint_compare_data_Derek09282020( compare_tp_table)
	prog( ( add_ls remove_ls move_ls testpoint_different_data_ls compare_string compare_string_ls)
		;;;;; get add dataset
		
		foreach( net_name compare_tp_table
			after_different_tp_data_ls = mapcar( 'get_log_data_Derek09282020 car( compare_tp_table[ net_name]))
			before_different_tp_data_ls = mapcar( 'get_log_data_Derek09282020 cadr( compare_tp_table[ net_name]))
			
			before_different_tp_data_ls = sort( before_different_tp_data_ls !'alphalessp)
			after_different_tp_data_ls = sort( after_different_tp_data_ls !'alphalessp)
			
			sprintf( compare_string "[%s]\n\t%-6s: %L\n\t%-6s: %L"
					net_name _before before_different_tp_data_ls _after after_different_tp_data_ls)
			
			cond(
				( null( before_different_tp_data_ls) && dtpr( after_different_tp_data_ls)
					add_ls = append1( add_ls compare_string)
				)
				( dtpr( before_different_tp_data_ls) && null( after_different_tp_data_ls)
					remove_ls = append1( remove_ls compare_string)
				)
				( t
					move_ls = append1( move_ls compare_string)
				)
			)
		)
		
		compare_string_ls = append1( compare_string_ls
									 "\n************************************************************************************************* ADD\n")
		compare_string_ls = append( compare_string_ls add_ls)
		_total_add = length( add_ls)
		
		compare_string_ls = append1( compare_string_ls
									 "\n************************************************************************************************* REMOVE\n")
		compare_string_ls = append( compare_string_ls remove_ls)
		_total_remove = length( remove_ls)
		
		compare_string_ls = append1( compare_string_ls
									 "\n************************************************************************************************* MOVE\n")
		compare_string_ls = append( compare_string_ls move_ls)
		_total_move = length( move_ls)
		
		return( compare_string_ls)
	)
)

procedure( write_log_Derek09282020( compare_string_ls after_tp_amount before_tp_amount similarity_rate)
	prog( ()
		out_port = outfile( _compare_testpoint_logname "w")
		unless( outportp( out_port)
			printf( "ERROR: write_log() - Fail to write log file: %s\n" _compare_testpoint_logname)
			return( nil)
		)
		
		fprintf( out_port "%s board file name: %s\n" _before _before_drawing_name)
		fprintf( out_port "%s schematic name: %s\n\n" _before _before_schematic_name)
		
		fprintf( out_port "%s board file name: %s\n" _after axlGetDrawingName())
		fprintf( out_port "%s schematic name: %s\n\n" _after _after_schematic_name)
		
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction:\n")
		fprintf( out_port "\tThis log is mainly to compare the position of the testpoint\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Summary:\n")
		fprintf( out_port "\t%-40s: %s\n\n" "Unit" _allegro_unit)
		
		sprintf( string "%s board's testpoint amount" _before)
		fprintf( out_port "\t%-40s: %d\n" string before_tp_amount)
		sprintf( string "%s board's testpoint amount" _after)
		fprintf( out_port "\t%-40s: %d\n\n" string after_tp_amount)
		
		fprintf( out_port "\t%-40s: %d\n" "Differentiation Amount" _total_add + _total_remove + _total_move)
		fprintf( out_port "\t%-40s: %d\n" "        Total ADD" _total_add)
		fprintf( out_port "\t%-40s: %d\n" "        Total REMOVE" _total_remove)
		fprintf( out_port "\t%-40s: %d\n\n" "        Total MOVE" _total_move)
		
		fprintf( out_port "\t%-40s: %.2f%%\n" "Similarity Rate" similarity_rate)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "\nThe differentiation of testpoint position is below:\n")
		
		fprintf( out_port "\n")
		
		fprintf( out_port "[<Net Name>]\n\t<Board Tag>: (<Testpoint Name>:<Layer>:<Position>...)\n")
		
		fprintf( out_port "\n")
		
		foreach( compare_string compare_string_ls
			fprintf( out_port "%s\n" compare_string)
		)
		
		fprintf( out_port "\n\n")
		
		close( out_port)
	)
)

procedure( get_similarity_rate_Derek09282020( after_tp_table before_tp_table compare_tp_table)
	prog( ( total different similarity_rate)
		total = length( remove_duplicated_element_Derek09282020( append( after_tp_table->? before_tp_table->?)))
		different = total - length( compare_tp_table->?)
		similarity_rate = float( different) / total * 100
		
		return( similarity_rate)
	)
)

procedure( compare_testpoint_main_Derek09282020()
	prog( ()
		unless( axlOKToProceed() println( "Please done after command to use this function") return( nil))
		;;
		
		init_Derek09282020()
		
		;;;;; get after testpoint data
		after_tp_table = parse_testpoint_table_Derek09282020()
		;foreach( net_name after_tp_table printf( "[%s]: %d\n" net_name length( after_tp_table[net_name])))
		
		;;;;; get before testpoint data
		unless( open_before_board_Derek09282020() return( nil))
		before_tp_table = parse_testpoint_table_Derek09282020()
		
		;;;;; go back to after board
		open_board_Derek09282020( _after_design_name)
		
		;;;;; compare the data
		compare_tp_table = compare_testpoint_data_Derek09282020( after_tp_table before_tp_table)
		
		;;;;; write log
		compare_string_ls = get_testpoint_compare_data_Derek09282020( compare_tp_table)
		similarity_rate = get_similarity_rate_Derek09282020( after_tp_table before_tp_table compare_tp_table)
		write_log_Derek09282020( compare_string_ls length( after_tp_table->?) length( before_tp_table->?) similarity_rate)
		
		;;;;; display log file
		axlUIViewFileCreate( _compare_testpoint_logname "Compare Testpoint Report" nil)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "compare_testpoint" 'compare_testpoint_main_Derek09282020)
; (compare_testpoint_main_Derek09282020)
; skill encrypt( "C:/skill/compare_testpoint_v1.il" "C:/skill/compare_testpoint_v1.ile")
; (load "compare_testpoint_v1.il")
; (load "compare_testpoint_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup