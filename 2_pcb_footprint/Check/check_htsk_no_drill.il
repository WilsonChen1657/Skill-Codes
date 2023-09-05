/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/11/11                                                      #
#  Reference: locker, utility_program, footprint_utility_program               #
#  Purpose:                                                                    #
#       To check HTSK (no drill) symbols                                       #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkhtsknodrill()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram( t)
	setq( _check_htsk_no_drill_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkhtsknodrill()
	prog( ( log_info out_port)
		Init_checkhtsknodrill()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_htsk_no_drill_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_htsk_no_drill_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check HTSK (no drill) symbols are created according to SOP\n")
		fprintf( out_port "\n\n")
		fprintf( out_port "DFA_DEV_CLASS: %s\n" GetDfaDevClass_footprintutilityprogram())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Manual check: ")
		fprintf( out_port "%-14s2. ASSEMBLY_TOP body size\n" "")
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
		
		Check_checkhtsknodrill( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_htsk_no_drill_logname "Check HTSK (no drill) report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkhtsknodrill( out_port)
	let( ( visible_ls pin_ls layer_ls)
		visible_ls = axlVisibleGet()
		fprintf( out_port "1.")
		CheckPkgAssemblyTop_footprintutilityprogram( out_port)
		fprintf( out_port "2.")
		CheckPkgSilkscreenTop_footprintutilityprogram( out_port)
		fprintf( out_port "3.")
		CheckPkgPlaceBoundTop_footprintutilityprogram( out_port)
		fprintf( out_port "4.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "5.")
		CheckNote_footprintutilityprogram( out_port)
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_htsk_no_drill" 'Main_checkhtsknodrill)
/*
(encrypt "c:/skill/check_htsk_no_drill_v1d1.il" "c:/skill/check_htsk_no_drill_v1d1.ile")
(load "check_htsk_no_drill_v1d1.il")
(load "check_htsk_no_drill_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup