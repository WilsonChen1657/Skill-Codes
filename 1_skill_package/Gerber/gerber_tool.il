;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 02/22/2018 - _Derek02222018
;Introduction: This tool is used to generate and achieve part of item of the gerber out package, including
;	3.<brd name>_date(brd).7z
;	4.<brd name>_date(dxf).7z
;	5.<brd name>_date(emn_emp).7z
;	6.<brd name>_date(odb++).7z
;	7.<brd name>_date(cad).7z
;	8.<brd name>_date(gbr).7z
;	10.<brd name>_date(panel).7z
;	11.<brd name>_date(pcba).7z
;	13.<brd name>_component.txt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

(procedure get_main_gerber_name_Derek02222018(today work_name)
	(prog ()
	;;;;; to escape

	(filename = (upperCase work_name))
	(if (index filename "-") then
		(f = (car (parseString filename "-")))
	else
		(f = axlEnterString(?prompts "Certain Brd term can't be gotten. Please enter the brd name"))
		(unless f return(nil))
		(when (zerop (strlen f))
			println("You have to at least enter one character to trigger this function. Process halt")
			return(nil)
		)
	)
	
	(f_name = (strcat f "_" today "%s"))
	
	return(f_name)
	)
)

(defun init_Derek02222018 ()
	(prog ()
	
	(setq work_name axlCurrentDesign())
	(setq work_path getWorkingDir())
	(setq work_addr axlGetDrawingName())
	(setq allegro_version (sprintf nil "Allegro_%.1f_%s" axlVersion('version) axlVersion('buildDate)))
	
	(setq mon_ls '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	(sscanf getCurrentTime() "%s %d %d:%d:%d %d" mon date hr min sec year)
	(for nm 0 11 (when (equal mon (nth nm mon_ls)) (mon_num = (add1 nm))))
	(setq today (sprintf nil "%.4d%.2d%.2d" year mon_num date))
	(setq gerber_file_term get_main_gerber_name_Derek02222018(today work_name))
	(unless gerber_file_term return(nil))
	(when (index gerber_file_term " ") println("No gap allowed in the brd name") return(nil))
	
	(setq gerber_dir (strcat "CAD_DATA_" today))
	(setq gerber_addr (strcat work_path "/" gerber_dir))
	(setq gerber_back_addr (axlOSBackSlash gerber_addr))
	
	;;;;; deal with log
	(unless axlGetVariable("ads_sdlog") axlSetVariable("ads_sdlog" "log"))
	(unless (isDir (dir = axlGetVariable("ads_sdlog"))) (createDir dir))
	
	;;;;; deal with artwork
	(unless axlGetVariable("ads_sdart") axlSetVariable("ads_sdart" "artwork"))
	(unless (isDir (dir = axlGetVariable("ads_sdart"))) (createDir dir))
	(setq art_dir axlGetVariable("ads_sdart"))
	(when (isDir art_dir) (delete_extra_file_Derek02222018 (getDirFiles art_dir) art_dir))
	
	;;;;; axlGetVariable("NCDPATH")
	(setq cnv_filename "temp.cnv")
	
	return(t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

(procedure archieve_7z_Derek02222018(file_names achieve_name @optional (ext ".7z"))
	(prog ()
	;;;;; prog is used to escape the function while indicated condition does not meet
	
	(achieve_name = (strcat achieve_name ext))
	(achieve_addr = (strcat gerber_dir "\\" achieve_name))
	
	(if (dtpr file_names)
		(foreach nm file_names (unless (isFile nm) printf("No file has been found: %s\n" nm) return(nil)))
		(unless (isFile file_names) printf("No file has been found: %s\n" file_names) return(nil))
	)
	(when (isFile achieve_addr) printf("Exists achieve file: %s\n" achieve_name) return(nil))
	
	(if (dtpr file_names)
		(file_name = (buildString file_names " "))
		(file_name = file_names)
	)
	
	(cmd = (buildString (list "\"C:\\Program Files\\7-Zip\\7z\"" "a" achieve_name file_name) " "))
	(unless (sh cmd)
		printf("No achieve file is created: %s\n" achieve_name)
		return(nil)
	)
		
	(unless (axlOSFileMove achieve_name achieve_addr)
		printf("File can't be moved: %s\n" achieve_name)
		return(nil)
	)
	
	printf("File is created: %s\n" achieve_name)
	
	return(t)
	)
)

(procedure create_dxf_cnv_Derek02222018(layer)
	(when (outportp (out_port = (outfile cnv_filename)))
		(fprintf out_port "BOARD GEOMETRY!\n")
		(fprintf out_port "\tLOGO!\t%s_LOGO!\n" layer)
		(fprintf out_port "\tOUTLINE!\tBG_OUTLINE!\n")
		
		(fprintf out_port "DRAWING FORMAT!\n")
		(fprintf out_port "\t%s!\tDF_%s!\n" layer layer)
		
		(fprintf out_port "ETCH!\n")
		(fprintf out_port "\t%s!\tET_%s!\n" layer layer)
		
		(fprintf out_port "PIN!\n")
		(fprintf out_port "\t%s!\tPIN_%s!\n" layer layer)
		(fprintf out_port "\tFILMMASK%s!\tPIN_FILMMASK%s!\n" layer layer)
		
		(fprintf out_port "VIA CLASS!\n")
		(fprintf out_port "\t%s!\tVC_%s!\n" layer layer)
		(close out_port)
	)
)

(procedure create_top_bot_dxf_Derek02222018()
	;;;;; create top dxf
	(dxf_filename = "TOP.dxf")
	create_dxf_cnv_Derek02222018("TOP")
	
	(axlVisibleDesign nil)
	(axlVisibleLayer "PIN/FILMMASKTOP" t)
	(axlVisibleLayer "VIA CLASS/TOP" t)
	(axlVisibleLayer "PIN/TOP" t)
	(axlVisibleLayer "ETCH/TOP" t)
	(axlVisibleLayer "DRAWING FORMAT/TOP" t)
	(axlVisibleLayer "BOARD GEOMETRY/OUTLINE" t)
	(axlVisibleLayer "BOARD GEOMETRY/LOGO" t)
	
	(when axlOKToProceed()
		(cmd = (strcat "a2dxf -u MILS -a 1 " cnv_filename " " dxf_filename " "  axlGetDrawingName()))
		axlRunBatchDBProgram("top_a2dxf" cmd ?startMsg "Export TOP DXF" ?silent t)
	)
	
	;;;;; create bot dxf
	(dxf_filename = "BOT.dxf")
	create_dxf_cnv_Derek02222018("BOTTOM")
	
	(axlVisibleDesign nil)
	(axlVisibleLayer "PIN/FILMMASKBOTTOM" t)
	(axlVisibleLayer "VIA CLASS/BOTTOM" t)
	(axlVisibleLayer "PIN/BOTTOM" t)
	(axlVisibleLayer "ETCH/BOTTOM" t)
	(axlVisibleLayer "DRAWING FORMAT/BOTTOM" t)
	(axlVisibleLayer "BOARD GEOMETRY/OUTLINE" t)
	(axlVisibleLayer "BOARD GEOMETRY/LOGO" t)
	
	(when axlOKToProceed()
		(cmd = (strcat "a2dxf -u MILS -a 1 " cnv_filename " " dxf_filename " "  axlGetDrawingName()))
		axlRunBatchDBProgram("bottom_a2dxf" cmd ?startMsg "Export BOTTOM DXF" ?silent t)
	)
)

(procedure create_emn_emp_Derek02222018(out_name)
	(when (outportp (out_port = (outfile "iDfFilterOut.config")))
		(fprintf out_port (buildString (list "("
											"filter"
											"Route_Keepout_sym"
											"Route_Keepout_board"
											"Via_Keepout_sym"
											"Via_Keepout_board"
											"Vias"
											"Panel_Outline"
											"Route_Outline"
											"Package_Keepin"
											"Package_Keepout"
											"Unplaced_Comp"
											")" "  ")))
		(close out_port)
	)
	
	(when axlOKToProceed()
		(cmd = (strcat "idf_out %s -d PTC -o " out_name " -V 3.0 -b 1 -s \"" allegro_version "\" -h 1 -c iDfFilterOut.config"))
		axlRunBatchDBProgram("emn_emp_idf_out" cmd ?startMsg "Export EMN EMP" ?silent t)
	)
)

(procedure delete_extra_file_Derek02222018(file_ls @optional (dir "."))
	(let (addr)
	;;;;; while using the recursive, addr variable will be overwrited by the next stage called function
	
	(foreach file file_ls
		(addr = (strcat dir "/" file))
		(when (isFile addr) (deleteFile addr))
		(when (and (isDir addr) (not (member file '("." ".."))))
			(delete_extra_file_Derek02222018 (getDirFiles addr) addr)
			(deleteDir addr)
		)
	)
		
	)
)

(procedure create_odb_Derek02222018(exe_addr file_names)
	(prog ()
	
	;;;;; import valor.il
	(valor_addr = (strcat getShellEnvVar("ALLEGRO_BRD2ODB") "/valor_ext.il"))
	(unless (isFile valor_addr)
		printf("No file has been found: %s\n" valor_addr)
		return(nil)
	)
	(load valor_addr)
	valor_extract_info()
	;;;;; 
	
	sprintf(cmd "%s -lp \"%s\" -a2l -c p -jn odbjob -jp \"%s\" -no_view -gz -read_sqa no -tr_sym yes -p s -pst r -skip_refdes no -sp \"%s\"" exe_addr work_path work_path work_addr)
	axlRunBatchDBProgram("flex_brd2odb" cmd ?noUnload t ?noProgress nil)
	)
)

(procedure create_script_file_Derek02222018(script_name)
	(when (outportp (out_port = (outfile script_name "w")))
		(fprintf out_port "#A!REFDES!COMP_CLASS!COMP_PART_NUMBER!COMP_HEIGHT!COMP_DEVICE_LABEL!COMP_INSERTION_CODE!SYM_TYPE\n")    
		(fprintf out_port "#!SYM_NAME!SYM_MIRROR!SYM_ROTATE!SYM_X!SYM_Y!COMP_VALUE!COMP_TOL!COMP_VOLTAGE!\n")    
		(fprintf out_port "COMPONENT \n")
		(fprintf out_port "REFDES \n")    
		(fprintf out_port "COMP_CLASS \n")    
		(fprintf out_port "COMP_PART_NUMBER \n")    
		(fprintf out_port "COMP_HEIGHT \n")    
		(fprintf out_port "COMP_DEVICE_LABEL \n")    
		(fprintf out_port "COMP_INSERTION_CODE \n")    
		(fprintf out_port "SYM_TYPE \n")    
		(fprintf out_port "SYM_NAME \n")    
		(fprintf out_port "SYM_MIRROR \n")    
		(fprintf out_port "SYM_ROTATE \n")    
		(fprintf out_port "SYM_X \n")    
		(fprintf out_port "SYM_Y \n")    
		(fprintf out_port "COMP_VALUE \n")    
		(fprintf out_port "COMP_TOL \n")    
		(fprintf out_port "COMP_VOLTAGE \n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!NET_NAME!REFDES!PIN_NUMBER!PIN_NAME!PIN_GROUND!PIN_POWER!\n")    
		(fprintf out_port "COMPONENT_PIN \n")    
		(fprintf out_port "\n")    
		(fprintf out_port "NET_NAME \n")    
		(fprintf out_port "REFDES \n")    
		(fprintf out_port "PIN_NUMBER \n")    
		(fprintf out_port "PIN_NAME \n")    
		(fprintf out_port "PIN_GROUND \n")    
		(fprintf out_port "PIN_POWER \n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!CLASS!SUBCLASS!\n")    
		(fprintf out_port "GEOMETRY \n")    
		(fprintf out_port "\n")    
		(fprintf out_port "CLASS!=\"VIA CLASS\" \n")    
		(fprintf out_port "CLASS!=\"PIN\" \n")    
		(fprintf out_port "CLASS!=\"PACKAGE GEOMETRY\" \n")    
		(fprintf out_port "CLASS!=\"ETCH\" \n")    
		(fprintf out_port "OR \n")    
		(fprintf out_port "CLASS=\"ETCH\" \n")    
		(fprintf out_port "CLASS \n")    
		(fprintf out_port "SUBCLASS \n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!PAD_NAME!REC_NUMBER!LAYER!FIXFLAG!VIAFLAG!PADSHAPE1!PADWIDTH!PADHGHT!PADXOFF!PADYOFF!\n")    
		(fprintf out_port "#PADFLASH!PADSHAPENAME!TRELSHAPE1!TRELWIDTH!TRELHGHT!TRELXOFF!TRELYOFF!TRELFLASH!TRELSHAPENAME!\n")    
		(fprintf out_port "#APADSHAPE1!APADWIDTH!APADHGHT!APADXOFF!APADYOFF!APADFLASH!APADSHAPENAME!\n")    
		(fprintf out_port "PAD_DEF \n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!GRAPHIC_DATA_NAME!GRAPHIC_DATA_NUMBER!RECORD_TAG!GRAPHIC_DATA_1!GRAPHIC_DATA_2!GRAPHIC_DATA_3!GRAPHIC_DATA_4\n")    
		(fprintf out_port "#!GRAPHIC_DATA_5!GRAPHIC_DATA_6!GRAPHIC_DATA_7!GRAPHIC_DATA_8!GRAPHIC_DATA_9!SUBCLASS!SYM_NAME!REFDES!\n")    
		(fprintf out_port "GEOMETRY \n")    
		(fprintf out_port "CLASS=\"PACKAGE GEOMETRY\" \n")    
		(fprintf out_port "\n")    
		(fprintf out_port "GRAPHIC_DATA_NAME \n")    
		(fprintf out_port "GRAPHIC_DATA_NUMBER \n")    
		(fprintf out_port "RECORD_TAG \n")    
		(fprintf out_port "GRAPHIC_DATA_1 \n")    
		(fprintf out_port "GRAPHIC_DATA_2 \n")    
		(fprintf out_port "GRAPHIC_DATA_3 \n")    
		(fprintf out_port "GRAPHIC_DATA_4 \n")    
		(fprintf out_port "GRAPHIC_DATA_5 \n")    
		(fprintf out_port "GRAPHIC_DATA_6 \n")    
		(fprintf out_port "GRAPHIC_DATA_7 \n")    
		(fprintf out_port "GRAPHIC_DATA_8 \n")    
		(fprintf out_port "GRAPHIC_DATA_9 \n")    
		(fprintf out_port "SUBCLASS \n")    
		(fprintf out_port "SYM_NAME \n")    
		(fprintf out_port "REFDES \n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!SYM_NAME!SYM_MIRROR!PIN_NAME!PIN_NUMBER!PIN_X!PIN_Y!PAD_STACK_NAME!REFDES!PIN_ROTATION!TEST_POINT!\n")    
		(fprintf out_port "COMPOSITE_PAD \n")    
		(fprintf out_port "CLASS!=\"VIA CLASS\" \n")    
		(fprintf out_port "\n")    
		(fprintf out_port "SYM_NAME \n")    
		(fprintf out_port "SYM_MIRROR\n")    
		(fprintf out_port "PIN_NAME \n")    
		(fprintf out_port "PIN_NUMBER \n")    
		(fprintf out_port "PIN_X \n")    
		(fprintf out_port "PIN_Y \n")    
		(fprintf out_port "PAD_STACK_NAME \n")    
		(fprintf out_port "REFDES \n")    
		(fprintf out_port "PIN_ROTATION\n")    
		(fprintf out_port "TEST_POINT \n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!VIA_X!VIA_Y!PAD_STACK_NAME!NET_NAME!TEST_POINT!VIA_MIRROR!\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "COMPOSITE_PAD \n")    
		(fprintf out_port "CLASS=\"VIA CLASS\" \n")    
		(fprintf out_port "\n")    
		(fprintf out_port "VIA_X \n")    
		(fprintf out_port "VIA_Y \n")    
		(fprintf out_port "PAD_STACK_NAME \n")    
		(fprintf out_port "NET_NAME \n")    
		(fprintf out_port "TEST_POINT \n")    
		(fprintf out_port "VIA_MIRROR\n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!CLASS!SUBCLASS!GRAPHIC_DATA_NAME!GRAPHIC_DATA_NUMBER!RECORD_TAG!GRAPHIC_DATA_1!\n")    
		(fprintf out_port "#GRAPHIC_DATA_2!GRAPHIC_DATA_3!GRAPHIC_DATA_4!GRAPHIC_DATA_5!GRAPHIC_DATA_6!GRAPHIC_DATA_7!\n")    
		(fprintf out_port "#GRAPHIC_DATA_8!GRAPHIC_DATA_9!NET_NAME!\n")    
		(fprintf out_port "GEOMETRY \n")    
		(fprintf out_port "CLASS!=\"VIA CLASS\" \n")    
		(fprintf out_port "CLASS!=\"PIN\" \n")    
		(fprintf out_port "CLASS!=\"PACKAGE GEOMETRY\" \n")    
		(fprintf out_port "CLASS!=\"ETCH\" \n")    
		(fprintf out_port "OR \n")    
		(fprintf out_port "CLASS=\"ETCH\" \n")    
		(fprintf out_port "\n")    
		(fprintf out_port "CLASS \n")    
		(fprintf out_port "SUBCLASS \n")    
		(fprintf out_port "GRAPHIC_DATA_NAME \n")    
		(fprintf out_port "GRAPHIC_DATA_NUMBER \n")    
		(fprintf out_port "RECORD_TAG \n")    
		(fprintf out_port "GRAPHIC_DATA_1 \n")    
		(fprintf out_port "GRAPHIC_DATA_2 \n")    
		(fprintf out_port "GRAPHIC_DATA_3 \n")    
		(fprintf out_port "GRAPHIC_DATA_4 \n")    
		(fprintf out_port "GRAPHIC_DATA_5 \n")    
		(fprintf out_port "GRAPHIC_DATA_6 \n")    
		(fprintf out_port "GRAPHIC_DATA_7 \n")    
		(fprintf out_port "GRAPHIC_DATA_8 \n")    
		(fprintf out_port "GRAPHIC_DATA_9 \n")    
		(fprintf out_port "NET_NAME \n")    
		(fprintf out_port "END\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "#A!SUBCLASS!PAD_SHAPE_NAME!GRAPHIC_DATA_NAME!GRAPHIC_DATA_NUMBER!RECORD_TAG!GRAPHIC_DATA_1!\n")    
		(fprintf out_port "#GRAPHIC_DATA_2!GRAPHIC_DATA_3!GRAPHIC_DATA_4!GRAPHIC_DATA_5!GRAPHIC_DATA_6!GRAPHIC_DATA_7!GRAPHIC_DATA_8!\n")    
		(fprintf out_port "#GRAPHIC_DATA_9!PAD_STACK_NAME!REFDES!PIN_NUMBER!\n")    
		(fprintf out_port "FULL_GEOMETRY\n")    
		(fprintf out_port "REFDES!=\"\"\n")    
		(fprintf out_port "PAD_STACK_NAME!=\"\"\n")    
		(fprintf out_port "GRAPHIC_DATA_NAME=\"LINE\"\n")    
		(fprintf out_port "\n")    
		(fprintf out_port "SUBCLASS\n")    
		(fprintf out_port "PAD_SHAPE_NAME\n")    
		(fprintf out_port "GRAPHIC_DATA_NAME\n")    
		(fprintf out_port "GRAPHIC_DATA_NUMBER\n")    
		(fprintf out_port "RECORD_TAG\n")    
		(fprintf out_port "GRAPHIC_DATA_1\n")    
		(fprintf out_port "GRAPHIC_DATA_2\n")    
		(fprintf out_port "GRAPHIC_DATA_3\n")    
		(fprintf out_port "GRAPHIC_DATA_4\n")    
		(fprintf out_port "GRAPHIC_DATA_5\n")    
		(fprintf out_port "GRAPHIC_DATA_6\n")    
		(fprintf out_port "GRAPHIC_DATA_7\n")    
		(fprintf out_port "GRAPHIC_DATA_8\n")    
		(fprintf out_port "GRAPHIC_DATA_9\n")    
		(fprintf out_port "PAD_STACK_NAME\n")    
		(fprintf out_port "REFDES\n")    
		(fprintf out_port "PIN_NUMBER\n")    
		(close out_port)
	)
)

(defun create_cad_Derek02222018 (cad_name)
	(prog ()
	
	(script_name = "cds2fab.txt")
	
	create_script_file_Derek02222018(script_name)

	(sprintf cmd "extracta %s.brd %s exa1.out exa2.out exa3.out exa4.out exa5.out exa6.out exa7.out exa8.out exa9.out" work_name script_name)
	(axlRunBatchDBProgram "cad_extracta" cmd ?noUnload t ?noProgress nil)
	
	(sprintf cmd "copy exa*.out %s" cad_name)
	(shell cmd)
	
	;;;;; this line is used to wait the system to merge the *.out to cad. don't delete it
	axlUIConfirm("CAD .out files have been created.")
	
	)
)

(procedure create_artwork_param_Derek02222018()
	(filename = (strcat art_dir "/art_param.txt"))
	
	(when (outportp (out_port = (outfile filename "w")))
		(fprintf out_port "DEVICE-TYPE           GERBER_RS274X\n")
		(fprintf out_port "OUTPUT-UNITS          INCHES\n")
		(fprintf out_port "FILM-SIZE             2400000 1600000\n")
		(fprintf out_port "FORMAT                5.5\n")
		(fprintf out_port "ABORT-ON-ERROR        NO\n")
		(fprintf out_port "SCALE                 1\n")
		(fprintf out_port "SUPPRESS-LEAD-ZEROES  YES\n")
		(fprintf out_port "SUPPRESS-TRAIL-ZEROES NO\n")
		(fprintf out_port "SUPPRESS-EQUAL        YES\n")
		(fprintf out_port "UNDEF-APT-CONT        NO\n")
		(close out_port)
	)
)

(procedure create_drill_parameter_Derek02222018()
	;(bd_opt = (if backdrill_b "YES" "NO"))
	
	(when (outportp (out_port = (outfile (strcat art_dir "/nc_param.txt") "w")))
		(fprintf out_port "INTEGER-PLACES         5\n")
		(fprintf out_port "DECIMAL-PLACES         5\n")
		(fprintf out_port "X-OFFSET               0.000000\n")
		(fprintf out_port "Y-OFFSET               0.000000\n")
		(fprintf out_port "FEEDRATE               1\n")
		(fprintf out_port "COORDINATES            ABSOLUTE\n")
		(fprintf out_port "OUTPUT-UNITS           ENGLISH\n")
		(fprintf out_port "TOOL-ORDER             DECREASING\n")
		(fprintf out_port "REPEAT-CODES           NO\n")
		(fprintf out_port "SUPPRESS-LEAD-ZEROES   YES\n")
		(fprintf out_port "SUPPRESS-TRAIL-ZEROES  NO\n")
		(fprintf out_port "SUPPRESS-EQUAL         NO\n")
		(fprintf out_port "TOOL-SELECT            YES\n")
		(fprintf out_port "OPTIMIZE_DRILLING      NO\n")
		(fprintf out_port "ENHANCED_EXCELLON      YES\n")
		(fprintf out_port "HEADER                 none\n")
		(fprintf out_port "LEADER                 12\n")
		(fprintf out_port "CODE                   ASCII\n")
		(fprintf out_port "SEPARATE               YES\n")
		(fprintf out_port "SEPARATE-ROUTING       YES\n")
		(fprintf out_port "DRILLING               LAYER-PAIR\n")
		(fprintf out_port "BACKDRILL              YES\n")
		(fprintf out_port "CAVITY                 NO\n")
		(close out_port)
	)
)

;(procedure has_drill_Derek02222018()
;	(let (art_ls (get_drl nil))
;		(art_ls = axlGetParam("artwork")->groupMembers)
;		(foreach art art_ls
;			(cond
;				;;;;; if there is any layer having backdrill
;				((index art "-BD-") (get_drl = t))
;				;;;;; if there is any layer having laser 
;				((index art "-DRILL-") (get_drl = t))
;			)
;		)
;		
;		get_drl
;	)
;)

(procedure create_drill_Derek02222018()
	;(backdrill_b = has_drill_Derek02222018())
	create_drill_parameter_Derek02222018()
	
	;(if backdrill_b
	(sprintf cmd "nctape -b %s.brd" work_name)
	;	(sprintf cmd "nctape %s.brd" work_name)
	;)
	(axlRunBatchDBProgram "back_drill_nctape" cmd ?noUnload t ?noProgress nil)
	
	(sprintf cmd "ncroute %s.brd" work_name)
	(axlRunBatchDBProgram "back_drill_ncroute" cmd ?noUnload t ?noProgress nil)
)

(defun create_gbr_Derek02222018 (ipc_name)
	create_artwork_param_Derek02222018()
	
	;;;;; create artwork
	(sprintf cmd "artwork %s.brd" work_name)
	(axlRunBatchDBProgram "gbr_artwork" cmd ?noUnload t ?noProgress nil ?noLogview t)
	
	;;;;; create ipc356
	(sprintf ipc_name gerber_file_term ".ipc")
	(sprintf cmd "ipc356_out -A %s.brd %s" work_name ipc_name)
	(axlRunBatchDBProgram "flex_ipc356_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
	(axlOSFileMove ipc_name (strcat art_dir "/" ipc_name))
	
	;;;;; create backdrill
	create_drill_Derek02222018()
	
	;;;;; this is used to wait all three group file storing into artwork
	axlUIConfirm("All GBR package has been created")
)

(procedure create_panel_Derek02222018(file_names)
	(prog ()
	
	(panel = (car (setof x axlGetParam("artwork")->groupMembers (index x "PANEL"))))
	(unless (stringp panel)
		println("No panel has been found in Artwork")
		return(nil)
	)
	
	(sprintf cmd "pdf_out %s.brd -o %s -f %s -r -B -x -n -m -T" work_name file_names panel)
	axlRunBatchDBProgram("panel_pdf_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
	
	)
)

(defun create_gbr_pdf_Derek02222018 (file_names)
	; axlGetParam("artwork:05-L2_GND1")
	; a->groupMembers = '("DRAWING FORMAT/GND1" "BOARD GEOMETRY/OUTLINE" "BOARD GEOMETRY/LOGO" "ETCH/L2_GND1" "PIN/L2_GND1" "VIA CLASS/L2_GND1")
	(film_ls = axlGetParam("artwork")->groupMembers)
	(cmd_film = (strcat "-f " (buildString film_ls " -f ")))
	(sprintf cmd "pdf_out %s.brd -o %s %s -r -B -x -n -m -T" work_name file_names cmd_film)
	axlRunBatchDBProgram("gbr_pdf_pdf_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
)

(defun create_pcba_Derek02222018 (file_names)
	(p_top = "PCBA_TOP")
	(p_bot = "PCBA_BOT")
	
	(pcba_top_layer = '("Board Geometry/outline"
						"Board Geometry/assembly_notes"
						"Board Geometry/logo"
						"Ref Des/silkscreen_top"
						"Pin/Top"
						"Board Geometry/silkscreen_top"
						"Package Geometry/silkscreen_top"
						"Component Value/silkscreen_top"
						"Drawing Format/pcba_top"))
						
	(pcba_bot_layer = '("Board Geometry/outline"
						"Board Geometry/assembly_notes"
						"Board Geometry/logo"
						"Ref Des/silkscreen_bottom"
						"Pin/Top"
						"Board Geometry/silkscreen_bottom"
						"Package Geometry/silkscreen_bottom"
						"Component Value/silkscreen_bottom"
						"Drawing Format/pcba_bot"))
	
	;;;;; create pcba top/bottom
	(axlfcreate p_top '(0 0 0 500 100 1 0 0 0 0 0 0 1) pcba_top_layer)
	(axlfcreate p_bot '(0 0 0 500 100 1 1 0 0 0 0 0 1) pcba_bot_layer)
	
	;;;;; export pdf
	(axlSaveDesign ?design "temp" ?mode "nocheck" ?noMru t ?noConfirm t ?writeModel t)
	(sprintf cmd "pdf_out temp.brd -o %s -f %s -f %s -r -B -x -n -m -T" file_names p_top p_bot)
	(axlRunBatchDBProgram "pcba_pdf_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
	
	;;;;; delete pcba top/bottom
	(axlDeleteObject (axlGetParam (strcat "artwork:" p_top)))
	(axlDeleteObject (axlGetParam (strcat "artwork:" p_bot)))
)

(defun create_gerber_items_Derek02222018 ()
	;;;;; get current files
	(old_file_ls = (getDirFiles getWorkingDir()))
	
	;	3.<brd name>_date(brd).7z
	(when axlOKToProceed()
		(achieve_name = (sprintf nil gerber_file_term "(brd)"))
		(file_names = (strcat axlCurrentDesign() ".brd"))
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	;	4.<brd name>_date(dxf).7z
	(when axlOKToProceed()
		(achieve_name = (sprintf nil gerber_file_term "(dxf)"))
		(file_names = '("TOP.dxf" "BOT.dxf"))
		create_top_bot_dxf_Derek02222018()
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	;	5.<brd name>_date(emn_emp).7z
	(when axlOKToProceed()
		(achieve_name = (sprintf nil gerber_file_term "(emn_emp)"))
		(out_name = (sprintf nil gerber_file_term ""))
		(file_names = (list (strcat out_name ".emn") (strcat out_name ".emp")))
		create_emn_emp_Derek02222018(out_name)
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	;	6.<brd name>_date(odb++).7z
	(when axlOKToProceed()
		(achieve_name = (sprintf nil gerber_file_term "(odb++)"))
		(file_names = "odbjob.tgz")
		
		(exe_addr = (strcat getShellEnvVar("ALLEGRO_BRD2ODB") "\\brd2odb.exe"))
		
		(if (isFile exe_addr) then
			create_odb_Derek02222018(exe_addr file_names)
			(archieve_7z_Derek02222018 file_names achieve_name)
		else
			println("No ODB++ found - Please install ODB++ before using this function")
		)
	)
	
	;	7.<brd name>_date(cad).7z
	(when axlOKToProceed()
		(sprintf cad_name gerber_file_term "(cad).cad")
		(achieve_name = (sprintf nil gerber_file_term "(cad)"))
		(file_names = cad_name)
		
		create_cad_Derek02222018(cad_name)
		
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	
	;	8.<brd name>_date(gbr).7z
	(when axlOKToProceed()
		(sprintf ipc_name gerber_file_term ".ipc")
		(achieve_name = (sprintf nil gerber_file_term "(gbr)"))
		;;;;; all artwork, ipc356, open short in gerber tool
		create_gbr_Derek02222018(ipc_name)
		(file_names = (cddr (getDirFiles art_dir)))
		
		;;;;; artwork.txt and .ipc
		(foreach file file_names (axlOSFileCopy (strcat art_dir "/" file) (strcat work_path "/" file) nil))
		; (file_names = (mapcar (lambda (x) (strcat art_dir "\\" x)) art_file_ls))
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	;	10.<brd name>_date(panel).7z
	(when axlOKToProceed()
		(achieve_name = (sprintf nil gerber_file_term "(panel)"))
		(file_names = (sprintf nil gerber_file_term "(panel).pdf"))
		create_panel_Derek02222018(file_names)
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	;	11.<brd name>_date(pcba).7z
	(when axlOKToProceed()
		(achieve_name = (sprintf nil gerber_file_term "(pcba)"))
		(file_names = (sprintf nil gerber_file_term "(pcba).pdf"))
		create_pcba_Derek02222018(file_names)
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	;	12.<brd name>_date(gbr_pdf).7z
	(when axlOKToProceed()
		(achieve_name = (sprintf nil gerber_file_term "(gbr_pdf)"))
		(file_names = (sprintf nil gerber_file_term "(gbr_pdf).pdf"))
		create_gbr_pdf_Derek02222018(file_names)
		(archieve_7z_Derek02222018 file_names achieve_name)
	)
	
	;	13.<brd name>_component.txt
	(when axlOKToProceed()
		(out_name = (sprintf nil (strcat gerber_file_term "_component.txt") ""))
		(cmd = (strcat "report -v cmp %s " out_name))
		axlRunBatchDBProgram("component_report" cmd ?startMsg "Export Component Report" ?silent t ?noLogview t)
		(axlOSFileMove out_name (strcat gerber_dir "\\" out_name))
	)
	
	;;;;; get all files
	(new_file_ls = (getDirFiles getWorkingDir()))
	(added_file_ls = (setof x new_file_ls (not (member x old_file_ls))))
	delete_extra_file_Derek02222018(added_file_ls) ;***************************************************************************************************************
)

(defun gerber_tool_main_Derek02222018 ()
	(prog ()
	;;;;; prog function used to escape the program while the condition not meet
	(unless init_Derek02222018() return(nil))
	
	;;;;; create a new getber package directory anyway
	(if (isDir gerber_dir)
		delete_extra_file_Derek02222018((getDirFiles gerber_dir) gerber_dir)
		(createDir gerber_dir)
	)
	(unless (isDir gerber_dir) println("Gerber directory can't be created. Process halt") return(nil))
	
	;;;;; test whether the 7z command is exists
	(unless (sh "\"C:\\Program Files\\7-Zip\\7z\"")
		println("Please install 7z or it isn't installed in the default path. Process halt")
		return(nil)
	)
	
	;;;;; store display setting
	(ori_display = axlVisibleGet())
	
	;;;;; create item iterally
	create_gerber_items_Derek02222018()
	
	;;;;; restore display setting
	axlVisibleSet(ori_display)
	axlVisibleUpdate(t)
	
	axlUIConfirm("The process is done")
	
	return(t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

; (gerber_tool_main_Derek02222018)
(axlCmdRegister "gerber_tool" 'gerber_tool_main_Derek02222018)
; skill encrypt( "C:/skill/gerber_tool_v1.il" "C:/skill/gerber_tool_v1.ile")
; (load "gerber_tool_v1.il")
; (load "gerber_tool_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup