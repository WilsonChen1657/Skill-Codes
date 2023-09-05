/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/10/14                                                      #
#  Reference: locker, utility_program, create_smd                              #
#  Purpose:                                                                    #
#       To check Gold Finger symbols                                           #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkgf()
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	
	InitCheckBaseData_footprintutilityprogram( ?has_assembly nil)
	setq( _check_gf_logname "")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_checkgf()
	prog( ( log_info out_port)
		Init_checkgf()
		
		unless( Main_footprintlocker()
			return( nil)
		)
		
		log_info = SetUpLog_utilityprogram( "check_gf_symbol")
		unless( log_info
			return( nil)
		)
			
		out_port = nth( 0 log_info)
		_check_gf_logname = nth( 1 log_info)

		LogTitle_footprintutilityprogram( out_port "Gold Finger" ?body_size nil)
		Check_checkgf( out_port)
		close( out_port)
		axlUIViewFileCreate( _check_gf_logname "Check gf report" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( Check_checkgf( out_port)
	let( ( visible_ls)
		visible_ls = axlVisibleGet()
		fprintf( out_port "1.")
		CheckPlaceBound_checkgf( out_port)
		fprintf( out_port "2.")
		CheckSoldermask_checkgf( out_port)
		fprintf( out_port "3.")
		CheckNoPorb_checkgf( out_port)
		fprintf( out_port "4.")
		CheckViaKO_checkgf( out_port)
		fprintf( out_port "5.")
		CheckPkgKO_checkgf( out_port)
		fprintf( out_port "6.")
		CheckAssemblyNote_checkgf( out_port)
		fprintf( out_port "7.")
		CheckPin1Mark_footprintutilityprogram( out_port)
		fprintf( out_port "8.")
		CheckPinNumber_footprintutilityprogram( out_port)
		fprintf( out_port "9.")
		CheckPinNote_footprintutilityprogram( out_port)
		fprintf( out_port "10.")
		CheckRefDes_footprintutilityprogram( out_port)
		fprintf( out_port "11.")
		CheckNote_footprintutilityprogram( out_port)
		axlVisibleSet( visible_ls)
	)
)

procedure( CheckPlaceBound_checkgf( out_port)
	let( ( layer_ls point_ls)
		layer_ls = list( _layer_pkg_pbt _layer_pkg_pbb)
		sprintf( layer_str "%L" layer_ls)
		printf( _check_msg_format layer_str)
		fprintf( out_port _check_msg_format layer_str)
		fprintf( out_port "* Shape should be same with PCB_EDGE's down edge and wrap to top edge of PAD's soldermask")
		fprintf( out_port "\n\n")
		
		point_ls = GetPlaceBoundPoints_creategf()
		CheckShapeByPoints_checkgf( out_port point_ls layer_ls)

	)
)

procedure( CheckSoldermask_checkgf( out_port)
	let( ( layer_ls point_ls)
		layer_ls = list( _layer_pkg_smt _layer_pkg_smb)
		sprintf( layer_str "%L" layer_ls)
		printf( _check_msg_format layer_str)
		fprintf( out_port _check_msg_format layer_str)
		fprintf( out_port "* Shape should be same with PCB_EDGE's down edge and wrap to top edge of PAD's soldermask")
		fprintf( out_port "\n\n")

		point_ls = GetPlaceBoundPoints_creategf()
		CheckShapeByPoints_checkgf( out_port point_ls layer_ls)
	)
)

procedure( CheckNoPorb_checkgf( out_port)
	let( ( layer_ls point_ls)
		layer_ls = list( _layer_manu_npt _layer_manu_npb)
		sprintf( layer_str "%L" layer_ls)
		printf( _check_msg_format layer_str)
		fprintf( out_port _check_msg_format layer_str)
		fprintf( out_port "* Shape should be same with PCB_EDGE's box")
		fprintf( out_port "\n\n")

		point_ls = GetNoPorbPoints_creategf()
		CheckShapeByPoints_checkgf( out_port point_ls layer_ls)
	)
)

procedure( CheckViaKO_checkgf( out_port)
	let( ( layer_ls point_ls)
		layer = _layer_via_ko_a
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Shape should be same with PCB_EDGE's width and push up 10 mils from PAD's top edge")
		fprintf( out_port "\n\n")

		point_ls = GetViaKOPoints_creategf()
		CheckShapeByPoints_checkgf( out_port point_ls layer)
	)
)

procedure( CheckPkgKO_checkgf( out_port)
	let( ( layer_ls point_ls)
		layer = _layer_pkg_ko_a
		printf( _check_msg_format layer)
		fprintf( out_port _check_msg_format layer)
		fprintf( out_port "* Shape should be same with PCB_EDGE's box top and width and PAD's soldermask top edge")
		fprintf( out_port "\n\n")

		point_ls = GetPkgKOPoints_creategf()
		CheckShapeByPoints_checkgf( out_port point_ls layer)
	)
)

procedure( CheckShapeByPoints_checkgf( out_port point_ls layer_ls)
	let( ( path_id path_poly result_msg result)
		when( and( !dtpr( layer_ls) stringp( layer_ls))
			layer_ls = list( layer_ls)
		)

		path_id = axlPathStart( append1( point_ls car( point_ls)))
		path_poly = car( axlPolyFromDB( path_id))
		result_msg = ""
		result = t
		foreach( layer layer_ls
			shape_ls = GetShapeList_utilityprogram( layer)
			unless( dtpr( shape_ls)
				result_msg = strcat( result_msg sprintf( nil "\tShape not found on %s\n" layer))
				result = nil
			)

			unless( equal( length( shape_ls) 1)
			result_msg = strcat( result_msg sprintf( nil "\tMore then one shape are found on %s\n" layer))
				result = nil
			)

			when( result
				shape_id = car( shape_ls)
				shape_poly = car( axlPolyFromDB( shape_id))
				result = IsSamePoly_footprintutilityprogram( path_poly shape_poly)
				if( result
					result_msg = strcat( result_msg sprintf( nil "\t%s PASS\n" layer))
					result_msg = strcat( result_msg sprintf( nil "\tShape on %s is incorrect\n" layer))
				)
			)
		)
		
		fprintf( out_port result_msg)
		PrintCheckResult_footprintutilityprogram( result sprintf( nil "%L" layer_ls) out_port)
	)
)

procedure( CheckAssemblyNote_checkgf( out_port)
	let( ( result layer key_ls text_ls)
		result = t
		layer = _layer_bg_an
		key_ls = list( "gf_title" "gf_angle" "gf_bevel_length" "gf_thickness" "gf_bevel_length_sub" "gf_thickness_sub")
		printf( "Check Assembly Notes on %s\n" layer)
		fprintf( out_port "Check Symbol Notes on %s\n" layer)
		fprintf( out_port "* Contains text with prop COMMENT %L\n" key_ls)

		text_ls = GetTextList_utilityprogram( layer)
		foreach( key key_ls
			when( result
				result = IsOnlyOneText_checkgf( out_port text_ls key)
			)
		)

		PrintCheckResult_footprintutilityprogram( result "Assembly notes" out_port)
	)
)

procedure( IsOnlyOneText_checkgf( out_port text_ls key)
	let( ( result target_text_ls)
		result = t
		target_text_ls = setof( x text_ls equal( x->prop->COMMENT key))
		unless( dtpr( target_text_ls)
			fprintf( out_port "\tCOMMENT = [%s] not found!\n" key)
			result = nil
		)

		when( and( result !equal( length( target_text_ls) 1))
			fprintf( out_port "\tCOMMENT = [%s] should only have one!\n" key)
			result = nil
		)
		
		result
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "check_gf" 'Main_checkgf)
/*
(encrypt "c:/skill/check_gf_v1d1.il" "c:/skill/check_gf_v1d1.ile")
(load "check_gf_v1d1.il")
(load "check_gf_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup