;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;
;Starting Date: 06/12/2019 - _Derek06122019
;
;description:
;	1. the composition of numbers of function, including
;		1. before
;			1. setup board init
;			2. create logo (pending)
;			3. create xsection
;			4. create artwork
;			5. create outline keepout
;		2. after
;			1. create stackup table
;			2. create fab note
;			3. import pcb form data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global

procedure( init_Derek06122019( )
	setq( _allegro_version axlVersion( 'version))
	setq( _allegro_type axlDesignType( nil))
	setq( _allegro_unit upperCase( car( axlDBGetDesignUnits())))
	setq( _allegro_path getWorkingDir())
	
	setq( _csv_filename "Excel_sheet[0].csv")
	setq( _table_filename "Excel_sheet[0].table")
	setq( _csv_addr strcat( _allegro_path "/" _csv_filename))
	setq( _table_addr strcat( _allegro_path "/" _table_filename))

	setq( _manipulate_xlsx_proc 'manipulate_xlsx_main_Derek06122018)
	setq( _setup_board_init_proc 'setup_board_init_main_Derek06062019)
	setq( _create_logo_proc 'create_logo_main_Derek06112019)
	setq( _setup_xsection_proc 'setup_xsection_main_Derek06242019)
	setq( _setup_artwork_proc 'setup_artwork_main_Derek06042019)
	setq( _create_shape_on_board_proc 'create_shape_on_board_main_Derek03262019)
	setq( _stack_up_table_proc 'stack_up_table_main_Derek06212017)
	setq( _fab_note_proc 'fab_note_main_Derek06282017)
	setq( _setup_pcb_form_data_proc 'setup_pcb_form_data_main_Derek05222019)
	
	;;; local define
	setq( _to_run nil)
	setq( _form_filename "setup_board_panel.form")
	setq( _form_handle 'setup_board_panel)
	setq( _setup_board_panel_table makeTable( "setup_board_panel" nil))
	
	setq( _init_key "setup_board_init")
	setq( _logo_key "create_logo")
	setq( _xsect_key "create_xsection")
	setq( _art_key "create_artwork")
	setq( _kpt_key "create_keepout")
	setq( _stack_key "create_stackup")
	setq( _fab_key "create_fab_note")
	setq( _form_key "setup_form")
	
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	setq( _tmp_dirname sprintf( nil "tmp_%d%s%d%d%d%d" _year _month _date _hour _minute _second))
	
	t
)



procedure( check_init_Derek06122019( )
	prog( ()
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		when( (_allegro_version < 16.6) println( "Allegro verions has to be greater than 16.6") return( nil))
		unless( equal( "LAYOUT" _allegro_type) println( "Allegro has to be layout editor") return ( nil))
		unless( equal( "MILS" _allegro_unit) println( "Unit of Allegro has to be mils") return( nil))
	;	axlDBGetDesign()->prop->??
	;	foreach( x axlVersion() printf( "[%s] - %L\n" x axlVersion( x)))
		
		
		;;; ------------------------------------------------------------------------------------------------------------------------ remove later
	;	(load "manipulate_xlsx_v3.il")
	;	(load "setup_board_init_v1.il")
	;	(load "xsection_artwork_v5.il")
	;	(load "setup_artwork_v1.il")
	;	(load "create_shape_on_board_v2.il")
	;	(load "stack_up_table_creator_v7.il")
	;	(load "fab_note_creator_v8.il")
	;	(load "setup_pcb_form_data_v1.il")
		;;; ------------------------------------------------------------------------------------------------------------------------
		
		
		unless( isCallable( _manipulate_xlsx_proc) println( "ERROR: Fail to call 'manipulate_xlsx' function") return( nil))
		unless( isCallable( _setup_board_init_proc) println( "ERROR: Fail to call 'setup_board_init' function") return( nil))
		unless( isCallable( _setup_xsection_proc) println( "ERROR: Fail to call 'xsection_artwork' function") return( nil))
		unless( isCallable( _setup_artwork_proc) println( "ERROR: Fail to call 'setup_artwork' function") return( nil))
		unless( isCallable( _create_shape_on_board_proc) println( "ERROR: Fail to call 'create_shape_on_board' function") return( nil))
		unless( isCallable( _stack_up_table_proc) println( "ERROR: Fail to call 'stack_up_table' function") return( nil))
		unless( isCallable( _fab_note_proc) println( "ERROR: Fail to call 'fab_note' function") return( nil))
		unless( isCallable( _setup_pcb_form_data_proc) println( "ERROR: Fail to call 'setup_pcb_form_data' function") return( nil))
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_form_Derek06122019( )
	prog( ( out_port group_width content_x sub_content_x group_x group_y y_start y_end)
		when( isFile( _form_filename) deleteFile( _form_filename))
		out_port = outfile( _form_filename "w")
		unless( outportp( out_port) println( "ERROR: write_form() - Fail to write file") return( nil))
		;;
		
		;;; general
		
		group_width = 20
		content_x = 3
		sub_content_x = content_x + 2
		group_x = 1
		
		;;; ------------------------------------------------------------------------- headr
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" (group_width + 2) 100)
		fprintf( out_port "HEADER \"%s\"\n" "Setup Board Panel")
		fprintf( out_port "TILE\n")
		
		;;; ------------------------------------------------------------------------- contents
		
		;;;;; setup panel
		
		group_y = 1
		y_start = group_y
		y_end = y_start
		
		fprintf( out_port "FIELD %s\n" 'ctrl_all)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" 'All 'ctrl)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'ctrl_rfq)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" "RFQ" 'ctrl)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'ctrl_kickoff)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" "Kick Off" 'ctrl)
		fprintf( out_port "ENDFIELD\n")

		fprintf( out_port "FIELD %s\n" 'ctrl_none)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \"%s\" \n" 'None 'ctrl)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "GROUP \"%s\"\n" 'Control)
		fprintf( out_port "FLOC %d %d\n" group_x group_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width (y_end - y_start + 2))
		fprintf( out_port "ENDGROUP\n")
		
		;;;;; setup options
		
		group_y = y_end + 2
		y_start = group_y
		y_end = y_start
		
		fprintf( out_port "FIELD %s\n" _init_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Board Init")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _xsect_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Xsection")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _art_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Artwork")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _logo_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Logo")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _kpt_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Rt/Pkg Keepout")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _stack_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Stackup Draw")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _fab_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " Fab Note Draw")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" _form_key)
		fprintf( out_port "FLOC %d %d\n" content_x (y_end = (y_end + 2)))
		fprintf( out_port "CHECKLIST \" %s\" \n" " PCB Form")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "GROUP \"%s\"\n" 'Process)
		fprintf( out_port "FLOC %d %d\n" group_x group_y)
		fprintf( out_port "TSSIZE %d %d\n" group_width (y_end - y_start + 2))
		fprintf( out_port "ENDGROUP\n")
		
		;;;;; run button
		
		group_y = y_end + 1
		y_start = group_y
		y_end = y_start
		
		fprintf( out_port "FIELD %s\n" 'run)
		fprintf( out_port "FLOC %d %d\n" group_x (y_end = (y_end + 2)))
		fprintf( out_port "MENUBUTTON \"RUN\" %d %d\n" group_width 2)
		fprintf( out_port "ENDFIELD\n\n")
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		;;; ------------------------------------------------------------------------- tails
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		;;; end of out_port
		close( out_port)
		
		
		return( t)
	)
)

procedure( set_form_process_Derek06122019( form_id nt lg xsctn rtwrk kpt stck fb frm)
	unless( axlIsFormType( form_id) println( "ArgErr: set_form_process() - form_id is not in form type") return( nil))
	unless( booleanp( nt) println( "ArgErr: set_form_process() - board_init is not in boolean type") return( nil))
	unless( booleanp( lg) println( "ArgErr: set_form_process() - logo is not in boolean type") return( nil))
	unless( booleanp( xsctn) println( "ArgErr: set_form_process() - xsection is not in boolean type") return( nil))
	unless( booleanp( rtwrk) println( "ArgErr: set_form_process() - artwork is not in boolean type") return( nil))
	unless( booleanp( kpt) println( "ArgErr: set_form_process() - keepout is not in boolean type") return( nil))
	unless( booleanp( stck) println( "ArgErr: set_form_process() - stackup is not in boolean type") return( nil))
	unless( booleanp( fb) println( "ArgErr: set_form_process() - fab is not in boolean type") return( nil))
	unless( booleanp( frm) println( "ArgErr: set_form_process() - form is not in boolean type") return( nil))
	;;
	
	;;
	axlFormSetField( form_id _init_key nt)
	axlFormSetField( form_id _logo_key lg)
	axlFormSetField( form_id _xsect_key xsctn)
	axlFormSetField( form_id _art_key rtwrk)
	axlFormSetField( form_id _kpt_key kpt)
	axlFormSetField( form_id _stack_key stck)
	axlFormSetField( form_id _fab_key fb)
	axlFormSetField( form_id _form_key frm)
	
	return( t)
)

procedure( set_form_Derek06122019( form_id)
	prog( ()
		unless( axlIsFormType( form_id) println( "ArgErr: set_form() - form_id is not in form type") return( nil))
		;;
		
		axlFormSetField( form_id "ctrl_all" t)
		
		set_form_process_Derek06122019( form_id t t t t t t t t)
		
		return( t)
	)
)

procedure( form_action_Derek06122019( form_id)
	prog( ( cur_field status)
		unless( axlIsFormType( form_id) println( "ArgErr: form_action() - form_id is not in form type") return( nil))
		;;
		
		cur_field = form_id->curField
		
		case( cur_field
			( "ctrl_all"
				set_form_process_Derek06122019( form_id t t t t t t t t)
			)
			( "ctrl_rfq"
				set_form_process_Derek06122019( form_id t t t t nil nil nil nil)
			)
			( "ctrl_kickoff"
				set_form_process_Derek06122019( form_id nil nil nil nil nil t t t)
			)
			( "ctrl_none"
				set_form_process_Derek06122019( form_id nil nil nil nil nil nil nil nil)
			)
			( "run"
				status = axlFormGetField( form_id _init_key)
				_setup_board_panel_table[ _init_key] = status
				
				status = axlFormGetField( form_id _logo_key)
				_setup_board_panel_table[ _logo_key] = status
				
				status = axlFormGetField( form_id _xsect_key)
				_setup_board_panel_table[ _xsect_key] = status
				
				status = axlFormGetField( form_id _art_key)
				_setup_board_panel_table[ _art_key] = status
				
				status = axlFormGetField( form_id _kpt_key)
				_setup_board_panel_table[ _kpt_key] = status
				
				status = axlFormGetField( form_id _stack_key)
				_setup_board_panel_table[ _stack_key] = status
				
				status = axlFormGetField( form_id _fab_key)
				_setup_board_panel_table[ _fab_key] = status
				
				status = axlFormGetField( form_id _form_key)
				_setup_board_panel_table[ _form_key] = status
				
				;;
				_to_run = t
				axlFormClose( form_id)
			)
		)
	
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( move_in_files( filenames)
	prog( ( file_ls from_addr to_addr)
		unless( filenames println( "ArgErr: move_in_files() - filenames is nil") return( nil))
		unless( dtpr( filenames) (filenames = list( filenames)))
		unless( forall( x filenames and( stringp( x) isFile( x))) println( "ArgErr: move_in_files() - filenames is neither string or file") return( nil))
		;;
		
		;;;; create an empty dir
		if( isDir( _tmp_dirname) then
			file_ls = getDirFiles( _tmp_dirname)
			foreach( file file_ls deleteFile( file))
		else
			createDir( _tmp_dirname)
		)
		
		;;;; move files
		foreach( file filenames
			from_addr = file
			to_addr	= strcat( _tmp_dirname "/" file)
			axlOSFileMove( from_addr to_addr)
		)
		
		return( t)
	)
)

procedure( move_out_files()
	let( ( file_ls from_addr to_addr)
		when( isDir( _tmp_dirname)
			file_ls = getDirFiles( _tmp_dirname)
			foreach( file file_ls
				from_addr = strcat( _tmp_dirname "/" file)
				to_addr = file
				axlOSFileMove( from_addr to_addr)
			)
			
			deleteDir( _tmp_dirname)
		)
		
		t
	)
)

procedure( execute_process_Derek06122019( )
	prog( ( msg valid_csv)
		when( _setup_board_panel_table[ _init_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _init_key)
			
			;;;; save the current extracted csv file to a temp directory
			when( isFile( _csv_filename) move_in_files( _csv_filename))
			
			;;;; to initlize board
			funcall( _setup_board_init_proc)
			
			;;;; restore the origin csv file
			move_out_files()
		)
		
		when( or( _setup_board_panel_table[ _xsect_key] _setup_board_panel_table[ _stack_key])
			msg = "Please select the target stack-up table xlsx"
			funcall( _manipulate_xlsx_proc ?question_to_select msg)
			;;
			unless( and( isFile( _table_addr) isFile( _csv_addr))
				printf( "ERROR: execute_process() - Fail to create [%s] or [%s]. xsection and stack-up table may be affected\n"
					_table_addr _csv_addr)
			)
		)
		
		when( _setup_board_panel_table[ _xsect_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _xsect_key)
			funcall( _setup_xsection_proc ?table_addr _table_addr)
		)
		
		when( _setup_board_panel_table[ _art_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _art_key)
			funcall( _setup_artwork_proc)
		)
		
		when( _setup_board_panel_table[ _logo_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _logo_key)
			funcall( _create_logo_proc)
		)
		
		when( _setup_board_panel_table[ _kpt_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _kpt_key)
			funcall( _create_shape_on_board_proc)
		)
		
		when( _setup_board_panel_table[ _stack_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _stack_key)
			funcall( _stack_up_table_proc ?csv_addr _csv_addr)
		)
		
		when( _setup_board_panel_table[ _fab_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _fab_key)
			funcall( _fab_note_proc)
		)
		
		when( _setup_board_panel_table[ _form_key]
			printf( "\n ============================================================ Start running [%s]\n\n" _form_key)
			funcall( _setup_pcb_form_data_proc)
		)
		
		t
	)
)

procedure( setup_board_panel_main_Derek06122019( )
	prog( ( form_id)
		;;
		init_Derek06122019( )
		
		;;
		unless( check_init_Derek06122019( ) return( nil))
		
		;;; form process
		unless( write_form_Derek06122019( ) return( nil))
		form_id = axlFormCreate( _form_handle _form_filename '( "east" "outer") 'form_action_Derek06122019 nil)
		unless( axlIsFormType( form_id) println( "Please close current form before opening a new one") return( nil))
		set_form_Derek06122019( form_id)
		axlFormDisplay( form_id)
		
		;;; execute process
		when( isFile( _csv_addr) deleteFile( _csv_addr))
		execute_process_Derek06122019( )
		
		;;; clean Dir
		when( isFile( _form_filename) deleteFile( _form_filename))
		
		;;;
		axlUIConfirm( "'Setup Board Panel' process is done. Please check this out")
		println( "'Setup Board Panel' process is done. Please check this out")
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

; (load "manipulate_xlsx_v3.ile")
axlCmdRegister( "setup_board_panel" 'setup_board_panel_main_Derek06122019)
; (setup_board_panel_main_Derek06122019)
; skill (encrypt "c:/skill/setup_board_panel_v1.il" "c:/skill/setup_board_panel_v1.ile")
; (load "setup_board_panel_v1.ile")
; (load "setup_board_panel_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup