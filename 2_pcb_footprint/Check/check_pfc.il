/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/19                                                      #
#  Reference: locker, utility_program, create_smd                              #
#  Purpose:                                                                    #
#       To check PFC symbols                                                   #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkpfc()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram()
	setq( _check_pfc_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkpfc()
	prog( ( log_info out_port visible_ls)
		Init_checkpfc()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_pfc_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_pfc_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check PFC symbols are created according to SOP\n")
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
		fprintf( out_port "\n")
		pth_pin_ls = setof( x axlDBGetDesign()->pins x->definition->plating == "PLATED")
		fprintf( out_port "Total pth pin count:%d\n" length( pth_pin_ls))
		drill_size_ls = UniqueList_utilityprogram( pth_pin_ls~>definition~>drillDiameter)
		foreach( drill_size drill_size_ls
			pin_count = length( setof( x pth_pin_ls axlGeoEqual( x->definition->drillDiameter drill_size)))
			fprintf( out_port "drillDiameter: %L, pin count:%d\n" drill_size pin_count)
		)
		
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
		
		Check_checkpfc( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_pfc_logname "Check pfc report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkpfc( out_port)
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
		CheckPackageKeepoutTop_footprintutilityprogram( out_port)
		fprintf( out_port "10.")
		CheckPinProperties_footprintutilityprogram( out_port)
		fprintf( out_port "11.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "12.")
		CheckPin1Mark_footprintutilityprogram( out_port)
		fprintf( out_port "13.")
		CheckPinNote_footprintutilityprogram( out_port)
		fprintf( out_port "14.")
		CheckPCBEdgeNote_footprintutilityprogram( out_port)
		fprintf( out_port "15.")
		CheckNote_footprintutilityprogram( out_port)
		
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_pfc" 'Main_checkpfc)
/*
(encrypt "c:/skill/check_pfc_v1d1.il" "c:/skill/check_pfc_v1d1.ile")
(load "check_pfc_v1d1.il")
(load "check_pfc_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup