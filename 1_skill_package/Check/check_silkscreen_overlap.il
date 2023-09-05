;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Description
;
; Developer: Derek Hsu
; Starting date: 7/24/2018
; Description:
;	1. layer: silkscreen/soldermask for top/bot
;	2. rules: soldermask to silkscreen [box to line compare]
;				silkscreen to silkscreen [ box to box compare]
;	3. result: format and csv file
;	4. title: [silkscreen to silkscreen / silkscreen to soldermask][top / bottom][position link]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of description

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

(procedure init()
	;;;;;
	(setq silk_top_ls get_subclass_by_name("SILKSCREEN_TOP"))
	(setq silk_bot_ls get_subclass_by_name("SILKSCREEN_BOTTOM"))
	(setq solder_top_ls get_subclass_by_name("SOLDERMASK_TOP"))
	(setq solder_bot_ls get_subclass_by_name("SOLDERMASK_BOTTOM"))
	
	;;;;; get whole box
	(sh_ls = (axlDBGetShapes "MANUFACTURING/PHOTOPLOT_OUTLINE"))
	(if (onep (length sh_ls)) (brd_box = (car sh_ls)->bBox) (brd_box = nil))
	
	
	;;;;; demo purpose, please delete it by releasing
	axlVisibleDesign(nil)
	(axlVisibleLayer "USER PART NUMBER/SILKSCREEN_TOP" t)
	(axlVisibleUpdate t)
	axlClearSelSet()
	(axlSetFindFilter ?enabled (list "noall" "LINES") ?onButtons (list "noall" "LINES"))
	axlAddSelectAll()
	axlDeleteObject(axlGetSelSet())
	(axlSetFindFilter ?enabled (list "noall") ?onButtons (list "noall"))
)

(procedure get_subclass_by_name(sub_nm)
	(let (class_ls param sub_ls result result_ls)
		(class_ls = axlClasses())
		;;
		(foreach cl class_ls
			(param = (strcat "paramLayerGroup:" cl))
			(sub_ls = axlGetParam(param)->groupMembers)
			;;
			(foreach sub sub_ls
				(when (equal sub_nm sub)
					(result_ls = (cons (strcat cl "/" sub) result_ls))
				)
			)
		)
		
		result_ls
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Sub function

(procedure get_char_ext(char photo_width)
	;;; this function is used to shrink up the width of text block
	;;; first element is left gap, second element is right gap
	(let (result_ls)
		(case char
			;;
			("0" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("1" (result_ls = (list photo_width photo_width)))
			("2" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("5" (result_ls = (list (photo_width / 6) (photo_width / 6))))
			("6" (result_ls = (list (photo_width / 4) (photo_width / 4))))
			("7" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("8" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("9" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			;;
			("E" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("H" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("J" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("K" (result_ls = (list (photo_width / 7) (photo_width / 7))))
			("L" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("N" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("P" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("R" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("S" (result_ls = (list (photo_width / 5) (photo_width / 5))))
			("Y" (result_ls = (list (photo_width / 5) (photo_width / 5))))
		)
		
		result_ls
	)
)

(procedure get_text_4_pt(xy text justify text_height text_width rot photo_width)
	(let (outline_xy ul_pt ur_pt dl_pt dr_pt result_ls)
		;;;; upper left, upper right, downer left downer right
		
		(outline_xy = (axlMXYAdd xy (list 0 -(photo_width / 2))))
		;;
		(char = (substring text 1 1))
		(gap_left = (car (get_char_ext char photo_width)))
		(unless gap_left (gap_left = 0))
		
		(char = (substring text -1 1))
		(gap_right = (cadr (get_char_ext char photo_width)))
		(unless gap_right (gap_right = 0))
		
		;;
		(case justify
			("CENTER"
				(ul_pt = (axlMXYAdd outline_xy (list (gap_left - (text_width / 2)) text_height)))
				(ur_pt = (axlMXYAdd outline_xy (list ((text_width / 2) - gap_right) text_height)))
				(dr_pt = (axlMXYSub ur_pt (list 0 text_height)))
				(dl_pt = (axlMXYSub ul_pt (list 0 text_height)))
			)
			("LEFT"
				(dl_pt = (axlMXYAdd outline_xy (list gap_left 0)))
				(dr_pt = (axlMXYAdd outline_xy (list (text_width - gap_right) 0)))
				(ul_pt = (axlMXYAdd dl_pt (list 0 text_height)))
				(ur_pt = (axlMXYAdd dr_pt (list 0 text_height)))
			)
			("RIGHT"
				(dr_pt = (axlMXYSub outline_xy (list gap_right 0)))
				(dl_pt = (axlMXYSub outline_xy (list (text_width + gap_left) 0)))
				(ul_pt = (axlMXYAdd dl_pt (list 0 text_height)))
				(ur_pt = (axlMXYAdd dr_pt (list 0 text_height)))
			)
			(t
				printf("The justify [%s] of the text [%s] has not been supported yet\n" justify text)
			)
		)
		
		;;; modification and rotation
		(when (and (dtpr ul_pt) (dtpr ur_pt) (dtpr dl_pt) (dtpr dr_pt))
			(when (not (eqv 0.0 rot))
				(ul_pt = (axlGeoRotatePt rot ul_pt xy))
				(ur_pt = (axlGeoRotatePt rot ur_pt xy))
				(dl_pt = (axlGeoRotatePt rot dl_pt xy))
				(dr_pt = (axlGeoRotatePt rot dr_pt xy))
			)
			;;
			(result_ls = (list ul_pt ur_pt dr_pt dl_pt))
		)
		
		result_ls
	)
)

(procedure get_text_corner(text_id)
	(let (text tb_num rot xy justify param tb_id height photo_width width char_spacing text_height text_len text_width result_ls)
		(when (stringp text_id->text)
			(text = text_id->text)
			(tb_num = text_id->textBlock)
			(rot = text_id->rotation)
			(xy = text_id->xy)
			(justify = text_id->justify) ;; left, center, right
			
			;; get textblock id
			(param = (strcat "paramTextBlock:" tb_num))
			(tb_id = (axlGetParam param))
			
			;; get height element
			(height = tb_id->height)
			(photo_width = tb_id->photoWidth)
			
			;; get width element
			(width = tb_id->width)
			(char_spacing = tb_id->charSpace)
			
			;; get estimated text dimension (height / width)
			(text_height = (height + photo_width))
			(text_len = (strlen text))
			(text_width = (text_len * width + (sub1 text_len) * char_spacing))
			
			;;;
			(result_ls = get_text_4_pt(xy text justify text_height text_width rot photo_width))
		)
		
		result_ls
	)
)

(procedure get_line_box(start_end width se_len)
	(let (leng ori_pt ext_pt start_pt end_pt vector x_vector start_1_pt start_2_pt end_1_pt end_2_pt result_ls)
		(when (and (dtpr start_end) (numberp se_len) (numberp width) (numberp se_len))
			(leng = (se_len + width / 2))
			
			;;;;; extend start
			(ori_pt = (cadr start_end))
			(ext_pt = (car start_end))
			
			;;
			(start_pt = (axlMUniVector ori_pt ext_pt leng))
			(vector = (axlMXYSub start_pt ext_pt))
			(x_vector = (if (zerop (car vector)) (list -(cadr vector) (car vector)) (list (cadr vector) -(car vector))))
			(start_1_pt = (axlMXYAdd start_pt x_vector))
			(start_2_pt = (axlMXYSub start_pt x_vector))
			
			;;;;; extend end
			(ori_pt = (car start_end))
			(ext_pt = (cadr start_end))
			
			;;
			(end_pt = (axlMUniVector ori_pt ext_pt leng))
			(vector = (axlMXYSub end_pt ext_pt))
			(x_vector = (if (zerop (car vector)) (list -(cadr vector) (car vector)) (list (cadr vector) -(car vector))))
			(end_1_pt = (axlMXYAdd end_pt x_vector))
			(end_2_pt = (axlMXYSub end_pt x_vector))
			
			;;;;; build up box
			(result_ls = (list start_1_pt end_2_pt end_1_pt start_2_pt))
		)
		
		result_ls
	)
)

(procedure get_arc_box(start_end width radius box_width extend_length is_cw small_arc)
	(let (head_pt tail_pt start_pt end_pt uni_vector x_uni_vector x_vector x_arc_vector test_pt test_dis start_1_pt start_2_pt end_1_pt end_2_pt result_ls)
		(when (and (dtpr start_end) (numberp width) (numberp radius) (numberp box_width) (numberp extend_length) (booleanp is_cw))
			(head_pt = (car start_end))
			(tail_pt = (cadr start_end))
			(uni_vector = (axlMUniVector tail_pt head_pt))
			(start_pt = (axlMXYAdd head_pt (axlMXYMult uni_vector extend_length)))
			(end_pt = (axlMXYAdd tail_pt (axlMXYMult uni_vector -extend_length)))
			(x_uni_vector = (if (zerop (car uni_vector)) (list -(cadr uni_vector) (car uni_vector)) (list (cadr uni_vector) -(car uni_vector))))
			
			;;;; check outer side
			(test_pt = (axlMXYAdd head_pt x_uni_vector))
			(test_dis = (axlDistance center_xy test_pt))
			(if (or (and small_arc (test_dis > radius)) (and (null small_arc) (test_dis < radius))) then
				(x_vector = (axlMXYMult x_uni_vector -(width / 2)))
				(x_arc_vector = (axlMXYMult x_uni_vector box_width))
			else
				(x_vector = (axlMXYMult x_uni_vector (width / 2)))
				(x_arc_vector = (axlMXYMult x_uni_vector -box_width))
			)
			
			;;
			(start_1_pt = (if is_cw (axlMXYAdd start_pt x_vector) (axlMXYAdd start_pt x_arc_vector)))
			(start_2_pt = (if is_cw (axlMXYAdd start_pt x_arc_vector) (axlMXYAdd start_pt x_vector)))
			;;
			(end_1_pt = (if is_cw (axlMXYAdd end_pt x_arc_vector) (axlMXYAdd end_pt x_vector)))
			(end_2_pt = (if is_cw (axlMXYAdd end_pt x_vector) (axlMXYAdd end_pt x_arc_vector)))
			
			;;;;; build up box
			(result_ls = (list start_1_pt end_2_pt end_1_pt start_2_pt))
		)
		
		result_ls
	)
)

(procedure get_circle_corner(center_xy radius width)
	(let (clip ul_pt ur_pt dl_pt dr_pt result_ls)
		(when (and (dtpr center_xy) (numberp radius) (numberp width))
			(clip = (radius + width / 2))
			;;
			(ul_pt = (axlMXYAdd center_xy (list -clip clip)))
			(ur_pt = (axlMXYAdd center_xy (list clip clip)))
			(dl_pt = (axlMXYAdd center_xy (list -clip -clip)))
			(dr_pt = (axlMXYAdd center_xy (list clip -clip)))
			;;
			(result_ls = (list ul_pt ur_pt dr_pt dl_pt))
		)
		
		result_ls
	)
)

(procedure is_small_arc(start_end center_xy is_cw)
	(let (start_pt end_pt cs_vector ce_vector cross result)
		(start_pt = (car start_end))
		(end_pt = (cadr start_end))
		;;;; a_vector cross b_vector
		(cs_vector = (axlMXYSub start_pt center_xy))
		(ce_vector = (axlMXYSub end_pt center_xy))
		(cross = ((car cs_vector) * (cadr ce_vector) - (car ce_vector) * (cadr cs_vector)))
		
		;;;; when cross >= 0 and ccw, it is small arc
		;;;; when cross < 0 and cw, it is small arc
		(result = (or (and (cross < 0) is_cw) (and (cross >= 0) (null is_cw))))
		
		result
	)
)

(procedure get_seg_corner(seg)
	(let (ul_pt ur_pt dl_pt dr_pt result_ls)
		(start_end = seg->startEnd)
		(se_len = (axlDistance (car start_end) (cadr start_end))) ;; start end length
		(when (zerop (width = seg->width)) (width = 1.0))
		(type = seg->objType)
		
		;;
		(case type
			("arc"
				(radius = seg->radius)
				(is_cw = seg->isClockwise)
				(center_xy = seg->xy)
				(se_len_d2 = (se_len / 2))
				(small_arc = is_small_arc(start_end center_xy is_cw))
				;;
				(if seg->isCircle then
					(result_ls = get_circle_corner(center_xy radius width))
				else
					(if small_arc then
						(box_width = (radius - (sqrt (radius**2 - se_len_d2**2)) + width / 2))
						(extend_length = (width / 2))
						(result_ls = get_arc_box(start_end width radius box_width extend_length is_cw small_arc))
					else
						(box_width = (radius + (sqrt (radius**2 - se_len_d2**2)) + width / 2))
						(extend_length = (radius - se_len_d2 + width / 2))
						(result_ls = get_arc_box(start_end width radius box_width extend_length is_cw small_arc))
					)
				)
			)
			("line"
				(result_ls = get_line_box(start_end width se_len))
			)
			(t
				printf("get_seg_corner - Type [%s] has not been supported yet in box %L\n" type seg->bBox)
			)
		)
		
		result_ls
	)
)

(procedure get_silk_block_pt(silk)
	(let (pt_ls type box result_ls)
		(type = silk->objType)
		(box = silk->bBox)
		
		;;;;; the following selector will be rapped up into another function foe repeatly usage
		(case type
			("path"
				;;; get outest line ;; rectangle or triangle
				(seg_ls = silk->segments)
				(foreach seg seg_ls
					(pt_ls = get_seg_corner(seg))
					(pt_ls = (append1 pt_ls (car pt_ls)))
					(result_ls = (append1 result_ls pt_ls))
				)
			)
			("text"
				(result_ls = get_text_corner(silk))
				(result_ls = (append1 result_ls (car result_ls)))
				(result_ls = (list result_ls))
			)
			(t
				printf("solder_to_silk_check - No function to support type [%s] in box %L\n" type box)
			)
		)
		
		result_ls
	)
)

(procedure is_block_over_block(block_pt_ls obj)
	(let (line_1 line_2 dis dis_ls result)
		(type_seg = obj->objType)
		(pt_ls = get_seg_corner(obj))
		(pt_ls = (append1 pt_ls (car pt_ls)))
		;;;;; this function may be optimized to speed up
		
		(foreach block_pts block_pt_ls
			;;; loop through all the (segments)block in current silkscreen
			(for i 0 3
				(for j 0 3
					;;; totally 4 * 4 line to check the intersection. if it gets the intersection, then break the function instantly
					(line_1 = (list (nth i block_pts) (nth (add1 i) block_pts)))
					(line_2 = (list (nth j pt_ls) (nth (add1 j) pt_ls)))
					
					;; the returned 2nd is 0 means there is a intersection found
					;printf("1: [%L], 2: [%L], res: [%L]\n" line_1 line_2 (axl_ol_ol2 line_1 line_2))
					(data_ls = (axl_ol_ol2 line_1 line_2))
					(when (zerop (caddr data_ls))
						(dis_ls = (cons (car data_ls) dis_ls))
					)
				)
			)
		)
		
		;;
		(when (and (dtpr dis_ls) (eqv 2 (length dis_ls)))
			;;; get 3rd line or the average line of all distange
			(dis = (axlDistance (car dis_ls) (cadr dis_ls)))
			
			;;; 4 is a magic number to ignore the corner to corner overlap
			(result = (dis >= 4))
		)
		
		result
	)
)

(procedure is_block_over_arc(seg pt_ls)
	(let (xy radius result)
		(xy = seg->xy)
		(radius = seg->radius)
		
		;;; there are 5 point in pt_ls; first and last is the same one, therefore, skip the first one by cdr
		(dis_ls = (mapcar (lambda (x) (axlDistance xy x)) (cdr pt_ls)))
		(result = (exists x dis_ls (x <= radius)))
		
		printf("R:[%f], Center:[%L], Pts:[%L], Distances:[%L]\n" radius xy (cdr pt_ls) dis_ls)
		
		result
	)
)

(procedure is_over_else(silk obj_ls)
	(prog (se_ls type_silk silk_se_ls seg seg_ls block_pt_ls result_ls result) ;;; turn to prog later, leave the function as soon as possible
		;;;; remove itself
		(obj_ls = (mapcan (lambda (x) (unless (eq silk x) (list x))) obj_ls))
		
		(type_silk = silk->objType)
		
		;;;; to check whether the line fron silkscreen and selected object is connected
		(when (equal "path" type_silk)
			(foreach se silk->segments~>startEnd (silk_se_ls = (append silk_se_ls se)))
		)
	
		(block_pt_ls = get_silk_block_pt(silk))
	;	printf("--- silk[%s] qty:[%d] objs in box [%L]\n" silk->objType (length obj_ls) silk->bBox)
		
		(foreach obj obj_ls
			(type_obj = obj->objType)
			;;
			(case type_obj
				("text"
					(result = is_block_over_block(block_pt_ls obj))
					;;
					(when result
						println(silk->??)
						printf("Over text: [%L]\n" obj->xy)
						
						(result_ls = (if (equal "text" type_silk) (list silk obj) (list obj)))
						(return result_ls)
					)
				)
				("path"
					;;; to check whether these are connected line
					(result = nil)
					(seg_ls = obj->segments)
					
					;;;; to ignore the manual drawing line
					(when (equal "path" type_silk)
						(se_ls = nil)
						(foreach seg seg_ls (se_ls = (append se_ls seg->startEnd)))
						(result = (exists x se_ls (exists y silk_se_ls (axlGeoPointsEqual x y))))
					)
					
					(unless result
						(foreach obj seg_ls
							(result = is_block_over_block(block_pt_ls obj))
							
							;;;; when result is t, then check arc and circle
							(when (and result (equal "arc" type_seg))
								(result = is_block_over_arc(obj pt_ls))
							)
							
							;;
							(when result
								println(silk->??)
								printf("Over path: [%L]\n" obj->startEnd)
								
								(if (equal "text" type_silk)
									(result_ls = (list silk))
									(result_ls = (list (silk->parent || silk) (obj->parent || obj)))
								)
								(return result_ls)
							)
						)
					)
				)
				("net"
					printf("Net start end [%L]\n" obj->startEnd)
				)
				("pin"
					println("Pin xy [%L]\n" obj->xy)
				)
				("via"
					printf("Via xy [%L]\n" obj->xy)
				)
				(t
					printf("is_over_else - Type [%s] has not been supported yet\n" type_obj)
				)
			)
		)
		
		(return nil)
	)
)

(procedure solder_to_silk_check(solder_ly_ls silk_ly_ls)
;	(let (silk_parent over_ls all_over_ls obj_ls box visi_ls)
		;;; visible to soldermask
		axlVisibleDesign(nil)
		(foreach ly silk_ly_ls (axlVisibleLayer ly t))
		(axlVisibleUpdate t)
		
		;;; get all thing on silkscreen
		axlClearSelSet()
		(visi_ls = (list "NOALL" "LINES" "TEXT" "SHAPES"))
		(axlSetFindFilter ?enabled visi_ls ?onButtons visi_ls)
		axlAddSelectAll()
		(silk_obj_ls = axlGetSelSet())
		axlClearSelSet()
		
		
		;;;;;;;;;; filter out the things above down to 1000
		(tmp_ls = nil)
		(for i 0 300 (tmp_ls = (append1 tmp_ls (nth i silk_obj_ls))))
		(silk_obj_ls = tmp_ls)
		
		;;;;;;;;;;
		
		;;; visible to silkscreen
	;	(foreach ly solder_ly_ls (axlVisibleLayer ly t))
	;	(axlVisibleUpdate t)
		
		;;; check the things in box
		(visi_ls = (list "NOALL" "LINES" "TEXT" "SHAPES" "PINS" "VIAS"))
		(axlSetFindFilter ?enabled visi_ls ?onButtons visi_ls)
		;; move to let later
		(over_ls = nil)
		(all_over_ls = nil)
		;;
		(foreach silk silk_obj_ls
			(box = silk->bBox)
			
			;;;; select all the object in this boundary box
			(axlSingleSelectBox box)
			(obj_ls = axlGetSelSet())
			
			;;;;; skip the path if its parent is as same as silk
			(when (equal "path" silk->objType)
				(silk_parent = silk->parent)
				(obj_ls = (mapcar (lambda (x) (if (and (equal "path" x->objType) (eq silk_parent x->parent)) nil x)) obj_ls))
				(obj_ls = (mapcan (lambda (x) (when x (list x))) obj_ls))
			)
			
			;;;; loop through the objects to check it's conflicted or not
			(over_ls = is_over_else(silk obj_ls))
			(when (dtpr over_ls)
				(all_over_ls = (append all_over_ls over_ls))
				println("")
			)
			
			;;;; the following creating line is for testing purpose, please comment it later
		;	(block_pt_ls = get_silk_block_pt(silk))
		;	(foreach block_pt block_pt_ls
		;		(axlDBCreateLine block_pt 1 "USER PART NUMBER/SILKSCREEN_TOP")
		;	)
		)
		
		;;; return result
		(all_over_ls = (maplist (lambda (x) (if (memq (car x) (cdr x)) nil (car x))) all_over_ls))
		(all_over_ls = (mapcan (lambda (x) (when x (list x))) all_over_ls))
		println(all_over_ls)
		
		(foreach over all_over_ls
			(case over->objType
				("text" printf("Text:[%s], xy:[%L]\n" over->text over->xy))
				("path" printf("Path: box:[%L]\n" over->bBox))
				("symbol" printf("Symbol:[%s], xy:[%L]\n" over over->xy))
				(t printf("No:[%s]\n" over->objType))
			)
		)
		
		
		;;; restore the setting
		(axlSetFindFilter ?enabled (list "noall") ?onButtons (list "noall"))
;	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of sub function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main function

(defun silkscreen_over_check_main ()
	(prog ()
		init()
		
		;;;;; check artwork having silkscreen and soldermask
		(unless (dtpr brd_box) println("More than one shape in photoplot layer. process halt") (return nil))
		(unless (dtpr silk_top_ls) println("No silkscreen top layer has been found. Process halt") (return nil))
		(unless (dtpr silk_bot_ls) println("No silkscreeb bottom layer has been found. Process halt") (return nil))
		(unless (dtpr solder_top_ls) println("No soldermask top layer has been found. Process halt") (return nil))
		(unless (dtpr solder_bot_ls) println("No soldermask bottom layer has been found. Process halt") (return nil))
		
		;;;;; check soldermask to silkscreen against top
		solder_to_silk_check(solder_top_ls silk_top_ls)
		
		
		;;;;; check soldermask to silkscreen against top
		;;;;; check silkscreen to silkscreen against bottom
		;;;;; output result to csv 
		;;;;; display the result as report
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of main function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

(axlCmdRegister "silkscreen_over_check" 'silkscreen_over_check_main)
(silkscreen_over_check_main)
; skill encrypt( "C:/skill/silkscreen_over_check_v1.il" "C:/skill/silkscreen_over_check_v1.ile")
; (load "silkscreen_over_check_v1.ile")
; (load "silkscreen_over_check_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup