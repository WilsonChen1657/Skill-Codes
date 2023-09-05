;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 03/06/2019 - _Derek03062019
; Introduction: This tool is used to generate and achieve part of item of the gerber line package, including
;	3.<brd name>_date(brd).7z
;	4.<brd name>_date(dxf).7z
;	5.<brd name>_date(emn_emp).7z
;	6.<brd name>_date(odb++).7z
;	7.<brd name>_date(cad).7z
;	8.<brd name>_date(gbr).7z
;	10.<brd name>_date(panel).7z
;	11.<brd name>_date(pcba).7z
;	13.<brd name>_component.txt
;
; background:
;	1. the former version of this skill tool is gerber_tool_v7
;	2. the updated part
;		1. layer of pcba_top
;		2. layer of pcba_bot
;		3. layer of panel
;		4. pcba_top, pcba_bot and panel will permanently exists in artwork
;		5. no panel and pcba_top/pcba_bot for gbr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek03062019()
	setq( _work_name axlCurrentDesign())
	setq( _work_path getWorkingDir())
	setq( _work_addr axlGetDrawingName())
	setq( _odb_path getShellEnvVar( "ALLEGRO_BRD2ODB"))
	setq( _odb_addr strcat( _odb_path "\\brd2odb.exe"))
	setq( _valor_addr strcat( _odb_path "/valor_ext.il"))
	setq( _allegro_version axlVersion( 'version))
	
	;;;;; get allegro version
	sprintf( _allegro_version_full "Allegro_%.1f_%s" _allegro_version axlVersion( 'buildDate))
	
	;;;;; ge time stamp
	setq( _mon_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" mon date hr min sec year)
	sprintf( _today "%.4d%.2d%.2d" year listnindex( _mon_ls mon) date)
	
	;;;;; get cad file name
	setq( _gerber_file_term get_main_gerber_name_Derek03062019())
	sprintf( _gerber_dir "CAD_DATA_%s" _today)
	sprintf( _gerber_addr "%s/%s" _work_path _gerber_dir)
	setq( _gerber_back_addr axlOSBackSlash( _gerber_addr))
	
	;;;;; deal with log
	unless( stringp( axlGetVariable( "ads_sdlog")) axlSetVariable( "ads_sdlog" "log"))
	unless( isDir( (dir = axlGetVariable("ads_sdlog"))) createDir( dir))
	
	;;;;; deal with artwork
	unless( stringp( axlGetVariable( "ads_sdart")) axlSetVariable( "ads_sdart" "artwork"))
	setq( _art_dir axlGetVariable("ads_sdart"))
	if( isDir( _art_dir)
		delete_extra_file_Derek03062019( getDirFiles( _art_dir) _art_dir)
		createDir( _art_dir)
	)
	
	;;;;; form section
	setq( _gb_form_nm "gerber_tool_panel.form")
	setq( _package_table makeTable( "package_table" nil))
	
	;;; get legel film list
	setq( _film_ls axlGetParam( "artwork")->groupMembers)
	_film_ls = setof( f _film_ls plusp( atoi( car( parseString( f "-")))))
	_film_ls = sort( _film_ls 'film_bigger_Derek03062019)
	
	;;;;; user define
	setq( _to_run nil)
	setq( _etch_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _etch_total axlGetParam( "paramLayerGroup:ETCH")->nChildren)
	setq( _exists_ncroute is_ncroute_exists_Derek03062019())
	setq( _exists_backdrill is_backdrill_exists_Derek03062019())
	setq( _exists_thru_p_np is_thru_p_np_exists_Derek03062019())
	
	setq( _panel_film_nm get_full_from_list_Derek03062019( "PANEL" _film_ls 'artwork_film))
	setq( _pcba_top_film_nm get_full_from_list_Derek03062019( "PCBA-TOP" _film_ls 'artwork_film))
	setq( _pcba_bot_film_nm get_full_from_list_Derek03062019( "PCBA-BOT" _film_ls 'artwork_film))
	setq( _pcb_fab_film_nm get_full_from_list_Derek03062019( "PCB-FAB" _film_ls 'artwork_film))
	
	setq( _gbr_film_ls setof( f _film_ls not( member( f list( _panel_film_nm _pcba_top_film_nm _pcba_bot_film_nm)))))
	
	setq( _outline_ly if( (_allegro_version > 17.0) '( "BOARD GEOMETRY/CUTOUT" "BOARD GEOMETRY/DESIGN_OUTLINE") '( "BOARD GEOMETRY/OUTLINE")))
	setq( _mh_top_ly_nm "BOARD GEOMETRY/ME_HOLE_TOP")
	setq( _mh_bot_ly_nm "BOARD GEOMETRY/ME_HOLE_BOT")
	setq( _cfg_filename "iDfFilterOut.config")
	setq( _gbr_index "00-index.csv")
	setq( _art_prm_nm "art_param.txt")
	setq( _nc_prm_nm "nc_param.txt")
	setq( _nc_rou_nm "ncroutebits.txt")
	
	setq( _gbr_index_addr strcat( _art_dir "/" _gbr_index))
	setq( _art_addr strcat( _art_dir "/" _art_prm_nm))
	setq( _nc_prm_addr strcat( _art_dir "/" _nc_prm_nm))
	
	setq( _dxf_top_trace_ly_ls append( list( "PIN/FILMMASKTOP"
							"PIN/TOP"
							"ETCH/TOP"
							"VIA CLASS/TOP"
							"DRAWING FORMAT/TOP"
							"BOARD GEOMETRY/LOGO"
							"BOARD GEOMETRY/SILKSCREEN_TOP"
							"PACKAGE GEOMETRY/SILKSCREEN_TOP"
							_mh_top_ly_nm) _outline_ly))
	
	setq( _dxf_top_sym_ly_ls append( list( "PIN/FILMMASKTOP"
							"PIN/TOP"
							"DRAWING FORMAT/TOP"
							"BOARD GEOMETRY/LOGO"
							"BOARD GEOMETRY/SILKSCREEN_TOP"
							"PACKAGE GEOMETRY/SILKSCREEN_TOP"
							_mh_top_ly_nm) _outline_ly))
	
	setq( _dxf_bot_trace_ly_ls append( list( "PIN/FILMMASKBOTTOM"
							"PIN/BOTTOM"
							"ETCH/BOTTOM"
							"VIA CLASS/BOTTOM"
							"DRAWING FORMAT/BOTTOM"
							"BOARD GEOMETRY/LOGO"
							"BOARD GEOMETRY/SILKSCREEN_BOTTOM"
							"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
							_mh_bot_ly_nm) _outline_ly))
	
	setq( _dxf_bot_sym_ly_ls append( list( "PIN/FILMMASKBOTTOM"
							"PIN/BOTTOM"
							"DRAWING FORMAT/BOTTOM"
							"BOARD GEOMETRY/LOGO"
							"BOARD GEOMETRY/SILKSCREEN_BOTTOM"
							"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
							_mh_bot_ly_nm) _outline_ly ))
	
;	setq( _pcba_top_layer list( "BOARD GEOMETRY/OUTLINE"
;						"BOARD GEOMETRY/ASSEMBLY_NOTES"
;						"BOARD GEOMETRY/LOGO"
;						"REF DES/SILKSCREEN_TOP"
;						"PIN/TOP"
;						"BOARD GEOMETRY/SILKSCREEN_TOP"
;						"PACKAGE GEOMETRY/SILKSCREEN_TOP"
;						"COMPONENT VALUE/SILKSCREEN_TOP"
;						"DRAWING FORMAT/PCBA_TOP"))
;						
;	setq( _pcba_bot_layer list( "BOARD GEOMETRY/OUTLINE"
;						"BOARD GEOMETRY/ASSEMBLY_NOTES"
;						"BOARD GEOMETRY/LOGO"
;						"REF DES/SILKSCREEN_BOTTOM"
;						"PIN/BOTTOM"
;						"BOARD GEOMETRY/SILKSCREEN_BOTTOM"
;						"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
;						"COMPONENT VALUE/SILKSCREEN_BOTTOM"
;						"DRAWING FORMAT/PCBA_BOT"))


	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( build_form_Derek03062019()
	prog( (out_port group_width group_x content_x y_cnt y_start)
		out_port = outfile( _gb_form_nm "w")
		unless( outportp( out_port) println( "ERROR: build_form() - Fail to write form") return( nil))
		;;
		
		group_width = 20
		group_x = 1
		content_x = 3
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" add1( group_width) 100)
		fprintf( out_port "HEADER \"Gerber Package Selector\"\n")
		fprintf( out_port "TILE\n")
		
		;;;;;
		
		y_cnt = 1
		y_start = y_cnt
		
		fprintf( out_port "FIELD ctrl_all\n")
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" All\" \"ctrl\" \n")
		fprintf( out_port "ENDFIELD\n")

		fprintf( out_port "FIELD ctrl_none\n")
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" None\" \"ctrl\" \n")
		fprintf( out_port "ENDFIELD\n")
			
		fprintf( out_port "GROUP \"%s\"\n" 'Control)
		fprintf( out_port "FLOC %d %d\n" group_x y_start)
		fprintf( out_port "TSSIZE %d %d\n" group_width (y_cnt - y_start + 2))
		fprintf( out_port "ENDGROUP\n")
		
		;;;;;
		
		y_cnt = y_cnt + 2
		y_start = y_cnt
		
		fprintf( out_port "FIELD %s\n" 'brd_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" BRD\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'dxf_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" DXF\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'emn_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" EMN/EMP\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'odb_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" ODB++\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'cad_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" CAD\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'gbr_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" GBR\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'panel_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" PANEL\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'pcba_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" PCBA\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "FIELD %s\n" 'comp_create)
		fprintf( out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		fprintf( out_port "CHECKLIST \" COMPONENT\" \n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "GROUP \"%s\"\n" 'Package)
		fprintf( out_port "FLOC %d %d\n" group_x y_start)
		fprintf( out_port "TSSIZE %d %d\n" group_width (y_cnt - y_start + 2))
		fprintf( out_port "ENDGROUP\n")
		
		;;;;;
		
		y_cnt = y_cnt + 3
		y_start = y_cnt
		
		fprintf( out_port "FIELD %s\n" 'run)
		fprintf( out_port "FLOC %d %d\n" group_x y_start)
		fprintf( out_port "MENUBUTTON \"RUN\" %d %d\n" group_width 2)
		fprintf( out_port "ENDFIELD\n\n")
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( set_form_package_to_Derek03062019( out_form opt)
	prog( ()
		unless( axlIsFormType( out_form) println( "ArgErr: set_form_package_to() - out_form is not a form") return( nil))
		unless( booleanp( opt) println( "ArgErr: set_form_package_to() - opt is not a boolean") return( nil))
		;;
		
		axlFormSetField( out_form "brd_create" opt)
		axlFormSetField( out_form "dxf_create" opt)
		axlFormSetField( out_form "emn_create" opt)
		axlFormSetField( out_form "odb_create" opt)
		axlFormSetField( out_form "cad_create" opt)
		axlFormSetField( out_form "gbr_create" opt)
		axlFormSetField( out_form "panel_create" opt)
		axlFormSetField( out_form "pcba_create" opt)
		axlFormSetField( out_form "comp_create" opt)
		
		return( t)
	)
)

procedure( set_package_table_Derek03062019( out_form)
	prog( ()
		unless( axlIsFormType( out_form) println( "ArgErr: set_package_table() - out_form is not a form") return( nil))
		;;
		
		_package_table[ 'brd_create] = axlFormGetField( out_form "brd_create")
		_package_table[ 'dxf_create] = axlFormGetField( out_form "dxf_create")
		_package_table[ 'emn_create] = axlFormGetField( out_form "emn_create")
		_package_table[ 'odb_create] = axlFormGetField( out_form "odb_create")
		_package_table[ 'cad_create] = axlFormGetField( out_form "cad_create")
		_package_table[ 'gbr_create] = axlFormGetField( out_form "gbr_create")
		_package_table[ 'panel_create] = axlFormGetField( out_form "panel_create")
		_package_table[ 'pcba_create] = axlFormGetField( out_form "pcba_create")
		_package_table[ 'comp_create] = axlFormGetField( out_form "comp_create")
		
		return( t)
	)
)

procedure( out_form_action_Derek03062019( out_form)
	prog( (cur_field)
		unless( axlIsFormType( out_form) println( "ArgErr: out_form_action() - out_form is not a form") return( nil))
		;;
		
		cur_field = out_form->curField
		;;
		
		(case cur_field
			("ctrl_all" set_form_package_to_Derek03062019( out_form t))
			("ctrl_none" set_form_package_to_Derek03062019( out_form nil))
			("run"
				set_package_table_Derek03062019( out_form)
				axlFormClose( out_form)
				
				;;;;; create item iterally
				_to_run = t
				create_gerber_items_Derek03062019()
			)
			(("" "brd_create" "dxf_create" "emn_create" "odb_create" "cad_create" "gbr_create" "panel_create" "pcba_create" "comp_create")
			)
			(t printf("ArgErr: out_form_action() - Not define field [%s] yet\n" cur_field))
		)
	)
)

procedure( set_form_Derek03062019( out_form)
	prog( ()
		unless( axlIsFormType( out_form) println( "ArgErr: set_form() - out_form is not a form") return( nil))
		;;
		
		axlFormSetField( out_form "ctrl_all" t)
		set_form_package_to_Derek03062019( out_form t)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_full_from_list_Derek03062019( term name_ls tag)
	prog( ( target_ls total result)
		unless( symbolp( tag) println( "ArgErr: get_full_from_list() - tag is not a symbol") return( nil))
		unless( stringp( term) println( "ArgErr: get_full_from_list() - term is not a string") return( nil))
		unless( dtpr( name_ls) println( "ArgErr: get_full_from_list() - name_ls is not a dtpr") return( nil))
		unless( forall( n name_ls stringp( n)) println( "ArgErr: get_full_from_list() - name_ls is not a string list") return( nil))
		;;
		
		target_ls = setof( n name_ls index( n term))
		total = length( target_ls)
		caseq( total
			(0
				printf( "ERROR: get_full_from_list() - None of [%s] has been found in [%s] list\n" term tag)
			)
			(1
				result = car( target_ls)
			)
			(t
				printf( "WARNING: get_full_from_list() - Multiple name[%L] have been found by [%s] in [%s] list. Get first one.\n" target_ls term tag)
				result = car( targer_ls)
			)
		)
		
		return( result)
	)
)

procedure( get_main_gerber_name_Derek03062019()
	prog( (file_nm f result)
		;;;;; to escape

		file_nm = upperCase( _work_name)
		if( index( file_nm "-") then
			f = car( parseString( file_nm "-"))
		else
			f = axlEnterString( ?prompts "Certain Brd term can't be gotten. Please enter CAD name")
			unless( stringp( f) return( nil))
			
			when( zerop( strlen( f))
				println( "You have to at least enter one character to trigger this function. Process halt")
				return( nil)
			)
		)
		
		sprintf( result "%s_%s%%s" f _today)
		
		return( result)
	)
)

procedure( is_ncroute_exists_Derek03062019()
	prog( (plated unplated plating sym_ls pin_ls result)
		;;; get all symbol
		sym_ls = axlDBGetDesign()->symbols
		
		;;; get pins which are through
		pin_ls = (mapcan (lambda (s) setof( p s->pins p->isThrough )) sym_ls)
		
		;;; get through pins which is not in circle
		pin_ls = (mapcan (lambda (p) unless( equal( "circle_drill" p->definition->holeType) list( p))) pin_ls)
		
		;;
		result = dtpr( pin_ls)
		plated = unplated = 0
		when( result
			foreach( pin_id pin_ls
				plating = pin_id->definition->plating
				if( equal( "PLATED" plating)
					plated++
					unplated++
				)
			)
		)
		
		;;
		if( result
			printf( "\tThis board has ncroute. Number of non-circle drill: [plated:%d] [unplated:%d]\n" plated unplated)
			printf( "\tThis board does not have ncroute\n")
		)
		
		;;
		result = if( result list( plated unplated) nil)
		
		return( result)
	)
)

procedure( is_thru_p_np_exists_Derek03062019()
	prog( ( sym_ls thru_pin_ls has_plated_pin has_non_plated_pin result)
		;;;; get thru pin info
		axlDBGetDesign()->padstacks 
		sym_ls = axlDBGetDesign()->symbols
		
		thru_pin_ls = mapcan( lambda( (x) setof( y x->pins y->isThrough)) sym_ls)
		has_plated_pin = dtpr( setof( x thru_pin_ls equal( "PLATED" x->definition->plating)))
		has_non_plated_pin = dtpr( setof( x thru_pin_ls equal( "NON_PLATED" x->definition->plating)))
		
		result = list( has_plated_pin has_non_plated_pin)
		
		return( result)
	)
)

procedure( is_backdrill_exists_Derek03062019()
	;;; ncbg = "NCBACKDRILL-1-13"
	prog( (ncbg_ls layer film_ls total_figure start_ly end_ly bg_se result)
		ncbg_ls = axlGetParam("paramLayerGroup:MANUFACTURING")->groupMembers
		unless( dtpr( ncbg_ls) println( "This board does not have any MANUFACTURING/NCBACKDRILL") return( nil))
		
		axlSetFindFilter( ?enabled list( "FIGURES") ?onButtons list( "FIGURES"))
		
		rexCompile( "^NCBACKDRILL-\\([0-9]+\\)-\\([0-9]+\\)$")
		foreach( ncbg ncbg_ls
			when( rexExecute( ncbg)
				layer = strcat( "MANUFACTURING/" ncbg)
				make_visible_layers_Derek03062019( layer)
				axlAddSelectAll()
				total_figure = axlGetSelSetCount()
				axlClearSelSet()
				;;
				unless( zerop( total_figure)
					start_ly = rexSubstitute( "\\1")
					end_ly = rexSubstitute( "\\2")
					bg_se = list( start_ly end_ly)
					result = append1( result bg_se)
				)
			)
		)
		
		axlSetFindFilter( ?enabled list( "NOALL") ?onButtons list( "NOALL"))
		
		if( dtpr( result)
			printf( "\tThis board has backdrill[from/to]: %L\n" result)
			printf( "\tThis board has no backdrill\n")
		)
		
		return( result)
	)
)

procedure( archieve_7z_Derek03062019( file_names achieve_name @optional (ext ".7z"))
	prog( (err files_line cmd non_exists_file_ls)
		err = "ERROR: archieve_7z() -"
		argerr = "ArgErr: archieve_7z() -"
		if( dtpr( file_names)
			unless( forall( f file_names stringp( f)) printf( "%s file_names list contain non-string %L\n" argerr file_names) return( nil))
			unless( stringp( file_names) printf( "%s file_names is not a string\n" argerr) return( nil))
		)
		if( dtpr( file_names)
			unless( forall( f file_names isFile( f))
				non_exists_file_ls = setof( x file_names not( isFile( x)))
				printf( "%s file_names list contain non-file-name %L\n" argerr non_exists_file_ls)
				return( nil)
			)
			unless( isFile( file_names) printf( "%s file_names is not a file\n" argerr) return( nil))
		)
		
		;;
		achieve_name = strcat( achieve_name ext)
		achieve_addr = strcat( _gerber_dir "\\" achieve_name)
		when( isFile( achieve_addr) printf( "%s Exists achieve file: %s\n" err achieve_name) return( nil))
		
		;;; convert multiple file name into a line with space 
		if( dtpr( file_names)
			files_line = (buildString file_names " ")
			files_line = file_names
		)
		
		;;; zip up the files
		sprintf( cmd "\"C:\\Program Files\\7-Zip\\7z\" a %s %s" achieve_name files_line)
		unless( sh( cmd)
			printf( "%s Fail to create achieve file: %s\n" err achieve_name)
			return( nil)
		)
		
		;;; move the zipped file to CAD directory
		unless( axlOSFileMove( achieve_name achieve_addr)
			printf( "%s Fail to move file: %s\n" err achieve_name)
			return( nil)
		)
		
		printf( "Successfully create file: %s\n" achieve_name)
		
		return( t)
	)
)

procedure( create_dxf_cnv_Derek03062019( cnv_nm cnv_tag is_etch)
	prog( (out_port me_ly silk_ly)
		unless( booleanp( is_etch) println( "ArgErr: create_dxf_cnv() - is_etch is not a boolean") return( nil))
		unless( stringp( cnv_nm) println( "ArgErr: create_dxf_cnv() - cnv_nm is not a string") return( nil))
		unless( stringp( cnv_tag) println( "ArgErr: create_dxf_cnv() - cnv_tag is not a string") return( nil))
		unless( member( cnv_tag '("TOP" "BOTTOM")) println( "ArgErr: create_dxf_cnv() - cnv_tag is neither TOP or BOTTOM") return( nil))
		out_port = outfile( cnv_nm)
		unless( outportp( out_port) printf( "ERROR: create_dxf_cnv() - Fail to write file [%s]\n" cnv_nm) return( nil))
		
		;;
		me_ly = if( equal( "TOP" cnv_tag) _mh_top_ly_nm _mh_bot_ly_nm)
		me_ly = cadr( parseString( me_ly "/"))
		silk_ly = if( index( "TOP" cnv_tag) "SILKSCREEN_TOP" "SILKSCREEN_BOTTOM")
		
		;;
		fprintf( out_port "#This is the Layer Conversion File used for\n")
		fprintf( out_port "#importing DXF data into Allegro/APD.\n\n")
		fprintf( out_port "#CLASS!            SUBCLASS!                           DXF_LAYER!\n\n")
		
		;;
		bg_form = "\t%s!\tBG_%s!\n"
		fprintf( out_port "BOARD GEOMETRY!\n")
		fprintf( out_port bg_form "LOGO" "LOGO")
		fprintf( out_port bg_form "OUTLINE" "OUTLINE")
		fprintf( out_port bg_form me_ly me_ly)
		fprintf( out_port bg_form silk_ly silk_ly)		
		
		;;
		fprintf( out_port "PACKAGE GEOMETRY!\n\t%s!\tBG_%s!\n" silk_ly silk_ly)
		
		;;
		fprintf( out_port "DRAWING FORMAT!\n\t%s!\tDF_%s!\n" cnv_tag cnv_tag)
		
		;;
		when( is_etch
			fprintf( out_port "ETCH!\n\t%s!\tET_%s!\n" cnv_tag cnv_tag)
			fprintf( out_port "VIA CLASS!\n\t%s!\tVC_%s!\n" cnv_tag cnv_tag)
		)
		
		;;
		fprintf( out_port "PIN!\n")
		fprintf( out_port "\t%s!\tPIN_%s!\n" cnv_tag cnv_tag)
		fprintf( out_port "\tFILMMASK%s!\tPIN_FILMMASK%s!\n" cnv_tag cnv_tag)
		
		;;
		fprintf( out_port "\n#END")
		
		;;
		close( out_port)
		
		return( t)
	)
)

procedure( make_visible_layers_Derek03062019( layer_ls)
	prog( ()
		unless( dtpr( layer_ls) (layer_ls = list( layer_ls)))
		unless( forall( x layer_ls stringp( x)) println( "ArgErr: make_visible_layers() - layer_ls is not a string or a strign list") return( nil))
		unless( forall( x layer_ls axlIsLayer( x)) println( "ArgErr: make_visible_layers() - layer_ls contain non-layer string") return( nil))
		;;
		
		axlVisibleDesign( nil)
		foreach( layer layer_ls axlVisibleLayer( layer t))
		axlVisibleUpdate( t)
		
		return( t)
	)
)

procedure( create_dxf_Derek03062019( file_nm cnv_tag is_etch vis_ly_ls)
	prog( (cmd cnv_nm dxf_nm)
		unless( stringp( file_nm) println( "ArgErr: create_dxf() - file_nm is not a string") return( nil))
		unless( stringp( cnv_tag) println( "ArgErr: create_dxf() - cnv_tag is not a string") return( nil))
		unless( member( cnv_tag '("TOP" "BOTTOM")) println( "ArgErr: create_dxf() - cnv_tag is neither TOP or BOTTOM") return( nil))
		unless( booleanp( is_etch) println( "ArgErr: create_dxf() - is_etch is not a boolean") return( nil))
		unless( dtpr( vis_ly_ls) println( "ArgErr: create_dxf() - vis_ly_ls is not a list") return( nil))
		;;
		
		cnv_nm = strcat( file_nm ".cnv")
		dxf_nm = strcat( file_nm ".dxf")
		
		create_dxf_cnv_Derek03062019( cnv_nm cnv_tag is_etch)
		
		;;; tune the visible layer
		make_visible_layers_Derek03062019( vis_ly_ls)
		
		sprintf( cmd "a2dxf -u MM -a 4 \"%s\" \"%s\" \"%s\"" cnv_nm dxf_nm _work_addr)
		sprintf( cmd_nm "%s_a2dxf" cnv_tag)
		sprintf( msg "Export %s" dxf_nm)
		axlRunBatchDBProgram( cmd_nm cmd ?startMsg msg ?silent t)
		
		return( t)
	)
)

procedure( get_obl_path_Derek03062019( xy side radius is_hor @optional (pth_wid 0.0))
	prog( xy1( c_xy path side_d2)
		unless( dtpr( xy) println( "ArgErr: get_obl_path() - xy is not a list") return( nil))
		unless( plusp( side) println( "ArgErr: get_obl_path() - side is not a positive number") return( nil))
		unless( plusp( radius) println( "ArgErr: get_obl_path() - radius is not a positive number") return( nil))
		unless( booleanp( is_hor) println( "ArgErr: get_obl_path() - is_hor is not a boolean") return( nil))
		when( minusp( pth_wid) println( "ArgErr: get_obl_path() - pth_wid is not a positive number") return( nil))
		;;
		
		side = float( side)
		radius = float( radius)
		pth_wid = float( pth_wid)
		
		side_d2 = side / 2
		
		if( is_hor then
			xy1 = list( ( car( xy) - side_d2) (cadr( xy) + radius))
			path = axlPathStart( list( xy1) pth_wid)
			;;
			xy1 = axlMXYAdd( xy1 list( side 0))
			axlPathLine( path pth_wid xy1)
			;;
			c_xy = axlMXYSub( xy1 list( 0 radius))
			xy1 = axlMXYSub( c_xy list( 0 radius))
			axlPathArcCenter( path pth_wid xy1 t c_xy)
			;;
			xy1 = axlMXYSub( xy1 list( side 0))
			axlPathLine( path pth_wid xy1)
			;;
			c_xy = axlMXYAdd( xy1 list( 0 radius))
			xy1 = axlMXYAdd( c_xy list( 0 radius))
			axlPathArcCenter( path pth_wid xy1 t c_xy)
		else
			xy1 = list( ( car( xy) - radius) ( cadr( xy) + side_d2))
			path = axlPathStart( list( xy1) pth_wid)
			;;
			c_xy = axlMXYAdd( xy1 list( radius 0))
			xy1 = axlMXYAdd( c_xy list( radius 0))
			axlPathArcCenter( path pth_wid xy1 t c_xy)
			;;
			xy1 = axlMXYSub( xy1 list( 0 side))
			axlPathLine( path pth_wid xy1)
			;;
			c_xy = axlMXYSub( xy1 list( radius 0))
			xy1 = axlMXYSub( c_xy list( radius 0))
			axlPathArcCenter( path pth_wid xy1 t c_xy)
			;;
			xy1 = axlMXYAdd( xy1 list( 0 side))
			axlPathLine( path pth_wid xy1)
		)
		
		return( path)
	)
)

procedure( delete_layer_Derek03062019(ly_nm)
	prog( (ly_id obj_ls visi_ly_ls)
		unless( stringp( ly_nm) println( "ArgErr: delete_layer() - ly_nm is not a string") return( nil))
		unless( axlIsLayer( ly_nm) println( "ArgErr: delete_layer() - ly_nm is not a layer") return( nil))
		;;
		
		ly_id = (axlLayerGet ly_nm)
		unless( ly_id printf( "ERROR: delete_layer() - Fail to get layer id: %s\n" ly_nm) return( nil))
		
		;;;; store the current visible layer and restore later
		axlVisibleLayer( ly_nm nil)
		visi_ly_ls = axlVisibleGet()
		(axlVisibleDesign nil)
		
		;;; display the target layer only and select all the things on it
		axlVisibleLayer( ly_nm t)
		axlSetFindFilter( ?enabled list( "ALL") ?onButtons list( "ALL"))
		axlAddSelectAll()
		obj_ls = axlGetSelSet()
		axlClearSelSet()
		
		;;; remove all the visible things including layer
		obj_ls = setof( x obj_ls equal( ly_nm x->layer))
		foreach( obj obj_ls axlDeleteObject( obj))
		axlDeleteObject( ly_id)
		
		;;; restore the visible layer
		axlVisibleSet( visi_ly_ls)
		
		return( t)
	)
)

procedure( create_me_hole_Derek03062019( mh_ly_nm)
	prog( (ly_id me_ls xy_rx_ry_ls xy pin_id pad_ls et_id pad_box rx ry xrrr side etch_ly type location)
		unless( stringp( mh_ly_nm) println( "ArgErr: create_me_hole() - mh_ly_nm is not a string") return( nil))
		when( axlIsLayer( mh_ly_nm) delete_layer_Derek03062019( mh_ly_nm))
		
		;;; create new me layer
		axlLayerCreateNonConductor( mh_ly_nm)
		
		;;; find line all me symbol
		me_ls = setof( s axlDBGetDesign()->symbols (exists p s->pins p->isThrough))
		;(me_ls = setof( s a (exists p s->pins p->isThrough)))
		me_ls = setof( s me_ls not( equal( "FIDUCIAL" s->component->compdef->prop->VALUE)))
		
		;;; get (xy radius_x radius_y) list
		etch_ly = if( equal( _mh_top_ly_nm mh_ly_nm) "ETCH/TOP" "ETCH/BOTTOM")
		foreach( me_id me_ls
			pin_ls = me_id->pins
			pin_ls = setof( p pin_ls p->isThrough)
			;;
			foreach( pin_id pin_ls
				xrrr = nil
				xy = pin_id->xy
				rotation = pin_id->rotation
			;	;; get pad diameter
			;	(pad_ls = pin_id->pads)
			;	(et_id = car( setof( p pad_ls and( equal( etch_ly p->layer) equal( "REGULAR" p->type)))))
			;	(pad_box = et_id->bBox)
			;	(rx = (abs ((caar pad_box) - (caadr pad_box))))
			;	(ry = (abs ((cadar pad_box) - (cadadr pad_box))))
			;	;;
			;	(xrrr = list( xy rx ry))
			;	(xy_rx_ry_ls = append1( xy_rx_ry_ls xrrr))
				
				;;; get drill diameter
				pin_def = pin_id->definition
				type = pin_def->holeType
				(case type
					("circle_drill"
						rx = pin_def->drillDiameter
						ry = pin_def->drillDiameter
						xrrr = list( xy rx ry rotation)
					)
					("oval_slot"
						rx = pin_def->drillSizeWidth
						ry = pin_def->drillSizeHeight
						xrrr = list( xy rx ry rotation)
					)
					(t
						printf( "ERROR: create_me_hole() - not support drill type [%s] at %L\n" type xy)
					)
				)
				when( dtpr( xrrr) (xy_rx_ry_ls = append1( xy_rx_ry_ls xrrr)))
			)
		)
		
		;;; place outline of me hole onto me layer
		foreach( xrrr xy_rx_ry_ls
			xy = car( xrrr)
			rx = cadr( xrrr)
			ry = (caddr xrrr)
			rotation = (cadddr xrrr)
			;;
			if( axlGeoEqual( rx ry) then
				;;; circle
				radius = rx / 2
				location = list( xy radius)
				axlDBCreateCircle( location 0.0 mh_ly_nm)
			else
				;;; oblong
				if( (rx > ry) then
					;;; horizontal oblong
					side = rx - ry
					radius = ry / 2
					path = get_obl_path_Derek03062019( xy side radius t)
				else
					;;; vertical oblong
					side = ry - rx
					radius = rx / 2
					path = get_obl_path_Derek03062019( xy side radius nil)
				)
				obj_id = caar( axlDBCreatePath( path mh_ly_nm 'line)) ; mh_ly_nm = _mh_top_ly_nm
				unless( zerop( rotation) axlTransformObject( obj_id ?origin xy ?angle rotation))
			)
		)
		
		return( t)
	)
)

procedure( create_top_bot_dxf_Derek03062019()
	let( ( dxf_filename dxf_out_cmd cmd)
		;;;;; create board_geometry/me_hole and place ME hole line circle on it
		create_me_hole_Derek03062019( _mh_top_ly_nm)
		create_me_hole_Derek03062019( _mh_bot_ly_nm)
		
		;;;;; save design
		axlSaveDesign( ?mode "nocheck" ?noConfirm t)
		
		;;;;; create top dxf
		create_dxf_Derek03062019( "TOP" "TOP" nil _dxf_top_sym_ly_ls)
		create_dxf_Derek03062019( "TOP_with_trace" "TOP" t _dxf_top_trace_ly_ls)
		create_dxf_Derek03062019( "BOT" "BOTTOM" nil _dxf_bot_sym_ly_ls)
		create_dxf_Derek03062019( "BOT_with_trace" "BOTTOM" t _dxf_bot_trace_ly_ls)
	)
)

procedure( create_emn_emp_Derek03062019( out_name)
	prog( ( out_port cmd)
		unless( stringp( out_name) println( "ArgErr: create_emn_emp() - out_name is not a string") return( nil))
		out_port = outfile( _cfg_filename "w")
		unless( outportp( out_port) println( "ERROR: create_emn_emp() - Fail to write file") return( nil))
		;;
		
		;;
		fprintf( out_port (buildString list( "("
											"filter"
											"Route_Keepout_sym"
											"Route_Keepout_board"
											"Via_Keepout_sym"
											"Via_Keepout_board"
											"Vias"
											"Panel_Outline"
											"Route_Outline"
											"Package_Keepin"
											"Package_Keepout"
											"Unplaced_Comp"
											")" "  ")))
		close( out_port)
		
		when( axlOKToProceed()
			sprintf( cmd "idf_out \"%s\" -d PTC -o \"%s\" -V 3.0 -b 1 -s \"%s\" -h 1 -c iDfFilterOut.config" _work_addr out_name _allegro_version_full)
		;	(cmd = strcat( "idf_out \"%s\" -d PTC -o \"" out_name "\" -V 3.0 -b 1 -s \"" _allegro_version_full "\" -h 1 -c iDfFilterOut.config"))
			axlRunBatchDBProgram("emn_emp_idf_out" cmd ?startMsg "Export EMN EMP" ?silent t)
		)
	)
)

procedure( delete_extra_file_Derek03062019( file_ls @optional (dir "."))
	let( ( addr)
		;;;;; while using the recursive, addr variable will be overwrited by the next stage called function
		
		foreach( file file_ls
			addr = strcat( dir "/" file)
			when( isFile( addr) deleteFile( addr))
			when( and( isDir( addr) not( member( file '("." ".."))))
				delete_extra_file_Derek03062019( getDirFiles( addr) addr)
				deleteDir( addr)
			)
		)
	)
)

procedure( create_odb_Derek03062019( exe_addr)
	prog( (cmd )
		unless( stringp( exe_addr) println( "ArgErr: create_odb() - exe_addr is not a string") return( nil))
		unless( isFile( exe_addr) println( "ArgErr: create_odb() - exe_addr is not a file") return( nil))
		;;
		
		load( _valor_addr)
		valor_extract_info()
		
		;; -lp: log path
		;; -a2l: appends log messages to existing log file log_brd2obd
		;; -c p: outline-placebound
		;; -jn odbjob: odb++ product model name
		;; -jp: output path for the ODB++ product model
		;; -no_view: runs the translator without opening the ODB++ viewer
		;; -gz: zip ODB++
		;; -read_sqa no: determines whether to create the signal quality layer.
		;; -tr_sym yes: controls the translation of symbols. (yes to translate symbols as components)
		;; -p s: where the <model> is s[ubstitute]
		;; -pst r: defines the symbol type of lines and arcs describing step profile. r[ound]
		;; -skip_refdes no: skip components with refdes containing asterisk characters(*)
		;; -sp: turn eda_cadence_supress on
		
		sprintf( cmd "%s -lp \"%s\" -a2l -c p -jn odbjob -jp \"%s\" -no_view -gz -read_sqa no -tr_sym yes -p s -pst r -skip_refdes no -sp \"%s\""
					exe_addr _work_path _work_path _work_addr)
		axlRunBatchDBProgram( "flex_brd2odb" cmd ?noUnload t ?noProgress nil)
	)
)

procedure( create_script_file_Derek03062019( script_name)
	prog( (out_port)
		unless( stringp( script_name) println( "ArgErr: create_script_file() - script_name is not a string") return( nil))
		out_port = outfile( script_name "w")
		unless( outportp( out_port) println( "ERROR: create_script_file() - Fail to write file") return( nil))
		;;
		
		;;
		fprintf( out_port "#A!REFDES!COMP_CLASS!COMP_PART_NUMBER!COMP_HEIGHT!COMP_DEVICE_LABEL!COMP_INSERTION_CODE!SYM_TYPE\n")    
		fprintf( out_port "#!SYM_NAME!SYM_MIRROR!SYM_ROTATE!SYM_X!SYM_Y!COMP_VALUE!COMP_TOL!COMP_VOLTAGE!\n")    
		fprintf( out_port "COMPONENT \n")
		fprintf( out_port "REFDES \n")    
		fprintf( out_port "COMP_CLASS \n")    
		fprintf( out_port "COMP_PART_NUMBER \n")    
		fprintf( out_port "COMP_HEIGHT \n")    
		fprintf( out_port "COMP_DEVICE_LABEL \n")    
		fprintf( out_port "COMP_INSERTION_CODE \n")    
		fprintf( out_port "SYM_TYPE \n")    
		fprintf( out_port "SYM_NAME \n")    
		fprintf( out_port "SYM_MIRROR \n")    
		fprintf( out_port "SYM_ROTATE \n")    
		fprintf( out_port "SYM_X \n")    
		fprintf( out_port "SYM_Y \n")    
		fprintf( out_port "COMP_VALUE \n")    
		fprintf( out_port "COMP_TOL \n")    
		fprintf( out_port "COMP_VOLTAGE \n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!NET_NAME!REFDES!PIN_NUMBER!PIN_NAME!PIN_GROUND!PIN_POWER!\n")    
		fprintf( out_port "COMPONENT_PIN \n")    
		fprintf( out_port "\n")    
		fprintf( out_port "NET_NAME \n")    
		fprintf( out_port "REFDES \n")    
		fprintf( out_port "PIN_NUMBER \n")    
		fprintf( out_port "PIN_NAME \n")    
		fprintf( out_port "PIN_GROUND \n")    
		fprintf( out_port "PIN_POWER \n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!CLASS!SUBCLASS!\n")    
		fprintf( out_port "GEOMETRY \n")    
		fprintf( out_port "\n")    
		fprintf( out_port "CLASS!=\"VIA CLASS\" \n")    
		fprintf( out_port "CLASS!=\"PIN\" \n")    
		fprintf( out_port "CLASS!=\"PACKAGE GEOMETRY\" \n")    
		fprintf( out_port "CLASS!=\"ETCH\" \n")    
		fprintf( out_port "OR \n")    
		fprintf( out_port "CLASS=\"ETCH\" \n")    
		fprintf( out_port "CLASS \n")    
		fprintf( out_port "SUBCLASS \n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!PAD_NAME!REC_NUMBER!LAYER!FIXFLAG!VIAFLAG!PADSHAPE1!PADWIDTH!PADHGHT!PADXOFF!PADYOFF!\n")    
		fprintf( out_port "#PADFLASH!PADSHAPENAME!TRELSHAPE1!TRELWIDTH!TRELHGHT!TRELXOFF!TRELYOFF!TRELFLASH!TRELSHAPENAME!\n")    
		fprintf( out_port "#APADSHAPE1!APADWIDTH!APADHGHT!APADXOFF!APADYOFF!APADFLASH!APADSHAPENAME!\n")    
		fprintf( out_port "PAD_DEF \n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!GRAPHIC_DATA_NAME!GRAPHIC_DATA_NUMBER!RECORD_TAG!GRAPHIC_DATA_1!GRAPHIC_DATA_2!GRAPHIC_DATA_3!GRAPHIC_DATA_4\n")    
		fprintf( out_port "#!GRAPHIC_DATA_5!GRAPHIC_DATA_6!GRAPHIC_DATA_7!GRAPHIC_DATA_8!GRAPHIC_DATA_9!SUBCLASS!SYM_NAME!REFDES!\n")    
		fprintf( out_port "GEOMETRY \n")    
		fprintf( out_port "CLASS=\"PACKAGE GEOMETRY\" \n")    
		fprintf( out_port "\n")    
		fprintf( out_port "GRAPHIC_DATA_NAME \n")    
		fprintf( out_port "GRAPHIC_DATA_NUMBER \n")    
		fprintf( out_port "RECORD_TAG \n")    
		fprintf( out_port "GRAPHIC_DATA_1 \n")    
		fprintf( out_port "GRAPHIC_DATA_2 \n")    
		fprintf( out_port "GRAPHIC_DATA_3 \n")    
		fprintf( out_port "GRAPHIC_DATA_4 \n")    
		fprintf( out_port "GRAPHIC_DATA_5 \n")    
		fprintf( out_port "GRAPHIC_DATA_6 \n")    
		fprintf( out_port "GRAPHIC_DATA_7 \n")    
		fprintf( out_port "GRAPHIC_DATA_8 \n")    
		fprintf( out_port "GRAPHIC_DATA_9 \n")    
		fprintf( out_port "SUBCLASS \n")    
		fprintf( out_port "SYM_NAME \n")    
		fprintf( out_port "REFDES \n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!SYM_NAME!SYM_MIRROR!PIN_NAME!PIN_NUMBER!PIN_X!PIN_Y!PAD_STACK_NAME!REFDES!PIN_ROTATION!TEST_POINT!\n")    
		fprintf( out_port "COMPOSITE_PAD \n")    
		fprintf( out_port "CLASS!=\"VIA CLASS\" \n")    
		fprintf( out_port "\n")    
		fprintf( out_port "SYM_NAME \n")    
		fprintf( out_port "SYM_MIRROR\n")    
		fprintf( out_port "PIN_NAME \n")    
		fprintf( out_port "PIN_NUMBER \n")    
		fprintf( out_port "PIN_X \n")    
		fprintf( out_port "PIN_Y \n")    
		fprintf( out_port "PAD_STACK_NAME \n")    
		fprintf( out_port "REFDES \n")    
		fprintf( out_port "PIN_ROTATION\n")    
		fprintf( out_port "TEST_POINT \n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!VIA_X!VIA_Y!PAD_STACK_NAME!NET_NAME!TEST_POINT!VIA_MIRROR!\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "COMPOSITE_PAD \n")    
		fprintf( out_port "CLASS=\"VIA CLASS\" \n")    
		fprintf( out_port "\n")    
		fprintf( out_port "VIA_X \n")    
		fprintf( out_port "VIA_Y \n")    
		fprintf( out_port "PAD_STACK_NAME \n")    
		fprintf( out_port "NET_NAME \n")    
		fprintf( out_port "TEST_POINT \n")    
		fprintf( out_port "VIA_MIRROR\n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!CLASS!SUBCLASS!GRAPHIC_DATA_NAME!GRAPHIC_DATA_NUMBER!RECORD_TAG!GRAPHIC_DATA_1!\n")    
		fprintf( out_port "#GRAPHIC_DATA_2!GRAPHIC_DATA_3!GRAPHIC_DATA_4!GRAPHIC_DATA_5!GRAPHIC_DATA_6!GRAPHIC_DATA_7!\n")    
		fprintf( out_port "#GRAPHIC_DATA_8!GRAPHIC_DATA_9!NET_NAME!\n")    
		fprintf( out_port "GEOMETRY \n")    
		fprintf( out_port "CLASS!=\"VIA CLASS\" \n")    
		fprintf( out_port "CLASS!=\"PIN\" \n")    
		fprintf( out_port "CLASS!=\"PACKAGE GEOMETRY\" \n")    
		fprintf( out_port "CLASS!=\"ETCH\" \n")    
		fprintf( out_port "OR \n")    
		fprintf( out_port "CLASS=\"ETCH\" \n")    
		fprintf( out_port "\n")    
		fprintf( out_port "CLASS \n")    
		fprintf( out_port "SUBCLASS \n")    
		fprintf( out_port "GRAPHIC_DATA_NAME \n")    
		fprintf( out_port "GRAPHIC_DATA_NUMBER \n")    
		fprintf( out_port "RECORD_TAG \n")    
		fprintf( out_port "GRAPHIC_DATA_1 \n")    
		fprintf( out_port "GRAPHIC_DATA_2 \n")    
		fprintf( out_port "GRAPHIC_DATA_3 \n")    
		fprintf( out_port "GRAPHIC_DATA_4 \n")    
		fprintf( out_port "GRAPHIC_DATA_5 \n")    
		fprintf( out_port "GRAPHIC_DATA_6 \n")    
		fprintf( out_port "GRAPHIC_DATA_7 \n")    
		fprintf( out_port "GRAPHIC_DATA_8 \n")    
		fprintf( out_port "GRAPHIC_DATA_9 \n")    
		fprintf( out_port "NET_NAME \n")    
		fprintf( out_port "END\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "#A!SUBCLASS!PAD_SHAPE_NAME!GRAPHIC_DATA_NAME!GRAPHIC_DATA_NUMBER!RECORD_TAG!GRAPHIC_DATA_1!\n")    
		fprintf( out_port "#GRAPHIC_DATA_2!GRAPHIC_DATA_3!GRAPHIC_DATA_4!GRAPHIC_DATA_5!GRAPHIC_DATA_6!GRAPHIC_DATA_7!GRAPHIC_DATA_8!\n")    
		fprintf( out_port "#GRAPHIC_DATA_9!PAD_STACK_NAME!REFDES!PIN_NUMBER!\n")    
		fprintf( out_port "FULL_GEOMETRY\n")    
		fprintf( out_port "REFDES!=\"\"\n")    
		fprintf( out_port "PAD_STACK_NAME!=\"\"\n")    
		fprintf( out_port "GRAPHIC_DATA_NAME=\"LINE\"\n")    
		fprintf( out_port "\n")    
		fprintf( out_port "SUBCLASS\n")    
		fprintf( out_port "PAD_SHAPE_NAME\n")    
		fprintf( out_port "GRAPHIC_DATA_NAME\n")    
		fprintf( out_port "GRAPHIC_DATA_NUMBER\n")    
		fprintf( out_port "RECORD_TAG\n")    
		fprintf( out_port "GRAPHIC_DATA_1\n")    
		fprintf( out_port "GRAPHIC_DATA_2\n")    
		fprintf( out_port "GRAPHIC_DATA_3\n")    
		fprintf( out_port "GRAPHIC_DATA_4\n")    
		fprintf( out_port "GRAPHIC_DATA_5\n")    
		fprintf( out_port "GRAPHIC_DATA_6\n")    
		fprintf( out_port "GRAPHIC_DATA_7\n")    
		fprintf( out_port "GRAPHIC_DATA_8\n")    
		fprintf( out_port "GRAPHIC_DATA_9\n")    
		fprintf( out_port "PAD_STACK_NAME\n")    
		fprintf( out_port "REFDES\n")    
		fprintf( out_port "PIN_NUMBER\n")    
		
		close( out_port)
		
		return( t)
	)
)

procedure( create_cad_Derek03062019( cad_name)
	prog( (script_name cmd)
		unless( stringp( cad_name) println("ArgErr: create_cad_Derek03062019(0)") return( nil))
		;;
		
		script_name = "cds2fab.txt"
		create_script_file_Derek03062019( script_name)
		
		;;;
		sprintf( cmd "extracta \"%s.brd\" \"%s\" exa1.line exa2.line exa3.line exa4.line exa5.line exa6.line exa7.line exa8.line exa9.line" _work_name script_name)
		axlRunBatchDBProgram( "cad_extracta" cmd ?noUnload t ?noProgress nil)
		
		;;;
		sprintf( cmd "copy exa*.line %s" cad_name)
		shell( cmd)
		
		;;;;; this line is used to wait the system to merge the *.line to cad. don't delete it
		axlUIConfirm( "CAD .line files have been created.")
	)
)

procedure( create_artwork_param_Derek03062019()
	prog( (out_port)
		out_port = outfile( _art_addr "w")
		unless( outportp( out_port) println( "ERROR: create_artwork_param() - Fail to write file") return( nil))
		
		fprintf( out_port "DEVICE-TYPE           GERBER_RS274X\n")
		fprintf( out_port "OUTPUT-UNITS          INCHES\n")
		fprintf( out_port "FILM-SIZE             2400000 1600000\n")
		fprintf( out_port "FORMAT                5.5\n")
		fprintf( out_port "ABORT-ON-ERROR        NO\n")
		fprintf( out_port "SCALE                 1\n")
		fprintf( out_port "SUPPRESS-LEAD-ZEROES  YES\n")
		fprintf( out_port "SUPPRESS-TRAIL-ZEROES NO\n")
		fprintf( out_port "SUPPRESS-EQUAL        YES\n")
		fprintf( out_port "UNDEF-APT-CONT        NO\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( create_drill_parameter_Derek03062019()
	prog( (out_port)
		out_port = outfile( _nc_prm_addr "w")
		unless( outportp( out_port) println( "ERROR: create_drill_parameter() - Fail to write file") return( nil))
		;;
		
		;;
		fprintf( out_port "INTEGER-PLACES         5\n")
		fprintf( out_port "DECIMAL-PLACES         5\n")
		fprintf( out_port "X-OFFSET               0.000000\n")
		fprintf( out_port "Y-OFFSET               0.000000\n")
		fprintf( out_port "FEEDRATE               1\n")
		fprintf( out_port "COORDINATES            ABSOLUTE\n")
		fprintf( out_port "OUTPUT-UNITS           ENGLISH\n")
		fprintf( out_port "TOOL-ORDER             DECREASING\n")
		fprintf( out_port "REPEAT-CODES           NO\n")
		fprintf( out_port "SUPPRESS-LEAD-ZEROES   YES\n")
		fprintf( out_port "SUPPRESS-TRAIL-ZEROES  NO\n")
		fprintf( out_port "SUPPRESS-EQUAL         NO\n")
		fprintf( out_port "TOOL-SELECT            YES\n")
		fprintf( out_port "OPTIMIZE_DRILLING      NO\n")
		fprintf( out_port "ENHANCED_EXCELLON      YES\n")
		fprintf( out_port "HEADER                 none\n")
		fprintf( out_port "LEADER                 12\n")
		fprintf( out_port "CODE                   ASCII\n")
		fprintf( out_port "SEPARATE               YES\n")
		fprintf( out_port "SEPARATE-ROUTING       YES\n")
		fprintf( out_port "DRILLING               LAYER-PAIR\n")
		fprintf( out_port "BACKDRILL              YES\n")
		fprintf( out_port "CAVITY                 NO\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( create_ncroutebits_Derek03062019()
	prog( (out_port)
		out_port = outfile( _nc_rou_nm "w")
		unless( outportp( out_port) println( "ERROR: create_ncroutebits() - Fail to write file") return( nil))
		;;
		
		fprintf( out_port "0.01			T01\n")
		fprintf( out_port "0.02			T02\n")
		fprintf( out_port "0.03			T03\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( create_gbr_Derek03062019( ipc_name)
	prog( ( cmd films)
		unless( stringp( ipc_name) println( "ArgErr: create_gbr() - ipc_name is not a string") return( nil))
		;;
		
		;;;;; create artwork
		create_artwork_param_Derek03062019()
		films = strcat( "-f " buildString( _gbr_film_ls " -f "))
		sprintf( cmd "artwork %s \"%s.brd\"" films _work_name)
		axlRunBatchDBProgram( "gbr_artwork" cmd ?noUnload t ?noProgress nil ?noLogview t)
		
		;;;;; create ipc356
		sprintf( cmd "ipc356_out -A \"%s\" \"%s\"" _work_addr ipc_name)
		axlRunBatchDBProgram( "flex_ipc356_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
		axlOSFileMove( ipc_name strcat( _art_dir "/" ipc_name))
		
		;;;;; create nc drill parameter ;;; create drill
		create_drill_parameter_Derek03062019()
		sprintf( cmd "nctape -b \"%s.brd\"" _work_name)
		axlRunBatchDBProgram( "drill_nctape" cmd ?noUnload t ?noProgress nil)
		
		;;;;; create ncroute
		when( _exists_ncroute
			create_ncroutebits_Derek03062019()
			sprintf( cmd "ncroute \"%s.brd\"" _work_name)
			axlRunBatchDBProgram( "non_circle_drill_ncroute" cmd ?noUnload t ?noProgress nil)
			axlOSFileMove( _nc_rou_nm strcat( _art_dir "/" _nc_rou_nm))
		)
		
		return( t)
	)
)

procedure( film_bigger_Derek03062019( af bf)
	prog( ( argerr a_num b_num result)
		argerr = "ArgErr: film_bigger() -"
		unless( index( af "-") printf( "%s No '-' has been found in af[%s]. ex: 01-SILK-TOP\n" argerr af) return( nil))
		unless( index( bf "-") printf( "%s No '-' has been found in bf[%s]. ex: 01-SILK-TOP\n" argerr bf) return( nil))
		;;
		
		a_num = atoi( car( parseString( af "-")))
		b_num = atoi( car( parseString( bf "-")))
		
		unless( and( integerp( a_num) integerp( b_num))
			printf( "ERROR: film_bigger() - Fail to extrat serial number from film: %L %L\n" a_num b_num)
			return( nil)
		)
		
		;;
		result = (a_num < b_num)
		
		return( result)
	)
)

procedure( get_layer_attribute_Derek03062019( ly_nm)
	;;; get the attribute from film(artwork) and xsection to check and return either positive/negative
	prog( (etch_ly art_inf art_mirr xsect artwork_neg result)
		unless( stringp( ly_nm) println( "ArgErr: get_layer_attribute() - ly_nm is not a string") return( nil))
		unless( member( ly_nm _film_ls) printf( "ArgErr: get_layer_attribute() - ly_nm[%s] is not in _file_ls\n" ly_nm) return( "N/A"))
		;;
		
		;;; get mirror value ;; t means negative, nil means positive
		art_inf = axlGetParam( strcat( "artwork:" ly_nm))
		art_mirr = art_inf->mirrored
		
		;;; get value in xsection
		etch_ly = setof( ly art_inf->groupMembers index( ly "ETCH/"))
		unless( onep( length( etch_ly))
			printf( "get_layer_attribute() - More than one or none etch(%L) in %s\n" etch_ly ly_nm)
			return( "")
		)
		
		etch_ly = cadr( parseString( car( etch_ly) "/"))
		xsect = setof( x axlGetXSection() equal( etch_ly car( x)))
		unless( onep( length( xsect)) printf( "get_layer_attribute() - No %s layer in xsection\n" etch_ly) return( ""))
		artwork_neg = (nth 7 xsect)
		
		;;; output result
		unless( (eq art_mirr artwork_neg) printf( "The attribute in artwork(%s) and xsection(%s) are different\n" ly_nm etch_ly) return( ""))
		result = if( artwork_neg "NEGATIVE" "POSITIVE")
		
		return( result)
	)
)

procedure( get_gbr_index_des_Derek03062019( ly_nm @optional tag start_ly to_ly)
	;;; get the description[,attribute] of the 00-idnex of the GBR package
	prog( (np result)
		unless( stringp( ly_nm) println( "ArgErr: get_gbr_index_des(0)") return( "N/A,N/A"))
		;;
		
		cond(
			( eq( 'art tag)
				cond(
					( index( ly_nm "-DRILL") sprintf( result "DRILL MAP AND LOCATION,N/A"))
					( index( ly_nm "-BD-") sprintf( result "BACK DRILL MAP AND LOCATION,N/A"))
					( index( ly_nm "-PANEL") (result = "PANEL DRAWING AND PCB FAB. NOTE,POSITIVE"))
					( index( ly_nm "-SILK-TOP") (result = "COMPONENT SIDE SILKSCREEN,POSITIVE"))
					( index( ly_nm "-PASTE-TOP") (result = "COMPONENT SIDE PASTE MASK,POSITIVE"))
					( index( ly_nm "-MASK-TOP") (result = "COMPONENT SIDE SOLDER MASK,POSITIVE"))
					( index( ly_nm "-SILK-BOT") (result = "SOLDER SIDE SILKSCREEN,POSITIVE"))
					( index( ly_nm "-PASTE-BOT") (result = "SOLDER SIDE PASTE MASK,POSITIVE"))
					( index( ly_nm "-MASK-BOT") (result = "SOLDER SIDE SOLDER MASK,POSITIVE"))
					(t
						;;; get the layer number from L?. ex: 01-L3_GND1
						rexCompile( "-L\\([0-9]+\\)_[0-9A-Z]+$")
						start_ly = if( (rexExecute ly_nm) (atoi (rexSubstitute "\\1")) 0)
						when( zerop( start_ly) printf( "create_gbr_index() - Fail to get layer from film:%s\n" ly_nm))
						
						;;; check this film is in positive/negative
						np = get_layer_attribute_Derek03062019( ly_nm)
						
						;;
						cond(
							( index( ly_nm "TOP") sprintf( result "LAYER %d / SIGNAL LAYER,%s" start_ly np))
							( index( ly_nm "BOTTOM") sprintf( result "LAYER %d/SIGNAL LAYER,%s" start_ly np))
							( index( ly_nm "INT") sprintf( result "LAYER %d / SIGNAL LAYER,%s" start_ly np))
							( index( ly_nm "GND") sprintf( result "LAYER %d / GROUND PLANE,%s" start_ly np))
							( index( ly_nm "VCC") sprintf( result "LAYER %d / POWER PLANE,%s" start_ly np))
							(t
								printf( "get_gbr_index_des() - No description for %s\n" ly_nm)
								(result = "N/A,N/A")
							)
						)
					)
				)
			)
			( index( ly_nm ".drl")
				caseq( tag
					('pth (result = "PLATED NC DRILL FROM TOP TO BOTTOM"))
					('npth (result = "NON-PLATED NC DRILL FROM TOP TO BOTTOM"))
					('bd (result = "BACK DRILL,N/A"))
					('laser sprintf( result "LASER VIA FROM %d TO %d,N/A" start_ly to_ly))
					('other sprintf( result "BURIED VIA FROM %d TO %d,N/A" start_ly to_ly))
					(t
						printf( "get_gbr_index_des() - No drl description for %s\n" ly_nm)
						(result = "N/A,N/A")
					)
				)
			)
			( index( ly_nm ".ipc") (result = "IPC FORMAT NET-LIST,N/A"))
			( index( ly_nm ".rou") (result = "NC ROUTE FOR SLOT DRILL,N/A"))
			( index( ly_nm ".txt")
				caseq( tag
					('nc_b (result = "N/A,N/A")) ;; ncroutebits.txt
					('nc_p (result = "NC DRILL FORMAT,N/A")) ;; nc_param.txt
					('nc_t (result = "N/A,N/A")) ;; nc_tools_auto.txt
					('art_p (result = "GERBER FORMAT,N/A")) ;; art_param.txt
					(t
						printf( "get_gbr_index_des() - No txt description for %s\n" ly_nm)
						(result = "N/A,N/A")
					)
				)
			)
			(t
				printf( "get_gbr_index_des() - No description for %s\n" ly_nm)
				result = "N/A,N/A"
			)
		)
		
		return( result)
	)
)

procedure( get_etch_ly_num_Derek03062019( layer)
	prog( (etch th)
		unless( stringp( layer) println( "ArgErr: get_etch_ly_num() - layer is not a string") return( nil))
		unless( axlIsLayer( layer) println( "ArgErr: get_etch_ly_num() - layer is not a layer") return( nil))
		;;
		etch = cadr( parseString( layer "/"))
		th = listnindex( _etch_ls etch)
		
		if( numberp( th)
			th = add1( th)
			printf( "ERROR: get_etch_ly_num() - Fail to find %s in etch_ls\n" layer)
		)
		
		return( th)
	)
)

procedure( create_gbr_index_Derek03062019( ipc_nm)
	prog( ( out_port file_ls out_form drl_nm out_content_ls line via_ls via_nm 
			start_end_ly start_ly to_ly non_standard drl_type type description)
		unless( stringp( ipc_name) println( "ArgErr: create_gbr_index(0)") return( nil))
		;;
		
		;;; %d: item number; %s: film name; %s: description[,attribute]
		;;; the third part is used to replace the portion of the fabrication worksheet
		out_form = "%s,%s\n"
		
		;;
		out_content_ls = append1( out_content_ls "LAYER,DESCRIPTION,ATTRIBUTE\n")
		
		;;;; get film files if anyway
		foreach( fl _gbr_film_ls
			description = get_gbr_index_des_Derek03062019( fl 'art)
			sprintf( line out_form strcat( fl ".art") description)
			out_content_ls = append1( out_content_ls line)
		)
		
		;;;; ipc
		description = get_gbr_index_des_Derek03062019( ipc_nm)
		sprintf( line out_form ipc_nm description)
		out_content_ls = append1( out_content_ls line)
				
		;;;; nc_route file
		when( _exists_ncroute
			;; first value: number of plated drill
			;; second value: number of unplated drill
			unless( zerop( cadr( _exists_ncroute))
				sprintf( drl_nm "%s.rou" _work_name)
				description = get_gbr_index_des_Derek03062019( drl_nm)
				sprintf( line out_form drl_nm description)
				out_content_ls = append1( out_content_ls line)
			)
			
			unless( zerop( car( _exists_ncroute))
				sprintf( drl_nm "%s_plated.rou" _work_name)
				description = get_gbr_index_des_Derek03062019( drl_nm)
				sprintf( line out_form drl_nm description)
				out_content_ls = append1( out_content_ls line)
			)
		)
		
		;;;; for non plated through hole
		when( cadr( _exists_thru_p_np)
			sprintf( drl_nm "%s-1-%d-np.drl" _work_name _etch_total)
			description = get_gbr_index_des_Derek03062019( drl_nm 'npth)
			sprintf( line out_form drl_nm description)
			out_content_ls = append1( out_content_ls line)
		)
		
		;;;; for plated through hole
		when( car( _exists_thru_p_np)
			sprintf( drl_nm "%s-1-%d.drl" _work_name _etch_total)
			description = get_gbr_index_des_Derek03062019( drl_nm 'pth)
			sprintf( line out_form drl_nm description)
			out_content_ls = append1( out_content_ls line)
		)
		
		;;;; non-standard via
		via_ls = setof( v axlGetAllViaList() stringp( v->drillNonStandard))
		foreach( via_id via_ls
			via_nm = via_id->name
			start_end_ly = via_id->startEnd
			start_ly = get_etch_ly_num_Derek03062019( car( start_end_ly))
			to_ly = get_etch_ly_num_Derek03062019( cadr( start_end_ly))
			non_standard = via_id->drillNonStandard
			
			;;
			case( non_standard
				("LASER_DRILL"
					drl_type = "laser"
					type = 'laser
				)
				("OTHER_DRILL"
					drl_type = "other"
					type = 'other
				)
				(t
					printf( "ERROR: create_gbr_index() - Not define via drill-nonstandard [%s] at [%s]\n" non_standard via_nm)
					drl_type = type = nil
				)
			)
			
			;;
			when( and( stringp( drl_type) symbolp( type))
				sprintf( drl_nm "%s-%d-%d-%s.drl" _work_name start_ly to_ly drl_type)
				description = get_gbr_index_des_Derek03062019( drl_nm type start_ly to_ly)
				sprintf( line out_form drl_nm description)
				out_content_ls = append1( out_content_ls line)
			)
		)
		
		;;;; backdrill if any
		when( _exists_backdrill
			foreach( start_end_ly _exists_backdrill
				start_ly = car( start_end_ly)
				end_ly = cadr( start_end_ly)
				;;
				sprintf( drl_nm "%s-bd-%s-%s.drl" _work_name start_ly end_ly)
				description = get_gbr_index_des_Derek03062019( drl_nm 'bd)
				sprintf( line out_form drl_nm description)
				out_content_ls = append1( out_content_ls line)
			)
		)
		
				
		;;;; art param.txt
		description = get_gbr_index_des_Derek03062019( _art_prm_nm 'art_p)
		sprintf( line out_form _art_prm_nm description)
		out_content_ls = append1( out_content_ls line)
		
		;;; nc_param.txt
		description = get_gbr_index_des_Derek03062019( _nc_prm_nm 'nc_p)
		sprintf( line out_form _nc_prm_nm description)
		out_content_ls = append1( out_content_ls line)
		
		;;; nc_tools_auto
		drl_nm = "nc_tools_auto.txt"
		description = get_gbr_index_des_Derek03062019( drl_nm 'nc_t)
		sprintf( line out_form drl_nm description)
		out_content_ls = append1( out_content_ls line)
		
		;; ncroutebits.txt
		when( _exists_ncroute
			description = get_gbr_index_des_Derek03062019( _nc_rou_nm 'nc_b)
			sprintf( line out_form _nc_rou_nm description)
			out_content_ls = append1( out_content_ls line)
		)
		
		;;;;;
		out_port = outfile( _gbr_index_addr "w")
		unless( outportp( out_port) println( "create_gbr_index() - Fail to write") return( nil))
		foreach( line out_content_ls fprintf( out_port line))
		close( out_port)
		
		return( t)
	)
)

procedure( create_panel_Derek03062019( file_names)
	prog( ( cmd)
		unless( stringp( file_names) println( "ArgErr: create_panel() - file_names is not a string") return( nil))
		
		;; -o: output file name
		;; -f art film name
		;; -r: Export board/symbol outlines, refdes as well if pins exported
		;; -B: Create PDF file in black and white. Default to use the design colors.
		;; -x: Vector text and invisible text string for search. 
		;; -n: Meta Data Options:Net Data Tree
		;; -m: Meta Data Options:Component Data Tree
		;; -T: Meta Data Options:TestPoint Tree and testPoint outline
		
		sprintf( cmd "pdf_out \"%s.brd\" -o \"%s\" -f \"%s\" -B -x -n -m -T" _work_name file_names _panel_film_nm)
		axlRunBatchDBProgram( "panel_pdf_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
	
		return( t)
	)
)

;procedure( create_gbr_pdf_Derek03062019( file_names)
;	prog( (cmd_film cmd )
;		unless( stringp( file_names) println( "ArgErr: create_gbr_pdf() - file_names is not a string") return( nil))
;		; a->groupMembers = '("DRAWING FORMAT/GND1" "BOARD GEOMETRY/OUTLINE" "BOARD GEOMETRY/LOGO" "ETCH/L2_GND1" "PIN/L2_GND1" "VIA CLASS/L2_GND1")
;		cmd_film = strcat( "-f " (buildString _film_ls " -f "))
;		
;		;;; if no select film, then print line all
;		sprintf( cmd "pdf_out \"%s.brd\" -o \"%s\" -B -x -n -m -T" _work_name file_names)
;		;; sprintf( cmd "pdf_out \"%s.brd\" -o %s %s -B -x -n -m -T" _work_name file_names cmd_film)
;		axlRunBatchDBProgram( "gbr_pdf_pdf_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
;		
;		return( t)
;	)
;)

procedure( create_pcba_Derek03062019( file_names)
	prog( (p_top p_bot cmd)
		unless( stringp( file_names) println( "ArgErr: create_pcba() - file_names is not a string") return( nil))
		;;
		
		sprintf( cmd "pdf_out %s.brd -o \"%s\" -f \"%s\" -f \"%s\" -B -x -n -m -T" _work_name file_names _pcba_top_film_nm _pcba_bot_film_nm)
		axlRunBatchDBProgram( "pcba_pdf_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
		
		return( t)
	)
)

procedure( create_gerber_items_Derek03062019()
	let( (old_file_ls achieve_name file_names out_name cad_name ipc_name from_addr to_addr cmd new_file_ls added_file_ls)
		;;;;; get current files
		old_file_ls = getDirFiles( getWorkingDir())
		
		;	3.<brd name>_date(brd).7z
		when( _package_table['brd_create]
			sprintf( achieve_name _gerber_file_term "(brd)")
			file_names = strcat( _work_name ".brd")
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		;	4.<brd name>_date(dxf).7z
		when( _package_table['dxf_create]
			sprintf( achieve_name _gerber_file_term "(dxf)")
			file_names = list( "TOP.dxf" "BOT.dxf" "TOP_with_trace.dxf" "BOT_with_trace.dxf"
							"TOP.cnv" "BOT.cnv" "TOP_with_trace.cnv" "BOT_with_trace.cnv")
			create_top_bot_dxf_Derek03062019()
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		;	5.<brd name>_date(emn_emp).7z
		when( _package_table['emn_create]
			sprintf( achieve_name _gerber_file_term "(emn_emp)")
			sprintf( out_name _gerber_file_term "")
			file_names = list( strcat( out_name ".emn") strcat( out_name ".emp"))
			create_emn_emp_Derek03062019( out_name)
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		;	6.<brd name>_date(odb++).7z
		when( _package_table['odb_create]
			sprintf( achieve_name _gerber_file_term "(odb++)")
			file_names = "odbjob.tgz"
			create_odb_Derek03062019( _odb_addr)
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		;	7.<brd name>_date(cad).7z
		when( _package_table['cad_create]
			sprintf( cad_name _gerber_file_term ".cad")
			sprintf( achieve_name _gerber_file_term "(cad)")
			file_names = cad_name
			create_cad_Derek03062019( cad_name)
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		
		;	8.<brd name>_date(gbr).7z
		when( _package_table['gbr_create]
			sprintf( ipc_name _gerber_file_term ".ipc")
			sprintf( achieve_name _gerber_file_term "(gbr)")
			;;;;; all artwork, ipc356, open short in gerber tool
			create_gbr_Derek03062019( ipc_name)
			create_gbr_index_Derek03062019( ipc_name)
			
			;;;; waiting for system saves the artwork to directory
			axlUIConfirm( "Confirm to transfer files to GBR")
			
			;;;; get all the current file in artwork directory
			;; use caddr to skip . and ..
			file_names = cddr( getDirFiles( _art_dir))
			
			;;;;; artwork.txt and .ipc
			foreach( file file_names
				from_addr = strcat( _art_dir "/" file)
				to_addr = strcat( _work_path "/" file)
				axlOSFileCopy( from_addr to_addr nil)
			)
			
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		;	10.<brd name>_date(panel).7z
		when( _package_table['panel_create]
			sprintf( achieve_name _gerber_file_term "(panel)")
			sprintf( file_names _gerber_file_term "(panel).pdf")
			create_panel_Derek03062019( file_names)
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		;	11.<brd name>_date(pcba).7z
		when( _package_table['pcba_create]
			sprintf( achieve_name _gerber_file_term "(pcba)")
			sprintf( file_names _gerber_file_term "(pcba).pdf")
			create_pcba_Derek03062019( file_names)
			archieve_7z_Derek03062019( file_names achieve_name)
		)
		
		;;;;; removed function, this package should be retrieved from gerber tool instead of board file. there are some distinctive colored-markup.
		;	12.<brd name>_date(gbr_pdf).7z
	;	when( axlOKToProceed()
	;		(achieve_name = sprintf( nil _gerber_file_term "(gbr_pdf)"))
	;		(file_names = sprintf( nil _gerber_file_term "(gbr_pdf).pdf"))
	;		create_gbr_pdf_Derek03062019(file_names)
	;		archieve_7z_Derek03062019( file_names achieve_name)
	;	)
		
		;	13.<brd name>_component.txt
		when( _package_table['comp_create]
			sprintf( out_name strcat( _gerber_file_term "_component.txt") "")
			sprintf( cmd "report -v cmp \"%s\" \"%s\"" _work_addr out_name)
		;	(cmd = strcat( "report -v cmp \"%s\" " out_name))
			axlRunBatchDBProgram( "component_report" cmd ?startMsg "Export Component Report" ?silent t ?noLogview t)
			axlOSFileMove( out_name strcat( _gerber_dir "\\" out_name))
		)
		
		;;;;; get all files
		new_file_ls = getDirFiles( getWorkingDir())
		added_file_ls = setof( x new_file_ls not( member( x old_file_ls)))
		delete_extra_file_Derek03062019( added_file_ls)
	)
)

procedure( gerber_tool_main_Derek03062019()
	prog( ( is_lack_data ori_display out_form answer cmd)
		err = "ERROR: gerber_tool_main() -"
		;;
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		
		unless( isDir( "C:\\MentorGraphics\\ODB++_Inside_Cadence_Allegro") println( "ERROR: Please install ODB++ before using this function") return( nil))
		unless( getShellEnvVar( "ALLEGRO_BRD2ODB") setShellEnvVar( "ALLEGRO_BRD2ODB=C:\\MentorGraphics\\ODB++_Inside_Cadence_Allegro"))
		
		answer = axlUIYesNo( "The change in this process may be saved. Would you like to keep continue?" "Starting Confirm" 'yes)
		unless( answer return( nil))
		
		
		answer = axlUIYesNo( "The film name without serial number(ex: [01]-SILK-TOP) will be skipped. Would you like to keep continue?" "Film Name Confirm" 'yes)
		unless( answer return( nil))
		
		;;;;; startthe program
		init_Derek03062019()
		is_lack_data = nil
		unless( stringp( _gerber_file_term) printf( "%s Fail to get gerber file term\n" err) (is_lack_data = t))
		unless( isDir( axlGetVariable( "ads_sdlog")) printf( "%s Fail to create log directory\n" err) (is_lack_data = t))
		unless( isDir( axlGetVariable( "ads_sdart")) printf( "%s Fail to create artwork directory\n" err) (is_lack_data = t))
		unless( dtpr( _film_ls) printf( "%s Fail to get artwork content. Artwork has to have at least one film\n" err) (is_lack_data = t))
		unless( dtpr( _etch_ls) printf( "%s Fail to get etch layer\n" err) (is_lack_data = t))
		unless( isFile( _odb_addr) printf( "%s No odb++ has been found on path (%s). Please install odb++ before using this tool\n" err _odb_addr) (is_lack_data = t))
		unless( isFile( _valor_addr) printf( "%s No valor has been found on path (%s). Please install valor before using this tool\n" err _valor_addr) (is_lack_data = t))
		unless( stringp( _panel_film_nm) printf( "%s No PANEL film has been found in artwork\n" err) (is_lack_data = t))
		unless( stringp( _pcba_top_film_nm) printf( "%s No PCBA_TOP film has been found in artwork\n" err) (is_lack_data = t))
		unless( stringp( _pcba_bot_film_nm) printf( "%s No PCBA_BOT film has been found in artwork\n" err) (is_lack_data = t))
		unless( stringp( _pcb_fab_film_nm) printf( "%s No PCB_FAB film has been found in artwork\n" err) (is_lack_data = t))
		unless( dtpr( _gbr_film_ls) printf( "%s Fail to get film list for gbr package\n" err) (is_lack_data = t))
		when( is_lack_data return( nil))
		
		;;;;; create a new getber package directory anyway
		if( isDir( _gerber_dir)
			delete_extra_file_Derek03062019( getDirFiles( _gerber_dir) _gerber_dir)
			createDir( _gerber_dir)
		)
		unless( isDir( _gerber_dir) printf( "%s Gerber directory can't be created. Process halt\n" err) return(nil))
		
		;;;;; test whether the 7z command is exists
		unless( sh( "\"C:\\Program Files\\7-Zip\\7z\"")
			println( "Please install 7z or it isn't installed in the default path. Process halt")
			return( nil)
		)
		
		;;;;; store display setting
		ori_display = axlVisibleGet()
		
		;;;;; form to select package
		unless( build_form_Derek03062019() printf( "%s Fail to create form content file\n" err) return( nil))
		out_form = axlFormCreate( gensym() _gb_form_nm '("east" "outer") 'out_form_action_Derek03062019 nil)
		set_form_Derek03062019( out_form)
		axlFormDisplay( out_form)
		
		;;;;; restore display setting
		axlVisibleSet( ori_display)
		axlVisibleUpdate( t)
		
		;;;;; report done
		when( _to_run
			printf( "Successfully create the file [%s]. Please check this line\n" _gerber_dir)
			sprintf( cmd "start \"\" \"%s\"" _gerber_back_addr)
			sh( cmd)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "gerber_tool_since_jun_2019" 'gerber_tool_main_Derek03062019)
; gerber_tool_main_Derek03062019()
; skill (encrypt "C:/skill/gerber_tool_since_jun_2019_v1.il" "C:/skill/gerber_tool_since_jun_2019_v1.ile")
; (load "gerber_tool_since_jun_2019_v1.ile")
; (load "gerber_tool_since_jun_2019_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup