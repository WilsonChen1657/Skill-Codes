;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 06032020 - _Derek06032020
;Introduction:
;	1. restore the DRC mode by the function in "setup board init"
;	2. run DB check upon fulll options
;	3. display display>status
;	4. run Summary Drawing and Dangle Line Reports
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; globle variable

procedure( init_Derek06032020()
	setq( _dangling_lines_rptname "dangling_lines.rpt")
	setq( _sym_rep_rptname "sum_rep.rpt")
	setq( _netLoop_rep_rptname "netLoop_rep.rpt")
	setq( _symbol_library_path_rptname "slp_rep.rpt")
	
	setq( _default_board_init_addr "W:/footprint_building_aid_skill/1-0_Setup_Board_Init/board_init_vDerek.xlsx")
	
	;;;;;
	;;;;; get last board init data
	setq( _default_board_init_path "W:/footprint_building_aid_skill/1-0_Setup_Board_Init/")
	;setq( _default_board_init_path "D:/flex_program_define_by_Derek/document/")
	setq( _default_board_init_file_pattern "^board_init_vDerek-\\([0-9]+\\).xlsx")
	setq( _default_board_init_filename nil)
	setq( _default_board_init_addr nil)
	get_default_board_init_addr_Derek06032020()
	
	
	;;;;; log directory
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _now_time "%d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	
	sprintf( _db_rpt_filename "check_db-%s.rpt" _now_time)
	sprintf( _draw_rpt_filename "check_draw-%s.rpt" _now_time)
	sprintf( _dangling_rpt_filename "check_dangling-%s.rpt" _now_time)
	sprintf( _netloop_rpt_filename "check_netloop-%s.rpt" _now_time)
	sprintf( _symbol_library_path_rpt_filename "check_symbol_library_path-%s.rpt" _now_time)
	
	sprintf( _check_db_rptname "%s/%s" _log_dir _db_rpt_filename)
	sprintf( _check_draw_rptname "%s/%s" _log_dir _draw_rpt_filename)
	sprintf( _check_dangling_rptname "%s/%s" _log_dir _dangling_rpt_filename)
	sprintf( _check_netloop_rptname "%s/%s" _log_dir _netloop_rpt_filename)
	sprintf( _check_symbol_library_path_rptname "%s/%s" _log_dir _symbol_library_path_rpt_filename)
)

procedure( get_default_board_init_addr_Derek06032020()
	let( (file_ls date_file_ls)
		file_ls = getDirFiles( _default_board_init_path)
		
		rexCompile( _default_board_init_file_pattern)
		foreach( file_name file_ls
			when( rexExecute( file_name)
				date = atoi( rexSubstitute( "\\1"))
				date_file_ls = append1( date_file_ls list( date file_name))
			)
		)
		unless( dtpr( date_file_ls) printf( "ERROR: Fail to find file at %s%s\n" _default_board_init_path _default_board_init_file_pattern) return( nil))
		
		date_file_ls = sortcar( date_file_ls 'greaterp)
		_default_board_init_filename = cadar( date_file_ls)
		_default_board_init_addr = strcat( _default_board_init_path _default_board_init_filename)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of globle variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( run_db_check_Derek06032020()
	prog( ( out_port)
		out_port = outfile( _check_db_rptname "w")
		unless( outportp( out_port) printf( "ERROR: run_db_check() - Fail to write file: %s\n" _check_db_rptname) return( nil))
		
		err_warn = axlDBCheck( '(general all shapes log) out_port)
		close( out_port)
		
		axlUIViewFileCreate( _check_db_rptname "DB Check Report" nil)
		
		
		return( t)
	)
)

procedure( run_report_Derek06032020( title cmd_format report_name report_log_name @optional (on_html nil))
	let( ( cmd result)
		html_option = if( on_html " -H" "")
		sprintf( cmd "report -v%s %s %s" html_option cmd_format axlCurrentDesign())
		result = axlRunBatchDBProgram( "report" cmd ?silent t)
		
		if( isFile( report_name) then
			axlUIViewFileCreate( report_name title nil)
			axlOSFileCopy( report_name report_log_name nil)
		else
			sprintf( message "Fail to create %s" title)
			axlUIConfirm( message)
		)
	)
)

procedure( check_report_main_Derek06032020()
	prog( ( message)
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		
		printf( "\n**********************************Start of check DRC DB status***********************************************\n\n")
		
		;;;;; init
		init_Derek06032020()
		
		;;;;; check the validation of the function
		if( isFile( _default_board_init_addr) then
			printf( "INFO: Board init reference: %L\n" _default_board_init_addr)
		else
			sprintf( message "Fail to find following file. Please reconnect Driver or put the file back before using this function: %s. Would you like to keep continue?"
					_default_board_init_addr)
			unless( axlUIYesNo( message) return( nil))
		)
		unless( isCallable( 'setup_board_init_main_Derek06062019) println( "Please load 'Setup Board init' before using this function") return( nil))
		;;
		
		;;;;; 
		when( isFile( _default_board_init_addr)
			printf( " ******* Setting DRC mode per default setting in \"init Board\" Tool......\n")
			result = setup_board_init_main_Derek06062019( ?board_init_xlsx_addr _default_board_init_addr ?init_options list( 'am))
			unless( result println( "ERROR: check_DRC_DB_status_main() - Fail to execute 'setup_board_init'. Exit the function") return( nil))
		)
		
		printf( " ******* Running DB Check *******\n")
		run_db_check_Derek06032020()
		
		printf( " ******* Opening Status *******\n")
		axlShell( "status")
		
		run_report_Derek06032020( "Dangling Lines Report" "sum" _dangling_lines_rptname _check_dangling_rptname)
		run_report_Derek06032020( "Summary Drawing Report" "sum" _sym_rep_rptname _check_draw_rptname)
		run_report_Derek06032020( "Net Loop Report" "netloop" _netLoop_rep_rptname _check_netloop_rptname)
		run_report_Derek06032020( "Symbol Library Path Report" "slp" _symbol_library_path_rptname _check_symbol_library_path_rptname)
		
		printf( "\n************************************End of check Report***********************************************\n\n")
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup
;(load "manipulate_xlsx_v3.ile")
; (load "setup_board_init_v2d7.il")

(axlCmdRegister "check_report" 'check_report_main_Derek06032020)
; (check_report_main_Derek06032020)
; skill encrypt( "C:/skill/check_report_v1.il" "C:/skill/check_report_v1.ile")
; (load "check_report_v1.il")
; (load "check_report_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup