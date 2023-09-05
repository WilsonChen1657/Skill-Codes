/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/11/21                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To read rename.log and convert to rename.swp                           #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_renamerefdes()
	setq( _work_dir getWorkingDir())
	setq( _work_name axlCurrentDesign())
	unless( stringp( axlGetVariable( "ads_sdlog"))
		axlSetVariable( "ads_sdlog" "log")
	)
	
	setq( _log_dir axlGetVariable("ads_sdlog"))
	setq( _rename_log strcat( _log_dir "/rename.log"))
	setq( _rename_swp strcat( _work_dir "/" _work_name "_rename.swp"))
	
	defstruct( rename_struct old new)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_renamerefdes()
	prog( ( rename_data_ls result)
		unless( Main_locker()
			return( nil)
		)
		
		Init_renamerefdes()
		result = SetNoRenameComponents_renamerefdes()
		unless( result
			return( nil)
		)
		
		when( isFile( _rename_log)
			deleteFile( _rename_log)
		)
		
		; if this setting has value, alert to unset
		when( axlGetVariable( "fst_ref_des")
			axlUIConfirm( "Please unset 'fst_ref_des' first !!\nSetup > User Preferences or env file")
			return( nil)
		)
		
		RunRename_renamerefdes()
		
		rename_data_ls = ReadRenameLog_renamerefdes()
		result = WriteRenameSWP_renamerefdes( rename_data_ls)
		when( result
			sprintf( msg "Successfully write file\n%s\nPlease check this out." _rename_swp)
			axlUIConfirm( msg)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( SetNoRenameComponents_renamerefdes()
	prog( ( no_rename_txt in_port no_rename_ls hard_comp_ls result no_rename_comp_ls prop)
		no_rename_txt = axlDMFileBrowse( nil nil ?title "Please select a no rename list" ?optFilters "All text files(*.txt)|*.txt")
		when( no_rename_txt	
			in_port = infile( no_rename_txt)
			unless( inportp( in_port)
				println( "ERROR: SetNoRenameComponents() - Fail to open no_rename.txt")
				return( nil)
			)
			
			while( gets( line in_port)
				no_rename_ls = append1( no_rename_ls Trim_utilityprogram( line "\n"))
			)
			
			close( in_port)
			
			no_rename_ls = remq( "" no_rename_ls)
			unless( dtpr( no_rename_ls)
				println( "WARN: SetNoRenameComponents() - no_rename.txt is empty")
			)
			
			no_rename_ls = UniqueList_utilityprogram( no_rename_ls)
		)
		
		hard_comp_ls = setof( x axlDBGetDesign()->components x->prop->HARD_LOCATION)
		WriteLog_renamerefdes( no_rename_ls hard_comp_ls)
		result = axlUIYesNo( "Are you sure to rename this brd?" "Rename Refdes" 'no)
		unless( result
			return( nil)
		)
		
		SaveAsBackUpFile_renamerefdes()
		
		no_rename_comp_ls = setof( x axlDBGetDesign()->components member( x->symbol->refdes no_rename_ls))
		prop = list( "HARD_LOCATION" t)
		foreach( component_id no_rename_comp_ls
			axlDBAddProp( component_id prop)
		)
		
		return( t)
	)
)

procedure( WriteLog_renamerefdes( no_rename_ls hard_comp_ls)
	prog( ( log_info)
		log_info = SetUpLog_utilityprogram( "rename_compare_refdes")
		unless( log_info
			return( nil)
		)
		
		out_port = nth( 0 log_info)
		logname = nth( 1 log_info)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L" getCurrentTime())
		fprintf( out_port "\n\n")
	
		fprintf( out_port "Introduction: Compare no rename list with brd file's components that had set property 'HARD_LOCATION'")
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Total Component count : %d" length( axlDBGetDesign()->components))
		fprintf( out_port "\n\n")
		
		fprintf( out_port "No rename txt: \n")
		if( no_rename_ls then
			fprintf( out_port "count : %d\n" length( no_rename_ls))
			fprintf( out_port "Refdes\n")
			foreach( refdes no_rename_ls
				fprintf( out_port "%-10s\n" refdes)
			)
		else
			fprintf( out_port "\tNone")
		)
		
		fprintf( out_port "\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n")
		
		fprintf( out_port "Components with property 'HARD_LOCATION': \n")
		if( hard_comp_ls then
			fprintf( out_port "count : %d\n" length( hard_comp_ls))
			fprintf( out_port "%-10s,%s\n" "Refdes" "XY")
			foreach( comp_id hard_comp_ls
				fprintf( out_port "%-10s,%L\n" comp_id->symbol->refdes comp_id->symbol->xy)
			)
		else
			fprintf( out_port "\tNone")
		)
		
		close( out_port)
		;axlUIViewFileCreate( logname "Rename compare refdes report" nil)
		; open log file to pause thread to check report
		shell( strcat( getWorkingDir() "/" logname))
		return( t)
	)
)

procedure( SaveAsBackUpFile_renamerefdes()
	let( ( current_design file_name)
		; save back up file
		current_design = axlCurrentDesign()
		file_name = strcat( current_design "_before_rename")
		axlSaveDesign( ?design file_name ?noConfirm t)
		axlOpenDesignForBatch( current_design "wf")
	)
)

procedure( RunRename_renamerefdes()
	let( ( cmd_ls cmd)
		cmd_ls = list( "rename param"
						; grid specification
						"FORM rename use_default_grid YES "
						"FORM rename rename_all YES "
						"FORM rename more"
						; layer option
						"FORM rename_more layer_side BOTH "
						"FORM rename_more first_side 'Top Layer' "
						"FORM rename_more component_origin 'Symbol Origin' "
						; direction for top layer
						"FORM rename_more top_direction Horizontal "
						"FORM rename_more top_first 'Left to Right' "
						"FORM rename_more top_second Downwards "
						; direction for bottom layer
						"FORM rename_more bottom_direction Horizontal "
						"FORM rename_more bottom_first 'Right to Left' "
						"FORM rename_more bottom_second Downwards "
						; reference designator format
						"FORM rename_more top_comp_des  "
						"FORM rename_more bottom_comp_des  "
						"FORM rename_more preserve_prefix YES "
						; sequential renaming
						"FORM rename_more naming_convention Sequential "
						"FORM rename_more refdes_no 1 "
						"FORM rename_more close"
						"rename execute"
						"FORM rename close")
		cmd = buildString( cmd_ls ";")
		axlShell( cmd)
	)
)

procedure( ReadRenameLog_renamerefdes()
	prog( ( rename_log in_port rename_data_ls)
		rename_log = _rename_log
		unless( isFile( rename_log)
			rename_log = axlDMFileBrowse( nil nil ?title "Please select rename.log" ?optFilters "All log files(*.log)|*.log")
		)
		
		in_port = infile( rename_log)
		unless( inportp( in_port)
			println( "ERROR: ReadRenameLog() - Fail to open sov input file")
			return( nil)
		)
		
		rename_data_ls = nil
		while( gets( line in_port)
			when( and( index( line "OLD") index( line "NEW"))
				line_data_ls = parseString( line)
				old_name = nth( 1 line_data_ls)
				new_name = nth( 3 line_data_ls)
				rename_data = make_rename_struct( ?old old_name ?new new_name)
				rename_data_ls = append1( rename_data_ls rename_data)
			)
		)
		
		close( in_port)
		return( rename_data_ls)
	)
)

procedure( WriteRenameSWP_renamerefdes( rename_data_ls)
	prog( ( out_port)
		out_port = outfile( _rename_swp "w")
		unless( outportp( out_port)
			println( "ERROR: WriteRenameSWP() - Fail to write file")
			return( nil)
		)
		
		format = "%s %s\n"
		foreach( data rename_data_ls
			fprintf( out_port format data->old data->new)
		)
		
		close( out_port)
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "rename_refdes" 'Main_renamerefdes ?cmdType "general")
/*
(encrypt "c:/skill/rename_refdes_v1d1.il" "c:/skill/rename_refdes_v1d1.ile")
(load "rename_refdes_v1d1.il")
(load "rename_refdes_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup