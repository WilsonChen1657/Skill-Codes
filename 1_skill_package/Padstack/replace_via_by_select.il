;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 07/08/2019 - _Derek07082019
; introduction:
;	1. select via by box
;	2. display via converter table by grid table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek07082019()
	setq( _display_form_name "replace_via_by_box.form")
	setq( _display_form_handle 'replace_via_by_box)
	
	;;;; form setting
	setq( _form_key_select "select")
	setq( _form_key_grid "vias_grid")
	setq( _form_key_grid_col_valid list( "valid" 1))
	setq( _form_key_grid_col_curr_via list( "curr_via" 2))
	setq( _form_key_grid_col_curr_num list( "curr_num" 3))
	setq( _form_key_grid_col_replace_via list( "new_via" 4))
	setq( _form_key_apply "apply")
	setq( _form_key_replace "replace")
	setq( _form_key_clear "clear")
	setq( _form_key_close "close")
	setq( _form_string_length 40)
	
	setq( _display_via_ls nil)
	
	setq( _button_event nil)
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( create_form_Derek07082019()
	prog( ( out_port form_width display_x display_y display_width display_height button_width button_height button_x)
		out_port = outfile( _display_form_name "w")
		unless( check_value_Derek07082019( 'ArgErr 'create_form 'out_port out_port '_outport) return( nil))
		
		form_width = 52
		
		;;;;; header of the form
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=%d\n" 1)   
		fprintf( out_port "FORM TOOLWINDOW \n")
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" form_width 90)
		fprintf( out_port "HEADER \"Create Shape On Board\"\n\n")
		
		fprintf( out_port "TILE\n\n")
		
		display_x = 1
		display_y = 1
		
		;;;; header button
		display_width = form_width - 1
		display_height = 2
		
		fprintf( out_port "FIELD %s\n" _form_key_select)
		fprintf( out_port "FLOC %d %d\n" display_x display_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "Start to select vias by select" display_width display_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		;;;; main table
		display_y = display_y + 4
		display_height = 20
		
		;;;;; grid for data
		fprintf( out_port "GRID %s\n" _form_key_grid)
		fprintf( out_port "FLOC %d %d\n" display_x display_y)
		fprintf( out_port "FSIZE %d %d\n" display_width display_height)
		fprintf( out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		fprintf( out_port "GHEAD TOP\n")
		fprintf( out_port "HEADSIZE %d\n" 2)
		fprintf( out_port "OPTIONS %s\n" "3D")
		fprintf( out_port "ENDGHEAD\n")
		fprintf( out_port "ENDGRID\n\n")
		
		;;;;; button
		display_y = display_y + display_height + 1
		button_width = 8
		button_height = 2
		
		button_x = 2
		fprintf( out_port "FIELD %s\n" _form_key_apply)
		fprintf( out_port "FLOC %d %d\n" button_x display_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "APPLY" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_x = button_x + button_width + 1
		fprintf( out_port "FIELD %s\n" _form_key_replace)
		fprintf( out_port "FLOC %d %d\n" button_x display_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "REPLACE" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_x = button_x + button_width + 2
		fprintf( out_port "FIELD %s\n" _form_key_clear)
		fprintf( out_port "FLOC %d %d\n" button_x display_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "CLEAR" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_x = button_x + button_width + 1
		fprintf( out_port "FIELD %s\n" _form_key_close)
		fprintf( out_port "FLOC %d %d\n" button_x display_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "CLOSE" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		;;;;; tail of the form
		fprintf( out_port "ENDTILE\n\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
	)
)

procedure( set_form_Derek07082019( display_form)
	prog( ( col label)
		unless( check_value_Derek07082019( 'ArgErr 'set_form 'display_form display_form '_form) return( nil))
		;;
		
		;;;; setup default button
		axlFormDefaultButton( display_form _form_key_apply)
		
		;;;; setup grid column
		label = car( _form_key_grid_col_valid)
		col = make_formGridCol()
		col->fieldType = 'CHECKITEM
		col->colWidth = 1
		col->align = 'center
		col->headText = "V"
		col->scriptLabel = label
		axlFormGridInsertCol( display_form _form_key_grid col)
		
		;;;
		label = car( _form_key_grid_col_curr_via)
		col = make_formGridCol()
		col->fieldType = 'TEXT
		col->colWidth = 10
		col->align = 'left
		col->headText = "Current Via"
		col->scriptLabel = label
		axlFormGridInsertCol( display_form _form_key_grid col)
		
		;;;
		label = car( _form_key_grid_col_curr_num)
		col = make_formGridCol()
		col->fieldType = 'LONG
		col->colWidth = 2
		col->align = 'center
		col->headText = "C"
		col->scriptLabel = label
		axlFormGridInsertCol( display_form _form_key_grid col)
		
		;;;
		label = car( _form_key_grid_col_replace_via)
		col = make_formGridCol()
		col->fieldType = 'STRING
		col->colWidth = 10
		col->align = 'left
		col->headText = "Replace Via"
		col->scriptLabel = label
		col->fieldLength = _form_string_length
		axlFormGridInsertCol( display_form _form_key_grid col)
		
		;;;; for testing purpose, please comment it while releasing
	;	create_form_grid_row_Derek07082019( display_form nil "VIA8_P18_ANTI30" 3 nil)
	;	create_form_grid_row_Derek07082019( display_form nil "VIA8_P18_ANTI30" 3 nil)
	;	create_form_grid_row_Derek07082019( display_form nil "VIA8_P18_ANTI30" 3 nil)
	;	create_form_grid_row_Derek07082019( display_form nil "VIA8_P18_ANTI30" 3 nil)
	;	create_form_grid_row_Derek07082019( display_form nil "VIA8_P18_ANTI30" 3 nil)
	;	create_form_grid_row_Derek07082019( display_form nil "VIA8_P18_ANTI30" 3 nil)
		
		;;;;; refresh the grid
		axlFormGridUpdate( display_form _form_key_grid)
		
		;;;;
		axlFormGridEvents( display_form _form_key_grid 'change)

		return( t)
	)
)

procedure( get_form_grid_cell_value_Derek07082019( display_form row col @optional row_seek_col)
	prog( ( valid_col cell result)
		unless( check_value_Derek07082019( 'ArgErr 'get_form_grid_cell_value 'display_form display_form '_form) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'get_form_grid_cell_value 'row row '_natural_number_or_string) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'get_form_grid_cell_value 'col col '_natural_number) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'get_form_grid_cell_value 'row_seek_col row_seek_col '_natural_number_or_nil) return( nil))
		;;
		
		valid_col = cadr( _form_key_grid_col_valid)
		
		if( numberp( row) then
			;;; while row is number, then get the value directly
			cell = axlFormGridNewCell()
			cell->row = row
			cell->col = col
			cell = axlFormGridGetCell( display_form _form_key_grid cell)
			if( eqv( valid_col col) then
				result = cell->check
			else
				result = cell->value
				when( stringp( result) (result = upperCase( result)))
			)
		else
			;;; while row is a string 
			th = 0
			content = t
			while( content
				content = get_form_grid_cell_value_Derek07082019( display_form ++th row_seek_col)
				;;
				when( equal( row content)
					result = get_form_grid_cell_value_Derek07082019( display_form th col)
					content = nil
				)
			)
		)
		
		return( result)
	)
)

procedure( create_form_grid_rows_Derek07082019( display_form)
	prog( ( via_cnt_table via_name replace_via via_nm_ls replace_via_col curr_via_col replace_via_ls )
		unless( check_value_Derek07082019( 'ArgErr 'create_form_grid_rows 'display_form display_form '_form) return( nil))
		;;
		
		via_cnt_table = makeTable( "via_cnt_table" nil)
		replace_via_col = cadr( _form_key_grid_col_replace_via)
		curr_via_col = cadr( _form_key_grid_col_curr_via)
		
		;;;
		foreach( via_id _display_via_ls
			via_name = via_id->name
			
			if( via_cnt_table[ via_name]
				++via_cnt_table[ via_name]
				via_cnt_table[ via_name] = 1
			)
		)
		
		via_nm_ls = via_cnt_table->?
		replace_via_ls = mapcar( lambda( (x) get_form_grid_cell_value_Derek07082019( display_form x replace_via_col curr_via_col)) via_nm_ls)
		
		;;;; remove all rows
		clear_form_grid_rows_Derek07082019( display_form)
		
		;;;; fill up the data to the blank grid
		foreach( (via_name replace_via) via_nm_ls replace_via_ls
			count = via_cnt_table[ via_name]
			create_form_grid_row_Derek07082019( display_form nil via_name count replace_via)
		)

		;;;; refresh the grid
		axlFormGridUpdate( display_form _form_key_grid)
		
		return( t)
	)
)

procedure( create_form_grid_row_Derek07082019( display_form valid curr_via count replace_via)
	prog( ( row col cell )
		unless( check_value_Derek07082019( 'ArgErr 'create_form_grid_row 'display_form display_form '_form) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'create_form_grid_row 'valid valid '_bool) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'create_form_grid_row 'curr_via curr_via '_via_name) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'create_form_grid_row 'count count '_natural_number) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'create_form_grid_row 'replace_via replace_via '_string_or_nil) return( nil))
		;;
		
		row = 1
		axlFormGridInsertRows( display_form _form_key_grid 0 1)
		
		;;;;
		col = cadr( _form_key_grid_col_valid)
		set_form_grid_cell_Derek07082019( display_form row col valid t)
		
		;;;;
		col = cadr( _form_key_grid_col_curr_via)
		set_form_grid_cell_Derek07082019( display_form row col curr_via t)
		
		;;;;
		col = cadr( _form_key_grid_col_curr_num)
		set_form_grid_cell_Derek07082019( display_form row col count t)
		
		;;;;
		col = cadr( _form_key_grid_col_replace_via)
		set_form_grid_cell_Derek07082019( display_form row col replace_via nil)
		
		return( t)
	)
)

procedure( clear_form_grid_rows_Derek07082019( display_form)
	prog( ( curr_via curr_via_col)
		unless( check_value_Derek07082019( 'ArgErr 'clear_form_grid_rows 'display_form display_form '_form) return( nil))
		;;
		
		curr_via = t
		curr_via_col = cadr( _form_key_grid_col_curr_via)
		while( curr_via
			curr_via = get_form_grid_cell_value_Derek07082019( display_form 1 curr_via_col)
			when( curr_via axlFormGridDeleteRows( display_form _form_key_grid 1 1))
		)
		
		;;;;; refresh the grid
		axlFormGridUpdate( display_form _form_key_grid)
		
		return( t)
	)
)

procedure( popup_form_done_Derek07082019( )
	let( ()
		_button_event = 'done
		axlFinishEnterFun()
	)
)

procedure( popup_form_cancel_Derek07082019( )
	let( ()
		_button_event = 'cancel
		axlCancelEnterFun()
	)
)

procedure( update_form_grid_by_select( display_form)
	prog( ( display_popup opt_ls curr_via_ls curr_via_cnt)
		unless( check_value_Derek07082019( 'ArgErr 'update_form_grid_by_select 'display_form display_form '_form) return( nil))
		;;
		
		println( "Info: update_form_grid_by_select() - Please start selecting vias")
		
		;;;; setup right-popup
		display_popup = axlUIPopupDefine( nil list( list( "Done" 'popup_form_done_Derek07082019) list( "Cancel" 'popup_form_cancel_Derek07082019)))
		axlUIPopupSet( display_popup)
		
		;;;; setup find filter
		opt_ls = '( "NOALL" "VIAS")
		axlSetFindFilter( ?enabled opt_ls ?onButtons opt_ls)
		
		while( axlSelect()
			display_popup = axlUIPopupDefine( nil list( list( "Done" 'popup_form_done_Derek07082019) list( "Cancel" 'popup_form_cancel_Derek07082019)))
			axlUIPopupSet( display_popup)
			;;
			curr_via_ls = axlGetSelSet()
			curr_via_cnt = axlGetSelSetCount()
			printf( "Current count of selected vias: %d\n" curr_via_cnt)
		)
		when( eq( 'cancel _button_event) (curr_via_ls = nil))
		
		;;; remove the popup
		axlUIPopupSet( nil)
		
		when( dtpr( curr_via_ls)
			;;; add to the main list
			curr_via_ls = setof( x curr_via_ls equal( "via" x->objType))
			curr_via_ls = setof( x curr_via_ls not( memq( x _display_via_ls)))
			_display_via_ls = append( _display_via_ls curr_via_ls)
			
			;;; highlight selected obj
			axlHighlightObject( _display_via_ls nil)
			
			;;;
			create_form_grid_rows_Derek07082019( display_form)
		)
		
		return( t)
	)
)

procedure( set_form_grid_cell_Derek07082019( display_form row col val no_edit)
	prog( ( valid_col cell)
		unless( check_value_Derek07082019( 'ArgErr 'set_form_grid_cell 'display_form display_form '_form) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'set_form_grid_cell 'row row '_natural_number) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'set_form_grid_cell 'col col '_natural_number) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'set_form_grid_cell 'val val '_string_or_bool_or_natural_number) return( nil))
		unless( check_value_Derek07082019( 'ArgErr 'set_form_grid_cell 'no_edit no_edit '_bool) return( nil))
		;;
		
		valid_col = cadr( _form_key_grid_col_valid)
		
		cell = axlFormGridNewCell()
		cell->row = row
		cell->col = col
		if( eqv( valid_col col)
			cell->check = val
			cell->value = val
		)
		cell->noEdit = no_edit
		axlFormSetField( display_form _form_key_grid cell)
		
		;;;;; refresh the grid
		axlFormGridUpdate( display_form _form_key_grid)
		
		return( t)
	)
)

procedure( update_form_grid_by_apply_Derek07082019( display_form)
	prog( ( valid_col replace_via_col curr_via_col curr_via replace_via row via_id )
		unless( check_value_Derek07082019( 'ArgErr 'update_form_grid_by_apply 'display_form display_form '_form) return( nil))
		;;
		
		valid_col = cadr( _form_key_grid_col_valid)
		replace_via_col = cadr( _form_key_grid_col_replace_via)
		curr_via_col = cadr( _form_key_grid_col_curr_via)
		
		curr_via = replace_via = t
		row = 1
		while( curr_via
			curr_via = get_form_grid_cell_value_Derek07082019( display_form row curr_via_col)
			replace_via = get_form_grid_cell_value_Derek07082019( display_form row replace_via_col)
			;;
			when( and( stringp( curr_via) stringp( replace_via))
				;;; load padstack
				via_id = axlDBFindByName( 'padstack replace_via)
				if( via_id then
					printf( "Info: update_form_grid_by_apply() - Successful to find replace_via[%s] of curr_via[%s]\n" replace_via curr_via)
					set_form_grid_cell_Derek07082019( display_form row valid_col t t)
					set_form_grid_cell_Derek07082019( display_form row replace_via_col nil t)
				else
					printf( "Warning: update_form_grid_by_apply() - Fail to find replace_via[%s] of curr_via[%s]\n" replace_via curr_via)
					set_form_grid_cell_Derek07082019( display_form row valid_col nil t)
					set_form_grid_cell_Derek07082019( display_form row replace_via_col "" nil)
				)
				row++
			)
			;;
			when( and( stringp( curr_via) null( replace_via))
				printf( "Warning: update_form_grid_by_apply() - Remove the row for curr_via[%s]\n" curr_via)
				axlFormGridDeleteRows( display_form _form_key_grid row 1)
			)
		)
		
		;;;;; refresh the grid
		axlFormGridUpdate( display_form _form_key_grid)
		
		return( t)
	)
)

procedure( get_form_grid_via_pairs_Derek07082019( display_form)
	prog( ( valid_col replace_via_col curr_via_col row curr_via replace_via valid curr_replace_via_ls via_id currName_newId)
		unless( check_value_Derek07082019( 'ArgErr 'get_form_grid_via_pairs 'display_form display_form '_form) return( nil))
		;;
		
		valid_col = cadr( _form_key_grid_col_valid)
		replace_via_col = cadr( _form_key_grid_col_replace_via)
		curr_via_col = cadr( _form_key_grid_col_curr_via)
		
		row = 1
		curr_via = replace_via = t
		while( curr_via
			valid = get_form_grid_cell_value_Derek07082019( display_form row valid_col)
			curr_via = get_form_grid_cell_value_Derek07082019( display_form row curr_via_col)
			replace_via = get_form_grid_cell_value_Derek07082019( display_form row replace_via_col)
			;;
			when( valid
				via_id = axlDBFindByName( 'padstack replace_via)
				currName_newId = list( curr_via via_id)
				curr_replace_via_ls = append1( curr_replace_via_ls currName_newId)
			)
			
			row++
		)
		
		return( curr_replace_via_ls)
	)
)

procedure( action_form_Derek07082019( display_form)
	prog( ( field curr_replace_via_ls)
		unless( check_value_Derek07082019( 'ArgErr 'action_form 'display_form display_form '_form) return( nil))
		;;
		
		field = display_form->curField
		
		cond(
			( equal( _form_key_select field)
				update_form_grid_by_select( display_form)
			)
			( equal( _form_key_clear field)
				clear_form_grid_rows_Derek07082019( display_form)
				axlDehighlightObject( _display_via_ls nil)
				_display_via_ls = nil
			)
			( equal( _form_key_close field)
				axlDehighlightObject( _display_via_ls nil)
				_display_via_ls = nil
				axlFormClose( display_form)
			)
			( equal( _form_key_apply field)
				update_form_grid_by_apply_Derek07082019( display_form)
			)
			( equal( _form_key_replace field)
				curr_replace_via_ls = get_form_grid_via_pairs_Derek07082019( display_form)
				if( dtpr( curr_replace_via_ls)
					replace_vias_Derek07082019( curr_replace_via_ls)
					println( "Info: action_form() - Please [APPLY] at least a valid via data row to replace the via")
				)
			)
		)
	
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( replace_vias_Derek07082019( curr_replace_via_ls)
	prog( ( curr_replace curr_via_nm replace_via_id replace_via_nm curr_via_ls result total status)
		unless( check_value_Derek07082019( 'ArgErr 'replace_vias 'curr_replace_via_ls curr_replace_via_ls '_dtpr) return( nil))
		;;
		
		axlDehighlightObject( _display_via_ls)
		
		foreach( curr_replace curr_replace_via_ls
			curr_via_nm = car( curr_replace)
			replace_via_id = cadr( curr_replace)
			replace_via_nm = replace_via_id->name
			;;
			curr_via_ls = setof( x _display_via_ls equal( curr_via_nm x->name))
			result = axlReplacePadstack( curr_via_ls replace_via_id)
			;;
			total = length( curr_via_ls)
			status = if( result "Successful" "Fail")
			printf( "Info: replace_vias() - %s to replace[%s] to [%s](%d)\n" status curr_via_nm replace_via_nm total)
			;;
			axlHighlightObject( curr_via_ls)
		)
		
		return( t)
	)
)

procedure( check_value_Derek07082019( err_type func_nm val_nm val type)
	prog( ( result)
		unless( symbolp( type) println( "ArgErr: check_value() - [type] is not a symbol") return( nil))
		unless( symbolp( err_type) println( "ArgErr: check_value() - [err_type] is not a symbol") return( nil))
		unless( symbolp( func_nm) println( "ArgErr: check_value() - [func_nm] is not a symbol") return( nil))
		unless( symbolp( val_nm) println( "ArgErr: check_value() - [val_nm] is not a symbol") return( nil))
		;;
		
		caseq( type
			( '_form
				result = axlIsFormType( val)
			)
			( '_via_name
				result = and( stringp( val) member( val axlGetAllViaList()~>name))
			)
			( '_natural_number
				;; 1 2 3 4 5 6 7 8 9
				result = and( integerp( val) (val > 0))
			)
			( '_natural_number_or_string
				;; 1 2 3 4 5 6 7 8 9 ""
				result = or( and( integerp( val) (val > 0)) stringp( val))
			)
			( '_natural_number_or_nil
				;; 1 2 3 4 5 6 7 8 9 ""
				result = or( and( integerp( val) (val > 0)) null( val))
			)
			( '_bool
				result = booleanp( val)
			)
			( '_string
				result = stringp( val)
			)
			( '_string_or_nil
				result = or( null( val) stringp( val))
			)
			( '_string_or_bool
				result = or( booleanp( val) stringp( val))
			)
			( '_string_or_bool_or_natural_number
				result = or( booleanp( val) stringp( val) and( integerp( val) (val > 0)))
			)
			( '_dtpr
				result = dtpr( val)
			)
			( '_outport
				result = outportp( val)
			)
			( t
				printf( "ERROR: check_value() - Yet to define type[%s] for value[%s] in function[%s]\n" type val_nm val_nm func_nm)
			)
		)
		
		unless( result printf( "%s: %s() - [%s] is not a %s\n" err_type func_nm val_nm type))
		
		return( result)
	)
)

procedure( perform_status_Derek07082019( option)
	setq( _orign_visible nil)
	prog( ()
		unless( check_value_Derek20190826( 'ArgErr 'perform_status 'option option '_v_bool) return( nil))
		;;
		
		if( option then
			;;; end of a process
			axlVisibleSet( _orign_visible)
			axlVisibleUpdate( t)
		else
			;;; begining of a process
			_orign_visible = axlVisibleGet()
		)
		
		;;;;
		axlDBControl( 'drcEnable option)
		axlDBControl( 'busRats option)
		axlDBControl( 'ratnestDistance option)
		axlDBMemoryReclaim()
		
		
		return( t)
	)
)

procedure( replace_via_by_select_main_Derek07082019()
	prog( ( display_popup opt_ls display_form )
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		;;
		
		;;;; initlize the board memory
		axlShell( "generalEdit")
		perform_status_Derek07082019( nil)
		
		;;;; initlize the program
		init_Derek07082019()
		
		;;;; setup form
		create_form_Derek07082019()
		; _display_form_handle
		display_form = (axlFormCreate gensym() _display_form_name '("east" "outer") 'action_form_Derek07082019 nil)
		unless( axlIsFormType( display_form) println( "ERROR: replace_via_by_box_main() - Fail to create form") return( nil))
		set_form_Derek07082019( display_form)
		axlFormDisplay( display_form)
		
		;;;; clear all he highligh if the form is left by cross
		axlDehighlightObject( _display_via_ls nil)
		
		println( "Process 'replace_via_by_select' is done. Please check this out")
		perform_status_Derek07082019( t)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "replace_via_by_select" 'replace_via_by_select_main_Derek07082019)
; (replace_via_by_select_main_Derek07082019)
; skill (encrypt "c:/skill/replace_via_by_select_v1.il" "c:/skill/replace_via_by_select_v1.ile")
; (load "replace_via_by_select_v1.ile")
; (load "replace_via_by_select_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup