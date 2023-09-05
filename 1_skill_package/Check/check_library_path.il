;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; description
;
; Developer: Derek Hsu
; Starting date: 2/24/2021 - _Derek02242021
; Description:
;	1. Check the reference of via and symbol
;		1. trial: symbol_id->definition->prop->LIBRARY_PATH
;		2. trial: via_id->definition->prop->LIBRARY_PATH
;	2. let user input the default reference, unlimited string length
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of description

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init_Derek02242021()
	;;;;;
	setq( _default_lib_path_ls list( "W:/Library-Flex"))
	setq( _default_lib_path_example_ls list( "W:/Library-Flex" "W:/Library-Special"))
	setq( _lib_path_ls nil)
	
	;;;;; define slot
	defstruct( sym_struct refdes name lib_path layer xy)
	defstruct( via_struct name lib_path xy)
	
	;;;;; log
	setq( _log_var_key "ads_sdlog")
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _log_filename "check_library_path-%s.log" _date_time)
	unless( axlGetVariable( _log_var_key) axlSetVariable( _log_var_key "log"))
	setq( _log_dir (axlGetVariable( _log_var_key) || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _check_library_path_logname "%s/%s" _log_dir _log_filename)
	setq( _schematic_name get_schematic_name_Derek02242021())
)

procedure( get_schematic_name_Derek02242021()
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

procedure( get_symbol_lib_path_Derek02242021()
	prog( ( sym_ls refdes lib_path sym_stru sym_stru_ls)
		sym_ls = axlDBGetDesign()->symbols
		
		foreach( sym_id sym_ls
			refdes = sym_id->refdes
			name = sym_id->name
			lib_path = sym_id->definition->prop->LIBRARY_PATH
			sym_stru = make_sym_struct( ?refdes refdes ?name name ?lib_path lib_path ?layer sym_id->layer ?xy sym_id->xy)
			
			sym_stru_ls = append1( sym_stru_ls sym_stru)
		)
		
		return( sym_stru_ls)
	)
)

procedure( get_vias_on_net_Derek02242021( net_id)
	prog( ( children via_ls)
		foreach( branch net_id->branches
			children = append( children branch->children)
		)
		
		via_ls = setof( x children x->objType == "via")
		
		return( via_ls)
	)
)

procedure( get_vias_on_board_Derek02242021()
	prog( (net_ls via_ls all_via_ls)
		net_ls = axlDBGetDesign()->nets
		
		foreach( net_id net_ls
			via_ls = get_vias_on_net_Derek02242021( net_id)
			all_via_ls = append( all_via_ls via_ls)
		)
		
		return( all_via_ls)
	)
)

procedure( get_via_lib_path_Derek02242021()
	prog( ( via_ls name lib_path via_stru via_stru_ls)
		via_ls = get_vias_on_board_Derek02242021()
		
		foreach( via_id via_ls
			name = via_id->name
			lib_path = via_id->definition->prop->LIBRARY_PATH
			via_stru = make_via_struct( ?name name ?lib_path lib_path ?xy via_id->xy)
			
			via_stru_ls = append1( via_stru_ls via_stru)
		)
		
		return( via_stru_ls)
	)
)

procedure( is_correct_path_Derek02242021( lib_path_ls object)
	prog( ( lib_path result)
		lib_path = object->lib_path
		unless( stringp( lib_path) return( nil))
		
		result = dtpr( exists( x lib_path_ls index( lib_path x)))
		
		return( result)
	)
)

procedure( write_log_Derek02242021( lib_path_ls sym_stru_ls via_stru_ls)
	prog( ( out_port)
		out_port = outfile( _check_library_path_logname "w")
		unless( outportp( out_port)
			println( "ERROR: write_log() - Fail to write a log file")
			return( nil)
		)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: Check whether symbols and vias's library path are correct\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=================================================================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Correct Path Term:\n")
		foreach( path lib_path_ls
			fprintf( out_port "\t%s\n" path)
		)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=================================================================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Summary\n")
		fprintf( out_port "\tAll missing-place %-6s: %d\n" "symbol" length( sym_stru_ls))
		fprintf( out_port "\tAll missing-place %-6s: %d\n" "via" length( via_stru_ls))
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=================================================================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		fprintf( out_port "Symbol Data\n\n")
		format = "%-20s,%-40s,%-7s,%-25s,%s\n"
		fprintf( out_port format "Refdes" "Name" "Layer" "xy" "Lib_Path")
		unless( sym_stru_ls
			fprintf( out_port format "None" "None" "None" "None" "None")
		)
		foreach( sym_stru sym_stru_ls
			sprintf( xy "%L" sym_stru->xy)
			refdes = sym_stru->refdes || ""
			lib_path = sym_stru->lib_path || ""
			fprintf( out_port format refdes sym_stru->name sym_stru->layer xy lib_path)
		)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Via Data\n\n")
		format = "%-30s,%-25s,%s\n"
		fprintf( out_port format "Name" "xy" "Lib_Path")
		unless( via_stru_ls
			fprintf( out_port format "None" "None" "None")
		)
		foreach( via_stru via_stru_ls
			sprintf( xy "%L" via_stru->xy)
			lib_path = via_stru->lib_path || ""
			fprintf( out_port format via_stru->name xy lib_path)
		)
		
		fprintf( out_port "\n\n")
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		close( out_port)
	)
)

procedure( enter_correct_lib_path_Derek02242021()
	prog( ( lib_path_example lib_path lib_path_ls)
		lib_path_example = buildString( _default_lib_path_example_ls ",")
		
		sprintf( message "Library path, divide by Comma. ex: %s" lib_path_example)
		lib_path = axlEnterString( ?prompts message)
		unless( lib_path return( nil))
		
		if( lib_path == "" then
			lib_path_ls = _default_lib_path_ls
		else
			lib_path_ls = parseString( lib_path ",")
		)
		
		return( lib_path_ls)
	)
)

procedure( unify_struct_by_name_Derek02242021( struct_ls)
	prog( ()
		struct_ls = maplist( lambda( (xs) unless( member( car( xs)->name cdr( xs)~>name) car( xs))) struct_ls)
		struct_ls = remq( nil struct_ls)
		
		return( struct_ls)
	)
)

procedure( get_incorrect_lib_path_structures( struct_ls lib_path_ls)
	prog( ()
		struct_ls = setof( x struct_ls !is_correct_path_Derek02242021( lib_path_ls x))
		struct_ls = unify_struct_by_name_Derek02242021( struct_ls)
		
		return( struct_ls)
	)
)

procedure( check_library_path_main_Derek02242021()
	prog( ()
		unless( axlOKToProceed() (println "Please done current function to use this program") (return nil))
		;;
		init_Derek02242021()
		
		lib_path_ls = enter_correct_lib_path_Derek02242021()
		unless( lib_path_ls return( nil))
		
		sym_stru_ls = get_symbol_lib_path_Derek02242021()
		via_stru_ls = get_via_lib_path_Derek02242021()
		
		;;;;; filter out the correct object with correct library path
		sym_stru_ls = get_incorrect_lib_path_structures( sym_stru_ls lib_path_ls)
		via_stru_ls = get_incorrect_lib_path_structures( via_stru_ls lib_path_ls)
		
		;;;;;
		write_log_Derek02242021( lib_path_ls sym_stru_ls via_stru_ls)
		
		axlUIViewFileCreate( _check_library_path_logname "Check Library Path Report" nil)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_library_path" 'check_library_path_main_Derek02242021)
; (check_library_path_main_Derek02242021)
; skill encrypt( "C:/skill/check_library_path_v1.il" "C:/skill/check_library_path_v1.ile")
; (load "check_library_path_v1.ile")
; (load "check_library_path_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup