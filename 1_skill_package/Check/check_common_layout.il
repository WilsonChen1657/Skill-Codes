;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
; Developer: Derek Hsu
; Starting Date: 09/16/2020 - _Derek09162020
; introduction: common checking item for HS/LS signal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global variable

procedure( init_Derek09162020()
	
	setq( _seperator_format "============================================= %s =============================================\n")
	
	;;;;; main body
	
	;;
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _log_filename "check_common_layout-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _check_common_layout_logname "%s/%s" _log_dir _log_filename)
	setq( _schematic_name get_schematic_name_Derek09162020())
)

procedure( get_schematic_name_Derek09162020()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls (length( s->pins) > 1)))
		unless( sym_id println( "ERROR: get_schematic_name() - Fail to get a symbol") return( nil))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( write_log_utility_Derek09162020( title header_ls data_ls format_ls)
	let( ( header format content_ls)
		header = strcat( "\t" buildString( header_ls ","))
		format = strcat( "\t" buildString( format_ls ","))
		content_ls = mapcar( lambda( (x) apply( 'lsprintf format x)) data_ls)
		
		content_ls = append( list( "" title header) content_ls)
		
		write_log_Derek09162020( content_ls)
	)
)

procedure( write_log_Derek09162020( content_ls @key (seperator nil) (position 0))
	let( ( out_port tab)
		unless( dtpr( content_ls ) printf( "ERROR: write_log() - content_ls argument should be a dtpr") return( nil))
		out_port = outfile( _check_common_layout_logname "a")
		unless( outportp( out_port) printf( "ERROR: write_log() - Fail to write/append log file") return( nil))
		;;
		
		cond(
			( seperator
				foreach( content content_ls
					unless( content == ""
						sprintf( content _seperator_format content)
					)
					fprintf( out_port "%s\n" content)
				)
			)
			( t
				tab = ""
				for( i 1 position
					tab = strcat( tab "\t")
				)
				
				foreach( content content_ls
					fprintf( out_port "%s%s\n" tab content)
				)
			)
		)
		
		close( out_port)
	)
)

procedure( write_log_header_Derek09162020()
	let( ( content_ls)
		content_ls = list( sprintf( nil "Board file name: %s" axlCurrentDesign())
						sprintf( nil "Schematic name: %s" _schematic_name)
						sprintf( nil "Date-time: %s" getCurrentTime()))
		write_log_Derek09162020( content_ls)
	)
)

procedure( write_log_section_Derek09162020( section)
	let( ()
		content_ls = list( "" "" section)
		write_log_Derek09162020( content_ls ?seperator t)
	)
)

procedure( get_smd_width_Derek09162020( smd_id)
	prog( ( layer pad_id box side1 side2 width)
		layer = car( smd_id->startEnd)
		pad_id = axlDBGetPad( smd_id layer "REGULAR")
		
		box = pad_id->bBox
		side1 = abs( caar( box) - caadr( box))
		side2 = abs( cadar( box) - cadadr( box))
		width = if( side1 > side2 side2 side1)
		
		return( width)
	)
)

procedure( get_cline_seg_on_pin_Derek09162020( pin_id)
	prog( ( xy path_ls cline_seg_ls)
		xy = pin_id->xy
		obj_ls = axlDBGetConnect( pin_id)
		path_ls = setof( x obj_ls x->objType == "path")
		
		foreach( path_id path_ls
			foreach( seg_id path_id->segments
				when( axlIsPointOnLine( xy seg_id->startEnd)
					cline_seg_ls = append1( cline_seg_ls seg_id)
				)
			)
		)
		
		return( cline_seg_ls)
	)
)

procedure( get_smd_on_design_Derek09162020( @key (on_clineseg nil))
	prog( ( symbol_ls pin_ls smd_ls total_smd_ls)
		symbol_ls = axlDBGetDesign()->symbols
		foreach( symbol_id symbol_ls
			pin_ls = symbol_id->pins
			smd_ls = setof( x pin_ls car( x->startEnd) == cadr( x->startEnd))
			
			total_smd_ls = append( total_smd_ls smd_ls)
		)
		
		when( on_clineseg
			temp_ls = nil
			foreach( smd_id total_smd_ls
				obj_ls = axlDBGetConnect( smd_id t)
				path_ls = setof( x obj_ls x->objType == "path")
				
				when( dtpr( path_ls)
					temp_ls = append1( temp_ls smd_id)
				)
			)
			total_smd_ls = temp_ls
		)
		
		return( total_smd_ls)
	)
)

procedure( get_subclass_in_layer_Derek09162020( layer)
	prog( ( sect_2 subclass)
		sect_2 = parseString( layer "/")
		subclass = cadr( sect_2)
		
		return( subclass)
	)
)

procedure( get_xy_string_Derek09162020( xy)
	prog( ( text)
		sprintf( text "(%f %f)" car( xy) cadr( xy))
		
		return( text)
	)
)

procedure( check_clineseg_width_on_smd_Derek09162020()
	let( ( smd_ls xy path_ls cline_seg_ls net_name pin_name layer subclass smd_width 
			cline_seg_width data data_ls title header_ls data_form_ls)
		smd_ls = get_smd_on_design_Derek09162020( ?on_clineseg t)
		
		foreach( smd_id smd_ls
			cline_seg_ls = get_cline_seg_on_pin_Derek09162020( smd_id)
			
			;;;;;
			xy = get_xy_string_Derek09162020( smd_id->xy)
			net_name = smd_id->net->name || "NO_NET_NAME"
			pin_name = axlDbidName( smd_id)
			layer = car( smd_id->startEnd)
			subclass = get_subclass_in_layer_Derek09162020( layer)
			smd_width = get_smd_width_Derek09162020( smd_id)
			foreach( cline_seg_id cline_seg_ls
				cline_seg_width = cline_seg_id->width
				when( cline_seg_width > smd_width
					data = list( net_name pin_name cline_seg_width smd_width subclass xy)
					data_ls = append1( data_ls data)
				)
			)
		)
		
		;;;;;
		title = "Width of Cline segment should be equal or less over smd width/radius"
		header_ls = list( "net_name" "pad" "net_width" "smd_width" "layer" "xy")
		format_ls = list( "%-30s" "%-15s" "%-6.2f" "%-6.2f" "%-10s" "%-25s")
		write_log_utility_Derek09162020( title header_ls data_ls format_ls)
	)
)

procedure( check_common_layout_main_Derek09162020()
	prog( ()
		unless( axlOKToProceed() println( "Please done the current function before using this tool") return( nil))
		;;
		
		init_Derek09162020()
		
		write_log_header_Derek09162020()
		
		;;;;; main body
		
		write_log_section_Derek09162020( "Check item upon Net and SMD")
		check_clineseg_width_on_smd_Derek09162020()
		
		
		;;;;; end of report
		axlUIViewFileCreate( _check_common_layout_logname "Check Common Layout" nil)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

(axlCmdRegister "check_common_layout" 'check_common_layout_main_Derek09162020)
; (check_common_layout_main_Derek09162020)
; skill (encrypt "c:/skill/check_common_layout_v1.il" "c:/skill/check_common_layout_v1.ile")
; (load "check_common_layout_v1.ile")
; (load "check_common_layout_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup