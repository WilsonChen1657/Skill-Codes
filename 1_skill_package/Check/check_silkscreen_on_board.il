;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
; Developer: Derek Hsu
; Starting Date: 10/12/2020 - _Derek10122020
; introduction: check all silkscreen object is in the board
;	1. out of the cutout, however, within the outline/design_outline
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek10122020()
	setq( _user_visible axlVisibleGet())
	setq( _allegro_version axlVersion( 'version))
	
	setq( _outline_layer "BOARD GEOMETRY/DESIGN_OUTLINE")
	setq( _cutout_layer "BOARD GEOMETRY/CUTOUT")
	
	setq( _refdes_class "REF DES")
	setq( _silkscreen_text_layer_ls list( "BOARD GEOMETRY/SILKSCREEN_TOP"
									"BOARD GEOMETRY/SILKSCREEN_BOTTOM"
									"PACKAGE GEOMETRY/SILKSCREEN_TOP"
									"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
									"REF DES/SILKSCREEN_TOP"
									"REF DES/SILKSCREEN_BOTTOM"))
	
	;;
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _log_filename "check_silkscreen_on_board-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _check_silkscreen_on_board_logname "%s/%s" _log_dir _log_filename)
	setq( _schematic_name get_schematic_name_Derek10122020())
)

procedure( get_schematic_name_Derek10122020()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( x sym_ls (length( x->pins) > 1 && x->component->functions)))
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( set_display_Derek10122020( layer_ls)
	let( ()
		axlVisibleDesign( nil)
		foreach( layer layer_ls
			axlVisibleLayer( layer t)
		)
	)
)

procedure( set_find_filter_Derek10122020( object_ls)
	let( ( option_ls)
		option_ls = list( "NOALL")
		when( dtpr( object_ls)
			option_ls = append( option_ls object_ls)
		)
		
		axlSetFindFilter( ?enabled option_ls ?onButtons option_ls)
	)
)

procedure( select_all_Derek10122020( layer_ls object_ls)
	prog( ( obj_ls)
		set_display_Derek10122020( layer_ls)
		set_find_filter_Derek10122020( object_ls)
		
		axlAddSelectAll()
		obj_ls = axlGetSelSet()
		axlClearSelSet()
		
		set_find_filter_Derek10122020( nil)
		
		return( obj_ls)
	)
)

procedure( get_boundary_points_Derek10122020( xy_ls)
	prog( ( x_ls y_ls x_min x_max y_min y_max x_boundary_ls y_boundary_ls boundary_xy_ls)
		x_ls = mapcar( 'car xy_ls)
		y_ls = mapcar( 'cadr xy_ls)
		
		x_min = apply( 'min x_ls)
		x_max = apply( 'max x_ls)
		y_min = apply( 'min y_ls)
		y_max = apply( 'max y_ls)
		
		x_boundary_ls = list( x_min x_max)
		y_boundary_ls = list( y_max y_max)
		
		boundary_xy_ls = setof( xy xy_ls exists( x x_boundary_ls car( xy) == x)
									|| exists( y y_boundary_ls cadr( xy) == y))
		
		return( boundary_xy_ls)
	)
)

procedure( get_text_boundary_points_Derek10122020( text_id)
	; text_id = car( axlGetSelSet())
	prog( ( paths_ls path_ls poly xy_ls boundary_xy_ls total_boundary_xy_ls)
		paths_ls = axlText2Lines( text_id)
		foreach( paths paths_ls path_ls = append( path_ls paths))
		
		foreach( path path_ls
			; path = car( path_ls)
			;;;; every product should be one-element list because the individual has been combinded into the path_ls
			poly = car( axlPolyFromDB( path ?line2poly t ?endCapType 'ROUND))
			; axlDBCreateShape( poly t "ETCH/TOP")
			xy_ls = mapcar( 'car poly->vertices)
			boundary_xy_ls = get_boundary_points_Derek10122020( xy_ls)
			total_boundary_xy_ls = append( total_boundary_xy_ls boundary_xy_ls)
		)
		
		return( total_boundary_xy_ls)
	)
)

procedure( get_obj_points_Derek10122020( obj_id)
	prog( ( obj_type xy_ls)
		obj_type = obj_id->objType
		case( obj_type
			( "text"
				xy_ls = get_text_boundary_points_Derek10122020( obj_id)
				;axlDBCreatePath( axlPathStart( xy_ls) "BOARD GEOMETRY/SILKSCREEN_TOP" 'line)
			)
			( t
				printf( "ERROR: get_obj_points() - Yet to support object type: %L\n" obj_type)
			)
		)
		
		return( xy_ls)
	)
)

procedure( is_silkscreen_on_board_Derek10122020( obj_id outline_sh_ls cutout_sh_ls)
	prog( ( xy_ls is_on_board)
		xy_ls = get_obj_points_Derek10122020( obj_id)
		
		is_on_board = forall( xy xy_ls exists( shape_id outline_sh_ls axlGeoPointInShape( xy shape_id)))
		unless( is_on_board return( nil))
		
		unless( dtpr( cutout_sh_ls) return( t))
		is_on_board = forall( xy xy_ls forall( shape_id cutout_sh_ls !axlGeoPointInShape( xy shape_id)))
		
		return( is_on_board)
	)
)

procedure( get_log_content_Derek10122020( fatel_obj_ls)
	prog( ( format header log_content content)
		format = "%-38s,%-20s,%s"
		sprintf( header format "layer" "xy" "text")
		log_content = list( header)
		
		unless( dtpr( fatel_obj_ls)
			log_content = append1( log_content "None")
			return( log_content)
		)
		;;
		
		foreach( obj_id fatel_obj_ls
			case( obj_id->objType
				( "text"
					text = obj_id->text
					layer = obj_id->layer
				)
				( "symbol"
					println( obj_id->??)
					sprintf( text "'Missing REFDES':<%s>" obj_id->refdes)
					layer = strcat( "ETCH/" obj_id->layer)
				)
			)
			sprintf( xy "%L" obj_id->xy)
			
			sprintf( content format layer xy text)
			
			log_content = append1( log_content content)
		)
		
		return( log_content)
	)
)

procedure( write_log_Derek10122020( log_content)
	prog( ( out_port format)
		out_port = outfile( _check_silkscreen_on_board_logname "w")
		unless( outportp( out_port) println( "ERROR: Fail to write log file") return( nil))
		;;
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction:\n")
		fprintf( out_port "\tCheck if the silkscreen text is out of the board\n")
		fprintf( out_port "\t\t1. It has to be within BOARD GEOMETRY/DESIGN_OUTLINE and out of BOARD GEOMETRY/CUTOUT\n")
		fprintf( out_port "\t\t2. Text layers including:\n" _silkscreen_text_layer_ls)
		foreach( layer _silkscreen_text_layer_ls
			fprintf( out_port "\t\t\t%s\n" layer)
		)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Summary:\n")
		fprintf( out_port "\tTotal item: %d\n" sub1( length( log_content)))
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Checking data is following\n")
		foreach( line log_content
			fprintf( out_port "\t%s\n" line)
		)
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( is_refdes_on_board_Derek10122020( text refdes_ls)
	prog( ()
		return( member( text refdes_ls~>text))
	)
)

procedure( get_fatel_objects_Derek10122020( outline_sh_ls cutout_sh_ls)
	prog( ( text_ls sym_ls over_text_ls refdes_ls miss_text_ls fatel_obj_ls)
		text_ls = select_all_Derek10122020( _silkscreen_text_layer_ls list( "TEXT"))
		sym_ls = setof( x axlDBGetDesign()->symbols stringp( x->refdes))
		
		;;;;;
		over_text_ls = setof( text_id text_ls !is_silkscreen_on_board_Derek10122020( text_id outline_sh_ls cutout_sh_ls))
		
		refdes_ls = setof( x text_ls index( x->layer _refdes_class))
		miss_text_ls = setof( sym_id sym_ls !is_refdes_on_board_Derek10122020( sym_id->refdes refdes_ls))
		
		fatel_obj_ls = append( over_text_ls miss_text_ls)
		
		return( fatel_obj_ls)
	)
)

procedure( check_silkscreen_on_board_main_Derek10122020()
	prog( ()
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		;;
		
		init_Derek10122020()
		unless( _allegro_version > 17.0 printf( "Please upgrade to Allegro 17.2 to use this function") return( nil))
		
		;;;;; program start from here
		outline_sh_ls = axlDBGetShapes( _outline_layer)
		unless( dtpr( outline_sh_ls) printf( "WARNING: No shape has been found in %s\n" _outline_layer) return( nil))
		cutout_sh_ls = axlDBGetShapes( _cutout_layer)
		
		;;;;;
		fatel_obj_ls = get_fatel_objects_Derek10122020( outline_sh_ls cutout_sh_ls)
		
		;;;;;
		log_content = get_log_content_Derek10122020( fatel_obj_ls)
		write_log_Derek10122020( log_content)
		
		axlUIViewFileCreate( _check_silkscreen_on_board_logname "Check Silkscreen on Board Report" nil)
		
		axlVisibleSet( _user_visible)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_silkscreen_on_board" 'check_silkscreen_on_board_main_Derek10122020)
; (check_silkscreen_on_board_main_Derek10122020)
; skill encrypt( "C:/skill/check_silkscreen_on_board_v1.il" "C:/skill/check_silkscreen_on_board_v1.ile")
; (load "check_silkscreen_on_board_v1.il")
; (load "check_silkscreen_on_board_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup