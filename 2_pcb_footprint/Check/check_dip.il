/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/14                                                      #
#  Reference: locker, utility_program, create_smd                              #
#  Purpose:                                                                    #
#       To check DIP symbols                                                   #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkdip()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram()
	setq( _check_dip_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkdip()
	prog( ( log_info out_port visible_ls)
		Init_checkdip()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_dip_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_dip_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check DIP symbols are created according to SOP\n")
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
		
		Check_checkdip( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_dip_logname "Check dip report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkdip( out_port)
	let( ( visible_ls)
		visible_ls = axlVisibleGet()
		fprintf( out_port "1.")
		CheckPkgAssemblyTop_footprintutilityprogram( out_port)
		fprintf( out_port "2.")
		CheckPkgSilkscreenTop_footprintutilityprogram( out_port)
		fprintf( out_port "3.")
		CheckPkgPlaceBoundTop_footprintutilityprogram( out_port)
		fprintf( out_port "4.")
		CheckPkgDFABoundTop_footprintutilityprogram( out_port)
		fprintf( out_port "5.")
		CheckManufacturingNoProbeTop_footprintutilityprogram( out_port)
		fprintf( out_port "6.")
		CheckPlaceBoundBottom_footprintutilityprogram( out_port)
		fprintf( out_port "7.")
		CheckRouteKeepoutAll_footprintutilityprogram( out_port)
		fprintf( out_port "8.")
		CheckPackageKeepoutBottom_footprintutilityprogram( out_port)
		fprintf( out_port "9.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "10.")
		CheckPin1Mark_footprintutilityprogram( out_port)
		fprintf( out_port "11.")
		CheckPinNote_footprintutilityprogram( out_port)
		fprintf( out_port "12.")
		CheckPCBEdgeNote_footprintutilityprogram( out_port)
		fprintf( out_port "13.")
		CheckNote_footprintutilityprogram( out_port)
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_dip" 'Main_checkdip)
/*
(encrypt "c:/skill/check_dip_v1d1.il" "c:/skill/check_dip_v1d1.ile")
(load "check_dip_v1d1.il")
(load "check_dip_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup