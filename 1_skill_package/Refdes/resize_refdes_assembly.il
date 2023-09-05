/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/05/29                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To create refdes of symbol on REF DES/ASSEMBLY_TOP & BOTTOM            #
#                                                                              #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_resizerefdesassembly()
	let( ( width height)
		defstruct( refdes_struct sym_id target_orient text_rotation target_xy old_textBlock)
		defstruct( footprint_struct footprint_name assembly_outline refdes_assembly assembly_center)
		setq( _layer_pkg_at "PACKAGE GEOMETRY/ASSEMBLY_TOP")
		setq( _layer_pkg_ab "PACKAGE GEOMETRY/ASSEMBLY_BOTTOM")
		setq( _layer_pkg_pbt "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
		setq( _layer_pkg_pbb "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
		setq( _layer_ref_at "REF DES/ASSEMBLY_TOP")
		setq( _layer_ref_ab "REF DES/ASSEMBLY_BOTTOM")
		setq( _layer_ref_st "REF DES/SILKSCREEN_TOP")
		setq( _rlc_sym_ls list( "0805" "0603" "0402" "0201"))
		setq( _create_refdes_logname "")
		setq( _flex_orient_table makeTable( 'flex_orient_table nil))
		setq( _start_tb 31)
		
		setq( _target_textblock_count 36)
		setq( _max_textblock axlDBControl( 'maxTextBlock))
		setq( _current_orient_table makeTable( 'orient_table nil))
		
		setq( _is_flex_textblock t)
	
		setq( _sym_orient_table makeTable( 'sym_orient_table nil))
		setq( _error_struct_ls nil)
		setq( _error_refdes_sym_ls nil)
		setq( _error_outline_sym_ls nil)
		setq( _error_center_sym_ls nil)
		setq( _is_textblock_fit t)
		setq( _cannot_resize_sym_ls nil)
	)
)

procedure( GetCurrentOrients_resizerefdesassembly()
	let( ()
		_max_textblock = axlDBControl( 'maxTextBlock)
		_current_orient_table = makeTable( 'orient_table nil)
		for( i 1 _max_textblock
			orient = make_axlTextOrientation( ?textBlock sprintf( nil "%d" i) ?justify "center")
			_current_orient_table[ i] = orient
		)
	)
)

procedure( CheckFlexTexblock_resizerefdesassembly()
	let( ( width height)
		width = 10.0
		height = 18.0
		for( i _start_tb (_start_tb + 5)
			when( _is_flex_textblock
				param = axlGetParam( strcat( "paramTextBlock:" sprintf( nil "%d" i)))
				unless( and( param->width axlGeoEqual( param->width width) axlGeoEqual( param->height height)
							axlGeoEqual( param->lineSpace 0.0) axlGeoEqual( param->photoWidth 0.0) axlGeoEqual( param->charSpace 0.0))
					_is_flex_textblock = nil
				)

				width = width * 2
				height = height * 2
			)
		)

		CheckTexblockUsage_resizerefdesassembly()
	)
)

procedure( CheckTexblockUsage_resizerefdesassembly()
	prog( ( add_new_textblock unused)
		when( null( _is_flex_textblock)
			if( _max_textblock < 59 then
				add_new_textblock = t
			else
				unused = axlDBTextBlockCompact( nil)
				when( and( null( _is_flex_textblock) unused > 0)
					sprintf( msg "There are %d unused textblocks, do you want to compact it?" unused)
					result = axlUIYesNo( msg "Check Texblock Usage")
					when( result
						axlDBTextBlockCompact( t)
						_max_textblock = axlDBControl( 'maxTextBlock)
						when( _max_textblock < 59
							add_new_textblock = t	
						)
					)
				)
			)
		)

		when( add_new_textblock
			width = 10.0
			height = 18.0
			_start_tb = _max_textblock + 1
			for( i _start_tb _start_tb + 5
				axlDBTextBlockCreate( i ?width width ?height height ?lineSpace 0.0 ?photoWidth 0.0 ?charSpace 0.0)
				width = width * 2
				height = height * 2
			)

			_is_flex_textblock = t
		)
		
		GetCurrentOrients_resizerefdesassembly()
		;ReadFootprintData_resizerefdesassembly()
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_resizerefdesassembly( @optional (is_check nil))
	prog( ()
		unless( Main_locker()
			return( nil)
		)

		Init_resizerefdesassembly()
		
		if( is_check then
			ReadFootprintData_resizerefdesassembly( t)
			WriteCheckLog_resizerefdesassembly()
		else
			CheckFlexTexblock_resizerefdesassembly()
			ReadFootprintData_resizerefdesassembly()
			ResizeRefdes_resizerefdesassembly()
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( ReadFootprintData_resizerefdesassembly( @optional (is_check nil))
	let( ( sym_ls sym_name_ls refdes_text_ls error_ls result_ls error_refdes_ls error_outline_ls box hor_ver orient)
		_error_struct_ls = nil
		_sym_orient_table = makeTable( 'sym_orient_table nil)
		sym_ls = setof( x axlDBGetDesign()->symbols and( axlDBRefreshId( x) x->refdes))
		; reverse to let R0201 to check before C0201
		sym_name_ls = reverse( sort( UniqueList_utilityprogram( sym_ls~>name) 'alphalessp))
		refdes_text_ls = GetTextList_utilityprogram( list( _layer_ref_at _layer_ref_ab))
		foreach( sym_name sym_name_ls
			footprint_strc = make_footprint_struct( ?footprint_name sym_name ?assembly_outline t ?refdes_assembly t ?assembly_center t)
			result_ls = setof( x sym_ls equal( x->name sym_name))
			; check refdes assembly exists
			error_refdes_ls = setof( x result_ls !exists( y refdes_text_ls equal( y->text x->refdes)))
			when( dtpr( error_refdes_ls)
				footprint_strc->refdes_assembly = nil
				_error_refdes_sym_ls = append( _error_refdes_sym_ls error_refdes_ls)
			)
			
			error_ls = error_refdes_ls
			; check assembly outline exists
			error_outline_ls = setof( x result_ls !GetAssemblyBox_resizerefdesassembly( x))
			when( dtpr( error_outline_ls)
				footprint_strc->assembly_outline = nil
				_error_outline_sym_ls = append( _error_outline_sym_ls error_outline_ls)
			)

			error_ls = append( error_ls error_outline_ls)
			result_ls = setof( x result_ls !member( x error_ls))
			
			; check assembly outline center with place bound center
			error_center_ls = setof( x result_ls !CheckAssemblyCenter_resizerefdesassembly( x))
			when( dtpr( error_center_ls)
				footprint_strc->assembly_center = nil
				_error_center_sym_ls = append( _error_center_sym_ls error_center_ls)
			)

			unless( is_check
				error_ls = append( error_ls error_center_ls)
				error_ls = UniqueList_utilityprogram( error_ls)
				result_ls = setof( x result_ls !member( x error_ls))

				length_ls = UniqueList_utilityprogram( mapcar( lambda( (x) length( x)) result_ls~>refdes))
				foreach( refdes_length length_ls
					is_hor = t
					sym_id = car( setof( x result_ls and( equal( length( x->refdes) refdes_length) equal( modf( x->rotation 90.0) 0.0))))
					if( sym_id then
						case( sym_id->rotation
							( (0 180)
								is_hor = t
							)
							( (90 270)
								is_hor = nil
							)
						)

						box = GetAssemblyBox_resizerefdesassembly( sym_id)
						hor_ver = GetBoxSize_resizerefdesassembly( box)
						unless( is_hor
							hor_ver = list( cadr( hor_ver) car( hor_ver))
						)
						
						sprintf( key "%s_%d" sym_name refdes_length)
						sprintf( temp_key "R%s_%d" buildString( cdr( parseString( sym_name "")) "") refdes_length)
						temp_orient = _sym_orient_table[ temp_key]
						if( temp_orient
							orient = temp_orient
							orient = GetOrientBySize_resizerefdesassembly( hor_ver sym_id->refdes)
						)
						
						_sym_orient_table[ key] = orient
					else
						sprintf( msg "[%s] Symbol's rotation are not 0, 90, 180, 270" sym_name)
						PrintMsg_utilityprogram( msg ?title "Init()" ?level 'warn ?show_warn nil)
					)
				)
			)
			
			unless( and( footprint_strc->assembly_outline footprint_strc->refdes_assembly footprint_strc->assembly_center)
				_error_struct_ls = append1( _error_struct_ls footprint_strc)
			)
		)
	)
)

procedure( ResizeRefdes_resizerefdesassembly()
	let( ( error_sym_ls sym_ls text_ls resize_ls error_text_ls)
		axlVisibleDesign( nil)
		axlVisibleLayer( _layer_pkg_at t)
		axlVisibleLayer( _layer_ref_at t)

		error_sym_ls = append( _error_outline_sym_ls _error_refdes_sym_ls)
		error_sym_ls = UniqueList_utilityprogram( append( error_sym_ls _error_center_sym_ls))
		sym_ls = setof( x axlDBGetDesign()->symbols and( x->refdes !member( x->refdes error_sym_ls~>refdes)))
		text_ls = GetTextList_utilityprogram( list( _layer_ref_at _layer_ref_ab))
		foreach( sym_id sym_ls
			refdes_struc = GetStruct_resizerefdesassembly( sym_id)
			if( refdes_struc then
				text_id = car( setof( x text_ls equal( x->text sym_id->refdes)))
				refdes_struc->old_textBlock = text_id->textBlock
				when( text_id
					unless( and( axlGeoPointsEqual( text_id->xy refdes_struc->target_xy)
								equal( refdes_struc->target_orient->textBlock text_id->textBlock))
						resize_ls = append1( resize_ls refdes_struc)
						error_text_ls = append1( error_text_ls text_id)
					)
				)
			else
				_cannot_resize_sym_ls = append1( _cannot_resize_sym_ls sym_id)
			)
		)

		when( dtpr( error_text_ls)
			axlDeleteObject( error_text_ls)
		)

		CreateRefdes_resizerefdesassembly( resize_ls)
	)
)

procedure( GetStruct_resizerefdesassembly( sym_id)
	prog( ( key orient param offset rotation target_xy refdes_struc)
		msg_title = "GetStruct()"
		sprintf( key "%s_%d" sym_id->name length( sym_id->refdes))
		orient = _sym_orient_table[ key]
		unless( orient
			sprintf( msg "[%s] can't get textblock" sym_id->name)
			PrintMsg_utilityprogram( msg ?title msg_title ?level 'warn ?show_warn nil)
			return( nil)
		)
		
		param = axlGetParam( strcat( "paramTextBlock:" orient->textBlock))
		offset = 0:(-param->height / 2)
		rotation = sym_id->rotation || 0.0
		; to make sure refdes are in same direction
		when( rotation >= 180
			rotation = rotation - 180
		)

		;target_xy = axlGeoRotatePt( rotation axlMXYAdd( sym_id->xy offset) sym_id->xy)
		sym_xy = axlMidPointLine( GetAssemblyBox_resizerefdesassembly( sym_id))
		target_xy = axlGeoRotatePt( rotation axlMXYAdd( sym_xy offset) sym_xy)
		refdes_struc = make_refdes_struct( ?sym_id sym_id ?target_orient orient ?text_rotation rotation ?target_xy target_xy)
		return( refdes_struc)
	)
)

procedure( GetAssemblyBox_resizerefdesassembly( sym_id)
	prog( ( assembly_layer obj_ls)
		assembly_layer = if( equal( sym_id->layer "TOP") _layer_pkg_at _layer_pkg_ab)
		obj_ls = setof( x sym_id->children and( equal( x->layer assembly_layer) equal( x->objType "path")
												equal( axlPathGetWidth( axlDB2Path(x)) 0)))
		unless( obj_ls
			; no assembly_top should let Rita edit footprint
			return( nil)
		)

		return( axlDBGetExtents( obj_ls nil))
	)
)

procedure( CheckAssemblyCenter_resizerefdesassembly( sym_id)
	prog( ( assembly_box assembly_center place_bound_layer shape_ls shape_box)
		assembly_box = GetAssemblyBox_resizerefdesassembly( sym_id)
		assembly_center = axlMidPointLine( assembly_box)
		place_bound_layer = if( equal( sym_id->layer "TOP") _layer_pkg_pbt _layer_pkg_pbb)
		shape_ls = setof( x sym_id->children and( equal( x->layer place_bound_layer) equal( x->objType "shape")))
		if( dtpr( shape_ls) then
			cond(
				( exists( x _rlc_sym_ls index( sym_id->name x))
					shape_box = car( shape_ls)->bBox
					return( axlGeoPointsEqual( assembly_center axlMidPointLine( shape_box)))
				)
				( t
					pb_box = axlDBGetExtents( shape_ls nil)
					shape_center = axlMidPointLine( pb_box)
					tolerance = GetUnitValueByMils_utilityprogram( 10)
					target_box = list( axlMXYAdd( shape_center -tolerance:-tolerance) axlMXYAdd( shape_center tolerance:tolerance))
					return( axlIsPointInsideBox( assembly_center target_box))	
				)
			)
		else
			return( nil)
		)
	)
)

procedure( GetBoxSize_resizerefdesassembly( box)
	prog( ( hor ver)
		hor = caadr( box) - caar( box)
		ver = cadadr( box) - cadar( box)
		return( list( hor ver))
	)
)

procedure( GetOrientBySize_resizerefdesassembly( hor_ver refdes)
	prog( ( textblock_id result_orient orient temp_orient)
		msg_title = "GetOrientBySize()"
		if( _is_flex_textblock then
			max_textblock = _start_tb + 5
			min_textblock = _start_tb
		else
			max_textblock = _max_textblock
			min_textblock = 1
		)
		
		textblock_id = _max_textblock
		while( and( null( result_orient->textBlock) (textblock_id <= max_textblock) (textblock_id >= min_textblock))
			orient = _current_orient_table[ textblock_id]
			when( orient
				text_size = GetTextSize_resizerefdesassembly( orient->textBlock refdes)
				when( and( cadr( text_size) <= cadr( hor_ver) car( text_size) <= car( hor_ver))
					if( or( cadr( text_size) >= cadr( hor_ver) * 0.5 car( text_size) >= car( hor_ver) * 0.5) then
						result_orient = orient
					else
						if( temp_orient then
							temp_text_size = GetTextSize_resizerefdesassembly( temp_orient->textBlock refdes)
							when( or( car( text_size) > car( temp_text_size) cadr( text_size) > cadr( temp_text_size))
								temp_orient = orient
							)
						else
							temp_orient = orient
						)
					)
				)
			)

			textblock_id--
		)

		if( result_orient then
			return( result_orient)
		else
			if( temp_orient then
				return( temp_orient)
			else
				_is_textblock_fit = nil
				sprintf( msg "No suitable textblock for [%s]" refdes)
				PrintMsg_utilityprogram( msg ?title msg_title ?level 'warn ?show_warn nil)
				return( nil)
				;return( _current_orient_table[ 1])
			)
		)
	)
)

procedure( GetTextSize_resizerefdesassembly( textblock refdes)
	prog( ( param text_width text_height text_size)
		param = axlGetParam( strcat( "paramTextBlock:" textblock))
		text_width = (param->width + param->charSpace) * length( refdes) - param->charSpace
		text_height = param->height + param->photoWidth
		text_size = list( text_width text_height)
		return( text_size)
	)
)

procedure( CreateRefdes_resizerefdesassembly( data_ls)
	let( ()
		foreach( data data_ls
			sym_id = data->sym_id
			if( equal( sym_id->layer "TOP")
				text_layer = _layer_ref_at
				text_layer = _layer_ref_ab
			)

			data->target_orient->rotation = data->text_rotation
			axlDBCreateText( data->sym_id->refdes data->target_xy data->target_orient text_layer sym_id)
		)

		WriteLog_resizerefdesassembly( data_ls)
	)
)

procedure( WriteLog_resizerefdesassembly( data_ls)
	prog( ( log_info out_port format)
		log_info = SetUpLog_utilityprogram( "create_refdes_assembly")
		unless( log_info
			return( nil)
		)
	
		out_port = nth( 0 log_info)
		_create_refdes_logname = nth( 1 log_info)

		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: Resize refdes on %L\n" list( _layer_ref_at _layer_ref_ab))

		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")

		WriteCheckData_resizerefdesassembly( out_port nil)
		
		fprintf( out_port "Cannot resize data[%d]\n" length( _cannot_resize_sym_ls))
		format = "%-10s,%-30s,%-20s,%L\n"
		fprintf( out_port format "Layer" "Name" "Refdes" 'xy)
		if( dtpr( _cannot_resize_sym_ls) then
			_cannot_resize_sym_ls = sort( _cannot_resize_sym_ls 'SortSymbol_resizerefdesassembly)
			foreach( sym_id _cannot_resize_sym_ls
				fprintf( out_port format sym_id->layer sym_id->name sym_id->refdes sym_id->xy)
			)
		else
			fprintf( out_port "\tNone\n")
		)

		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")

		data_ls = sort( data_ls 'SortData_resizerefdesassembly)
		fprintf( out_port "Resized data[%d]\n" length( data_ls))
		format = "%-10s,%-30s,%-20s,%-10s,%-18s,%L\n"
		fprintf( out_port format "Layer" "Name" "Refdes" "textBlock" "sym text rotation" 'xy)
		if( dtpr( data_ls) then
			foreach( data data_ls
				sym_id = data->sym_id
				sprintf( textblock "%s -> %s" data->old_textBlock (data->target_orient->textBlock || "NONE"))
				sprintf( rotation "%5s -> %-5s" sprintf( nil "%.1f" sym_id->rotation) sprintf( nil "%.1f" data->text_rotation))
				fprintf( out_port format sym_id->layer sym_id->name sym_id->refdes textblock rotation sym_id->xy)
			)
		else
			fprintf( out_port "\tNone\n")
		)

		close( out_port)
		axlUIViewFileCreate( _create_refdes_logname "Create refdes assembly report" nil)
	)
)

procedure( WriteCheckLog_resizerefdesassembly()
	let( ( log_info out_port)
		log_info = SetUpLog_utilityprogram( "check_refdes_assembly")
		unless( log_info
			return( nil)
		)

		out_port = nth( 0 log_info)
		_create_refdes_logname = nth( 1 log_info)

		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: Check footprint's ASSEMBLY outline and REFDES\non %L\n" list( _layer_ref_at _layer_ref_ab))

		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")

		WriteCheckData_resizerefdesassembly( out_port)
		
		close( out_port)
		axlUIViewFileCreate( _create_refdes_logname "Check refdes assembly report" nil)
	)
)

procedure( WriteCheckData_resizerefdesassembly( out_port @optional (show_detail t))
	let( ( format error_sym_ls)
		_error_struct_ls = sort( _error_struct_ls lambda( (a b) alphalessp( a->footprint_name b->footprint_name)))
		if( !dtpr( _error_struct_ls) then
			fprintf( out_port "All footprints are correct\n")
		else
			sym_ls = axlDBGetDesign()->symbols
			fprintf( out_port "ASSEMBLY outline and REF DES on footprint:\n")
			format = "%-30s,%-10s,%-20s,%-20s,%s\n"
			fprintf( out_port format "Footprint name" "usage" "Assembly outline" "Refdes Assembly" "Assembly center")
			foreach( data _error_struct_ls
				sprintf( usage_count "%d" length( setof( x sym_ls equal( x->name data->footprint_name))))
				error_outline_count = length( setof( x _error_outline_sym_ls equal( x->name data->footprint_name)))
				error_refdes_count = length( setof( x _error_refdes_sym_ls equal( x->name data->footprint_name)))
				error_center_count = length( setof( x _error_center_sym_ls equal( x->name data->footprint_name)))
				
				assembly_outline = if( data->assembly_outline "PASS" sprintf( nil "FAIL[%d]" error_outline_count))
				refdes_assembly = if( data->refdes_assembly "PASS" sprintf( nil "FAIL[%d]" error_refdes_count))
				assembly_center = if( data->assembly_center "PASS" sprintf( nil "FAIL[%d]" error_center_count))
				fprintf( out_port format data->footprint_name usage_count assembly_outline refdes_assembly assembly_center)
			)

			fprintf( out_port "\nPlease inform Rita to correct it!!\n")
			
			when( show_detail
				fprintf( out_port "\n\n")
				fprintf( out_port GetLogSeperator_utilityprogram())
				fprintf( out_port "\n\n")

				_error_outline_sym_ls = sort( _error_outline_sym_ls 'SortSymbol_resizerefdesassembly)
				_error_refdes_sym_ls = sort( _error_refdes_sym_ls 'SortSymbol_resizerefdesassembly)
				_error_center_sym_ls = sort( _error_center_sym_ls 'SortSymbol_resizerefdesassembly)
				
				fprintf( out_port "Error Assembly outline data[%d]\n" length( _error_outline_sym_ls))
				format = "%-10s,%-30s,%-20s,%L\n"
				fprintf( out_port format "Layer" "Name" "Refdes" 'xy)
				if( dtpr( _error_outline_sym_ls) then
					foreach( sym_id _error_outline_sym_ls
						fprintf( out_port format sym_id->layer sym_id->name sym_id->refdes sym_id->xy)
					)
				else
					fprintf( out_port "\tNone")
				)

				fprintf( out_port "\n\n")
				fprintf( out_port GetLogSeperator_utilityprogram())
				fprintf( out_port "\n\n")

				fprintf( out_port "Missing Refdes data[%d]\n" length( _error_refdes_sym_ls))
				fprintf( out_port format "Layer" "Name" "Refdes" 'xy)
				if( dtpr( _error_refdes_sym_ls) then
					foreach( sym_id _error_refdes_sym_ls
						fprintf( out_port format sym_id->layer sym_id->name sym_id->refdes sym_id->xy)
					)
				else
					fprintf( out_port "\tNone")
				)
				

				fprintf( out_port "\n\n")
				fprintf( out_port GetLogSeperator_utilityprogram())
				fprintf( out_port "\n\n")

				fprintf( out_port "Assembly outline has been moved data[%d]\n" length( _error_center_sym_ls))
				fprintf( out_port "* ASSEMBLY outline's mid point should be same with PLACE_BOUND shape's mid point\n  when Symbol's name contains %L\n" _rlc_sym_ls)
				fprintf( out_port "* Else has 10 mils tolerance\n\n")
				fprintf( out_port format "Layer" "Name" "Refdes" 'xy)
				if( dtpr( _error_center_sym_ls) then
					foreach( sym_id _error_center_sym_ls
						fprintf( out_port format sym_id->layer sym_id->name sym_id->refdes sym_id->xy)
					)
				else
					fprintf( out_port "\tNone")
				)
			)
		)

		fprintf( out_port "\n\n")
		fprintf( out_port GetLogSeperator_utilityprogram())
		fprintf( out_port "\n\n")
	)
)

procedure( SortSymbol_resizerefdesassembly( sym_a sym_b)
	prog( ()
		if( equal( sym_a->layer sym_b->layer)
			return( alphalessp( sym_a->refdes sym_b->refdes))
			return( !alphalessp( sym_a->layer sym_b->layer))
		)
	)
)

procedure( SortData_resizerefdesassembly( data_a data_b)
	prog( ( sym_a sym_b)
		sym_a = data_a->sym_id
		sym_b = data_b->sym_id
		if( equal( sym_a->layer sym_b->layer) then
			if( equal( sym_a->name sym_b->name)
				return( alphalessp( sym_a->refdes sym_b->refdes))
				return( alphalessp( sym_a->name sym_b->name))
			)
		else
			return( !alphalessp( sym_a->layer sym_b->layer))
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "resize_refdes_assembly" 'Main_resizerefdesassembly)
/*
(encrypt "c:/skill/resize_refdes_assembly_v1d1.il" "c:/skill/resize_refdes_assembly_v1d1.ile")
(load "resize_refdes_assembly_v1d1.il")
(load "resize_refdes_assembly_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup