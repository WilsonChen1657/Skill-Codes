;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 06/24/2019 - _Derek06242019
;introduction:
;	1. get xsection data from table( created by manupulate_xlsx)
;	2. import xsection data by techfile
;	3. remove the extra layer by script file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek06242019()
	setq( _allegro_version axlVersion( 'version))
	setq( _allegro_path getWorkingDir())
	
	setq( _table_filename "Excel_sheet[0].table")
	setq( _table_layer_col "B")
	setq( _table_type_col "C")
	setq( _table_const_col "G")
	setq( _table_thick_col "J")
	
	setq( _pwr "PWR")
	setq( _sig "SIG")
	setq( _gnd "GND")
	setq( _top "TOP")
	setq( _bot "BOT")
	setq( _bottom "BOTTOM")
	setq( _positive "POSITIVE")
	setq( _top_bottom list( _top _bottom))
	
	setq( _boundary "BOUNDARY")
	setq( _etch "ETCH")
	
	setq( _script_filename "setup_xsection.scr")
	setq( _script_addr strcat( _allegro_path "/" _script_filename))
	
	setq( _type_dielectric "DIELECTRIC")
	setq( _type_plane "PLANE")
	setq( _type_conductor "CONDUCTOR")
	
	setq( _meterial_fr4 "FR-4")
	setq( _meterial_copper "COPPER")
	
	setq( _default_constant "1.0")
	
	setq( _etch_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
	setq( _etch_total axlGetParam( "paramLayerGroup:ETCH")->nChildren)
	
	setq( _sync "SYNC")
	setq( _sync_subclass sprintf( nil "%s%%d" _sync))
	setq( _xsect_int_form "%s_INT%d")
	setq( _xsect_vcc_form "%s_VCC%d")
	setq( _xsect_gnd_form "%s_GND%d")
	setq( _xsect_int_vcc_form "%s_INT-VCC%d")
	setq( _xsect_int_gnd_form "%s_INT-GND%d")
	setq( _xsect_vcc_gnd_form "%s_VCC-GND%d")
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( read_table_Derek06242019( filename)
	prog( ( in_port table csv_ls key val)
		unless( stringp( filename) println( "ArgErr: read_table() - filename is not a string") return( nil))
		unless( isFile( filename) println( "ArgErr: read_table() - filename is not a file") return( nil))
		in_port = infile( filename)
		unless( inportp( in_port) println( "ArgErr: read_table() - Fail to read filename") return( nil))
		;;
		
		table = makeTable( filename nil)
		
		while( gets( csv_line in_port)
			when( and( index( csv_line ",") stringp( csv_line))
				csv_ls = axlStringCSVParse( csv_line ",")
				key = car( csv_ls)
				val = buildString( cdr( csv_ls) ",")
				;;
				if( and( index( key "[") index( key "]")) then
					key = substring( key 2 (strlen( key) - 2))
					table[ key] = val
				else
					printf( "Warning: read_table() - Fail to manipulate csv_line[%s] in [%s]\n" csv_line table_filename)
				)
			)
		)
		close( in_port)
		
		return( table)
	)
)

procedure( get_table_row_by_value_Derek06242019( table val)
	prog( ( cell_ls cell_val row)
		unless( tablep( table) println( "ArgErr: get_table_row_by_value() - [table] is not a table") return( nil))
		unless( stringp( val) println( "ArgErr: get_table_row_by_value() - [val] is not a string") return( nil))
		;;
		
		rexCompile( "^[A-Z]+\\([0-9]+\\)$")
		cell_ls = table->?
		foreach( cell cell_ls
			cell_val = table[ cell]
			when( and( equal( val cell_val) rexExecute( cell))
				row = rexSubstitute( "\\1")
				row = atoi( row)
			)
		)
		
		return( row)
	)
)

procedure( get_table_values_from_col_Derek06242019( table top_row bot_row col step @optional default_val)
	prog( ( val val_ls)
		unless( tablep( table) println( "ArgErr: get_table_values_from_col() - [table] is not a table") return( nil))
		unless( plusp( top_row) println( "ArgErr: get_table_values_from_col() - [top_row] is not a plus") return( nil))
		unless( plusp( bot_row) println( "ArgErr: get_table_values_from_col() - [bot_row] is not a plus") return( nil))
		unless( stringp( col) println( "ArgErr: get_table_values_from_col() - [col] is not a string") return( nil))
		unless( plusp( step) println( "ArgErr: get_table_values_from_col() - [step] is not a plus") return( nil))
		unless( or( null( default_val) stringp( default_val)) println( "ArgErr: get_table_values_from_col() - [default_val] is neither nil nor string") return( nil))
		;;
		
		;;;; get type from top row to bot row stepping 2
		row = top_row
		while( (row <= bot_row)
			sprintf( cell "%s%d" col row)
			val = table[ cell]
			;;
			when( stringp( val) (val_ls = append1( val_ls val)))
			when( and( null( val) stringp( default_val)) (val_ls = append1( val_ls default_val)))
			
			;; step to next
			row = row + step
		)
		
		return( val_ls)
	)
)

procedure( convert_layer_digit_Derek06242019( layer digit)
	;; deal with L1 to L9. convert them to 2 decimal. L01 - L09
	prog( ( layer_num layer_form result)
		unless( stringp( layer) println( "ArgErr: convert_layer_digit() - [layer] is not a string") return( nil))
		when( or( equal( _top layer) equal( _bot layer)) return( layer))
		unless( and( integerp( digit) plusp( digit)) println( "ArgErr: convert_layer_digit() - [digit] is not a plus integer") return( nil))
		
		rexCompile( "^L\\([0-9]+\\)$")
		unless( rexExecute( layer) printf( "ArgErr: convert_layer_digit() - [layer](%s) is not follow the naming Rule\n" layer) return( nil))
		;;
		
		layer_num = rexSubstitute( "\\1")
		layer_num = atoi( layer_num)
		
		sprintf( layer_form "L%%.%dd" digit)
		sprintf( result layer_form layer_num)
		
		return( result)
	)
)

procedure( get_xsect_subclass_names_Derek06242019( layer_ls type_ls)
	prog( ( int_cnt vcc_cnt gnd_cnt iv_cnt ig_cnt vg_cnt subclass_ls)
		unless( dtpr( layer_ls) println( "ArgErr: get_xsect_subclass_names() - layer_ls is not a dtpr") return( nil))
		unless( forall( x layer_ls stringp( x)) println( "ArgErr: get_xsect_subclass_names() - layer_ls is not a string dtpr") return( nil))
		unless( dtpr( type_ls) println( "ArgErr: get_xsect_subclass_names() - type_ls is not a dtpr") return( nil))
		unless( forall( x type_ls stringp( x)) println( "ArgErr: get_xsect_subclass_names() - type_ls is not a string dtpr") return( nil))
		;;
		
				;;;; create layer name in xsection
		int_cnt = vcc_cnt = gnd_cnt = iv_cnt = ig_cnt = vg_cnt = 0
		foreach( (layer type) layer_ls type_ls
			layer = convert_layer_digit_Derek06242019( layer 2)
			;;
			cond(
				( equal( layer _top)
					subclass = _top
				)
				( equal( layer _bot)
					subclass = _bottom
				)
				( and( index( type _pwr) index( type _gnd))
					sprintf( subclass _xsect_vcc_gnd_form layer ++vg_cnt)
				)
				( and( index( type _sig) index( type _pwr))
					sprintf( subclass _xsect_int_vcc_form layer ++iv_cnt)
				)
				( and( index( type _sig) index( type _gnd))
					sprintf( subclass _xsect_int_gnd_form layer ++ig_cnt)
				)
				( index( type _sig)
					sprintf( subclass _xsect_int_form layer ++int_cnt)
				)
				( index( type _pwr)
					sprintf( subclass _xsect_vcc_form layer ++vcc_cnt)
				)
				( index( type _gnd)
					sprintf( subclass _xsect_gnd_form layer ++gnd_cnt)
				)
				( t printf( "ERROR: get_xsect_subclass_names() - Fail to define layer[%s] - type[%s]\n" layer type))
			)
			
			subclass_ls = append1( subclass_ls subclass)
		)
		
		return( subclass_ls)
	)
)

procedure( convert_to_xsection_format_Derek06242019( subclass_ls type_ls const_ls thick_ls)
	prog( ( total is_dielectrical thick const contents subclass type ly_tp_thk_mtr_cns_ls)
		unless( dtpr( subclass_ls) println( "ArgErr: convert_to_xsection_format() - [subclass_ls] is not a dtpr") return( nil))
		unless( dtpr( type_ls) println( "ArgErr: convert_to_xsection_format() - [type_ls] is not a dtpr") return( nil))
		unless( dtpr( const_ls) println( "ArgErr: convert_to_xsection_format() - [const_ls] is not a dtpr") return( nil))
		unless( dtpr( thick_ls) println( "ArgErr: convert_to_xsection_format() - [thick_ls] is not a dtpr") return( nil))
		;;
		
		total = sub1( length( thick_ls))
		is_dielectrical = t
		
		for( th 0 total
			th_d2 = th / 2
			thick = nth( th thick_ls)
			const = nth( th_d2 const_ls)
			;;
			if( is_dielectrical then
				contents = list( nil _type_dielectric thick _meterial_fr4 const)
			else
				subclass = nth( th_d2 subclass_ls)
				type = nth( th_d2 type_ls)
				type = if( equal( _sig type) _type_conductor _type_plane)
				
				contents = list( subclass type thick _meterial_copper _default_constant)
			)
			
			ly_tp_thk_mtr_cns_ls = append1( ly_tp_thk_mtr_cns_ls contents)
			is_dielectrical = !is_dielectrical
		)
		
		return( ly_tp_thk_mtr_cns_ls)
	)
)

procedure( get_xsection_data_Derek06242019( filename)
	prog( ( table top_row bot_row row int_cnt vcc_cnt gnd_cnt iv_cnt ig_cnt vg_cnt
			layer_ls type_ls const_ls thick_ls subclass_ls result)
		unless( stringp( filename) println( "ArgErr: get_xsection_data() - filename is not a string") return( nil))
		unless( isFile( filename) println( "ArgErr: get_xsection_data() - filename is not a file") return( nil))
		;;
		
		;;;; get data from table file
		table = read_table_Derek06242019( filename)
		unless( tablep( table) return( nil))
		
		;;;; get top row and bottom row
		top_row = get_table_row_by_value_Derek06242019( table "TOP")
		bot_row = get_table_row_by_value_Derek06242019( table "BOT")
		unless( and( plusp( top_row) plusp( bot_row))
			printf( "ERROR: get_xsection_data() - Fail to get Top[%L] and Bot[%L] on Col[%s]\n" top_row bot_row _table_layer_col)
			return( nil)
		)
		
		;;;; get layer from top row to bot row stepping 2
		layer_ls = get_table_values_from_col_Derek06242019( table top_row bot_row _table_layer_col 2)
		unless( dtpr( layer_ls) printf( "ERROR: get_xsection_data() - Fail to get layers on col[%s]\n" _table_layer_col) return( nil))
		
		type_ls = get_table_values_from_col_Derek06242019( table top_row bot_row _table_type_col 2)
		unless( dtpr( type_ls) printf( "ERROR: get_xsection_data() - Fail to get types on col[%s]\n" _table_type_col) return( nil))
		
		const_ls = get_table_values_from_col_Derek06242019( table sub1( top_row) add1( bot_row) _table_const_col 2 _default_constant)
		unless( dtpr( const_ls) printf( "ERROR: get_xsection_data() - Fail to get types on col[%s]\n" _table_const_col) return( nil))
		
		thick_ls = get_table_values_from_col_Derek06242019( table sub1( top_row) add1( bot_row) _table_thick_col 1)
		unless( dtpr( thick_ls) printf( "ERROR: get_xsection_data() - Fail to get types on col[%s]\n" _table_thick_col) return( nil))
		
		unless( and( eqv( length( layer_ls) length( type_ls))
					eqv( add1( 2 * length( layer_ls)) length( thick_ls))
					eqv( length( layer_ls) sub1( length( const_ls))))
			println( "ERROR: get_xsection_data() - Number of value in 4 cols is against the rule")
			printf( "\tLayer: [%s](%d) - %L\n" _table_layer_col length( layer_ls) layer_ls)
			printf( "\tType: [%s](%d) - %L\n" _table_type_col length( type_ls) type_ls)
			printf( "\tConstant: [%s](%d) - %L\n" _table_const_col length( const_ls) const_ls)
			printf( "\tThickness: [%s](%d) - %L\n" _table_thick_col length( thick_ls) thick_ls)
			return( nil)
		)
		
		;;;; get subclass
		subclass_ls = get_xsect_subclass_names_Derek06242019( layer_ls type_ls)
		unless( subclass_ls return( nil))
		
		ly_tp_thk_mtr_cns_ls = convert_to_xsection_format_Derek06242019( subclass_ls type_ls const_ls thick_ls)
		unless( dtpr( ly_tp_thk_mtr_cns_ls) return( nil))
		
		;;;; the result would be ((layer_name type thickness material constant)...)
		return( ly_tp_thk_mtr_cns_ls)
	)
)

procedure( update_display_byLayers_Derek06242019( layers)
	prog( ()
		when( stringp( layers) (layers = list( layers)))
		unless( dtpr( layers) println( "ArgErr: update_display_byLayers() - layers is not a dtpr") return( nil))
		;;
		
		axlVisibleDesign( nil)
		foreach( layer layers axlVisibleLayer( layer t))
		
		axlVisibleUpdate( t)
		
		
		return( t)
	)
)

procedure( get_obj_on_display_Derek06242019( opt_ls layer_ls)
	prog( ( total obj_ls)
		unless( dtpr( opt_ls) (opt_ls = list( opt_ls)))
		unless( forall( x opt_ls stringp( x)) println( "ArgErr: get_obj_on_display() - [opt_ls] is not a string dtpr") return( nil))
		;;
		
		;;;
		update_display_byLayers_Derek06242019( layer_ls)
		
		;;;
		axlSetFindFilter( ?enabled opt_ls ?onButtons opt_ls)
		axlAddSelectAll()
		obj_ls = axlGetSelSet()
		
		axlSetFindFilter( ?enabled '( "noall") ?onButtons '( "noall"))
		axlClearSelSet()
		
		;;;
		obj_ls = setof( x obj_ls member( x->layer layer_ls))
		total = length( obj_ls)
		
		printf( "Info: get_obj_on_display() - There are [%d] objects have been selected on layer\n\t%L\n" total layer_ls)
		
		return( obj_ls)
	)
)

procedure( remove_all_on_layers_Derek06242019( layer_ls)
	prog( ( opt_ls obj_ls)
		unless( dtpr( layer_ls) (layer_ls = list( layer_ls)))
		unless( forall( x layer_ls stringp( x)) println( "ArgErr: remove_all_on_layers() - [layer_ls] is not a string dtpr") return( nil))
		unless( forall( x layer_ls axlIsLayer( x)) println( "ArgErr: remove_all_on_layers() - [layer_ls] is not a layer dtpr") return( nil))
		;;
		
		opt_ls = '( "NOALL" "CLINESEGS" "LINES" "TEXT" "SHAPES" "BOUNDARY_SHAPES" "VOIDS")
		obj_ls = get_obj_on_display_Derek06242019( opt_ls layer_ls)
		
		
		result = dtpr( obj_ls)
		
		foreach( obj obj_ls
			when( stringp( obj->objType) axlDeleteObject( obj))
		)
		
		if( result
			println( "Info: remove_all_on_layers() - Removing things on layers")
			println( "Info: remove_all_on_layers() - None of things is removed from layers")
		)
		
		return( t)
	)
)

procedure( write_file_Derek06242019( filename contents)
	prog( ( out_port)
		unless( stringp( filename) println( "ArgErr: write_file() - filename is not a string") return( nil))
		unless( dtpr( contents) println( "ArgErr: write_file() - contents is not a dtpr") return( nil))
		unless( forall( x contents stringp( x))
			println( "ArgErr: write_file() - contents contain non-string thing")
			foreach( line contents println( line))
			return( nil)
		)
		;;
		
		when( isFile( filename) deleteFile( filename))
		
		out_port = outfile( filename "w")
		unless( outportp( out_port) println( "ERROR: write_file() - Fail to write file") return( nil))
		
		foreach( line contents fprintf( out_port "%s\n" line))
		
		close( out_port)
		
		return( t)
	)
)

procedure( replay_scr_Derek06242019( file_addr)
	prog( ( cmd cmd_nm msg)
		unless( stringp( file_addr) println( "ArgErr: replay_scr() - file_addr is not a string") return( nil))
		unless( isFile( file_addr) println( "ArgErr: replay_scr() - script file is not found") return( nil))
		unless( index( file_addr "/") println( "ArgErr: replay_scr() - file_addr is not a address") return( nil))
		;;
		
		;;;; replay the exists script file
		sprintf( cmd "replay \"%s\"" file_addr)
		axlShell( cmd)
		
		return( t)
	)
)

procedure( update_xection_modify_Derek06242019( ly_tp_thk_mtr_cns_ls)
	prog( ( result)
		unless( dtpr( ly_tp_thk_mtr_cns_ls) println( "ArgErr: update_xection_modify() - [ly_tp_thk_mtr_cns_ls] is nil") return( nil))
		;;
		
		if( ( _allegro_version > 17.0)
			result = update_xection_modify_17_Derek06242019( ly_tp_thk_mtr_cns_ls)
			result = update_xection_modify_16_Derek06242019( ly_tp_thk_mtr_cns_ls)
		)
		
		return( result)
	)
)

procedure( update_xection_modify_16_Derek06242019( ly_tp_thk_mtr_cns_ls)
	;; FORM fplyrstack lsgrid change 5,name L2_haha 
	;; FORM fplyrstack lsgrid change 5,type CONDUCTOR 
	;; FORM fplyrstack lsgrid change 5,material COPPER 
	;; FORM fplyrstack lsgrid change 5,thickness 20 
	;; FORM fplyrstack lsgrid change 5,dielectric 5.5 
	;; FORM fplyrstack lsgrid change 11,shield yes 
	prog( ( data name_script_form type_script_form material_script_form thickness_script_form constant_script_form shield_script_form
			lines contents position subclass type thickness material constant name_scripts type_scripts thickness_scripts shield_scripts
			material_scripts constant_scripts msg)
		unless( dtpr( ly_tp_thk_mtr_cns_ls) println( "ArgErr: update_xection_17_modify() - [ly_tp_thk_mtr_cns_ls] is nil") return( nil))
		;;
		
		;;;;
		lines = list( "version 16.6" "setwindow pcb" "generaledit" "xsection" "setwindow form.fplyrstack")
		contents = append( contents lines)
		
		;;;; create the content of the script
		name_script_form = "FORM fplyrstack lsgrid cell %d,name\nFORM fplyrstack lsgrid change %d,name %s"
		type_script_form = "FORM fplyrstack lsgrid lprepopup %d,type\nFORM fplyrstack lsgrid cell %d,type\nFORM fplyrstack lsgrid change %d,type %s"
		material_script_form = "FORM fplyrstack lsgrid lprepopup %d,material\nFORM fplyrstack lsgrid cell %d,material\nFORM fplyrstack lsgrid change %d,material %s"
		thickness_script_form = "FORM fplyrstack lsgrid cell %d,thickness\nFORM fplyrstack lsgrid change %d,thickness %s"
		constant_script_form = "FORM fplyrstack lsgrid cell %d,dielectric\nFORM fplyrstack lsgrid change %d,dielectric %s"
		shield_script_form = "FORM fplyrstack lsgrid cell %d,shield\nFORM fplyrstack lsgrid change %d,shield yes"
		
		;;;;
		position = 1
		foreach( data ly_tp_thk_mtr_cns_ls
			;;
			position++
			subclass = nth( 0 data)
			type = nth( 1 data)
			thickness = nth( 2 data)
			material = nth( 3 data)
			constant = nth( 4 data)
			
			;;
			name_scripts = when( stringp( subclass) sprintf( nil name_script_form position position subclass))
			type_scripts = when( stringp( type) sprintf( nil type_script_form position position position type))
			material_scripts = when( stringp( material) sprintf( nil material_script_form position position position material))
			thickness_scripts = when( stringp( thickness) sprintf( nil thickness_script_form position position thickness))
			constant_scripts = when( stringp( constant) sprintf( nil constant_script_form position position constant))
			sprintf( shield_scripts shield_script_form position position)
			
			;;
			lines = nil
			cond(
				( or( equal( _top subclass) equal( _bottom subclass))
					lines = list( type_scripts material_scripts thickness_scripts constant_scripts)
				)
				( and( stringp( subclass) equal( _type_conductor type))
					lines = list( name_scripts type_scripts material_scripts thickness_scripts constant_scripts)
				)
				( and( stringp( subclass) equal( _type_plane type))
					lines = list( name_scripts type_scripts material_scripts thickness_scripts constant_scripts shield_scripts)
				)
				( null( subclass)
					lines = list( type_scripts material_scripts thickness_scripts constant_scripts)
				)
				( t
					printf( "ERROR: update_xection_modify_16() Fail to define\n\tlayer[%s] type[%s]\n" subclass type)
				)
			)
			when( dtpr( lines) (contents = append( contents lines)))
		)
		
		;;;
		lines = list( "FORM fplyrstack apply" "FORM fplyrstack done" "setwindow pcb" "generaledit")
		contents = append( contents lines)

		;;;; execute script
		write_file_Derek06242019( _script_filename contents)
		replay_scr_Derek06242019( _script_addr)
		
		return( t)
	)
)

procedure( update_xection_modify_17_Derek06242019( ly_tp_thk_mtr_cns_ls)
	prog( ( position subclass type thickness meterial constant tar_xsect data_xsect result)
		unless( dtpr( ly_tp_thk_mtr_cns_ls) println( "ArgErr: update_xection_modify_17() - [ly_tp_thk_mtr_cns_ls] is nil") return( nil))
		;;
		
		;;;; do not remove this line. xsection has to be refresh
		axlShell( "generalEdit")
		
		position = 1
		foreach( data ly_tp_thk_mtr_cns_ls
			;;
			subclass = nth( 0 data)
			type = nth( 1 data)
			thickness = atof( nth( 2 data))
			meterial = nth( 3 data)
			constant = nth( 4 data)
			
			;;
			tar_xsect = axlXSectionGet( nil position++)
			curr_layer = tar_xsect->name
			
			;;
			cond(
				( or( equal( _top subclass) equal( _bottom subclass))
					data_xsect = axlXSectionModify( ?layerType type ?thickness thickness ?material meterial ?dielectricConst constant)
				)
				( and( stringp( subclass) equal( curr_layer subclass) equal( _type_conductor type))
					data_xsect = axlXSectionModify( ?layerType type ?thickness thickness ?material meterial
													?dielectricConst constant ?unusedVia t ?unusedPin t)
				)
				( and( stringp( subclass) equal( curr_layer subclass) equal( _type_plane type))
					data_xsect = axlXSectionModify( ?layerType type ?thickness thickness ?material meterial
													?dielectricConst constant ?unusedVia t ?unusedPin t ?shield t)
				)
				( and( stringp( subclass) not( equal( curr_layer subclass)) equal( _type_conductor type))
					data_xsect = axlXSectionModify( ?name subclass ?layerType type ?thickness thickness ?material meterial
													?dielectricConst constant ?unusedVia t ?unusedPin t)
				)
				( and( stringp( subclass) not( equal( curr_layer subclass)) equal( _type_plane type))
					data_xsect = axlXSectionModify( ?name subclass ?layerType type ?thickness thickness ?material meterial
													?dielectricConst constant ?unusedVia t ?unusedPin t ?shield t)
				)
				( null( subclass)
					data_xsect = axlXSectionModify( ?layerType type ?layerFunction type ?thickness thickness ?material meterial
													?dielectricConst constant)
				)
				( t
					printf( "ERROR: update_xection_modify_17() Fail to define\n\tlayer[%s] type[%s]\n" subclass type)
				)
			)
			
			result = when( data_xsect axlXSectionSet( tar_xsect data_xsect))
			if( result
				printf( "Info: update_xection_modify_17() - Successfully write subclass[%s]\n" or( subclass type))
				printf( "Info: update_xection_modify_17() - Fail to write subclass[%s]\n" or( subclass type))
			)
		)
		
		return( result)
	)
)

procedure( is_curr_new_xsect_layers_in_order_Derek06242019( new_xsect_layer_ls)
	prog( ( new_xsect_total long_layer_ls short_layer_ls result)
		unless( dtpr( new_xsect_layer_ls) println( "ArgErr: is_curr_new_xsect_layers_in_order() - new_xsect_layer_ls is nil") return( nil))
		unless( forall( x new_xsect_layer_ls stringp( x)) println( "ArgErr: is_curr_new_xsect_layers_in_order() - new_xsect_layer_ls is not string dtpr") return( nil))
		;;
		
		new_xsect_total = length( new_xsect_layer_ls)
		
		result = t
		unless( eqv( _etch_total new_xsect_total)
			if( (_etch_total < new_xsect_total) then
				long_layer_ls = new_xsect_layer_ls
				short_layer_ls = _etch_ls
			else
				long_layer_ls = _etch_ls
				short_layer_ls = new_xsect_layer_ls
			)
			
			long_layer_ls = mapcar( lambda( (x) cadr( parseString( x "_"))) long_layer_ls)
			short_layer_ls = mapcar( lambda( (x) cadr( parseString( x "_"))) short_layer_ls)
			
			foreach( layer short_layer_ls
				if( member( layer long_layer_ls) then
					long_layer_ls = member( layer long_layer_ls)
				else
					result = nil
				)
			)
		)
		
		return( result)
	)
)

procedure( create_script_remove_layer_number_16_Derek06242019( conduct_name_ls new_name_ls)
	prog( ( contents all_name_ls position_ls lines line)
		unless( dtpr( conduct_name_ls) println( "ArgErr: create_script_remove_layer_number_16() - conduct_name_ls is not a dtpr") return( nil))
		unless( dtpr( new_name_ls) println( "ArgErr: create_script_remove_layer_number_16() - new_name_ls is not a dtpr") return( nil))
		unless( eqv( length( conduct_name_ls) length( new_name_ls))
			println( "ArgErr: create_script_remove_layer_number_16() - mismatch length to conduct_name_ls and new_name_ls") return( nil))
		;;
		
		;;;;
		lines = list( "version 16.6" "setwindow pcb" "generaledit" "xsection" "setwindow form.fplyrstack")
		contents = append( contents lines)
		
		;;;;
		all_name_ls = get_curr_xsection_layers_16_Derek06242019( 'all_name)
		position_ls = mapcar( lambda( (x) add1( listnindex( all_name_ls x))) conduct_name_ls)
		
		foreach( (position new_name) position_ls new_name_ls
			lines = list( sprintf( nil "FORM fplyrstack lsgrid cell %d,name" position)
							sprintf( nil "FORM fplyrstack lsgrid change %d,name %s" position new_name))
			contents = append( contents lines)
		)
		
		;;;;
		lines = list( "FORM fplyrstack apply" "FORM fplyrstack done" "setwindow pcb" "generaledit")
		contents = append( contents lines)
		
		return( contents)
	)
)

procedure( remove_layer_number_Derek06242019( )
	let( ()
		if( ( _allegro_version > 17.0)
			remove_layer_number_17_Derek06242019( )
			remove_layer_number_16_Derek06242019( )
		)
		
		t
	)
)

procedure( remove_layer_number_16_Derek06242019( )
	let( ( conduct_name_ls new_name_ls contents )
		conduct_name_ls = get_curr_xsection_layers_16_Derek06242019( 'conductor_name_non_top_bot)
		new_name_ls = get_curr_xsection_layers_16_Derek06242019( 'conductor_post_non_top_bot)
		
		;;
		when( and( dtpr( conduct_name_ls) dtpr( new_name_ls))
			contents = create_script_remove_layer_number_16_Derek06242019( conduct_name_ls new_name_ls)
			write_file_Derek06242019( _script_filename contents)
			replay_scr_Derek06242019( _script_addr)
		)
		
		t
	)
)

procedure( remove_layer_number_17_Derek06242019( )
	let( ( conduct_name_ls new_name_ls data_xsect result )
		conduct_name_ls = get_curr_xsection_layers_17_Derek06242019( 'conductor_name_non_top_bot)
		new_name_ls = get_curr_xsection_layers_17_Derek06242019( 'conductor_post_non_top_bot)
		
		;;
		when( and( dtpr( conduct_name_ls) dtpr( new_name_ls))
			foreach( (tar_xsect new_name) conduct_name_ls new_name_ls
				data_xsect = axlXSectionModify( ?name new_name)
				result = axlXSectionSet( tar_xsect data_xsect)
			)
		)
		
		t
	)
)

procedure( create_script_over_bot_diele_16_Derek06242019()
	let( ( subclass_ls th lines contents)
		
		;;; get the th from upper surface to bottom
		subclass_ls = get_curr_xsection_layers_16_Derek06242019( 'all_name)
		
		;;;
		th = listnindex( subclass_ls _bottom)
		th = th + 2
		
		;;; create the contents of hte script
		lines = list( "version 16.6" "setwindow pcb" "generaledit" "xsection" "setwindow form.fplyrstack")
		contents = append( contents lines)
		
		;;;;
		lines = list( sprintf( nil "FORM fplyrstack lsgrid rprepopup %d,number" th)
						sprintf( nil "FORM fplyrstack lsgrid rpopup %d,number 'Add Layer Above'" th))
		contents = append( contents lines)
		
		;;;;
		lines = list( "FORM fplyrstack apply" "FORM fplyrstack done" "setwindow pcb" "generaledit")
		contents = append( contents lines)
		
		contents
	)
)

procedure( create_xsect_layer_Derek06242019( insert_sub subclass type meterial)
	prog( ( result)
		unless( or( stringp( insert_sub) symbolp( insert_sub))
			println( "ArgErr: create_xsect_layer() - insert_sub is neither string nor symbol") return( nil))
		unless( or( not( or( subclass type meterial)) and( stringp( subclass) stringp( type) stringp( meterial)))
			println( "ArgErr: create_xsect_layer() - subclass/type/meterial has to be either nil or string") return( nil))
		;;
		
		if( ( _allegro_version > 17.0)
			result = create_xsect_layer_17_Derek06242019( insert_sub subclass type meterial)
			result = create_xsect_layer_16_Derek06242019( insert_sub subclass type meterial)
		)
		
		return( result)
	)
)

procedure( create_xsect_layer_16_Derek06242019( insert_sub subclass type meterial)
	prog( ( xsect result)
		unless( or( stringp( insert_sub) symbolp( insert_sub))
			println( "ArgErr: create_xsect_layer_16() - insert_sub is neither string nor symbol") return( nil))
		unless( or( not( or( subclass type meterial)) and( stringp( subclass) stringp( type) stringp( meterial)))
			println( "ArgErr: create_xsect_layer_16() - subclass/type/meterial has to be either nil or string") return( nil))
		;;
		
		;;
		if( eq( 'afterBottom insert_sub) then
			contents = create_script_over_bot_diele_16_Derek06242019()
			write_file_Derek06242019( _script_filename contents)
			result = replay_scr_Derek06242019( _script_addr)
			
			axlUIConfirm( "Dielectrical has been added after BOTTOM. Press OK to continue")
		else
			when( symbolp( insert_sub) (insert_sub = symbolToString( insert_sub)))
			
			if( and( stringp( subclass) stringp( type) stringp( meterial))
				result = axlLayerCreateCrossSection( insert_sub type meterial subclass _positive)
				result = axlLayerCreateCrossSection( insert_sub _type_dielectric _meterial_fr4)
			)
		)
		
		if( result
			printf( "Info: create_xsect_layer_16() - Successful to create [%L] ref[%s]\n" subclass insert_sub)
			printf( "Info: create_xsect_layer_16() - Fail to create [%L] ref[%s]\n" subclass insert_sub)
		)
		
		return( result)
	)
)

procedure( create_xsect_layer_17_Derek06242019( insert_sub subclass type meterial)
	prog( ( xsect result)
		unless( or( stringp( insert_sub) symbolp( insert_sub))
			println( "ArgErr: create_xsect_layer_17() - insert_sub is neither string nor symbol") return( nil))
		unless( or( not( or( subclass type meterial)) and( stringp( subclass) stringp( type) stringp( meterial)))
			println( "ArgErr: create_xsect_layer_17() - subclass/type/meterial has to be either nil or string") return( nil))
		;;
		
		;;
		if( and( stringp( subclass) stringp( type) stringp( meterial))
			xsect = make_axlXSection( ?name subclass ?layerType _type_conductor ?material _meterial_copper)
			xsect = make_axlXSection()
		)
		
		;;
		result = axlXSectionCreate( nil insert_sub xsect)
		
		if( result
			printf( "Info: create_xsect_layer_17() - Successful to create [%L] ref[%s]\n" subclass insert_sub)
			printf( "Info: create_xsect_layer_17() - Fail to create [%L] ref[%s]\n" subclass insert_sub)
		)
		
		return( result)
	)
)

procedure( create_post_layers_name_Derek06242019( sync_post_ls)
	prog( ( insert_sub r_sync_post_ls subclass curr_xsect_ls pre_subclass post_subclass pre_xsect post_xsect position result)
		unless( dtpr( sync_post_ls) println( "ArgErr: create_post_layer_name_17() - sync_post_ls is nil") return( nil))
		unless( forall( x sync_post_ls stringp( x)) println( "ArgErr: create_post_layer_name_17() - sync_post_ls is not string dtpr") return( nil))
		;;
		
		subclass_ls = get_curr_xsection_layers_Derek06242019( 'conductor_name)
		r_subclass_ls = reverse( subclass_ls)
		
		r_sync_post_ls = reverse( sync_post_ls)
		foreach( subclass r_sync_post_ls
			when( index( subclass _sync)
				post_subclass = cadr( member( subclass sync_post_ls))

				create_xsect_layer_Derek06242019( post_subclass subclass _type_conductor _meterial_copper)
				create_xsect_layer_Derek06242019( post_subclass nil nil nil)
			)
		)
		
		return( t)
	)
)

procedure( is_increase_Derek06242019( number_ls)
	prog( ( result last_num)
		unless( dtpr( number_ls) println( "ArgErr: is_increase() - number_ls is not a dtpr") return( nil))
		unless( forall( x number_ls numberp( x)) println( "ArgErr: is_increase() - number_ls is not a number dtpr") return( nil))
		;;
		
		result = t
		last_num = car( number_ls)
		foreach( num number_ls
			if( (last_num > num)
				result = nil
				last_num = num
			)
		)
		
		return( result)
	)
)

procedure( is_curr_xsect_layers_in_order_Derek06242019( )
	let( ( sub_ls tag th_ls th curr_tag start end area sum result)
		sub_ls = get_curr_xsection_layers_Derek06242019( 'conductor_post_non_top_bot)
		
		;;; check sub
		result = t
		rexCompile( "\\([A-Z]+\\)\\([0-9]+\\)")
		foreach( sub sub_ls
			if( rexExecute( sub) then
				tag = rexSubstitute( "\\1")
				th = rexSubstitute( "\\2")
				;;
				when( and( stringp( tag) stringp( th))
					th = atof( th)
					
					if( or( null( curr_tag) equal( curr_tag tag)) then
						curr_tag = tag
						th_ls = append1( th_ls th)
					else
						;printf( "curr_tag[%s] tag[%s] tag_ls[%L]\n" curr_tag tag th_ls)
						curr_tag = tag
						
						if( is_increase_Derek06242019( th_ls) then
							th_ls = list( th)
						else
							printf( "ERROR: is_curr_xsect_layers_in_order() - Missing order for subclass. [%s]%L\n" tag th_ls)
							th_ls = list( th)
							result = nil
						)
					)
				)
			else
				printf( "ERROR: is_curr_xsect_layers_in_order() - Fail to analysis subclass[%s]\n" sub)
				result = nil
			)
		)
		
		;;; check the end one
		when( dtpr( th_ls)
			unless( is_increase_Derek06242019( th_ls)
				printf( "ERROR: is_curr_xsect_layers_in_order() - Missing order for subclass. [%s]%L\n" tag th_ls)
				result = nil
			)
		)
		
		result
	)
)

procedure( create_diele_over_top_bot_Derek06242019()
	let( ()
		if( ( _allegro_version > 17.0)
			create_diele_over_top_bot_17_Derek06242019()
			create_diele_over_top_bot_16_Derek06242019()
		)
		
		t
	)
)

procedure( create_diele_over_top_bot_16_Derek06242019()
	let( ( subclass_ls position xsect )
		subclass_ls = get_curr_xsection_layers_16_Derek06242019( 'all_name)
		
		position = length( member( _bottom subclass_ls))
		when( (position < 3)
			create_xsect_layer_16_Derek06242019( 'afterBottom nil nil nil)
		)
		
		position = length( member( _top reverse( subclass_ls)))
		when( (position < 3)
			create_xsect_layer_16_Derek06242019( 'top nil nil nil)
		)
		
		t
	)
)

procedure( create_diele_over_top_bot_17_Derek06242019()
	let( ( position xsect )
		;;; position(0): surface, position(1): dielectric, position(2): TOP
		position = axlXSectionGet( nil "BOTTOM")->position + 1
		xsect = axlXSectionGet( nil position)
		unless( equal( _type_dielectric xsect->layerType)
			create_xsect_layer_17_Derek06242019( 'afterBottom nil nil nil)
		)
		
		;;;
		position = axlXSectionGet( nil "TOP")->position
		when( (position < 2)
			create_xsect_layer_17_Derek06242019( 'top nil nil nil)
		)
		
		t
	)
)

procedure( check_xsection_Derek06242019( new_xsect_layer_ls)
	prog( ( result )
		unless( dtpr( new_xsect_layer_ls) println( "ArgErr: check_xsection() - new_xsect_layer_ls is nil") return( nil))
		unless( forall( x new_xsect_layer_ls stringp( x)) println( "ArgErr: check_xsection() - new_xsect_layer_ls is not string dtpr") return( nil))
		;;
		
		;;; check current xsection is in order, number of the post of the subclass
		result = is_curr_xsect_layers_in_order_Derek06242019( )
		unless( result println( "ERROR: check_xsection() - postfix number for current xsection is not in order") return( nil))
		
		;;; check 1
		result = is_curr_new_xsect_layers_in_order_Derek06242019( new_xsect_layer_ls)
		unless( result println( "ERROR: check_xsection() - Fail to map new xsection to current one") return( nil))
		
		
		;;; create dielectrical above top or under bottom if necessary
		create_diele_over_top_bot_Derek06242019()
		
		return( t)
	)
)

procedure( get_relative_etch_layers_Derek06242019( subclass)
	prog( ( class param_name param subclass_ls layer result )
		unless( stringp( subclass) println( "ArgErr: get_relative_etch_layers() - [subclass] is not a string") return( nil))
		curr_subclass_ls = get_curr_xsection_layers_Derek06242019( 'conductor_name_non_top_bot)
		unless( member( subclass curr_subclass_ls)
			println( "ArgErr: get_relative_etch_layers() - subclass is not in current xsection. or (top/bottom)") return( nil)
		)
		;;
		
		foreach( class axlClasses()
			param_name = strcat( "paramLayerGroup:" class)
			param = axlGetParam( param_name)
			
			subclass_ls = param->groupMembers
			subclass_ls = setof( x subclass_ls equal( subclass x))
			
			when( dtpr( subclass_ls)
				layer = strcat( class "/" subclass)
				result = append1( result layer)
			)
		)
		
		return( result)
	)
)

procedure( get_sub_list_Derek06242019( tar_list start_pos leng)
	prog( ( th total result)
		unless( dtpr( tar_list) println( "ArgErr: get_sub_list() - tar_list is not a dtpr") return( nil))
		unless( and( integerp( leng) plusp( leng)) println( "ArgErr: get_sub_list() - leng is not a plusp integer") return( nil))
		;;
		
		total = start_pos + leng - 1
		for( th start_pos total
			data = nth( th tar_list)
			when( data (result = append1( result data)))
		)
		
		return( result)
	)
)

procedure( create_script_remove_xsect_16_Derek06242019( to_remove_position_ls)
	prog( ( contents line lines)
		unless( dtpr( to_remove_position_ls)
			println( "ArgErr: create_script_remove_xsect_16() - [to_remove_position_ls] is nil") return( nil))
		unless( forall( x to_remove_position_ls and( integerp( x) plusp( x)))
			println( "ArgErr: create_script_remove_xsect_16() - [to_remove_position_ls] is not string plus integer") return( nil))
		;;
		
		;;;;
		lines = list( "version 16.6" "setwindow pcb" "generaledit" "xsection" "setwindow form.fplyrstack")
		contents = append( contents lines)
		
		;;;;
		foreach( position to_remove_position_ls
			sprintf( line "FORM fplyrstack lsgrid rprepopup %d,number\nFORM fplyrstack lsgrid rpopup %d,number 'Remove Layer'" position position)
			contents = append( contents list( line line))
		)
		
		;;;;
		lines = list( "FORM fplyrstack apply" "FORM fplyrstack done" "setwindow pcb" "generaledit")
		contents = append( contents lines)
		
		return( contents)
	)
)

procedure( remove_post_layer_name_Derek06242019( sync_post_ls)
	prog( ( result )
		unless( dtpr( sync_post_ls) println( "ArgErr: remove_post_layer_name() - [sync_post_ls] is nil") return( nil))
		unless( forall( x sync_post_ls stringp( x)) println( "ArgErr: remove_post_layer_name() - [sync_post_ls] is not string dtpr") return( nil))
		;;
		
		if( ( _allegro_version > 17.0)
			result = remove_post_layer_name_17_Derek06242019( sync_post_ls)
			result = remove_post_layer_name_16_Derek06242019( sync_post_ls)
		)
		
		return( result)
	)
)

procedure( remove_post_layer_name_16_Derek06242019( sync_post_ls)
	prog( ( all_name_ls subclass layer_ls subclass_ls sync_post position to_remove_position_ls contents result )
		unless( dtpr( sync_post_ls) println( "ArgErr: remove_post_layer_name_16() - [sync_post_ls] is nil") return( nil))
		unless( forall( x sync_post_ls stringp( x)) println( "ArgErr: remove_post_layer_name_16() - [sync_post_ls] is not string dtpr") return( nil))
		;;
		
		;;;; remove all the things from relative layer
		all_name_ls = get_curr_xsection_layers_16_Derek06242019( 'all_name)
		subclass_ls = get_curr_xsection_layers_16_Derek06242019( 'conductor_name)
		foreach( (subclass sync_post) subclass_ls sync_post_ls
			when( index( sync_post _sync)
				layer_ls = get_relative_etch_layers_Derek06242019( subclass)
				remove_all_on_layers_Derek06242019( layer_ls)
				
				;;; the position is start from 1
				position = add1( listnindex( all_name_ls subclass))
				to_remove_position_ls = append1( to_remove_position_ls position)
			)
		)
		
		;;;; start from bottom to avoid position shift
		to_remove_position_ls = reverse( to_remove_position_ls)
		
		;;;; remove xsection 
		contents = create_script_remove_xsect_16_Derek06242019( to_remove_position_ls)
		write_file_Derek06242019( _script_filename contents)
		result = replay_scr_Derek06242019( _script_addr)
		
		return( result)
	)
)

procedure( remove_post_layer_name_17_Derek06242019( sync_post_ls)
	prog( ( start_pos subclass xsect xsect_name_ls layer_ls subclass_ls sync_post xsect_ls to_remove_xsect_ls)
		unless( dtpr( sync_post_ls) println( "ArgErr: remove_post_layer_name_17() - [sync_post_ls] is nil") return( nil))
		unless( forall( x sync_post_ls stringp( x)) println( "ArgErr: remove_post_layer_name_17() - [sync_post_ls] is not string dtpr") return( nil))
		;;
		
		;;;; do not remove this line. xsection has to be refresh
		axlShell( "generalEdit")
		
		
		xsect_ls = get_curr_xsection_layers_17_Derek06242019( 'all_id)
		xsect_name_ls = xsect_ls~>name
		subclass_ls = get_curr_xsection_layers_17_Derek06242019( 'conductor_post)
		
		;;; remove all the thing in etch layer
		foreach( ( sync_post subclass) sync_post_ls subclass_ls
			when( index( sync_post _sync)
				layer_ls = get_relative_etch_layers_Derek06242019( subclass)
				unless( dtpr( layer_ls)
						printf( "ERROR: remove_post_layer_name_17() - Fail to get layer_ls from layer[%s]\n" subclass))
				
				remove_all_on_layers_Derek06242019( layer_ls)
				
				;;; remove a conductor and its upper dielectric
				start_pos = listnindex( xsect_name_ls subclass)
				unless( plusp( start_pos)
						printf( "ERROR: remove_post_layer_name_17() - Fail to get subclass[%s] from %L\n" subclass xsect_name_ls))
				
				;;;
				contents = get_sub_list_Derek06242019( xsect_ls start_pos 2)
				when( dtpr( contents) (to_remove_xsect_ls = append( to_remove_xsect_ls contents)))
			)
		)
		
		;;; remove subclass from xsection
		foreach( xsect to_remove_xsect_ls
			subclass = or( xsect->name xsect->layerType)
			printf( "Info: remove_post_layer_name_17() - Removing xsection [%s]\n" subclass)
			axlXSectionDelete( xsect)
		)
		
		return( t)
	)
)

procedure( get_curr_xsection_layers_Derek06242019( type)
	prog( ( result)
		unless( symbolp( type) println( "ArgErr: get_curr_xsection_layers() - type is not a symbol") return( nil))
		;;
		
		if( ( _allegro_version > 17.0)
			result = get_curr_xsection_layers_17_Derek06242019( type)
			result = get_curr_xsection_layers_16_Derek06242019( type)
		)
		
		return( result)
	)
)

procedure( get_curr_xsection_layers_16_Derek06242019( type)
	prog( ( result)
		unless( symbolp( type) println( "ArgErr: get_curr_xsection_layers_16_Derek06242019() - type is not a symbol") return( nil))
		;;
		
		result = axlGetXSection()
		
		caseq( type
			( 'all_name
				result = mapcar( 'car result)
			)
			( 'conductor_name_non_top_bot
				result = mapcan( lambda( (x) unless( equal( "" car( x)) list( car( x)))) result)
				result = setof( x result not( or( equal( _top x) equal( _bottom x))))
			)
			( 'conductor_name
				result = mapcan( lambda( (x) unless( equal( "" car( x)) list( car( x)))) result)
			)
			( 'conductor_post_non_top_bot
				result = mapcan( lambda( (x) unless( equal( "" car( x)) list( car( x)))) result)
				result = mapcar( lambda( (x) cadr( parseString( x "_"))) result)
				result = setof( x result x)
			)
			( 'conductor_post
				result = mapcan( lambda( (x) unless( equal( "" car( x)) list( car( x)))) result)
				result = mapcar( lambda( (x) or( cadr( parseString( x "_")) x)) result)
			)
			( t
				printf( "ERROR: get_curr_xsection_layers_16_Derek06242019() - Not support type[%s]\n" type)
				result = nil
			)
		)
		
		return( result)
	)
)

procedure( get_curr_xsection_layers_17_Derek06242019( type)
	prog( ( result)
		unless( symbolp( type) println( "ArgErr: get_curr_xsection_layers_17_Derek06242019() - type is not a symbol") return( nil))
		;;
		
		result = axlXSectionGet( nil 'all)
		
		caseq( type
			( 'all_id)
			( 'conductor_id
				result = setof( x result stringp( x->name))
			)
			( 'conductor_id_non_top_bot
				result = setof( x result stringp( x->name))
				result = setof( x result not( or( equal( _top x->name) equal( _bottom x->name))))
			)
			( 'conductor_name_non_top_bot
				result = setof( x result stringp( x->name))
				result = setof( x result~>name not( or( equal( _top x) equal( _bottom x))))
			)
			( 'conductor_name
				result = setof( x result stringp( x->name))
				result = result~>name
			)
			( 'conductor_post_non_top_bot
				result = setof( x result stringp( x->name))
				result = mapcar( lambda( (x) cadr( parseString( x "_"))) result~>name)
				result = setof( x result x)
			)
			( 'conductor_post
				result = setof( x result stringp( x->name))
				result = mapcar( lambda( (x) or( cadr( parseString( x "_")) x)) result~>name)
			)
			( t
				printf( "ERROR: get_curr_xsection_layers_17_Derek06242019() - Not support type[%s]\n" type)
				result = nil
			)
		)
		
		return( result)
	)
)

procedure( sync_up_layer_Derek06242019( new_xsect_layer_ls)
	prog( ( short_layer_ls long_layer_ls sync_post_ls cnt total )
		unless( dtpr( new_xsect_layer_ls) println( "ArgErr: sync_up_layer() - new_xsect_layer_ls is nil") return( nil))
		unless( forall( x new_xsect_layer_ls stringp( x)) println( "ArgErr: sync_up_layer() - new_xsect_layer_ls is not string dtpr") return( nil))
		;;
		
		;;
		new_post_layer_ls = mapcar( lambda( (x) or( cadr( parseString( x "_")) x)) new_xsect_layer_ls)
		curr_layer_ls = get_curr_xsection_layers_Derek06242019( 'conductor_post)
		
		;;
		if( ( length( new_post_layer_ls) > length( curr_layer_ls)) then
			long_layer_ls = new_post_layer_ls
			short_layer_ls = curr_layer_ls
		else
			long_layer_ls = curr_layer_ls
			short_layer_ls = new_post_layer_ls
		)
		
		;;
		cnt = 1
		total = sub1( length( long_layer_ls))
		for( th 0 total
			pre_sub = nth( sub1( th) long_layer_ls)
			curr_sub = nth( th long_layer_ls)
			post_sub = nth( add1( th) long_layer_ls)
			;;
			pre_th = listnindex( short_layer_ls pre_sub)
			curr_th = listnindex( short_layer_ls curr_sub)
			post_th = listnindex( short_layer_ls post_sub)
			;;
			cond(
				( equal( _top curr_sub)
					sync_post_ls = append1( sync_post_ls _top)
				)
				( equal( _bottom curr_sub)
					sync_post_ls = append1( sync_post_ls _bottom)
				)
				( null( curr_th)
					;;; the certain sub can't be found in short list
					sprintf( subclass _sync_subclass cnt++)
					sync_post_ls = append1( sync_post_ls subclass)
				)
				( not( or( pre_th post_th))
					sync_post_ls = append1( sync_post_ls curr_sub)
				)
				( or( and( null( pre_th) post_th) and( pre_th null( post_th)))
					unless( pre_th (pre_th = -1))
					unless( post_th (post_th = -1))
					;;
					if( or( onep( (post_th - curr_th)) onep( (curr_th - pre_th))) then
						sync_post_ls = append1( sync_post_ls curr_sub)
					else
						sprintf( subclass _sync_subclass cnt++)
						sync_post_ls = append1( sync_post_ls subclass)
					)
				)
				( or( onep( (post_th - curr_th)) onep( (curr_th - pre_th)))
					sync_post_ls = append1( sync_post_ls curr_sub)
				)
				( t
					sprintf( subclass _sync_subclass cnt++)
					sync_post_ls = append1( sync_post_ls subclass)
				)
			)
		)
		
		return( sync_post_ls)
	)
)

procedure( update_xection_Derek06242019( ly_tp_thk_mtr_cns_ls new_xsect_total sync_post_ls)
	prog( ( new_xsect_layer_ls result)
		unless( dtpr( ly_tp_thk_mtr_cns_ls) println( "ArgErr: update_xection_17() - ly_tp_thk_mtr_cns_ls is nil") return( nil))
		unless( dtpr( sync_post_ls) println( "ArgErr: update_xection_17() - sync_post_ls is nil") return( nil))
		unless( plusp( new_xsect_total) println( "ArgErr: update_xection_17() - new_xsect_total is not a plus") return( nil))
		;;
		
		;;;
		unless( eqv( _etch_total new_xsect_total)
			;;;; remove layer number
			println( "Info: update_xection() - Start removing Layer Number")
			remove_layer_number_Derek06242019( )
			
			if( ( _etch_total < new_xsect_total) then
				;;;; insert new layer
				println( "Info: update_xection() - Start Creating subclass")
				create_post_layers_name_Derek06242019( sync_post_ls)
			else
				println( "Info: update_xection() - Start removing subclass")
				remove_post_layer_name_Derek06242019( sync_post_ls)
			)
		)
		
		;;; modify to new etch subclass name and the content
		println( "Info: update_xection() - Start Modifying subclass")
		result = update_xection_modify_Derek06242019( ly_tp_thk_mtr_cns_ls)
	
		return( result)
	)
)

procedure( update_xsection_Derek06242019( ly_tp_thk_mtr_cns_ls)
	prog( ( cnt new_xsect_layer_ls new_xsect_total sync_post_ls result)
		unless( dtpr( ly_tp_thk_mtr_cns_ls) println( "ArgErr: update_xsection() - [ly_tp_thk_mtr_cns_ls] is not a dtpr") return( nil))
		;;
		
		;;
		new_xsect_layer_ls = mapcan( lambda( (x) when( stringp( car( x)) list( car( x)))) ly_tp_thk_mtr_cns_ls)
		new_xsect_total = length( new_xsect_layer_ls)
		
		;;; validation
		result = check_xsection_Derek06242019( new_xsect_layer_ls)
		if( result then
			;;; get sync map
			sync_post_ls = sync_up_layer_Derek06242019( new_xsect_layer_ls)
			printf( "Info: update_xsection() - sync up list: %L\n" sync_post_ls)
			
			;;
			result = update_xection_Derek06242019( ly_tp_thk_mtr_cns_ls new_xsect_total sync_post_ls)
		else
			result = axlUIYesNo( "Too different to insert new layer. Would you like to overwrite the xsection?" "Overwrite Xsection confirm" 'yes)
			unless( result return( nil))
			
			;;
			cnt = 1
			sync_post_ls = get_curr_xsection_layers_Derek06242019( 'conductor_name)
			sync_post_ls = mapcar( lambda( (x) if( member( x _top_bottom) x sprintf( nil _sync_subclass cnt++))) sync_post_ls)
			printf( "Info: update_xsection() - sync up list: %L\n" sync_post_ls)
			
			;;
			println( "Info: update_xsection() - Start removing subclass")
			remove_post_layer_name_Derek06242019( sync_post_ls)
			
			;;
			sync_post_ls = sync_up_layer_Derek06242019( new_xsect_layer_ls)
			result = update_xection_Derek06242019( ly_tp_thk_mtr_cns_ls new_xsect_total sync_post_ls)
		)
		
		return( result)
	)
)

procedure( is_valid_etch_layers_Derek06242019( etch_ls)
	prog( ( err_ls result)
		unless( dtpr( etch_ls) println( "ArgErr: is_valid_etch_layers() - etch_ls is nil") return( nil))
		unless( forall( x etch_ls stringp( x)) println( "ArgErr: is_valid_etch_layers() - etch_ls is not a string dtpr") return( nil))
		;;
		
		rex_form = "^L[0-9]+_"
		rexCompile( rex_form)
		err_ls = mapcan( lambda( (x) unless( rexCompile( x) list( x))) etch_ls)
		
		result = t
		when( dtpr( err_ls)
			printf( "ERROR: is_valid_etch_layers() - Not follow namign rule[%s] for the following layer\n\t%L\n" rex_form err_ls)
			result = nil
		)
		
		return( result)
	)
)

procedure( setup_xsection_main_Derek06242019( @key ( table_addr nil))
	prog( ( msg result ly_tp_thk_mtr_cns_ls result)
		unless( or( null( table_addr) stringp( table_addr) isFile( table_addr) index( table_addr ".table"))
			println( "ArgErr: setup_xsection_main() - table_addr has to be nil or string file name") return( nil))
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		unless( isCallable( 'manipulate_xlsx_main_Derek06122018)
			println( "ERROR: Fail to call 'manipulate_xlsx' function. Please import it first") return( nil))
		;;
		
		;;;; do not remove this line. xsection has to be refresh
		axlShell( "generalEdit")
		
		
		init_Derek06242019()
		result = is_valid_etch_layers_Derek06242019( _etch_ls)
		unless( result return( nil))
		
		if( stringp( table_addr) then
			_table_filename = table_addr
		else
			;;;; create the target table file
			msg = "Please select a target stack-up table"
			result = manipulate_xlsx_main_Derek06122018( ?question_to_select msg ?non_csv t)
			unless( result return( nil))
		)
		
		
		unless( isFile( _table_filename) println( "ERROR: setup_xsection_main() - Fail to get table file") return( nil))
		
		;;;; get value
		ly_tp_thk_mtr_cns_ls = get_xsection_data_Derek06242019( _table_filename)
		unless( dtpr( ly_tp_thk_mtr_cns_ls) return( nil))
		
		;;;; display the current information
		println( "The content of the xsection:")
		foreach( line ly_tp_thk_mtr_cns_ls println( line))
		
		;;;; update xsection
		result = update_xsection_Derek06242019( ly_tp_thk_mtr_cns_ls)
		
		;;;;
		if( result
			msg = "Successful to do 'Setup Xsection' process. Please check this out"
			msg = "Fail to do 'Setup Xsection' process. Please check this out"
		)
		axlUIConfirm( msg)
		println( msg)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

; (load "manipulate_xlsx_v3.ile")
(axlCmdRegister "setup_xsection" 'setup_xsection_main_Derek06242019)
; (setup_xsection_main_Derek06242019)
; skill (encrypt "c:/skill/setup_xsection_v1.il" "c:/skill/setup_xsection_v1.ile")
; (load "setup_xsection_v1.ile")
; (load "setup_xsection_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup