;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Provider: Derek Hsu
;Starting Date: 08/19/2017 - _Derek08192017
;Description: import the artworks into etch class with user-defined postfix
;Usage: 
;	1. This program will autoly draw the color into pattern
;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

(defun init_compare_dxf_import_Derek08192017 ()
	(setq brd_path (strcat getWorkingDir() "/"))
	(setq compare_dxf_import_file_address (strcat brd_path "compare_dxf_import_Derek.scr"))
	(setq dxf_dict_path nil)
	(setq subclass_postfix nil)
	(setq etch_subclass_ls list())
	;(setq etch_layer_ls axlGetParam("paramLayerGroup:ETCH")->groupMembers)
	(setq bg_layer_ls axlGetParam("paramLayerGroup:BOARD GEOMETRY")->groupMembers)
	(setq dxf_files list())
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

(procedure get_dxf_files_inDict_Derek08192017(dxf_dict_path)
	(rexMatchList ".dxf$" (getDirFiles dxf_dict_path))
)

(procedure get_etch_subclass_ls_Derek08192017(dxf_files subclass_postfix)
	(subclass_ls = list())
	
	(when (dtpr dxf_files)
		(subclass_ls = dxf_files)
		(subclass_ls = (mapcar (lambda (x) (car (parseString x "."))) subclass_ls))
		(unless (equal "" subclass_postfix) (subclass_ls = (mapcar (lambda (x) (strcat x "_" subclass_postfix)) subclass_ls)))
	)
	
	subclass_ls
)

(procedure front_layer_topper_Derek08192017(a b)
	(a_val = (cond ((rexMatchp "TOP" a) 1) ((rexMatchp "BOTTOM" a) 1000) ((rexMatchp "L\\([0-9]+\\)_" a) (atoi rexSubstitute("\\1")))))
	(b_val = (cond ((rexMatchp "TOP" b) 1) ((rexMatchp "BOTTOM" b) 1000) ((rexMatchp "L\\([0-9]+\\)_" b) (atoi rexSubstitute("\\1")))))
	(a_val <= b_val)
)

(procedure get_layer_type_Derek08192017(layer)
	(layer_type = nil)
	
	(cond
		((nindex layer "GND") (layer_type = "Plane"))
		((nindex layer "SIG") (layer_type = "Conductor"))
		((nindex layer "VCC") (layer_type = "Plane"))
		(t (layer_type = "Conductor"))
	)
	
	layer_type
)

(procedure get_material_type_Derek08192017(layer)
	(material_type = nil)
	
	(cond
		((nindex layer "GND") (material_type = "FR-4"))
		((nindex layer "SIG") (material_type = "Copper"))
		((nindex layer "VCC") (material_type = "Copper"))
		(t (material_type = "Copper"))
	)
	
	material_type
)

(procedure delete_layer(layer_name) ; BOARD GEOMETRY/DEREK
	(origin_visible = axlVisibleGet())
	
	(axlVisibleDesign nil)
	(axlVisibleLayer layer_name t)
	axlVisibleUpdate(t)
	
	axlSetFindFilter(?enabled list("all") ?onButtons list("all"))
	axlAddSelectAll()
	(deleted_ls = (mapcan (lambda (x) (when (equal layer_name x->layer) (list x))) axlGetSelSet()))
	axlDeleteObject(deleted_ls)
	
	axlVisibleSet(origin_visible)
	
	(layer = axlLayerGet(layer_name))
	axlDeleteObject(layer)
)

(defun create_etch_layers_Derek08192017 (etch_subclass_ls)
	(pre_layer = nil)
	;(pre_layer_num = (length etch_layer_ls))
	(pre_layer_num = (length bg_layer_ls))
	
	(foreach sub_layer etch_subclass_ls
		(when (member sub_layer bg_layer_ls)
			(delete_layer = (strcat "BOARD GEOMETRY/" sub_layer))
			(if delete_layer(delete_layer)
				printf("The layer %s has been deleted.\n" delete_layer)
				printf("Fail to delete the layer %s. There is something can't be deleted.\n" delete_layer)
			)
		)
		axlLayerCreateNonConductor((strcat "BOARD GEOMETRY/" sub_layer))
	)
	
	axlVisibleUpdate(nil)
	
	;;;;;;; return
	(now_layer_num = (length (bg_layer_ls = axlGetParam("paramLayerGroup:BOARD GEOMETRY")->groupMembers)))
	(now_layer_num - pre_layer_num)
)

(procedure dxf_import_commands_Derek08192017(dxf_address cnv_address import_etch_subclass)
	(commands = (list "setwindow pcb"
						"dxf in"
						"setwindow form.dxfInMain"
						"FORM dxfInMain browsedxf"
						(strcat "fillin '" dxf_address "'")
						"fillin yes"
						"FORM dxfInMain units MILS"
						"FORM dxfInMain texttable NO"
						"FORM dxfInMain incremental YES"
						"FORM dxfInMain fillshapes NO"
						"FORM dxfInMain editcnvprofile"
						"fillin yes"
						"setwindow form.dxfInMapping"
						"FORM dxfInMapping selectall YES"
						"FORM dxfInMapping classenum BOARD GEOMETRY"
						(strcat "FORM dxfInMapping subclassenum " import_etch_subclass)
						"FORM dxfInMapping map"
						"FORM dxfInMapping done"
						"fillin yes"
						"setwindow form.dxfInMain"
						"FORM dxfInMain import"
						"FORM dxfInMain cancel"
						"setwindow pcb"
				)
	)
)

(defun dxf_import_loop_Derek08192017 (dxf_path dxf_filename_ls etch_subclass_ls)
	(command_ls = list())
	
	(if (and (isDir dxf_path) (dtpr dxf_filename_ls) (dtpr etch_subclass_ls)) then
		(dxf_address_ls = (mapcar (lambda (x) (strcat dxf_path "/" x)) dxf_filename_ls))
		(cnv_address_ls = (mapcar (lambda (x) sprintf(nil "%s/%s.cnv" dxf_path (car (parseString x ".")))) dxf_filename_ls))
		(command_ls = (append1 command_ls "version 16.6"))
		(foreach (dxf_address cnv_address etch_subclass) dxf_address_ls cnv_address_ls etch_subclass_ls
			(when (dtpr (cmd = dxf_import_commands_Derek08192017(dxf_address cnv_address etch_subclass)))
				(cmd = (append1 cmd (strcat "echo '------------------------------------------------------------ Layer: " etch_subclass "'")))
				(command_ls = (append command_ls cmd))
			)
		)
	else
		println("dxf_import_loop_Derek08192017() got nil arguments. ")
	)
	
	command_ls
)

(procedure out_file_Derek08192017(file_address content_ls)
	(if (and (dtpr content_ls) (outportp (out_port = (outfile file_address "w")))) then
		(foreach line content_ls fprintf(out_port (strcat line "\n")))
		(close out_port)
	else
		println("Fail to export the scr file.")
	)
	
	(isFile file_address)
)

(procedure sort_layers_forXsection_Derek08192017(layer_ls)
	(res_ls = list())
	(when (dtpr layer_ls)
		(res_ls = (sort layer_ls 'front_layer_topper_Derek08192017))
		(res_ls = (reverse res_ls))
	)
	
	res_ls
)

(procedure fill_color_Derek08192017(etch_subclass_ls)
	(start_color = 30) ;; the color will start from purple
	(embedded_ls = (rexMatchList "L[0-9]+" bg_layer_ls))
	(color = (start_color + ((((length embedded_ls) / (length etch_subclass_ls)) - 1) * 2)))
	(command_ls = (list "version 16.6"
						"setwindow pcb"
						"color192"
						"setwindow cvf.dialog"
						"cvf layer_tree_item 'Board Geometry'"
						))
	(foreach layer etch_subclass_ls
		(command_ls = (append1 command_ls sprintf(nil "cvf layers_color board_geometry/%s %d" (lowerCase layer) color)))
	)
	(command_ls = (append command_ls (list "cvf apply" "cvf okay" "setwindow pcb")))
	
	command_ls
)

(defun compare_dxf_import_main_Derek08192017 ()
	;;;;; initial global variable
	init_compare_dxf_import_Derek08192017()
	
	;;;;; get dictionary path
	(dxf_dict_path = axlDMDirectoryBrowse("." t ?title "Pick up the target DXF folder"))
	(if (and (stringp dxf_dict_path) (isDir dxf_dict_path))
		printf("Pick up folder: %s\n" dxf_dict_path)
		println("No folder was picked. No further step will be implemented.")
	)
	
	;;;;; get postfix
	(subclass_postfix = axlEnterString(?prompts "Please enter the postfix of the etch subclass."))
	(when (stringp subclass_postfix) (subclass_postfix = (upperCase subclass_postfix)))
	
	;;;;; get etch subclass name
	(when (isDir dxf_dict_path) (dxf_files = get_dxf_files_inDict_Derek08192017(dxf_dict_path)))
	
	;;;;; mask up the new layer name by postfix
	(when (and (stringp dxf_dict_path) (dtpr dxf_files))
		(etch_subclass_ls = get_etch_subclass_ls_Derek08192017(dxf_files subclass_postfix))
	)
	
	(if (dtpr etch_subclass_ls) then
		;;;;; sort out the masked layers name
		(etch_subclass_ls = (sort_layers_forXsection_Derek08192017 etch_subclass_ls))
		(dxf_files = (sort_layers_forXsection_Derek08192017 dxf_files))
		printf("Subclasse names were created: %L\n" etch_subclass_ls)
		
		;;;;; create etch classes
		(added_layer_num = create_etch_layers_Derek08192017(etch_subclass_ls))
		printf("%d etch subclasses were added.\n" added_layer_num)
		
		;;;;; close color
		(import_dxf_commands = (list "setwindow form.vf_vis"
										"FORM vf_vis all_all_visible NO"
										"FORM vf_vis all_all_visible_pln NO"
										"setwindow pcb"))
		;;;;; create dxf 
		(import_dxf_commands = (append import_dxf_commands dxf_import_loop_Derek08192017(dxf_dict_path dxf_files etch_subclass_ls)))
		;;;;; change color
		(import_dxf_commands = (append import_dxf_commands fill_color_Derek08192017(etch_subclass_ls)))
		
		(if (out_file_Derek08192017 compare_dxf_import_file_address import_dxf_commands)
			printf("dxf import scr was created to %s\n" compare_dxf_import_file_address)
			println("No dxf import scr was created. No further step will be executed.")
		)
		
		;;;;; import dxf
		(when (isFile compare_dxf_import_file_address)
			axlShell((strcat "replay " compare_dxf_import_file_address))
			(deleteFile compare_dxf_import_file_address)
			axlUIConfirm( "The process has been done")
		)
		
	else
		println("No subclass name was created.")
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

;(compare_dxf_import_main_Derek08192017)
(axlCmdRegister "compare_dxf_import" 'compare_dxf_import_main_Derek08192017)
; encrypt( "c:/skill/compare_dxf_import_v1.il" "C:/skill/compare_dxf_import_v1.ile")
; (load "compare_dxf_import_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup