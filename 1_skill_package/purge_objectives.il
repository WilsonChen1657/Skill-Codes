;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 06/02/2020 - _Derek06022020
; Introduction: purge unused things
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek06022020()
	;;;;; global variable in this program
	setq( _purged_padstack 0)
	setq( _purged_via 0)
	setq( _purged_cns 0)

	;;;;; log directory
	unless( stringp( axlGetVariable( "ads_sdlog")) axlSetVariable( "ads_sdlog" "log"))
	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	
	;;;;; log filename
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _purge_objectives_logname "%s/purge_objectives-%d%s%.2d-%.2d%.2d%.2d.log" _log_dir _year _month _date _hour _minute _second)
	
	;;;;;
	setq( _schematic_name get_schematic_name_Derek06022020())
)

procedure( get_schematic_name_Derek06022020()
	; sym_id = car( axlGetSelSet())
	prog( ( sym_ls sym_id schematic_name)
		sym_ls = axlDBGetDesign()->symbols
		sym_id = car( exists( s sym_ls (length( s->pins) > 1)))
		
		;;;;;
		schematic_name = car( sym_id->component->functions)->prop->LOGICAL_PATH
		;;; remove @
		schematic_name = substring( schematic_name 2)
		;;; remove the string started from :
		schematic_name = car( parseString( schematic_name ":"))
		
		
		return( schematic_name)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( purge_unused_pad_Derek06022020()
	let( ()
		_purged_padstack = axlPurgePadstacks( 'padstacks nil)
		printf( "Number of purged unused padstacks: %L\n" _purged_padstack)
		
		_purged_via = axlPurgePadstacks( 'via nil)
		printf( "Number of purged unused vias: %L\n" _purged_via)
	)
)

procedure( purge_unused_constraint_Derek06022020()
	let( ()
		_purged_cns = axlCnsPurgeAll()
		unless( onep( length( _purged_cns)) printf( "Warning: unexpected condition - _purge_cns: %L\n" _purge_cns))
		
		_purged_cns = car( _purged_cns)
		printf( "Number of purged unused netclass / region / physical cset / spacing cset: %d\n" _purged_cns)
	)
)

procedure( write_file_Derek06022020()
	prog( ( out_port)
		out_port = outfile( _purge_objectives_logname "w")
		unless( outportp( out_port) printf( "ERROR: write_file() - Fail to write file: %s\n" _purge_objectives_logname) return( nil))
		;;
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: This program is used to purge unused padstack / via / netclass / region / physical cset / spacing cset")
		
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Number of purged unused padstacks: %L\n" _purged_padstack)
		fprintf( out_port "Number of purged unused vias: %L\n" _purged_via)
		fprintf( out_port "Number of purged unused netclass / region / physical cset / spacing cset: %d\n" _purged_cns)
		
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( purge_objectives_main_Derek06022020()
	prog( ( result answer)
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		;;
		
		printf( "\n******************************************start of purge objectives******************************************\n\n")
		
		;;;;; init_Derek06022020
		init_Derek06022020()
		
		answer = axlUIYesNoCancel( "Would you like to purge the unused padstack / via / netclass / region / physical cset / spacing cset?" "Purge Objectives Confirm" 'yes)
		
		caseq( answer
			( 1
				;;;;; yes
				println( "Start to purge specified objectives on the board")
				
				purge_unused_pad_Derek06022020()
				purge_unused_constraint_Derek06022020()
				result = t
			)
			( 0
				;;;;; no
				println( "Do no purge any specified objectives on the board")
				result = t
			)
			( 2
				;;;;; cancel
				println( "Nothing will be executed")
				result = nil
			)
		)
		
		;;;;;
		write_file_Derek06022020()
		
		;;;;; display log file
		axlUIViewFileCreate( _purge_objectives_logname "Purge Fiducial Report" nil)
		
		
		printf( "\n********************************************end of purge objectives******************************************\n\n")
		
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "purge_objectives" 'purge_objectives_main_Derek06022020)
; (purge_objectives_main_Derek06022020)
; skill encrypt( "C:/skill/purge_objectives_v1.il" "C:/skill/purge_objectives_v1.ile")
; (load "purge_objectives_v1.il")
; (load "purge_objectives_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup