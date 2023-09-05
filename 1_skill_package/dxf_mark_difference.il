;axlSetFindFilter(?enabled (list "LINESEGS" "SHAPESEGS" "VOIDSEGS") ?onButtons (list "LINESEGS" "SHAPESEGS" "VOIDSEGS"))
;axlSingleSelectPoint(1400.0:300.0)
;(car axlGetSelSet())->??
;axlGeoPointsEqual()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTRODUCTION
; 
; Editor: Derek Hsu
; Starting Date: 09/18/2017 - _Derek09182017
; Intent:
;	Automatically square up differences between dxf files 
; Usage:
;	1. Import two or more relative dxf files to a new board file
;	2. Run this program and the differences will be marked up on the new created subclasses in the Board Geometry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTRODUCTION

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; GLOBAL VARIABLE

(defun init ()
	(setq one_dxf_ls list())
	(setq another_dxf_ls list())
	(setq comparison_ls list())
	(setq red_square_layer_ls list())
	(setq square_postfix "_REDSQUARE")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; GLOBAL VARIABLE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN FUNCTION

(procedure separate_comparison_ls(comparison_ls)
	(one = (car comparison_ls))
	(one_postfix = (rindex one "_"))
	
	(foreach sub comparison_ls
		(if (nindex sub one_postfix)
			(one_dxf_ls = (append1 one_dxf_ls sub))
			(another_dxf_ls = (append1 another_dxf_ls sub))
		)
	)
	
	(and (dtpr one_dxf_ls) (dtpr another_dxf_ls) (eqv (length one_dxf_ls) (length another_dxf_ls)))
)

(procedure right_rindex(word de) ; rindex( "dandelion" "d")
	(when (and (stringp word) (stringp de) ((strlen word) > (strlen de)))
		(substring word 1 ((strlen word) - (strlen (rindex word de))))
	)
)

(procedure delete_layer(layer_name)
	
	(axlVisibleDesign nil)
	(axlVisibleLayer layer_name t)
	axlVisibleUpdate(t)
	
	axlSetFindFilter(?enabled list("all") ?onButtons list("all"))
	axlAddSelectAll()
	(deleted_ls = (mapcan (lambda (x) (when (equal layer_name x->layer) (list x))) axlGetSelSet()))
	axlDeleteObject(deleted_ls)

	(layer = axlLayerGet(layer_name))
	axlDeleteObject(layer)
)

(procedure add_red_square_subclass(one_dxf_ls)
	(red_square_layer_ls = (mapcar (lambda (x) (strcat "REDSQUARE" (index right_rindex(x "_") "_"))) one_dxf_ls))
	
	(foreach sub red_square_layer_ls
		(layer_name = (strcat "BOARD GEOMETRY/" sub))
		(when (axlIsLayer layer_name) delete_layer(layer_name)
			(if (axlIsLayer layer_name)
				printf("Fail to delete layer: %s\n" layer_name)
				printf("Success to delete layer: %s\n" layer_name)
			)
		)
		axlLayerCreateNonConductor(layer_name)
	)
	
	(eqv (length one_dxf_ls) (length (rexMatchList "^REDSQUARE_" axlGetParam("paramLayerGroup:BOARD GEOMETRY")->groupMembers)))
)

(procedure get_all_other_segs(layer_name)
	(sel_ls = list())
	
	axlClearSelSet()
	axlVisibleDesign(nil)
	axlVisibleLayer(layer_name t)
	axlVisibleUpdate(t)
	axlSetFindFilter(?enabled (list "LINESEGS" "SHAPESEGS" "VOIDSEGS") ?onButtons (list "LINESEGS" "SHAPESEGS" "VOIDSEGS"))
	axlAddSelectAll()
	(sel_ls = axlGetSelSet())
	axlClearSelSet()
	axlSetFindFilter(?enabled "NOALL")
	axlVisibleDesign(nil)
	axlVisibleUpdate(t)
	
	sel_ls
)

(procedure get_four_corner_pts(center_pt)
	(let ((ll_pt list()) (lu_pt list()) (rp_pt list()) (rl_pt list()))
		(when (dtpr center_pt)
			(ll_pt = ((car center_pt) / hor * hor):((cadr center_pt) / ver * ver)) ; left lower
			(lu_pt = (car ll_pt):((cadr ll_pt) + ver)) ; left upper
			(rp_pt = ((car lu_pt) + hor):(cadr lu_pt)) ; right upper
			(rl_pt = ((car ll_pt) + hor):(cadr ll_pt)) ; right lower
		)
		
		(if (and (dtpr ll_pt) (dtpr lu_pt) (dtpr rp_pt) (dtpr rl_pt))
			(list ll_pt lu_pt rp_pt rl_pt)
			list()
		)
	)
)

(procedure draw_red_square(center_pt square_subclass)
	(when (and (dtpr center_pt)
			(dtpr (four_corner_ls = get_four_corner_pts(center_pt)))
			(axlIsLayer (layer = (strcat "BOARD GEOMETRY/" square_subclass))))
		;(path = axlPathStart((list 100:100 200:200) 5))
		(path = axlPathStart( (append1 four_corner_ls (car four_corner_ls)) 5))
		(unless axlDBCreatePath(path layer)
			printf("Fail to create square on %L\n" four_corner_ls)
		)
	)
)

(procedure get_center_pt(seg)
	(center_pt = list())
	
	(case seg->objType
		("arc" (center_pt = axlMidPointArc(seg->startEnd seg->xy seg->radius seg->isClockwise)) )
		("line" (center_pt = axlMidPointLine(seg->startEnd)))
		;(t printf("Type: %s does not support. Location: %L\n" seg->objType seg->startEnd))
	)
	
	center_pt
)

(procedure find_seg_on_layer(seg sub_layer)
	(center_pt = list())
	(found_pt = list())
	(full_layer = (strcat "BOARD GEOMETRY/" sub_layer))
	
	(when (and (axlIsLayer seg->layer) (axlIsLayer (layer = (strcat "BOARD GEOMETRY/" sub_layer))))
		(center_pt = get_center_pt(seg))
		
		(when (and (dtpr center_pt) ((car center_pt) > 0) ((cadr center_pt) > 0))
			(center_pt = find_object_by_point(center_pt full_layer (list "LINESEGS" "SHAPESEGS" "VOIDSEGS")))
		)
	)
	
	center_pt
)

(procedure find_object_by_point(point full_layer find_filter_opts)
	(sel_pt = nil)
	
	axlClearSelSet()
	axlVisibleDesign(nil)
	axlVisibleLayer(full_layer t)
	axlVisibleUpdate(t)
	axlSetFindFilter(?enabled find_filter_opts ?onButtons find_filter_opts)
	(sel_pt = axlSingleSelectPoint(point))
	axlClearSelSet()
	axlSetFindFilter(?enabled "NOALL")
	axlVisibleDesign(nil)
	axlVisibleUpdate(t)
	
	sel_pt
)

(procedure red_square_exists(point square_subclass)
	(exist = nil)
	
	(when (and (dtpr point)
				(dtpr (four_corner_ls = get_four_corner_pts(point)))
				(axlIsLayer (layer = (strcat "BOARD GEOMETRY/" square_subclass))))
		
		(l_pt = (axlMidPointLine (list (nth 0 four_corner_ls) (nth 1 four_corner_ls)))) ; left
		(u_pt = (axlMidPointLine (list (nth 1 four_corner_ls) (nth 2 four_corner_ls)))) ; upper
		(r_pt = (axlMidPointLine (list (nth 2 four_corner_ls) (nth 3 four_corner_ls)))) ; right
		(d_pr = (axlMidPointLine (list (nth 3 four_corner_ls) (nth 0 four_corner_ls)))) ; downer
		
		(when (and find_object_by_point(l_pt layer "LINES")
					find_object_by_point(u_pt layer "LINES")
					find_object_by_point(r_pt layer "LINES")
					find_object_by_point(d_pr layer "LINES"))
			(exist = t)
		)
	)
	
	exist
)

(defun search_seg_on_another_subclass (seg_ls another_subclass square_subclass)
	(foreach seg seg_ls
		(center_pt = find_seg_on_layer(seg another_subclass)) ; (seg = (car one_seg_ls)) ; another_subclass = another
		(unless center_pt
			(center_pt = get_center_pt(seg))
			(unless red_square_exists(center_pt square_subclass) ; square_subclass = square
				draw_red_square(center_pt square_subclass)
			)
		)
	)
)

(defun compare_layer ()
	(foreach (one another square) one_dxf_ls another_dxf_ls red_square_layer_ls
		printf("Current layers: %s,%s\n" one another)
		
		(one_seg_ls = (get_all_other_segs (strcat "BOARD GEOMETRY/" one))) ; (one = (car one_dxf_ls))
		(another_seg_ls = (get_all_other_segs (strcat "BOARD GEOMETRY/" another))) ; (another = (car another_dxf_ls))
		
		(if (and (dtpr one_seg_ls) (dtpr another_seg_ls)) then
			(one_seg_ls = (mapcan (lambda (x) (when (or (nindex x->objType "line") (nindex x->layer "arc")) (list x))) one_seg_ls))
			(another_seg_ls = (mapcan (lambda (x) (when (or (nindex x->objType "line") (nindex x->layer "arc")) (list x))) another_seg_ls))
			
			printf("%s: %d  -  %s: %d\n" one (length one_seg_ls) another (length another_seg_ls))
			
			search_seg_on_another_subclass(one_seg_ls another square) ; (square = (car red_square_layer_ls))
			search_seg_on_another_subclass(another_seg_ls one square)
		else
			printf("Fail to get 'Other segs' from layer %s and %s in Board Geometry.\n" one another)
		)
	)
)

(defun dxf_mark_difference_main (@optional (ver 1000) (hor 1000))
	(prog ()
		init()
		
		;;;;; check arguments
		(unless (and (plusp ver) (integerp ver) (plusp hor) (integerp hor))
			println("Fail to imput the arguments. Both arguments have to be positive number.")
			return(nil)
		)
		
		;;;;; extract the all comparison subclass out
		(subclass_ls = axlGetParam("paramLayerGroup:BOARD GEOMETRY")->groupMembers)
		(unless (dtpr (comparison_ls = (rexMatchList "^COMPARISON_" subclass_ls)))
			println("No comparison subclass has been found in BOARD GEOMETRY. Hint: COMPARISON_TOP_1")
			return(nil)
		)
		
		;;;;; seperate the comparison list to two
		(unless separate_comparison_ls(comparison_ls)
			println("Fail to extract the comparison from Board Geometry or the dxf num is different")
			return(nil)
		)
		
		;;;;; create new subclass for storing the red square
		(unless add_red_square_subclass(one_dxf_ls)
			printf("Fail to create subclasses %s in Board Geometry.\n" square_postfix)
			return(nil)
		)
		
		;;;;; compare layer by layer
		compare_layer()
		
		axlUIConfirm( "The differences has been marked." )
		
		return(t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN FUNCTION

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETTING UP

(dxf_mark_difference_main)
(axlCmdRegister "dxf_mark_difference" 'dxf_mark_difference_main)
; encrypt( "c:/skill/dxf_mark_difference_v1.il" "C:/skill/dxf_mark_difference_v1.ile")
; (load "dxf_mark_difference_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETTING UP