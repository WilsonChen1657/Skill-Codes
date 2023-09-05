;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 07/22/2019 - _Derek07222019
;introduction:
;	1. copy or paste symbol/line/text from one board to another
;	2. 
;data format
;	SYMBOL,R100
;	POSITION,symbol,refdes,layer,xy,rotation,mirrored
;	TEXT,textblock
;	LINE,start_xy,end_xy,width
;	ARC,start_xy,end_xy,width,center_xy,cw
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( check_value_Derek07222019( err_type func_nm val_nm val type)
	prog( ( result)
		unless( symbolp( type) println( "ArgErr: check_value() - [type] is not a symbol") return( nil))
		unless( symbolp( err_type) println( "ArgErr: check_value() - [err_type] is not a symbol") return( nil))
		unless( symbolp( func_nm) println( "ArgErr: check_value() - [func_nm] is not a symbol") return( nil))
		unless( symbolp( val_nm) println( "ArgErr: check_value() - [val_nm] is not a symbol") return( nil))
		;;
		
		caseq( type
			( '_v_dbid
				result = stringp( val->objType)
			)
			( '_v_shape_objtype
				result = equal( "shape" val->objType)
			)
			( '_v_shape_or_polygon_objtype
				result = or( equal( "shape" val->objType) equal( "polygon" val->objType))
			)
			( '_v_shape_or_polygon_objtype_dtpr
				result = and( dtpr( val) forall( x val or( equal( "shape" x->objType) equal( "polygon" x->objType))))
			)
			( '_v_shape_dtpr
				result = and( dtpr( val) forall( x val equal( "shape" x->objType)))
			)
			( '_v_text_objtype
				result = equal( "text" val->objType)
			)
			( '_v_form_objtype
				result = equal( "form" val->objType)
			)
			( '_v_via_name
				result = and( stringp( val) member( val axlGetAllViaList()~>name))
			)
			( '_v_number
				result = numberp( val)
			)
			( '_v_number_positive
				result = and( numberp( val) (val >= 0))
			)
			( '_v_natural_number
				;; 1 2 3 4 5 6 7 8 9
				result = and( integerp( val) (val > 0))
			)
			( '_v_natural_number_or_string
				;; 1 2 3 4 5 6 7 8 9 ""
				result = or( and( integerp( val) (val > 0)) stringp( val))
			)
			( '_v_natural_number_or_nil
				;; 1 2 3 4 5 6 7 8 9
				result = or( and( integerp( val) (val > 0)) null( val))
			)
			( '_v_bool
				result = booleanp( val)
			)
			( '_v_symbol_or_string
				result = or( symbolp( val) stringp( val))
			)
			( '_v_symbol_objtype
				result = equal( "symbol" val->objType)
			)
			( '_v_symbol_objtype_dtpr
				result = and( dtpr( val) forall( x val equal( "symbol" x->objType)))
			)
			( '_v_symbol_objtype_or_nil
				if( null( val)
					result = t
					result = equal( "symbol" val->objType)
				)
			)
			( '_v_symbol
				result = symbolp( val)
			)
			( '_v_string
				result = stringp( val)
			)
			( '_v_string_or_nil
				result = or( null( val) stringp( val))
			)
			( '_v_string_or_bool
				result = or( booleanp( val) stringp( val))
			)
			( '_v_string_or_bool_or_natural_number
				result = or( booleanp( val) stringp( val) and( integerp( val) (val > 0)))
			)
			( '_v_list
				result = listp( val)
			)
			( '_v_dtpr
				result = dtpr( val)
			)
			( '_v_string_dtpr
				result = and( dtpr( val) forall( x val stringp( x)))
			)
			( '_v_string_dtpr_or_string
				result = or( stringp( val) and( dtpr( val) forall( x val stringp( x))))
			)
			( '_v_string_list_or_string
				result = or( null( val) stringp( val) and( dtpr( val) forall( x val stringp( x))))
			)
			( '_v_table_or_nil
				result = or( null( val) tablep( val))
			)
			( '_v_outport
				result = outportp( val)
			)
			( '_v_inport
				result = inportp( val)
			)
			( '_v_filename
				result = and( stringp( val) isFile( val))
			)
			( '_v_table
				result = tablep( val)
			)
			( '_v_alphabet
				when( or( symbolp( val) stringp( val))
					(result = rexMatchp( "[a-zA-Z]+" val))
				)
			)
			( '_v_xy
				result = and( pairp( val) numberp( car( val)) numberp( cadr( val)))
			)
			( '_v_xy_or_nil
				if( null( val)
					result = t
					result = and( pairp( val) numberp( car( val)) numberp( cadr( val)))
				)
			)
			( '_v_path_objtype
				result = dtpr( val->_pathList)
			)
			( '_v_text_objtype_dtpr
				result = and( dtpr( val) forall( x val equal( "text" x->objType)))
			)
			( '_v_text_objtype_list
				if( null( val)
					result = t
					result = and( dtpr( val) forall( x val equal( "text" x->objType)))
				)
			)
			( '_v_seg_objtype_dtpr
				result = and( dtpr( val) forall( x val or( equal( "line" x->objType) equal( "arc" x->objType))))
			)
			( '_v_seg_objtype_list
				if( null( val)
					result = t
					result = and( dtpr( val) forall( x val or( equal( "line" x->objType) equal( "arc" x->objType))))
				)
			)
			( t
				printf( "ERROR: check_value() - Yet to define type[%s] for value[%s] in function[%s]\n" type val_nm val_nm func_nm)
			)
		)
		
		unless( result printf( "%s: %s() - [%s][%L] is not a %s\n" err_type func_nm val_nm val type))
		
		return( result)
	)
)

procedure( init_Derek07222019()
	;;;;
	setq( _allegro_version axlVersion( 'version))
	setq( _allegro_work_dir getWorkingDir())
	setq( _allegro_design_name axlCurrentDesign())
	setq( _month_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	setq( _now_time sprintf( nil "%d%.2d%.2d-%.2d%.2d%.2d" _year listnindex( _month_ls _month) _date _hour _minute _second))
	sprintf( nil "%.2d" 2)
	
	
	;;;; form variable
	setq( _form_filename "copy_paste_symbols.form")
	setq( _form_handle 'copy_paste_symbols)
	
	setq( _form_symbol_copy "symbol_copy")
	setq( _form_silkscreen_copy "silkscreen_copy")
	setq( _form_paste "paste")
	setq( _form_close "close")
	setq( _form_operate _form_close)
	
	;;;;
	setq( _csv ".csv")
	setq( _copy_paste_symbols "copy_paste_symbols")
	setq( _store_log_filename sprintf( nil "%s-store-%s.log" _copy_paste_symbols _now_time))
	setq( _relocate_log_filename sprintf( nil "%s-relocate-%s.log" _copy_paste_symbols _now_time))
	setq( _default_store_file_csv sprintf( nil "%s-%s%s" _copy_paste_symbols _now_time _csv))
	setq( _popup_command nil)
	setq( _done 'done)
	setq( _cancel 'cancel)
	setq( _void "void")
	setq( _symbol "symbol")
	setq( _path "path")
	setq( _shape "shape")
	setq( _start "start")
	setq( _end "end")
	setq( _nil "nil")
	
	;;;; DATA FORMAT
	setq( _package "package")
	setq( _package_end "end_of_package")
	setq( _position "position")
	setq( _text "text")
	setq( _line "line")
	setq( _arc "arc")
	setq( _true "true")
	setq( _false "false")
	
	;;;; layer
	setq( _ref_des "REF DES")
	setq( _silkscreen "SILKSCREEN")
	setq( _board_geometry "BOARD GEOMETRY")
	setq( _pg_silk_top "PACKAGE GEOMETRY/SILKSCREEN_TOP")
	setq( _pg_silk_bot "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM")
	setq( _pg_silk_ls list( _pg_silk_top _pg_silk_bot))
	setq( _bg_silk_top "BOARD GEOMETRY/SILKSCREEN_TOP")
	setq( _bg_silk_bot "BOARD GEOMETRY/SILKSCREEN_BOTTOM")
	setq( _bg_silk_ls list( _bg_silk_top _bg_silk_bot))
	setq( _rd_silk_top "REF DES/SILKSCREEN_TOP")
	setq( _rd_silk_bot "REF DES/SILKSCREEN_BOTTOM")
	setq( _rd_silk_ls list( _rd_silk_top _rd_silk_bot))
	setq( _rd_bg_silk_ls list( _bg_silk_top _bg_silk_bot _rd_silk_top _rd_silk_bot))
	
	;;;; format for symbol
	;	"PACKAGE",R100
	;	"POSITION",symbol,layer,xy,rotation,mirrored
	;	"TEXT",text,textblock,layer,xy,justify,rotation,mirrored
	;	"LINE",layer,start_xy,end_xy,width
	;	"ARC",layer,start_xy,end_xy,width,center_xy,cw
	;	"end_of_package"
	
	;;;; format for board beometry/silkscreen
	;	"PACKAGE","BOARD GEOMETRY"
	;	"SHAPE","START",this_xy,layer
	;	"SHAPE","LINE",this_xy
	;	"SHAPE","ARC",this_xy,center_xy,cw
	;	"SHAPE","END"
	;	"SHAPE","START",this_xy,layer
	;	"SHAPE","LINE",this_xy
	;	"SHAPE","ARC",this_xy,center_xy,cw
	;	"VOID","START",this_xy,layer
	;	"VOID","LINE",this_xy
	;	"VOID","ARC",this_xy,center_xy,cw
	;	"VOID","END"
	;	"SHAPE","END"
	;	"TEXT",text,textblock,layer,xy,justify,rotation,mirrored
	;	"LINE",layer,start_xy,end_xy,width
	;	"ARC",layer,start_xy,end_xy,width,center_xy,cw
	;	"end_of_package"
	
	setq( _header_line_ls list( sprintf( nil "Project Name: %s" _allegro_design_name)
						sprintf( nil "Time: %s" getCurrentTime())
						sprintf( nil "Allegro version: %.2f" _allegro_version)
						""))
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_form_Derek07222019()
	prog( ( out_port form_width form_height button_width button_height button_x button_y )
		out_port = outfile( _form_filename "w")
		unless( check_value_Derek07222019( 'ArgErr 'write_form_Derek07222019 'out_port out_port '_v_outport) return( nil))
		;;
		
		form_width = 29
		form_height = 100
		
		button_width = 26
		button_height = 2
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" form_width form_height)
		fprintf( out_port "HEADER \"Gerber Package Selector\"\n")
		fprintf( out_port "TILE\n")
		
		button_x = 2
		button_y = 1
		
		fprintf( out_port "FIELD %s\n" _form_symbol_copy)
		fprintf( out_port "FLOC %d %d\n" button_x button_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "Store Symbol Location" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_y = button_y + button_height + 2
		
		fprintf( out_port "FIELD %s\n" _form_silkscreen_copy)
		fprintf( out_port "FLOC %d %d\n" button_x button_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "Store [Brd/Ref]/silkscreen" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_y = button_y + button_height + 2
		
		fprintf( out_port "FIELD %s\n" _form_paste)
		fprintf( out_port "FLOC %d %d\n" button_x button_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "Relocate Objective by CSV" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		button_y = button_y + button_height + 2
		
		fprintf( out_port "FIELD %s\n" _form_close)
		fprintf( out_port "FLOC %d %d\n" button_x button_y)
		fprintf( out_port "MENUBUTTON \"%s\" %d %d\n" "Close" button_width button_height)
		fprintf( out_port "ENDFIELD\n\n")
		
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		return( t)
	)
)

procedure( action_form_Derek07222019( out_form)
	prog( ( cur_field)
		unless( check_value_Derek07222019( 'ArgErr 'action_form 'out_form out_form '_v_form_objtype) return( nil))
		;;
		
		cur_field = out_form->curField
		
		cond(
			( equal( _form_symbol_copy cur_field)
				println( "INFO: action_form() - Store Symbol Location")
				_form_operate = _form_symbol_copy
				axlFormClose( out_form)
			)
			( equal( _form_silkscreen_copy cur_field)
				println( "INFO: action_form() - Store Board Geometry/silkscreen Location")
				_form_operate = _form_silkscreen_copy
				axlFormClose( out_form)
			)
			( equal( _form_paste cur_field)
				println( "INFO: action_form() - Relocate Symbol by last CSV")
				_form_operate = _form_paste
				axlFormClose( out_form)
			)
			( equal( _form_close cur_field)
				println( "INFO: action_form() - Close Form")
				_form_operate = _form_close
				axlFormClose( out_form)
			)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( popup_done_Derek07222019()
	_popup_command = _done
	axlFinishEnterFun()
)

procedure( popup_cancel_Derek07222019()
	_popup_command = _cancel
	axlCancelEnterFun()
)

procedure( select_parts_Derek07222019( obj_ls @optional (layers nil))
	prog( ( popup part_ls)
		unless( check_value_Derek07222019( 'ArgErr 'select_parts 'obj_ls obj_ls '_v_string_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'select_parts 'layers layers '_v_string_list_or_string) return( nil))
		when( stringp( layers) (layers = list( layers)))
		;;
		
		popup = axlUIPopupDefine( nil (list (list "Done" 'popup_done_Derek07222019) (list "Cancel" 'popup_cancel_Derek07222019)))
		
		;;;;
		opt_ls = append( list( "NOALL") obj_ls)
		axlSetFindFilter( ?enabled opt_ls ?onButtons opt_ls)
		axlUIPopupSet( popup)
		
		while( axlSelect()
			axlUIPopupSet( popup)
			part_ls = axlGetSelSet()
			
			;;;; remove via optimization
			part_ls = setof( x part_ls or( not( equal( _symbol x->objType)) dtpr( x->pins)))
			
			;;;; filter out by layer
			when( dtpr( layers)
				part_ls = setof( x part_ls member( x->layer layers))
			)
			;;
			axlSingleSelectObject( part_ls)
			printf( "INFO: select_parts() - Selected objective \n\t %L: [%d]\n" obj_ls length( part_ls))
		)
		axlUIPopupSet( nil)
		axlSetFindFilter( ?enabled list( "noall") ?onButtons list( "noall"))
		axlClearSelSet()
		
		;;;;
		when( eq( _cancel _popup_command) (part_ls = nil))
		
		return( part_ls)
	)
)

procedure( get_seg_contents_Derek07222019( seg_ls)
	;	LINE,start_xy,end_xy,width
	;	ARC,start_xy,end_xy,width,center_xy,cw
	prog( ( seg_id type start_xy end_xy width center_xy cw content log_lines line result)
		unless( check_value_Derek07222019( 'ArgErr 'get_path_contents 'seg_ls seg_ls '_v_seg_objtype_dtpr) return( nil))
		;;
		
		foreach( seg_id seg_ls
			type = seg_id->objType
			layer = seg_id->layer
			start_xy = car( seg_id->startEnd)
			end_xy = cadr( seg_id->startEnd)
			width = seg_id->width
			center_xy = seg_id->xy
			cw = seg_id->isClockwise
			
			when( dtpr( start_xy) sprintf( start_xy "%f %f" car( start_xy) cadr( start_xy)))
			when( dtpr( end_xy) sprintf( end_xy "%f %f" car( end_xy) cadr( end_xy)))
			when( dtpr( center_xy) sprintf( center_xy "%f %f" car( center_xy) cadr( center_xy)))
			when( numberp( width) sprintf( width "%f" width))
			when( booleanp( cw) (cw = if( cw _true _false)))
			
			;;
			content = nil
			cond(
				( equal( _line type)
					if( and( stringp( layer) stringp( start_xy) stringp( end_xy) stringp( width)) then
						content = list( type layer start_xy end_xy width)
					else
						sprintf( log_lines "ERROR: get_path_contents() - Missing [%s] data start_xy:%L end_xy:%L width:%f\n"
								type start_xy end_xy width)
						write_log_Derek07222019( _store_log_filename log_lines t)
					)
				)
				( equal( _arc type)
					if( and( stringp( layer) stringp( start_xy) stringp( end_xy) stringp( width) stringp( center_xy) stringp( cw)) then
						content = list( type layer start_xy end_xy width center_xy cw)
					else
						sprintf( log_lines "ERROR: get_path_contents() - Missing [%s] data start_xy:%L end_xy:%L width:%f center_xy:%L cw:%L\n"
								type start_xy end_xy width center_xy cw)
						write_log_Derek07222019( _store_log_filename log_lines t)
					)
				)
				( t
					sprintf( log_lines "ERROR: get_path_contents() - Fail to define type[%s] at %L\n" type center_xy)
					write_log_Derek07222019( _store_log_filename log_lines t)
				)
			)
			
			when( dtpr( content)
				line = buildString( content ",")
				result = append1( result line)
			)
		)
		
		return( result)
	)
)

procedure( get_text_contents_Derek07222019( refdes text_ls)
	; text_id = car( axlGetSelSet())
	; a = axlDBGetAttachedText( text_id)
	; car( setof( x axlDBGetDesign()->text equal( "J2" x->text)))
	prog( ( text_id text textblock layer xy justify rotation mirrored text_line_ls log_lines)
		unless( check_value_Derek07222019( 'ArgErr 'get_text_contents 'refdes refdes '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'get_text_contents 'text_ls text_ls '_v_text_objtype_dtpr) return( nil))
		;;
		
		foreach( text_id text_ls
			text = text_id->text
			textblock = text_id->textBlock
			layer = text_id->layer
			xy = text_id->xy
			justify = text_id->justify
			rotation = text_id->rotation
			mirrored = if( text_id->isMirrored _true _false)
			
			when( numberp( rotation) sprintf( rotation "%f" rotation))
			
			if( and( stringp( text) stringp( textblock) stringp( layer) dtpr( xy) stringp( justify) stringp( rotation) stringp( mirrored)) then
				sprintf( text_line "%s,\"%s\",%s,%s,%f %f,%s,%s,%s" _text text textblock layer car( xy) cadr( xy) justify rotation mirrored)
				text_line_ls = append1( text_line_ls text_line)
			else
				sprintf( log_lines "ERROR: get_text_contents() - Fail to get text from refdes[%s]\n\t text[%s] \n\t textblock[%s] \n\t layer[%s] \n\t xy[%L] \n\t justify[%s] \n\t rotation[%s] \n\t mirrored[%s]\n"
						refdes text textblock layer xy justify rotation mirrored)
				write_log_Derek07222019( _store_log_filename log_lines t)
			)
		)
		
		return( text_line_ls)
	)
)

procedure( get_shape_content_Derek07222019( shape_id tag_name)
	; shape_id = car( axlGetSelSet())
	;;; SHAPE,"START",this_xy,layer
	;;; SHAPE,"LINE",this_xy
	;;; SHAPE,"ARC",this_xy,center_xy,cw
	;;; SHAPE,"END"
	prog( ( shape_start shape_end void_start void_end line_ls layer seg_ls start_xy line void_ls void_id seg_line_ls)
		unless( check_value_Derek07222019( 'ArgErr 'get_shape_content 'shape_id shape_id '_v_shape_or_polygon_objtype) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'get_shape_content 'tag_name tag_name '_v_string) return( nil))
		;;
		
		fill = if( shape_id->fill _true _false)
		sprintf( shape_start "%s,%s,%s" _shape _start fill)
		sprintf( shape_end "%s,%s" _shape _end)
		sprintf( void_start "%s,%s" _void _start)
		sprintf( void_end "%s,%s" _void _end)
		layer = shape_id->layer
		
		;;;
		seg_ls = shape_id->segments
		seg_line_ls = get_seg_contents_Derek07222019( seg_ls)
		when( dtpr( seg_line_ls) (line_ls = append( line_ls seg_line_ls)))
		
		;;;
		void_ls = shape_id->voids
		foreach( void_id void_ls
			seg_ls = void_id->segments
			seg_line_ls = get_seg_contents_Derek07222019( seg_ls)
			when( dtpr( seg_line_ls)
				seg_line_ls = append( list( void_start) seg_line_ls)
				seg_line_ls = append1( seg_line_ls void_end)
				
				line_ls = append( line_ls seg_line_ls)
			)
		)
		
		;;;
		when( dtpr( line_ls)
			line_ls = append( list( shape_start) line_ls)
			line_ls = append1( line_ls shape_end)
		)
		
		return( line_ls)
	)
)

procedure( write_file_Derek07222019( filename contents)
	prog( ( out_port)
		unless( check_value_Derek07222019( 'ArgErr 'write_file 'filename filename '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'write_file 'contents contents '_v_string_dtpr_or_string) return( nil))
		unless( dtpr( contents) (contents = list( contents)))
		;;
		
		out_port = outfile( filename "w")
		unless( check_value_Derek07222019( 'ArgErr 'write_file 'out_port out_port '_v_outport) return( nil))
		
		foreach( line contents fprintf( out_port "%s\n" line))
		
		close( out_port)
		
		return( t)
	)
)

procedure( convert_symbol_position_data_Derek07222019( sym_ls)
	;; sym_id = car( axlGetSelSet())
	;	PACKAGE,R100
	;	POSITION,symbol,layer,xy,rotation,mirrored
	;	TEXT,text,textblock,layer,xy,justify,rotation,mirrored
	;	LINE,layer,start_xy,end_xy,width
	;	ARC,layer,start_xy,end_xy,width,center_xy,cw
	;	"end_of_package"
	prog( ( obj_ls sym_id head_line sym_line seg_line_ls refdes sym_name layer xy rotation mirrored
			text_ls text_line_ls seg_ls seg_line_ls line_ls contents log_lines)
		unless( check_value_Derek07222019( 'ArgErr 'convert_symbol_position_data 'sym_ls sym_ls '_v_symbol_objtype_dtpr) return( nil))
		;;
		
		foreach( sym_id sym_ls
			head_line = sym_line = text_line_ls = seg_line_ls = nil
			
			;;;; starting for a block
			refdes = sym_id->refdes
			when( stringp( refdes)
				head_line = strcat( _package "," refdes)
			)
			
			;;;; information of symbol
			sym_name = sym_id->name
			layer = car( car( sym_id->pins)->startEnd)
			xy = sym_id->xy
			rotation = sym_id->rotation
			mirrored = if( sym_id->isMirrored _true _false)
			when( and( stringp( sym_name) stringp( layer) dtpr( xy) numberp( rotation) stringp( mirrored))
				sprintf( sym_line "%s,%s,%s,%f %f,%f,%s" _position sym_name layer car( xy) cadr( xy) rotation mirrored)
			)
			
			;;;; information of attaced text
			text_ls = get_symbol_texts_Derek07222019( sym_id _pg_silk_ls)
			when( dtpr( text_ls) (text_line_ls = get_text_contents_Derek07222019( refdes text_ls)))
			
			;;;; information of each line/arc
			seg_ls = get_symbol_seg_Derek07222019( sym_id 'all)
			when( dtpr( seg_ls) (seg_line_ls = get_seg_contents_Derek07222019( seg_ls)))
			
			;;;; composition
			if( and( stringp( head_line) stringp( sym_line) listp( text_line_ls) listp( seg_line_ls)) then
				line_ls = append( append( list( head_line sym_line) text_line_ls) seg_line_ls)
				line_ls = append1( line_ls _package_end)
				contents = append( contents line_ls)
			else
				sprintf( log_lines "ERROR: create_position_data() - Fail to get complete data at %L\n\t head_line: %L \n\t sym_line: %L \n\t text_line_ls: %L \n\t seg_line_ls: %L\n"
						xy head_line sym_line text_line_ls seg_line_ls)
				write_log_Derek07222019( _store_log_filename log_lines t)
			)
		)
		
		
		return( contents)
	)
)

procedure( convert_silkscreen_position_data_Derek07222019( part_ls)
	;;; create position data for board geometry/silkscreen
	;	"PACKAGE","BOARD GEOMETRY"
	;	"TEXT",text,textblock,layer,xy,justify,rotation,mirrored
	;	"LINE",layer,start_xy,end_xy,width
	;	"ARC",layer,start_xy,end_xy,width,center_xy,cw
	;	"end_of_package"
	prog( ( obj_ls layer_clip text_ls shape_ls path_ls path_id seg_ls head_line
			shape_seg_line_ls shape_line_ls seg_line_ls text_line_lsline_ls contents)
		unless( check_value_Derek07222019( 'ArgErr 'convert_silkscreen_position_data 'part_ls part_ls '_v_dtpr) return( nil))
		;;
		
		;;;;
		text_ls = setof( x part_ls equal( _text x->objType))
		shape_ls = setof( x part_ls equal( _shape x->objType))
		path_ls = setof( x part_ls equal( _path x->objType))
		foreach( path_id path_ls (seg_ls = append( seg_ls path_id->segments)))
		
		;;;;
		when( or( dtpr( text_ls) dtpr( shape_ls) dtpr( seg_ls))
			head_line = strcat( _package "," _silkscreen)
			line_ls = list( head_line)
			
			;;;;
			when( dtpr( text_ls)
				text_line_ls = get_text_contents_Derek07222019( _silkscreen text_ls)
				line_ls = append( line_ls text_line_ls)
			)
			
			;;;;
			when( dtpr( seg_ls)
				seg_line_ls = get_seg_contents_Derek07222019( seg_ls)
				line_ls = append( line_ls seg_line_ls)
			)
			
			;;;;
			when( dtpr( shape_ls)
				foreach( shape_id shape_ls
					shape_seg_line_ls = get_shape_content_Derek07222019( shape_id _shape)
					shape_line_ls = append( shape_line_ls shape_seg_line_ls)
				)
				line_ls = append( line_ls shape_line_ls)
			)
			
			contents = append1( line_ls _package_end)
		)
		
		return( contents)
	)
)

procedure( read_pass_file_Derek07222019( file_addr)
	prog( ( in_port csv_line csv_ls contents temp_shape_contents temp_void_contents temp_contents refdes parts sym_name
			layer xy rotation mirrored parts text textblock justify start_xy end_xy width center_xy cw log_lines type)
		unless( check_value_Derek07222019( 'ArgErr 'read_pass_file 'file_addr file_addr '_v_filename) return( nil))
		;;
		
		in_port = infile( file_addr)
		unless( check_value_Derek07222019( 'ArgErr 'read_pass_file 'in_port in_port '_v_inport) return( nil))
		
		;;;;
		while( gets( csv_line in_port)
			csv_ls = axlStringCSVParse( csv_line)
			cond(
				( equal( _package_end car( csv_ls))
					when( dtpr( contents)
						if( equal( _silkscreen refdes)
							transform_silkscreen_data_Derek07222019( contents)
							transform_symbol_data_Derek07222019( refdes contents)
						)
					)
					contents = nil
				)
				( equal( _package car( csv_ls))
					refdes = nth( 1 csv_ls)
					parts = list( _package refdes)
					contents = list( parts)
				)
				( equal( _shape car( csv_ls))
					;;; shape,start,true
					;;; shape,end
					status = nth( 1 csv_ls)
					cond(
						( equal( _start status)
							fill = equal( _true nth( 2 csv_ls))
							temp_shape_contents = contents
						)
						( equal( _end status)
							temp_contents = nthcdr( length( temp_shape_contents) contents)
							temp_contents = append1( list( _shape fill) temp_contents)
							contents = append1( temp_shape_contents temp_contents)
						)
						( t
							sprintf( log_lines "ERROR: read_pass_file() - Yet to define status[%L] in shape\n" status)
							write_log_Derek07222019( _relocate_log_filename log_lines t)
						)
					)
				)
				( equal( _void car( csv_ls))
					;;; void,start
					;;; void,end
					status = nth( 1 csv_ls)
					cond(
						( equal( _start status)
							temp_void_contents = contents
						)
						( equal( _end status)
							temp_contents = nthcdr( length( temp_void_contents) contents)
							temp_contents = append1( list( _void) temp_contents)
							contents = append1( temp_void_contents temp_contents)
						)
						( t
							sprintf( log_lines "ERROR: read_pass_file() - Yet to define status[%L] in void\n" status)
							write_log_Derek07222019( _relocate_log_filename log_lines t)
						)
					)
				)
				( equal( _position car( csv_ls))
					;; [POSITION],symbol,layer,xy,rotation,mirrored
					sym_name = nth( 1 csv_ls)
					layer = nth( 2 csv_ls)
					xy = mapcar( 'atof parseString( nth( 3 csv_ls) " "))
					rotation = atof( nth( 4 csv_ls))
					mirrored = equal( _true nth( 5 csv_ls))
					
					parts = list( _position sym_name layer xy rotation mirrored)
					contents = append1( contents parts)
				)
				( equal( _text car( csv_ls))
					;; [TEXT],text,textblock,layer,xy,justify,rotation,mirrored
					text = nth( 1 csv_ls)
					textblock = nth( 2 csv_ls)
					layer = nth( 3 csv_ls)
					xy = mapcar( 'atof parseString( nth( 4 csv_ls) " "))
					justify = nth( 5 csv_ls)
					rotation = atof( nth( 6 csv_ls))
					mirrored = equal( _true nth( 7 csv_ls))
					
					parts = list( _text text textblock layer xy justify rotation mirrored)
					contents = append1( contents parts)
				)
				( equal( _line car( csv_ls))
					;; [LINE],layer,start_xy,end_xy,width
					layer = nth( 1 csv_ls)
					start_xy = mapcar( 'atof parseString( nth( 2 csv_ls) " "))
					end_xy = mapcar( 'atof parseString( nth( 3 csv_ls) " "))
					width = atof( nth( 4 csv_ls))
					
					parts = list( _line layer start_xy end_xy width)
					contents = append1( contents parts)
				)
				( equal( _arc car( csv_ls))
					;; [ARC],layer,start_xy,end_xy,width,center_xy,cw
					layer = nth( 1 csv_ls)
					start_xy = mapcar( 'atof parseString( nth( 2 csv_ls) " "))
					end_xy = mapcar( 'atof parseString( nth( 3 csv_ls) " "))
					width = atof( nth( 4 csv_ls))
					center_xy = mapcar( 'atof parseString( nth( 5 csv_ls) " "))
					cw = equal( _true nth( 6 csv_ls))
					
					parts = list( _arc layer start_xy end_xy width center_xy cw)
					contents = append1( contents parts)
				)
				( t
					sprintf( log_lines "ERROR: read_pass_file() - Yet to define type[%s] in csv file\n" car( csv_ls))
					write_log_Derek07222019( _relocate_log_filename log_lines t)
					contents = nil
				)
			)
		)
		close( in_port)
		
		return( t)
	)
)

procedure( transform_objective_Derek07222019( obj_name obj_id data_xy data_rotation data_mirrored)
	;; position,[sym name],[layer],[xy],[rotation],[mirrored]
	prog( ( data_sym_name data_layer sym_layer sym_xy type
			sym_rotation sym_mirrored move_xy mirrored angle)
		unless( check_value_Derek07222019( 'ArgErr 'transform_symbol 'obj_name obj_name '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'transform_symbol 'obj_id obj_id '_v_dbid) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'transform_symbol 'data_xy data_xy '_v_xy) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'transform_symbol 'data_rotation data_rotation '_v_number) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'transform_symbol 'data_mirrored data_mirrored '_v_bool) return( nil))
		;;
		
		;;;; mirrored first
		type = obj_id->objType
		cond(
			( equal( _symbol type)
				mirrored = obj_id->isMirrored
				mirrored = not( eq( data_mirrored mirrored))
				when( mirrored
					axlDBCloak( 'axlTransformObject( obj_id ?mirror mirrored) 'shape)
				)
			)
			( equal( _text type)
				;;;; do not mirror text. use axlchangetext instead
			)
			( t
				printf( "ERROR: transform_objective() - Yet to define type[%s]\n" type)
			)
		)
		
		
		;;;; rotate second
		sym_rotation = obj_id->rotation
		angle = data_rotation - sym_rotation
		unless( zerop( angle)
			axlDBCloak( 'axlTransformObject( obj_id ?angle angle ?origin data_xy) 'shape)
		)
		
		;;;; move third
		sym_xy = obj_id->xy
		move_xy = axlMXYSub( data_xy sym_xy)
		unless( axlGeoPointsEqual( 0:0 move_xy)
			axlDBCloak( 'axlTransformObject( obj_id ?move move_xy) 'shape)
		)
		
		unless( and( axlGeoPointsEqual( 0:0 move_xy) zerop( angle) not( mirrored))
			axlHighlightObject( obj_id)
			sprintf( log_lines "UPDATE: transform_symbol() - Transform [%s]\tmove[%L]\trotate[%f]\tmirrored[%L]"
					obj_name move_xy angle mirrored)
			write_log_Derek07222019( _relocate_log_filename log_lines)
		)
		
		return( t)
	)
)

procedure( get_symbol_seg_Derek07222019( sym_id option)
	;; sym_id = car( axlGetSelSet())
	prog( ( path_ls seg_ls result)
		unless( check_value_Derek07222019( 'ArgErr 'get_symbol_path 'sym_id sym_id '_v_symbol_objtype) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'get_symbol_path 'option option '_v_symbol) return( nil))
		;;
		
		path_ls = setof( x sym_id->children and( equal( _path x->objType) member( x->layer _pg_silk_ls)))
		foreach( path_id path_ls (seg_ls = append( seg_ls path_id->segments)))
		
		caseq( option
			( 'all
				result = seg_ls
			)
			( 'line
				result = setof( x seg_ls equal( _line x->objType))
			)
			( 'arc
				result = setof( x seg_ls equal( _arc x->objType))
			)
			( t
				printf( "ERROR: get_symbol_path() - Yet to define path type[%s]\n" option)
				result = nil
			)
		)
		
		return( result)
	)
)

procedure( compare_xy_Derek07222019( xy1 xy2)
	prog( ( x1 y1 x2 y2)
		unless( check_value_Derek07222019( 'ArgErr 'compare_xy 'xy1 xy1 '_v_xy) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'compare_xy 'xy2 xy2 '_v_xy) return( nil))
		when( axlGeoPointsEqual( xy1 xy2) return( nil))
		;;
		
		x1 = car( xy1)
		y1 = cadr( xy1)
		radius1_p2 = x1**2 + y1**2
		
		x2 = car( xy2)
		y2 = cadr( xy2)
		radius2_p2 = x2**2 + y2**2
		
		cond(
			( (radius1_p2 < radius2_p2) return( t))
			( (radius1_p2 > radius2_p2) return( nil))
			( t
				cond(
					( (x1 < x2) return( t))
					( (x1 > x2) return( nil))
					( t
						cond(
							( (y1 < y2) return( t))
							( (y1 > y2) return( nil))
						)
					)
				)
			)
		)
		
		return( nil)
	)
)

procedure( is_same_dtpr_Derek07222019( a_ls b_ls comp_func)
	prog( ( result_ls result)
		unless( and( dtpr( a_ls) dtpr( b_ls)) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_same_dtpr 'a_ls a_ls '_v_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_same_dtpr 'b_ls b_ls '_v_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_same_dtpr 'comp_func comp_func '_v_symbol) return( nil))
		unless( eqv( length( a_ls) length( b_ls)) return( nil))
		;;
		
		foreach( ( a b) a_ls b_ls
			result = funcall( comp_func a b)
			result_ls = append1( result_ls result)
		)
		
		result = forall( x result_ls x)
		
		return( result)
	)
)

procedure( is_modified_seg_Derek07222019( seg_ls line_data_ls arc_data_ls @optional (refdes nil))
	;	LINE,layer,start_xy,end_xy,width
	;	ARC,layer,start_xy,end_xy,width,center_xy,cw
	prog( ( refdes_term line_ls arc_ls line_num arc_num line_data_num arc_data_num line_content_ls
			line_data_content_ls arc_content_ls arc_data_content_ls result log_lines)
		unless( or( dtpr( seg_ls) dtpr( line_data_ls) dtpr( arc_data_ls)) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_modified_seg 'seg_ls seg_ls '_v_seg_objtype_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_modified_seg 'line_data_ls line_data_ls '_v_list) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_modified_seg 'arc_data_ls arc_data_ls '_v_list) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_modified_seg 'refdes refdes '_v_string_or_nil) return( nil))
		;;
		
		;;;;
		line_ls = setof( x seg_ls equal( _line x->objType))
		arc_ls = setof( x seg_ls equal( _arc x->objType))
		
		refdes_term = if( stringp( refdes) sprintf( nil " at refdes[%s]" refdes) "")
		
		;;;; checke the total number of segments
		line_num = length( line_ls)
		arc_num = length( arc_ls)
		line_data_num = length( line_data_ls)
		arc_data_num = length( arc_data_ls)
		unless( and( eqv( line_num line_data_num) eqv( arc_num arc_data_num))
			sprintf( log_lines "INFO: is_modified_seg() - segment count - line_num[%d] line_data_num[%d] arc_num[%d] arc_data_num[%d]%s"
					line_num line_data_num arc_num arc_data_num refdes_term)
			write_log_Derek07222019( _relocate_log_filename log_lines)
			return( t)
		)
		
		;;;; check xy of the line
		line_content_ls = mapcan( lambda( (x) x->startEnd) line_ls)
		line_data_content_ls = mapcan( lambda( (x) list( nth( 2 x) nth( 3 x))) line_data_ls)
		when( and( dtpr( line_content_ls) dtpr( line_data_content_ls))
			line_content_ls = sort( line_content_ls 'compare_xy_Derek07222019)
			line_data_content_ls = sort( line_data_content_ls 'compare_xy_Derek07222019)
			
			result = is_same_dtpr_Derek07222019( line_content_ls line_data_content_ls 'axlGeoPointsEqual)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - line segment xy -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						line_content_ls line_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		;;;; check xy of the line
		arc_content_ls = mapcan( lambda( (x) x->startEnd) arc_ls)
		arc_data_content_ls = mapcan( lambda( (x) list( nth( 2 x) nth( 3 x))) arc_data_ls)
		when( and( dtpr( arc_content_ls) dtpr( arc_data_content_ls))
			arc_content_ls = sort( arc_content_ls 'compare_xy_Derek07222019)
			arc_data_content_ls = sort( arc_data_content_ls 'compare_xy_Derek07222019)
			
			result = is_same_dtpr_Derek07222019( arc_content_ls arc_data_content_ls 'axlGeoPointsEqual)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - arc segment xy -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						arc_content_ls arc_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		;;;; compare layer composition
		line_content_ls = mapcar( lambda( (x) x->layer) line_ls)
		line_data_content_ls = mapcar( lambda( (x) cadr( x)) line_data_ls)
		when( and( dtpr( line_content_ls) dtpr( line_data_content_ls))
			line_content_ls = sort( line_content_ls 'alphalessp)
			line_data_content_ls = sort( line_data_content_ls 'alphalessp)
			
			result = is_same_dtpr_Derek07222019( line_content_ls line_data_content_ls 'equal)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - line sorted layer -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						line_content_ls line_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		arc_content_ls = mapcar( lambda( (x) x->layer) arc_ls)
		arc_data_content_ls = mapcar( lambda( (x) cadr( x)) arc_data_ls)
		when( and( dtpr( arc_content_ls) dtpr( arc_data_content_ls))
			arc_content_ls = sort( arc_content_ls 'alphalessp)
			arc_data_content_ls = sort( arc_data_content_ls 'alphalessp)
			
			result = is_same_dtpr_Derek07222019( arc_content_ls arc_data_content_ls 'equal)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - arc sorted layer -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						arc_content_ls arc_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		;;;; compare width
		line_content_ls = mapcar( lambda( (x) x->width) line_ls)
		line_data_content_ls = mapcar( lambda( (x) nth( 4 x)) line_data_ls)
		when( and( dtpr( line_content_ls) dtpr( line_data_content_ls))
			line_content_ls = sort( line_content_ls 'lessp)
			line_data_content_ls = sort( line_data_content_ls 'lessp)
			
			result = is_same_dtpr_Derek07222019( line_content_ls line_data_content_ls 'axlGeoEqual)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - line sorted width -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						line_content_ls line_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		arc_content_ls = mapcar( lambda( (x) x->width) arc_ls)
		arc_data_content_ls = mapcar( lambda( (x) nth( 4 x)) arc_data_ls)
		when( and( dtpr( arc_content_ls) dtpr( arc_data_content_ls))
			arc_content_ls = sort( arc_content_ls 'lessp)
			arc_data_content_ls = sort( arc_data_content_ls 'lessp)
			
			result = is_same_dtpr_Derek07222019( arc_content_ls arc_data_content_ls 'axlGeoEqual)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - arc sorted width -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						arc_content_ls arc_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		;;;; compare center_xy
		arc_content_ls = mapcar( lambda( (x) x->xy) arc_ls)
		arc_data_content_ls = mapcar( lambda( (x) nth( 5 x)) arc_data_ls)
		when( and( dtpr( arc_content_ls) dtpr( arc_data_content_ls))
			arc_content_ls = sort( arc_content_ls 'compare_xy_Derek07222019)
			arc_data_content_ls = sort( arc_data_content_ls 'compare_xy_Derek07222019)
			
			result = is_same_dtpr_Derek07222019( arc_content_ls arc_data_content_ls 'axlGeoPointsEqual)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - arc sorted center_xy -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						arc_content_ls arc_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		;;;; compare clockwise
		arc_content_ls = mapcar( lambda( (x) x->isClockwise) arc_ls)
		arc_data_content_ls = mapcar( lambda( (x) nth( 6 x)) arc_data_ls)
		when( and( dtpr( arc_content_ls) dtpr( arc_data_content_ls))
			arc_content_ls = sort( arc_content_ls lambda( (a b) null( a)))
			arc_data_content_ls = sort( arc_data_content_ls lambda( (a b) null( a)))
			
			result = is_same_dtpr_Derek07222019( arc_content_ls arc_data_content_ls 'eq)
			unless( result
				sprintf( log_lines "INFO: is_modified_seg() - arc sorted clockwise -\n\tline_content_ls[%L]\n\tline_data_content_ls[%L]%s"
						arc_content_ls arc_data_content_ls refdes_term)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( t)
			)
		)
		
		return( nil)
	)
)

procedure( create_path_util_Derek07222019( path end_xy layer width @optional (center_xy nil) (cw nil))
	prog( ()
		unless( check_value_Derek07222019( 'ArgErr 'create_path 'path path '_v_path_objtype) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_path 'end_xy end_xy '_v_xy) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_path 'layer layer '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_path 'width width '_v_number) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_path 'center_xy center_xy '_v_xy_or_nil) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_path 'cw cw '_v_bool) return( nil))
		;;
		
		if( dtpr( center_xy) then
			axlPathArcCenter( path width end_xy cw center_xy)
		else
			axlPathLine( path width end_xy)
		)
		
		return( path)
	)
)

procedure( create_path_Derek07222019( sym_id start_xy end_xy layer width @optional (center_xy nil) (cw nil))
	prog( ( path path_ls status status_term refdes_term log_lines result)
		unless( check_value_Derek07222019( 'ArgErr 'create_seg 'sym_id sym_id '_v_symbol_objtype_or_nil) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_seg 'start_xy start_xy '_v_xy) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_seg 'end_xy end_xy '_v_xy) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_seg 'layer layer '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_seg 'width width '_v_number) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_seg 'center_xy center_xy '_v_xy_or_nil) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_seg 'cw cw '_v_bool) return( nil))
		;;
		
		;;;;
		path = axlPathStart( list( start_xy))
		path = create_path_util_Derek07222019( path end_xy layer width center_xy cw)
		result = axlDBCreatePath( path layer)
		path_ls = car( result)
		when( and( sym_id dtpr( path_ls)) axlSymbolAttach( sym_id path_ls))
		
		;;;;
		status = dtpr( path_ls)
		when( and( status sym_id) axlHighlightObject( sym_id))
		status_term = if( status "UPDATE" "ERROR")
		refdes_term = if( sym_id sprintf( nil " on refdes[%s]" sym_id->refdes) "")
		
		sprintf( log_lines "%s: create_seg() - create segment%s from %L to %L" status_term refdes_term start_xy end_xy)
		write_log_Derek07222019( _relocate_log_filename log_lines null( status))
		
		
		return( path_ls)
	)
)

procedure( progress_symbol_silk_Derek07222019( refdes sym_id line_data_ls arc_data_ls)
	; sym_id = car( axlGetSelSet())
	;	LINE,layer,start_xy,end_xy,width
	;	ARC,layer,start_xy,end_xy,width,center_xy,cw
	prog( ( seg_id seg_ls line_data layer start_xy end_xy width result path log_lines)
		unless( check_value_Derek07222019( 'ArgErr 'progress_symbol_silk 'refdes refdes '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'progress_symbol_silk 'sym_id sym_id '_v_symbol_objtype) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'progress_symbol_silk 'line_data_ls line_data_ls '_v_list) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'progress_symbol_silk 'arc_data_ls arc_data_ls '_v_list) return( nil))
		;;
		
		;;;;
		seg_ls = get_symbol_seg_Derek07222019( sym_id 'all)
		when( is_modified_seg_Derek07222019( seg_ls line_data_ls arc_data_ls refdes)
			sprintf( log_lines "UPDATE: progress_symbol_silk() - Creating path on refdes[%s]" refdes)
			write_log_Derek07222019( _relocate_log_filename log_lines)
			
			;;;; remove path from origin symbol
			foreach( seg_id seg_ls axlDeleteObject( seg_id))
		
			;;;; create line silkscreen
			foreach( line_data line_data_ls
				layer = nth( 1 line_data)
				start_xy = nth( 2 line_data)
				end_xy = nth( 3 line_data)
				width = nth( 4 line_data)
				
				result = create_path_Derek07222019( sym_id start_xy end_xy layer width)
			)
			
			;;;; create arc silkscreen
			foreach( arc_data arc_data_ls
				layer = nth( 1 arc_data)
				start_xy = nth( 2 arc_data)
				end_xy = nth( 3 arc_data)
				width = nth( 4 arc_data)
				center_xy = nth( 5 arc_data)
				cw = nth( 6 arc_data)
				
				result = create_path_Derek07222019( sym_id start_xy end_xy layer width center_xy cw)
			)
		)
		
		return( t)
	)
)

procedure( get_symbol_texts_Derek07222019( sym_id layer_ls)
	prog( ( text_ls)
		unless( check_value_Derek07222019( 'ArgErr 'get_symbol_texts 'sym_id sym_id '_v_symbol_objtype) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'get_symbol_texts 'layer_ls layer_ls '_v_string_dtpr) return( nil))
		;;
		
		text_ls = setof( x sym_id->children and( equal( _text x->objType) member( x->layer layer_ls)))
		
		return( text_ls)
	)
)

procedure( create_symbol_Derek07222019( refdes position_data)
	;; position,[sym name],[layer],[xy],[rotation],[mirrored]
	prog( ( sym_name layer xy rotation mirrored result sym_id log_lines)
		unless( check_value_Derek07222019( 'ArgErr 'create_symbol 'refdes refdes '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_symbol 'position_data position_data '_v_dtpr) return( nil))
		;;
		
		sym_name = nth( 1 position_data)
		layer = nth( 2 position_data)
		xy = nth( 3 position_data)
		rotation = nth( 4 position_data)
		mirrored = nth( 5 position_data)
		
		result = axlDBCreateSymbol( refdes xy mirrored rotation)
		if( cadr( result) then
			sprintf( log_lines "ERROR: create_symbol() - Fail to create refdes[%s]" refdes)
			write_log_Derek07222019( _relocate_log_filename log_lines t)
		else
			sprintf( log_lines "UPDATE: create_symbol() - Create refdes[%s]\txy[%L]\trotate[%f]\tmirrored[%L]"
					refdes xy rotation mirrored)
			write_log_Derek07222019( _relocate_log_filename log_lines)
			sym_id = car( result)
			
			axlHighlightObject( sym_id)
		)
		
		
		return( sym_id)
	)
)

procedure( transform_symbol_data_Derek07222019( refdes contents)
	;; sym_id = car( axlGetSelSet())
	;	PACKAGE,R100
	;	POSITION,symbol,layer,xy,rotation,mirrored
	;	TEXT,text,textblock,layer,xy,justify,rotation,mirrored
	;	LINE,layer,start_xy,end_xy,width
	;	ARC,layer,start_xy,end_xy,width,center_xy,cw
	prog( ( data_refdes sym_id sym_name data_sym_name position_data text_data_ls line_data_ls arc_data_ls
			data_xy data_rotation data_mirrored log_lines text_ls)
		unless( check_value_Derek07222019( 'ArgErr 'transform_position_data 'refdes refdes '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'transform_position_data 'contents contents '_v_dtpr) return( nil))
		;;
		
		;;;;
		position_data = car( setof( x contents equal( _position car( x))))
		text_data_ls = setof( x contents equal( _text car( x)))
		line_data_ls = setof( x contents equal( _line car( x)))
		arc_data_ls = setof( x contents equal( _arc car( x)))
		
		;;;;
		sym_id = axlDBFindByName( 'refdes refdes)->symbol
		
		;;;; if no refdes found, then create one
		unless( sym_id (sym_id = create_symbol_Derek07222019( refdes position_data)))
		
		;;;;
		sym_name = sym_id->name
		data_sym_name = nth( 1 position_data)
		
		;;;; transform symbol
		if( and( sym_id equal( data_sym_name sym_name)) then
			;;;; transform the symbol
			data_xy = nth( 3 position_data)
			data_rotation = nth( 4 position_data)
			data_mirrored = nth( 5 position_data)
			transform_objective_Derek07222019( refdes sym_id data_xy data_rotation data_mirrored)
			
			;;;; recreate line and arc
			when( or( dtpr( line_data_ls) dtpr( arc_data_ls))
				progress_symbol_silk_Derek07222019( refdes sym_id line_data_ls arc_data_ls)
			)
			
			;;;; place text on it
			when( dtpr( text_data_ls)
				text_ls = get_symbol_texts_Derek07222019( sym_id _pg_silk_ls)
				progress_text_Derek07222019( text_ls text_data_ls sym_id)
			)
		else
			sprintf( log_lines "ERROR: transform_position_data() - Fail to create refdes[%s] or different symbols between brd[%L] and file[%L] under same refdes\n"
					refdes sym_name data_sym_name)
			write_log_Derek07222019( _relocate_log_filename log_lines t)
		)
		
		return( t)
	)
)

procedure( compare_text_layer_xy_Derek07222019( tlxy1 tlxy2)
	;;; text,"E",1,BOARD GEOMETRY/SILKSCREEN_BOTTOM,1567.000000 4207.000000,LEFT,0.000000,true
	prog( ( text1 text2 layer1 layer2 xy1 xy2)
		unless( check_value_Derek07222019( 'ArgErr 'compare_text_xy 'tlxy1 tlxy1 '_v_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'compare_text_xy 'tlxy2 tlxy2 '_v_dtpr) return( nil))
		;;
		
		text1 = car( tlxy1)
		text2 = car( tlxy2)
		layer1 = cadr( tlxy1)
		layer2 = cadr( tlxy2)
		xy1 = caddr( tlxy1)
		xy2 = caddr( tlxy2)
		
		;;;;
		if( equal( text1 text2) then
			if( equal( layer1 layer2)
				result = compare_xy_Derek07222019( xy1 xy2)
				result = alphalessp( layer1 layer2)
			)
		else
			result = alphalessp( text1 text2)
		)
		
		return( result)
	)
)


procedure( is_same_text_orient_Derek07222019( text_id textblock justify rotation mirrored)
	prog( ( result)
		unless( check_value_Derek07222019( 'ArgErr 'is_same_text_orient 'text_id text_id '_v_text_objtype) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_same_text_orient 'textblock textblock '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_same_text_orient 'justify justify '_v_string) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_same_text_orient 'rotation rotation '_v_number) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'is_same_text_orient 'mirrored mirrored '_v_bool) return( nil))
		;;
		
		result = and( equal( justify text_id->justify)
						axlGeoEqual( rotation text_id->rotation)
						eq( mirrored text_id->isMirrored)
						equal( textblock text_id->textBlock))
		
		return( result)
	)
)

procedure( progress_text_Derek07222019( text_ls text_data_ls @optional (sym_id nil))
	;;; "TEXT",text,textblock,layer,xy,justify,rotation,mirrored
	prog( ( refdes_term tlxy_text_ls tlxy_text_data_ls text_id text_data text textblock layer xy justify rotation mirrored orient
			this_sym_id log_lines result)
		unless( check_value_Derek07222019( 'ArgErr 'create_text 'text_ls text_ls '_v_text_objtype_list) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_text 'text_data_ls text_data_ls '_v_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'create_text 'sym_id sym_id '_v_symbol_objtype_or_nil) return( nil))
		;;
		
		refdes_term = if( sym_id sprintf( nil " refdes[%s]" sym_id->refdes) "")
		
		;;;; take text and xy to the front for sorting
		tlxy_text_ls = mapcar( lambda( (x) list( list( x->text x->layer x->xy) x)) text_ls)
		tlxy_text_data_ls = mapcar( lambda( (x) list( list( nth( 1 x) nth( 3 x) nth( 4 x)) x)) text_data_ls)
		
		;;;; sorting and remove the keys
		tlxy_text_ls = sortcar( tlxy_text_ls 'compare_text_layer_xy_Derek07222019)
		tlxy_text_data_ls = sortcar( tlxy_text_data_ls 'compare_text_layer_xy_Derek07222019)
		
		text_ls = mapcar( 'cadr tlxy_text_ls)
		text_data_ls = mapcar( 'cadr tlxy_text_data_ls)
		
		;;;;
		while( or( dtpr( text_ls) dtpr( text_data_ls))
			;;;; do one thing at a time
			text_id = car( text_ls)
			text_data = car( text_data_ls)
			
			text = nth( 1 text_data)
			textblock = nth( 2 text_data)
			layer = nth( 3 text_data)
			xy = nth( 4 text_data)
			justify = nth( 5 text_data)
			rotation = nth( 6 text_data)
			mirrored = nth( 7 text_data)
			
			orient = make_axlTextOrientation( ?textBlock textblock ?rotation rotation ?mirrored mirrored ?justify justify)
			cond(
				( equal( text text_id->text)
					;;;; change orient or move the text_id by text_data
					
					unless( equal( layer text_id->layer)
						axlDBCloak( 'axlChangeLayer( text_id layer))
						sprintf( log_lines "UPDATE: progress_text() - Change layer -%s text[%s] layer[%s] xy[%L]" refdes_term text layer xy)
						write_log_Derek07222019( _relocate_log_filename log_lines)
						
						axlHighlightObject( text_id)
					)
					
					unless( is_same_text_orient_Derek07222019( text_id textblock justify rotation mirrored)
						axlDBCloak( 'axlDBChangeText( text_id text orient))
						sprintf( log_lines "UPDATE: progress_text() - Change orientation -%s text[%s] layer[%s] xy[%L] textblock[%s] rotation[%.1f] mirrored[%L] justify[%s]"
								refdes_term text layer xy textblock rotation mirrored justify)
						write_log_Derek07222019( _relocate_log_filename log_lines)
						
						axlHighlightObject( text_id)
					)
					
					transform_objective_Derek07222019( strcat( text " (text)") text_id xy rotation nil)
					
					;;;; iterator
					text_ls = cdr( text_ls)
					text_data_ls = cdr( text_data_ls)
				)
				( or( and( stringp( text) stringp( text_id->text) alphalessp( text text_id->text)) and( null( text_id) text))
					;;;; no chance to find text_id by text_data in subsequence. create text_data anyway
					
					sprintf( log_lines "UPDATE: progress_text() - Create -%s text_data[%s] on layer[%s] at [%L]" refdes_term text layer xy)
					write_log_Derek07222019( _relocate_log_filename log_lines)
					
					if( sym_id then
						result = axlDBCloak( 'axlDBCreateText( text xy orient layer sym_id))
					else
						;;;; under the silkscreen mode, give text a parent if the text is the name of the refdes
						this_sym_id = axlDBFindByName( 'refdes text)->symbol
						result = axlDBCloak( 'axlDBCreateText( text xy orient layer this_sym_id))
					)
					axlHighlightObject( car( result))
					
					;;;; iterator
					text_data_ls = cdr( text_data_ls)
				)
				( or( and( stringp( text) stringp( text_id->text) alphalessp( text_id->text text)) and( text_id null( text)))
					;;;; there might be a chance the current text_data could fit to the next text_id. Therefore, remove current text_id
					;;; don't care the text on board geometry(silkscreen) because the text pool is in common
					
					when( sym_id
						sprintf( log_lines "UPDATE: progress_text() - remove -%s text_id[%s] on layer[%s] at [%L]" refdes_term text_id->text text_id->layer text_id->xy)
						write_log_Derek07222019( _relocate_log_filename log_lines)
						
						axlDBCloak( 'axlDeleteObject( text_id))
					)
					
					;;;; iterator
					text_ls = cdr( text_ls)
				)
				( t
					sprintf( log_lines "ERROR: progress_text() - Fail to define\n\ttext_id: %L\n\ttext_data: %L" text_id->?? text_data)
					write_log_Derek07222019( _relocate_log_filename log_lines)
				)
			)
		)
		
		return( t)
	)
)

procedure( select_obj_on_layers_Derek07222019( opt_ls layers)
	prog( ( obj_ls)
		unless( check_value_Derek07222019( 'ArgErr 'select_obj_on_layers 'opt_ls opt_ls '_v_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'select_obj_on_layers 'layers layers '_v_string_dtpr_or_string) return( nil))
		unless( dtpr( layers) (layers = list( layers)))
		;;
		
		axlVisibleDesign( nil)
		foreach( layer layers axlVisibleLayer( layer t))
		
		opt_ls = append( list( "NOALL") opt_ls)
		axlSetFindFilter( ?enabled opt_ls ?onButtons opt_ls)
		axlAddSelectAll()
		obj_ls = axlGetSelSet()
		axlClearSelSet()
		
		obj_ls = setof( x obj_ls member( x->layer layers))
		
		return( obj_ls)
	)
)

procedure( exists_segment_overlap_Derek07222019( seg_ls start_xy end_xy layer @optional (center_xy nil) (cw nil))
	prog( ( seg_id seg_start_xy seg_end_xy seg_layer seg_center_xy seg_cw result status log_lines)
		
		while( and( null( result) dtpr( seg_ls))
			seg_id = car( seg_ls)
			seg_start_xy = car( seg_id->startEnd)
			seg_end_xy = cadr( seg_id->startEnd)
			seg_layer = seg_id->layer
			seg_center_xy = seg_id->xy
			seg_cw = seg_id->isClockwise
			
			when( and( or( and( axlGeoPointsEqual( seg_start_xy start_xy) axlGeoPointsEqual( seg_end_xy end_xy))
							and( axlGeoPointsEqual( seg_end_xy start_xy) axlGeoPointsEqual( seg_start_xy end_xy)))
						equal( seg_layer layer)
						or( not( or( seg_center_xy center_xy))
							and( dtpr( seg_center_xy) dtpr( center_xy) axlGeoPointsEqual( seg_center_xy center_xy)))
						eq( seg_cw cw))
			
				result = seg_id
			)
			
			seg_ls = cdr( seg_ls)
		)
		
		when( result
			status = if( dtpr( center_xy) _arc _line)
			sprintf( log_lines "Info: exists_segment_overlap() - Exists segment[%s] on layer[%s] from %L to %L" status layer start_xy end_xy)
			write_log_Derek07222019( _relocate_log_filename log_lines)
		)
		
		return( result)
	)
)

procedure( progress_silk_Derek07222019( line_data_ls arc_data_ls)
	;;;; this function can't be merged with package geometry one since the silkscreen in symbol is absolute but it's not on board
	;;;; otherwise, no silkscreen on board geometry will be removed
	;	"LINE",layer,start_xy,end_xy,width
	;	"ARC",layer,start_xy,end_xy,width,center_xy,cw
	prog( ( opt_ls seg_ls line_ls arc_ls line_data layer start_xy end_xy width seg_id center_xy cw result)
		unless( check_value_Derek07222019( 'ArgErr 'progress_silk 'line_data_ls line_data_ls '_v_list) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'progress_silk 'arc_data_ls arc_data_ls '_v_list) return( nil))
		;;
		
		;;;; select all segments from board geometry
		opt_ls = list( "LINESEGS")
		seg_ls = select_obj_on_layers_Derek07222019( opt_ls _bg_silk_ls)
		line_ls = setof( x seg_ls equal( _line x->objType))
		arc_ls = setof( x seg_ls equal( _arc x->objType))
		
		;;;; create line segments if it's not exists
		foreach( line_data line_data_ls
			layer = nth( 1 line_data)
			start_xy = nth( 2 line_data)
			end_xy = nth( 3 line_data)
			width = nth( 4 line_data)
			
			seg_id = exists_segment_overlap_Derek07222019( line_ls start_xy end_xy layer)
			when( seg_id (line_ls = remq( seg_id line_ls)))
			
			when( and( seg_id not( axlGeoEqual( width seg_id->width)))
				sprintf( log_lines "UPDATE: progress_silk() - Remove seg[line] by width[%f] from %L to %L on layer[%s]" width start_xy end_xy layer)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				
				axlDBCloak( 'axlDeleteObject( seg_id))
				seg_id = nil
			)
			unless( seg_id
				result = create_path_Derek07222019( nil start_xy end_xy layer width)
			)
		)
		
		;;;; create arc segments if it's not exists
		foreach( arc_data arc_data_ls
			layer = nth( 1 arc_data)
			start_xy = nth( 2 arc_data)
			end_xy = nth( 3 arc_data)
			width = nth( 4 arc_data)
			center_xy = nth( 5 arc_data)
			cw =  nth( 6 arc_data)
			
			seg_id = exists_segment_overlap_Derek07222019( arc_ls start_xy end_xy layer center_xy cw)
			when( seg_id (arc_ls = remq( seg_id arc_ls)))
			
			when( and( seg_id not( axlGeoEqual( width seg_id->width)))
				sprintf( log_lines "UPDATE: progress_silk() - Remove seg[arg] by width[%f] from %L to %L on layer[%s]" width start_xy end_xy layer)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				
				axlDBCloak( 'axlDeleteObject( seg_id))
				seg_id = nil
			)
			unless( seg_id
				result = create_path_Derek07222019( nil start_xy end_xy layer width center_xy cw)
			)
		)
		
		return( t)
	)
)

procedure( exists_shape_inbox_Derek07222019( shape_ls shape_data type)
	;	("shape" fill (("LINE",layer,start_xy,end_xy,width) ("ARC",layer,start_xy,end_xy,width,center_xy,cw)
	;		("void" (("LINE",layer,start_xy,end_xy,width) ("ARC",layer,start_xy,end_xy,width,center_xy,cw)))))	
	prog( (layer line_arc_void_data_ls lin_arc_data_ls line_data_ls arc_data_ls xy_ls void_data_ls shape_id box
			xy shape_inbox_ls shape_seg_ls void_seg_ls void_ls tar_shape_id result line log_lines)
		unless( or( dtpr( shape_ls) dtpr( shape_data)) return( t))
		unless( check_value_Derek07222019( 'ArgErr 'exists_shape_inbox 'shape_ls shape_ls '_v_shape_or_polygon_objtype_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'exists_shape_inbox 'shape_data shape_data '_v_dtpr) return( nil))
		unless( check_value_Derek07222019( 'ArgErr 'exists_shape_inbox 'type type '_v_symbol) return( nil))
		;;
		
		layer = car( shape_ls)->layer
		
		cond(
			( eq( 'shape type)
				line_arc_void_data_ls = caddr( shape_data)
			)
			( eq( 'void type)
				line_arc_void_data_ls = shape_data
			)
			( t
				sprintf( log_lines "ERROR: exists_shape_inbox() - Yet to define type[%s] for getting line_arc_void_data_ls" type)
				write_log_Derek07222019( _relocate_log_filename log_lines)
				return( nil)
			)
		)
		
		
		;;;; get shape data
		
		lin_arc_data_ls = setof( x line_arc_void_data_ls not( equal( _void car( x))))
		
		line_data_ls = setof( x lin_arc_data_ls equal( _line car( x)))
		arc_data_ls = setof( x lin_arc_data_ls equal( _arc car( x)))
		xy_ls = mapcar( lambda( (x) caddr( x)) lin_arc_data_ls)
		
		;;;; get void data
		void_data_ls = setof( x line_arc_void_data_ls equal( _void car( x)))
		void_data_ls = mapcar( 'cadr void_data_ls)
		
		;;;; get overlap shape
		foreach( shape_id shape_ls
			box = shape_id->bBox
			when( exists( xy xy_ls axlIsPointInsideBox( xy box))
				shape_inbox_ls = append1( shape_inbox_ls shape_id)
			)
		)
		
		;;;; get exists shape
		shape_ls = shape_inbox_ls
		while( and( null( tar_shape_id) dtpr( shape_ls))
			shape_id = car( shape_ls)
			shape_seg_ls = shape_id->segments
			
			unless( is_modified_seg_Derek07222019( shape_seg_ls line_data_ls arc_data_ls)
				void_ls = shape_id->voids
				when( forall( void_data void_data_ls exists_shape_inbox_Derek07222019( void_ls void_data 'void))
					tar_shape_id = shape_id
					shape_inbox_ls = remq( tar_shape_id shape_inbox_ls)
				)
			)
			
			shape_ls = cdr( shape_ls)
		)
		
		;;;;
		when( tar_shape_id
			sprintf( log_lines "INFO: exists_shape_inbox() - Exists %s on layer[%s] at xy[%L]" type layer xy_ls)
			write_log_Derek07222019( _relocate_log_filename log_lines)
		)
		
		;;;;
		when( dtpr( shape_inbox_ls)
			sprintf( line "INFO: exists_shape_inbox() - Overlaped %s on layer[%s] at xy[%L]" type layer xy_ls)
			log_lines = list( line)
			foreach( shape_id shape_inbox_ls
				xy_ls = mapcar( 'car shape_id->segments~>startEnd)
				sprintf( line "INFO: exists_shape_inbox() - %s at xy[%L]" type xy_ls)
				log_lines = append1( log_lines line)
			)
			write_log_Derek07222019( _relocate_log_filename log_lines)
		)
		
		;;;;
		when( or( tar_shape_id dtpr( shape_inbox_ls))
			result = list( tar_shape_id shape_inbox_ls)
		)
		
		return( result)
	)
)

procedure( create_shape_Derek07222019( shape_data)
	;	"LINE",layer,start_xy,end_xy,width
	;	"ARC",layer,start_xy,end_xy,width,center_xy,cw
	;	"void" (("LINE",layer,start_xy,end_xy,width) ("ARC",layer,start_xy,end_xy,width,center_xy,cw))
	prog( ( fill void_data_ls line_arc_void_data_ls line_arc_data_ls layer start_xy width path data
			end_xy center_xy cw path shape_id poly_id status)
		unless( check_value_Derek07222019( 'ArgErr 'create_shape 'shape_data shape_data '_v_dtpr) return( nil))
		;;
		
		fill = cadr( shape_data)
		line_arc_void_data_ls = caddr( shape_data)
		
		;;;;
		void_data_ls = setof( x line_arc_void_data_ls equal( _void car( x)))
		void_data_ls = mapcar( 'cadr void_data_ls)
		line_arc_data_ls = setof( x line_arc_void_data_ls not( equal( _void car( x))))
		
		layer = cadar( line_arc_data_ls)
		
		start_xy = caddar( line_arc_data_ls)
		width = 0.0
		
		;;;; create shape
		path = axlPathStart( list( start_xy))
		foreach( data line_arc_data_ls
			end_xy = nth( 3 data)
			center_xy = nth( 5 data)
			cw =  nth( 6 data)
			
			path = create_path_util_Derek07222019( path end_xy layer width center_xy cw)
		)
		shape_id = axlDBCreateShape( path fill layer)
		
		when( shape_id axlHighlightObject( shape_id))
		status = if( shape_id "UPDATE" "ERROR")
		sprintf( log_lines "%s: create_shape() - Create shape at xy[%L] on layer[%s]" status mapcar( lambda( (x) caddr( x)) line_arc_data_ls) layer)
		write_log_Derek07222019( _relocate_log_filename log_lines)
		
		;;;; create void
		when( dtpr( void_data_ls)
			start_xy = caddar( void_data_ls)
			path = axlPathStart( list( start_xy))
			foreach( data void_data_ls
				end_xy = nth( 3 data)
				center_xy = nth( 5 data)
				cw =  nth( 6 data)
				
				path = create_path_util_Derek07222019( path end_xy layer width center_xy cw)
			)
			poly_id = axlDBCreateVoid( shape_id path)
			
			status = if( poly_id "UPDATE" "ERROR")
			sprintf( log_lines "%s: create_shape() - Create void at xy[%L] on layer[%s]" status mapcar( lambda( (x) caddr( x)) void_data_ls) layer)
			write_log_Derek07222019( _relocate_log_filename log_lines)
		)
		
		
		return( shape_id)
	)
)

procedure( progress_shape_Derek07222019( shape_data_ls)
	;	("shape" fill (("LINE",layer,start_xy,end_xy,width) ("ARC",layer,start_xy,end_xy,width,center_xy,cw)
	;		("void" (("LINE",layer,start_xy,end_xy,width) ("ARC",layer,start_xy,end_xy,width,center_xy,cw)))))
	prog( ( shape_top_ls shape_bot_ls shape_data line_data_ls arc_data_ls layer
			shape_inboxs shape_id shape_inbox_ls log_lines xy_ls)
		unless( check_value_Derek07222019( 'ArgErr 'progress_shape 'shape_data_ls shape_data_ls '_v_dtpr) return( nil))
		;;
		
		shape_top_ls = axlDBGetShapes( _bg_silk_top)
		shape_bot_ls = axlDBGetShapes( _bg_silk_bot)
		
		foreach( shape_data shape_data_ls
			line_arc_void_data_ls = caddr( shape_data)
			layer = cadar( line_arc_void_data_ls)
			
			cond(
				( equal( _bg_silk_top layer)
					
					shape_inboxs = exists_shape_inbox_Derek07222019( shape_top_ls shape_data 'shape)
					
					shape_id = car( shape_inboxs)
					shape_inbox_ls = cadr( shape_inboxs)
					when( shape_id (shape_top_ls = remq( shape_id shape_top_ls)))
				)
				( equal( _bg_silk_bot layer)
					
					shape_inboxs = exists_shape_inbox_Derek07222019( shape_bot_ls shape_data 'shape)
					
					shape_id = car( shape_inboxs)
					shape_inbox_ls = cadr( shape_inboxs)
					when( shape_id (shape_bot_ls = remq( shape_id shape_bot_ls)))
				)
				( t
					sprintf( log_lines "UPDATE: progress_shape() - Creat seg[arg] from %L to %L on layer[%s]" start_xy end_xy layer)
					write_log_Derek07222019( _relocate_log_filename log_lines)
				)
			)
			
			;;;; create shape
			unless( shape_id
				shape_id = create_shape_Derek07222019( shape_data)
				xy_ls = mapcar( 'car shape_id->segments~>startEnd)
				sprintf( log_lines "UPDATE: progress_shape() - Creat shape on layer[%s] with xy[%L]" layer xy_ls)
				write_log_Derek07222019( _relocate_log_filename log_lines)
			)
		)
		
		return( t)
	)
)

procedure( transform_silkscreen_data_Derek07222019( contents)
	prog( ( text_data_ls line_data_ls arc_data_ls shape_data_ls text_ls sym_text_ls)
		unless( check_value_Derek07222019( 'ArgErr 'transform_silkscreen_data 'contents contents '_v_dtpr) return( nil))
		;;
		
		text_data_ls = setof( x contents equal( _text car( x)))
		line_data_ls = setof( x contents equal( _line car( x)))
		arc_data_ls = setof( x contents equal( _arc car( x)))
		shape_data_ls = setof( x contents equal( _shape car( x)))
		
		;;;; transform text
		when( dtpr( text_data_ls)
			sym_text_ls = mapcan( lambda( (x) get_symbol_texts_Derek07222019( x _rd_silk_ls)) axlDBGetDesign()->symbols)
			text_ls = setof( x axlDBGetDesign()->text member( x->layer _bg_silk_ls))
			text_ls = append( text_ls sym_text_ls)
			
			progress_text_Derek07222019( text_ls text_data_ls)
		)
		
		;;;; create segments
		when( or( dtpr( line_data_ls) dtpr( arc_data_ls))
			progress_silk_Derek07222019( line_data_ls arc_data_ls)
		)
		
		;;;; transform shape
		when( dtpr( shape_data_ls)
			progress_shape_Derek07222019( shape_data_ls)
		)
		
		return( t)
	)
)

procedure( perform_status_Derek07222019( option)
	prog( ()
		unless( check_value_Derek07222019( 'ArgErr 'perform_status 'option option '_v_bool) return( nil))
		;;
		
		axlDBControl( 'drcEnable option)
		axlDBControl( 'busRats option)
		axlDBControl( 'ratnestDistance option)
		axlDBMemoryReclaim()
		
		return( t)
	)
)

procedure( write_log_Derek07222019( filename log_lines @optional (output nil))
	prog( ( out_port line)
		unless( check_value_Derek07222019( 'ArgErr 'write_log 'log_lines log_lines '_v_string_dtpr_or_string) return( nil))
		unless( dtpr( log_lines) (log_lines = list( log_lines)))
		unless( check_value_Derek07222019( 'ArgErr 'write_log 'filename filename '_v_string) return( nil))
		;;
		
		out_port = outfile( filename "a")
		unless( check_value_Derek07222019( 'ArgErr 'write_log 'out_port out_port '_v_outport) return( nil))
		
		when( output foreach( line log_lines printf( "%s\n" line)))
		foreach( line log_lines fprintf( out_port "%s\n" line))
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( copy_paste_symbols_main_Derek07222019()
	prog( ( title out_form file_addr write_flag default_filename log_lines pass_table result status
			log_filename msg obj_ls sym_ls contents part_ls curr_visible)
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		;;
		
		axlShell( "generalEdit")
		perform_status_Derek07222019( nil)
		
		;;;; store visible
		curr_visible = axlVisibleGet()
	
		init_Derek07222019()
		
		;;;;
		unless( write_form_Derek07222019() println( "ERROR: copy_paste_symbols_main() - Fail to create form content file\n") return( nil))
		out_form = axlFormCreate( gensym() _form_filename '("east" "outer") 'action_form_Derek07222019 nil)
		axlFormDisplay( out_form)
		deleteFile( _form_filename)
		when( equal( _form_close _form_operate) return( nil))
		
		;;;; copy or paste a file
		title = "Enter a filename for passing symbols location"
		if( member( _form_operate list( _form_symbol_copy _form_silkscreen_copy))
			file_addr = axlDMFileBrowse( "COMMA_SEPARATED_VALUE" t ?defaultName _default_store_file_csv ?title title)
			file_addr = axlDMFileBrowse( "COMMA_SEPARATED_VALUE" nil ?title title)
		)
		unless( stringp( file_addr) return( nil))
		unless( index( file_addr _csv) println( "ERROR: copy_paste_symbol_text_line() - File has to be csv file") return( nil))
		_header_line_ls = append1( _header_line_ls strcat( "Passing Filename: " file_addr "\n\nHistory\n"))
		
		;;;;
		cond(
			( equal( _form_symbol_copy _form_operate)
				;;;; copying symbol
				log_filename = _store_log_filename
				write_file_Derek07222019( log_filename _header_line_ls)
				
				;;;
				obj_ls = list( "SYMBOLS")
				sym_ls = select_parts_Derek07222019( obj_ls)
				sym_ls = setof( x sym_ls dtpr( x->pins)) ;;;; remove via optimization
				contents = convert_symbol_position_data_Derek07222019( sym_ls)
				
				;;;
				result = write_file_Derek07222019( file_addr contents)
				status = if( result "Successful" "Fail")
				sprintf( msg "INFO: copy_paste_symbols_main() - %s to copy symbols's position data" status)
			)
			( equal( _form_silkscreen_copy _form_operate)
				;;;; copying board geometry/silkscreen
				log_filename = _store_log_filename
				write_file_Derek07222019( log_filename _header_line_ls)
				
				;;;
				obj_ls = list( "LINES" "SHAPES" "TEXT")
				part_ls = select_parts_Derek07222019( obj_ls _rd_bg_silk_ls)
				contents = convert_silkscreen_position_data_Derek07222019( part_ls)
				
				;;;
				result = write_file_Derek07222019( file_addr contents)
				status = if( result "Successful" "Fail")
				sprintf( msg "INFO: copy_paste_symbols_main() - %s to copy symbols's position data" status)
			)
			( equal( _form_paste _form_operate)
				;;; pasting
				log_filename = _relocate_log_filename
				write_file_Derek07222019( log_filename _header_line_ls)
				
				result = read_pass_file_Derek07222019( file_addr)
				status = if( result "Successful" "Fail")
				sprintf( msg "INFO: copy_paste_symbols_main() - %s to transform symbols" status)
			)
			( t
				printf( "ERROR: copy_paste_symbols_main() - Yet to define function num[%L]\n" _form_operate)
			)
		)
		
		;;;;
		perform_status_Derek07222019( t)
		
		;;;;
		axlVisibleSet( curr_visible)
		axlVisibleUpdate( t)
		
		;;;;
		println( msg)
		axlUIConfirm( msg 'INFO)
		axlUIViewFileCreate( log_filename "Check copy_paste_symbols log" nil)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "copy_paste_symbols" 'copy_paste_symbols_main_Derek07222019)
; copy_paste_symbols_main_Derek07222019()
; skill (encrypt "c:/skill/copy_paste_symbols_v1.il" "c:/skill/copy_paste_symbols_v1.ile")
; (load "copy_paste_symbols_v1.ile")
; (load "copy_paste_symbols_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup