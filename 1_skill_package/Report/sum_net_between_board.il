;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 5/6/2021 - _Derek05062010
; Introduction
; input:
;	1. using xlsx
;	2. may import more than 1 page
;	3. for each sheet
;		1. 2 boards should be present on column B,C on row 1
;		2. start from row 2,
;			1. column B,C: a refdes on the board defined at its top of the same column
; output:
;	1. seperate the result by sheetname.csv
;	2. date:
;		1. header: refdes.pin_number,pin_number,board_name1,,,,refdes.pin_number,board_name2,,,,total
;		2. data: <refdes.pin_number>,net_name,net_length,net_name,net_length, <refdes.pin_number>,net_name,net_length,net_name,net_length, total
; process:
;	1. import sum_net_between_board.xlsx
;	2. collect all board its refdes
;	3. open allegro and save data by sheet by 2 boards
;	4. merge 2 boards in each sheet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek05062010()
	setq( _allegro_path getWorkingDir())
	
	setq( _out_csvname_form "%s.csv")
	
	setq( _sheet_ls nil)
	setq( _csvname_ls nil)
	setq( _out_csvname_ls nil)
	
	defstruct( sum_struct fileterm refdes_ls brd_addr)
	defstruct( sheet_struct fileterm1 refdes1_ls fileterm2 refdes2_ls out_filename)
	defstruct( map_struct fileterm refdes pin_number net_name1 net_len1 net_name2 net_len2)
	defstruct( merge_struct map1 map2 total)
	defstruct( out_struct out_filename dataset_ls)
	defstruct( length_struct net_len pin_delay via_z_len)
	
	setq( _sheet_table makeTable( 'sheet nil))
	setq( _sum_table makeTable( 'sum nil))
	
	sprintf( _out_filename_form "%s/%%s.csv" _allegro_path)
	
	;;;;; filename
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _out_filename "sum_net_between_board-%s.csv" _date_time)
	sprintf( _out_fileaddr "%s/%s" _allegro_path _out_filename)
)

procedure( get_csvname_Derek05062010( form value)
	prog( ( csvname csv_addr)
		sprintf( csvname form value)
		csv_addr = strcat( _allegro_path "/" csvname)
		
		return( csv_addr)
	)
)

procedure( get_csvnames_Derek05062010()
	prog( ( tota csv_addr csvname_ls)
		total = length( _sheet_ls) - 1
		
		for( i 0 total
			csv_addr = get_csvname_Derek05062010( _excel_csv_form i)
			csvname_ls = append1( csvname_ls csv_addr)
		)
		
		return( csvname_ls)
	)
)

procedure( init_config_Derek05062010()
	prog( ( question )
		question = "Please complete sym_net_between_board.xlsx before selecting this file"
		manipulate_xlsx_main_Derek06122018( ?global_sheets "" ?non_table t ?question_to_select question)
		
		_sheet_ls = _sheetname_ls
		if( zerop( length( _sheet_ls)) then
			printf( "ERROR: init_config() - Fail to get sheetnames from the selected excel")
			return( nil)
		else
			printf( "INFO: init_config() - All sheet in the selected excel: %L\n" _sheet_ls)
		)
		
		_csvname_ls = get_csvnames_Derek05062010()
		printf( "INFO: init_config() - Created csv file: %L\n" _csvname_ls)
		
		_out_csvname_ls = mapcar( lambda( (x) get_csvname_Derek05062010( _out_csvname_form x)) _sheet_ls)
		printf( "INFO: init_config() - To-be-created csv file: %L\n" _out_csvname_ls)
		
		return( t)
	)
)

procedure( init_table_Derek05062010()
	prog( ( result)
		;;;; init the data from excel
		result = init_config_Derek05062010()
		unless( result
			return( nil)
		)
		
		_sheet_table = get_sheet_table_Derek05062010()
		unless( _sheet_table
			printf( "ERROR: sum_net_between_board_main_Derek05062010() - Fail to get data from exported CSV files")
			return( nil)
		)
		 
		_sum_table = get_sum_table_Derek05062010()
		unless( _sum_table
			printf( "ERROR: No data is defined to be exported from board file")
			return( nil)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( read_csv_Derek05062010( filename sheetname)
	prog( ( in_port is_first parts fileterm1 fileterm2 sheet_stru refdes1_ls refdes2_ls)
		in_port = infile( filename)
		unless( inportp( in_port)
			printf( "ERROR: read_csv() - Fail to read file\n")
			return( nil)
		)
		
		gets( line in_port)
		parts = axlStringCSVParse( line t)
		fileterm1 = car( parts)
		fileterm2 = cadr( parts)
		sheet_stru = make_sheet_struct( ?fileterm1 fileterm1 ?fileterm2 fileterm2)
		
		while( gets( line in_port)
			parts = axlStringCSVParse( line t)
			refdes1_ls = car( parts)
			refdes2_ls = cadr( parts)
			
			sheet_stru->refdes1_ls = append1( sheet_stru->refdes1_ls refdes1_ls)
			sheet_stru->refdes2_ls = append1( sheet_stru->refdes2_ls refdes2_ls)
		)
		
		close( in_port)
		
		sprintf( out_filename _out_filename_form sheetname)
		sheet_stru->out_filename = out_filename
		
		return( sheet_stru)
	)
)

procedure( get_sheet_table_Derek05062010()
	prog( ( sheet_table total csvname sheetname sheet_stru)
		sheet_table = makeTable( 'sheet nil)
		
		total = length( _csvname_ls) - 1
		for( i 0 total
			csvname = nth( i _csvname_ls)
			sheetname = nth( i _sheet_ls)
			
			sheet_stru = read_csv_Derek05062010( csvname sheetname)
			
			sheet_table[ sheetname] = sheet_stru
		)
		
		return( sheet_table)
	)
)

procedure( update_sum_table_Derek05062010( sum_table fileterm refdes_ls)
	prog( ( sum_stru )
		if( member( fileterm sum_table->?) then
			sum_stru = sum_table[ fileterm]
			sum_stru->refdes_ls = append( sum_stru->refdes_ls refdes_ls)
		else
			sum_stru = make_sum_struct( ?fileterm fileterm ?refdes_ls refdes_ls)
		)
		
		sum_table[ fileterm] = sum_stru
		
		return( sum_table)
	)
)

procedure( get_sum_table_Derek05062010()
	prog( ( sum_table)
		unless( _sheet_table return( nil))
		
		sum_table = makeTable( 'sum nil)
		
		foreach( sheetname _sheet_table
			sheet_stru = _sheet_table[ sheetname]
			
			sum_table = update_sum_table_Derek05062010( sum_table sheet_stru->fileterm1 sheet_stru->refdes1_ls)
			sum_table = update_sum_table_Derek05062010( sum_table sheet_stru->fileterm2 sheet_stru->refdes2_ls)
		)
		
		return( sum_table)
	)
)

procedure( select_board_Derek05062010( fileterm)
	prog( ( title file_addr)
		sprintf( title "Please open a board file of [%s]" fileterm)
		file_addr = axlDMFileBrowse( "ALLEGRO_LAYOUT_DB" nil ?title title)
		
		return( file_addr)
	)
)

procedure( set_boards_addr_Derek05062010()
	prog( ( brd_addr sum_stru)
		foreach( fileterm _sum_table
			brd_addr = select_board_Derek05062010( fileterm)
			unless( stringp( brd_addr)
				return( nil)
			)
			
			unless( isFile( brd_addr)
				return( nil)
			)
			
			sum_stru = _sum_table[ fileterm]
			sum_stru->brd_addr = brd_addr
			_sum_table[fileterm] = sum_stru
		)
		
		return( t)
	)
)

procedure( open_brd_Derek05062010( brd_addr)
	prog( ( result)
		when( axlGetDrawingName() == brd_addr
			return( t)
		)
		
		result = axlOpenDesign( ?design brd_addr ?mode "wl" ?ignoreLock t)
		unless( result
			printf( "ERROR: open_brd() - Fail to open brd file: %L\n" brd_addr)
			return( nil)
		)
		
		axlUIConfirm( "Switching to another board. Please press OK to continue")
		
		return( t)
	)
)

procedure( is_passive_Derek05062010( sym_id)
	prog( ( pin_ls result)
		pin_ls = sym_id->pins
		pin_ls = setof( x pin_ls x->number != "")
		pin_ls = setof( x pin_ls !x->isThrough)
		pin_ls = setof( x pin_ls x->definition->plating == "PLATED")
		
		result = length( pin_ls) == 2
		
		return( result)
	)
)

procedure( get_another_net_Derek05062010( net_id)
	prog( ( pin_ls passive_pin_id another_net_id)
		pin_ls = axlPinsOfNet( net_id 'pin)
		passive_pin_id = car( setof( x pin_ls is_passive_Derek05062010( x->parent)))
		another_net_id = car( remq( passive_pin_id passive_pin_id->parent->pins))->net
		
		return( another_net_id)
	)
)

procedure( get_2net_Derek05062010( net_id)
	; net_id = car( axlGetSelSet())
	prog( ( net_2 another_net_id )
		
		unless( net_id
			return( nil)
		)
		
		when( net_id->xnet->groupMembers
			net_2 = net_id->xnet->groupMembers
			
			if( length( net_2) == 2 then
				return( net_2)
			else
				return( nil)
			)
		)
		
		another_net_id = get_another_net_Derek05062010( net_id)
		net_2 = list( net_id another_net_id)
		
		return( net_2)
	)
)

procedure( get_pin_delay_value_Derek05062010( pin_delay_string)
	prog( ( value)
		when( pin_delay_string == "" || null( pin_delay_string)
			return( 0.0)
		)
		
		value = car( parseString( pin_delay_string " "))
		unless( value
			return( 0.0)
		)
		
		value = atof( value)
		
		return( value)
	)
)

procedure( get_pin_delay_Derek05062010( pin_id)
	prog( ( pin_delay_string )
		unless( pin_id
			return( 0.0)
		)
		
		pin_delay_string = pin_id->prop->PIN_DELAY
		
		unless( pin_delay_string
			pin_delay_string = pin_id->parent->prop->PIN_DELAY
		)
		
		value = get_pin_delay_value_Derek05062010( pin_delay_string)
		
		return( value)
	)
)

procedure( get_net_pin_delay_Derek05062010( net_id)
	prog( ( pin_ls value pin_delay)
		pin_ls = axlPinsOfNet( net_id 'pin)
		
		pin_delay = 0.0
		foreach( pin_id pin_ls
			value = get_pin_delay_Derek05062010( pin_id)
			pin_delay = pin_delay + value
		)
		
		return( pin_delay)
	)
)

procedure( get_via_z_len_Derek05062010( via_id)
	prog( ( layer1 layer2 inclusion via_z_len)
		unless( via_id
			return( 0.0)
		)
		
		layer1 = car( via_id->startEnd)
		layer2 = cadr( via_id->startEnd)
		
		inclusion = 'second
		
		via_z_len = axlViaZLength( layer1 layer2 inclusion)
		
		return( via_z_len)
	)
)

procedure( get_net_obj_Derek05062010( net_id obj)
	prog( ( obj_ls total_obj_ls)
		unless( net_id
			return( nil)
		)
		
		when( obj == "" || null( obj)
			return( nil)
		)
		
		foreach( br net_id->branches
			obj_ls = setof( x br->children x->objType == obj)
			total_obj_ls = append( total_obj_ls obj_ls)
		)
		
		return( total_obj_ls)
	)
)

procedure( get_net_via_z_len_Derek05062010( net_id)
	prog( ( via_ls via_z_len value)
		via_ls = get_net_obj_Derek05062010( net_id "via")
		
		via_z_len = 0.0
		foreach( via_id via_ls
			value = get_via_z_len_Derek05062010( via_id)
			via_z_len = via_z_len + value
		)
		
		return( via_z_len)
	)
)

procedure( get_net_length_Derek05062010( net_id)
	; defstruct( length_struct net_len pin_delay via_z_len)
	prog( ( net_len pin_ls pin_delay via_z_len total_len)
		unless( net_id
			return( 0.0)
		)
		
		net_len = axlDBGetLength( net_id)
		pin_delay = get_net_pin_delay_Derek05062010( net_id)
		via_z_len = get_net_via_z_len_Derek05062010( net_id)
		
		;length_stru = make_length_struct( ?net_len net_len ?pin_delay pin_delay ?via_z_len via_z_len)
		
		total_len = net_len + pin_delay + via_z_len
		
		return( total_len)
	)
)

procedure( create_map_struct_Derek05062010( fileterm refdes @key (pin_number "") (net_name1 "") (net_len1 0.0) (net_name2 "") (net_len2 0.0))
	; defstruct( map_struct fileterm refdes pin_number net_name1 net_len1 net_name2 net_len2)
	prog( ( map_stru)
		net_name1 = net_name1 || ""
		net_name2 = net_name2 || ""
		
		if( strlen( net_name1) > strlen( net_name2) then
			net_name_long = net_name1
			net_len_long = net_len1
			net_name_short = net_name2
			net_len_short = net_len2
		else
			net_name_short = net_name1
			net_len_short = net_len1
			net_name_long = net_name2
			net_len_long = net_len2
		)
		
		
		map_stru = make_map_struct( ?fileterm fileterm
									?refdes refdes 
									?pin_number pin_number
									?net_name1 net_name_long
									?net_len1 net_len_long
									?net_name2 net_name_short
									?net_len2 net_len_short)
		
		return( map_stru)
	)
)

procedure( get_net_between_data_Derek05062010( sum_stru)
	; 
	prog( ( sym_ls format pin_ls pin_number net_name net_len map_stru map_stru_ls)
		fileterm = sum_stru->fileterm
		refdes_ls = sum_stru->refdes_ls
		sym_ls = setof( x axlDBGetDesign()->symbols member( x->refdes refdes_ls))
		
		foreach( sym_id sym_ls
			pin_ls = sym_id->pins
			
			foreach( pin_id pin_ls
				net_2 = get_2net_Derek05062010( pin_id->net)
				net1_id = car( net_2)
				net2_id = cadr( net_2)
				net_len1 = get_net_length_Derek05062010( net1_id)
				net_len2 = get_net_length_Derek05062010( net2_id)
				
				map_stru = create_map_struct_Derek05062010( fileterm
											sym_id->refdes
											?pin_number pin_id->number
											?net_name1 net1_id->name 
											?net_len1 net_len1 
											?net_name2 net2_id->name
											?net_len2 net_len2)
				
				map_stru_ls = append1( map_stru_ls map_stru)
			)
		)
		
		return( map_stru_ls)
	)
)

procedure( read_net_between_brd_Derek05062010( sum_stru)
	prog( ( result map_stru_ls)
		unless( sum_stru
			printf( "ERROR: read_net_between_brd() - Fail to get sum Structure")
			return( nil)
		)
		
		brd_addr = sum_stru->brd_addr
		result = open_brd_Derek05062010( brd_addr)
		
		map_stru_ls = get_net_between_data_Derek05062010( sum_stru)
		
		return( map_stru_ls)
	)
)

procedure( get_boards_data_Derek05062010()
	prog( ( sum_stru brd_addr map_stru_ls current_map_stru_ls)
		foreach( fileterm _sum_table
			sum_stru = _sum_table[ fileterm]
			current_map_stru_ls = read_net_between_brd_Derek05062010( sum_stru)
			map_stru_ls = append( map_stru_ls current_map_stru_ls)
		)
		
		brd_addr = axlGetDrawingName()
		open_brd_Derek05062010( brd_addr)
		
		return( map_stru_ls)
	)
)

procedure( get_map_total_Derek05062010( map_stru)
	prog( ( net_len1 net_len2 total)
		unless( map_stru
			return( 0.0)
		)
		
		net_len1 = map_stru->net_len1 || 0.0
		net_len2 = map_stru->net_len2 || 0.0
		total = net_len1 + net_len2
		
		return( total)
	)
)

procedure( get_merge_strus_Derek05062010( map_strus_ls sheet_stru)
	prog( ( map_stru1_ls map_stru2_ls map_stru1_refdes_ls map_stru2_refdes_ls total merge_stru merge_stru_ls)
		unless( sheet_stru
			printf( "ERROR: get_merge_strus() - Argument is nil")
			return( nil)
		)
		
		map_stru1_ls = setof( x map_strus_ls x->fileterm == sheet_stru->fileterm1)
		map_stru2_ls = setof( x map_strus_ls x->fileterm == sheet_stru->fileterm2)
		
		;;;;;
		foreach( (refdes1 refdes2) sheet_stru->refdes1_ls sheet_stru->refdes2_ls
			map_stru1_refdes_ls = setof( x map_stru1_ls x->refdes == refdes1)
			map_stru2_refdes_ls = setof( x map_stru2_ls x->refdes == refdes2)
			
			foreach( map1 map_stru1_refdes_ls
				map2 = car( setof( x map_stru2_refdes_ls x->pin_number == map1->pin_number))
				map_stru2_refdes_ls = remq( map2 map_stru2_refdes_ls)
				
				unless( map2
					map2 = create_map_struct_Derek05062010( sheet_stru->fileterm2 refdes2)
				)
				
				total = apply( 'plus mapcar( 'get_map_total_Derek05062010 list( map1 map2)))
				
				merge_stru = make_merge_struct( ?map1 map1 ?map2 map2 ?total total)
				merge_stru_ls = append1( merge_stru_ls merge_stru)
			)
			
			;;;;;
			map1 = create_map_struct_Derek05062010( sheet_stru->fileterm1 refdes1)
			foreach( map2 map_stru2_refdes_ls
				total = get_map_total_Derek05062010( map2)
				
				merge_stru = make_merge_struct( ?map1 map1 ?map2 map2 ?total total)
				merge_stru_ls = append1( merge_stru_ls merge_stru)
			)
		)
		
		return( merge_stru_ls)
	)
)

procedure( get_map_dataset_Derek05062010( map_stru)
	; defstruct( map_struct fileterm refdes pin_number net_name1 net_len1 net_name2 net_len2)
	; <refdes.pin_number>,net_name,net_length,net_name,net_length, <refdes.pin_number>,net_name,net_length,net_name,net_length, total
	prog( ( fileterm refdes pin_number net_name1 net_len1 net_name2 net_len2 dataset)
		format = "%s,%s,%s,%s,%s,%s,%s"
		
		when( map_stru == 'header
			sprintf( dataset format "Fileterm" "Refdes" "PinNumber" "NetName1+PinDelay+ViaZ" "NetLength1" "NetName2" "NetLength2+PinDelay+ViaZ")
			return( dataset)
		)
		
		fileterm = map_stru->fileterm
		refdes = map_stru->refdes
		pin_number = map_stru->pin_number
		net_name1 = map_stru->net_name1 || ""
		net_len1 = map_stru->net_len1 || 0.0
		net_name2 = map_stru->net_name2 || ""
		net_len2 = map_stru->net_len2 || 0.0
		
		sprintf( net_len1 "%.2f" net_len1)
		sprintf( net_len2 "%.2f" net_len2)
		
		sprintf( dataset format fileterm refdes pin_number net_name1 net_len1 net_name2 net_len2)
		
		return( dataset)
	)
)

procedure( get_sum_net_dataset_header_Derek05062010()
	prog( ( header)
		header = get_map_dataset_Derek05062010( 'header)
		sprintf( header "%s,%s,Total" header header)
		
		return( header)
	)
)

procedure( get_sum_net_descriptions_Derek05062010( sheet_stru)
	prog( ( format line line_ls)
		format = "%s,%s"
		
		sprintf( line format "Fileterm" "BoardAddr")
		line_ls = append1( line_ls line)
		
		unless( sheet_stru
			return( line_ls)
		)
		
		sprintf( line format sheet_stru->fileterm1 _sum_table[ fileterm1]->brd_addr)
		line_ls = append1( line_ls line)
		
		sprintf( line format sheet_stru->fileterm2 _sum_table[ fileterm2]->brd_addr)
		line_ls = append1( line_ls line)
		
		line = ""
		line_ls = append1( line_ls line)
		
		return( line_ls)
	)
)

procedure( get_sum_net_datasets_Derek05062010( map_strus_ls sheet_stru)
	prog( ( merge_stru_ls dataset1 dataset2 total header dataset dataset_ls)
		lines = get_sum_net_descriptions_Derek05062010( sheet_stru)
		dataset_ls = append( dataset_ls lines)
		
		line = get_sum_net_dataset_header_Derek05062010()
		dataset_ls = append1( dataset_ls line)
		
		merge_stru_ls = get_merge_strus_Derek05062010( map_strus_ls sheet_stru)
		foreach( merge_stru merge_stru_ls
			dataset1 = get_map_dataset_Derek05062010( merge_stru->map1)
			dataset2 = get_map_dataset_Derek05062010( merge_stru->map2)
			sprintf( total "%.2f" merge_stru->total)
			
			sprintf( dataset "%s,%s,%s" dataset1 dataset2 total)
			
			dataset_ls = append1( dataset_ls dataset)
		)
		
		return( dataset_ls)
	)
)

procedure( merge_map_data_Derek05062010( map_strus_ls)
	; defstruct( sum_struct fileterm refdes_ls brd_addr)
	; defstruct( sheet_struct fileterm1 refdes1_ls fileterm2 refdes2_ls out_filename)
	; defstruct( map_struct fileterm refdes pin_number net_name1 net_len1 net_name2 net_len2)
	; defstruct( merge_struct map1 map2 total)
	; defstruct( out_struct fileterm1 brd_addr1 fileterm2 brd_addr2 out_filename dataset_ls)
	prog( ( sheet_stru merge_stru_ls dataset_ls out_stru out_stru_ls)
		foreach( sheetname _sheet_table
			sheet_stru = _sheet_table[sheetname]
			
			;;;;;
			dataset_ls = get_sum_net_datasets_Derek05062010( map_strus_ls sheet_stru)
			out_stru = make_out_struct(?out_filename sheet_stru->out_filename ?dataset_ls dataset_ls)
			out_stru_ls = append1( out_stru_ls out_stru)
		)
		
		return( out_stru_ls)
	)
)

procedure( write_file_Derek05062010( filename dataset_ls)
	prog( ( out_port)
		out_port = outfile( filename "w")
		unless( outportp( out_port)
			printf( "ERROR: write_file() - Fail to write file: %L\n" filename)
			return( nil)
		)
		
		foreach( dataset dataset_ls
			fprintf( out_port "%s\n" dataset)
		)
		
		close( out_port)
		
		return( t)
	)
)

procedure( write_sum_net_Derek05062010( out_stru_ls)
	; defstruct( out_struct out_filename dataset_ls)
	prog( ( out_filenameresult )
		foreach( out_stru out_stru_ls
			out_filename = out_stru->out_filename
			result = write_file_Derek05062010( out_filename out_stru->dataset_ls)
			
			if( result then
				printf( "INFO: Successfully write file: %s\n" out_filename)
			else
				printf( "ERROR: Fail to write file: %s\n" out_filename)
			)
		)
		
		return( t)
	)
)

procedure( sum_net_between_board_main_Derek05062010()
	prog( ()
		unless( axlOKToProceed()
			println( "Please done the current function to keep continue")
			return( nil)
		)
		
		unless( isCallable( 'manipulate_xlsx_main_Derek06122018)
			println( "ERROR: Fail to call 'manipulate_xlsx' function. Please import it first") return( nil)
		)
		
		init_Derek05062010()
		
		;;;; init the data from excel
		result = init_table_Derek05062010()
		unless( result return( nil))
		
		;;; get all board name
		result = set_boards_addr_Derek05062010()
		unless( result return( nil))
		
		;;; open number of allegro and export data by board by sheet
		map_strus_ls = get_boards_data_Derek05062010()
		unless( map_strus_ls return( nil))
		
		;;; merge the data file
		out_stru_ls = merge_map_data_Derek05062010( map_strus_ls)
		
		write_sum_net_Derek05062010( out_stru_ls)
		
		axlUIConfirm( "Successfully generate the *.csv to current directory. Please check this out")
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

; (load "manipulate_xlsx_v3d2.ile")
(axlCmdRegister "sum_net_between_board" 'sum_net_between_board_main_Derek05062010)
 (sum_net_between_board_main_Derek05062010)
; skill (encrypt "c:/skill/sum_net_between_board_v1.il" "c:/skill/sum_net_between_board_v1.ile")
; (load "sum_net_between_board_v1.ile")
; (load "sum_net_between_board_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup