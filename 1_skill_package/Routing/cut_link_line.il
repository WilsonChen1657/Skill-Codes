;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; 1. Developer: Derel Hsu
; 2. Starting Date: 1/14/2019 - _Derek01142019
; 3. introduction: do cut and link net or line by right click
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global var

(procedure init_Derek01142019()
	(setq global_mode nil)
	(setq mypopup (axlUIPopupDefine nil (list (list "Done" 'axlFinishEnterFun)
												(list "Cancel" 'axlCancelEnterFun)
												(list "MENU_SEPARATOR" nil)
												(list "cut cline/seg" 'set_cut_line_Derek01142019)
												(list "cut shape" 'set_cut_shape_Derek01142019)
												(list "MENU_SEPARATOR" nil)
												(list "link (corner)" 'set_link_cor_Derek01142019)
												(list "link (straight)" 'set_link_str_Derek01142019)
												(list "MENU_SEPARATOR" nil))))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of gloval var

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

(procedure create_line_Derek01142019(a_xy b_xy layer width @optional (net_nm 'line))
	(prog (path new_path)
		(unless (dtpr a_xy) (println "ArgErr: create_line(0)") (return nil))
		(unless (dtpr b_xy) (println "ArgErr: create_line(1)") (return nil))
		(unless (axlIsLayer layer) (println "ArgErr: create_line(2)") (return nil))
		(unless (floatp width) (println "ArgErrL create_line(3)") (return nil))
		(unless (or (eq 'line net_nm) (axlDBFindByName 'net net_nm)) (println "ArgErr: create_line(4)") (return nil))
		;;
		
		(path = (axlPathStart (list a_xy)))
		(axlPathLine path width b_xy)
		
		;;; if layer is in etch, then force the line become cline with name ""
		(new_path = (axlDBCreatePath path layer net_nm))
		(printf "Create [%s] between %L in width:%f on %s\n" net_nm (list a_xy b_xy) width layer)
		
		(return new_path)
	)
)

(procedure scissor_line_Derek01142019(seg_ls xy_1234)
	; seg_id = (car axlGetSelSet())
	(prog (box xy_1 xy_2 xy_3 xy_4 line4 se layer width to_cut net_id net_nm seg_parent seg_prop)
		(unless (dtpr seg_ls) (return nil))
		(unless (eqv 4 (length xy_1234)) (println "ArgErr: scissor_line(0)") (return nil))
		
		(xy_1 = (car xy_1234))
		(xy_2 = (cadr xy_1234))
		(xy_3 = (caddr xy_1234))
		(xy_4 = (cadddr xy_1234))
		(box = (list xy_1 xy_3))
		(line4 = (list (list xy_1 xy_2) (list xy_2 xy_3) (list xy_3 xy_4) (list xy_4 xy_1)))
		
		;; remove the segment in the selected box
		(in_seg_ls = (mapcan (lambda (s) (when (forall p s->startEnd (axlIsPointInsideBox p box)) (list s))) seg_ls))
		(foreach seg_id in_seg_ls (axlDeleteObject seg_id))
		(seg_ls = (mapcan (lambda (s) (when (stringp s->objType) (list s))) seg_ls))
		
		;;
		(foreach seg_id seg_ls
			(se = seg_id->startEnd)
			(xy_start = (car se))
			(xy_end = (cadr se))
			(layer = seg_id->layer)
			(width = seg_id->width)
			(net_nm = seg_id->net->name)
			(when (and (null net_nm) (index layer "ETCH")) (net_nm = ""))
			(seg_prop = seg_id->prop)
			
			;; if box edge cut up the segment on the board
			(foreach line line4
				(a_b_dis = (axl_ol_ol2 se line))
				(when (zerop (caddr a_b_dis))
					(when (stringp seg_id->objType) (axlDeleteObject seg_id))
					(xy_mid = (car a_b_dis))
					;;
					(line_1 = (list xy_start xy_mid))
					(line_2 = (list xy_end xy_mid))
					(cond
						((exists se line4 (and (zerop (caddr (axl_ol_ol2 line_1 se))) (not (axlGeoPointsEqual (car se) (car line)))))
							(xy_one = xy_end)
						)
						((exists se line4 (and (zerop (caddr (axl_ol_ol2 line_2 se))) (not (axlGeoPointsEqual (car se) (car line)))))
							(xy_one = xy_start)
						)
						((axlIsPointInsideBox xy_start box) (xy_one = xy_end))
						((axlIsPointInsideBox xy_end box) (xy_one = xy_start))
					)
					;;
					(if (stringp net_nm) then
						(new_path = (create_line_Derek01142019 xy_one xy_mid layer width net_nm))
					else
						(new_path = (create_line_Derek01142019 xy_one xy_mid layer width))
					)
				)
			)
		)
		
		(return t)
	)
)

(procedure in_layer_Derek01142019(tar_ly obj)
	(prog (type layer_ls)
		(type = obj->objType)
		(unless (member type (list "line" "via" "pin")) (println "ArgErr: in_layer(0)") (return nil))
		;;
		
		(case type
			(("via" "pin")
				(layer_ls = obj->startEnd)
				(when (forall x (list "ETCH/TOP" "ETCH/BOTTOM") (member x layer_ls))
					(layer_ls = 'all)
				)
			)
			("line" (layer_ls = (list obj->layer)))
		)
		
		(return (or (eq 'all layer_ls) (member tar_ly layer_ls)))
	)
)

(procedure get_unlink_xy_Derek01142019(cl_id)
	;;  cl_id = (car axlGetSelSet())
	(prog (layer net_nm se one_xy another_xy one_box another_box obj_ls)
		(unless cl_id->net (println "ArgErr: get_unlink_xy(0)") (return nil))
		(axlSetFindFilter ?enabled (list "NOALL" "CLINESEGS" "PINS" "VIAS") ?onButtons (list "NOALL" "CLINESEGS" "PINS" "VIAS"))
		;;
		(layer = cl_id->layer)
		(net_nm = cl_id->net->name)
		(se = cl_id->startEnd)
		(one_xy = (car se))
		(another_xy = (cadr se))
		;;
		(one_box = (list one_xy one_xy))
		(another_box = (list another_xy another_xy))
		;;
		
		(axlSingleSelectBox one_box)
		(obj_ls = axlGetSelSet())
		axlClearSelSet()
		(obj_ls = (mapcan (lambda (x) (when (and (in_layer_Derek01142019 layer x) (not (eq cl_id x))) (list x))) obj_ls))
		(obj_ls = (mapcan (lambda (x) (unless (and x->isEtch (not (exists p x->startEnd (axlGeoPointsEqual one_xy p)))) (list x))) obj_ls))
		(unless obj_ls (return one_xy))
		
		(axlSingleSelectBox another_box)
		(obj_ls = axlGetSelSet())
		axlClearSelSet()
		(obj_ls = (mapcan (lambda (x) (when (and (in_layer_Derek01142019 layer x) (not (eq cl_id x))) (list x))) obj_ls))
		(obj_ls = (mapcan (lambda (x) (unless (and x->isEtch (not (exists p x->startEnd (axlGeoPointsEqual another_xy p)))) (list x))) obj_ls))
		(unless obj_ls (return another_xy))
		
		(return nil)
	)
)

(procedure get_another_xy_Derek01142019(xy line_id)
	(prog (se another_xy)
		(se = line_id->startEnd)
		(unless se (println "ArgErr: get_another_xy(0)") (return nil))
		(unless (exists x se (axlGeoPointsEqual xy x)) (println "ArgErr: get_another_xy(1)") (return nil))
		;;
		
		(another_xy = (if (axlGeoPointsEqual xy (car se)) (cadr se) (car se)))
		
		(return another_xy)
	)
)

(procedure get_link_info_Derek01142019()
	(prog (cline_ls net_table net_nm rest_ls a2_b2_ly_wd_ntm_ls end_xy_ls a2_xy b2_xy layer width)
		axlFinishEnterFun()
		(axlSetFindFilter ?enabled (list "NOALL" "CLINESEGS") ?onButtons (list "NOALL" "CLINESEGS"))
		(while axlSelect()
			(axlSetFindFilter ?enabled (list "NOALL" "CLINESEGS") ?onButtons (list "NOALL" "CLINESEGS"))
			(cline_ls = axlGetSelSet())
			(printf "Number of selected cline: %d\n" (length cline_ls))
			(axlUIPopupSet mypopup)
		)
		axlClearSelSet()
		
		;;;; get pair
		(net_table = (makeTable "net_pair" nil))
		(foreach cl_id cline_ls
			(net_nm = cl_id->net->name)
			(when (stringp net_nm) (net_table[net_nm] = (append1 net_table[net_nm] cl_id)))
		)
		(rest_ls = (mapcan (lambda (c) (unless (member c->net->name net_table->?) (list c->net->name))) cline_ls))
		(printf "Those net are not in pair: %L\n" rest_ls)
		
		;;;; get break side xy
		(foreach net_nm net_table->?
			(cline_ls = net_table[net_nm])
			(end_xy_ls = (mapcan (lambda (c) (when (xy = (get_unlink_xy_Derek01142019 c)) (list (list xy (get_another_xy_Derek01142019 xy c))))) cline_ls))
			(if (eqv 2 (length end_xy_ls)) then
				(a2_xy = (car end_xy_ls))
				(b2_xy = (cadr end_xy_ls))
				(layer = (car cline_ls)->layer)
				(width = (car cline_ls)->width)
				(a2_b2_ly_wd_ntm_ls = (append1 a2_b2_ly_wd_ntm_ls (list a2_xy b2_xy layer width net_nm)))
			else
				(printf "More then 2 or none break have been found on net: %s %L\n" net_nm (mapcar 'car end_xy_ls))
			)
		)
		
		(return a2_b2_ly_wd_ntm_ls)
	)
)

(procedure set_link_str_Derek01142019()
	(prog (a2_b2_ly_wd_ntm_ls a_xy b_xy layer width net_nm new_path)
		(println "***************** Link cline straight mode *****************")
		;;
		
		(a2_b2_ly_wd_ntm_ls = get_link_info_Derek01142019())
		
		;;;; create net
		(foreach slot a2_b2_ly_wd_ntm_ls
			(a_xy = (caar slot))
			(b_xy = (caadr slot))
			(layer = (caddr slot))
			(width = (cadddr slot))
			(net_nm = (nth 4 slot))
			;;
			(new_path = (create_line_Derek01142019 a_xy b_xy layer width net_nm))
		)
	)
)

(procedure get_formula_Derek01142019(seg)
	; seg = (car axlGetSelSet())->startEnd
	(prog (x1 x2 y1 y2 x1_e_x2 m c result)
		(unless (and (floatp (caar seg)) (floatp (cadar seg)) (floatp (caadr seg)) (floatp (cadar seg)))
			(println "ArgErr: get_formula(0)") (return nil))
		;;
		
		(x1 = (caar seg))
		(y1 = (cadar seg))
		(x2 = (caadr seg))
		(y2 = (cadadr seg))
		;;
		
		(x1_e_x2 = (x1 - x2))
		(if (zerop x1_e_x2) then
			;;; vertical line have infinit_Derek01142019ive m
			(m = nil)
			(c = x1) ;; x1 and x2 are the same value
		else
			(m = ((y1 - y2) / x1_e_x2))
			(c = (y1 - (m * x1)))
		)
		
		(result = (list m c))
		
		(return result)
	)
)

(procedure get_cross_xy_Derek01142019(seg1 seg2)
	;; y = m1x + b
	;; y = m2x + c
	;; x = (c - b) / (m1 - m2)
	;; y = (m1c - m2b) / (m1 - m2)
	(prog (line1_m_c line2_m_c m1 b m2 c m1_e_m2 x y cross_xy)
		(unless (and (floatp (caar seg1)) (floatp (cadar seg1)) (floatp (caadr seg1)) (floatp (cadar seg1)))
			(println "ArgErr: get_cross_xy(0)") (return nil))
		(unless (and (floatp (caar seg2)) (floatp (cadar seg2)) (floatp (caadr seg2)) (floatp (cadar seg2)))
			(println "ArgErr: get_cross_xy(1)") (return nil))
		;;
		(line1_m_c = (get_formula_Derek01142019 seg1))
		(line2_m_c = (get_formula_Derek01142019 seg2))
		;;
		(m1 = (car line1_m_c))
		(b = (cadr line1_m_c))
		(m2 = (car line2_m_c))
		(c = (cadr line2_m_c))
		;;
		(cond
			((not (or m1 m2)) (cross_xy = nil))
			((and (null m1) (floatp m2))
				(y = (b * m2 + c))
				(cross_xy = (list b y))
			)
			((and (null m2) (floatp m1))
				(y = (c * m1 + b))
				(cross_xy = (list c y))
			)
			(t
				(m1_e_m2 = (m1 - m2))
				(if (zerop m1_e_m2) then
					(cross_xy = nil)
				else
					(x = ((c - b) / m1_e_m2))
					(y = (((m1 * c) - (m2 * b)) / m1_e_m2))
					(cross_xy = (list x y))
				)
			)
		)
		
		(return cross_xy)
	)
)

(procedure is_same_direction_Derek01142019(from_xy to_xy tar_xy)
	(prog (fr2tar_dis fr2to_dis to2tar_dis result)
		(unless (and (floatp (car from_xy)) (floatp (cadr from_xy))) (println "ArgErr: is_same_direction(0)") (return nil))
		(unless (and (floatp (car to_xy)) (floatp (cadr to_xy))) (println "ArgErr: is_same_direction(0)") (return nil))
		(unless (and (floatp (car tar_xy)) (floatp (cadr tar_xy))) (println "ArgErr: is_same_direction(0)") (return nil))
		;;
		
		(fr2tar_dis = (axlDistance from_xy tar_xy))
		(fr2to_dis = (axlDistance from_xy to_xy))
		(to2tar_dis = (axlDistance to_xy tar_xy))
		
		(result = (axlGeoEqual fr2tar_dis (fr2to_dis + to2tar_dis)))
		
		(return result)
	)
)

(procedure set_link_cor_Derek01142019()
	;; a = (car axlGetSelSet())
	(prog (a2_b2_ly_wd_ntm_ls a2_xy b2_xy layer width net_nm new_path)
		(println "***************** Link cline corner mode *****************")
		;;
		
		(a2_b2_ly_wd_ntm_ls = get_link_info_Derek01142019())
		
		;;;; create net
		(foreach slot a2_b2_ly_wd_ntm_ls
			(a2_xy = (car slot))
			(b2_xy = (cadr slot))
			(layer = (caddr slot))
			(width = (cadddr slot))
			(net_nm = (nth 4 slot))
			
			;;;; get cross poiint
			(cross_xy = (get_cross_xy_Derek01142019 a2_xy b2_xy))
			
			;;;; check cross point
			(println cross_xy)
			(when cross_xy
				(unless (and (is_same_direction_Derek01142019 (cadr a2_xy) (car a2_xy) cross_xy) (is_same_direction_Derek01142019 (cadr b2_xy) (car b2_xy) cross_xy))
					(cross_xy = nil)
				)
			)
			;;;; link
			(if cross_xy then
				(new_path = (create_line_Derek01142019 (car a2_xy) cross_xy layer width net_nm))
				(new_path = (create_line_Derek01142019 cross_xy (car b2_xy) layer width net_nm))
			else
				(new_path = (create_line_Derek01142019 (car a2_xy) (car b2_xy) layer width net_nm))
			)
		)
	)
)

(procedure set_cut_shape_Derek01142019()
	(prog (line_width path line_ly xy_ls line fade_poly
		sh_ls sh_bd_id sh_bd_ls net_nm prop layer sh_poly new_poly_ls new_sh box_ls line_ls)
		(println "***************** Cut shape mode *****************")
		;;
		axlFinishEnterFun()
		
		;;; active layer to draw line
		(line_ly = "BOARD GEOMETRY/DIMENSION")
		(axlVisibleLayer line_ly t)
		
		;;; get the width of line
		(line_width = (axlEnterString ?prompts (list "Please enter the width of gap(ex: 4):")))
		(unless (and line_width (plusp (atof line_width)))
			(println "Please input a positive number to cut the beneath shape")
			(axlUIPopupSet mypopup)
			(return nil)
		)
		(line_width = (atof line_width))
		
		;;; create a line to cut the shape
		(axlUIPopupSet mypopup)
		(while (path = (axlEnterPath ?lastPath path))
			(axlUIPopupSet mypopup)
			(ep_ls = path->_pathList~>_endPoint)
			(line = (caar (axlDBCreateLine ep_ls line_width line_ly 'line)))
			;;
			(line_ls = (append1 line_ls line))
			;;
			(if (dtpr xy_ls) then
				(xy_ls = (append xy_ls (cdr (reverse ep_ls))))
			else
				(xy_ls = (append xy_ls (reverse ep_ls)))
			)
			;;
			(when (eqv 2 (length ep_ls)) (box_ls = (append box_ls ep_ls)))
			(when (eqv 3 (length ep_ls)) (box_ls = (append box_ls (list (list (car ep_ls) (cadr ep_ls)) (cdr ep_ls)))))
		)
		
		;;; create poly
		(line = (caar (axlDBCreateLine xy_ls line_width line_ly 'line)))
		(fade_poly = (axlPolyFromDB line))
		(axlDeleteObject line)
		
		;;; get shape beneath
		(axlSetFindFilter ?enabled (list "NOALL" "SHAPES") ?onButtons (list "NOALL" "SHAPES"))
		(foreach box box_ls (axlAddSelectBox box))
		(sh_ls = axlGetSelSet())
		axlClearSelSet()
		
		;;; cut the shape
		(foreach sh_id sh_ls
			(sh_bd_id = (if sh_id->shapeBoundary sh_id->shapeBoundary sh_id))
			(sh_bd_ls = (append1 sh_bd_ls sh_bd_id))
			(net_nm = sh_id->net->name)
			(prop =  (axlDBGetProperties sh_id))
			(layer = sh_bd_id->layer)
			(sh_poly = (axlPolyFromDB sh_bd_id))
			;;
			(new_poly_ls = (axlPolyOperation sh_poly fade_poly 'ANDNOT))
			;;
			(foreach np new_poly_ls
				(new_sh = (axlDBCreateShape np t layer net_nm))
				(if new_sh then
					(when prop
						(axlDBAddProp new_sh prop)
						(printf "Create a shape on %s with %L on %s\n" net_nm prop layer)
					)
					(printf "Create a shape on %s on %s\n" net_nm layer)
				else
					(println "Fail to create the shape")
				)
			)
		)
		;;
		(foreach sh_id sh_bd_ls (when (stringp sh_id->objType) (axlDeleteObject sh_id)))
		
		;;; remove line_ls
		(foreach line line_ls (axlDeleteObject line))
		
		;;; hide layer
		(axlVisibleLayer line_ly nil)
		(axlUIPopupSet mypopup)
	)
)

(procedure set_cut_line_Derek01142019()
	(prog (box seg_ls sh_ls)
		(println "***************** Cut seg mode *****************")
		;;
		axlFinishEnterFun()
		(axlSetFindFilter ?enabled (list "NOALL" "CLINESEGS" "LINESEGS") ?onButtons (list "NOALL" "CLINESEGS" "LINESEGS"))
		(while (box = axlEnterBox())
			(axlSetFindFilter ?enabled (list "NOALL" "CLINESEGS" "LINESEGS") ?onButtons (list "NOALL" "CLINESEGS" "LINESEGS"))
			(printf "Current box is:%L\n" box)
			
			;;
			(axlSingleSelectBox box)
			(seg_ls = axlGetSelSet())
			axlClearSelSet()
			;;
			(xy_1 = (car box))
			(xy_2 = (cadr box))
			(xy_3 = (list (car xy_2) (cadr xy_1)))
			(xy_4 = (list (car xy_1) (cadr xy_2)))
			(xy_1234 = (list xy_1 xy_3 xy_2 xy_4))
			;;
			
			;;; cut lines if any
			(scissor_line_Derek01142019 seg_ls xy_1234)
			
			;;; reset the right-click
			(axlUIPopupSet mypopup)
		)
	)
)

(procedure cut_link_line_main_Derek01142019()
	(prog ()
		(unless axlOKToProceed() println("Please done the current function to execute this function") (return nil))
		;;
		
		init_Derek01142019()
		
		(axlUIPopupSet mypopup)
		
		set_cut_line_Derek01142019()
		; set_link_cor_Derek01142019()
		; set_cut_shape_Derek01142019()
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "cut_link_line" 'cut_link_line_main_Derek01142019)
; cut_link_line_main_Derek01142019()
; skill (encrypt "C:/skill/cut_link_line_v1.il" "C:/skill/cut_link_line_v1.ile")
; (load "cut_link_line_v1.il")
; (load "cut_link_line_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup