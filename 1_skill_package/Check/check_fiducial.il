;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Stating Date: 06012020 - _derek06012020
; introduction: it should have at least 3 fiducials on the top and bottom side individually
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_derek06012020()
	setq( _layer_top "ETCH/TOP")
	setq( _layer_bottom "ETCH/BOTTOM")
	
	;;;;; log directory
	unless( stringp( axlGetVariable( "ads_sdlog")) axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	
	;;;;; log filename
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _fiducial_logname "%s/check_fiducial-%d%s%.2d-%.2d%.2d%.2d.log" _log_dir _year _month _date _hour _minute _second)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_fiducial_by_layer_derek06012020( layer)
	prog( ( sym_ls)
		sym_ls = axlDBGetDesign()->symbols
		
		;;;; one pin only
		sym_ls = setof( s sym_ls onep( length( s->pins)))
		
		;;;;; is smd
		sym_ls = setof( s sym_ls !car( s->pins)->isThrough)
		
		;;;; no net name on pin
		sym_ls = setof( s sym_ls equal( "" (car( s->pins)->net->name || "")))
		
		;;;; no via
		sym_ls = setof( s sym_ls !exists( s sym_ls member( "via" s->childen~>objType)))
		
		;;;; on layer
		sym_ls = setof( s sym_ls equal( layer car( car( s->pins)->startEnd)))
		
		
		return( sym_ls)
	)
)

procedure( write_file_derek06012020( fiducial_sym_top_ls fiducial_sym_bot_ls)
	prog( ( out_port result)
		out_port = outfile( _fiducial_logname "w")
		unless( outportp( out_port) printf( "ERROR: write_file() - Fail to write file: $s\n" _fiducial_logname) return( nil))
		;;
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "It should have at least 3 fiducial on Top and Bottom individually\n\n")
		
		fprintf( out_port "fiducial on Top: [%d]\n" length( fiducial_sym_top_ls))
		foreach( sym_id fiducial_sym_top_ls fprintf( out_port "\t[%s]: %L\n" sym_id->name sym_id->xy))
		
		fprintf( out_port "fiducial on Bot: [%d]\n" length( fiducial_sym_bot_ls))
		foreach( sym_id fiducial_sym_bot_ls fprintf( out_port "\t[%s]: %L\n" sym_id->name sym_id->xy))
		
		fprintf( out_port "\n\n")
		
		result = and( (cnt_fiducial_top > 2 ) (cnt_fiducial_bot > 2))
		fprintf( out_port "Result: %s\n" if( result "Pass" "Fail"))
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( check_fiducial_main_derek06012020()
	prog( ()
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		;;
		
		;;;;; init_derek06012020
		init_derek06012020()
		
		fiducial_sym_top_ls = get_fiducial_by_layer_derek06012020( _layer_top)
		fiducial_sym_bot_ls = get_fiducial_by_layer_derek06012020( _layer_bottom)
		
		;;;;;
		cnt_fiducial_top = length( fiducial_sym_top_ls)
		cnt_fiducial_bot = length( fiducial_sym_bot_ls)
		println( "It should have at least 3 fiducial on Top and Bottom individually")
		printf( "There are [%d] fiducial on Top: %L\n" cnt_fiducial_top fiducial_sym_top_ls~>xy)
		printf( "There are [%d] fiducial on Bottom: %L\n" cnt_fiducial_bot fiducial_sym_bot_ls~>xy)
		
		;;;;;
		result = and( (cnt_fiducial_top > 2 ) (cnt_fiducial_bot > 2))
		printf( "Result: %s\n" if( result "Pass" "Fail"))
		
		;;;;; write log file
		write_file_derek06012020( fiducial_sym_top_ls fiducial_sym_bot_ls)
		
		;;;;; display log file
		axlUIViewFileCreate( _fiducial_logname "Checking fiducial Report" nil)
		
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_fiducial" 'check_fiducial_main_derek06012020)
; (check_fiducial_main_derek06012020)
; skill encrypt( "C:/skill/check_fiducial_v1.il" "C:/skill/check_fiducial_v1.ile")
; (load "check_fiducial_v1.il")
; (load "check_fiducial_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup