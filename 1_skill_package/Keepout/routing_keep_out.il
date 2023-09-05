;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; information
; File: routing_keep_out_v1.il
; Author: Derek Hsu
; Date: 06/05/2017 - _Derek06052017
; Purpose: it is used to dig holes on the associated ground plane or any other sort of shape by pins or vias
; Usage:
;	open Allegro
;	input skill in command
;	(load "routing_keep_out_v1.il")
;	(Randy Orton)
; Detail:
;	select point
;		single: select one point then operats circular or rectangle function
;		pair: select two points then operate circular, dogbone or rectangle function
;		quad: select one point then operate rectangle function
;		area: drag out a range then dig a hole
;	shape
;		circular: 
;			expansion: 0 is to align the outline;
;			expansion: >0 is to expan out the shape;
;			expansion: <0 is to shrinl out the shape
;		dogbone:
;			width is the gap of the bridge
;			it will waive out the single end and GND mendatory
;		rectangle:
;			vertical is the expansion cross from the pin or via to another. horizontal is the extension of expansion by pin to pin direction
;			it will waive out the single end and GND mendatory in pair mode 
;	layer
;		select: choose layer by from to textbox
;		current: pick up current layer only
;		all: select the whole layer
;	waive: waive the related poly associated to the single selected pin ot via.
;	Done: close the form
;	restriction:
;		Supporting the above description only, the rest of the option will be deactive.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of information
;; (load "routing_keep_out_v1.il")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable
(defun init_Derek06052017 ()
	(setq etch_layer_list axlGetParam("paramLayerGroup:ETCH")->groupMembers)
	(setq rko_form_name "rko_control_panel.form")
	(setq help_filename "rko_help_doc.txt")
	(setq rko_class "ROUTE KEEPOUT")
	(setq rko_form nil)
	(setq brd_dir getWorkingDir())
	(setq pad_tol 200.0); the distance from one pin or via to another pin or via. what is searching by range
	(setq shape_cir_exp 0.0)
	(setq shape_dogb_exp 0.0)
	(setq shape_dogb_wid 10.0)
	(setq shape_rect_ver 0.0)
	(setq shape_rect_hor 0.0)

	(setq layer_current nil)
	(setq layer_from "TOP")
	(setq layer_to "BOTTOM")
	(setq start_pick nil)
	(setq start_range nil)
	(setq from_to_layer list())
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form UI

(defun rko_form_builder_Derek06052017 ()
	(rko_port = outfile(rko_form_name "w"))
	
	fprintf(rko_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
	fprintf(rko_port "FORM TOOLWINDOW \n")	
	fprintf(rko_port "FIXED\n")
	fprintf(rko_port "PORT 35 44\n")
	fprintf(rko_port "HEADER \"Routing Keep Out v1.0\"\n")
	;;;; this form is super special. regard first a as the list of value, second a as the list of id. if the user only input one string, then its list can be both
	fprintf(rko_port "POPUP <all_layer_pop>\"a\"\"a\".\n")
	fprintf(rko_port "TILE\n")
	
	;;;;; this is the group to select how many point has to be included
	fprintf(rko_port "GROUP \"Select Point(s)\"\n")
	fprintf(rko_port "FLOC 1 1\n")
	fprintf(rko_port "TSSIZE 34 4\n")
		
		fprintf(rko_port "FIELD pt_single\n")
		fprintf(rko_port "FLOC 4 3\n")
		fprintf(rko_port "CHECKLIST \" \" \"select_point\" \n")
			fprintf(rko_port "TEXT \"Single\" \n")
			fprintf(rko_port "FLOC 7 3\n")
			fprintf(rko_port "ENDTEXT\n")
		fprintf(rko_port "ENDFIELD\n")

		fprintf(rko_port "FIELD pt_pair\n")
		fprintf(rko_port "FLOC 15 3\n")
		fprintf(rko_port "CHECKLIST \" \" \"select_point\" \n")
			fprintf(rko_port "TEXT \"Pair\" \n")
			fprintf(rko_port "FLOC 18 3\n")
			fprintf(rko_port "ENDTEXT\n")
		fprintf(rko_port "ENDFIELD\n")
		
		fprintf(rko_port "FIELD pt_quad\n")
		fprintf(rko_port "FLOC 26 3\n")
		fprintf(rko_port "CHECKLIST \" \" \"select_point\" \n")
			fprintf(rko_port "TEXT \"Quad\" \n")
			fprintf(rko_port "FLOC 29 3\n")
			fprintf(rko_port "ENDTEXT\n")
		fprintf(rko_port "ENDFIELD\n")
		
	fprintf(rko_port "ENDGROUP\n")

	;;;;; this is the group to select how many point has to be included
	fprintf(rko_port "GROUP \"Shape\"\n")
		fprintf(rko_port "FLOC 1 5\n")
		fprintf(rko_port "TSSIZE 34 9\n")
		
		fprintf(rko_port "FIELD shape_circular\n")
		fprintf(rko_port "FLOC 2 7\n")
		fprintf(rko_port "CHECKLIST \" \" \"select_shape\" \n")
			fprintf(rko_port "TEXT \"Circular\" \n")
			fprintf(rko_port "FLOC 5 7\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "TEXT \"Exp:\" \n")
			fprintf(rko_port "FLOC 14 7\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "FIELD shape_circular_exp\n")
			fprintf(rko_port "FLOC 17 7\n")
			fprintf(rko_port "REALFILLIN 5 5\n")
			fprintf(rko_port "ENDFIELD\n")
		fprintf(rko_port "ENDFIELD\n")
		
		fprintf(rko_port "FIELD shape_DogBone\n")
		fprintf(rko_port "FLOC 2 9\n")
		fprintf(rko_port "CHECKLIST \" \" \"select_shape\" \n")
			fprintf(rko_port "TEXT \"DogBone\" \n")
			fprintf(rko_port "FLOC 5 9\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "TEXT \"Exp:\" \n")
			fprintf(rko_port "FLOC 14 9\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "FIELD shape_dogbone_exp\n")
			fprintf(rko_port "FLOC 17 9\n")
			fprintf(rko_port "REALFILLIN 5 5\n")
			fprintf(rko_port "ENDFIELD\n")
			
			fprintf(rko_port "TEXT \"Wid:\" \n")
			fprintf(rko_port "FLOC 24 9\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "FIELD shape_dogbone_wid\n")
			fprintf(rko_port "FLOC 27 9\n")
			fprintf(rko_port "REALFILLIN 5 5\n")
			fprintf(rko_port "ENDFIELD\n")
		fprintf(rko_port "ENDFIELD\n")
		
		fprintf(rko_port "FIELD shape_Rectangle\n")
		fprintf(rko_port "FLOC 2 11\n")
		fprintf(rko_port "CHECKLIST \" \" \"select_shape\" \n")
			fprintf(rko_port "TEXT \"Rectangle\" \n")
			fprintf(rko_port "FLOC 5 11\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "TEXT \"Ver:\" \n")
			fprintf(rko_port "FLOC 14 11\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "FIELD shape_rectangle_ver\n")
			fprintf(rko_port "FLOC 17 11\n")
			fprintf(rko_port "REALFILLIN 5 5\n")
			fprintf(rko_port "ENDFIELD\n")
			
			fprintf(rko_port "TEXT \"Hor:\" \n")
			fprintf(rko_port "FLOC 24 11\n")
			fprintf(rko_port "ENDTEXT\n")
			
			fprintf(rko_port "FIELD shape_rectangle_hor\n")
			fprintf(rko_port "FLOC 27 11\n")
			fprintf(rko_port "REALFILLIN 5 5\n")
			fprintf(rko_port "ENDFIELD\n")
		fprintf(rko_port "ENDFIELD\n")
	fprintf(rko_port "ENDGROUP\n")
	
	;;;;; this is the group to select layer
	fprintf(rko_port "GROUP \"Layer\"\n")
		fprintf(rko_port "FLOC 1 14\n")
		fprintf(rko_port "TSSIZE 34 7\n")
		
		fprintf(rko_port "FIELD layer_select\n")
		fprintf(rko_port "FLOC 4 16\n")
		fprintf(rko_port "CHECKLIST \" \" \"layer_option\" \n")
			fprintf(rko_port "TEXT \"Sel\" \n")
			fprintf(rko_port "FLOC 7 16\n")
			fprintf(rko_port "ENDTEXT\n")
		fprintf(rko_port "ENDFIELD\n")

		fprintf(rko_port "FIELD layer_current\n")
		fprintf(rko_port "FLOC 15 16\n")
		fprintf(rko_port "CHECKLIST \" \" \"layer_option\" \n")
			fprintf(rko_port "TEXT \"Curr\" \n")
			fprintf(rko_port "FLOC 18 16\n")
			fprintf(rko_port "ENDTEXT\n")
		fprintf(rko_port "ENDFIELD\n")
		
		fprintf(rko_port "FIELD layer_all\n")
		fprintf(rko_port "FLOC 26 16\n")
		fprintf(rko_port "CHECKLIST \" \" \"layer_option\" \n")
			fprintf(rko_port "TEXT \"All\" \n")
			fprintf(rko_port "FLOC 29 16\n")
			fprintf(rko_port "ENDTEXT\n")
		fprintf(rko_port "ENDFIELD\n")
		
		fprintf(rko_port "TEXT \"From:\" \n")
		fprintf(rko_port "FLOC 2 18\n")
		fprintf(rko_port "ENDTEXT\n")
		
		fprintf(rko_port "FIELD layer_from\n")
		fprintf(rko_port "FLOC 6 18\n")
		fprintf(rko_port "ENUMSET 10\n")
		fprintf(rko_port "OPTIONS prettyprint ownerdrawn\n")
		fprintf(rko_port "POP \"all_layer_pop\"\n") ;;;;; this section is used to reference the list
		fprintf(rko_port "ENDFIELD\n")
		
		fprintf(rko_port "TEXT \"To:\" \n")
		fprintf(rko_port "FLOC 19 18\n")
		fprintf(rko_port "ENDTEXT\n")
		
		fprintf(rko_port "FIELD layer_to\n")
		fprintf(rko_port "FLOC 22 18\n")
		fprintf(rko_port "ENUMSET 10\n")
		fprintf(rko_port "OPTIONS prettyprint ownerdrawn\n")
		fprintf(rko_port "POP \"all_layer_pop\"\n")
		fprintf(rko_port "ENDFIELD\n")
	fprintf(rko_port "ENDGROUP\n")
	
	fprintf(rko_port "FIELD invisible\n")
	fprintf(rko_port "FLOC 1 1\n")
	fprintf(rko_port "MENUBUTTON \"fake\" 8 1\n")
	fprintf(rko_port "ENDFIELD\n\n")
	
	fprintf(rko_port "FIELD done\n")
	fprintf(rko_port "FLOC 14 22\n")
	fprintf(rko_port "MENUBUTTON \"Done\" 8 1\n")
	fprintf(rko_port "ENDFIELD\n\n")

	fprintf(rko_port "FIELD rko_help\n")
	fprintf(rko_port "FLOC 26 22\n")
	fprintf(rko_port "MENUBUTTON \"Help\" 8 1\n")
	fprintf(rko_port "ENDFIELD\n\n")
	
	fprintf(rko_port "ENDTILE\n")
	fprintf(rko_port "ENDFORM\n")
	close(rko_port)
)

(defun rko_form_help_Derek06052017 ()

	;;;;; the content of the help section
	(setq help_port (outfile help_filename "w"))
	fprintf(help_port "This is introduction.\n")
	close(help_port)
	
	;;;;; the section below is used to check the help file has been generated or not
	(if isFile(help_filename) then
		axlUIViewFileCreate( help_filename "Routing Keep Out - Help" nil)
        (when (isFile help_filename) (deleteFile help_filename))
	else
        axlUIConfirm( (strcat "Unable to Open Help File, Check Permissions on " brd_dir))
	)
)

(defun set_form_Derek06052017 (rko_form)
	(from_to_layer = set_layer_Derek06052017(layer_from layer_to))
	(axlFormBuildPopup rko_form "layer_from" etch_layer_list)
	(axlFormSetField rko_form "shape_circular_exp" shape_cir_exp)
	(axlFormSetField rko_form "shape_dogbone_exp" shape_dogb_exp)
	(axlFormSetField rko_form "shape_dogbone_wid" shape_dogb_wid)
	(axlFormSetField rko_form "shape_rectangle_ver" shape_rect_ver)
	(axlFormSetField rko_form "shape_rectangle_hor" shape_rect_hor)
	(axlFormSetField rko_form "layer_select" t)
	(axlFormSetField rko_form "layer_from" layer_from)
	(axlFormSetField rko_form "layer_to" layer_to)
	
	;;;;; set default button to prevent the the user leaving the form directly while click the enter
	(axlFormSetFieldVisible rko_form "invisible" 0)
	(axlFormDefaultButton rko_form "invisible")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form UI



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form action

(defun rko_form_action_Derek06052017 (rko_form)
	(setq choice rko_form->curField)
	(case rko_form->curField
		("done"
			println("DONE")
			axlCancelEnterFun()
			axlFormClose(rko_form)
			;axlTempFileRemove("via_prop_add.form")
			t)
		("rko_help"
			(rko_form_help_Derek06052017)
		)
		("pt_single" action_single_mode_Derek06052017())
		("pt_pair" action_pair_mode_Derek06052017())
		("pt_quad" action_quad_mode_Derek06052017())
		;("pt_area" action_area_mode())
		("layer_select"
			(layer_current = nil)
			(set_from_to_editable_Derek06052017 '(t t))
			(axlFormSetField rko_form "layer_from"  layer_from)
			(axlFormSetField rko_form "layer_to"  layer_to)
		)
		("layer_current"
			(layer_current = t)
			(set_from_to_editable_Derek06052017 '(nil nil))
			(axlFormSetField rko_form "layer_from"  "AUTO")
			(axlFormSetField rko_form "layer_to"  "AUTO")
		)
		("layer_all"
			(layer_current = nil)
			(set_from_to_editable_Derek06052017 '(nil nil))
			(layer_from = "TOP")
			(layer_to = "BOTTOM")
			(from_to_layer = set_layer_Derek06052017(layer_from layer_to))
			println(from_to_layer)
			(axlFormSetField rko_form "layer_from"  layer_from)
			(axlFormSetField rko_form "layer_to"  layer_to)
		)
		;("shape_circular")
		;("shape_DogBone")
		;("shape_Rectangle")
		;("shape_circular_exp")
		;("shape_dogbone_exp")
		;("shape_dogbone_wid")
		;("shape_rectangle_ver")
		;("shape_rectangle_hor")
		("layer_from"
			(layer_from = rko_form->curValue)
			(from_to_layer = set_layer_Derek06052017(layer_from layer_to))
			printf("Selected layer: %L.\n" from_to_layer)
		)
		("layer_to"
			(layer_to = rko_form->curValue)
			(from_to_layer = set_layer_Derek06052017(layer_from layer_to))
			printf("Selected layer: %L.\n" from_to_layer)
		)
	)
)

(procedure set_layer_Derek06052017(from to)
	;;;;; to create a list from from_layer to to_layer
	(if (member to (member from etch_layer_list))
		(member to (reverse (member from etch_layer_list)))
		(member to (reverse (member from (reverse etch_layer_list)))))
)
		
(defun action_single_mode_Derek06052017 ()
	(set_shape_editable_Derek06052017 '(t nil nil))
	(axlFormSetField rko_form "shape_circular" t)
)

(defun action_pair_mode_Derek06052017 ()
	(set_shape_editable_Derek06052017 '(t t t))
	(axlFormSetField rko_form "shape_circular" t)
)

(defun action_quad_mode_Derek06052017 ()
	(set_shape_editable_Derek06052017 '(nil nil t))
	(axlFormSetField rko_form "shape_Rectangle" t)
)

;(defun set_current_layer_Derek06052017 ()
;	(layer_from = (cadr parseString(axlGetParam("paramDisplay")->activeLayer "/")))
;	(layer_to = layer_from)
;	(axlFormSetField rko_form "layer_from"  layer_from)
;	(axlFormSetField rko_form "layer_to"  layer_to)
;)

;(defun set_point_editable_Derek06052017 (ratio_ls)
;	axlFormSetFieldEditable(rko_form "pt_single" (car ratio_ls))
;	axlFormSetFieldEditable(rko_form "pt_pair" (cadr ratio_ls))
;	axlFormSetFieldEditable(rko_form "pt_quad" (caddr ratio_ls))
;	;axlFormSetFieldEditable(rko_form "pt_area" (cadddr ratio_ls))
;)

(defun set_shape_editable_Derek06052017 (ratio_ls)
	axlFormSetFieldEditable(rko_form "shape_circular" (car ratio_ls))
	axlFormSetFieldEditable(rko_form "shape_DogBone" (cadr ratio_ls))
	axlFormSetFieldEditable(rko_form "shape_Rectangle" (caddr ratio_ls))
)

;(defun set_layer_editable_Derek06052017 (ratio_ls)
;	axlFormSetFieldEditable(rko_form "layer_select" (car ratio_ls))
;	axlFormSetFieldEditable(rko_form "layer_current" (cadr ratio_ls))
;	axlFormSetFieldEditable(rko_form "layer_all" (caddr ratio_ls))
;)

(defun set_from_to_editable_Derek06052017 (ratio_ls)
	axlFormSetFieldEditable(rko_form "layer_from" (car ratio_ls))
	axlFormSetFieldEditable(rko_form "layer_to" (cadr ratio_ls))
)

(procedure get_sel_point_Derek06052017()
	(if (axlIsFormType rko_form) then
		(cond 
			((axlFormGetField rko_form "pt_single") 'pt_single)
			((axlFormGetField rko_form "pt_pair") 'pt_pair)
			((axlFormGetField rko_form "pt_quad") 'pt_quad)
		(t println("get_sel_point() - Not selected yet.") nil)
		)
	else
		nil
	)
)

(procedure get_sel_shape_Derek06052017()
	(if (axlIsFormType rko_form) then
		(cond 
			((axlFormGetField rko_form "shape_circular") 'shape_circular)
			((axlFormGetField rko_form "shape_DogBone") 'shape_DogBone)
		((axlFormGetField rko_form "shape_Rectangle") 'shape_Rectangle)
			(t println("get_sel_shape() - Not selected yet.") nil)
		)
	else
		nil
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form action



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; main function

(defun picking_Derek06052017 ()
	(prev_select = list())
	
	axlClearSelSet()
	(while axlSelect()
		;;;;; highlight and dehighlight the selected pin or via
		;(axlDehighlightObject prev_select)
		;(axlHighlightObject (prev_select = axlGetSelSet()))
		(set_ls = axlGetSelSet())
		
		;;;;; check the element is pin or via
		(set_ls = (mapcan 'lambda( (x) (when (((equal x->objType "via") || (equal x->objType "pin")) && (neq x->net->name "GND")) (list x))) set_ls))
		
		;;;;; choose mode
		(sel_point = get_sel_point_Derek06052017())
		(sel_shape = get_sel_shape_Derek06052017())
		
		(cond 
			(((null sel_point) || (null sel_shape)) println("Please select a poitn and a shape mode."))
			((null set_ls) println("All the user selected pad is GND pin or via. Plese select the object again."))
			(t
				(printf "Point: %s, Shape: %s - has been chosen.\n" sel_point sel_shape); ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
				(cond
					((and (eq sel_point 'pt_single) (eq sel_shape 'shape_circular)) draw_single_circular_block_Derek06052017(set_ls))
					((eq sel_point 'pt_pair) draw_pair_block_Derek06052017(set_ls))
					;((and (eq sel_point 'pt_pair) (eq sel_shape 'shape_circular)) draw_pair_block(set_ls))
					;((and (eq sel_point 'pt_pair) (eq sel_shape 'shape_DogBone)) draw_pair_block(set_ls))
					;((and (eq sel_point 'pt_pair) (eq sel_shape 'shape_Rectangle)) draw_pair_block(set_ls))
					((and (eq sel_point 'pt_quad) (eq sel_shape 'shape_Rectangle)) draw_quard_block_Derek06052017(set_ls))
					((and sel_point sel_shape) printf("The %s is not valid when you select %s.\n") sel_shape sel_point)
					((and (null sel_point) sel_shape) println("Please select single, pair or quad mode."))
					((and sel_point (null sel_shape)) println("Please select circular, dogbone or rectangle shape."))
				)
			)
		)
		
		axlClearSelSet()
	)
)

(defun draw_quard_block_Derek06052017 (set_ls)
	(item_ls = set_ls)
	(this_ls = list())
	(one_pad = nil)
	(another_pad = nil)
	(another_ls = list())
	(center_xy = list())
	(angle = nil)
	(radius = list())
	(hor_half_len = nil)
	(ver_half_len = nil)
	
	(while (dtpr item_ls)
		(one_pad = nil)
		(another_pad = nil)
		(this_ls = (list (car item_ls)))
		
		(if ((equal (car this_ls)->objType "pin") && (eqv (length (car this_ls)->component->pins) 2))
			(this_ls = (car this_ls)->component->pins)
			println("This %s is not a pin or this component has more than 2 pins.")
		)
		
		(when ((dtpr this_ls) && (eqv (length this_ls) 2)) ;  axlHighlightObject()
			(one_pad = get_diff_pad_Derek06052017((car this_ls)))
			(another_pad = get_diff_pad_Derek06052017((cadr this_ls)))
		)
		
		(if (one_pad && another_pad) then
			(if (axlGeoEqual (axlDistance (car this_ls)->xy another_pad->xy) (axlDistance (cadr this_ls)->xy one_pad->xy)) then
				(center_xy = (axlMidPointLine (list (car this_ls)->xy another_pad->xy)))
				(angle = get_angle_Derek06052017(this_ls~>xy))
				(radius = get_radius_padstack_Derek06052017((car this_ls)))
				(hor_half_len = ((((axlDistance (car this_ls)->xy (cadr this_ls)->xy) + (car radius)) / 2) + (axlFormGetField rko_form "shape_rectangle_ver")))
				(ver_half_len = ((((axlDistance (car this_ls)->xy one_pad->xy) + (cadr radius)) / 2) + (axlFormGetField rko_form "shape_rectangle_hor")))
				(if (center_xy && angle && radius && hor_half_len && ver_half_len) then
					(bridge_path = get_drill_rectangle_path_Derek06052017(center_xy hor_half_len ver_half_len angle))
					(if layer_current then
						(shape = create_shape_Derek06052017((list bridge_path) strcat(rko_class "/" (cadr parseString(axlGetActiveLayer() "/")))))
					else
						(foreach layer from_to_layer (shape = create_shape_Derek06052017((list bridge_path) (strcat rko_class "/" layer))))
					)
				else
					println("One of following data is missing: center_xy, angle, radius, hor_half_len or ver_half_len.")
				)
			else
				println("Two component are not in parallel.")
			)
		else
			println("No correspond component has been found.")
		)
		
		(axlFlushDisplay)
		
		(item_ls = (mapcan 'lambda( (x) (unless (memq x this_ls) (list x))) item_ls))
	)
)

(defun draw_single_circular_block_Derek06052017 (set_ls)
	(foreach item set_ls
		(pad = axlDBGetPad(item axlGetActiveLayer() "REGULAR"))
		
		(radius = ((car get_radius_padstack_Derek06052017(item)) / 2 + (axlFormGetField rko_form "shape_circular_exp")))
		(center_xy = item->xy)
		(shape_name = item->name)
		(figure = (pad->figureName || item->objType))
		printf("rad: %f, xy: %L, name: %s, Figure: %s.\n" radius center_xy shape_name figure)
		 
		;;;;; cond for oval and circle
		(if (member figure (list "CIRCLE" "via")) then
			(path = get_drill_circle_path_Derek06052017(center_xy radius))
			;println(path)
			(if layer_current then
				create_shape_Derek06052017((list path) strcat(rko_class "/" (cadr parseString(axlGetActiveLayer() "/"))))
			else
				(foreach layer from_to_layer
					create_shape_Derek06052017((list path) strcat(rko_class "/" layer))
				)
			)
			(when shape printf("The shape to %s has been generated.\n" shape_name))
		else
			printf("%s is not circular and it will not be processed.\n" shape_name)
		)
		
		(axlFlushDisplay)
	)
)

(defun draw_pair_block_Derek06052017 (set_ls)
	(item_ls = set_ls)
	(one_path = nil)
	(another_path = nil)
	(another_pad = nil)
	(bridge_path = nil)
	(center_xy = list())
	(hor_half_len = nil)
	(ver_half_len = nil)
	(angle = nil)
	(ver = nil)
	(hor = nil)
	(shape_ls = list())
	(while (dtpr item_ls)
		;;;;; if the user only select two pins or vias, then privilege to build thsi two together
		(if (eqv (length set_ls) 2) (this_ls = set_ls) (this_ls = (list (car item_ls))))
		;printf("This list %L.\n" this_ls)
		
		;;;;; find diffpin or via if user select more than two pins once
		(unless (eqv (length set_ls) 2)
			(another_pad = get_diff_pad_Derek06052017((car this_ls)))
			(when another_pad (this_ls = (append1 this_ls another_pad)))
		)
		
		(when ((dtpr this_ls) && (eqv (length this_ls) 2))
			;;;;; build up path - on pin or via
			(cond
				((axlFormGetField rko_form "shape_circular")
					(radius = (car get_radius_padstack_Derek06052017((car this_ls))))
					(if (numberp radius) (radius = (radius / 2 + (axlFormGetField rko_form "shape_circular_exp"))) (radius = nil))
					(ver_half_len = radius)
					(hor_half_len = ((axlDistance (car this_ls)->xy (cadr this_ls)->xy) / 2))
				)
				((axlFormGetField rko_form "shape_DogBone")
					(radius = (car get_radius_padstack_Derek06052017((car this_ls))))
					(if (numberp radius) (radius = (radius / 2 + (axlFormGetField rko_form "shape_dogbone_exp"))) (radius = nil))
					(ver = (axlFormGetField rko_form "shape_dogbone_wid"))
					(if ((null ver) || (ver <= 0)) (ver_half_len = nil) (ver_half_len = (ver / 2)))
					(hor_half_len = ((axlDistance (car this_ls)->xy (cadr this_ls)->xy) / 2))
				)
				((axlFormGetField rko_form "shape_Rectangle")
					(radius = get_radius_padstack_Derek06052017((car this_ls)))
					(ver = (axlFormGetField rko_form "shape_rectangle_ver"))
					(hor = (axlFormGetField rko_form "shape_rectangle_hor"))
					(if ((numberp ver) && (numberp hor)) then
						(ver_half_len = ((cadr radius) / 2 + ver))
						(hor_half_len = ((((axlDistance (car this_ls)->xy (cadr this_ls)->xy) + (car radius)) / 2) + hor))
					else
						(ver_half_len = nil)
						(hor_half_len = nil)
					)
					(radius = nil)
				)
				(t println("draw_pair_block() - There is no such shape selection for pair mode."))
			)
			
			(center_xy = (axlMidPointLine this_ls~>xy))
			
			(unless (angle = get_angle_Derek06052017(this_ls~>xy)) println("draw_pair_circular_block() - retrieve angle is fail."))
			
			;;;;; get two circle pad if it is under the circule or dogbone shape mode
			(if (numberp radius) then
				(one_path = get_drill_circle_path_Derek06052017((car this_ls)->xy radius))
				(another_path = get_drill_circle_path_Derek06052017((cadr this_ls)->xy radius))
			else
				(one_path = nil)
				(another_path = nil)
			)
			
			;;;;; create rectangle path
			(if ((null center_xy) || (null hor_half_len) || (null ver_half_len) || (null angle)) then
				println("draw_pair_circular_block() - center_xy, hor_half_len, ver_half_len or angle is nil. Please check this out.")
			else
				(bridge_path = get_drill_rectangle_path_Derek06052017(center_xy hor_half_len ver_half_len angle)); get_drill_rectangle_path(center_xy hor_half_len ver_half_len angle))
				printf("center: %L, hor: %f, ver: %f, ang: %f\n" center_xy hor_half_len ver_half_len angle)
			)
			
			;;;;; turn path to shape
			(if (one_path && another_path) (shape_ls = (list one_path another_path bridge_path)) (shape_ls = (list bridge_path)))
			(if layer_current then
				(shape = create_shape_Derek06052017(shape_ls strcat(rko_class "/" (cadr parseString(axlGetActiveLayer() "/")))))
			else
				(foreach layer from_to_layer (shape = create_shape_Derek06052017(shape_ls (strcat rko_class "/" layer))))
			)
		)
		
		(axlFlushDisplay)
		
		;;;;; next loop
		(if (eqv (length set_ls) 2) (item_ls = (list)) (item_ls = (mapcan 'lambda( (x) (unless (memq x this_ls) (list x))) item_ls)))
	)
)

(procedure create_shape_Derek06052017(path_ls shape_class)
	(shape = nil)
	(when (dtpr path_ls)
		(foreach path path_ls
			(shape = axlDBCreateShape(path t shape_class nil nil)) ; shape_class = "ROUTE KEEPOUT/BOTTOM"
			(when (car shape) axlDBAddProp((car shape) (list '("VIAS_ALLOWED" t) '("ROUTES_ALLOWED" t))))
		)
	)
	
	shape
)

(procedure get_radius_padstack_Derek06052017(item) ; item represent pin or via
	; item = (car axlGetSelSet()) ; pad = (nth 1 padstack->pads)
	(padstack = axlDBFindByName('padstack item->name))
	(pad = (car padstack->pads)) ; the first place is usually the "etch/top" layer and it ususally has the actual value of the bBox
	(left_down = (car pad->bBox))
	(right_up = (cadr pad->bBox))
	(delta_x = (abs ((car left_down) - (car right_up))))
	(delta_y = (abs ((cadr left_down) - (cadr right_up))))
	(list delta_x delta_y)
	;(padstack = axlDBFindByName('padstack item->name))
	;(radius = (padstack->drillDiameter / 2))
	
	;radius
)

(procedure get_diff_net_id_Derek06052017(this_net)
	(let ((another_net_name nil) (this_net_name nil) (another_net nil) (diffpair this_net->diffpair->groupMembers)) ; diffpair = this_net->diffpair->groupMembers
		(if (dtpr diffpair) then
			(this_net_name = this_net->name)
			(cond
				((rexMatchp "DP" this_net_name) (another_net_name = (rexReplace this_net_name "DN" 1)))
				((rexMatchp "DN" this_net_name) (another_net_name = (rexReplace this_net_name "DP" 1)))
				(t printf("The net name %s does not be supported to retrieve the diff net name. Please add either DP or DN to the diff net name.\n" this_net_name))
			)
			(when another_net_name (another_net = (axlDBFindByName 'net another_net_name)))
		else
			printf("get_diff_net_id() - No Diffpair for net: %s.\n" this_net->name)
		)
	another_net)
)

(procedure same_start_end_Derek06052017(one another)
	(when ((dtpr one) && (dtpr another))
		(((equal (car one) (car another)) && (equal (cadr one) (cadr another))) || ((equal (car one) (cadr another)) && (equal (cadr one) (car another))))
	)
)

(procedure get_diff_pad_Derek06052017(this_pad)
	(another_pad = nil)
	(another_net = nil)
	(candidate_ls = (list))
	
	;;;;; get all candidate from the specific area
	(when (axlSingleSelectBox (list (axlMXYAdd this_pad->xy pad_tol:pad_tol) (axlMXYSub this_pad->xy pad_tol:pad_tol)))
		(candidate_ls = (axlGetSelSet)))
		
	(candidate_ls = (mapcan 'lambda( (x) (when ((equal this_pad->objType x->objType) && same_start_end_Derek06052017(this_pad->startEnd x->startEnd)) (list x))) candidate_ls))
	
	;;;;; get diff net, if the selected pin or via is not in the differential group, then this function might not work
	(another_net = get_diff_net_id_Derek06052017(this_pad->net))
	
	;;;;; find out the target pin or via from the selected object
	(if (dtpr candidate_ls) then
		(foreach pad candidate_ls (when (equal pad->net->name another_net->name) (another_pad = pad)))
		(unless another_pad printf("There is no differential pad for the pad %s.\n" this_pad->name))
	else
		println("There is no pin or via has been selected.")
	)
	
	another_pad
)

(procedure get_drill_circle_path_Derek06052017(center_xy radius)
	;;;;; setting variable
	; (radius = (radius + (axlFormGetField rko_form "shape_circular_exp")))
	(top_xy = (car center_xy):((cadr center_xy) + radius))
	(bottom_xy = (car center_xy):((cadr center_xy) - radius))
	
	;;;;; create path
	(path = axlPathStart((list top_xy)))
	axlPathArcCenter(path 0.0 bottom_xy t center_xy)
	axlPathArcCenter(path 0.0 top_xy t center_xy)
	
	path
)

(procedure get_angle_Derek06052017(two_pt)
	(let ((one (car two_pt)) (another (cadr two_pt)) (angle nil) (slope nil))
		(when ((dtpr one) && (dtpr another) && (not (axlGeoPointsEqual one another)))
			(if (slope = (axlLineSlope two_pt)) (angle = (axlRadToDeg (atan slope))) (angle = 90.0))
		)
	angle)
) ; get_angle( (list 10:10 20:20)) ; get_angle( (list 10:10 10:20)) get_angle( (list 10:10 20:10))

(procedure get_drill_rectangle_path_Derek06052017(center_xy hor_half_len ver_half_len angle)
	;;;;; get original four corner
	(left_top_pt = (axlMXYAdd center_xy -hor_half_len:ver_half_len))
	(left_bot_pt = (axlMXYAdd center_xy -hor_half_len:-ver_half_len))
	(right_top_pt = (axlMXYAdd center_xy hor_half_len:ver_half_len))
	(right_bot_pt = (axlMXYAdd center_xy hor_half_len:-ver_half_len))
	
	;;;;; get rotated four corner
	(left_top_pt = axlGeoRotatePt(angle left_top_pt center_xy))
	(left_bot_pt = axlGeoRotatePt(angle left_bot_pt center_xy))
	(right_top_pt = axlGeoRotatePt(angle right_top_pt center_xy))
	(right_bot_pt = axlGeoRotatePt(angle right_bot_pt center_xy))
	
	;;;;; create path
	(path = axlPathStart((list left_top_pt left_bot_pt right_bot_pt right_top_pt left_top_pt)))
	
	path
)

(defun rko_main_function_Derek06052017 ()
	(prog ()
		;;;;; init
		init_Derek06052017()
		
		;;;;; set find filter
		(axlSetFindFilter ?enabled (list "noall" "pins" "vias") ?onButtons (list "noall" "pins" "vias"))
		
		;;;;; create the rko form
		(rko_form_builder_Derek06052017)
		
		; to prevent diplay rko form multiple times
		(when rko_form axlUIWExpose(rko_form) return(nil))
		
		;;;;; build up the form
		(rko_form = (axlFormCreate (gensym) rko_form_name '("east" "outer") 'rko_form_action_Derek06052017 t))
		set_form_Derek06052017(rko_form)
		
		;;;;; running selecting function
		;; this function, what has recursive inside can not be set in the form or it will make the user input lake of capbility to input the string
		;;;;; display
		(when axlFormDisplay(rko_form) picking_Derek06052017())
		
		;(axlFormClose rko_form)
		;axlCancelEnterFun()
	return(t))
)

(axlCmdRegister "routing_keep_out" 'rko_main_function_Derek06052017)
;(rko_main_function_Derek06052017)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of main function
; encrypt("c:/skill/routing_keep_out_v1.il" "c:/skill/routing_keep_out_v1.ile")
;  axlCancelEnterFun()
;; (load "routing_keep_out_v1.il")