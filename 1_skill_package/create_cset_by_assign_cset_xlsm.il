;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 07/12/2019 - _Derek07122019
; purpose: create constraint by the xlsm developed by Wells
; Function:
;	1. you have to setup the Default constraint set correctly before using this function
;	2. The content of the constraint set is based on the naming rule of Flex TDC
;	3. only "" and "" will be obtain from the xlsm
; prerequest:
;	1. load the last manupulate_xlsx_v3
;	2. the stackup table. for getting neck mode
; detail
;	1. physical:
;		1. differential:
;			1. W5-4.75-4.5D8-9-6-Z85
;				line width(min/max):
;					outer: 5 mil
;					first inner from both top/bot: 4.75 mil
;					rest of inner: 4.5 mil
;				neck
;					min width: get the value from stackup table
;					max length: 500 mil
;				differential pair
;					min line spacing: get the value from stackup table
;					primary gap:
;						outer: 8 mil
;						first inner from both top/bot: 9 mil
;						rest of inner: 6 mil
;					neck gap: as same as min line spacing
;					tolerance(+/-): 0.1 mil
;		2. fake differential
;			1. W5-4.75-4.5D8-9-6-Z50
;				line width(min/max):
;					outer: 5 mil
;					first inner from both outer: 4.75 mil
;					rest of inner: 4.5 mil
;				neck
;					min width: 0 mil
;					max length: 0 mil
;				differential pair
;					min line spacing
;						outer: 8 mil
;						first inner from both top/bot: 9 mil
;						rest of inner: 6 mil
;					primary gap:
;						outer: 8 mil
;						first inner from both top/bot: 9 mil
;						rest of inner: 6 mil
;					neck gap: 0
;					tolerance(+/-): 0.1
;		3. single end
;			1. W4-3.5-3-Z50
;				line width(min/max):
;					outer: 4 mil
;					first inner from both outer: 3.5 mil
;					rest of inner: 3 mil
;		4. power
;			1. W16-P3V3
;				line width(min): 16 mil
;				line width(max): 0 mil
;		5. ground
;			1. W10-PLANE
;				line width(min): 10 mil
;				line width(max): 0 mil
;	2. spacing and same net spacing
;		1. S10:
;			outer: 10 mil
;			inner: 10 mil
;		2. S10-20
;			outer: 10 mil
;			inner: 20 mil
;				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek07122019()
	;;;; board file defined value
	setq( _allegro_path getWorkingDir())
	setq( _allegro_etch_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _allegro_etch_total axlGetParam( "paramLayerGroup:ETCH")->nChildren)
	setq( _conductor "CONDUCTOR")
	setq( _etch "ETCH")
	
	;;;; user defined value
	setq( _diffpair_toler "0.1")
	setq( _bbvia_stagger_min "5.0")
	setq( _bbvia_stagger_max "10000.0")
	setq( _default_neck_min_width "8.0")
	setq( _default_neck_max_length "500.0")
	
	setq( _allow_padconnect 'NOT_ALLOWED)
	setq( _allow_etch 'TRUE)
	setq( _allow_ts 'ANYTHERE)
	
	;;;; interaction with other program defined value
	setq( _table_filename "Excel_sheet[0].table")
	setq( _table_addr strcat( _allegro_path "/" _table_filename))
	
	;;;; Wells defined value
	setq( _diff "-DIFF")
	setq( _impedance_sheetname "Impedance")
	setq( _cset_start_col 'C)
	setq( _line_width_row 3)
	setq( _impedance_row 4)
	setq( _spacing_rows list( 5 6 7 8))
	setq( _phy_cset_form2 "%s_%s") ;; if change the term hereby, please make the program value is updated, too 
	
	;;;; stackup table defined value
	setq( _w "W")
	setq( _s "S")
	setq( _stackup_start_col 'K)
	setq( _stackup_start_row 3)
	
	;;;; program defined value
	setq( _physical 'physical)
	setq( _spacing 'spacing)
	setq( _same_net 'sameNet)
	setq( _line_line 'line_line)
	
	setq( _alphabet_total 26)
	setq( _alphabet_ls list( nil 'A 'B 'C 'D 'E 'F 'G 'H 'I 'J 'K 'L 'M 'N 'O 'P 'Q 'R 'S 'T 'U 'V 'W 'X 'Y 'Z))
	
	
	;;;;; init path
	result = t
	msg = "Please select the 'Assign class cset' xlsm file developed by Wells"
	result = manipulate_xlsx_main_Derek06122018( ?question_to_select msg
												?global_sheets _impedance_sheetname
												?non_csv t ?default_xlsm t ?row_limits 10)
	
	result
)

procedure( check_value_Derek07122019( err_type func_nm val_nm val type)
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
			( '_number
				result = numberp( val)
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
				;; 1 2 3 4 5 6 7 8 9
				result = or( and( integerp( val) (val > 0)) null( val))
			)
			( '_bool
				result = booleanp( val)
			)
			( '_symbol_or_string
				result = or( symbolp( val) stringp( val))
			)
			( '_symbol
				result = symbolp( val)
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
			( '_string_ls_or_string_or_nil
				result = or( null( val) stringp( val) and( dtpr( val) forall( x val stringp( x))))
			)
			( '_table_or_nil
				result = or( null( val) tablep( val))
			)
			( '_outport
				result = outportp( val)
			)
			( '_inport
				result = inportp( val)
			)
			( '_filename
				result = and( stringp( val) isFile( val))
			)
			( '_table
				result = tablep( val)
			)
			( '_alphabet
				when( or( symbolp( val) stringp( val))
					(result = rexMatchp( "[a-zA-Z]+" val))
				)
			)
			( t
				printf( "ERROR: check_value() - Yet to define type[%s] for value[%s] in function[%s]\n" type val_nm val_nm func_nm)
			)
		)
		
		unless( result printf( "%s: %s() - [%s] is not a %s\n" err_type func_nm val_nm type))
		
		return( result)
	)
)

procedure( get_number_by_alphabet_Derek07122019( word)
	prog( ( str_len left right result)
		unless( check_value_Derek07122019( 'ArgErr 'get_number_by_alphabet 'word word '_symbol_or_string) return( nil))
		;;
		
		when( symbolp( word) (word = symbolToString( word)))
		
		str_len = strlen( word)
		when( (str_len > 2) printf( "ArgErr: get_number_by_alphabet() - length of word[%s] has to be less equal than 2\n" word) return( nil))
		word = upperCase( word)
		
		if( onep( str_len) then
			result = listnindex( _alphabet_ls getchar( word 1))
		else
			left = listnindex( _alphabet_ls getchar( word 1))
			right = listnindex( _alphabet_ls getchar( word 2))
			result = left * _alphabet_total + right
		)
		
		return( result)
	)
)

procedure( get_alphabet_by_number_Derek07122019( number)
	prog( ( left right result)
		unless( and( plusp( number) integerp( number)) println( "ArgErr: get_alphabet_by_number() - Number is not a plus integer") return( nil))
		;;
		
		if( (number > _alphabet_total) then
			left = number / _alphabet_total
			right = remainder( number _alphabet_total)
			;;
			cond(
				( (left > _alphabet_total)
					printf( "ERROR: get_alphabet_by_number() - Fail to define number[%d]\n" number)
					return( nil)
				)
				( zerop( right)
					left = nth( --left _alphabet_ls)
					right = nth( _alphabet_total _alphabet_ls)
				)
				( t
					left = nth( left _alphabet_ls)
					right = nth( right _alphabet_ls)
				)
			)
			;;
			result = strcat( left right)
			result = stringToSymbol( result)
		else
			result = nth( number _alphabet_ls)
		)
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( read_table_Derek07122019( table_addr)
	prog( ( cell_table in_port csv_ls key val )
		unless( check_value_Derek07122019( 'ArgErr 'read_table 'table_addr table_addr '_filename) return( nil))
		in_port = infile( table_addr)
		unless( check_value_Derek07122019( 'ArgErr 'read_table 'in_port in_port '_inport) return( nil))
		;;
		
		cell_table = makeTable( "cell_table" nil)
		while( stringp( gets( csv_line in_port))
			csv_ls = axlStringCSVParse( csv_line ",")
			key = car( csv_ls)
			
			;;; extract the key name from [A1] to A1
			key = substring( key 2 (strlen( key) - 2))
			
			;;; merge the rest of content without key
			val = buildString( cdr( csv_ls) ",")
			;;
			when( stringp( val) (cell_table[ key] = val))
		)
		close( in_port)
		
		return( cell_table)
	)
)

procedure( get_value_in_row_by_table_Derek07122019( table row Start_col)
	prog( ( col key val pos result )
		unless( check_value_Derek07122019( 'ArgErr 'get_value_in_row_by_table 'table table '_table) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'get_value_in_row_by_table 'row row '_natural_number) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'get_value_in_row_by_table 'Start_col Start_col '_alphabet) return( nil))
		;;
		
		col = Start_col
		sprintf( key "%s%d" col row)
		while( (val = table[ key])
			result = append1( result val)
			;;
			pos = get_number_by_alphabet_Derek07122019( col)
			col = get_alphabet_by_number_Derek07122019( ++pos)
			sprintf( key "%s%d" col row)
		)
		
		return( result)
	)
)

procedure( get_value_in_col_by_table_Derek07122019( table start_row end_row col)
	prog( ( row key val result)
		unless( check_value_Derek07122019( 'ArgErr 'get_value_in_col_by_table 'table table '_table) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'get_value_in_col_by_table 'start_row start_row '_natural_number) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'get_value_in_col_by_table 'end_row end_row '_natural_number) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'get_value_in_col_by_table 'col col '_alphabet) return( nil))
		;;
		
		for( row start_row end_row
			sprintf( key "%s%d" col row)
			val = table[ key]
			result = append1( result val)
		)
		
		return( result)
	)
)

procedure( get_physical_cset_by_table_Derek07122019( cell_table)
	prog( ( line_width_name_ls impedance_name_ls phy_cset_ls)
		unless( check_value_Derek07122019( 'ArgErr 'get_physical_cset_by_table 'cell_table cell_table '_table) return( nil))
		;;
		
		line_width_name_ls = get_value_in_row_by_table_Derek07122019( cell_table _line_width_row _cset_start_col)
		impedance_name_ls = get_value_in_row_by_table_Derek07122019( cell_table _impedance_row _cset_start_col)
		unless( eqv( length( line_width_name_ls) length( impedance_name_ls))
			println( "ERROR: get_physical_cset_by_table() - Number of line_width and impedance is not equal. Please check this out")
			printf( "\tline width: %L\n\tImpedance: %L\n" line_width_name_ls impedance_name_ls)
			return( nil)
		)
		
		phy_cset_ls = mapcar( lambda( (a b) sprintf( nil _phy_cset_form2 a b)) line_width_name_ls impedance_name_ls)
		
		;;;; remove duplicate name
		phy_cset_ls = mapcar( 'upperCase phy_cset_ls)
		phy_cset_ls = maplist( lambda( (x) if( member( car( x) cdr( x)) nil car( x))) phy_cset_ls)
		phy_cset_ls = remq( nil phy_cset_ls)
		
		return( phy_cset_ls)
	)
)

procedure( get_spacing_cset_table_Derek07122019( cell_table)
	prog( ( row cell_ls spc_cset_ls)
		unless( check_value_Derek07122019( 'ArgErr 'get_spacing_cset_table 'cell_table cell_table '_table) return( nil))
		;;
		
		foreach( row _spacing_rows
			cell_ls = get_value_in_row_by_table_Derek07122019( cell_table row _cset_start_col)
			spc_cset_ls = append( spc_cset_ls cell_ls)
		)
		
		;;;; remove duplicate name
		spc_cset_ls = mapcar( 'upperCase spc_cset_ls)
		spc_cset_ls = maplist( lambda( (x) if( member( car( x) cdr( x)) nil car( x))) spc_cset_ls)
		spc_cset_ls = remq( nil spc_cset_ls)
		
		
		return( spc_cset_ls)
	)
)

procedure( get_end_col_by_table_Derek07122019( cell_table)
	prog( ( key_ls col_ls col_num_ls end_col)
		unless( check_value_Derek07122019( 'ArgErr 'get_end_col_by_table 'cell_table cell_table '_table) return( nil))
		;;
		
		key_ls = cell_table->?
		
		rexCompile( "\\([A-Z]+\\)")
		col_ls = mapcar( lambda( (x) when( rexExecute( x) rexSubstitute( "\\1"))) key_ls)
		when( exists( x col_ls null(x))
			printf( "ERROR: get_end_col_by_table() - Fail to find all column in address \n\t Cells: %L \n\t Cols: %L\n" key_ls col_ls)
			return( nil)
		)
		
		col_num_ls = mapcar( lambda( (x) get_number_by_alphabet_Derek07122019( x)) col_ls)
		col_num_ls = sort( col_num_ls 'greaterp)
		
		end_col = car( col_num_ls)
		end_col = get_alphabet_by_number_Derek07122019( end_col)
		
		
		return( end_col)
	)
)

procedure( get_end_row_by_table_Derek07122019( cell_table)
	prog( ( end_row)
		unless( check_value_Derek07122019( 'ArgErr 'get_end_row_by_table 'cell_table cell_table '_table) return( nil))
		;;
		
		;;; _stackup_start_row: the row of ohm
		;;; 2: sub-title and a dielectric
		;;; n*2: cppoer with a dielectric
		;;; 1: dielectric under bottom
		end_row = _stackup_start_row + 2 + _allegro_etch_total * 2 + 1
		
		return( end_row)
	)
)

procedure( get_ohm_wsws_util_Derek07122019( cell_table)
	prog( ( start_col_num end_col end_col_num start_row end_row col cell_ls ext_ls ext_total col_num
			w_ls s_ls ohm ws_ls content_1 content_2 ohm_wsws_ls ohm_wsws_table)
		unless( check_value_Derek07122019( 'ArgErr 'get_ohm_wsws_util 'cell_table cell_table '_table) return( nil))
		;;
		
		;;;
		start_col_num = get_number_by_alphabet_Derek07122019( _stackup_start_col)
		end_col = get_end_col_by_table_Derek07122019( cell_table)
		end_col_num = get_number_by_alphabet_Derek07122019( end_col)
		
		;;;
		start_row = _stackup_start_row
		end_row = get_end_row_by_table_Derek07122019( cell_table)
		
		unless( and( numberp( start_col_num) numberp( end_col_num) numberp( start_row) numberp( end_row))
			println( "Info: get_ohm_wsws_util() - Fail to get the range of extension")
			printf( "\tStart Col Number: %d \n\t End Col Number: %d \n\t Start Row: %d \n\t End Row: %d\n"
						start_col_num end_col_num start_row end_row)
		)
		
		;;;
		for( col_num start_col_num end_col_num
			col = get_alphabet_by_number_Derek07122019( col_num)
			
			cell_ls = get_value_in_col_by_table_Derek07122019( cell_table start_row end_row col)
			cell_ls = remq( nil cell_ls)
			cell_ls = mapcar( 'upperCase cell_ls)
			ext_ls = append1( ext_ls cell_ls)
		)
		
		;;; get main routing and breakout block by block
		rexCompile( "\\([0-9]+\\)")
		ext_total = sub1( length( ext_ls))
		for( col_num 0 ext_total
			;;;; get the current col and the next col and find out the Width/Spacing
			w_ls = nth( col_num ext_ls)
			s_ls = nth( add1( col_num) ext_ls)
			
			;;;; get the w/s key in column
			w_key = car( member( _w w_ls))
			s_key = car( member( _s s_ls))
			
			;;; get single end
			when( and( stringp( w_key) not( stringp( s_key)))
				ohm = car( w_ls)
				if( rexExecute( ohm) then
					ohm = rexSubstitute( "\\1")
					w_ls = cdr( member( _w w_ls))
					ws_ls = mapcar( lambda( (x) list( x nil)) w_ls)
					;;
					content = list( ohm ws_ls)
					ohm_wsws_ls = append1( ohm_wsws_ls content)
				else
					printf( "Warning: get_ohm_wsws_util() - Fail to get Single End ohm on [%s]\n" w_key)
				)
			)
			
			;;; get differential data
			when( and( stringp( w_key) stringp( s_key))
				ohm = car( w_ls)
				if( rexExecute( ohm) then
					ohm = rexSubstitute( "\\1")
					w_ls = cdr( member( _w w_ls))
					s_ls = cdr( member( _s s_ls))
					;;
					ws_ls = mapcar( lambda( (a b) list( a b)) w_ls s_ls)
					content = list( ohm ws_ls)
					ohm_wsws_ls = append1( ohm_wsws_ls content)
				else
					printf( "Warning: get_ohm_wsws_util() - Fail to get Differential ohm on [%s]\n" w_key)
				)
			)
		)
		
		;;; merge breakout( neck mode) to main routing
		total = length( ohm_wsws_ls) - 1
		taken = nil
		ohm_wsws_table = makeTable( "ohm_wsws" nil)
		for( th 0 total
			if( taken then
				taken = nil
			else
				content_1 = nth( th ohm_wsws_ls)
				content_2 = nth( add1( th) ohm_wsws_ls)
				
				ohm_1 = car( content_1)
				ohm_2 = car( content_2)
				
				ws1_ls = cadr( content_1)
				ws2_ls = cadr( content_2)
				
				if( equal( ohm_1 ohm_2) then
					content = list( ws1_ls ws2_ls)
					ohm_wsws_table[ ohm_1] = content
					taken = t
				else
					content = list( ws1_ls nil)
					ohm_wsws_table[ ohm_1] = content
				)
			)
		)
		
		;;;; print
		foreach( ohm ohm_wsws_table
			wsws = ohm_wsws_table[ ohm]
			ws1_ls = car( wsws)
			ws2_ls = cadr( wsws)
			printf( "Info: get_ohm_wsws_util() - ohm[%s] (W/S) \n\t Main Routing: %L \n\t Break Out: %L\n" ohm ws1_ls ws2_ls)
		)
		
		return( ohm_wsws_table)
	)
)

procedure( check_conductor_subclass_Derek07122019( ohm_wsws_table)
	prog( ( wsws xsect_ls conductor_ls conductor_total result ohm main_routing_ls main_routing_total )
		unless( check_value_Derek07122019( 'ArgErr 'check_conductor_subclass 'ohm_wsws_table ohm_wsws_table '_table) return( nil))
		;;
		
		xsect_ls = axlGetXSection()
		conductor_ls = setof( x xsect_ls equal( _conductor cadr( x)))
		conductor_total = length( conductor_ls)
		
		result = t
		foreach( ohm ohm_wsws_table
			wsws = ohm_wsws_table[ ohm]
			main_routing_ls = car( wsws)
			main_routing_total = length( main_routing_ls)
			unless( eqv( conductor_total main_routing_total)
				printf( "Info: check_conductor_subclass() - Mismatch amound of conductor layer.\tOhm[%s]\tBrd[%d]\tStackup[%d]\n"
						ohm conductor_total main_routing_total)
				result = nil
			)
		)
		
		return( result)
	)
)

procedure( get_number_after_char_Derek07122019( word char)
	prog( ( rex_pattern result)
		unless( check_value_Derek07122019( 'ArgErr 'get_number_after_char 'word word '_string) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'get_number_after_char 'char char '_string) return( nil))
		;;
		
		sprintf( rex_pattern "%s\\([0-9]+\\)" char)
		rexCompile( rex_pattern)
		if( rexExecute( word)
			result = rexSubstitute( "\\1")
			printf( "Warning: get_number_after_char() - Fail to get number from [%s] after [%s]\n" word char)
		)
		
		return( result)
	)
)

procedure( merge_data_to_xsect_Derek07122019( data_ls @optional (default_value "0"))
	prog( ( data_cnt subclass layer type data result)
		unless( check_value_Derek07122019( 'ArgErr 'merge_data_to_xsect 'data_ls data_ls '_string_ls_or_string_or_nil) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'merge_data_to_xsect 'default_value default_value '_string) return( nil))
		;;
		
		cond(
			( dtpr( data_ls)
				data_cnt = 0
				foreach( subclass _allegro_etch_ls
					layer = strcat( _etch "/" subclass)
					type = axlDBGetLayerType( layer)
					;;
					data = if( equal( _conductor type) nth( data_cnt++ data_ls) default_value)
					result = append1( result data)
				)
			)
			( stringp( data_ls)
				data = data_ls
				result = mapcar( lambda( (x) data) _allegro_etch_ls)
			)
			( t
				result = mapcar( lambda( (x) default_value) _allegro_etch_ls)
			)
		)
		
		return( result)
	)
)

procedure( create_phy_cset_with_xsect_Derek07122019( phy_cset_ls ohm_wsws_table)
	;;; format of result ( phy_cset_name ( (line_width_min_ls) (neck_min_width_ls) (neck_gap_ls) (primary_gap_ls)))
	;;; diffpair: neck_gap is as same as min_line_spacing
	;;; toler(+/-) are always 0.1 mil
	;;; line width min/max are always the same
	;;; neck: max_length is always 500 mil
	prog( ( phy_cset_data_table default_ls phy_cset line_width_min_ls line_width_max_ls primary_gap_ls
			neck_min_width_ls neck_max_length_ls neck_gap_ls min_line_spc_ls impedance
			line_width primary_gap wsws w_ls s_ls ws_ls content is_diff)
		unless( check_value_Derek07122019( 'ArgErr 'create_phy_cset_with_xsect 'phy_cset_ls phy_cset_ls '_dtpr) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'create_phy_cset_with_xsect 'ohm_wsws_table ohm_wsws_table '_table) return( nil))
		;;
		
		;;;
		phy_cset_data_table = makeTable( "phy_cset_data" nil)
		default_ls = merge_data_to_xsect_Derek07122019( nil)
		
		;;;
		foreach( phy_cset phy_cset_ls
			line_width_min_ls = line_width_max_ls = primary_gap_ls = neck_min_width_ls = nil
			neck_max_length_ls = neck_gap_ls = min_line_spc_ls = nil
			impedance = get_number_after_char_Derek07122019( phy_cset "_Z")
			line_width = get_number_after_char_Derek07122019( phy_cset "^W")
			
			;;;; the gap for differential defined by single end
			primary_gap = get_number_after_char_Derek07122019( phy_cset "D")
			
			;;;; enforce using the value in the physical name
			is_diff = stringp( index( phy_cset _diff))
			
			;;
			cond(
				( and( stringp( impedance) not( is_diff))
					;;; a general cset with impedance, like W4-3.5-4_Z50, W5-4.75-4.75D8-9-6_Z85
					wsws = ohm_wsws_table[ impedance]
					
					;;;; part for main routing
					ws_ls = car( wsws)
					w_ls = mapcar( 'car ws_ls)
					s_ls = mapcar( 'cadr ws_ls)
					;;
					when( forall( x w_ls null( x)) (w_ls = nil))
					when( forall( x s_ls null( x)) (s_ls = nil))
					;;
					line_width_min_ls = merge_data_to_xsect_Derek07122019( w_ls)
					line_width_max_ls = merge_data_to_xsect_Derek07122019( w_ls)
					;;;;
					cond(
						( dtpr( s_ls) (primary_gap_ls = merge_data_to_xsect_Derek07122019( s_ls)))
						( stringp( primary_gap) (primary_gap_ls = merge_data_to_xsect_Derek07122019( primary_gap)))
						( t (primary_gap_ls = default_ls))
					)
					
					;;;; part for neck mode
					ws_ls = cadr( wsws)
					w_ls = mapcar( 'car ws_ls)
					s_ls = mapcar( 'cadr ws_ls)
					;;
					when( forall( x w_ls null( x)) (w_ls = nil))
					when( forall( x s_ls null( x)) (s_ls = nil))
					;;
					neck_min_width_ls = merge_data_to_xsect_Derek07122019( w_ls)
					if( dtpr( w_ls)
						neck_max_length_ls = merge_data_to_xsect_Derek07122019( _default_neck_max_length)
						neck_max_length_ls = default_ls
					)
					;;
					neck_gap_ls = merge_data_to_xsect_Derek07122019( s_ls)
					min_line_spc_ls = if( dtpr( s_ls) neck_gap_ls primary_gap_ls)
				)
				( stringp( line_width)
					;;; a plane cset, like W16_PWR16, W10_PLANE
					line_width_min_ls = merge_data_to_xsect_Derek07122019( line_width)
					line_width_max_ls = default_ls
					if( stringp( primary_gap) then
						primary_gap_ls = merge_data_to_xsect_Derek07122019( primary_gap)
						min_line_spc_ls = primary_gap_ls
					else
						primary_gap_ls = default_ls
						min_line_spc_ls = default_ls
					)
					neck_min_width_ls = merge_data_to_xsect_Derek07122019( _default_neck_min_width)
					neck_max_length_ls = merge_data_to_xsect_Derek07122019( _default_neck_max_length)
					neck_gap_ls = default_ls
				)
				( t
					printf( "Warning: create_phy_cset_with_xsect() - Fail to get line_width or impedance from phy_cset[%s]\n" phy_cset)
				)
			)
			
			if( and( dtpr( line_width_min_ls) dtpr( line_width_max_ls) dtpr( neck_min_width_ls) dtpr( neck_max_length_ls)
					dtpr( min_line_spc_ls) dtpr( primary_gap_ls) dtpr( neck_gap_ls)) then
				content = list( line_width_min_ls line_width_max_ls neck_min_width_ls neck_max_length_ls
								min_line_spc_ls primary_gap_ls neck_gap_ls)
				phy_cset_data_table[ phy_cset] = content
			else
				printf( " - Warning: create_phy_cset_with_xsect() - Fail to merge xlsm data with xsection \n\t Physical cset: %s\n" phy_cset)
				printf( "\t [Line width] min: %L \n\t [Line width] max: %L \n\t [Neck] min width: %L \n\t [Neck] max length: %L\n"
						line_width_min_ls line_width_max_ls neck_min_width_ls neck_max_length_ls)
				printf( "\t [Diffpair] Min line spacing: %L \n\t [Diffpair] Primary gap: %L \n\t [Diffpair] Neck gap: %L\n"
						min_line_spc_ls primary_gap_ls neck_gap_ls)
			)
		)
		
		;;;
		foreach( phy_cset phy_cset_data_table
			content = phy_cset_data_table[ phy_cset]
			line_width_min_ls = nth( 0 content)
			line_width_max_ls = nth( 1 content)
			neck_min_width_ls = nth( 2 content)
			neck_max_length_ls = nth( 3 content)
			min_line_spc_ls = nth( 4 content)
			primary_gap_ls = nth( 5 content)
			neck_gap_ls = nth( 6 content)
			;;
			printf( " - Info: create_phy_cset_with_xsect() \n\t Physical cset: %s\n" phy_cset)
			printf( "\t [Line width] min: %L \n\t [Line width] max: %L \n\t [Neck] min width: %L \n\t [Neck] max length: %L\n"
					line_width_min_ls line_width_max_ls neck_min_width_ls neck_max_length_ls)
			printf( "\t [Diffpair] Min line spacing: %L \n\t [Diffpair] Primary gap: %L \n\t [Diffpair] Neck gap: %L\n"
					min_line_spc_ls primary_gap_ls neck_gap_ls)
		)
		
		
		return( phy_cset_data_table)
	)
)

procedure( import_phy_cset_Derek07122019( phy_cset_data_table)
	prog( ( total phy_cset content line_width_min_ls line_width_max_ls neck_min_width_ls neck_max_length_ls min_line_spc_ls
			primary_gap_ls neck_gap_ls subclass_num subclass line_width_min line_width_max neck_min_width neck_max_length
			min_line_spc primary_gap neck_gap result)
		unless( check_value_Derek07122019( 'ArgErr 'import_phy_cset 'phy_cset_data_table phy_cset_data_table '_table) return( nil))
		;;
		
		total = sub1( _allegro_etch_total)
		foreach( phy_cset phy_cset_data_table
			content = phy_cset_data_table[ phy_cset]
			line_width_min_ls = nth( 0 content)
			line_width_max_ls = nth( 1 content)
			neck_min_width_ls = nth( 2 content)
			neck_max_length_ls = nth( 3 content)
			min_line_spc_ls = nth( 4 content)
			primary_gap_ls = nth( 5 content)
			neck_gap_ls = nth( 6 content)
			
			;;
			result = axlCNSCreate( _physical phy_cset nil)
			if( result
				printf( " - Info: import_phy_cset() - Successful to create [%s] in [%s] constraint. Start importing\n" phy_cset _physical)
				printf( " - Info: import_phy_cset() - [%s] is exists in [%s] constraint. Start importing\n" phy_cset _physical)
			)
			
			;;
			for( subclass_num 0 total
				subclass = nth( subclass_num _allegro_etch_ls)
				line_width_min = nth( subclass_num line_width_min_ls)
				line_width_max = nth( subclass_num line_width_max_ls)
				neck_min_width = nth( subclass_num neck_min_width_ls)
				neck_max_length = nth( subclass_num neck_max_length_ls)
				min_line_spc = nth( subclass_num min_line_spc_ls)
				primary_gap = nth( subclass_num primary_gap_ls)
				neck_gap = nth( subclass_num neck_gap_ls)
				;;
				content = list( list( 'width_min line_width_min)
								list( 'width_max line_width_max)
								list( 'neckwidth_min neck_min_width)
								list( 'necklength_max neck_max_length)
								list( 'dp_min_gap min_line_spc)
								list( 'dp_primary_gap primary_gap)
								list( 'dp_neck_gap neck_gap)
								list( 'dp_coupled_plus _diffpair_toler)
								list( 'dp_coupled_minus _diffpair_toler)
								list( 'bbvia_stagger_min _bbvia_stagger_min)
								list( 'bbvia_stagger_max _bbvia_stagger_max)
								list( 'allow_padconnect _allow_padconnect)
								list( 'allow_etch _allow_etch)
								list( 'allow_ts _allow_ts))
				axlCNSSetPhysical( phy_cset subclass content nil)
			)
		)
		
		;;;
		axlCNSMapUpdate()
		
		return( t)
	)
)

procedure( create_spc_cset_with_xsect_Derek07122019( spc_cset_ls)
	prog( ( spc_cset_data_table spc_cset outer_spacing inner_spacing spacing_ls content type spacing_ls)
		unless( check_value_Derek07122019( 'ArgErr 'create_spc_cset_with_xsect 'spc_cset_ls spc_cset_ls '_dtpr) return( nil))
		;;
		
		spc_cset_data_table = makeTable( "spc_cset_data" nil)
		
		foreach( spc_cset spc_cset_ls
			outer_spacing = get_number_after_char_Derek07122019( spc_cset "^S")
			inner_spacing = get_number_after_char_Derek07122019( spc_cset "-")
			unless( inner_spacing (inner_spacing = outer_spacing))
			;;
			spacing_ls = merge_data_to_xsect_Derek07122019( inner_spacing)
			spacing_ls = setcar( spacing_ls outer_spacing)
			spacing_ls = reverse( setcar( reverse( spacing_ls) outer_spacing))
			;;
			content = list( _line_line spacing_ls)
			spc_cset_data_table[ spc_cset] = content
		)
		
		;;; output the result
		foreach( spc_cset spc_cset_data_table
			content = spc_cset_data_table[ spc_cset]
			type = car( content)
			spacing_ls = cadr( content)
			;;
			printf( " - Info: create_spc_cset_with_xsect() \n\t Spacing cset: %s \n\t Type: %s \n\t Spacing: %L\n" spc_cset type spacing_ls)
		)
		
		return( spc_cset_data_table)
	)
)

procedure( import_spc_cset_Derek07122019( spc_cset_data_table domain)
	prog( ( spacing_func total spc_cset content type spacing_ls subclass_num subclass spacing result)
		unless( check_value_Derek07122019( 'ArgErr 'import_spc_cset 'spc_cset_data_table spc_cset_data_table '_table) return( nil))
		unless( check_value_Derek07122019( 'ArgErr 'import_spc_cset 'domain domain '_symbol) return( nil))
		;;
		
		cond(
			( eq( _spacing domain) (spacing_func = 'axlCNSSetSpacing))
			( eq( _same_net domain) (spacing_func = 'axlCNSSetSameNet))
			( t
				printf( "ERROR: import_spc_cset() - Yet to define cset domain [%s]\n" domain)
				return( nil)
			)
		)
		
		total = sub1( _allegro_etch_total)
		foreach( spc_cset spc_cset_data_table
			content = spc_cset_data_table[ spc_cset]
			type = car( content)
			spacing_ls = cadr( content)
			
			;;
			result = axlCNSCreate( domain spc_cset nil)
			if( result
				printf( " - Info: import_spc_cset() - Successful to create [%s] in [%s] constraint. Start importing\n" spc_cset domain)
				printf( " - Info: import_spc_cset() - [%s] is exists in [%s] constraint. Start importing\n" spc_cset domain)
			)
			
			;;
			for( subclass_num 0 total
				subclass = nth( subclass_num _allegro_etch_ls)
				spacing = nth( subclass_num spacing_ls)
				;;
				funcall( spacing_func spc_cset subclass type spacing)
			)
		)
				
		;;;
		axlCNSMapUpdate()
		
		return( t)
	)
)

procedure( create_cset_by_Assign_Cset_xlsm_Derek07122019()
	prog( ( result cell_table phy_cset_ls spc_cset_ls msg ohm_wsws_table phy_cset_data_table spc_cset_data_table )
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		unless( isCallable( 'manipulate_xlsx_main_Derek06122018)
			println( "ERROR: Fail to call 'manipulate_xlsx' function. Please import it first") return( nil))
		;;
		
		axlShell( "generalEdit")
		
		result = init_Derek07122019()
		unless( result return( nil))
		
		;;;;;
		cell_table = read_table_Derek07122019( _table_addr)
		unless( tablep( cell_table) return( nil))
		
		;;;;; get physical constraint
		phy_cset_ls = get_physical_cset_by_table_Derek07122019( cell_table)
		printf( "\nInfo: create_cset_by_Wells_xlsm_main() - To be created physical cset\n\t%L\n" phy_cset_ls)
		
		;;;;; get spacing and same net spacing
		spc_cset_ls = get_spacing_cset_table_Derek07122019( cell_table)
		printf( "\nInfo: create_cset_by_Wells_xlsm_main() - To be created spacing & same net spacing cset\n\t%L\n" spc_cset_ls)
		
		;;;;; get neck mode value
		when( dtpr( phy_cset_ls)
			msg = "Please select a target stack-up table"
			result = manipulate_xlsx_main_Derek06122018( ?question_to_select msg ?non_csv t)
			unless( result return( nil))
			;;
			cell_table = read_table_Derek07122019( _table_addr)
			when( tablep( cell_table)
				ohm_wsws_table = get_ohm_wsws_util_Derek07122019( cell_table)
			)
		)
		
		result = check_conductor_subclass_Derek07122019( ohm_wsws_table)
		unless( result return( nil))
		
		;;;;; create cset with xsection
		phy_cset_data_table = create_phy_cset_with_xsect_Derek07122019( phy_cset_ls ohm_wsws_table)
		spc_cset_data_table = create_spc_cset_with_xsect_Derek07122019( spc_cset_ls)
		
		;;;;; import cset
		import_phy_cset_Derek07122019( phy_cset_data_table)
		import_spc_cset_Derek07122019( spc_cset_data_table _spacing)
		import_spc_cset_Derek07122019( spc_cset_data_table _same_net)

		;;;;;
		msg = "Process 'create cset by Wells xlsm and stackup table' is done. Please check your constraint manager"
		axlUIConfirm( msg)
		println( msg)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

; (load "manipulate_xlsx_v3.il")
(axlCmdRegister "create_cset_by_Assign_Cset_xlsm" 'create_cset_by_Assign_Cset_xlsm_Derek07122019)
; (create_cset_by_Assign_Cset_xlsm_Derek07122019)
; skill (encrypt "c:/skill/create_cset_by_Assign_Cset_xlsm_v1.il" "c:/skill/create_cset_by_Assign_Cset_xlsm_v1.ile")
; (load "create_cset_by_Assign_Cset_xlsm_v1.ile")
; (load "create_cset_by_Assign_Cset_xlsm_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup