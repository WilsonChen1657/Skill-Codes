;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
; Developer: Derek Hsu
; Starting Date: 09/17/2020 - _Derek09172020
; Introduction: highlight/dehighligh symbols by page
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek09172020()
	setq( _page_to_syms_table nil)
	setq( _total_page nil)
	
	;;;;;
	setq( _form_name "highlight_symbol_by_page.form")
	setq( _form_field_grid_pages "pages")
	
	setq( _grid_pages_col_ls list( nil "H" "Page" "Layer" "Total"))
	setq( _grid_pages_h_col_num 1)
	setq( _grid_pages_page_col_num 2)
	setq( _grid_pages_layer_col_num 3)
	setq( _grid_pages_total_col_num 4)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_form_Derek09172020()
	prog( ( out_port)
		out_port = outfile( _form_name "w")
		unless( outportp( out_port) printf( "ERROR: write_form() - Fail to write form: %s\n" _form_name) return( nil))
	
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=%d\n" 1)   
		fprintf( out_port "FORM TOOLWINDOW \n")
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" 34 90)
		fprintf( out_port "HEADER \"Highlight Symbols by Page\"\n\n")
		fprintf( out_port "TILE\n\n")
		
		fprintf( out_port "GRID %s\n" _form_field_grid_pages)
		fprintf( out_port "FLOC %d %d\n" 1 1)
		fprintf( out_port "FSIZE %d %d\n" 34 30)
		fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		fprintf( out_port "GHEAD TOP\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "ENDGRID\n\n")
		
		fprintf( out_port "ENDTILE\n\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
	)
)

procedure( create_col_Derek09172020( field_type col_width head_text @optional (align 'left))
	prog( ( col)
		col = make_formGridCol()
		col->fieldType = field_type
		col->colWidth = col_width
		col->align = align
		col->headText = head_text
		col->scriptLabel = head_text
		
		return( col)
	)
)

procedure( set_form_grid_header_Derek09172020( form field)
	let( ( head_text col)
		head_text = nth( _grid_pages_h_col_num _grid_pages_col_ls)
		col = create_col_Derek09172020( 'CHECKITEM 2 head_text)
		axlFormGridInsertCol( form field col)
		
		head_text = nth( _grid_pages_page_col_num _grid_pages_col_ls)
		col = create_col_Derek09172020( 'LONG 6 head_text)
		axlFormGridInsertCol( form field col)
		
		head_text = nth( _grid_pages_layer_col_num _grid_pages_col_ls)
		col = create_col_Derek09172020( 'TEXT 10 head_text)
		axlFormGridInsertCol( form field col)
		
		head_text = nth( _grid_pages_total_col_num _grid_pages_col_ls)
		col = create_col_Derek09172020( 'LONG 6 head_text)
		axlFormGridInsertCol( form field col)
		
		axlFormGridUpdate( form field)
	)
)

procedure( create_cell_Derek09172020( row col @key (value nil) (no_edit t))
	prog( ( cell)
		cell = axlFormGridNewCell()
		cell->row = row
		cell->col = col
		cell->value = value
		cell->noEdit = no_edit
		
		return( cell)
	)
)

procedure( set_form_grid_row_Derek09172020( form field row page layers amount)
	let( ( cell)
		axlFormGridInsertRows( form field row 1)
		
		cell = create_cell_Derek09172020( row _grid_pages_h_col_num ?no_edit nil)
		axlFormSetField( form field cell)
		
		cell = create_cell_Derek09172020( row _grid_pages_page_col_num ?value page)
		axlFormSetField( form field cell)
		
		cell = create_cell_Derek09172020( row _grid_pages_layer_col_num ?value layers)
		axlFormSetField( form field cell)
		
		cell = create_cell_Derek09172020( row _grid_pages_total_col_num ?value amount)
		axlFormSetField( form field cell)
		
		axlFormGridUpdate( form field)
	)
)

procedure( set_form_grid_content_Derek09172020( form field)
	let( ( max_page row sym_ls amount layers)
		max_page = apply( 'max _page_to_syms_table->?)
		
		row = 1
		for( page 1 max_page
			sym_ls = mapcar( 'get_sym_by_refdes _page_to_syms_table[ page])
			when( dtpr( sym_ls)
				amount = length( sym_ls)
				layers = get_all_layer_from_syms_Derek09172020( sym_ls)
				set_form_grid_row_Derek09172020( form field row++ page layers amount)
			)
		)
	)
)

procedure( set_form_Derek09172020( form)
	let( ()
		set_form_grid_header_Derek09172020( form _form_field_grid_pages)
		set_form_grid_content_Derek09172020( form _form_field_grid_pages)
		
		axlFormGridEvents( form _form_field_grid_pages 'change)
	)
)

procedure( get_page_by_grid_row_Derek09172020( form field row)
	prog( ( cell grid_cell page)
		cell = create_cell_Derek09172020( row _grid_pages_page_col_num)
		grid_cell = axlFormGridGetCell( form field cell)
		page = grid_cell->value
		
		return( page)
	)
)

procedure( form_action_Derek09172020( form)
	let( ( field value row col page sym_ls)
		field = form->curField
		value = form->curValue
		col = form->col
		
		cond(
			( field == _form_field_grid_pages && col == _grid_pages_h_col_num
				row = form->row
				
				page = get_page_by_grid_row_Derek09172020( form field row)
				sym_ls = mapcar( 'get_sym_by_refdes _page_to_syms_table[ page])
				
				highlight_syms_Derek09172020( sym_ls value)
			)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_sym_by_refdes( refdes)
	prog( ()
		return( axlDBFindByName( 'refdes refdes))
	)
)

procedure( get_unique_list_Derek09172020( obj_ls)
	prog( ()
		obj_ls = maplist( lambda( (xs) if( exists( x cdr( xs) car( xs) == x) nil car( xs))) obj_ls)
		obj_ls = remq( nil obj_ls)
		
		return( obj_ls)
	)
)

procedure( get_subclass_in_layer( layer)
	prog( ( subclass)
		subclass = cadr( parseString( layer "/"))
		
		return( subclass)
	)
)

procedure( get_all_layer_from_syms_Derek09172020( sym_ls)
	prog( ( subclass_ls subclasses layer_ls)
		foreach( sym_id sym_ls
			foreach( pin_id sym_id->pins
				layer = car( pin_id->startEnd)
				
				unless( member( layer layer_ls)
					layer_ls = append1( layer_ls layer)
				)
			)
		)
		
		subclass_ls = mapcar( 'get_subclass_in_layer layer_ls)
		subclass_ls = sort( subclass_ls 'alphalessp)
		subclass_ls = reverse( subclass_ls)
		
		subclasses = buildString( subclass_ls ",")
		
		return( subclasses)
	)
)

procedure( highlight_syms_Derek09172020( sym_ls to_highlight)
	let( ()
		if( to_highlight then
			axlHighlightObject( sym_ls)
		else
			axlDehighlightObject( sym_ls)
		)
	)
)

procedure( get_page_from_sym_Derek09172020( sym_id toString)
	; physical_path = "@bt_evt_sib_sas3_ee_sch_v41_20191104.bluetail_sib_sas3_sch(sch_1):page48_ins24033300@other.\\m_hole_c.normal\\(chips)"
	; sym_id = car( axlGetSelSet())
	prog( ( page_ls physical_path page )
		rexCompile( ":page\\([0-9]+\\)_")
		func_ls = sym_id->component->functions
		foreach( func_id func_ls
			physical_path = func_id->prop~>PHYSICAL_PATH
			if( stringp( physical_path) && rexExecute( physical_path) then
				page = rexSubstitute( "\\1")
				unless( toString (page = atoi( page)))
				page_ls = append1( page_ls page)
			else
				printf( "WARNING: get_page_from_sym() - Fail to get physical path from %L\n" list( sym_id->refdes sym_id->xy func_id->prop~>??))
			)
		)
		
		;;;;; remove duplicate
		page_ls = maplist( lambda( (x) unless( memv( car( x) cdr( x)) car( x))) page_ls)
		page_ls = remq( nil page_ls)
		
		
		return( page_ls)
	)
)

procedure( get_table_by_page_to_symbols_Derek09172020( sym_ls)
	prog( ( page_to_syms_table page_ls)
		page_to_syms_table = makeTable( 'page_to_syms_table nil)
		
		foreach( sym_id sym_ls
			page_ls = get_page_from_sym_Derek09172020( sym_id nil)
			
			foreach( page page_ls
				page_to_syms_table[ page] = append1( page_to_syms_table[ page] sym_id->refdes)
			)
		)
		
		return( page_to_syms_table)
	)
)

procedure( get_all_symbol_in_schematic_Derek09172020()
	prog( ( sym_ls)
		sym_ls = axlDBGetDesign()->symbols
		sym_ls = setof( x sym_ls x->component)
		
		return( sym_ls)
	)
)

procedure( highlight_symbol_by_page_main_Derek09172020()
	prog( ()
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		;;
		
		init_Derek09172020()
		
		sym_ls = get_all_symbol_in_schematic_Derek09172020()
		
		_page_to_syms_table = get_table_by_page_to_symbols_Derek09172020( sym_ls)
		
		;;;;;
		write_form_Derek09172020()
		form = axlFormCreate( gensym() _form_name '("east" "outer") 'form_action_Derek09172020 t)
		set_form_Derek09172020( form)
		axlFormDisplay( form)
		
		deleteFile( _form_name)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "highlight_symbol_by_page" 'highlight_symbol_by_page_main_Derek09172020)
; (highlight_symbol_by_page_main_Derek09172020)
; skill encrypt( "c:/skill/highlight_symbol_by_page_v1.il" "C:/skill/highlight_symbol_by_page_v1.ile")
; (load "highlight_symbol_by_page_v1.il")
; (load "highlight_symbol_by_page_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup