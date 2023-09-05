;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 9/29/2020 - _Derek09292020
; Introduction: compare the symbol between after board and before board
; Data format: net_name/layer/TP_after_name:xy/TP_before_name:xy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek09292020()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	setq( _after_design_name axlCurrentDesign())
	setq( _before_drawing_name nil)
	setq( _before_schematic_name nil)
	
	setq( _before "Before")
	setq( _after "After")
	
	setq( _total_add 0)
	setq( _total_remove 0)
	setq( _total_move 0)
	setq( _total_change 0)
	
	;;;;; log
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _log_filename "compare_symbol-%s.log" _date_time)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _compare_symbol_logname "%s/%s" _log_dir _log_filename)
	
	setq( _after_schematic_name get_schematic_name_Derek09292020())
)

procedure( get_schematic_name_Derek09292020()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( x sym_ls (length( x->pins) > 1 && x->component->functions)))
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

procedure( parse_symbol_table_Derek09292020()
	prog( ( symbol_table net_ls net_name testpoint_ls testpoint_data_ls)
		symbol_table = makeTable( 'symbol_table nil)
		sym_ls = setof( x axlDBGetDesign()->symbols x->refdes)
		
		foreach( sym_id sym_ls
			sprintf( sym_data "%s,%s,%.1f,%L" sym_id->name sym_id->layer sym_id->rotation sym_id->xy)
			symbol_table[ sym_id->refdes] = sym_data
		)
		
		return( symbol_table)
	)
)

procedure( open_board_Derek09292020( board_addr)
	let( ()
		printf( "INFO: open_board() - Now is opening board file: %s\n" board_addr)
		axlOpenDesignForBatch( board_addr "wl")
	)
)

procedure( open_before_board_Derek09292020()
	prog( ()
		sprintf( title "Please select %s board to compare testpoint position" _before)
		_before_drawing_name = axlDMFileBrowse( "ALLEGRO_LAYOUT_DB" nil ?title title)
		unless( stringp( _before_drawing_name)
			println( "INFO: open_before_board() - No board has been selected")
			return( nil)
		)
		
		open_board_Derek09292020( _before_drawing_name)
		
		_before_schematic_name = get_schematic_name_Derek09292020()
		
		return( t)
	)
)

procedure( remove_duplicated_element_Derek09292020( element_ls)
	prog( ()
		element_ls = maplist( lambda( (xs) if( exists( x cdr( xs) car( xs) == x) nil car( xs))) element_ls)
		element_ls = remq( nil element_ls)
		
		return( element_ls)
	)
)

procedure( compare_sym_data_Derek09292020( after_sym_table before_sym_table)
	prog( ( compare_sym_table total_refdes_ls after_sym_data_ls before_sym_data_ls difference_ls)
		compare_sym_table = makeTable( 'compare_sym nil)
		
		total_refdes_ls = append( after_sym_table->? before_sym_table->?)
		total_refdes_ls = remove_duplicated_element_Derek09292020( total_refdes_ls)
		
		foreach( refdes total_refdes_ls
			after_sym_data = after_sym_table[ refdes]
			before_sym_data = before_sym_table[ refdes]
			
			unless( after_sym_data == before_sym_data
				compare_sym_table[ refdes] = list( after_sym_data before_sym_data)
			)
		)
		
		return( compare_sym_table)
	)
)

procedure( compare_sym_name_data_Derek09292020( a_data b_data)
	prog( ( a_name b_name)
		a_name = car( axlStringCSVParse( a_data))
		b_name = car( axlStringCSVParse( b_data))
		
		return( a_name == b_name)
	)
)

procedure( get_log_data_Derek09292020( sym_data)
	prog( ( sym_data_part_ls log_data)
		if( stringp( sym_data) then
			sym_data_part_ls = axlStringCSVParse( sym_data)
			log_data = apply( 'lsprintf "%-15s:%-6s:%-5s:%s" sym_data_part_ls)
		else
			log_data = "nil"
		)
		
		return( log_data)
	)
)

procedure( get_sym_compare_data_Derek09292020( compare_sym_table)
	prog( ( add_ls remove_ls move_ls change_ls testpoint_different_data_ls compare_string compare_string_ls)
		foreach( refdes compare_sym_table
			after_different_sym_data = car( compare_sym_table[ refdes])
			before_different_sym_data = cadr( compare_sym_table[ refdes])
			
			after_log_data = get_log_data_Derek09292020( car( compare_sym_table[ refdes]))
			before_log_data = get_log_data_Derek09292020( cadr( compare_sym_table[ refdes]))
			sprintf( compare_string "[%s]\n\t%-6s: %s\n\t%-6s: %s"
					refdes _before before_log_data _after after_log_data)
			
			cond(
				(  !stringp( before_different_sym_data) && stringp( after_different_sym_data)
					add_ls = append1( add_ls compare_string)
				)
				(  stringp( before_different_sym_data) && !stringp( after_different_sym_data)
					remove_ls = append1( remove_ls compare_string)
				)
				( compare_sym_name_data_Derek09292020( before_different_sym_data after_different_sym_data)
					move_ls = append1( move_ls compare_string)
				)
				( t
					change_ls = append1( change_ls compare_string)
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
		
		compare_string_ls = append1( compare_string_ls
									 "\n************************************************************************************************* CHANGE\n")
		compare_string_ls = append( compare_string_ls change_ls)
		_total_change = length( change_ls)
		
		return( compare_string_ls)
	)
)

procedure( write_log_Derek09292020( compare_string_ls after_sym_amount before_sym_amount similarity_rate)
	prog( ()
		out_port = outfile( _compare_symbol_logname "w")
		unless( outportp( out_port)
			printf( "ERROR: write_log() - Fail to write log file: %s\n" _compare_symbol_logname)
			return( nil)
		)
		
		fprintf( out_port "%s board file name: %s\n" _before _before_drawing_name)
		fprintf( out_port "%s schematic name: %s\n\n" _before _before_schematic_name)
		
		fprintf( out_port "%s board file name: %s\n" _after axlGetDrawingName())
		fprintf( out_port "%s schematic name: %s\n\n" _after _after_schematic_name)
		
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction:\n")
		fprintf( out_port "\tThis log is mainly to compare the position of the reference designation(refdes)\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Summary:\n")
		fprintf( out_port "\t%-40s: %s\n\n" "Unit" _allegro_unit)
		
		sprintf( string "%s board's symbol amount" _before)
		fprintf( out_port "\t%-40s: %d\n" string before_sym_amount)
		sprintf( string "%s board's symbol amount" _after)
		fprintf( out_port "\t%-40s: %d\n\n" string after_sym_amount)
		
		fprintf( out_port "\t%-40s: %d\n" "Differentiation Amount" _total_add + _total_remove + _total_move + _total_change)
		fprintf( out_port "\t%-40s: %d\n" "        Total ADD" _total_add)
		fprintf( out_port "\t%-40s: %d\n" "        Total REMOVE" _total_remove)
		fprintf( out_port "\t%-40s: %d\n" "        Total MOVE" _total_move)
		fprintf( out_port "\t%-40s: %d\n\n" "        Total CHANGE" _total_change)
		
		fprintf( out_port "\t%-40s: %.2f%%\n" "Similarity Rate" similarity_rate)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "The differentiation of symbol position is below:\n")
		
		fprintf( out_port "\n")
		
		fprintf( out_port "[<Refdes>]\n\t<Board Tag>: <Symbol Name>:<Layer>:<Rotation>:<Position>\n")
		
		fprintf( out_port "\n")
		
		foreach( compare_string compare_string_ls
			fprintf( out_port "%s\n" compare_string)
		)
		
		fprintf( out_port "\n\n")
		
		close( out_port)
	)
)

procedure( get_similarity_rate_Derek09292020( after_sym_table before_sym_table compare_sym_table)
	prog( ( total different similarity_rate)
		total = length( remove_duplicated_element_Derek09292020( append( after_sym_table->? before_sym_table->?)))
		different = total - length( compare_sym_table->?)
		similarity_rate = float( different) / total * 100
		
		return( similarity_rate)
	)
)

procedure( compare_symbol_main_Derek09292020()
	prog( ()
		unless( axlOKToProceed() println( "Please done after command to use this function") return( nil))
		;;
		
		init_Derek09292020()
		
		;;;;; get after testpoint data
		after_sym_table = parse_symbol_table_Derek09292020()
		;foreach( net_name after_sym_table printf( "[%s]: %d\n" net_name length( after_sym_table[net_name])))
		
		;;;;; get before testpoint data
		unless( open_before_board_Derek09292020() return( nil))
		before_sym_table = parse_symbol_table_Derek09292020()
		
		;;;;; go back to after board
		open_board_Derek09292020( _after_design_name)
		
		;;;;; compare the data
		compare_sym_table = compare_sym_data_Derek09292020( after_sym_table before_sym_table)
		
		;;;;; write log
		compare_string_ls = get_sym_compare_data_Derek09292020( compare_sym_table)
		similarity_rate = get_similarity_rate_Derek09292020( after_sym_table
														before_sym_table
														compare_sym_table)
		write_log_Derek09292020( compare_string_ls
								 length( after_sym_table->?)
								 length( before_sym_table->?)
								 similarity_rate)
		
		;;;;; display log file
		axlUIViewFileCreate( _compare_symbol_logname "Compare Testpoint Report" nil)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "compare_symbol" 'compare_symbol_main_Derek09292020)
; (compare_symbol_main_Derek09292020)
; skill encrypt( "C:/skill/compare_symbol_v1.il" "C:/skill/compare_symbol_v1.ile")
; (load "compare_symbol_v1.il")
; (load "compare_symbol_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup