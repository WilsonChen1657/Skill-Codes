;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 10/5/2020 = _Derek10052020
; Introduction: group/ungroup symbols by page. Single symbol may be engaged into more than a group if it's over pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init_Derek10052020()
	setq( _page_group_format "SCHEMATIC_PAGE:%d")
	setq( _page_group_regex "SCHEMATIC_PAGE:[0-9]+")
	setq( _page_regex ":page\\([0-9]+\\)_")
	setq( _board_sym_ls get_symbols_on_board_Derek10052020())
)

procedure( get_symbols_on_board_Derek10052020()
	prog( ()
		sym_ls = setof( x axlDBGetDesign()->symbols stringp( x->refdes))
		
		return( sym_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( remove_duplicate_Derek10052020( data_ls)
	prog( ()
		data_ls = maplist( lambda( (xs) if( exists( x cdr( xs) x == car( xs)) nil car( xs))) data_ls)
		data_ls = remq( nil data_ls)
		
		return( data_ls)
	)
)

procedure( get_pages_from_sym_Derek10052020( sym_id)
	; physicalPath = "@bt_evt_sib_sas3_ee_sch_v41_20191104.bluetail_sib_sas3_sch(sch_1):page48_ins24033300@other.\\m_hole_c.normal\\(chips)"
	prog( ( page_ls physical_path page )
		rexCompile( _page_regex)
		foreach( func sym_id->component->functions
			physical_path = func->prop~>PHYSICAL_PATH
			if( stringp( physical_path) && rexExecute( physical_path) then
				page = rexSubstitute( "\\1")
				page = atoi( page)
				page_ls = append1( page_ls page)
			else
				printf( "WARNING: get_pages_from_sym() - Fail to get physical path from %L\n" list( sym_id->refdes sym_id->xy func->prop~>??))
			)
		)
		
		page_ls = remove_duplicate_Derek10052020( page_ls)
		
		
		return( page_ls)
	)
)

procedure( delete_groups_Derek10052020()
	let( ( group_ls group_name)
		axlDBRefreshId( nil)
		
		group_ls = axlDBGetDesign()->groups
		rexCompile( _page_group_regex)
		foreach( group_id group_ls
			group_name = group_id->name
			when( rexExecute( group_id->name)
				axlDBDisbandGroup( group_id)
			)
		)
		
		axlDBRefreshId( nil)
	)
)

procedure( create_groups_Derek10052020( sym_ls)
	let( ( page_sym_table page_ls )
		page_sym_table = makeTable( 'page_sym nil)
		
		foreach( sym_id sym_ls
			page_ls = get_pages_from_sym_Derek10052020( sym_id)
			
			if( dtpr( page_ls) then
				foreach( page page_ls
					sprintf( group_name _page_group_format page)
					page_sym_table[ group_name] = append1( page_sym_table[ group_name] sym_id)
				)
			else
				printf( "WARNING: No page information has been found on refdes[%L] on %L at %L\n"
					sym_id->refdes sym_id->layer sym_id->xy)
			)
		)
		
		foreach( group_name page_sym_table
			axlDBCreateGroup( group_name "generic" page_sym_table[ group_name])
		)
		
		axlDBRefreshId( nil)
	)
)

procedure( dispatch_process_Derek10052020( option)
	prog( ()
		caseq( option
			( 1
				;; yes to group all symbols
				delete_groups_Derek10052020()
				create_groups_Derek10052020( _board_sym_ls)
				
				print( "INFO: Create group process is done")
			)
			( 0
				;; no to ungroup symbols
				delete_groups_Derek10052020()
				
				printf( "INFO: Delete group process is done")
			)
			( 2
				return( nil)
			)
		)
		
		return( t)
	)
)

procedure( group_symbol_by_page_main_Derek10052020()
	prog( ()
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		;;
		
		init_Derek10052020()
		
		;; yes: 1, no: 0, cancel: 2
		option = axlUIYesNoCancel( "Yes to group symbols by pages. No to ungroup symbols" "Group Symbols Panel" 'yes)
		dispatch_process_Derek10052020( option)
		
		axlUIConfirm( "Process is done")
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "group_symbol_by_page" 'group_symbol_by_page_main_Derek10052020)
; (group_symbol_by_page_main_Derek10052020)
; skill encrypt( "C:/skill/group_symbol_by_page_v1.il" "C:/skill/group_symbol_by_page_v1.ile")
; (load "group_symbol_by_page_v1.il")
; (load "group_symbol_by_page_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup