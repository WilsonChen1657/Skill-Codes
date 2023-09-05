/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/14                                                      #
#  Reference: locker, utility_program, create_smd                              #
#  Purpose:                                                                    #
#       To check BGA symbols                                                   #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkbga()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram()
	setq( _check_bga_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkbga()
	prog( ( log_info out_port visible_ls)
		Init_checkbga()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_bga_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_bga_logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: To check BGA symbols are created according to SOP\n")
		fprintf( out_port "\n\n")
		fprintf( out_port "DFA_DEV_CLASS: %s\n" GetDfaDevClass_footprintutilityprogram())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Manual check: ")
		fprintf( out_port "1. Pad size should between ball size * 0.8 and 1.2\n")
		fprintf( out_port "%-14s2. PIN Pitch\n" "")
		fprintf( out_port "%-14s3. PIN number\n" "")
		fprintf( out_port "%-14s4. ASSEMBLY_TOP body size\n" "")
		fprintf( out_port "\n")
		pth_pin_ls = setof( x axlDBGetDesign()->pins x->definition->plating == "PLATED")
		fprintf( out_port "Total pth pin count:%d\n" length( pth_pin_ls))
		pin_name_ls = UniqueList_utilityprogram( pth_pin_ls~>name)
		foreach( pin_name pin_name_ls
			pin_count = length( setof( x pth_pin_ls x->name == pin_name))
			fprintf( out_port "%-10s:%d\n" pin_name pin_count)
		)
		
		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
		
		Check_checkbga( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _check_bga_logname "Check bga report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkbga( out_port)
	let( ( visible_ls)
		visible_ls = axlVisibleGet()
		fprintf( out_port "1.")
		CheckPadSize_footprintutilityprogram( out_port)
		fprintf( out_port "2.")
		CheckPkgAssemblyTop_footprintutilityprogram( out_port)
		fprintf( out_port "3.")
		CheckPkgSilkscreenTop_footprintutilityprogram( out_port t)
		fprintf( out_port "4.")
		CheckPkgPlaceBoundTop_footprintutilityprogram( out_port)
		fprintf( out_port "5.")
		CheckPkgDFABoundTop_footprintutilityprogram( out_port)
		fprintf( out_port "6.")
		CheckManufacturingNoProbeTop_footprintutilityprogram( out_port)
		fprintf( out_port "7.")
		CheckPinNumber_footprintutilityprogram( out_port)
		fprintf( out_port "8.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "9.")
		CheckPin1Mark_footprintutilityprogram( out_port)
		fprintf( out_port "10.")
		CheckPinNote_footprintutilityprogram( out_port)
		fprintf( out_port "11.")
		CheckNote_footprintutilityprogram( out_port)
		axlVisibleSet( visible_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_bga" 'Main_checkbga)
/*
(encrypt "c:/skill/check_bga_v1d1.il" "c:/skill/check_bga_v1d1.ile")
(load "check_bga_v1d1.il")
(load "check_bga_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup