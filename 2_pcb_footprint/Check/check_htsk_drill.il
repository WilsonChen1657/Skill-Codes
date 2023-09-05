/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/11/11                                                      #
#  Reference: locker, utility_program, footprint_utility_program               #
#  Purpose:                                                                    #
#       To check HTSK (drill) symbols                                          #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkhtskdrill()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram( t)
	setq( _check_htsk_drill_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkhtskdrill()
	prog( ( log_info out_port)
		Init_checkhtskdrill()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_htsk_drill_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_htsk_drill_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check HTSK (drill) symbols are created according to SOP\n")
		fprintf( out_port "\n\n")
		fprintf( out_port "DFA_DEV_CLASS: %s\n" GetDfaDevClass_footprintutilityprogram())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Manual check: ")
		fprintf( out_port "1. Pad size\n")
		fprintf( out_port "%-14s2.ASSEMBLY_TOP body size\n" "")
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
		
		Check_checkhtskdrill( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_htsk_drill_logname "Check HTSK (drill) report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkhtskdrill( out_port)
	let( ( visible_ls pin_ls layer_ls)
		visible_ls = axlVisibleGet()
		pin_ls = axlDBGetDesign()->pins
		one_mm_to_mils = axlMKSConvert( 1 "MM" "MILS")
		fprintf( out_port "1.")
		CheckPkgAssemblyTop_footprintutilityprogram( out_port)
		fprintf( out_port "2.")
		CheckPkgSilkscreenTop_footprintutilityprogram( out_port)
		fprintf( out_port "3.")
		CheckPkgPlaceBoundTop_footprintutilityprogram( out_port)
		
		fprintf( out_port "4.Check Shape on pin on %s\n" _layer_rte_ko_a)
		fprintf( out_port "* Pin should have shape on %s (size: pin expand 12 mils on each side)\n\n" _layer_rte_ko_a)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_ls _layer_rte_ko_a ?expand_mils 12)
		
		fprintf( out_port "5.Check Shape on pin on %s\n" _layer_rte_ko_b)
		fprintf( out_port "* Pin should have shape on %s (size: pin expand 1 mm on each side)\n\n" _layer_rte_ko_b)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_ls _layer_rte_ko_b ?expand_mils one_mm_to_mils)
		
		fprintf( out_port "6.Check Shape on pin on %s\n" _layer_pkg_ko_b)
		fprintf( out_port "* Pin should have shape on %s (size: pin expand 1 mm on each side)\n\n" _layer_pkg_ko_b)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_ls _layer_pkg_ko_b ?expand_mils one_mm_to_mils)
		
		fprintf( out_port "7.")
		CheckPin1Mark_footprintutilityprogram( out_port)
		fprintf( out_port "8.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "9.")
		CheckNote_footprintutilityprogram( out_port)
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_htsk_drill" 'Main_checkhtskdrill)
/*
(encrypt "c:/skill/check_htsk_drill_v1d1.il" "c:/skill/check_htsk_drill_v1d1.ile")
(load "check_htsk_drill_v1d1.il")
(load "check_htsk_drill_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup