;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 06092020 - _Derek06092020
;Introduction: check the total amount of laser/through/backdrill is match to the real number on the board
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek06092020()
	;;;;; general
	setq( _class_manufacturing "MANUFACTURING")
	setq( _class_drawing_format "DRAWING FORMAT")
	setq( _class_pin "PIN")
	setq( _class_via "VIA CLASS")
	
	setq( _type_drill_chart "DB_DRILL_LEGEND")
	setq( _group_drill_legend_db "DRILL_LEGEND_BD")
	setq( _drill_legend_db_format "DRILL_LEGEND_BD_\\([0-9]+\\)_\\([0-9]+\\)")
	setq( _group_drill_legend "DRILL_LEGEND")
	setq( _drill_legend_format "DRILL_LEGEND_\\([0-9]+\\)_\\([0-9]+\\)")
	
	setq( _etch_subclass_ls axlGetParam("paramLayerGroup:ETCH")->groupMembers)
	
	;;;;; log directory
	unless( stringp( axlGetVariable( "ads_sdlog")) axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _check_drill_chart_logname "%s/check_drill_chart-%d%s%.2d-%.2d%.2d%.2d.log" _log_dir _year _month _date _hour _minute _second)
	
	;;;;;
	setq( _schematic_name get_schematic_name_Derek06092020())
)

procedure( get_schematic_name_Derek06092020()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls and( (length( s->pins) > 2) !zerop( strlen( car( s->pins)->net->name || "")))))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_chart_drill_total_Derek06092020( group_name group_layer text_ls)
	prog( ( a_text b_text c_text total)
		text_ls = sort( text_ls lambda( (a b) (cadr( a->xy) < cadr( b->xy))))
		
		a_text = car( text_ls)
		b_text = cadr( text_ls)
		c_text = caddr( text_ls)
		if( and( axlGeoEqual( cadr( a_text->xy) cadr( b_text->xy)) !axlGeoEqual( cadr( a_text->xy) cadr( c_text->xy))) then
			total = (atoi( a_text->text) || atoi( b_text->text))
			unless( numberp( total)
				printf( "ERROR: get_chart_drill_total() - Fail to get 'TOTAL HOLES' value next to it from [%s] on [%s]\n" group_name group_layer)
			)
		else
			printf( "ERROR: get_chart_drill_total() - Fail to get 'TOTAL HOLES' value from [%s] on [%s]\n" group_name group_layer)
		)
		
		return( total)
	)
)

procedure( get_chart_backdrill_total_Derek06092020( group_name group_layer text_ls)
	; a = "TOTAL BACKDRILLS: 120"; rexExecute( a) ; rexExecute( a)
	prog( ( total)
		rexCompile( "TOTAL BACKDRILLS: \\([0-9]+\\)")
		total = car( mapcan( lambda( (x) when( rexExecute( x->text) list( rexSubstitute( "\\1")))) text_ls))
		total = atoi( total)
		
		unless( numberp( total) printf( "ERROR: get_chart_backdrill_total() - Fail to get total from 'TOAL BACKDRILL: ?' from [%s] on [%s]\n" group_name group_layer))
		
		return( total)
	)
)

procedure( get_chart_all_total_Derek06092020( drill_chart_group_id)
	; drill_chart_group_id = car( drill_chart_group_ls)
	prog( ( group_name group_layer text_ls total)
		group_name = drill_chart_group_id->name
		group_layer = get_group_layer_Derek06092020( drill_chart_group_id)
		
		text_ls = setof( x drill_chart_group_id->groupMembers equal( "text" x->objType))
		
		cond(
			( index( group_name _group_drill_legend_db)
				total = get_chart_backdrill_total_Derek06092020( group_name group_layer text_ls)
			)
			( index( group_name _group_drill_legend)
				total = get_chart_drill_total_Derek06092020( group_name group_layer text_ls)
			)
			( t
				printf( "ERROR: get_chart_all_total() - Yet to define drill legend of group[%s]\n" group_name)
			)
		)
		
		;;;;; 
		unless( numberp( total) (total = 0))
		
		
		return( total)
	)
)

procedure( get_group_layer_Derek06092020( group_id)
	; group_id = car( axlGetSelSet())
	prog( ( layer_ls layer group_name )
		layer_ls = group_id->groupMembers~>layer
		layer = car( layer_ls)
		
		if( forall( x layer_ls equal( layer x)) then
			return( layer)
		else
			group_name = group_id->name
			layer_ls = maplist( lambda( (x) unless( member( car( x) cdr( x)) car( x))) layer_ls)
			layer_ls = remq( nil layer_ls)
			printf( "ERROR: get_group_layer() - Multiple layer has been found in group[%s]\n\t%L\n" group_name layer_ls)
			
			return( nil)
		)
	)
)

procedure( visible_layer_Derek06092020( layer_names)
	prog( ()
		unless( dtpr( layer_names) (layer_names = list( layer_names)))
		unless( forall( x layer_names stringp( x)) println( "ERROR: visible_layer() - layer_name is not a string") return( nil))
		unless( forall( x layer_names axlIsLayer( x)) println( "ERROR: visible_layer() - layer_name is not a layer") return( nil))
		
		axlVisibleDesign( nil)
		foreach( layer_name layer_names axlVisibleLayer( layer_name t))
		axlVisibleUpdate( t)
		
		
		return( t)
	)
)

procedure( get_all_objs_on_visible_Derek06092020( key_ls)
	prog( ( button_ls obj_ls)
		unless( dtpr( key_ls) println( "ERROR: get_all_objs_on_visible() - key_ls is nil") return( nil))
		;;
		
		button_ls = append( list( "NOALL") key_ls)
		axlSetFindFilter( ?enabled button_ls ?onButtons button_ls)
		axlAddSelectAll()
		
		obj_ls = axlGetSelSet()
		
		axlClearSelSet()
		axlSetFindFilter( ?enabled list( "NOALL") ?onButtons list( "NOALL"))
		
		
		return( obj_ls)
	)
)

procedure( get_board_backdrill_total_Derek06092020( group_name)
	; figure_id = car( axlGetSelSet())
	; a = car( axlGetSelSet())
	prog( ( from_layer to_layer from_subclass to_subclass pin_layer via_layer dip_ls total)
		rexCompile( _drill_legend_db_format)
		unless( rexExecute( group_name) printf( "ERROR: get_board_backdrill_total() - fail to map group[%s] by [%s]\n" group_name _drill_legend_db_format) return( nil))
		;;
		
		;;;;;
		from_layer = atoi( rexSubstitute( "\\1"))
		to_layer = atoi( rexSubstitute( "\\2"))
		
		;;;;;
		from_subclass = nth( sub1( from_layer) _etch_subclass_ls)
		to_subclass = nth( sub1( to_layer) _etch_subclass_ls)
		
		;;;;;
		sprintf( pin_layer "%s/%s" _class_pin from_subclass)
		sprintf( via_layer "%s/%s" _class_via from_subclass)
		visible_layer_Derek06092020( list( pin_layer via_layer))
		dip_ls = get_all_objs_on_visible_Derek06092020( list( "PINS" "VIAS"))
		
		;;;;;
		from_subclass = stringToSymbol( lowerCase( from_subclass))
		dip_ls = setof( x dip_ls eqv( axlBackDrill( x from_subclass)->toLayer to_layer))
		total = length( dip_ls)
		
		
		return( total)
	)
)

procedure( get_board_drill_total_Derek06092020( group_layer)
	prog( ( dip_ls total)
		visible_layer_Derek06092020( group_layer)
		dip_ls = get_all_objs_on_visible_Derek06092020( list( "PINS" "VIAS"))
		
		total = length( dip_ls)
		
		return( total)
	)
)

procedure( get_board_all_total_Derek06092020( drill_chart_group_id)
	prog( ( group_name group_layer total)
		group_name = drill_chart_group_id->name
		group_layer = get_group_layer_Derek06092020( drill_chart_group_id)
		
		cond(
			( index( group_name _group_drill_legend_db)
				total = get_board_backdrill_total_Derek06092020( group_name)
			)
			( index( group_name _group_drill_legend)
				total = get_board_drill_total_Derek06092020( group_layer)
			)
			( t
				printf( "ERROR: get_board_all_total() - Yet to define drill legend of group[%s] on layer[%s]\n" group_name group_layer)
			)
		)
		
		;;;;; 
		unless( numberp( total) (total = 0))
		
		
		return( total)
	)
)

procedure( compare_drill_data_Derek06092020( a_m_sb_chrt_brd b_m_sb_chrt_brd)
	prog( ( a b)
		a = car( a_m_sb_chrt_brd)
		b = car( b_m_sb_chrt_brd)
		if( equal( a b) then
			a = cadr( a_m_sb_chrt_brd)
			b = cadr( b_m_sb_chrt_brd)
			
			;;;;; move backdrill group to the back
			return( alphalessp( b a))
		else
			;;;;; fail and then pass
			return( alphalessp( a b))
		)
	)
)

procedure( get_drill_data_Derek06092020( dcg_chart_total_ls dgc_board_total_ls)
	prog( ( drill_chart_group_id group_name group_layer group_subclass chart_total board_total match m_sb_chrt_brd m_sb_chrt_brd_ls)
		;;;;; 
		foreach( ( gpid_chrt gpid_brd) dcg_chart_total_ls dgc_board_total_ls
			drill_chart_group_id = car( gpid_chrt)
			group_name = drill_chart_group_id->name
			group_layer = get_group_layer_Derek06092020( drill_chart_group_id)
			group_subclass = cadr( parseString( group_layer "/"))
			
			chart_total = cadr( gpid_chrt)
			board_total = cadr( gpid_brd)
			match = if( eqv( chart_total board_total) "PASS" "FAIL")
			
			;;;;;
			m_sb_chrt_brd = list( match group_subclass chart_total board_total)
			m_sb_chrt_brd_ls = append1( m_sb_chrt_brd_ls m_sb_chrt_brd)
		)
		
		;;;;; sort
		m_sb_chrt_brd_ls = sort( m_sb_chrt_brd_ls 'compare_drill_data_Derek06092020)
		
		
		return( m_sb_chrt_brd_ls)
	)
)

procedure( write_log_Derek06092020( m_sb_chrt_brd_ls)
	prog( ( out_port format match subclass chart_total board_total)
		out_port = outfile( _check_drill_chart_logname "w")
		unless( outportp( out_port) println( "ERROR: Fail to write log file") return( nil))
		;;
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction:\n")
		fprintf( out_port "\t1. This program is used to compare the total number of drill between chart and board\n")
		fprintf( out_port "\t2. Please create and place the chart to the correct layer before using this function\n")
		fprintf( out_port "\t3. Comparing items includes through/laser/backdrill\n")
		
		fprintf( out_port "\n\n")
		
		format = "%-6s,%-25s,%-13s,%-5s\n"
		fprintf( out_port format "Match" "MANUFACTURING Subclass" "Chart Total" "Board Total")
		foreach( m_sb_chrt_brd m_sb_chrt_brd_ls
			match = car( m_sb_chrt_brd)
			subclass = cadr( m_sb_chrt_brd)
			sprintf( chart_total "%d" caddr( m_sb_chrt_brd))
			sprintf( board_total "%d" nth( 3 m_sb_chrt_brd))
			
			fprintf( out_port format match subclass chart_total board_total)
		)
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( check_drill_chart_main_Derek06092020()
	prog( ()
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		
		init_Derek06092020()
		
		;;;;; get all drill subclass name
		drill_chart_group_ls = setof( x axlDBGetDesign()->groups equal( _type_drill_chart x->type))
		
		;;;;; get total amount from drill chart
		dcg_chart_total_ls = mapcar( lambda( (x) list( x get_chart_all_total_Derek06092020( x))) drill_chart_group_ls)
		
		;;;; get real amount of dip on the board
		drill_layer_ls = mapcar( lambda( (x) get_group_layer_Derek06092020( x)) drill_chart_group_ls)
		dgc_board_total_ls = mapcar( lambda( (x) list( x get_board_all_total_Derek06092020( x))) drill_chart_group_ls)
		
		;;;; sort our the data
		m_sb_chrt_brd_ls = get_drill_data_Derek06092020( dcg_chart_total_ls dgc_board_total_ls)
		
		;;;; write log file
		write_log_Derek06092020( m_sb_chrt_brd_ls)
		
		;;;;; display log file
		axlUIViewFileCreate( _check_drill_chart_logname "Check Drill Chart Report" nil)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_drill_chart" 'check_drill_chart_main_Derek06092020)
; (check_drill_chart_main_Derek06092020)
; skill encrypt( "C:/skill/check_drill_chart_v1.il" "C:/skill/check_drill_chart_v1.ile")
; (load "check_drill_chart_v1.il")
; (load "check_drill_chart_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup