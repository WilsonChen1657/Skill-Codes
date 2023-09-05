;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
; Provider: Derek Hsu
; Starting Date: 08/18/2017 - _Derek08182017
; Description: This program will extract all the etch artwork without GND into user-defined folder.
;				This program should compound with compare_dxf_import
; Cautious:
; 	1. This program will only regard the L<digital number>_? as the etch layer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

(defun init_compare_dxf_export_Derek08182017 ()
	(setq artwork_ToptoBot_ls list())
	(setq dxf_export_path nil)
	(sscanf getCurrentTime() "%s %d %d:%d:%d %s" mon date hr min sec year)
	(setq dxf_export_filename (sprintf nil "%s_comparison_%.2d%.2d%.2d_%.2d%s%s" axlCurrentDesign() hr min sec date mon year))
	(setq dxf_scr "compare_dxf_export_Derek.scr")
	(setq brd_path (strcat getWorkingDir() "/"))
	(setq dxf_scr_address (strcat brd_path dxf_scr))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function
(procedure dxf_command_Derek08182017(file_address)
	(commands = (list "dxf out"
						"setwindow form.dxf_out"
						"FORM dxf_out browsedxf"
						(strcat "fillin '" file_address ".dxf'")
						"FORM dxf_out units MILS"
						"FORM dxf_out browselayer"
						(strcat "fillin '" file_address "_l.cnv'")
						"FORM dxf_out edit"
						"setwindow form.dxfOutMapping"
						"FORM dxfOutMapping selectall YES"
						"FORM dxfOutMapping usedefaultlayernames YES"
						"FORM dxfOutMapping map"
						"FORM dxfOutMapping done"
						"setwindow form.dxf_out"
						"FORM dxf_out execute"
						"FORM dxf_out close"
						"setwindow pcb")
	)
) ; skill (axlShell (buildString commands ";"))

(procedure make_dxf_scr_Derek08182017(artwork_ls file_path)
	;;;;; setup the variable
	(original_visible_setting = axlVisibleGet())
	;(class_ls = axlGetParam("paramLayerGroup")->groupMembers)
	
	;;;;; create dxf scr
	(if (outportp (out_port = (outfile dxf_scr_address "w"))) then
		fprintf(out_port "version 16.6\n")
		(foreach film artwork_ls
			(file_name = (if (nindex film "-") (cadr (parseString film "-")) film))
			(file_address = (strcat file_path "/" file_name))
			(command_ls = (list "setwindow form.vf_vis"
								(strcat "FORM vf_vis colorview_list Film: " film)
								"setwindow pcb"
							))
			(command_ls = (append command_ls dxf_command_Derek08182017(file_address)))
			fprintf(out_port (strcat "skill (commands = \"" (buildString command_ls ";") "\")\n"))
			fprintf(out_port "skill (axlShell commands)\n")
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;axlRunBatchDBProgram("a2dxf" "a2dxf -u MILS -a 2 all_l.cnv aaa.dxf %s")
			;axlRunBatchDBProgram("report" "report -v x-section %s xhaha.txt")
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;(foreach cmd command_ls fprintf(out_port (strcat cmd "\n")))
		)
		(close out_port)
		else
			println("The csr file can't be created.")
	)
	
	axlVisibleSet(original_visible_setting)
	
	(isFile dxf_scr_address)
)

(procedure front_layer_topper_Derek08182017(a b)
	(a_val = (cond ((rexMatchp "TOP" a) 1) ((rexMatchp "BOTTOM" a) 1000) ((rexMatchp "L\\([0-9]+\\)_" a) (atoi rexSubstitute("\\1")))))
	(b_val = (cond ((rexMatchp "TOP" b) 1) ((rexMatchp "BOTTOM" b) 1000) ((rexMatchp "L\\([0-9]+\\)_" b) (atoi rexSubstitute("\\1")))))
	(a_val <= b_val)
)

(procedure get_artwork_top_bot_Derek08182017()
	(layer_ls = axlGetParam("artwork")->groupMembers)
	(layer_ls = (rexMatchList "L[0-9]+_[A-Z]+[0-9]*$" layer_ls))
	;(layer_ls = (mapcan (lambda (x) (unless (nindex x "GND") (list x))) layer_ls))
	(layer_ls = (sort layer_ls 'front_layer_topper_Derek08182017))
	;(layer_ls = (mapcar (lambda (x) (if (nindex x "-") (cadr (parseString x "-")) x)) layer_ls))
	
	layer_ls
)

(procedure make_dictionary_Derek08182017(file_name)
	(file_path = (strcat getWorkingDir() "/" file_name))
	createDir(file_path)
	
	file_path
)

(defun compare_dxf_export_main_Derek08182017 ()
	
	;;;;; initial all the matter variables
	init_compare_dxf_export_Derek08182017()
	
	;;;;; get artwork layer name from top to bottom
	(artwork_ToptoBot_ls = get_artwork_top_bot_Derek08182017())
	
	(if (isDir (dxf_export_filepath = make_dictionary_Derek08182017(dxf_export_filename)))
		printf("Create folder to %s\n" dxf_export_filepath)
		printf("%s folder was not created.\n" dxf_export_filename)
	)
	
	;;;;; export dxf files
	(if (stringp dxf_export_filepath) then
		(if make_dxf_scr_Derek08182017(artwork_ToptoBot_ls dxf_export_filepath) then
			println("The scr file was created.")
			;axlShell((strcat "replay " dxf_scr_address))
			;axlRunBatchDBProgram("replay" (strcat "replay " dxf_scr_address))
;			(deleteFile dxf_scr_address)
			axlUIConfirm( (strcat "Please fillin '" dxf_scr "' and press 'Replay' to finish this process."))
			axlShell("script")
		else
			println("The scr file was not created. No further step will be applied.")
		)
	else
		println("No file name was imported. No DXF will be exported.")
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

;(compare_dxf_export_main_Derek08182017)
(axlCmdRegister "compare_dxf_export" 'compare_dxf_export_main_Derek08182017)
; encrypt( "c:/skill/compare_dxf_export_v1.il" "C:/skill/compare_dxf_export_v1.ile")
; (load "compare_dxf_export_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup