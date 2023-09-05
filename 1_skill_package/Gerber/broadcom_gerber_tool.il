;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTRODUCTION
;
; Developer: Derek Hsu
; Starting Date: 11/1/2018 - _Derek11012018
; Description: a gerber tool for broadcom
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF INTRODUCTION

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; GLOBAL VARIABLE

(defun init_Derek11012018 ()
	(setq broadcom_gb_nm "broadcom_gerber_tool_panel.form")
	(setq ascii_file_nm "valext.txt")
	(setq zip_ext ".zip")
	
	(setq tot_opt 14) ;;; 14 is a total number of (length all_ls) + 4 None options
	(setq pre_opt_ls '(t t t nil t t t t nil t t nil t nil)) ;; options for 14 default setting
	(setq rel_opt_ls '(t t t nil t t t t nil t t nil t nil))
	(setq non_opt_ls '(nil nil nil t nil nil nil nil t nil nil t nil t))
	(setq all_ls '("fab_odb" "fab_fab" "fab_assem" "ict_odb" "ict_fab" "ict_axcii" "ict_fabm" "mec_idf" "mec_dxf" "cad_brd"))
	(setq fab_ls '("fab_odb" "fab_fab" "fab_assem"))
	(setq ict_ls '("ict_odb" "ict_fab" "ict_axcii" "ict_fabm"))
	(setq mec_ls '("mec_idf" "mec_dxf"))
	(setq cad_ls '("cad_brd"))
	
	;;;;;
	
	(setq work_name axlCurrentDesign())
	(setq work_name_max_num 64)
	(setq work_path getWorkingDir())
	(setq work_addr axlGetDrawingName())
	(setq mon_ls (list nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	(sscanf getCurrentTime() "%s %d %d:%d:%d %d" mon date hr min sec year)
	(setq today (sprintf nil "%.2d%.2d%.4d" (listnindex mon_ls mon) date year))
	(setq time (sprintf nil "%.2d%.2d%.2d" hr min sec))
	(setq zip_nm_format (sprintf nil "%s%%s_%s%%s" work_name today))
	(setq out_format (sprintf nil "%s_%%s" work_name))
	(setq broadcom_dir_name (sprintf nil "%s_deliverables_%s_%s" work_name today time))
	
	;;;;;
	
	(setq opt_table (makeTable 'opt_table nil))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF GLOBAL VARIABLE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FORM

(procedure build_form_Derek11012018()
	(prog (out_port group_width group_x content_x)
		(unless (outportp (out_port = (outfile broadcom_gb_nm "w"))) println("Fail to create form file") (return nil))
		;;
		
		(group_width = 20)
		(group_x = 1)
		(content_x = 3)
		
		(fprintf out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		(fprintf out_port "FORM TOOLWINDOW \n")	
		(fprintf out_port "FIXED\n")
		(fprintf out_port "PORT %d %d\n" (add1 group_width) 100)
		(fprintf out_port "HEADER \"broadcom Gerber Tool\"\n")
		(fprintf out_port "TILE\n")
		
		;;;;; control panel
		
		(y_cnt = 1)
		(y_start = y_cnt)
		
		(fprintf out_port "FIELD %s\n" 'ctrl_pre)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" %s\" \"%s\" \n" 'Preliminary 'ctrl)
		(fprintf out_port "ENDFIELD\n")

		(fprintf out_port "FIELD %s\n" 'ctrl_rel)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" %s\" \"%s\" \n" 'Release 'ctrl)
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "FIELD %s\n" 'ctrl_non)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" %s\" \"%s\" \n" 'None 'ctrl)
		(fprintf out_port "ENDFIELD\n")
			
		(fprintf out_port "GROUP \"%s\"\n" 'Control)
		(fprintf out_port "FLOC %d %d\n" group_x y_start)
		(fprintf out_port "TSSIZE %d %d\n" group_width (y_cnt - y_start + 2))
		(fprintf out_port "ENDGROUP\n")
		
		;;;;; revision
		
		(fprintf out_port "TEXT \"Revision:\" \n")
		(fprintf out_port "FLOC %d %d\n" (add1 group_x) (y_cnt = (y_cnt + 3)))
		(fprintf out_port "ENDTEXT\n")
		
		(fprintf out_port "FIELD %s\n" 'rev)
		(fprintf out_port "FLOC %d %d\n" (content_x + 7) y_cnt)
		(fprintf out_port "INTSLIDEBAR %d %d\n" 7 7)
		(fprintf out_port "MIN %d\n" -1)
		(fprintf out_port "MAX %d\n" 100)
		(fprintf out_port "ENDFIELD\n")
		
		;;;;; fabrication
		
		(y_cnt = (y_cnt + 2))
		(y_start = y_cnt)
		
		(fprintf out_port "FIELD %s\n" 'fab_odb)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" ODB++\" \n")
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "FIELD %s\n" 'fab_fab)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" Fab Dwg\" \n")
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "FIELD %s\n" 'fab_assem)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" Assem Dwg\" \n")
		(fprintf out_port "ENDFIELD\n")

		(fprintf out_port "FIELD %s\n" 'fab_none)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" %s\" \n" 'None)
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "GROUP \"%s\"\n" "Fabrication")
		(fprintf out_port "FLOC %d %d\n" group_x y_start)
		(fprintf out_port "TSSIZE %d %d\n" group_width (y_cnt - y_start + 2))
		(fprintf out_port "ENDGROUP\n")
		
		;;;;; in circuit test
		
		(y_cnt = (y_cnt + 2))
		(y_start = y_cnt)
		
		(fprintf out_port "FIELD %s\n" 'ict_odb)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" ODB++\" \n")
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "FIELD %s\n" 'ict_fab)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" Fab Dwg\" \n")
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "FIELD %s\n" 'ict_axcii)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" ASCII\" \n")
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "FIELD %s\n" 'ict_fabm)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" Fabmaster\" \n")
		(fprintf out_port "ENDFIELD\n")

		(fprintf out_port "FIELD %s\n" 'ict_none)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" %s\" \n" 'None)
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "GROUP \"%s\"\n" "In Circuit Test")
		(fprintf out_port "FLOC %d %d\n" group_x y_start)
		(fprintf out_port "TSSIZE %d %d\n" group_width (y_cnt - y_start + 2))
		(fprintf out_port "ENDGROUP\n")
		
		;;;;; mechanical
		
		(y_cnt = (y_cnt + 2))
		(y_start = y_cnt)
		
		(fprintf out_port "FIELD %s\n" 'mec_idf)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" IDF: EMN/EMP\" \n")
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "FIELD %s\n" 'mec_dxf)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" DXF: TOP/BOT\" \n")
		(fprintf out_port "ENDFIELD\n")

		(fprintf out_port "FIELD %s\n" 'mec_none)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" %s\" \n" 'None)
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "GROUP \"%s\"\n" "Mechanical")
		(fprintf out_port "FLOC %d %d\n" group_x y_start)
		(fprintf out_port "TSSIZE %d %d\n" group_width (y_cnt - y_start + 2))
		(fprintf out_port "ENDGROUP\n")
		
		;;;;; cad database
		
		(y_cnt = (y_cnt + 2))
		(y_start = y_cnt)
		
		(fprintf out_port "FIELD %s\n" 'cad_brd)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" Board\" \n")
		(fprintf out_port "ENDFIELD\n")

		(fprintf out_port "FIELD %s\n" 'cad_none)
		(fprintf out_port "FLOC %d %d\n" content_x (y_cnt = (y_cnt + 2)))
		(fprintf out_port "CHECKLIST \" %s\" \n" 'None)
		(fprintf out_port "ENDFIELD\n")
		
		(fprintf out_port "GROUP \"%s\"\n" "CAD Database")
		(fprintf out_port "FLOC %d %d\n" group_x y_start)
		(fprintf out_port "TSSIZE %d %d\n" group_width (y_cnt - y_start + 2))
		(fprintf out_port "ENDGROUP\n")
		
		;;;;; run
		
		(y_cnt = (y_cnt + 3))
		(y_start = y_cnt)
		
		(fprintf out_port "FIELD %s\n" 'run)
		(fprintf out_port "FLOC %d %d\n" group_x y_start)
		(fprintf out_port "MENUBUTTON \"RUN\" %d %d\n" group_width 2)
		(fprintf out_port "ENDFIELD\n\n")
		
		;;;;;
		
		(fprintf out_port "ENDTILE\n")
		(fprintf out_port "ENDFORM\n")
		
		(close out_port)
		
		(return t)
	)
)

(procedure set_form_opt_Derek11012018(out_form opt_ls)
	(prog ()
		(unless (dtpr opt_ls) println("ArgErr: set_form_opt_Derek11012018(0)") (return nil))
		(unless (eqv tot_opt (length opt_ls)) println("ArgErr: set_form_opt_Derek11012018(1)") (return nil))
		;;
		
		(axlFormSetField out_form "fab_odb" (nth 0 opt_ls))
		(axlFormSetField out_form "fab_fab" (nth 1 opt_ls))
		(axlFormSetField out_form "fab_assem" (nth 2 opt_ls))
		(axlFormSetField out_form "fab_none" (nth 3 opt_ls))
		(axlFormSetField out_form "ict_odb" (nth 4 opt_ls))
		(axlFormSetField out_form "ict_fab" (nth 5 opt_ls))
		(axlFormSetField out_form "ict_axcii" (nth 6 opt_ls))
		(axlFormSetField out_form "ict_fabm" (nth 7 opt_ls))
		(axlFormSetField out_form "ict_none" (nth 8 opt_ls))
		(axlFormSetField out_form "mec_idf" (nth 9 opt_ls))
		(axlFormSetField out_form "mec_dxf" (nth 10 opt_ls))
		(axlFormSetField out_form "mec_none" (nth 11 opt_ls))
		(axlFormSetField out_form "cad_brd" (nth 12 opt_ls))
		(axlFormSetField out_form "cad_none" (nth 13 opt_ls))
		
		(return t)
	)
)

(procedure out_form_action_Derek11012018(out_form)
	(prog (opt_ls rev ver ctrl_pre)
		(unless (axlIsFormType out_form) println("Fail to create form") (return nil))
		;;
		
		(field = out_form->curField)
		(val = out_form->curValue)
		
		(cond
			((and (equal "ctrl_pre" field) val)
				(set_form_opt_Derek11012018 out_form pre_opt_ls)
			)
			((and (equal "ctrl_rel" field) val)
				(set_form_opt_Derek11012018 out_form rel_opt_ls)
			)
			((and (equal "ctrl_non" field) val)
				(set_form_opt_Derek11012018 out_form non_opt_ls)
			)
			((and (equal "fab_none" field) val)
				(axlFormSetField out_form "fab_odb" nil)
				(axlFormSetField out_form "fab_fab" nil)
				(axlFormSetField out_form "fab_assem" nil)
			)
			((and (equal "ict_none" field) val)
				(axlFormSetField out_form "ict_odb" nil)
				(axlFormSetField out_form "ict_fab" nil)
				(axlFormSetField out_form "ict_axcii" nil)
				(axlFormSetField out_form "ict_fabm" nil)
			)
			((and (equal "mec_none" field) val)
				(axlFormSetField out_form "mec_idf" nil)
				(axlFormSetField out_form "mec_dxf" nil)
			)
			((and (equal "cad_none" field) val)
				(axlFormSetField out_form "cad_brd" nil)
			)
			((member field fab_ls)
				(if val then
					(axlFormSetField out_form "fab_none" nil)
				else
					(opt_ls = (mapcar (lambda (s) (axlFormGetField out_form s)) fab_ls))
					(unless (exists s opt_ls s) (axlFormSetField out_form "fab_none" t))
				)
			)
			((member field ict_ls)
				(if val then
					(axlFormSetField out_form "ict_none" nil)
				else
					(opt_ls = (mapcar (lambda (s) (axlFormGetField out_form s)) ict_ls))
					(unless (exists s opt_ls s) (axlFormSetField out_form "ict_none" t))
				)
			)
			((member field mec_ls)
				(if val then
					(axlFormSetField out_form "mec_none" nil)
				else
					(opt_ls = (mapcar (lambda (s) (axlFormGetField out_form s)) mec_ls))
					(unless (exists s opt_ls s) (axlFormSetField out_form "mec_none" t))
				)
			)
			((member field cad_ls)
				(if val then
					(axlFormSetField out_form "cad_none" nil)
				else
					(opt_ls = (mapcar (lambda (s) (axlFormGetField out_form s)) cad_ls))
					(unless (exists s opt_ls s) (axlFormSetField out_form "cad_none" t))
				)
			)
			((equal "run" field)
				(opt_ls = (mapcar (lambda (s) (axlFormGetField out_form s)) all_ls))
				
				(if (exists s opt_ls s) then
					(foreach opt all_ls (opt_table[opt] = (axlFormGetField out_form opt)))
					;;
					(ctrl_pre = (axlFormGetField out_form "ctrl_pre"))
					(ver = (if ctrl_pre "_PRELIM" ""))
					;;
					(rev = (axlFormGetField out_form "rev"))
					(rev = (if (eqv -1 rev) "" (sprintf nil "_rev%.3d" rev)))
					;;
					(zip_nm_format = (sprintf nil zip_nm_format rev ver))
					
					(axlFormClose out_form)
				else
					println("You have to have at least select one function to use this tool")
					
					(axlFormClose out_form)
				)
			)
		)
		
		(return t)
	)
)

(procedure set_form_Derek11012018(out_form)
	(prog ()
		(unless (axlIsFormType out_form) println("Fail to create form") (return nil))
		;;
		
		(axlFormSetField out_form "rev" -1)
		(axlFormSetField out_form "ctrl_pre" t)
		(set_form_opt_Derek11012018 out_form pre_opt_ls)
		
		(return t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF FORM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTION

(procedure archieve_zip_Derek11012018(file_addrs achieve_addr)
	(prog (file_name cmd)
		(unless (dtpr file_addrs) println("file_addrs has to be a list") (return nil))
		;;
		
		(file_addrs = (mapcar (lambda (x) (axlOSBackSlash x)) file_addrs))
		(foreach nm file_addrs (unless (isWritable nm) printf("No file has been found: %s\n" nm) (return nil)))
		(file_name = (buildString file_addrs " "))
		
		(achieve_addr = (axlOSBackSlash achieve_addr))
		(when (isWritable achieve_addr) printf("Exists achieve file: %s\n" achieve_addr) (return nil))
		
		(cmd = (buildString (list "\"C:\\Program Files\\7-Zip\\7z\"" "a" achieve_addr file_name) " "))
		(unless (sh cmd)
			printf("Fail to create achieve file: %s\n" achieve_addr)
			(return nil)
		)
		
		(return t)
	)
)

(procedure create_odb_Derek11012018(exe_addr file_name)
	(prog (valor_addr cmd)
		;;;;; import valor.il
		(valor_addr = (strcat getShellEnvVar("ALLEGRO_BRD2ODB") "/valor_ext.il"))
		(unless (load valor_addr) println("Fail to load Valor") (return nil))
		;;
		
		;;;; this function is extracted from (load valor_addr)
		println("Please click [No] for \"Do you want to extract net impedance average?\"")
		valor_extract_info()
		
		;;; help file address: C:\MentorGraphics\ODB++_Inside_Cadence_Allegro\Brd2odb_help.pdf
		;;; -lp - log path
		;;; -a21 - appends log messages to existing log file log_brd2odb
		;;; -c - <outline> / p[lacement] a[ssembly]
		;;; -jn - output ODB++ product model name
		;;; -jp - output path for the ODB++ product model
		;;; -no_view - without opening the ODB++ viewer
		;;; -read_sqa - [3, read sqa data] whether to create the signal quality layer
		;;; -tr_sym - [2, translation symbol] control the translation of symbol
		;;; -p - [2, padflash] s[ubstitude] / i[gnore]
		;;; -pst - [4, define symbol type of lines and arcs] r[ound] / s[quare]
		;;; -skip_refdes - [2, skip refdes with asterisk]
		;;; -sf - [4, turn 'eda_cadence_silk_fill' on]
		;;; -bb - [2, don't suppress pads on top/bottom]
		;;; -fi - [2, fully isolated pads]
		;;; -gui - More options
		(sprintf cmd "%s -lp \"%s\" -a2l -c a -jn \"%s\" -jp \"%s\" -no_view -gz -read_sqa no -tr_sym no -p i -pst r -skip_refdes no -sf -fi -bb -gui \"%s\""
				exe_addr work_path file_name work_path work_addr)
		(axlRunBatchDBProgram "flex_brd2odb" cmd ?noUnload t ?noProgress nil)
	)
)

(procedure create_pdf_Derek11012018(file_name film_ls)
	(prog (film cmd)
		(unless (stringp file_name) println("ArgErr: create_pdf_Derek11012018(0)") (return nil))
		(unless (dtpr film_ls) (return nil))
		;;
		
		(film = (strcat "-f " (buildString film_ls " -f ")))
		(sprintf cmd "pdf_out \"%s.brd\" -o \"%s\" %s -r -B -x -n -m -T" work_name file_name film)
		(axlRunBatchDBProgram "flex_pdf_out" cmd ?noUnload t ?noProgress nil ?noLogview t)
	
		(return t)
	)
)

(procedure create_ascii_cmd_file_Derek11012018()
	(prog (out_port)
		(unless (outportp (out_port = (outfile ascii_file_nm "w")))
			println("Fail to create a script file for ascii")
			(return nil)
		)
		;;
		
		(fprintf out_port "#\n")
		(fprintf out_port "# VALID ALLEGRO OUTPUT SCRIPT FOR CAMCAD\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This Script creates 5 files : BRD.TXT PAD.TXT SYM.TXT RTE.TXT SHP.TXT\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This is the new modified version May 92.\n")
		(fprintf out_port "# This is the new modified version APR 94.\n")
		(fprintf out_port "#      Component values, partnumber and type was added.\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This is the new modified version MAY 94. \n")
		(fprintf out_port "#      Pin Rotation was added. This only work from\n")
		(fprintf out_port "#      Allegro version 6.\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This is the new modified version JUN 94.\n")
		(fprintf out_port "#      Test point was added.\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This is the new modified version DEC 96.\n")
		(fprintf out_port "#      User properties added.\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# Board section was never used. Exchange it for Layer information\n")
		(fprintf out_port "#BOARD\n")
		(fprintf out_port "#       BOARD_NAME\n")
		(fprintf out_port "#       BOARD_UNITS\n")
		(fprintf out_port "#       BOARD_EXTENTS_X1\n")
		(fprintf out_port "#       BOARD_EXTENTS_Y1\n")
		(fprintf out_port "#       BOARD_EXTENTS_X2\n")
		(fprintf out_port "#       BOARD_EXTENTS_Y2\n")
		(fprintf out_port "#       BOARD_LAYERS\n")
		(fprintf out_port "#END\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This is the new modified version FEB 99.\n")
		(fprintf out_port "#      PIN_EDITED added 2-18-99 to recognize moved pins\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This is the new modified version OCT 2005.\n")
		(fprintf out_port "#      VIA_MIRROR added 10-02-2005 to recognize mirrored via instances\n")
		(fprintf out_port "#\n")
		(fprintf out_port "# This is the new modified version OCT 2007.\n")
		(fprintf out_port "#      SHP.TXT file added for complex pad shape support\n")
		(fprintf out_port "#\n")
		(fprintf out_port "\n")
		(fprintf out_port "# BRD.TXT file\n")
		(fprintf out_port "LAYER\n")
		(fprintf out_port "	LAYER_SORT\n")
		(fprintf out_port "	LAYER_SUBCLASS\n")
		(fprintf out_port "	LAYER_ARTWORK\n")
		(fprintf out_port "	LAYER_USE\n")
		(fprintf out_port "	LAYER_CONDUCTOR\n")
		(fprintf out_port "	LAYER_DIELECTRIC_CONSTANT\n")
		(fprintf out_port "	LAYER_ELECTRICAL_CONDUCTIVITY\n")
		(fprintf out_port "	LAYER_MATERIAL\n")
		(fprintf out_port "	LAYER_SHIELD_LAYER\n")
		(fprintf out_port "	LAYER_THERMAL_CONDUCTIVITY\n")
		(fprintf out_port "	LAYER_THICKNESS\n")
		(fprintf out_port "END\n")
		(fprintf out_port "\n")
		(fprintf out_port "# PAD.TXT file\n")
		(fprintf out_port "PAD_DEF\n")
		(fprintf out_port "END\n")
		(fprintf out_port "\n")
		(fprintf out_port "# SYM.TXT file\n")
		(fprintf out_port "GEOMETRY\n")
		(fprintf out_port "# GENERATES PLACEMENT, SYMBOL, AND ETCH INFORMATION\n")
		(fprintf out_port "  SYM_TYPE\n")
		(fprintf out_port "  SYM_NAME\n")
		(fprintf out_port "  REFDES_SORT\n")
		(fprintf out_port "  REFDES\n")
		(fprintf out_port "  SYM_X\n")
		(fprintf out_port "  SYM_Y\n")
		(fprintf out_port "  SYM_ROTATE\n")
		(fprintf out_port "  SYM_MIRROR\n")
		(fprintf out_port "  NET_NAME_SORT\n")
		(fprintf out_port "  NET_NAME\n")
		(fprintf out_port "  CLASS\n")
		(fprintf out_port "  SUBCLASS\n")
		(fprintf out_port "  RECORD_TAG\n")
		(fprintf out_port "  GRAPHIC_DATA_NAME\n")
		(fprintf out_port "  GRAPHIC_DATA_NUMBER\n")
		(fprintf out_port "  GRAPHIC_DATA_1\n")
		(fprintf out_port "  GRAPHIC_DATA_2\n")
		(fprintf out_port "  GRAPHIC_DATA_3\n")
		(fprintf out_port "  GRAPHIC_DATA_4\n")
		(fprintf out_port "  GRAPHIC_DATA_5\n")
		(fprintf out_port "  GRAPHIC_DATA_6\n")
		(fprintf out_port "  GRAPHIC_DATA_7\n")
		(fprintf out_port "  GRAPHIC_DATA_8\n")
		(fprintf out_port "  GRAPHIC_DATA_9\n")
		(fprintf out_port "  GRAPHIC_DATA_10\n")
		(fprintf out_port "  COMP_DEVICE_TYPE\n")
		(fprintf out_port "  COMP_PACKAGE\n")
		(fprintf out_port "  COMP_PART_NUMBER\n")
		(fprintf out_port "  COMP_VALUE\n")
		(fprintf out_port "# User Attributes are added here\n")
		(fprintf out_port "  VALUE\n")
		(fprintf out_port "# BARCODE\n")
		(fprintf out_port "# BOARD_FIDUCIAL\n")
		(fprintf out_port "# BOARD_TOOLING\n")
		(fprintf out_port "# BREAKAWAY\n")
		(fprintf out_port "# CUTOUT\n")
		(fprintf out_port "# PANEL_FIDUCIAL\n")
		(fprintf out_port "# PANEL_TOOLING\n")
		(fprintf out_port "# ROBBER_BAR\n")
		(fprintf out_port "# CLIP_DRAWING \n")
		(fprintf out_port "END\n")
		(fprintf out_port "\n")
		(fprintf out_port "# RTE.TXT file\n")
		(fprintf out_port "COMPOSITE_PAD\n")
		(fprintf out_port "# GENERATES VIA AND NETLIST INFORMATION\n")
		(fprintf out_port "  NET_NAME\n")
		(fprintf out_port "  PIN_NUMBER_SORT \n")
		(fprintf out_port "  CLASS\n")
		(fprintf out_port "  REFDES\n")
		(fprintf out_port "  SYM_TYPE\n")
		(fprintf out_port "  SYM_NAME\n")
		(fprintf out_port "  SYM_X\n")
		(fprintf out_port "  SYM_Y\n")
		(fprintf out_port "  SYM_ROTATE\n")
		(fprintf out_port "  SYM_MIRROR\n")
		(fprintf out_port "  PIN_NAME\n")
		(fprintf out_port "  PIN_NUMBER\n")
		(fprintf out_port "  PIN_X\n")
		(fprintf out_port "  PIN_Y\n")
		(fprintf out_port "# the PIN_EDITED command added 2-18-99 to recognize moved pins\n")
		(fprintf out_port "  PIN_EDITED      \n")
		(fprintf out_port "  PAD_STACK_NAME\n")
		(fprintf out_port "  VIA_X\n")
		(fprintf out_port "  VIA_Y\n")
		(fprintf out_port "# Added 10-02-2005 to recognize mirrored via instances\n")
		(fprintf out_port "  VIA_MIRROR\n")
		(fprintf out_port "# for Version 6\n")
		(fprintf out_port "  PIN_ROTATION\n")
		(fprintf out_port "  TEST_POINT\n")
		(fprintf out_port "  NET_PROBE_NUMBER\n")
		(fprintf out_port "END\n")
		(fprintf out_port "\n")
		(fprintf out_port "# Added 9-25-2007 for complex apertures\n")
		(fprintf out_port "# SHP.TXT not required for designs that \n")
		(fprintf out_port "# do not contain complex Apertures (shape pads)\n")
		(fprintf out_port "FULL_GEOMETRY\n")
		(fprintf out_port "  CLASS = \"PIN\"\n")
		(fprintf out_port "  # SUBCLASS = \"TOP\"\n")
		(fprintf out_port "  SUBCLASS\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"FIG_RECTANGLE\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"SQUARE\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"CIRCLE\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"OBLONG_Y\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"OBLONG_X\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"FIG_CIRCLE\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME != \"FIG_SQUARE\"\n")
		(fprintf out_port "  PAD_SHAPE_NAME \n")
		(fprintf out_port "  GRAPHIC_DATA_NAME\n")
		(fprintf out_port "  GRAPHIC_DATA_NUMBER\n")
		(fprintf out_port "  RECORD_TAG\n")
		(fprintf out_port "  GRAPHIC_DATA_1\n")
		(fprintf out_port "  GRAPHIC_DATA_2\n")
		(fprintf out_port "  GRAPHIC_DATA_3\n")
		(fprintf out_port "  GRAPHIC_DATA_4\n")
		(fprintf out_port "  GRAPHIC_DATA_5\n")
		(fprintf out_port "  GRAPHIC_DATA_6\n")
		(fprintf out_port "  GRAPHIC_DATA_7\n")
		(fprintf out_port "  GRAPHIC_DATA_8\n")
		(fprintf out_port "  GRAPHIC_DATA_9\n")
		(fprintf out_port "  PAD_STACK_NAME != \"\"\n")
		(fprintf out_port "  PAD_STACK_NAME\n")
		(fprintf out_port "  # REFDES != \"\"\n")
		(fprintf out_port "  REFDES\n")
		(fprintf out_port "  # PIN_NUMBER != \"\"\n")
		(fprintf out_port "  PIN_NUMBER\n")
		(fprintf out_port "END\n")
		(fprintf out_port "\n")
		(fprintf out_port "# End of VALEXT.txt\n")
		(close out_port)
		
		(return t)
	)
)

(procedure create_extracta_Derek11012018(script_name out_file_ls)
	(prog (cmd out_file)
		(unless (isFile script_name) printf("Fail to find %s\n" script_name) (return nil))
		(unless (dtpr out_file_ls) println("Output file has to be a list") (return nil))
		;;
		
		(out_file = (buildString out_file_ls " "))
		(sprintf cmd "extracta \"%s.brd\" \"%s\" %s" work_name script_name out_file)
		(axlRunBatchDBProgram "flex_extracta" cmd ?noUnload t ?noProgress nil)
		
		(return t)
	)
)

(procedure create_emn_emn_cfg_Derek11012018(cfg_filename)
	(let (out_port content)
		(if (outportp (out_port = (outfile cfg_filename))) then
			(content = (buildString (list "("
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
			(fprintf out_port content)
			(close out_port)
		else
			printf("Fail to write file [%s]\n" cfg_filename)
		)
	)
)

(procedure create_emn_emp_Derek11012018(out_name)
	(let ((cfg_filename "iDfFilterOut.config") cmd allegro_version)
		create_emn_emn_cfg_Derek11012018(cfg_filename)
		;;
		(when (isFile cfg_filename)
			(sprintf allegro_version "Allegro_%.1f_%s" axlVersion('version) axlVersion('buildDate))
			(sprintf cmd "idf_out \"%s\" -d PTC -o \"%s\" -V 3.0 -b 1 -s \"%s\" -h 1 -c %s" work_addr out_name allegro_version cfg_filename)
			(axlRunBatchDBProgram "emn_emp_idf_out" cmd ?startMsg "Export EMN EMP" ?silent t)
		)
	)
)

(procedure create_dxf_cnv_Derek11012018(layer cnv_filename)
	(let (out_port)
		(if (outportp (out_port = (outfile cnv_filename))) then
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
		else
			(printf "Fail to write file [%s]\n" cnv_filename)
		)
	)
)

(procedure create_top_bot_dxf_Derek11012018(dxf_top_nm dxf_bot_nm)
	(let ((cnv_filename "temp.cnv") cmd)
		;;;;; create top dxf
		create_dxf_cnv_Derek11012018("TOP" cnv_filename)
		
		(axlVisibleDesign nil)
		(axlVisibleLayer "PIN/FILMMASKTOP" t)
		(axlVisibleLayer "VIA CLASS/TOP" t)
		(axlVisibleLayer "PIN/TOP" t)
		(axlVisibleLayer "ETCH/TOP" t)
		(axlVisibleLayer "DRAWING FORMAT/TOP" t)
		(axlVisibleLayer "BOARD GEOMETRY/OUTLINE" t)
		(axlVisibleLayer "BOARD GEOMETRY/LOGO" t)
		
		(sprintf cmd "a2dxf -u MILS -a 1 \"%s\" \"%s\" \"%s\"" cnv_filename dxf_top_nm work_addr)
		(axlRunBatchDBProgram "top_a2dxf" cmd ?startMsg "Export TOP DXF" ?silent t)
		
		;;;;; create bot dxf
		create_dxf_cnv_Derek11012018("BOTTOM" cnv_filename)
		
		(axlVisibleDesign nil)
		(axlVisibleLayer "PIN/FILMMASKBOTTOM" t)
		(axlVisibleLayer "VIA CLASS/BOTTOM" t)
		(axlVisibleLayer "PIN/BOTTOM" t)
		(axlVisibleLayer "ETCH/BOTTOM" t)
		(axlVisibleLayer "DRAWING FORMAT/BOTTOM" t)
		(axlVisibleLayer "BOARD GEOMETRY/OUTLINE" t)
		(axlVisibleLayer "BOARD GEOMETRY/LOGO" t)
		
		(sprintf cmd "a2dxf -u MILS -a 1 \"%s\" \"%s\" \"%s\"" cnv_filename dxf_bot_nm work_addr)
		(axlRunBatchDBProgram "bottom_a2dxf" cmd ?startMsg "Export BOTTOM DXF" ?silent t)
	)
)

(procedure archive_opts_Derek11012018()
	(let (curr_file_ls odb_f_nm odb_addr fab_f_nm fab_addr assem_f_nm assem_addr ascii_d_nm ascii_addr ascii_out_ls
			fabm_f_nm fabm_out_ls fabm_addr idf_f_nm emn_f_nm emp_f_nm emn_addr emp_addr dxf_top_nm dxf_bot_nm dxf_top_addr dxf_bot_addr
			achieve_name exe_addr file_nm file_ls)
		;;;;; store all current file from current folder
		(curr_file_ls = (getDirFiles work_path))
		
		;;;;; create folders for the result in broadcom dir
		;;;;; define file name
		(sprintf odb_f_nm out_format "odbjob.tgz")
		(odb_f_nm = (lowerCase odb_f_nm))
		(odb_addr = (strcat "./" broadcom_dir_name "/" odb_f_nm))
		
		(sprintf fab_f_nm out_format "fab-dwg.pdf")
		(fab_addr = (strcat "./" broadcom_dir_name "/" fab_f_nm))
		
		(sprintf assem_f_nm out_format "asm-dwg.pdf")
		(assem_addr = (strcat "./" broadcom_dir_name "/" assem_f_nm))
		
		(sprintf ascii_d_nm out_format "ASCII-files")
		(ascii_addr = (strcat "./" broadcom_dir_name "/" ascii_d_nm))
		(createDir ascii_addr)
		(ascii_out_ls = '("brd.txt" "pad.txt" "sym.txt" "rte.txt" "shp.txt"))
		
		(sprintf fabm_f_nm out_format "FabMaster.txt")
		(fabm_out_ls = '("fabm1.out" "fabm2.out" "fabm3.out" "fabm4.out" "fabm5.out" "fabm6.out" "fabm7.out" "fabm8.out" "fabm9.out"))
		(fabm_addr = (strcat "./" broadcom_dir_name "/" fabm_f_nm))
		
		(sprintf idf_f_nm out_format "IDF") ;; add .emn .emp later
		(emn_f_nm = (strcat idf_f_nm ".emn"))
		(emp_f_nm = (strcat idf_f_nm ".emp"))
		(emn_addr = (strcat "./" broadcom_dir_name "/" emn_f_nm))
		(emp_addr = (strcat "./" broadcom_dir_name "/" emp_f_nm))
		
		(sprintf dxf_top_nm out_format "tasm.dxf")
		(sprintf dxf_bot_nm out_format "basm.dxf")
		(dxf_top_addr = (strcat "./" broadcom_dir_name "/" dxf_top_nm))
		(dxf_bot_addr = (strcat "./" broadcom_dir_name "/" dxf_bot_nm))
		
		;;;;; deal with each option
		(when (and (or opt_table["ict_odb"] opt_table["fab_odb"]) (not (isFile odb_addr)))
			(exe_addr = (strcat getShellEnvVar("ALLEGRO_BRD2ODB") "\\brd2odb.exe"))
			;;
			(if (isExecutable exe_addr) then
				(file_nm = (substring odb_f_nm 1 (sub1 (nindex odb_f_nm "."))))
				(create_odb_Derek11012018 exe_addr file_nm)
				(axlOSFileMove odb_f_nm odb_addr)
			else
				println("No ODB++ found - Please install ODB++ before using this function")
			)
		)
		
		;;; fab drawing
		(when (and (or opt_table["fab_fab"] opt_table["ict_fab"]) (not (isFile fab_addr)))
			(film_ls = (setof f axlGetParam("artwork")->groupMembers (index f "FAB")))
			(if (dtpr film_ls) then
				(create_pdf_Derek11012018 fab_f_nm film_ls)
				(axlOSFileMove fab_f_nm fab_addr)
			else
				println("Fail to find [FAB] film in this board")
			)
		)
		
		(when opt_table["fab_assem"]
			(film_ls = (setof f axlGetParam("artwork")->groupMembers (index f "ASM")))
			(if (dtpr film_ls) then
				(create_pdf_Derek11012018 assem_f_nm film_ls)
				(axlOSFileMove assem_f_nm assem_addr)
			else
				println("Fail to find [ASM*] film in this board")
			)
		)
		
		(when opt_table["ict_axcii"]
			create_ascii_cmd_file_Derek11012018()
			(out_file_ls = ascii_out_ls)
			(create_extracta_Derek11012018 ascii_file_nm out_file_ls)
			(foreach file out_file_ls (axlOSFileMove file (strcat ascii_addr "/" file)))
		)
		
		(when opt_table["ict_fabm"]
			(script_name = (strcat (axlOSSlash (axlGetVariable "cdsroot")) "/share/pcb/text/views/fabmaster.txt"))
			(out_file_ls = fabm_out_ls)
			(if (isFile script_name) then
				(create_extracta_Derek11012018 script_name out_file_ls)
				(shell (sprintf nil "copy fabm*.out %s" fabm_f_nm))
				(axlOSFileMove fabm_f_nm fabm_addr)
			else
				println("Fail to find the script file for fabmaster")
			)
		)
		
		(when opt_table["mec_idf"]
			(create_emn_emp_Derek11012018 idf_f_nm)
			(axlOSFileMove emn_f_nm emn_addr)
			(axlOSFileMove emp_f_nm emp_addr)
		)
		
		(when opt_table["mec_dxf"]
			(create_top_bot_dxf_Derek11012018 dxf_top_nm dxf_bot_nm)
			(axlOSFileMove dxf_top_nm dxf_top_addr)
			(axlOSFileMove dxf_bot_nm dxf_bot_addr)
		)
		
		;;;;; copy the result to each folder
		(when (exists x (list opt_table["fab_odb"] opt_table["fab_fab"] opt_table["fab_assem"]) x)
			(achieve_name = (strcat zip_nm_format "_FAB" zip_ext))
			(achieve_addr = (strcat "./" broadcom_dir_name "/" achieve_name))
			(file_addrs = (mapcan (lambda (x) (when (isWritable x) (list x))) (list odb_addr fab_addr assem_addr)))
			(archieve_zip_Derek11012018 file_addrs achieve_addr)
		)
		
		(when (exists x (list opt_table["ict_odb"] opt_table["ict_fab"] opt_table["ict_axcii"] opt_table["ict_fabm"]) x)
			(achieve_name = (strcat zip_nm_format "_ICT" zip_ext))
			(achieve_addr = (strcat "./" broadcom_dir_name "/" achieve_name))
			(file_addrs = (mapcan (lambda (x) (when (isWritable x) (list x))) (list odb_addr fab_addr ascii_addr fabm_addr)))
			(archieve_zip_Derek11012018 file_addrs achieve_addr)
		)
		
		(when (exists x (list opt_table["mec_idf"] opt_table["mec_dxf"]) x)
			(achieve_name = (strcat zip_nm_format "_MEC" zip_ext))
			(achieve_addr = (strcat "./" broadcom_dir_name "/" achieve_name))
			(file_addrs = (mapcan (lambda (x) (when (isWritable x) (list x))) (list emn_addr emp_addr dxf_top_addr dxf_bot_addr)))
			(archieve_zip_Derek11012018 file_addrs achieve_addr)
		)
		
		(when (exists x (list opt_table["cad_brd"]) x)
			(achieve_name = (strcat zip_nm_format "_CAD" zip_ext))
			(achieve_addr = (strcat "./" broadcom_dir_name "/" achieve_name))
			(file_addrs = (list (strcat "./" work_name ".brd")))
			(archieve_zip_Derek11012018 file_addrs achieve_addr)
		)
		
		;;;;; remove rest of files from tar folder
		(file_ls = (getDirFiles broadcom_dir_name))
		(file_ls = (mapcan (lambda (f) (unless (nindex f zip_ext) (list f))) file_ls))
		(delete_extra_file_Derek11012018 file_ls broadcom_dir_name)
		
		;;;;; remove the extra file from current folder
		(after_file_ls = (getDirFiles work_path))
		(after_file_ls = (mapcan (lambda (f) (unless (member f curr_file_ls) (list f))) after_file_ls))
		(delete_extra_file_Derek11012018 after_file_ls)
	)
)

(procedure delete_extra_file_Derek11012018(file_ls @optional (dir "."))
	(let (addr)
		;;;;; while using the recursive, addr variable will be overwrited by the next stage called function
		(foreach file file_ls
			(unless (member file '("." ".."))
				(addr = (strcat dir "/" file))
				(when (isFile addr) (deleteFile addr))
				(when (isDir addr)
					(delete_extra_file_Derek11012018 (getDirFiles addr) addr)
					(deleteDir addr)
				)
			)
		)
	)
)

(defun broadcom_gerber_tool_main_Derek11012018 ()
	(prog (out_form cmd)
		(unless axlOKToProceed() println("Please done current function and then use this tool") (return nil))
		(unless (sh "\"C:\\Program Files\\7-Zip\\7z\"")
			println("Please install 7z or it isn't installed in the default path. Process halt")
			return(nil)
		)
		
		;;
		init_Derek11012018()
		(when (nindex work_name " ") (axlUIConfirm "No space is allowed in board file name") (return nil))
				(unless ((strlen work_name) <= work_name_max_num)
			printf("Brd name %s has to be less then %d characters. Process abort" work_name work_name_max_num)
			(return nil)
		)
		
		;;;;; create form
		(unless build_form_Derek11012018() println("Fail to create form content file") (return nil))
		(out_form = (axlFormCreate (gensym) broadcom_gb_nm '("east" "outer") 'out_form_action_Derek11012018 nil))
		(set_form_Derek11012018 out_form)
		(axlFormDisplay out_form)
		(deleteFile broadcom_gb_nm)
		
		;;;;; create the rest of the file
		(unless (createDir broadcom_dir_name) println("Fail to create folder") (return nil))
		(unless (dtpr opt_table->?) println("Gerbering abort") (return nil))
		
		archive_opts_Derek11012018()
		
		;;;;; display the folder
		(sprintf cmd "start \"\" \"%s\"" broadcom_dir_name)
		(sh cmd)
		
		(return t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF FUNCTION

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETUP

(axlCmdRegister "broadcom_gerber_tool" 'broadcom_gerber_tool_main_Derek11012018)
; (broadcom_gerber_tool_main_Derek11012018)
; skill encrypt( "C:/skill/broadcom_gerber_tool_v1.il" "C:/skill/broadcom_gerber_tool_v1.ile")
; (load "broadcom_gerber_tool_v1.il")
; (load "broadcom_gerber_tool_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF SETUP