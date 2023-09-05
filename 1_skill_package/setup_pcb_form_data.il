;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; information
; 
; Developer: Derek Hsu
; Starting Date: 05/22/2019 - _Derek05222019
; compatible version: 16.6, 17.2
; purpose: import data from an excel to board pcb_fab
; usage:
;	1. fill up the [main] sheets in Board_data_form.xlsx
;	2. import flex_board_data_v1.dra to a allegro design editor
;	3. use this tool to import the data from (1) to (2)
; introduction: 
;	1. user defined subclass:
;		1. board geometry/board_form			: the content including positive-side form and content
;		2. board geometry/board_form_mirror		: the content including mirrored form and content
;	2. excel to board layer
;		1. [PCB_FAB] -> drawing format/pcb_fab
;		2. [PANEL] -> drawing format/panel
;		3. [PCBA] -> drawing format/pcba_top
;				  -> drawing format/pcba_bot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of information

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global_variable

procedure( init_Derek05222019()
	;;; key
	setq( _key_des1 "[des1]")
	setq( _key_des2 "[des2]")
	setq( _key_pn "[pn]")
	setq( _key_left "[l]")
	setq( _key_right "[r]")
	setq( _key_form_rev "[v%d]")
	setq( _key_form_layout "[layout%d]")
	setq( _key_form_hardware "[hardware%d]")
	setq( _key_form_date "[date%d]")
	setq( _key_form_approved "[appr%d]")
	
	;;; header for all
	setq( _header_col "C")
	setq( _rev_col "C")
	setq( _layout_col "D")
	setq( _hardware_col "E")
	setq( _date_col "F")
	setq( _approved_col "G")
	
	;;; history row
	setq( _des1_row_offset 0)
	setq( _des2_row_offset 1)
	setq( _pn_row_offset 2)
	setq( _pcb_header_start_row 1)
	setq( _panel_header_start_row 11)
	setq( _pcba_header_start_row 21)
	
	setq( _pcb_history_start_row 5)
	setq( _panel_history_start_row 15)
	setq( _pcba_history_start_row 25)
	setq( _history_max_row 5)
	
	;;;;; general setting
	setq( _pcba_top_ly "DRAWING FORMAT/PCBA_TOP")
	setq( _pcba_bot_ly "DRAWING FORMAT/PCBA_BOT")
	setq( _panel_ly "DRAWING FORMAT/PANEL")
	setq( _pcb_fab_ly "DRAWING FORMAT/PCB_FAB")
	setq( _brd_frm_ly "BOARD GEOMETRY/BOARD_FORM")
	setq( _brd_frm_mirr_ly "BOARD GEOMETRY/BOARD_FORM_MIRROR")
	setq( _brd_frm_ky_ly "BOARD GEOMETRY/BOARD_FORM_KEY")
	setq( _brd_frm_ky_mirr_ly "BOARD GEOMETRY/BOARD_FORM_KEY_MIRROR")
	
	unless( axlIsLayer( _pcba_top_ly) axlLayerCreateNonConductor( _pcba_top_ly))
	unless( axlIsLayer( _pcba_bot_ly) axlLayerCreateNonConductor( _pcba_bot_ly))
	unless( axlIsLayer( _panel_ly) axlLayerCreateNonConductor( _panel_ly))
	unless( axlIsLayer( _pcb_fab_ly) axlLayerCreateNonConductor( _pcb_fab_ly))
	unless( axlIsLayer( _brd_frm_ly) axlLayerCreateNonConductor( _brd_frm_ly))
	unless( axlIsLayer( _brd_frm_mirr_ly) axlLayerCreateNonConductor( _brd_frm_mirr_ly))
	unless( axlIsLayer( _brd_frm_ky_ly) axlLayerCreateNonConductor( _brd_frm_ky_ly))
	unless( axlIsLayer( _brd_frm_ky_mirr_ly) axlLayerCreateNonConductor( _brd_frm_ky_mirr_ly))
	
	;;;;; 
	setq( _main_sheet_nm "main")
	setq( _excel_table_name "Excel_Sheet[0].table")
	setq( _form_key_ls list( "[v1]" "[v2]" "[v3]" "[v4]" "[v5]"
					"[layout1]" "[layout2]" "[layout3]" "[layout4]" "[layout5]"
					"[hardware1]" "[hardware2]" "[hardware3]" "[hardware4]" "[hardware5]"
					"[date1]" "[date2]" "[date3]" "[date4]" "[date5]"
					"[appr1]" "[appr2]" "[appr3]" "[appr4]" "[appr5]"
					"[des1]" "[des2]" "[pn]" "[l]" "[r]"))
	setq( _board_form_text_group "board_form_text")
	setq( _sheet11 list( "1" "1"))
	setq( _sheet12 list( "1" "2"))
	setq( _sheet22 list( "2" "2"))
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( read_content_from_table_Derek05222019( )
	prog( (in_port board_form_table comma_th)
		in_port = infile( _excel_table_name)
		unless( inportp( in_port) printf( "ArgErr: read_content_from_table() - Fail to read file [%s]\n" _excel_table_name) return( nil))
		;;
		board_form_table = makeTable( "board_form_table" nil)
		while( gets( line in_port)
			comma_th = nindex( line ",")
			if( plusp( comma_th) then
				key = substring( line 1 sub1( comma_th))
				val = substring( line add1( comma_th) ( strlen( line) - comma_th - 1))
				;;
				if( board_form_table[key] then
					printf( "Warning: read_content_from_table() - Fail to set duplicated data [%s]\n" line)
				else
					board_form_table[key] = val
				)
			else
				printf( "Warning: read_content_from_table() - Fail to get comma from file data [%s]\n" line)
			)
		)
		close( in_port)
		
		return( board_form_table)
	)
)

procedure( get_content_from_table_Derek05222019( type board_form_table header_start_row history_start_row)
	;;; the line in _excel_table_name should be [A1],content
	;;;		Key: A1, value: content
	prog( (key line in_port row des1 des2 pn cnt history_ls rev layout hardware date approved result)
		unless( symbolp( type) println( "ArgErr: get_content_from_table() - type is not a symbol") return( nil))
		unless( plusp( header_start_row) println( "ArgErr: get_content_from_table() - header_start_row is not a positive integer") return( nil))
		unless( plusp( history_start_row) println( "ArgErr: get_content_from_table() - history_start_row is not a positive integer") return( nil))
		unless( tablep( board_form_table) println( "ArgErr: get_content_from_table() - board_form_table is not a table") return( nil))
		;;
		
		;;; get description_1
		row = header_start_row + _des1_row_offset
		sprintf( key "[%s%d]" _header_col row)
		des1 = board_form_table[key]
		
		;;; get description_2 / this section is skippable
		row = header_start_row + _des2_row_offset
		sprintf( key "[%s%d]" _header_col row)
		des2 = board_form_table[key]
		unless( stringp( des2) (des2 = ""))
		
		;;; get part number
		row = header_start_row + _pn_row_offset
		sprintf( key "[%s%d]" _header_col row)
		pn = board_form_table[key]
		
		unless( and( stringp( des1) stringp( des2) stringp( pn))
			printf( "Fail to get header from %s\n\tDescription_1:%L\n\tDescription_2:%L\n\tPart Number:%L\n" type des1 des2 pn)
			return( nil)
		)
		
		;;; get history data
		cnt = 0
		while( (cnt < _history_max_row)
			row = history_start_row + cnt
			;;
			sprintf( key "[%s%d]" _rev_col row)
			rev = board_form_table[key]
			sprintf( key "[%s%d]" _layout_col row)
			layout = board_form_table[key]
			sprintf( key "[%s%d]" _hardware_col row)
			hardware = board_form_table[key]
			sprintf( key "[%s%d]" _date_col row)
			date = board_form_table[key]
			sprintf( key "[%s%d]" _approved_col row)
			approved = board_form_table[key]
			;;
			cond(
				( not( or( stringp( rev) stringp( layout) stringp( hardware) stringp( date) stringp( approved)))
					cnt = _history_max_row
				)
				( not( and( stringp( rev) stringp( layout) stringp( hardware) stringp( date) stringp( approved)))
					;;; all the col in row has to be filled, otherwise skip this row
					printf( "Warning: get_content_from_table() - A row in type[%s] does not complete, please check\n" type)
					printf( "rev:[%s] layout:[%s] hardware:[%s] date:[%s] approved[%s]\n" rev layout hardware date approved)
					cnt = _history_max_row
				)
				(t
					history_ls = append1( history_ls list( rev layout hardware date approved))
					cnt++
				)
			)
		)
		
		;;; check history date
		unless( dtpr( history_ls) printf( "ERROR: get_content_from_table() - None of history has been found in type[%s]\n" type) return( nil))
		
		result = list( des1 des2 pn history_ls)
		
		return( result)
	)
)

procedure( get_key_from_layer_Derek05222019( type layer_ls)
	prog( ( text_ls key_table)
		unless( symbolp( type) println( "ArgErr: get_key_from_layer() - type is not a symbol") return( nil))
		when( stringp( layer_ls) (layer_ls = list( layer_ls)))
		unless( dtpr( layer_ls) println( "ArgErr: get_key_from_layer() - layer_ls is not a  layer list") return( nil))
		unless( forall( x layer_ls axlIsLayer( x)) println( "ArgErr: get_key_from_layer() - layer_ls is not a valid layer list") return( nil))
		;;
		
		;;;;; display layer
		axlVisibleDesign( nil)
		foreach( layer layer_ls axlVisibleLayer( layer t))
		axlVisibleUpdate( t)
		
		;;; get all text
		axlSetFindFilter( ?enabled list( "TEXT") ?onButtons list( "TEXT"))
		axlAddSelectAll()
		text_ls = axlGetSelSet()
		
		;;; restore to origin status
		axlClearSelSet()
		axlSetFindFilter( ?enabled list( "NOALL") ?onButtons list( "NOALL"))
		
		;;; remove title or anay other content without []
		unless( dtpr( text_ls) printf( "ERROR: get_key_from_layer() - Fail to get text from layer [%L]\n" layer_ls) return( nil))
		text_ls = setof( x text_ls stringp( x->text))
		text_ls = setof( x text_ls and( index( x->text "[") index( x->text "]")))
		
		;;; create table
		key_table = makeTable( type nil)
		foreach( text_id text_ls
			key = text_id->text
			xy = text_id->xy
			text_block = text_id->textBlock
			is_mirror = text_id->isMirrored
			key_table[ key] = list( xy text_block is_mirror)
		)
		
		return( key_table)
	)
)

procedure( get_board_form_text_group_Derek05222019( )
	let( ( err group_id)
		err = "ERROR: get_board_form_text_group() -"
		
		;;;
		group_id = axlSelectByName( "GROUP" _board_form_text_group)
		axlClearSelSet()
		
		;;; check this result
		group_len = length( group_id)
		caseq( group_len
			(0
				printf( "None of group[%s] has been found\n" _board_form_text_group)
				group_id = nil
			)
			(1
				group_id = car( group_id)
			)	
			(t
				printf( "%s more than one group has been found %L\n" err group_id~>name)
				group_id = nil
			)
			
		)
		
		group_id
	)
)

procedure( clear_text_group_Derek05222019( )
	;;; remove text by group
	;;; all the text should be on the in _pcba_top_ly / _pcba_bot_ly / _panel_ly / _pcb_fab_ly
	;; axlDBCreateGroup( _board_form_text_group "generic" axlGetSelSet())
	prog( (group_id text_ls total layer_ls)
		;;
		group_id = get_board_form_text_group_Derek05222019( )
		unless( group_id println( "clear_text_group() - None of text has been removed") return( t))
		
		text_ls = group_id->groupMembers
		total = length( text_ls)
		layer_ls = list( _pcba_top_ly _pcba_bot_ly _panel_ly _pcb_fab_ly)
		;;
		axlDBRemoveGroupObjects( group_id text_ls)
		axlDBDisbandGroup( group_id)
		foreach( text_id text_ls axlDeleteObject( text_id))
		;;
		printf( "clear_text_group() - There are %d text removed from %L\n" total layer_ls)
		
		return( t)
	)
)

procedure( create_text_to_layer_Derek05222019( type text to_layer xy_block_mirror)
	prog( (err argerr xy text_block is_mirror text_id text_orient)
		argerr = "ArgErr: create_text_to_layer() -"
		err = "ERROR: create_text_to_layer() -"
		unless( symbolp( type) printf( "%s type is not a symbol\n" argerr) return( nil))
		unless( stringp( text) printf( "%s text is not a string\n" argerr) return( nil))
		unless( stringp( to_layer) printf( "%s to_layer is not a string\n" argerr) return( nil))
		unless( axlIsLayer( to_layer) printf( "%s to_layer is not a valid layer\n" argerr) return( nil))
		unless( dtpr( xy_block_mirror) printf( "%s xy_block_mirror is not a list\n" argerr) return( nil))
		;;
		
		xy = car( xy_block_mirror)
		text_block = cadr( xy_block_mirror)
		is_mirror = caddr( xy_block_mirror)
		unless( dtpr( xy) printf( "%s xy is not a list\n" argerr) return( nil))
		unless( plusp( atoi( text_block)) printf( "%s text_block is not a integer convertable string\n" argerr) return( nil))
		unless( booleanp( is_mirror) printf( "%s is_mirror is not a boolean variable\n" argerr) return( nil))
		;;
		
		unless( equal( "" text)
			text_orient = make_axlTextOrientation( ?textBlock text_block ?rotation 0.0 ?mirrored is_mirror ?justify "center")
			text_id = caar( axlDBCreateText( text xy text_orient to_layer))
			printf( "INFO: create_text_to_layer() - Creating text [%s] at %L on %s\n" text xy to_layer)
		)
		
;		;;; check the result of the text
;		if( cadr( text_id) then
;			;;; if second value is t, then there is a DRC created
;			printf( "%s Fail to create text[%s] to layer[%s]\n" err text to_layer)
;			text_id = nil
;		else
;			text_id = car( text_id)
;			if( onep( length( text_id)) then
;				text_id = car( text_id)
;			else
;				printf( "%s More then a text has been created %L\n" err text_id~>text)
;				text_id = nil
;			)
;		)
		
		return( text_id)
	)
)

procedure( create_text_Derek05222019( type data_ls key_table sheet_2 to_layer)
	prog( ( des1 des2 pn history_ls left right xy_block_mirror text_id text_ls group_id text key cell_ls)
		unless( symbolp( type) printf( "ArgErr: create_text() - type is not a symbol\n") return( nil))
		unless( dtpr( data_ls) printf( "ArgErr: create_text() - data_ls is not a list\n") return( nil))
		unless( tablep( key_table) printf( "ArgErr: create_text() - key_table is not a table\n") return( nil))
		unless( dtpr( sheet_2) printf( "ArgErr: create_text() - sheet_2 is not a list\n") return( nil))
		unless( eqv( 2 length( sheet_2)) printf( "ArgErr: create_text() - sheet_2 does not have 2 elements\n") return( nil))
		unless( stringp( to_layer) printf( "ArgErr: create_text() - to_layer is not a string\n") return( nil))
		unless( axlIsLayer( to_layer) printf( "ArgErr: create_text() - to_layer is not a valid layer\n") return( nil))
		;;
		
		des1 = car( data_ls)
		des2 = cadr( data_ls)
		pn = caddr( data_ls)
		history_ls = cadddr( data_ls)
		left = car( sheet_2)
		right = cadr( sheet_2)
		unless( and( stringp( des1) stringp( des2) stringp( pn) dtpr( history_ls) stringp( left) stringp( right))
			printf( "ERROR: create_text() - Fail to get complete data on %s\n" type)
			printf( "\tDescription_1:%L\n\tDescription_2:%L\n\tPart Number:%L\n\tHistory:%L\n\tSheet: %L of %L\n" des1 des2 pn history_ls left right)
			return( nil)
		)
		
		;;; create description_1
		text_id = create_text_to_layer_Derek05222019( type des1 to_layer key_table[ _key_des1])
		when( text_id (text_ls = append1( text_ls text_id)))
		
		;;; create description_2
		text_id = create_text_to_layer_Derek05222019( type des2 to_layer key_table[ _key_des2])
		when( text_id (text_ls = append1( text_ls text_id)))
		
		;;; create part number
		text_id = create_text_to_layer_Derek05222019( type pn to_layer key_table[ _key_pn])
		when( text_id (text_ls = append1( text_ls text_id)))
		
		;;; create left of sheet
		text_id = create_text_to_layer_Derek05222019( type left to_layer key_table[ _key_left])
		when( text_id (text_ls = append1( text_ls text_id)))
		
		;;; create right of sheet
		text_id = create_text_to_layer_Derek05222019( type right to_layer key_table[ _key_right])
		when( text_id (text_ls = append1( text_ls text_id)))
		
		;;; create history
		row = 0
		while( (row < _history_max_row)
			cell_ls = nth( row history_ls)
			;;
			if( dtpr( cell_ls) then
				;;; create rev text
				text = nth( 0 cell_ls)
				sprintf( key _key_form_rev add1( row))
				text_id = create_text_to_layer_Derek05222019( type text to_layer key_table[ key])
				when( text_id (text_ls = append1( text_ls text_id)))
				
				;;; create layout text
				text = nth( 1 cell_ls)
				sprintf( key _key_form_layout add1( row))
				text_id = create_text_to_layer_Derek05222019( type text to_layer key_table[ key])
				when( text_id (text_ls = append1( text_ls text_id)))
				
				;;; create hardware text
				text = nth( 2 cell_ls)
				sprintf( key _key_form_hardware add1( row))
				text_id = create_text_to_layer_Derek05222019( type text to_layer key_table[ key])
				when( text_id (text_ls = append1( text_ls text_id)))
				
				;;; create date text
				text = nth( 3 cell_ls)
				sprintf( key _key_form_date add1( row))
				text_id = create_text_to_layer_Derek05222019( type text to_layer key_table[ key])
				when( text_id (text_ls = append1( text_ls text_id)))
				
				;;; create approved text
				text = nth( 4 cell_ls)
				sprintf( key _key_form_approved add1( row))
				text_id = create_text_to_layer_Derek05222019( type text to_layer key_table[ key])
				when( text_id (text_ls = append1( text_ls text_id)))
				
				;;;
				row++
			else
				row = _history_max_row
			)
		)
	
		;;; add to group
		unless( forall( x text_ls equal( "text" x->objType))
			printf( "ERROR: create_text() - text_ls contains non-text object: %L\n" text_ls~>objType)
			return( nil)
		)
		group_id = get_board_form_text_group_Derek05222019( )
		if( group_id
			axlDBAddGroupObjects( group_id text_ls)
			axlDBCreateGroup( _board_form_text_group "generic" text_ls)
		)
		
		return( t)
	)
)

procedure( setup_pcb_form_data_main_Derek05222019( )
	prog( ( msg cmd_ls pcb_data_ls panel_data_ls pcba_data_ls board_form_table key_table key_mirr_table key_len)
		unless( axlOKToProceed() println( "Warning: Please done the command before using this function") return( nil))
		unless(
			axlUIYesNo( "Please fill up the excel 'T:\\Layout\\SOP\\17. PCB_Form_Content\\Board_data_form.xlsx' before using this function. Do you want to keep continue?")
			return( nil)
		)
		cmd_ls = mapcar( 'cadr axlCmdList())
		unless( member( "manipulate_xlsx_main_Derek06122018" cmd_ls)
			println( "ArgErr: setup_pcb_form_data_main() - Please load manipulate_xlsx before using this function")
			return( nil)
		)
		
		;;;;; initial
		axlShell( "generaledit")
		init_Derek05222019()
		visible_ls = axlVisibleGet()
		
		;;;;; access the target xlsx
		when( isFile( _excel_table_name) deleteFile( _excel_table_name))
		msg = "Please select a 'board_data_form' xlsx file"
		manipulate_xlsx_main_Derek06122018( ?global_sheets _main_sheet_nm ?question_to_select msg)
		unless( isFile( _excel_table_name) printf( "ERROR: setup_pcb_form_data_main() - Fail to get file [%s]\n" _excel_table_name) return( nil))
		
		;;;;; read data from xlsx
		board_form_table = read_content_from_table_Derek05222019( )
		pcb_data_ls = get_content_from_table_Derek05222019( 'PCB_FAB board_form_table _pcb_header_start_row _pcb_history_start_row)
		panel_data_ls = get_content_from_table_Derek05222019( 'PANEL board_form_table _panel_header_start_row _panel_history_start_row)
		pcba_data_ls = get_content_from_table_Derek05222019( 'PCBA board_form_table _pcba_header_start_row _pcba_history_start_row)
		unless( and( dtpr( pcb_data_ls) dtpr( panel_data_ls) dtpr( pcba_data_ls))
			println( "ERROR: setup_pcb_form_data_main() - Fail to get essential data")
			return( nil)
		)
		
		;;;;; search and check the keys from [board geometry/board_form] and [board geometry/board_form_mirror]
		key_table = get_key_from_layer_Derek05222019( 'key _brd_frm_ky_ly)
		unless( tablep( key_table) println( "ERROR: Fail to get key_table") return( nil))
		key_ls = key_table->?
		unless( forall( x _form_key_ls member( x key_ls))
			printf( "ERROR: setup_pcb_form_data_main() - Fail to get enough keys from %s\n" _brd_frm_ky_ly)
			return( nil)
		)
		
		key_mirr_table = get_key_from_layer_Derek05222019( 'key_mirr _brd_frm_ky_mirr_ly)
		unless( tablep( key_mirr_table) println( "ERROR: Fail to get key_mirr_table") return( nil))
		key_ls = key_mirr_table->?
		unless( forall( x _form_key_ls member( x key_ls))
			printf( "ERROR: setup_pcb_form_data_main() - Fail to get enough mirrored keys from %s\n" _brd_frm_ky_mirr_ly)
			return( nil)
		)
		
		;;;;; remove exists board form content
		unless( clear_text_group_Derek05222019( ) return( nil))
		
		;;;;; create board form content
		create_text_Derek05222019( 'PCB_FAB pcb_data_ls key_table _sheet11 _pcb_fab_ly)
		create_text_Derek05222019( 'PANEL panel_data_ls key_table _sheet11 _panel_ly)
		create_text_Derek05222019( 'PCBA_TOP pcba_data_ls key_table _sheet12 _pcba_top_ly)
		create_text_Derek05222019( 'PCBA_BOT pcba_data_ls key_mirr_table _sheet22 _pcba_bot_ly)
		
		;;;;; restore visible
		axlVisibleSet( visible_ls)
		axlVisibleUpdate( t)
		
		;;;;; confirm finish
		axlUIConfirm( "'Setup PCB Form Data' process has been done. Please check this out")
		println( "'Setup PCB Form Data' process has been done. Please check this out")
	
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

axlCmdRegister( "setup_pcb_form_data" 'setup_pcb_form_data_main_Derek05222019)
; (load "manipulate_xlsx_v3.ile") ;;; wipped otu when release
; (setup_pcb_form_data_main_Derek05222019 )
; skill encrypt("c:/skill/setup_pcb_form_data_v1.il" "c:/skill/setup_pcb_form_data_v1.ile")
;; (load "setup_pcb_form_data_v1.ile")
;; (load "setup_pcb_form_data_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup