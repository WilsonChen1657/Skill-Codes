/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/11/04                                                      #
#  Reference: locker, utility_program, create_smd                              #
#  Purpose:                                                                    #
#       To check STDF symbols                                                  #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkstdf()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram()
	setq( _check_stdf_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkstdf()
	prog( ( log_info out_port visible_ls)
		Init_checkstdf()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_stdf_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_stdf_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check STDF symbols are created according to SOP\n")
		fprintf( out_port "\n\n")
		
		; DFA_DEV_CLASS
		axlClearSelSet()
		SetFindFilter_utilityprogram( '(alltypes))
		axlSingleSelectName( "component" "U1")
		props = axlDBGetProperties( car( axlGetSelSet()) '( "user" "allegro"))
		dfa_dev_class = car( setof( x props car( x) == 'DFA_DEV_CLASS))
		axlClearSelSet()
		fprintf( out_port "DFA_DEV_CLASS: %s\n" cadr( dfa_dev_class))
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Manual check: ")
		fprintf( out_port "1. Pad size\n")
		fprintf( out_port "%-14s2. PIN Pitch\n" "")
		fprintf( out_port "%-14s3. PIN number\n" "")
		fprintf( out_port "%-14s4. ASSEMBLY_TOP body size\n" "")
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
		
		Check_checkstdf( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_stdf_logname "Check stdf report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkstdf( out_port)
	let( ( visible_ls pin_id title check_msg)
		visible_ls = axlVisibleGet()
		pin_id = car( axlDBGetDesign()->pins)
		
		fprintf( out_port "1.")
		CheckPkgAssemblyTop_footprintutilityprogram( out_port t)
		
		fprintf( out_port "2.")
		CheckPkgSilkscreenTop_footprintutilityprogram( out_port)
		
		title = "%d.Check shape on pin on %s"
		check_msg = "* Pin should have shape on %s\n\n"
		
		fprintf( out_port title 3 _layer_pkg_pbt)
		fprintf( out_port check_msg _layer_pkg_pbt)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_id _layer_pkg_pbt ?pin_layer "PIN/TOP")
		fprintf( out_port title 4 _layer_pkg_pbb)
		fprintf( out_port check_msg _layer_pkg_pbb)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_id _layer_pkg_pbb ?pin_layer "PIN/BOTTOM")
		
		fprintf( out_port title 5 _layer_pkg_dfabt)
		fprintf( out_port check_msg _layer_pkg_dfabt)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_id _layer_pkg_dfabt ?pin_layer "PIN/TOP")
		fprintf( out_port title 6 _layer_pkg_dfabb)
		fprintf( out_port check_msg _layer_pkg_dfabb)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_id _layer_pkg_dfabb ?pin_layer "PIN/BOTTOM")

		fprintf( out_port title 7 _layer_manu_npt)
		fprintf( out_port check_msg _layer_manu_npt)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_id _layer_manu_npt ?expand_mils 15 ?pin_layer "PIN/TOP")
		fprintf( out_port title 8 _layer_manu_npb)
		fprintf( out_port check_msg _layer_manu_npb)
		CheckShapeOnPin_footprintutilityprogram( out_port pin_id _layer_manu_npb ?expand_mils 15 ?pin_layer "PIN/BOTTOM")
		
		fprintf( out_port "9.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "10.")
		CheckNote_footprintutilityprogram( out_port)
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_stdf" 'Main_checkstdf)
/*
(encrypt "c:/skill/check_stdf_v1d1.il" "c:/skill/check_stdf_v1d1.ile")
(load "check_stdf_v1d1.il")
(load "check_stdf_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup