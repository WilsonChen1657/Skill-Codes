/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/31                                                      #
#  Reference: locker, utility_program, footprint_utility_program               #
#  Purpose:                                                                    #
#       To check Screw hole (PTH) symbols                                      #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkscrewholepth()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram( t)
	setq( _check_screw_hole_pth_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkscrewholepth()
	prog( ( log_info out_port)
		Init_checkscrewholepth()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_screw_hole_pth_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_screw_hole_pth_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check Screw hole (PTH) symbols are created according to SOP\n")
		fprintf( out_port "\n\n")
		fprintf( out_port "DFA_DEV_CLASS: %s\n" GetDfaDevClass_footprintutilityprogram())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Manual check: ")
		fprintf( out_port "1. Pad size\n")
		fprintf( out_port "%-14s2. PIN number\n" "")
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
		
		Check_checkscrewholepth( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_screw_hole_pth_logname "Check Screw hole (PTH) report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkscrewholepth( out_port)
	let( ( visible_ls pin_ls layer_ls)
		visible_ls = axlVisibleGet()
		pin_ls = axlDBGetDesign()->pins
		fprintf( out_port "1.Check Shape on pin on %s and %s\n" _layer_pkg_pbt _layer_pkg_pbb)
		fprintf( out_port "* Pin should have shape on %s and %s\n\n" _layer_pkg_pbt _layer_pkg_pbb)
		layer_ls = list( _layer_pkg_pbt _layer_pkg_pbb)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_ls layer_ls)
		
		fprintf( out_port "2.Check Shape on pin on %s and %s\n" _layer_manu_npt _layer_manu_npb)
		fprintf( out_port "* Pin should have shape on %s and %s (size: pin expand 15 mils on each side)\n\n" _layer_manu_npt _layer_manu_npb)
		layer_ls = list( _layer_manu_npt _layer_manu_npb)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_ls layer_ls ?expand_mils 15)
		
		fprintf( out_port "3.Check Shape on pin on %s\n" _layer_pkg_ko_t)
		fprintf( out_port "* Pin should have shape on %s (size: pin expand 200 mils on each side)\n\n" _layer_pkg_ko_t)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_ls _layer_pkg_ko_t ?expand_mils 200)
		
		fprintf( out_port "4.Check Shape on pin on %s\n" _layer_pkg_ko_b)
		fprintf( out_port "* Pin should have shape on %s (size: pin expand 100 mils on each side)\n\n" _layer_pkg_ko_b)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_ls _layer_pkg_ko_b ?expand_mils 100)
		
		fprintf( out_port "5.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "6.")
		CheckNote_footprintutilityprogram( out_port)
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_screw_hole_pth" 'Main_checkscrewholepth)
/*
(encrypt "c:/skill/check_screw_hole_pth_v1d1.il" "c:/skill/check_screw_hole_pth_v1d1.ile")
(load "check_screw_hole_pth_v1d1.il")
(load "check_screw_hole_pth_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup