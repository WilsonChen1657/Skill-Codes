
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTRODUCTION 
; Author: Derek Hsu
; Allegro Version: 
; Program Name: EMN_Footprint_Mapping.il
; Starting Date: 05/26/2017
; Purpose: Base on the shapes in EMN file, search the corredponding or the closest 
; 			by look into the area. If the Offset_Diameter or Offset_center is out 
; 			of the tolerance, then the result would be fail. Otherwise is pass.
; 
; Detail
;	1. this program would imply in all the arc, circle and oval in the EMN. 
;	2. this program would not dedicate to check the first pin, component position 
;		and component rotation. However, you may regard the mounting hole position as the valid component real position.
;
; Usage: 
; 	1. put this file into skill path
; 	2. imply the command what is described in the main function block
; 	3. the report will be outputed into the working dictionary
; 
; Output form: 
; 	Entension: XML
; 	Title: (Layer Footprint Pin_Name Footprint_xy Symbol_xy Offset_Center Offset_Diameter Result)
; 	detail:
; 		Layer: either Top or Bottom.
; 		Footprint: The Footprint what the pin is located in.
; 		Pin_Name: The form is Component_name.Pin_number
; 		Footprint_xy: The coordination of the footprint
; 		Symbol_xy: The coordination of the symbol in EMN(Top_Room)
; 		Offset_Center: The distance between Footprint and symbol
; 		Offset_Diameter: The Differenet between footprint and symbol diameter
; 		Result: If the either Offset_Center or Offset_Diameter or both out of the tolerance, then the result would be fail. Otherwise, it would be pass.
; 		
; Disclaimer: 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF INTRODUCTION



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; VARIABLE SETUP
;(load "EMN_Footprint_Mapping_v1.il")
(setq _center_tolerance 2)
;(setq _diameter_tolerance 2)
(setq _lollipop_tolerance 25)
(setq _etch_layer_list axlGetParam("paramLayerGroup:ETCH")->groupMembers)
(setq final_table list())
(setq file_name "DerekFileForCompareEMNandFootprint.csv")
(setq _thisFileName axlCurrentDesign())
(setq _thisFilePath getWorkingDir())
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF VARIABLE SETUP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN FUNCTION


(procedure open_room(room display) ; Top_Room/Bottom_Room, t/nil
	(let (param)
		(param = axlGetParam(room))
		(param->visible = display)
		(axlSetParam param)
		axlVisibleUpdate(t))
)

(procedure visibility_control(class_only layer_only) ; Pin TOP/BOTTOM
	(let (param param_classv)
		(foreach layer _etch_layer_list
			(param_class = strcat("paramLayerGroup:" class_only "/paramLayer:" layer))
			(param = axlGetParam(param_class))
			(param->visible = (equal layer layer_only))
			(axlSetParam param)
			axlVisibleUpdate(t)
		)
	)
)

(procedure get_filter_dbid_list(feature)
	(axlClearSelSet)
	(axlSetFindFilter ?enabled (list "noall" feature) ?onButtons (list feature)) ; may use invisible
	(axlAddSelectAll)
	axlGetSelSet())
	
(procedure equal_center( pt1 pt2) (and (not (null pt1)) (not (null pt2)) (axlDistance( pt1 pt2) < _center_tolerance)))

(procedure get_arc_degree(radius edge cw) 
	(let (degree)
		(degree = axlRadToDeg(asin(edge / (2 * radius))))
		(if cw degree (360 - degree))))

(defun get_component_holes (seg_ls)
	(let ((hole_ls list()))
		(for seg_th 1 (length(seg_ls) - 2)
			; start from 1 since i wanna retrieve the previous info for each round
			; end with -2 since i always wanna retrieve the next info. total length-1 is the last nth 
			(when (and (nth seg_th seg_ls)->xy ; if this seg is arc
					(null (nth (seg_th - 1) seg_ls)->xy) ; if previous one is not arc
					(null (nth (seg_th + 1) seg_ls)->xy) ; if next oen is not arc
					(or (axlDistance( (car (nth (seg_th - 1) seg_ls)->startEnd) (cadr (nth (seg_th + 1) seg_ls)->startEnd)) < _lollipop_tolerance) ; if the distance from precious start to next end is less than tolerance
						(axlDistance( (cadr (nth (seg_th - 1) seg_ls)->startEnd) (car (nth (seg_th + 1) seg_ls)->startEnd)) < _lollipop_tolerance)) ; if the distance from previous end to next start is less than tolerance
					)
							(hole_ls = append1(hole_ls (nth seg_th seg_ls)))) 
		)
	hole_ls)
)
		
(defun get_shape_center (shape_emn)
	(let ((arc_ls list()) (tmp_arc_ls list()) (is_arc 0) (min_seg nil))
		(foreach shape shape_emn
			(cond
				; what is circle
				((eqv shape->nSegs 2) 
					;printf("is circle\n") (foreach seg shape->segments println(seg->??))
					(arc_ls = (append1 arc_ls (list 'circle (car shape->segments))))) ; what is circle
				
				; what is oral
				((and (eqv shape->nSegs 4) (nth 1 shape->segments)->xy (nth 3 shape->segments)->xy (eqv (nth 1 shape->segments)->radius (nth 3 shape->segments)->radius)) 
					;printf("is oral 1 3\n")
					;(foreach seg shape->segments println(seg->??)) 
					(arc_ls = (append1 arc_ls (list 'oral (nth 1 shape->segments) (nth 3 shape->segments)))))
				
				; what is clip
				((and (eqv shape->nSegs 4) (nth 1 shape->segments)->xy (nth 3 shape->segments)->xy (neq (nth 1 shape->segments)->radius (nth 3 shape->segments)->radius)) 
					;printf("is clip 1 3\n")
					;(foreach seg shape->segments println(seg->??))
					(if ((nth 1 shape->segments)->radius > (nth 3 shape->segments)->radius) (min_seg = (nth 3 shape->segments)) (min_seg = (nth 1 shape->segments)))
					(arc_ls = (append1 arc_ls (list 'clip (nth 1 shape->segments)))))
				
				; what is oral
				((and (eqv shape->nSegs 4) (nth 0 shape->segments)->xy (nth 2 shape->segments)->xy (eqv (nth 0 shape->segments)->radius (nth 2 shape->segments)->radius)  )
					;printf("is oral 0 2\n")
					;(foreach seg shape->segments println(seg->??))
					(arc_ls = (append1 arc_ls (list 'oral (nth 0 shape->segments) (nth 2 shape->segments))))) 
				
				; what is clip
				((and (eqv shape->nSegs 4) (nth 0 shape->segments)->xy (nth 2 shape->segments)->xy (neq (nth 0 shape->segments)->radius (nth 2 shape->segments)->radius)  )
					;printf("is clip 0 2\n") 
					;(foreach seg shape->segments println(seg->??))
					(if ((nth 0 shape->segments)->radius > (nth 2 shape->segments)->radius) (min_seg = (nth 2 shape->segments)) (min_seg = (nth 0 shape->segments)))
					(arc_ls = (append1 arc_ls (list 'clip min_seg))))
				
				; what are the hole associated with component
				(t 
					;printf("is the rest\n") 
					(foreach arc get_component_holes(shape->segments)
						;println(arc->??)
						(arc_ls = (append1 arc_ls (list 'sink arc))))
				) ; the rest of shapes
			)
		)
	arc_ls)
)

(defun get_dia (pin_name) ; C125D91
	(setq dia "")
	(cond
		((dia = (index pin_name "D")) (dia = substring(dia 2 (strlen(dia) - 1))))
		((dia = (index pin_name "SP")) (dia = substring(dia 3 (strlen(dia) - 1))))
		(t (dia = "0"))
	)
	;(when (dia = (index pin_name "D")) (dia = substring(dia 2 (strlen(dia)-1))))
	;(when (dia = (index pin_name "SP")) (dia = substring(dia 3 (strlen(dia)-1))))
	rexCompile( "-" )
	(dia = rexReplace( dia "." 1))
	;printf("get_dia: (%s) (%s) (%f)\n" pin_name dia atof(dia))
	atof(dia)
)
	
(defun mapping ( this_layer)
	(prog ()
		(if (equal this_layer "TOP")
			then
				(room = "BOARD GEOMETRY/TOP_ROOM")
				(room_param = "paramLayerGroup:BOARD GEOMETRY/paramLayer:TOP_ROOM") 
			else
				(room = "BOARD GEOMETRY/BOTTOM_ROOM")
				(room_param = "paramLayerGroup:BOARD GEOMETRY/paramLayer:BOTTOM_ROOM"))
		
		;;;;;
		(open_room room_param t)
		(all_shape = get_filter_dbid_list("shapes"))
		
		;;;;; get the shape within the broad only. it is mainly used to exclude the stack up table shape
		(shape_emn = mapcan( 'lambda( (x) (when (equal x->layer room) (list x))) all_shape))
		
		;;;;; get all eligible hole for seeking pin on the current layer
		(arc_list = get_shape_center(shape_emn))
		
		;;;;; find pin 
		visibility_control("Pin" this_layer)
		axlSetFindFilter(?enabled (list "noall" "pins") ?onButtons (list "noall" "pins"))
		(foreach arc arc_list
			;printf("arc: %L\n" arc)
			(if (eq 'oral (car arc))
				axlSingleSelectBox((list (car (cadr arc)->startEnd) (cadr (caddr arc)->startEnd)))
				axlSingleSelectBox((cadr arc)->bBox))
			(arc_single_list = axlGetSelSet())
			
			;;;;; get the first pins in the box. no matter how many pins i got
			;;; if no object exists, then return nil
			;println("get first pin")
			(unless (null arc_single_list)
				(pin = (car arc_single_list))
				
				;;;;; set offset_distance and offset_diameter
				;println("get xy, odis, odia")
				;println(pin->parent->name)
				;println(strcat(pin->parent->refdes "." pin->number))
				(if (eq 'oral (car arc)) (xy = axlMidPointLine((list (cadr arc)->xy (caddr arc)->xy))) (xy = (cadr arc)->xy))
				(odis = axlDistance(pin->xy xy))
				;(odia = abs((((cadr arc)->radius * 2) - get_dia(pin->name))))
				
				;;;;; (Layer Footprint Pin_Name Footprint_xy Symbol_xy Offset_Center Result)
				;println("insert to table")
				(unless (or (nindex pin->parent->name "BGA") rexMatchp("^C[0-9]+$" pin->parent->name))
					(final_table = append1(final_table 
												(list 
													(symbolToString (car arc))
													this_layer 
													pin->parent->name
													strcat(pin->parent->refdes "." pin->number)
													strcat( sprintf(nil "%.2f" (car pin->xy)) ":" sprintf(nil "%.2f" (cadr pin->xy)))
													strcat( sprintf(nil "%.2f" (car xy)) ":" sprintf(nil "%.2f" (cadr xy)))
													sprintf(nil "%.4f" odis)
													(if (odis <= _center_tolerance) "Pass" "Fail")
													;sprintf(nil "%.4f" odia)
													;(if (and (odis <= _center_tolerance) (odia <= _diameter_tolerance)) "Pass" "Fail")
													))))
			)
		)
		
		
		printf("The arc in layer %s has been set.\n" this_layer)
		(axlClearSelSet)
		(open_room room_param nil)
	return(t))
)

(defun create_csv (file_name tar_ls)
	(prog ()
		(out_port = (outfile strcat( _thisFilePath "/" file_name) "w"))
		(unless out_port return(nil))
		fprintf(out_port strcat(_thisFileName "\n\n"))
		fprintf(out_port "Layer,Footprint,Pin_Name,Footprint_xy,Symbol_xy,Offset_Center,Result\n")
		(when listp(tar_ls)
			(foreach line tar_ls fprintf(out_port strcat(buildString((cdr line) ",") "\n"))))
		close(out_port)
	return(t))
)

(defun sort_csv (tar_ls sort_item_ls)
	(let ((pos (car sort_item_ls)) (to_be_sorted_ls list()))
		(if (null pos)
			then
				;printf(" return previous block: %d\n" length(tar_ls))
				tar_ls
			else
				;printf("pos: %d\n" pos)
				(to_sort_ls = list())
				(foreach tar tar_ls
					;println(tar)
					(id = (nth pos tar))
					(to_sort_ls = append1(to_sort_ls (list id tar)))
				)
				(to_sort_ls = (sortcar to_sort_ls 'alphalessp))
				;(foreach x to_sort_ls println(buildString((cadr x) ",")))
				;(foreach x to_sort_ls println((car x)))
				
				(this_group_name = "")
				(foreach tar to_sort_ls
					(when (equal this_group_name (car tar))
								(tmp_group = append1(tmp_group (cadr tar)))
								;printf("1   %s   %s\n" (car tar) buildString((cadr tar) ","))
								)
					(when (equal this_group_name "")
								(this_group_name = (car tar))
								(tmp_group = (list (cadr tar)))
								;printf("2   %s   %s\n" (car tar) buildString((cadr tar) ","))
								)
					(when (neq this_group_name (car tar))
								(to_be_sorted_ls = append(to_be_sorted_ls sort_csv(tmp_group (cdr sort_item_ls))))
								;printf("Total result: %d\n" length(to_be_sorted_ls))
								(this_group_name = (car tar))
								(tmp_group = (list (cadr tar)))
								;printf("3   %s   %s\n" (car tar) buildString((cadr tar) ","))
								)
				)
				append(to_be_sorted_ls sort_csv(tmp_group (cdr sort_item_ls)))
		)
	)
)

(procedure emn_map_Report(@optional (reportName "EMN_to_placement_Report"))
	let( (fp line section (text ""))
		(fp = axlDMOpenFile("ALLEGRO_HTML" reportName "w"))
		
		fprintf(fp, "\n<html>\n")
		fprintf(fp, strcat("\n<head><title>" reportName "</title></head>\n"))
		fprintf(fp, "<body>\n")
		
		fprintf(fp, "\n<table align=center border=1><caption><b><u>This is a report show out the EMN and footprint position comparison.</u></b></caption>\n")

		(in_port = (infile file_name)) ; file_name is DerekFileForCompareEMNandFootprint.csv
		
		fscanf(in_port "%s" line) ; skip the design name
		;printf("1. %s" line)
		
		(while fscanf(in_port "%s" line)
			(text = "")
			;println(line)
			(foreach one parseString(line ",")
				(if (nindex one ":")
					then
						(section = parseString(one ":"))
						sprintf(section
								 "<td nowrap=true><a href=\"xprobe:xy:%s,%s\">(%s %s)</a></td>\n"
								 (car section) (cadr section) (car section) (cadr section))
						(text = strcat(text section))
					else
						(text = strcat(text "<td nowrap=true>" one "</td>\n"))
				)
			)
			fprintf(fp, strcat("<tr>\n" text "</tr>\n"))
		)
		
		close(in_port)
		
		fprintf(fp, "</table>\n")
		fprintf(fp, "</body>\n")
		fprintf(fp, "</html>\n")
		
		close(fp)
	t)
)

(defun emn_map_main ()
	(prog ()
		(mapping "TOP")
		(mapping "BOTTOM")
		(final_table = sort_csv(final_table '(7 1 2 3))) ; 7 1 2
		axlReportRegister('emn_map_Report, nil nil)
		(if create_csv(file_name final_table)
			then
				axlReportRegister('emn_map_Report "EMN_to_placement_Report" "This is a report show out the EMN and footprint position comparison.")
			else
				axlUIConfirm( "Please close the csv file first. The csv file has not been generated." 'warning )
		)
		
		;(foreach x final_table println(x))
		
		
		return(t))
)

;(emn_map_main)
(axlCmdRegister "emn_map" 'emn_map_main)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF MAIN FUNCTION

; (load "EMN_Footprint_Mapping_v1.il")