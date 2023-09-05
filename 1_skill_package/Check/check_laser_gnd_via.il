;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
; Developer: Derek Hsu
; Starting Date: 10/31/2017 - _Derek10312017
; Introduction: scanning the via name is fitting the cline segments connected to this via
; Form of GND Via Name: LV6C14_1-2_ANTI24
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

(defun init_Derek10312017 ()
	setq( _top "TOP")
	setq( _bottom "BOTTOM")
	
	setq( _key_not_gnd_net 'not_gnd_net)
	setq( _key_not_conn_sh 'not_conn_sh)
	setq( _key_mismatch_via_name 'mismatch_via_name)
	
	(setq _etch_subclass_ls (axlGetParam "paramLayerGroup:ETCH")->groupMembers)
	(setq _top_number 1)
	(setq _bot_number (length _etch_subclass_ls))
	
	setq( _via_2ly_ls nil)
	setq( _miss_via_ls nil)
	
	setq( _original_visible axlVisibleGet())
	
	;;;;;
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _log_filename "check_laser_gnd_via-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir)) createDir( _log_dir))
	sprintf( _check_laser_gnd_via_logname "%s/%s" _log_dir _log_filename)
	setq( _schematic_name get_schematic_name_Derek10312017())
)

procedure( get_schematic_name_Derek10312017()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls and( (length( s->pins) > 1))))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

(procedure set_via_visible_layer_Derek10312017()
	let( ()
		axlVisibleDesign( nil)
		
		axlVisibleLayer( "VIA CLASS/TOP" t)
		axlVisibleLayer( "VIA CLASS/BOTTOM" t)
		
		axlVisibleUpdate(t)
	)
)

(procedure get_via_find_filter_Derek10312017()
	prog( ( via_ls)
		axlClearSelSet()
		axlSetFindFilter( ?enabled (list "NOALL" "VIAS") ?onButtons (list "NOALL" "VIAS"))
		axlAddSelectAll()
		
		via_ls = axlGetSelSet()
		
		axlSetFindFilter( ?enabled (list "NOALL") ?onButtons (list "NOALL"))
		axlClearSelSet()
		
		return( via_ls)
	)
)

procedure( is_2ly_via_Derek10312017( via_id)
	prog( ( start_subclass end_subclass start_th end_th result)
		start_subclass = get_subclass_Derek10312017( car( via_id->startEnd))
		end_subclass = get_subclass_Derek10312017( cadr( via_id->startEnd))
		
		;;;; the th of top is 1
		start_th = add1( listnindex( _etch_subclass_ls start_subclass))
		end_th = add1( listnindex( _etch_subclass_ls end_subclass))
		
		result = and( or( onep( start_th) eqv( _bot_number end_th)) onep( end_th - start_th))
		
		return( result)
	)
)

(defun get_2ly_via_Derek10312017 ()
	prog( (via_ls)
		;;;;; set visible
		set_via_visible_layer_Derek10312017()
		
		;;;;; filter
		via_ls = get_via_find_filter_Derek10312017()
		
		;;;; get via with 2 layer only
		via_ls = setof( x via_ls is_2ly_via_Derek10312017( x))
		
		return( via_ls)
	)
)

procedure( get_subclass_Derek10312017( layer)
	prog( ( class subclass)
		unless( stringp( layer) return( nil))
		unless( stringp( index( layer "/")) return( nil))
		
		subclass = cadr( parseString( layer "/"))
		
		
		return( subclass)
	)
)

procedure( is_pair_etch_subclass_match_th_Derek10312017( subclass1 subclass2 th1 th2)
	prog( ( subclass1_th subclass2_th result)
		unless( and( stringp( subclass1) stringp( subclass2) integerp( th1) integerp( th2)) return( nil))
		;;
		
		subclass1_th = listnindex( _etch_subclass_ls subclass1)
		subclass2_th = listnindex( _etch_subclass_ls subclass2)
		unless( and( subclass1_th subclass2_th) return( nil))
		
		subclass1_th++
		subclass2_th++
		
		result = or( and( eqv( subclass1_th th1) eqv( subclass2_th th2)) and( eqv( subclass1_th th2) eqv( subclass2_th th1)))
		
		return( result)
	)
)

procedure( get_connected_by_layer_Derek10312017( via_id)
	prog( ( connected_ls)
		unless( equal( "via" via_id->objType) return( nil))
		
		connected_ls = axlDBGetConnect( via_id t)
		unless( connected_ls return( nil))
		
		connected_ls = maplist( lambda( (x) if( member( car( x)->layer cdr( x)~>layer) nil car( x))) connected_ls)
		connected_ls = remq( nil connected_ls)
		
		return( connected_ls)
	)
)

(defun get_miss_via_Derek10312017 ()
	; via_id = car( axlGetSelSet())
	let( (connected_ls miss_via_info subclass1 subclass2 )
		(foreach via_id _via_2ly_ls
			connected_ls = get_connected_by_layer_Derek10312017( via_id)
			cond(
				( !index( via_id->net->name "GND")
					;;;;; the name of the net should include GND
					miss_via_info = list( _key_not_gnd_net via_id->xy via_id->net->name)
				)
				( !exists( x connected_ls equal( "shape" x->objType))
					;;;; connect to gnd shape
					miss_via_info = list( _key_not_conn_sh via_id->xy via_id->name)
				)
				( (eqv 5 (sscanf via_id->name "LV%dC%d_%d-%d_ANTI%d" hole pad th1 th2 anti))
					;;;; if via name match Flex rule, then check the naming
					subclass1 = get_subclass_Derek10312017( car( via_id->startEnd))
					subclass2 = get_subclass_Derek10312017( cadr( via_id->startEnd))
					
					unless( is_pair_etch_subclass_match_th_Derek10312017( subclass1 subclass2 th1 th2)
						obj_ls = mapcar( 'get_subclass_Derek10312017 via_id->startEnd)
						miss_via_info = list( _key_mismatch_via_name via_id->xy via_id->name obj_ls)
					)
				)
				( t
					miss_via_info = nil
				)
			)
			
			;;;;;
			(when miss_via_info
				_miss_via_ls = append1( _miss_via_ls miss_via_info)
			)
		)
	)
)

procedure( get_via_uni_cnt_Derek10312017( via_ls)
	prog( (uni_via_name_ls uni_via_name_ls)
		uni_via_name_ls = maplist( lambda( (x) if( member( car( x)->name cdr( x)~>name) nil car( x)->name)) via_ls)
		uni_via_name_ls = remq( nil uni_via_name_ls)
		
		via_uni_cnt_ls = mapcar( lambda( (x) list( x length( member( x via_ls~>name)))) uni_via_name_ls)
		
		
		return( via_uni_cnt_ls)
	)
)

procedure( write_log_Derek10312017()
	prog( ( out_port)
		out_port = outfile( _check_laser_gnd_via_logname "w")
		unless( outportp( out_port) println( "ERROR: write_log() - fail to write file") return( nil))
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %s\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: This tool is used to check isolated 2-layer laser GND via by following topic\n")
		fprintf( out_port "\t1. The net of such via has no 'GND' term\n")
		fprintf( out_port "\t2. It should connect to a GND shape\n")
		fprintf( out_port "\t3. If the laser via name follows Flex rule, check whether the name and the real build-in layer are mapped\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=====================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Summary of 2-layer GND laser via:\n")
		via_uni_cnt_ls = get_via_uni_cnt_Derek10312017( _via_2ly_ls)
		foreach( name_cnt via_uni_cnt_ls
			fprintf( out_port "\t%s:   %d\n" car( name_cnt) cadr( name_cnt))
		)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "=====================================================================================================\n")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "1. The net of such via has no 'GND' term\n")
		;; miss_via_info = list( _key_not_gnd_net via_id->xy via_id->net->name)
		fprintf( out_port "via_xy, net_name\n")
		this_miss_via_ls = setof( x _miss_via_ls eq( _key_not_gnd_net car( x)))
		unless( this_miss_via_ls fprintf( out_port "None\n"))
		foreach( this_mis_via this_miss_via_ls
			fprintf( out_port "%L, %s\n" car( this_mis_via) cadr( this_mis_via))
		)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "2. It should connect to a GND shape\n")
		;; miss_via_info = list( _key_not_conn_sh via_id->xy via_id->net->name)
		fprintf( out_port "via_xy, via_name\n")
		this_miss_via_ls = setof( x _miss_via_ls eq( _key_not_conn_sh car( x)))
		unless( this_miss_via_ls fprintf( out_port "None\n"))
		foreach( this_mis_via this_miss_via_ls
			fprintf( out_port "%L, %s\n" car( this_mis_via) cadr( this_mis_via))
		)
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "3. If the laser via name follows Flex rule, check whether the name and the real build-in layer are mapped\n")
		;; miss_via_info = list( _key_mismatch_via_name via_id->xy via_id->name obj_ls)
		fprintf( out_port "via_xy, via_name, layers\n")
		this_miss_via_ls = setof( x _miss_via_ls eq( _key_mismatch_via_name car( x)))
		unless( this_miss_via_ls fprintf( out_port "None\n"))
		foreach( this_mis_via this_miss_via_ls
			fprintf( out_port "%L, %s, %L\n" car( this_mis_via) cadr( this_mis_via) caddr( this_mis_via))
		)
		
		
		close( out_port)
	)
)

(defun check_laser_gnd_via_main_Derek10312017 ()
	prog( ()
		(unless axlOKToProceed() (println "Please done current function to use this program") (return nil))
		;;
		
		init_Derek10312017()
		
		_via_2ly_ls = get_2ly_via_Derek10312017()
		get_miss_via_Derek10312017()
		
		(axlVisibleSet _original_visible)
		axlVisibleUpdate( t)
		
		;;;;; write log
		write_log_Derek10312017()
		
		axlUIViewFileCreate( _check_laser_gnd_via_logname "Check Laser GND Via Report" nil)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

(axlCmdRegister "check_laser_gnd_via" 'check_laser_gnd_via_main_Derek10312017)
; (check_laser_gnd_via_main_Derek10312017)
; skill encrypt( "C:/skill/check_laser_gnd_via_v1d1.il" "C:/skill/check_laser_gnd_via_v1d1.ile")
; (load "check_laser_gnd_via_v1d1.ile")
; (load "check_laser_gnd_via_v1d1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup