/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/12/02                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To archive part of item of the gerber                                  #
#       line package, including                                                #
#       1.pcb_part_number + _ + agile_rev.zip                                  #
#          1.pcb_part_number.7z                                                #
#          2.(cad).7z                                                          #
#          3._component.txt                                                    #
#          4.(gbr_pdf).7z                                                      #
#          5.(odb++).7z                                                        #
#       2.pcb_part_number + -AE + _ + agile_rev.pdf                            #
#          1.from (pcba).7z                                                    #
#       2.pcb_part_number + -AV + _ + agile_rev.pdf                            #
#          1.from (panel).7z                                                   #
#       2.(brd).zip                                                            #
#          1.from (brd).7z                                                     #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( Init_gerbertodcc()
	setq( _work_name axlCurrentDesign())
	setq( _work_path getWorkingDir())
	setq( _work_addr axlGetDrawingName())
	setq( _part_number nil)
	setq( _agile_rev nil)
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_gerbertodcc()
	prog( ( error_msg is_lack_data brd_form_key_text_ls pn_key_text_id pcb_fab_text_ls rev_index)
		unless( Main_locker()
			return( nil)
		)
		
		Init_gerbertodcc()
		
		when( index( _work_addr " ")
			printf( "ERROR: Please remove space from current path before using this tool\n\t%s\n" _work_addr)
			return( nil)
		)
		
		error_msg = "ERROR: Main_gerbertodcc() -"

		is_lack_data = nil
		
		when( index( _work_name " ")
			printf( "%s No space is allowed in the filename" error_msg)
			is_lack_data = t
		)
		
		; get PCB part number & agile_rev
		pcb_fab_msg = "%s %s not found on [DRAWING FORMAT/PCB_FAB], please check xy with text [%s] on [BOARD GEOMETRY/BOARD_FORM_KEY]"
		brd_form_key_text_ls = GetTextList_utilityprogram( "BOARD GEOMETRY/BOARD_FORM_KEY")
		pn_key_text_id = car( setof( x brd_form_key_text_ls x->text == "[pn]"))
		
		pcb_fab_text_ls = GetTextList_utilityprogram( "DRAWING FORMAT/PCB_FAB")
		_part_number = car( setof( x pcb_fab_text_ls x->xy == pn_key_text_id->xy))->text
		
		unless( _part_number
			printf( pcb_fab_msg error_msg "PCB part number" "pn")
			is_lack_data = t
		)
		
		rev_index = 5
		while( and( _agile_rev == nil rev_index > 0)
			sprintf( key "[v%d]" rev_index)
			rev_key_text_id = car( setof( x brd_form_key_text_ls x->text == key))
			_agile_rev = car( setof( x pcb_fab_text_ls x->xy == rev_key_text_id->xy))->text
			rev_index--
		)
		
		unless( _agile_rev
			printf( pcb_fab_msg error_msg "Agile Rev" "v1")
			is_lack_data = t
		)
		
		when( is_lack_data
			return( nil)
		)
		
		; test whether the 7z command is exists
		unless( sh( "\"C:\\Program Files\\7-Zip\\7z\" ")
			println( "Please install 7z or it isn't installed in the default path. Process halt")
			return( nil)
		)
		
		ToDcc_gerbertodcc()
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( ToDcc_gerbertodcc()
	prog( ( gerber_dir gerber_filename_ls dcc_dir pcb_pn_7z cad component gbr_pdf odb dcc_1_files
			pcba panel brd to_dcc_filename_ls delete_file_ls from_addr to_addr)
		gerber_dir = axlDMDirectoryBrowse( _work_path nil ?title "Select Gerber file's directory")
		unless( gerber_dir
			return( nil)
		)
		
		gerber_dir = strcat( gerber_dir "/")
		gerber_filename_ls = cddr( getDirFiles( gerber_dir))
		
		dcc_dir = strcat( gerber_dir "../" _part_number "_ToDCC/")
		if( isDir( dcc_dir)
			DeleteExtraFiles_gerbertodcc( getDirFiles( dcc_dir) dcc_dir)
			createDir( dcc_dir)
		)
		
		; 1. pcb_part_number + _ + agile_rev.zip
		; include : pcb_part_number.7z / (cad).7z / _component.txt / (gbr_pdf).7z / (odb++).7z
		pcb_pn_7z = car( setof( x gerber_filename_ls index( x strcat( _part_number ".7z"))))
		unless( pcb_pn_7z
			axlUIConfirm( sprintf( nil "%s.7z not found!!" _part_number))
			return( nil)
		)
		
		cad = car( setof( x gerber_filename_ls index( x "(cad).7z")))
		unless( cad
			axlUIConfirm( "(cad).7z not found!!")
			return( nil)
		)
		
		component = car( setof( x gerber_filename_ls index( x "_component.txt")))
		unless( component
			axlUIConfirm( "_component.txt not found!!")
			return( nil)
		)
		
		gbr_pdf = car( setof( x gerber_filename_ls index( x "(gbr_pdf).7z")))
		unless( gbr_pdf
			axlUIConfirm( "(gbr_pdf).7z not found!!")
			return( nil)
		)
		
		odb = car( setof( x gerber_filename_ls index( x "(odb++).7z")))
		unless( odb
			axlUIConfirm( "(odb++).7z not found!!")
			return( nil)
		)
		
		dcc_1_files = list( strcat( gerber_dir pcb_pn_7z) strcat( gerber_dir cad) 
								strcat( gerber_dir component) strcat( gerber_dir gbr_pdf) strcat( gerber_dir odb))
		
		; 2. pcb_part_number + -AE + _ + agile_rev.pdf
		; from (pcba).7z
		pcba = car( setof( x gerber_filename_ls index( x "(pcba).7z")))
		pcba = strcat( gerber_dir pcba)
		ExtractFile_gerbertodcc( pcba gerber_dir "*.pdf")
		gerber_filename_ls = cddr( getDirFiles( gerber_dir))
		pcba = car( setof( x gerber_filename_ls index( x "(pcba).pdf")))
		unless( pcba
			axlUIConfirm( "(pcba).7z not found!!")
			return( nil)
		)
		
		delete_file_ls = append1( delete_file_ls pcba)
		
		; 3. pcb_part_number + -AV + _ + agile_rev.pdf
		; from (panel).7z
		panel = car( setof( x gerber_filename_ls index( x "(panel).7z")))
		panel = strcat( gerber_dir panel)
		ExtractFile_gerbertodcc( panel gerber_dir "*.pdf")
		gerber_filename_ls = cddr( getDirFiles( gerber_dir))
		panel = car( setof( x gerber_filename_ls index( x "(panel).pdf")))
		unless( panel
			axlUIConfirm( "(panel).pdf not found!!")
			return( nil)
		)
		
		delete_file_ls = append1( delete_file_ls panel)
		
		; 4. (brd).zip
		; from (brd).7z
		brd = car( setof( x gerber_filename_ls index( x "(brd).7z")))
		unless( brd
			axlUIConfirm( "(brd).7z not found!!")
			return( nil)
		)
		
		brd = strcat( gerber_dir brd)
		ExtractFile_gerbertodcc( brd gerber_dir "*.brd")
		gerber_filename_ls = cddr( getDirFiles( gerber_dir))
		brd = car( setof( x gerber_filename_ls index( x ".brd")))
		unless( brd
			axlUIConfirm( ".brd not found!!")
			return( nil)
		)
		
		delete_file_ls = append1( delete_file_ls brd)
		brd = strcat( gerber_dir brd)
		
		to_dcc_filename_ls = nil
		; 1
		dcc_1_file_name = strcat( _part_number "_" _agile_rev)
		ArchiveWith7z_gerbertodcc( dcc_1_files dcc_1_file_name ".zip" gerber_dir)
		to_dcc_filename_ls = append1( to_dcc_filename_ls strcat( dcc_1_file_name ".zip"))
		; 2
		pcba_file_name = strcat( _part_number "-AE_" _agile_rev ".pdf")
		from_addr = strcat( gerber_dir pcba)
		to_addr = strcat( dcc_dir pcba_file_name)
		CopyFile_gerbertodcc( from_addr to_addr)
		; 3
		panel_file_name = strcat( _part_number "-AV_" _agile_rev ".pdf")
		from_addr = strcat( gerber_dir panel)
		to_addr = strcat( dcc_dir panel_file_name)
		CopyFile_gerbertodcc( from_addr to_addr)
		; 4
		parts = axlDMFileParts( brd)
		brd_name = nth( 1 parts)
		ArchiveWith7z_gerbertodcc( brd brd_name ".zip" gerber_dir)
		to_dcc_filename_ls = append1( to_dcc_filename_ls strcat( brd_name ".zip"))
		foreach( file_name to_dcc_filename_ls
			from_addr = strcat( gerber_dir file_name)
			to_addr = strcat( dcc_dir file_name)
			CopyFile_gerbertodcc( from_addr to_addr)
		)
		
		delete_file_ls = append( delete_file_ls to_dcc_filename_ls)
		DeleteExtraFiles_gerbertodcc( delete_file_ls gerber_dir)
		
		OpenDirectory_gerbertodcc( dcc_dir)
		return( t)
	)
)

procedure( ArchiveWith7z_gerbertodcc( file_names archive_name @optional (ext ".7z") (dir nil))
	prog( (files_line cmd non_exists_file_ls)
		if( dtpr( file_names) then
			unless( forall( f file_names stringp( f))
				printf( "ArgErr: ArchiveWith7z() - file_names list contain non-string %L\n" file_names)
				return( nil)
			)
			
			unless( forall( f file_names or( isFile( f) index( f "*")))
				non_exists_file_ls = setof( x file_names not( isFile( x)))
				printf( "ArgErr: ArchiveWith7z() - file_names list contain non-file-name %L\n" non_exists_file_ls)
				return( nil)
			)
		else
			unless( stringp( file_names)
				printf( "ArgErr: ArchiveWith7z() - file_names is not a string\n")
				return( nil)
			)
			
			unless( isFile( file_names)
				printf( "ArgErr: ArchiveWith7z() - file_names[%L] is not a file\n" file_names)
				return( nil)
			)
		)
		
		printf( "INFO: ArchiveWith7z() - Start to zip files: %L\n" file_names)
		
		archive_name = strcat( archive_name ext)
		archive_addr = strcat( dir "\\" archive_name)
		when( isFile( archive_addr)
			printf( "ERROR: ArchiveWith7z() - Exists archive file: %s\n" archive_name)
			return( nil)
		)
		
		;;; convert multiple file name into a line with space 
		if( dtpr( file_names)
			files_line = buildString( file_names " ")
			files_line = file_names
		)
		
		;;; zip up the files
		sprintf( cmd "\"C:\\Program Files\\7-Zip\\7z\" a %s %s" archive_name files_line)
		unless( sh( cmd)
			printf( "ERROR: ArchiveWith7z() - Fail to create archive file: %s\n" archive_name)
			return( nil)
		)
		
		;;; move the zipped file to CAD directory
		unless( axlOSFileMove( archive_name archive_addr)
			printf( "ERROR: ArchiveWith7z() - Fail to move file: %s\n" archive_name)
			return( nil)
		)
		
		printf( "Successfully create file: %s\n" archive_name)
		return( t)
	)
)

procedure( ExtractFile_gerbertodcc( archive_name output_dir @optional (file_filter ""))
	prog( ( cmd)
		unless( stringp( archive_name)
			printf( "ArgErr: ExtractFile() - archive_name is not a string\n")
			return( nil)
		)
		
		unless( isFile( archive_name)
			printf( "ArgErr: ExtractFile() - archive_name[%L] is not a file\n" archive_name)
			return( nil)
		)
		
		sprintf( cmd "\"C:\\Program Files\\7-Zip\\7z\" e %s -o%s %s" archive_name output_dir file_filter)
		unless( sh( cmd)
			printf( "ERROR: ExtractFiles() - Fail to extract file: %s\n" archive_name)
			return( nil)
		)
		
		return( t)
	)
)

procedure( DeleteExtraFiles_gerbertodcc( file_ls @optional (dir "."))
	let( ( addr)
		;;;;; while using the recursive, addr variable will be overwrited by the next stage called function
		foreach( file file_ls
			addr = strcat( dir "/" file)
			when( isFile( addr)
				deleteFile( addr)
			)
			
			when( and( isDir( addr) not( member( file '("." ".."))))
				DeleteExtraFiles_gerbertodcc( getDirFiles( addr) addr)
				deleteDir( addr)
			)
		)
	)
)

procedure( CopyFile_gerbertodcc( from_addr to_addr)
	let( ()
		axlOSFileCopy( from_addr to_addr nil)
	)
)

procedure( OpenDirectory_gerbertodcc( dir)
	let( ( cmd)
		sprintf( cmd "start \"\" \"%s\" " dir)
		sh( cmd)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

axlCmdRegister( "gerber_to_dcc" 'Main_gerbertodcc)
/*
(encrypt "C:/skill/gerber_to_dcc_v1d1.il" "C:/skill/gerber_to_dcc_v1d1.ile")
(load "gerber_to_dcc_v1d1.il")
(load "gerber_to_dcc_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup