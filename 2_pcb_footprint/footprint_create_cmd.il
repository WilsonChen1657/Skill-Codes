; (load "footprint_create_cmd.il")
;;;;; import pool
(setq global_x nil)
(setq global_y nil)
(setq alpha_ls (list "" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"
					"AA" "AB" "AC" "AD" "AE" "AF" "AG" "AH" "AI" "AJ" "AK" "AL" "AM" "AN" "AO" "AP" "AQ" "AR" "AS" "AT" "AU" "AV" "AW" "AX" "AY" "AZ"
					"BA" "BB" "BC" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BK" "BL" "BM" "BN" "BO" "BP" "BQ" "BR" "BS" "BT" "BU" "BV" "BW" "BX" "BY" "BZ"
					"MH1" "MH2" "MH3" "MH4" "MH5" "MH6" "MH7" "MH8" "MH9" "MH10" "MH11" "MH12" "MH13" "MH14" "MH15" "MH16" "MH17" "MH18" "MH19" "MH20"
					"MH21" "MH22" "MH23" "MH24" "MH25" "MH26" "MH27" "MH28" "MH29" "MH30" "MH31" "MH32" "MH33" "MH34" "MH35" "MH36" "MH37" "MH38" "MH39" "MH40"
					"MH41" "MH42" "MH43" "MH44" "MH45" "MH46" "MH47" "MH48" "MH49" "MH50" "MH51" "MH52" "MH53" "MH54" "MH55" "MH56" "MH57" "MH58" "MH59" "MH60"
					"MH61" "MH62" "MH63" "MH64" "MH65" "MH66" "MH67" "MH68" "MH69" "MH70" "MH71" "MH72" "MH73" "MH74" "MH75" "MH76" "MH77" "MH78" "MH79" "MH80"
					"MH81" "MH82" "MH83" "MH84" "MH85" "MH86" "MH87" "MH88" "MH89" "MH90" "MH91" "MH92" "MH93" "MH94" "MH95" "MH96" "MH97" "MH98" "MH99" "MH100"
					"MH101" "MH102" "MH103" "MH104" "MH105" "MH106" "MH107" "MH108" "MH109" "MH110" "MH111" "MH112" "MH113" "MH114" "MH115" "MH116" "MH117" "MH118"
					"MH119" "MH120" "MH121" "MH122" "MH123" "MH124" "MH125" "MH126" "MH127" "MH128" "MH129" "MH130" "MH131" "MH132" "MH133" "MH134" "MH135" "MH136"
					"MH137" "MH138" "MH139" "MH140" "MH141" "MH142" "MH143" "MH144" "MH145" "MH146" "MH147" "MH148" "MH149" "MH150" "MH151" "MH152" "MH153" "MH154"
					"MH155" "MH156" "MH157" "MH158" "MH159" "MH160" "MH161" "MH162" "MH163" "MH164" "MH165" "MH166" "MH167" "MH168" "MH169" "MH170" "MH171" "MH172"
					"MH173" "MH174" "MH175" "MH176" "MH177" "MH178" "MH179" "MH180" "MH181" "MH182" "MH183" "MH184" "MH185" "MH186" "MH187" "MH188" "MH189" "MH190"
					"MH191" "MH192" "MH193" "MH194" "MH195" "MH196" "MH197" "MH198" "MH199" "MH200"
					"P1" "P2" "P3" "P4" "P5" "P6" "P7" "P8" "P9" "P10" "P11" "P12" "P13" "P14" "P15" "P16" "P17" "P18" "P19" "P20" "P21" "P22" "P23" "P24" "P25"
					"P26" "P27" "P28" "P29" "P30" "P31" "P32" "P33" "P34" "P35" "P36" "P37" "P38" "P39" "P40" "P41" "P42" "P43" "P44" "P45"
					"P46" "P47" "P48" "P49" "P50" "P51" "P52" "P53" "P54" "P55" "P56" "P57" "P58" "P59" "P60" "P61" "P62" "P63" "P64" "P65"
					"P66" "P67" "P68" "P69" "P70" "P71" "P72" "P73" "P74" "P75" "P76" "P77" "P78" "P79" "P80" "P81" "P82" "P83" "P84" "P85"
					"P86" "P87" "P88" "P89" "P90" "P91" "P92" "P93" "P94" "P95" "P96" "P97" "P98" "P99" "P100" "P101" "P102" "P103" "P104" "P105"
					"P106" "P107" "P108" "P109" "P110" "P111" "P112" "P113" "P114" "P115" "P116" "P117" "P118" "P119" "P120"
					"P121" "P122" "P123" "P124" "P125" "P126" "P127" "P128" "P129" "P130" "P131" "P132" "P133" "P134" "P135"
					"P136" "P137" "P138" "P139" "P140" "P141" "P142" "P143" "P144" "P145" "P146" "P147" "P148" "P149" "P150"
					"P151" "P152" "P153" "P154" "P155" "P156" "P157" "P158" "P159" "P160" "P161" "P162" "P163" "P164" "P165"
					"P166" "P167" "P168" "P169" "P170" "P171" "P172" "P173" "P174" "P175" "P176" "P177" "P178" "P179" "P180"
					"P181" "P182" "P183" "P184" "P185" "P186" "P187" "P188" "P189" "P190" "P191" "P192" "P193" "P194" "P195"
					"P196" "P197" "P198" "P199" "P200"
					))

(procedure is_strings(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (forall x obj_ls (stringp x)))
		
		(return result)
	)
)

(procedure is_mils()
	(let ()
		(equal "mils" (car axlDBGetDesignUnits()))
	)
)

(procedure is_pins(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (forall x obj_ls (member x->objType '("pin" "padstack"))))
		
		(return result)
	)
)

(procedure is_nets(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (forall x obj_ls (equal "net" x->objType)))
		
		(return result)
	)
)

(procedure is_vias(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (forall x obj_ls (equal "via" x->objType)))
		
		(return result)
	)
)

(procedure is_symbols(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (forall x obj_ls (symbolp obj_ls)))
		
		(return result)
	)
)

(procedure is_layers(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (is_strings obj_ls))
		(when result (result = (forall x obj_ls (axlIsLayer x))))
		
		(return result)
	)
)

(procedure set_textbox1()
	(let (param)
		(param = (axlGetParam "paramTextBlock:1"))
		
		(if is_mils() then
			(param->width = 21.0)
			(param->photoWidth = 6.0)
			(param->lineSpace = 10.0)
			(param->height = 28.0)
			(param->charSpace = 0.0)
		else
			(param->width = 0.7112)
			(param->photoWidth = 0.1524)
			(param->lineSpace = 0.0)
			(param->height = 0.9144)
			(param->charSpace = 0.0)
		)
		
		(axlSetParam param)
	)
)

(procedure set_textbox10()
	(let (param)
		(param = (axlGetParam "paramTextBlock:10"))
		
		(if is_mils() then
			(param->width = 117.0)
			(param->photoWidth = 0.0)
			(param->lineSpace = 195.0)
			(param->height = 156.0)
			(param->charSpace = 62.0)
		else
			(param->width = 2.9718)
			(param->photoWidth = 0.0)
			(param->lineSpace = 4.953)
			(param->height = 3.9624)
			(param->charSpace = 1.5748)
		)
		
		(axlSetParam param)
	)
)

(procedure create_subclass(class_name @optional (overwrite t))
	(prog ()
		(main_cls_nm = (car (parseString class_name "/")))
		(unless (member main_cls_nm axlClasses()) (println "[POOL] create_subclass() - Main class is not exists") (return nil))
		
		(when (is_layers class_name)
			(layer = (axlLayerGet class_name))
			(axlDeleteObject layer)
		)
		
		(axlLayerCreateNonConductor class_name)
	)
)

(procedure get_pad_hv(obj_id layer)
	(prog (pad_id pad_box pad_hv rotation pad_ls)
		(unless (or (is_vias obj_id) (is_pins obj_id)) (println "ArgErr: get_pad_hv() - Arg has to be pin/via/padstack") (return nil))
		(unless (memq layer (list 'top 'bot)) (println "ArgErr: get_pad_hv() - layer has to be 'top or 'bot") (return nil))
		;;
		
		(rotation = (obj_id->rotation || 0.0))
		(pad_ls = obj_id->pads)
		
		;;
		(layer = (if (eq 'top layer) "ETCH/TOP" "ETCH/BOTTOM"))
		(pad_id = (car (setof p pad_ls (and (equal layer p->layer) (equal "REGULAR" p->type)))))
		(pad_box = pad_id->bBox)
		(pad_hv = (list (abs ((caar pad_box) - (caadr pad_box))) (abs ((cadar pad_box) - (cadadr pad_box)))))
		
		;;
		(when (or (axlGeoEqual 90.0 rotation) (axlGeoEqual 270.0 rotation)) (pad_hv = (reverse pad_hv)))
		
		(return pad_hv)
	)
)

(procedure get_drill_hv(obj_id)
	(prog (hor ver rotation result)
		(unless (or (is_vias obj_id) (is_pins obj_id)) (println "[POOL] get_drill_hv() - Arg has to be pin/via/padstack") (return nil))
		;;
		
		(pin_def = obj_id->definition)
		(hole_type = (pin_def->holeType || "None"))
		
		;;
		(case hole_type
			("circle_drill"
				(hor = ver = pin_def->drillDiameter)
			)
			(("oval_slot" "rectangle_slot")
				(hor = pin_def->drillSizeWidth)
				(ver = pin_def->drillSizeHeight)
			)
			(t (printf "get_drill_hv(): Not support type[%s] yet\n" hole_type))
		)
		
		;;
		(rotation = obj_id->rotation)
		(when (and (numberp hor) (numberp ver))
			(result = (list hor ver))
			;;
			(when (or (axlGeoEqual 90.0 rotation) (axlGeoEqual 270.0 rotation))
				(result = (reverse result))
			)
		)
	
		(return result)
	)
)

(procedure to_mm()
	(axlDBChangeDesignUnits "millimeters" 4)
	
	(println "Units to MM")
)

(procedure to_mils()
	(axlDBChangeDesignUnits "mils" 4)
	
	(println "Units to MIL")
)

(procedure active_silk_top()
	(axlSetActiveLayer "PACKAGE GEOMETRY/SILKSCREEN_TOP")
	(println "Active layer to [PACKAGE GEOMETRY/SILKSCREEN_TOP]")
)

(procedure active_place_top()
	(axlSetActiveLayer "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
	(println "Active layer to [PACKAGE GEOMETRY/PLACE_BOUND_TOP]")
)

(procedure active_place_bot()
	(axlSetActiveLayer "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
	(println "Active layer to [PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM]")
)

(procedure active_dfa_top()
	(axlSetActiveLayer "PACKAGE GEOMETRY/DFA_BOUND_TOP")
	(println "Active layer to [PACKAGE GEOMETRY/DFA_BOUND_TOP]")
)

(procedure active_assem_top()
	(axlSetActiveLayer "PACKAGE GEOMETRY/ASSEMBLY_TOP")
	(println "Active layer to [PACKAGE GEOMETRY/ASSEMBLY_TOP]")
)

(procedure active_pin_num()
	(axlSetActiveLayer "PACKAGE GEOMETRY/PIN_NUMBER")
	(println "Active layer to [PACKAGE GEOMETRY/PIN_NUMBER]")
)

(procedure active_prob_top()
	(axlSetActiveLayer "MANUFACTURING/NO_PROBE_TOP")
	(println "Active layer to [MANUFACTURING/NO_PROBE_TOP]")
)

(procedure active_pk_bot()
	(axlSetActiveLayer "PACKAGE KEEPOUT/BOTTOM")
	(println "Active layer to [PACKAGE KEEPOUT/BOTTOM]")
)

(procedure active_pk_top()
	(axlSetActiveLayer "PACKAGE KEEPOUT/TOP")
	(println "Active layer to [PACKAGE KEEPOUT/TOP]")
)

(procedure active_past_top()
	(axlSetActiveLayer "PACKAGE GEOMETRY/PASTEMASK_TOP")
	(println "Active layer to [PACKAGE GEOMETRY/PASTEMASK_TOP]")
)

(procedure active_past_bot()
	(axlSetActiveLayer "PACKAGE GEOMETRY/PASTEMASK_BOTTOM")
	(println "Active layer to [PACKAGE GEOMETRY/PASTEMASK_BOTTOM]")
)

(procedure active_route_keepout_all()
	(axlSetActiveLayer "ROUTE KEEPOUT/ALL")
	(println "Active layer to [ROUTE KEEPOUT/ALL]")
)

(procedure set_grid(@optional x y)
	(prog (grid)
		(unless axlOKToProceed()
			(println "Please finish current command first")
			(printf gg_help)
			(return nil)
		)
		;;
		
		(when (stringp x) (x = (atof x)))
		(when (stringp y) (y = (atof y)))
		(unless (and (floatp x) (floatp y))
			grid_info()
			(return nil)
		)
		
		(foreach g_nm (axlDBGridGet nil)
			(grid = (axlDBGridGet g_nm))
			(grid->name = 'all)
			(grid->xGrids = x)
			(grid->yGrids = y)
			(axlDBGridSet grid)
		)
		
		;;
		(printf "Grid to [%f,%f] in unit[%s] in acc[%d]\n" x y (car axlDBGetDesignUnits()) (cadr axlDBGetDesignUnits()))
	)
)

(procedure grid_info()
	(prog (grid unit acc)
		(println "Grid Information:")
		(foreach g_nm (axlDBGridGet nil)
			(grid = (axlDBGridGet g_nm))
			(printf "\tName[%s], grid_x[%L], grid_y[%L]\n" grid->name grid->xGrids grid->yGrids)
		)
		(unit = (car axlDBGetDesignUnits()))
		(acc = (cadr axlDBGetDesignUnits()))
		(printf "\tUnit[%s]\n\tAccuracy[%d]\n" unit acc)
	)
)

(procedure create_rectangle(type center_xy x y layer)
	(prog (x_d2 y_d2 ul_xy ur_xy dr_xy dl_xy unit path width obj_id)
		(unless (and (floatp x) (floatp y)) (println "ArgErr: create_rectangle() - 2 Args have to be float") (return nil))
		;;
		
		(x_d2 = (x / 2))
		(y_d2 = (y / 2))
		(ul_xy = (axlMXYAdd center_xy (list -x_d2 y_d2))) ;; up left xy
		(ur_xy = (axlMXYAdd center_xy (list x_d2 y_d2))) ;; up right xy
		(dr_xy = (axlMXYAdd center_xy (list x_d2 -y_d2))) ;; down right xy
		(dl_xy = (axlMXYAdd center_xy (list -x_d2 -y_d2))) ;; down left xy
		
		;;
		(unit = (car axlDBGetDesignUnits()))
		(width = (if (equal "PACKAGE GEOMETRY/SILKSCREEN_TOP" layer) 6.0 0.0))
		(if (and (not (eq 'shape type)) (equal "PACKAGE GEOMETRY/SILKSCREEN_TOP" layer)) then
			(cond
				((equal "millimeters" unit) (width = 0.1524))
				((equal "mils" unit) (width = 6.0))
				(t (width = 0.0))
			)
		else
			(width = 0.0)
		)
		
		(caseq type
			('line
				(obj_id = (axlDBCreateLine (list ul_xy ur_xy dr_xy dl_xy ul_xy) width layer 'line))
			)
			('shape
				path = (axlPathStart (list ul_xy ur_xy dr_xy dl_xy ul_xy))
				obj_id = axlDBCreateShape( path t layer)
				unless( obj_id (obj_id = axlDBCreateShape( path nil layer)))
			)
			(t (printf "Not support type [%s]\n" type))
		)
		
		(printf "Create %s [%f] by [%f] in width[%f] in unit[%s] on %s\n" type x y width unit layer)
		
		(return obj_id)
	)
)

(procedure create_oblong_path(xy hor ver)
	;;; create path in oblong
	(prog (path diameter radius side side_d2 pt1 pt2)
		(unless (dtpr xy) (println "ArgErr: create_oblong_path() - xy is not in dtpr") (return nil))
		(unless (plusp hor) (println "ArgErr: create_oblong_path() - hor is not a positive number") (return nil))
		(unless (plusp ver) (println "ArgErr: create_oblong_path() - ver is not a positive number") (return nil))
		;;
		
		(diameter = (if (hor > ver) ver hor))
		(radius = (diameter / 2))
		(side = (abs (hor - ver)))
		(side_d2 = (side / 2))
		
		;;; create path
		(if (hor > ver) then
			;;; oblong x
			(pt1 = (axlMXYAdd xy (list -side_d2 radius))) ;; up right point
			(pt2 = (axlMXYAdd pt1 (list side 0))) ;; up right point
			(path = (axlPathStart (list pt1 pt2) 0))
			;;
			(pt1 = (axlMXYAdd pt2 (list 0 -radius))) ;; center of right arc
			(pt2 = (axlMXYAdd pt1 (list 0 -radius))) ;; down right point
			(axlPathArcCenter path 0 pt2 t pt1)
			;;
			(pt1 = (axlMXYAdd pt2 (list -side 0))) ;; down left point
			(axlPathLine path 0 pt1)
			;;
			(pt2 = (axlMXYAdd pt1 (list 0 radius))) ;; center of left arc
			(pt1 = (axlMXYAdd pt2 (list 0 radius))) ;; up right point
			(axlPathArcCenter path 0 pt1 t pt2)
		else
			;;; oblong y
			(pt1 = (axlMXYAdd xy (list -radius side_d2))) ;; up left point
			(pt2 = (axlMXYAdd pt1 (list 0 -side))) ;; down left point
			(path = (axlPathStart (list pt1 pt2) 0))
			;;
			(pt1 = (axlMXYAdd pt2 (list radius 0))) ;; center of under arc
			(pt2 = (axlMXYAdd pt1 (list radius 0))) ;; right down point
			(axlPathArcCenter path 0 pt2 nil pt1)
			;;
			(pt1 = (axlMXYAdd pt2 (list 0 side))) ;; up right point
			(axlPathLine path 0 pt1)
			;;
			(pt2 = (axlMXYAdd pt1 (list -radius 0))) ;; center of up arc
			(pt1 = (axlMXYAdd pt2 (list -radius 0))) ;; left up point
			(axlPathArcCenter path 0 pt1 nil pt2)
		)
		
		(return path)
	)
)

(procedure create_oblong(type xy hor ver layer)
	(prog (diameter radius side pt1 pt2 path obj_id)
		(unless (and (symbolp type) (dtpr xy) (numberp hor) (numberp ver) (axlIsLayer layer)) (println "ArgErr: create_oblong(0)") (return nil))
		;;
		
		(path = (create_oblong_path xy hor ver))
		
		;;; create shape or line
		(caseq type
			('line (obj_id = (axlDBCreatePath path layer 'line)))
			('shape
				obj_id = axlDBCreateShape( path t layer)
				unless( obj_id (obj_id = axlDBCreateShape( path nil layer)))
			)
			(t (printf "Not support type [%s]\n" type))
		)
		
		(return obj_id)
	)
)

(procedure create_circle(type xy diameter layer)
	(prog (radius width unit path obj_id)
		(unless (and (floatp diameter) (plusp diameter)) (println "ArgErr: create_circle() - Fail diameter value") (return nil))
		;;
		
		(radius = (diameter / 2))
		(unit = (car axlDBGetDesignUnits()))
		(if (and (not (eq 'shape type)) (equal "PACKAGE GEOMETRY/SILKSCREEN_TOP" layer)) then
			(cond
				((equal "millimeters" unit) (width = 0.1524))
				((equal "mils" unit) (width = 6.0))
				(t (width = 0.0))
			)
		else
			(width = 0.0)
		)
		
		(caseq type
			('line
				(obj_id = (axlDBCreateCircle (list xy radius) width layer))
			)
			('shape
				path = (axlPathStartCircle (list xy radius) 0)
				obj_id = axlDBCreateShape( path t layer)
				unless( obj_id (obj_id = axlDBCreateShape( path nil layer)))
			)
			(t (printf "Not support type [%s]\n" type))
		)
		
		(printf "Create %s on [%L] on diameter [%f] in unit[%s] on %s\n" type xy diameter unit layer)
		
		(return obj_id)
	)
)

(procedure set_line(@optional (x 0) (y -1))
	(prog (type center_xy layer)
		(unless axlOKToProceed() (println "Please finish current command first") (printf ll_help) (return nil))
		(when (and (not (zerop x)) (eqv -1 y)) (y = x))
		(when (and (zerop x) (floatp global_x) (eqv -1 y) (floatp global_y)) (x = global_x) (y = global_y))
		;;
		
		(when (stringp x) (x = (atof x)))
		(when (stringp y) (y = (atof y)))
		(unless (and (floatp x) (floatp y)) (println "2 floating number are required") (return nil))
		
		;;
		(layer = axlGetActiveLayer())
		(type = 'line)
		(center_xy = 0:0)
		(cond
			((and (minusp x) (plusp y))
				;;; create oblong while x is in negative
				(create_oblong type center_xy -x y layer)
			)
			((and (plusp x) (zerop y))
				;;; create a circle shape while x is a non-zero positive number and y is zero
				(diameter = (if (zerop x) y x))
				(create_circle type center_xy diameter layer)
			)
			((and (plusp x) (plusp y))
				;;; create a oblong while both x and y are positive number
				(create_rectangle type center_xy x y layer)
			)
			(t
				(printf "set_line() - Fail to support args [%.2f] [%.2f]\n" x y)
			)
		)
		
		;; global setting
		(global_x = x)
		(global_y = y)
	)
)

(procedure set_shape(@optional (x 0) (y -1))
	(prog (type layer path)
		(unless axlOKToProceed() (println "Please finish current command first") (printf ss_help) (return nil))
		(when (and (not (zerop x)) (eqv -1 y)) (y = x))
		(when (and (zerop x) (floatp global_x) (eqv -1 y) (floatp global_y)) (x = global_x) (y = global_y))
		;;
		
		(when (stringp x) (x = (atof x)))
		(when (stringp y) (y = (atof y)))
		(unless (and (floatp x) (floatp y)) (println "ArgErr: set_shape() - 2 floating number are required") (printf ss_help) (return nil))
		
		;;
		(layer = axlGetActiveLayer())
		(type = 'shape)
		(center_xy = 0:0)
		(cond
			((and (minusp x) (plusp y))
				;;; create oblong while x is in negative
				(create_oblong type center_xy -x y layer)
			)
			((and (plusp x) (zerop y))
				;;; create a circle shape while x is a non-zero positive number and y is zero
				(diameter = (if (zerop x) y x))
				(create_circle type center_xy diameter layer)
			)
			((and (plusp x) (plusp y))
				;;; create a oblong while both x and y are positive number
				(create_rectangle type center_xy x y layer)
			)
			(t
				(printf "set_shape() - Fail to support args [%.2f] [%.2f]\n" x y)
			)
		)
		
		;; global setting
		(global_x = x)
		(global_y = y)
	)
)

(procedure set_text(word @optional (center_xy 0:0))
	(prog (tb1 orient)
		(unless axlOKToProceed() (println "Please finish current command first") (printf tt_help) (return nil))
		(when (zerop (strlen word)) (println "Please input at least one character") (printf tt_help) (return nil))
		;;
		
		set_textbox1()
		
		;;
		(orient = (make_axlTextOrientation ?textBlock "1" ?rotation 0.0 ?mirrored nil ?justify "center"))
		(axlDBCreateText word center_xy orient "REF DES/SILKSCREEN_TOP")
		(axlDBCreateText word center_xy orient "REF DES/ASSEMBLY_TOP")
		(axlDBCreateText word center_xy orient "COMPONENT VALUE/DISPLAY_TOP")
	)
)

(procedure set_view(@optional (view 1))
	(prog (layer_act is_vis)
		(when (eqv 1 view) (view = "1"))
		(unless (member view '("0" "1" "2" "3")) (printf "No this option: [%s]\n" view) (printf ii_help) (return nil))
		;;
		
		(case view
			("0" (axlVisibleDesign nil))
			("1" (axlVisibleDesign t))
			("2"
				(layer_act = axlGetActiveLayer())
				(is_vis = (axlIsVisibleLayer layer_act))
				(axlVisibleLayer layer_act (not is_vis))
			) ;; light up active layer (toggle)
			("3"
				(layer_act = axlGetActiveLayer())
				(is_vis = (axlIsVisibleLayer layer_act))
				(axlVisibleDesign (not is_vis))
				(axlVisibleLayer layer_act is_vis)
			) ;; light up active layer only (toggle)
		)
		(axlVisibleUpdate t)
	)
)

(setq last_x nil)
(setq last_y nil)
(setq last_nx nil)
(setq last_ny nil)
(procedure set_pick(@optional x y nx ny)
	(prog ()
		(unless (or (and x y nx ny) (and last_x last_y last_nx last_ny))
			(println "Please give it initial value")
			(printf xx_help)
			(return nil)
		)
		;;
		
		(if (and x y nx ny) then
			(last_x = (atof x))
			(last_y = (atof y))
			(last_nx = (atof nx))
			(last_ny = (atof ny))
			(unless (and (floatp last_x) (floatp last_y) (floatp last_nx) (floatp last_ny))
				(println "Please input number")
				(last_x = last_y = last_nx = last_ny = nil)
				(return nil)
			)
		else
			(last_x = (last_x + last_nx))
			(last_y = (last_y + last_ny))
		)
		(axlShell (sprintf nil "pick %f %f;" last_x last_y))
		
		(printf "Current pick %L. Next pick %L. Unit[%s]\n" last_x:last_y (last_x + last_nx):(last_y + last_ny) (car axlDBGetDesignUnits()))
	)
)

(procedure get_numbers(vals)
	(prog (start end result_ls)
		(if (index vals "-") then
			;;
			(vals = (upperCase vals))
			
			(start = (car (parseString vals "-")))
			(end = (cadr (parseString vals "-")))
			(when (atoi start) (start = (atoi start)))
			(when (atoi end) (end = (atoi end)))
			
			(unless (or (member start alpha_ls) (plusp start)) (println "ArgErr: get_numbers(1)") (return nil))
			(unless (or (member end alpha_ls) (plusp end)) (println "ArgErr: get_numbers(2)") (return nil))
			(unless (or (and (plusp start) (plusp end)) (and (member start alpha_ls) (member end alpha_ls)))
				(println "ArgErr: get_numbers(3)") (return nil)
			)
			;;
			
			(if (plusp start) then
				(if (end > start) then
					(for i start end (result_ls = (append1 result_ls i)))
				else
					(for i end start (result_ls = (append1 result_ls i)))
					(result_ls = (reverse result_ls))
				)
			else
				(start_th = (listnindex alpha_ls start))
				(end_th = (listnindex alpha_ls end))
				;;
				(if (end_th > start_th) then
					(for i start_th end_th (result_ls = (append1 result_ls (nth i alpha_ls))))
				else
					(for i end_th start_th (result_ls = (append1 result_ls (nth i alpha_ls))))
					(result_ls = (reverse result_ls))
				)
			)
		else
			(result_ls = (list (if (integerp (atoi vals)) (atoi vals) vals)))
		)
		
		
		(return result_ls)
	)
)

(procedure get_pin_num_matrix(row_ls col_ls)
	(prog (pin_num_ls pre_col_ls cur_col_ls result_ls)
		(unless (dtpr row_ls) (println "ArgErr: get_pin_num_matrix() - row_ls is missing") (return nil))
		(unless (dtpr col_ls) (println "ArgErr: get_pin_num_matrix() - col_ls is missing") (return nil))
		
		;; get pin number
		(col_length = (length col_ls))
		(if (and (plusp (car row_ls)) (plusp (car col_ls))) then
			(pin_num_ls = (list col_ls))
			(row_ls = (cdr row_ls))
			(first_num = (car col_ls))
			(last_num = (lastelem col_ls))
			(is_decrease = (equal (sub1 first_num) (car row_ls)))
			;;
			(foreach row row_ls
				(cur_col_ls = nil)
				(if is_decrease then
					(for i 1 col_length (cur_col_ls = (append1 cur_col_ls row--)))
				else
					(for i 1 col_length (cur_col_ls = (append1 cur_col_ls row++)))
				)
				(pin_num_ls = (append1 pin_num_ls cur_col_ls))
			)
		else
			(if (and (plusp (car row_ls)) (member (car col_ls) alpha_ls)) then
				(foreach row row_ls
					(cur_col_ls = (mapcar (lambda (c) (sprintf nil "%s%d" c row)) col_ls))
					(pin_num_ls = (append1 pin_num_ls cur_col_ls))
				)
			else
				(foreach row row_ls
					(cur_col_ls = (mapcar (lambda (c) (sprintf nil "%s%d" row c)) col_ls))
					(pin_num_ls = (append1 pin_num_ls cur_col_ls))
				)
			)
		)
		
		(return pin_num_ls)
	)
)

(procedure align_pin_bga(@optional padstack_name col_serial row_serial col_pitch row_pitch)
	;;; row_serial, col_serial: could be a,b,c,d,e or a-z or 50-1 or 1,2,3
	(prog (pad_id row_dis col_dis orient lu_xy curr_xy text)
		(unless (and (stringp padstack_name) (stringp padstack_name) (stringp padstack_name) (stringp padstack_name) (stringp padstack_name))
			(println "Please input all the arguments (padstack_name row_serial col_serial row_pitch col_pitch)")
			(printf pp_help)
			(return nil))
		;;
		(unless (pad_id = (axlLoadPadstack padstack_name)) (printf "No padstack has been found: %s\n" padstack_name) (printf pp_help) (return nil))
		(unless (plusp (row_pitch = (atof row_pitch))) (printf "Negative row_pitch: %f\n" row_pitch) (printf pp_help) (return nil))
		(unless (plusp (col_pitch = (atof col_pitch))) (printf "Negative col_pitch: %f\n" col_pitch) (printf pp_help) (return nil))
		;;
		
		(row_serial = (upperCase row_serial))
		(col_serial = (upperCase col_serial))
		;;
		(row_ls = (mapcan 'get_numbers (parseString row_serial ",")))
		(col_ls = (mapcan 'get_numbers (parseString col_serial ",")))
		
		;; get pin number list*list
		(pin_num_ls = (get_pin_num_matrix row_ls col_ls))
		
		;;
		(row_dis = (row_pitch * (sub1 (length row_ls))))
		(col_dis = (col_pitch * (sub1 (length col_ls))))
		(printf "Row Info: [%f] %L\n" row_dis row_ls)
		(printf "Col Info: [%f] %L\n" col_dis col_ls)
		(printf "Total Number of Pin:%d\n" ((length row_ls) * (length col_ls)))
			
		;; place pins
		(orient = (make_axlTextOrientation ?textBlock 1 ?rotation 0.0 ?mirrored nil ?justify "center"))
		(lu_xy = (list -(col_dis / 2) (row_dis / 2)))
		(foreach pns pin_num_ls
			(curr_xy = lu_xy)
			(foreach pn pns
				(text = (make_axlPinText ?number pn ?offset 0:0 ?text orient))
				(axlDBCreatePin pad_id curr_xy text)
				(curr_xy = (axlMXYAdd curr_xy (list col_pitch 0)))
			)
			(lu_xy = (axlMXYSub lu_xy (list 0 row_pitch)))
		)
	)
)

(procedure align_pin_qfp(ps_nm_hor ps_nm_ver side_num pitch edge @optional (cw 0))
	(prog (total_pin_num pn step edge_d2 hor_side_d2 ver_side_d2 orient curr_xy text)
		
		(unless (pad_hor_id = (axlLoadPadstack ps_nm_hor)) (printf "No padstack has been found: %s\n" padstack_name) (printf ppp_help) (return nil))
		(unless (pad_ver_id = (axlLoadPadstack ps_nm_ver)) (printf "No padstack has been found: %s\n" padstack_name) (printf ppp_help) (return nil))
		(unless (plusp (side_num = (atoi side_num))) (println "No side_num has been found") (printf ppp_help) (return nil))
		(unless (plusp (pitch = (atof pitch))) (println "No pitch has been found") (printf ppp_help) (return nil))
		(unless (plusp (edge = (atof edge))) (println "No edge has been found") (printf ppp_help) (return nil))
		(when (stringp cw) (cw = (atoi cw)))
		(unless (or (zerop cw) (onep cw)) (println "CW has to be 0/1") (printf ppp_help) (return nil))
		;;
		
		(total_pin_num = (side_num * 4))
		(if (zerop cw) then
			;;; counter clock-wise pin number
			(pn = 1)
			(step = 1)
		else
			;;; clock-wise pin number
			(pn = total_pin_num)
			(step = -1)
		)
		
		(edge_d2 = (edge / 2)) ;; half of edge to edge
		(side_d2 = ((pitch * (sub1 side_num)) / 2)) ;; half of side
		(orient = (make_axlTextOrientation ?textBlock 1 ?rotation 0.0 ?mirrored nil ?justify "center"))
		
		;;;; down side
		(curr_xy = (list -side_d2 -edge_d2))
		(for i 1 side_num
			(text = (make_axlPinText ?number (sprintf nil "%d" pn) ?offset 0:0 ?text orient))
			(axlDBCreatePin pad_hor_id curr_xy text)
			(pn = (pn + step))
			(curr_xy = (axlMXYAdd curr_xy (list pitch 0)))
		)
		
		;;;; right side
		(curr_xy = (list edge_d2 -side_d2))
		(for i 1 side_num
			(text = (make_axlPinText ?number (sprintf nil "%d" pn) ?offset 0:0 ?text orient))
			(axlDBCreatePin pad_ver_id curr_xy text)
			(pn = (pn + step))
			(curr_xy = (axlMXYAdd curr_xy (list 0 pitch)))
		)
		
		;;;; up side
		(curr_xy = (list side_d2 edge_d2))
		(for i 1 side_num
			(text = (make_axlPinText ?number (sprintf nil "%d" pn) ?offset 0:0 ?text orient))
			(axlDBCreatePin pad_hor_id curr_xy text)
			(pn = (pn + step))
			(curr_xy = (axlMXYAdd curr_xy (list -pitch 0)))
		)
		
		;;;; left side
		(curr_xy = (list -edge_d2 side_d2))
		(for i 1 side_num
			(text = (make_axlPinText ?number (sprintf nil "%d" pn) ?offset 0:0 ?text orient))
			(axlDBCreatePin pad_ver_id curr_xy text)
			(pn = (pn + step))
			(curr_xy = (axlMXYAdd curr_xy (list 0 -pitch)))
		)
		
		;; ppp smd10x22_ob smd22x10_ob 8 0.5 4.75
		(return t)
	)
)

(procedure get_perpheral_xy(center_xy radius number)
	(prog (step_angle angle y x xy xy_ls)
		(unless (dtpr center_xy) (println "ArgErr: get_perpheral_xy() - illegal center_xy") (return nil))
		(unless (and (plusp radius) (floatp radius)) (println "ArgErr: get_perpheral_xy() - Not positive float radius") (return nil))
		(unless (and (plusp number) (integerp number)) (println "ArgErr: get_perpheral_xy() - Not positive integer number of items") (return nil))
		;;
		
		(step_angle = (360.0 / number))
		(angle = (step_angle / 2))
		;;
		(for step 1 number
			(degree = (180.0 / angle))
			(y = (radius * (sin (axlPI / degree))))
			(x = (radius * (cos (axlPI / degree))))
			(xy = (axlMXYAdd center_xy (list x y)))
			(xy_ls = (append1 xy_ls xy))
			;;
			(angle = (angle + step_angle))
		)
		
		(return xy_ls)
	)
)

(procedure align_pin_circle(@optional ps_sd serial diameter)
	;;; ps_sd: this argument can be padstack name or circle shape diameter
	;;; (align_pin_circle <shape diameter> <number of shape> <ring diameter>)
	;;; (align_pin_circle <padstack name> <serial name of the padstack> <ring diameter>)
	(prog (sh_dia padstack_id layer center_xy radius number)
		(padstack_id = (axlLoadPadstack ps_sd))
		(unless padstack_id (sh_dia = (atof ps_sd)))
		(unless (or padstack_id sh_dia) (println "ArgErr: align_pin_circle() - ps_sd has to be padstack name or shape diameter") (return nil))
		(diameter = (atof diameter))
		(unless (plusp diameter) (println "ArgErr: align_pin_circle() - diameter has to be in float") (return nil))
		;;
		
		;;--------------------------------------------------------------------------------------
		(center_xy = 0:0)
		(radius = (diameter / 2))
		
		;;--------------------------------------------------------------------------------------
		(if (floatp sh_dia) then
			;;; this section is for circle shape
			(number = (atoi serial))
		else
			;;; this section is for padstack name
			(serial = (upperCase serial))
			(serial = (mapcan 'get_numbers (parseString serial ",")))
			(serial = (mapcar (lambda (x) (if (integerp x) (sprintf nil "%d" x) x)) serial))
			(number = (length serial))
		)
		(xy_ls = (get_perpheral_xy center_xy radius number))
		
		;;--------------------------------------------------------------------------------------
		(cond
			((floatp sh_dia)
				(layer = axlGetActiveLayer())
				(foreach xy xy_ls (create_circle 'shape xy sh_dia layer))
			)
			((stringp padstack_id->objType)
				(create_pins padstack_id xy_ls serial)
			)
			(t (println "align_pin_circle() - None of shape diameter or padstack name has been identified"))
		)
		
		(return t)
	)
)

(procedure get_shapes_by_name(ly_nm)
	(prog ()
		(unless (stringp ly_nm) (println "ArgErr: get_shapes_by_name() - ly_nm is not in string type") (return nil))
		(unless (axlIsLayer ly_nm) (printf "ArgErr: get_shapes_by_name() - [%s] is not a layer\n" ly_nm) (return nil))
		;;
		
		(sh_ls = (axlDBGetShapes ly_nm))
		
		(return sh_ls)
	)
)

(procedure set_dfa(@optional dfa_nm)
	(prog (cmd old_dfa_val dra_nm)
		(unless (or (get_shapes_by_name "PACKAGE GEOMETRY/DFA_BOUND_TOP") (get_shapes_by_name "PACKAGE GEOMETRY/DFA_BOUND_BOTTOM"))
			(println "set_dfa() - No DFA bound layer has been found")
			(return nil)
		)
		
		(old_dfa_val = (axlDBGetDesign()->prop->DFA_DEV_CLASS || "NONE"))
		;;
		(if (stringp dfa_nm) then
			(dra_nm = (strcat axlCurrentDesign() ".dra"))
			(work_dir = getWorkingDir())
			(dfa_nm = (upperCase dfa_nm))
			(sprintf cmd "dfa_update -f %s -d \"%s\" %s" dfa_nm work_dir dra_nm)
			(shell cmd)
			;;
			(printf "Updating DFA from [%s] to [%s]\n" old_dfa_val dfa_nm)
			(axlUIConfirm "DFA update information is showed in command window. Please reopen and check again")
		else
			(printf "DFA_DEV_CLASS: [%s]\n" old_dfa_val)
		)
	)
)

(procedure scissor_line()
	; seg_id = (car axlGetSelSet())
	(prog (box xy_1 xy_2 xy_3 xy_4 line4 seg_ls se layer width to_cut net_id net_nm seg_parent seg_prop)
		(unless axlOKToProceed() (println "Please finish current command first") (printf xl_help) (return nil))
		(axlSetFindFilter ?enabled (list "NOALL" "LINESEGS") ?onButtons (list "NOALL" "LINESEGS"))
		(println "Please select a box")
		(box = axlEnterBox())
		
		;;
		(unless (isBoxp box) (println "No box has been inputted") (return nil))
		(xy_1 = (car box))
		(xy_2 = (cadr box))
		(when (axlGeoPointsEqual xy_1 xy_2) (println "Please select 2 different point") (return nil))
		
		;;
		(xy_3 = (list (car xy_2) (cadr xy_1)))
		(xy_4 = (list (car xy_1) (cadr xy_2)))
		(line4 = (list (list xy_1 xy_3) (list xy_3 xy_2) (list xy_2 xy_4) (list xy_4 xy_1)))
		
		;;
		(axlSingleSelectBox box)
		(seg_ls = axlGetSelSet())
		
		;; remove the segment in the selected box
		(in_seg_ls = (mapcan (lambda (s) (when (forall p s->startEnd (axlIsPointInsideBox p box)) (list s))) seg_ls))
		(foreach seg_id in_seg_ls (axlDeleteObject seg_id))
		(seg_ls = (mapcan (lambda (s) (when (stringp s->objType) (list s))) seg_ls))
		
		;;
		(foreach seg_id seg_ls
			(to_cut = nil)
			(se = seg_id->startEnd)
			(xy_start = (car se))
			(xy_end = (cadr se))
			(layer = seg_id->layer)
			(width = seg_id->width)
			
			;; if box edge cut up the segment on the board
			(foreach line line4
				(a_b_dis = (axl_ol_ol2 se line))
				(when (zerop (caddr a_b_dis))
					(to_cut = t)
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
					(path = (axlPathStart (list xy_one)))
					(axlPathLine path width xy_mid)
					;;
					(printf "Create a seg from %L to %L\n" xy_one xy_mid)
					(new_path = (axlDBCreatePath path layer 'line))
				)
			)
			
			(when to_cut (axlDeleteObject seg_id))
		)
		
		
		(axlSetFindFilter ?enabled (list "NOALL") ?onButtons (list "NOALL"))
		axlClearSelSet()
		(return t)
	)
)

(procedure pin_add_shape(@optional (ext -1) (splited 0))
	(prog (mypopup pin_ls)
		(unless axlOKToProceed() (println "Please finish current command first") (printf ps_help) (return nil))
		(mypopup = (axlUIPopupDefine nil (list (list "Done" 'axlFinishEnterFun) (list "Cancel" 'axlCancelEnterFun))))
		(axlUIPopupSet mypopup)
		(println "Please select pins")
		(axlSetFindFilter ?enabled (list "NOALL" "PINS") ?onButtons (list "NOALL" "PINS"))
		
		;;
		(while axlSelect()
			(pin_ls = axlGetSelSet())
			(printf "%d pins have been selected\n" (length pin_ls))
		)
		
		;;
		(if (eqv -1 ext) then
			(ext = (if is_mils() 5.0 0.127))
		else
			(ext = (atof ext))
		)
		
		(xy_hv_ls = (mapcar (lambda (p) (list p->xy (get_pad_hv p 'top))) pin_ls))
		(layer = axlGetActiveLayer())
		(if (or (equal "0" splited) (zerop splited)) then
			(left_ls = (mapcar (lambda (ab) ((caar ab) - (caadr ab) / 2 - ext)) xy_hv_ls))
			(right_ls = (mapcar (lambda (ab) ((caar ab) + (caadr ab) / 2 + ext)) xy_hv_ls))
			(up_ls = (mapcar (lambda (ab) ((cadar ab) + (cadadr ab) / 2 + ext)) xy_hv_ls))
			(down_ls = (mapcar (lambda (ab) ((cadar ab) - (cadadr ab) / 2 - ext)) xy_hv_ls))
			
			;;
			(left_x = (car (sort left_ls 'lessp)))
			(down_y = (car (sort down_ls 'lessp)))
			(right_x = (car (sort right_ls 'greaterp)))
			(up_y = (car (sort up_ls 'greaterp)))
			
			;;
			(x = (right_x - left_x))
			(y = (up_y - down_y))
			(lu_xy = (list left_x up_y))
			(rd_xy = (list right_x down_y))
			(center_xy = (axlMidPointLine (list lu_xy rd_xy)))
			(create_rectangle 'shape center_xy x y layer)
		else
			(foreach xy_hv xy_hv_ls
				(xy = (car xy_hv))
				(hv = (cadr xy_hv))
				;;
				(x = ((car hv) + ext * 2))
				(y = ((cadr hv) + ext * 2))
				;;
				(create_rectangle 'shape xy x y layer)
			)
		)
	)
)

(procedure create_void_on_sh(main_sh_id xy hor ver ext)
	;;; create void on a shape id
	(prog (diameter location path result)
		(unless (equal "shape" main_sh_id->objType) (println "ArgErr: create_void_on_sh() - main_sh_id is not in shape type") (return nil))
		(unless (axlOK2Void main_sh_id->layer) (printf "Illegal to create void on shpae on layer [%s]\n" main_sh_id->layer) (return nil))
		(unless (dtpr xy) (println "ArgErr: create_void_on_sh() - xy is not in dtpr type") (return nil))
		(unless (plusp hor) (println "ArgErr: create_void_on_sh() - hor is not a positive number") (return nil))
		(unless (plusp ver) (println "ArgErr: create_void_on_sh() - ver is not a positive number") (return nil))
		(unless (numberp ext) (println "ArgErr: create_void_on_sh() - ext is not a number") (return nil))
		;;
		
		(hor = (hor + ext))
		(ver = (ver + ext))
		
		(if (axlGeoEqual hor ver) then
			;;; the void is in circle
			(diameter = (hor / 2))
			(location = (list xy diameter))
			(result = (axlDBCreateVoidCircle main_sh_id location))
		else
			;;; the void is in oblong
			(path = (create_oblong_path xy hor ver))
			(result = (axlDBCreateVoid main_sh_id path))
		)
		
		(return result)
	)
)

(procedure create_sl_util(type xy layer hor ver ext @optional prop)
	(prog (sh_id)
		(unless (and (dtpr xy) (stringp layer) (numberp hor) (numberp ver) (numberp ext)) (println "ArgErr: create_sl_util(0)") (return nil))
		(unless (exists x (list 'shape 'line) (eq x type)) (println "ArgErr: create_sl_util(1)") (return nil))
		;;
		
		;;
		(hor = (hor + ext))
		(ver = (ver + ext))
		
		;;
		(if (axlGeoEqual hor ver) then
			;; is circle
			(sh_id = (car (create_circle type xy hor layer)))
		else
			;; is oblong
			(sh_id = (car (create_oblong type xy hor ver layer)))
		)
		
		;;
		(when prop
			(sh_id = (car (axlDBAddProp sh_id (list prop))))
		)
		
		(return sh_id)
	)
)

(procedure create_shape_on_dip(pin_id)
	(prog (big_side prop_max prop_min pbb_layer stack_ext pin_def xy_offset xy plating hv pad_diameter ext)
		(unless (equal "pin" pin_id->objType) (println "ArgErr: create_shape_on_dip() - Not pin Arg") (return nil))
		;;
		
		(pbb_layer = "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
		(pkb_layer = "PACKAGE KEEPOUT/BOTTOM")
		(rka_layer = "ROUTE KEEPOUT/ALL")
		
		;;
		(pin_def = pin_id->definition)
		(xy_offset = pin_def->drillOffset)
		(xy = (axlMXYAdd pin_id->xy xy_offset))
		(plating = (pin_def->plating || "None")) ;; "PLATED" / 
		(prop_max = (list 'PACKAGE_HEIGHT_MAX "0.1 mil"))
		(prop_min = (list 'PACKAGE_HEIGHT_MIN "0.1 mil"))
		
		(case plating
			("PLATED"
				(hv = (get_pad_hv pin_id 'top))
				(hor = (car hv))
				(ver = (cadr hv))
				
				;; create plac bound bottom
				(sh_id = (create_sl_util 'shape xy pbb_layer hor ver 0 prop_max))
				
				;; create keep out bottom
				(ext = (if is_mils() 400.0 10.16))
				(big_side = (if (hor > ver) hor ver))
				(sh_id = (create_sl_util 'shape xy pkb_layer big_side big_side ext prop_min))
				
				(printf "PTH:[%s][%L] has been created\n" pin_id->number xy)
			)
			("NON_PLATED" ;; npth
				(hv = (get_drill_hv pin_id))
				(hor = (car hv))
				(ver = (cadr hv))
				
				;; create place bound bottom
				(sh_id = (create_sl_util 'shape xy pbb_layer hor ver 0 prop_max))
				
				;; create route keepout all
				(ext = (if is_mils() 24.0 0.6096))
				(sh_id = (create_sl_util 'shape xy rka_layer hor ver ext))
				
				;;; information
				(printf "NPTH:[%s][%L] has been created\n" pin_id->number xy)
			)
			(t (printf "Not support for plating [%s] on pin [%s]\n" plating pin_id->number))
		)
		
		(return t)
	)
)

(procedure add_dip_shape()
	(prog (mypopup pin_ls pin_def xy plating pad_id pad_box pad_hv pad_diameter sh_id)
		(unless axlOKToProceed() (println "Please finish current command first") (printf ds_help) (return nil))
		(mypopup = (axlUIPopupDefine nil (list (list "Done" 'axlFinishEnterFun) (list "Cancel" 'axlCancelEnterFun))))
		(axlUIPopupSet mypopup)
		(println "Please select a pth or npth")
		(axlSetFindFilter ?enabled (list "NOALL" "PINS") ?onButtons (list "NOALL" "PINS"))
		
		;;
		(while axlSelect()
			(pin_ls = (mapcan (lambda (p) (when p->isThrough (list p))) axlGetSelSet()))
			(printf "%d pth/npth have been selected\n" (length pin_ls))
		)
		
		;;
		(foreach pin_id pin_ls (create_shape_on_dip pin_id))
		
		(return t)
	)
)

(procedure get_pins_center()
	(prog (mypopup pin_ls xy)
		(unless axlOKToProceed() (println "Please finish current command first") (printf pxy_help) (return nil))
		(mypopup = (axlUIPopupDefine nil (list (list "Done" 'axlFinishEnterFun) (list "Cancel" 'axlCancelEnterFun))))
		(axlUIPopupSet mypopup)
		(println "Please select a pth or npth")
		(axlSetFindFilter ?enabled (list "NOALL" "PINS") ?onButtons (list "NOALL" "PINS"))
		
		;;
		(while axlSelect()
			(pin_ls = axlGetSelSet())
			(printf "%d pins have been selected\n" (length pin_ls))
		)
		(when (zerop (length pin_ls)) (println "Please select at least one pin") (return nil))
		
		;;
		(xy = 0:0)
		(foreach pin_id pin_ls (xy = (axlMXYAdd xy pin_id->xy)))
		
		;;
		(total = (length pin_ls))
		(xy = (list ((car xy) / total) ((cadr xy) / total)))
		
		(printf "The center of these pins is [ pick %f %f ]\n" (car xy) (cadr xy))
	)
)

(procedure shape_to_line()
	(prog (mypopup sh_ls layer path)
		(unless axlOKToProceed() (println "Please finish current command first") (printf sl_help) (return nil))
		(mypopup = (axlUIPopupDefine nil (list (list "Done" 'axlFinishEnterFun) (list "Cancel" 'axlCancelEnterFun))))
		(axlUIPopupSet mypopup)
		(println "Please select a shape")
		(axlSetFindFilter ?enabled (list "NOALL" "SHAPES") ?onButtons (list "NOALL" "SHAPES"))
		
		(while axlSelect()
			(sh_ls = axlGetSelSet())
			(printf "%d shapes have been selected\n" (length sh_ls))
		)
		
		(layer = axlGetActiveLayer())
		(foreach sh_id sh_ls
			(path = (axlDB2Path sh_id))
			(axlDBCreatePath path layer 'line)
		)
	)
)

(procedure create_pins(padstack_id xy_ls pin_num_ls)
	;;;
	(prog (text_ori pin_text pin_ls)
		(unless (and xy_ls pin_num_ls) (println "ArgErr: create_pins() - Either xy_ls or pin_num_ls is nil") (return nil))
		(unless (is_strings pin_num_ls) (println "ArgErr: create_pins() - pin_num_ls has to be string list") (return nil))
		(unless (equal "padstack" padstack_id->objType) (println "ArgErr: create_pins() - padstack_id is illegal") (return nil))
		;;
		
		(unless (dtpr (car xy_ls)) (xy_ls = (list xy_ls)))
		(unless (dtpr pin_num_ls) (pin_num_ls = (list pin_num_ls)))
		(unless (eqv (length xy_ls) (length pin_num_ls)) (printf "The number of xy_ls[%d] and pin_num_ls[%s] are different") (return nil))
		
		;;;
		(text_ori = (make_axlTextOrientation ?textBlock 1 ?rotation 0.0 ?justify "center"))
		(foreach (xy number) xy_ls pin_num_ls
			(pin_text = (make_axlPinText ?number number ?offset 0:0 ?text text_ori))
			(pin_id = (car (axlDBCreatePin padstack_id xy pin_text)))
			(pin_ls = (append1 pin_ls pin_id))
		)
		
		(return pin_ls)
	)
)

(procedure create_stdf(@optional pad_nm height)
	(prog (padstack_id center_xy stack_ext prop_max prop_min prop_h ext40 ext400 pin_id hv top_pad_hor top_pad_ver bot_pad_hor bot_pad_ver)
		(unless (is_strings pad_nm) (println "create_stdf() - Pad name has to be string") (return nil))
		(padstack_id = (axlLoadPadstack pad_nm))
		(unless padstack_id (println "create_stdf() - No pad has been found") (return nil))
		(height = (atof height))
		(unless (plusp height) (println "create_stdf() - Height has to be a positive non-zero number") (return nil))
		;;
		
		;;; general data
		(when is_mils() (height = (height * 39.37)))
		(center_xy = 0:0)
		(text_xy = (if is_mils() 0:-120.0 0:-3.048))
		(stack_ext = (if is_mils() 0.1 0.0025))
		(prop_max = (list 'PACKAGE_HEIGHT_MAX stack_ext))
		(prop_h = (list 'PACKAGE_HEIGHT_MAX height))
		(ext40 = (if is_mils() 40.0 1.0))
		(ext400 = (if is_mils() 400.0 10.16))
		
		;;; create pin
		(pin_id = (car (create_pins padstack_id center_xy "1")))
		(unless (equal "pin" pin_id->objType) (println "create_me_hole() - Fail to create pin") (return nil))
		
		;;; get top pad diameter
		(hv = (get_pad_hv pin_id 'top))
		(top_pad_hor = (car hv))
		(top_pad_ver = (cadr hv))
		
		;;; get bottom pad diameter
		(hv = (get_pad_hv pin_id 'bot))
		(bot_pad_hor = (car hv))
		(bot_pad_ver = (cadr hv))
		
		;;; create shape based on pad
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/PLACE_BOUND_TOP" top_pad_hor top_pad_ver 0 prop_h)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM" bot_pad_hor bot_pad_ver 0 prop_max)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/DFA_BOUND_TOP" top_pad_hor top_pad_ver 0)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/DFA_BOUND_BOTTOM" bot_pad_hor bot_pad_ver 0)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/PASTEMASK_TOP" top_pad_hor top_pad_ver 0)
		(create_sl_util 'shape center_xy "MANUFACTURING/NO_PROBE_TOP" top_pad_hor top_pad_ver ext40)
		(create_sl_util 'shape center_xy "MANUFACTURING/NO_PROBE_BOTTOM" bot_pad_hor bot_pad_ver ext40)
		
		;;; create text
		(set_text "STDF*" text_xy)
		
		
		(return t)
	)
)

(procedure create_me_hole(@optional pad_nm etch_hor etch_ver)
	;;; the pad diameter will be as same as etch_hor if etch_ver is nil and etch_hor is in number type
	;;; 	plus, etch/top and etch/bottom with void will be created
	(prog (center_xy keepout_ext stack_ext drill_ext text_xy prop_max prop_min padstack_id pin_id
			hv hor ver drill_hor drill_ver dia sh_id plating)
		(unless (is_strings pad_nm) (println "create_me_hole() - Pad name has to be string") (return nil))
		(padstack_id = (axlLoadPadstack pad_nm))
		(unless padstack_id (println "create_me_hole() - No pad has been found") (return nil))
		(unless (or (null etch_hor) (floatp (atof etch_hor))) (println "create_me_hole() - etch_hor has to be nil or a number") (return nil))
		(unless (or (null etch_ver) (floatp (atof etch_ver))) (println "create_me_hole() - etch_ver has to be nil or a number") (return nil))
		
		;;;;
		(when etch_hor (when (zerop (etch_hor = (atof etch_hor))) (etch_hor = nil)))
		(when etch_ver (when (zerop (etch_ver = (atof etch_ver))) (etch_ver = nil)))
		
		;;;; general definition
		(center_xy = 0:0)
		(stack_ext = (if is_mils() 0.1 0.0025))
		(keepout_ext = (if is_mils() 400.0 10.16))
		(drill_ext = (if is_mils() 24.0 0.6096))
		(text_xy = (if is_mils() 0:-120.0 0:-3.048))
		(prop_max = (list 'PACKAGE_HEIGHT_MAX stack_ext))
		(prop_min = (list 'PACKAGE_HEIGHT_MIN stack_ext))
		
		
		;;;; load pad by pad_nm
		(pin_id = (car (create_pins padstack_id center_xy "1")))
		(unless (equal "pin" pin_id->objType) (println "create_me_hole() - Fail to create pin") (return nil))
		
		;; get value from pin_id
		(hv = (get_drill_hv pin_id))
		(drill_hor = (car hv))
		(drill_ver = (cadr hv))
		
		(plating = pin_id->definition->plating)
		
		;;------------------------------------------------------------------------------------
		;;;; create 7 shapes
		(hv = (get_pad_hv pin_id 'top))
		(hor = pad_hor = (car hv))
		(ver = pad_ver = (cadr hv))
		
		(when (or etch_hor etch_ver)
			;;; if the pad region is not on pad but on the etch, then do this section
			(unless (and etch_hor etch_ver)
				(etch_ver = etch_hor)
			)
			;;; create shape on etch/top with void
			(sh_id = (create_sl_util 'shape center_xy "ETCH/TOP" etch_hor etch_ver 0))
			(sh_id = (create_void_on_sh sh_id center_xy pad_hor pad_ver drill_ext))
			;;; create shape on etch/bottom with void
			(sh_id = (create_sl_util 'shape center_xy "ETCH/BOTTOM" etch_hor etch_ver 0))
			(sh_id = (create_void_on_sh sh_id center_xy pad_hor pad_ver drill_ext))
			
			;;;
			(hor = etch_hor)
			(ver = etch_ver)
		)
		
		;;------------------------------------------------------------------------------------
		;;; create all the necessary shape alonging with pad
		(create_sl_util 'shape center_xy "PACKAGE KEEPOUT/TOP" hor ver keepout_ext prop_min)
		(create_sl_util 'shape center_xy "PACKAGE KEEPOUT/BOTTOM" hor ver keepout_ext prop_min)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/PLACE_BOUND_TOP" hor ver 0 prop_max)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM" hor ver 0 prop_max)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/DFA_BOUND_TOP" hor ver 0)
		(create_sl_util 'shape center_xy "PACKAGE GEOMETRY/DFA_BOUND_BOTTOM" hor ver 0)
		(create_sl_util 'shape center_xy "MANUFACTURING/NO_PROBE_TOP" hor ver 0)
		(create_sl_util 'shape center_xy "MANUFACTURING/NO_PROBE_BOTTOM" hor ver 0)
		(when (equal "NON_PLATED" plating)
			(create_sl_util 'shape center_xy "ROUTE KEEPOUT/ALL" hor ver drill_ext)
		)
		
		;;;; create reference
		(set_text "MH*" text_xy)
	)
)

(procedure create_oblong_flash(drill_height drill_width)
	(prog (tube_wid arc_tube_wid side_tube_wid sh_gap_min center_xy et_ly eb_ly long_dis short_dis h_d2 w_d2 side s_d2 in_dia in_rad out_dia out_rad)
		(unless axlOKToProceed() (println "Please done current command to use this function") (return nil))
		(drill_height = (float drill_height))
		(drill_width = (float drill_width))
		
		(tube_wid = 15.0)
		(arc_tube_wid = 15.0)
		(side_tube_wid = 25.0)
		(sh_gap_min = 5.0)
		(center_xy = 0:0)
		(et_ly = "ETCH/TOP")
		(eb_ly = "ETCH/BOTTOM")
		;;
		
		(if (drill_height > drill_width) then
			(long_dis = drill_height)
			(short_dis = drill_width)
		else
			(long_dis = drill_width)
			(short_dis = drill_height)
		)
		
		(h_d2 = (long_dis / 2))
		(w_d2 = (short_dis / 2))
		(side = (long_dis - short_dis))
		(s_d2 = (side / 2))
		
		(when (side_tube_wid > side)
			(printf "Drill Side has to be greater than %f\n" side_tube_wid)
			(side_tube_wid = (side - sh_gap_min))
			(when (side_tube_wid < sh_gap_min) (side_tube_wid = sh_gap_min))
		)
		
		(in_dia = short_dis)
		(in_rad = (in_dia / 2))
		(out_dia = (in_dia + tube_wid * 2))
		(out_rad = (out_dia / 2))
		
		(when (arc_tube_wid > in_dia)
			(printf "Drill Diameter has to be greatre than %f\n" in_dia)
			(arc_tube_wid = (in_dia - sh_gap_min))
			(when (arc_tube_wid < sh_gap_min) (arc_tube_wid = sh_gap_min))
		)
		
		
		;;
		(atw_d2 = (arc_tube_wid / 2))
		(stw_d2 = (side_tube_wid / 2))
		
		;;;; create left up slice
		(xy1 = (axlMXYAdd center_xy (list -w_d2 s_d2))) ;; inner upper point aside with arc
		(xy2 = (axlMXYAdd center_xy (list -w_d2 stw_d2))) ;; inner down point
		(xy3 = (axlMXYAdd xy2 (list -tube_wid 0))) ;; outer down point
		(xy4 = (axlMXYAdd xy1 (list -tube_wid 0))) ;; outer upper point aside with arc
		(ah = (sqrt (out_rad**2 - atw_d2**2))) ;; outer arc heigh
		(xy5 = (axlMXYAdd center_xy (list -atw_d2 (s_d2 + ah)))) ;; outer upper arc xy
		(ah = (sqrt (in_rad**2 - atw_d2**2))) ;; outer arc heigh
		(xy6 = (axlMXYAdd center_xy (list -atw_d2 (s_d2 + ah))))
		(arc_c_xy = (axlMXYAdd center_xy (list 0 s_d2)))
		;;
		(path = (axlPathStart (list xy1 xy2 xy3 xy4)))
		(axlPathArcCenter path 0 xy5 t arc_c_xy)
		(axlPathLine path 0 xy6)
		(axlPathArcCenter path 0 xy1 nil arc_c_xy)
		;;
		(sh1_id = (car axlDBCreateShape( path t et_ly)))
		
		;;;; create right up slice
		(sh2_id = (car axlDBCreateShape( path t eb_ly)))
		(axlTransformObject sh2_id ?mirror t ?origin center_xy)
		
		;;;; create right down slice
		(sh3_id = (car axlDBCreateShape( path t et_ly)))
		(axlTransformObject sh3_id ?angle 180.0 ?origin center_xy)
		
		;;;; create left down slice
		(sh4_id = (car axlDBCreateShape( path t eb_ly)))
		(axlTransformObject sh4_id ?angle 180.0 ?mirror t ?origin center_xy)
		
		
		;;;
		(when (drill_width > drill_height)
			(sh_ls = (list sh1_id sh2_id sh3_id sh4_id))
			(axlTransformObject sh_ls ?angle 90.0 ?origin center_xy)
		)
	
		(return t)
	)
)

(procedure create_circle_flash(drill_diameter)
	(prog (tube_wid center_xy tube_wid_half drill_radius out_radius out_distance in_distance out_down_xy in_down_xy out_up_xy in_up_xy path shape_id)
		(unless axlOKToProceed() (println "Please done current command to use this function") (return nil))
		(unless (numberp drill_diameter) (println "Please into drill diameter number") (return nil))
		(drill_diameter = (float drill_diameter))
		(tube_wid = 20.0) ;; default is 20
		(center_xy = 0:0)
		;;
		
		(tube_wid_half = (tube_wid / 2))
		(drill_radius = (drill_diameter / 2))
		
		;; get in distance
		(in_dis_exp2 = (drill_radius**2 - tube_wid_half**2))
		(in_distance = (if (plusp in_dis_exp2) (sqrt in_dis_exp2) 0.0))
		;;; in_distance has to be on the left of the inner_tube_node, otherwise, it will raise up comflict issue
		(while (and (in_distance < tube_wid_half) (plusp tube_wid))
			(tube_wid_half = (--tube_wid / 2))
			;;
			(in_dis_exp2 = (drill_radius**2 - tube_wid_half**2))
			(in_distance = (if (plusp in_dis_exp2) (sqrt in_dis_exp2) 0.0))
			(printf "Tube[%f], in_dis[%f]\n" tube_wid in_distance)
		)
		(when (minusp in_dis_exp2) (println "ArgErr: Fail to find a proprt tube width") (return nil))
		
		;;; get out distance
		(out_radius = (drill_radius + tube_wid))
		(out_distance = (sqrt (out_radius**2 - tube_wid_half**2)))
		

		;;;; create up side lip
		(out_down_xy = (list -out_distance tube_wid_half))
		(in_down_xy = (list -in_distance tube_wid_half))
		(out_up_xy = (list -tube_wid_half out_distance))
		(in_up_xy = (list -tube_wid_half in_distance))
		
		;;;; create top lip path
		(path = (axlPathStart (list out_up_xy in_up_xy)))
		(axlPathArcCenter path 0 in_down_xy nil center_xy)
		(axlPathLine path 0 out_down_xy)
		(axlPathArcCenter path 0 out_up_xy t center_xy)
		
		;;;; create left lip
		(shape_id = axlDBCreateShape( path t "ETCH/TOP"))
		(axlTransformObject shape_id ?angle 45.0 ?origin center_xy)
		
		
		;;;; create down
		(shape_id = axlDBCreateShape( path t "ETCH/TOP"))
		(axlTransformObject shape_id ?angle 135.0 ?origin center_xy)
		
		;;;; create right
		(shape_id = axlDBCreateShape( path t "ETCH/TOP"))
		(axlTransformObject shape_id ?angle 225.0 ?origin center_xy)
		
		;;;; create up
		(shape_id = axlDBCreateShape( path t "ETCH/TOP"))
		(axlTransformObject shape_id ?angle 315.0 ?origin center_xy)
		
		
		(return t)
	)
)

(procedure create_flash(@optional drill_width drill_height)
	;;; when drill_width is equal to drill_height, then the flash will be regard as a circle whose name is T<drill_width>
	;;; when drill_width is not equal to drill_height, then the flash will be regard as a oblong whose name is T<drill_width><drill_height>
	(prog ()
		(unless (or drill_width drill_height) (println "ArgErr: Please enter at least one number to use this function") (return nil))
		(when (stringp drill_width) (drill_width = (atof drill_width)))
		(when (stringp drill_height) (drill_height = (atof drill_height)))
		(unless (or (floatp drill_width) (floatp drill_height)) (println "ArgErr: Please input number to trigger this function") (return nil))
		;;
		
		;;; change unit to mils
		(axlDBChangeDesignUnits "mils" 4)
		(println "Change unit to mil and change the accuracy to 4")
		
		;;; check whether is oblong or circle
		(when (and (floatp drill_width) (floatp drill_height))
			(when (axlGeoEqual drill_width drill_height) (drill_height = nil))
		)
		
		;;
		(cond
			((and (floatp drill_width) (null drill_height))
				;;; to create a circle flash
				(create_circle_flash drill_width)
			)
			((and (floatp drill_width) (floatp drill_height))
				;;; to create a oblong flash
				(create_oblong_flash drill_height drill_width)
			)
			(t
				(println "create_flash() - Fail to create flash")
				(return nil)
			)
		)
		
		(return t)
	)
)

(procedure get_xml_sections_from_file(element file_addr)
	(prog (in_port header tailer start_getting sect_ls)
		(unless (stringp element) (println "ArgErr: get_xml_section_from_file() - element is not a string") (return nil))
		(unless (isFile file_addr) (println "ArgErr: get_xml_section_from_file() - file_addr is not a file") (return nil))
		(unless (inportp (in_port = (infile file_addr))) (println "Error: get_xml_section_from_file() - fail to read file") (return nil))
		;;
		
		; file_addr = "D:/Footprint_Check/self_create/351_derek/ic_sdram-ddr4_78p_mt40a1g8.xml"
		(sprintf header "<%s>" element)
		(sprintf tailer "</%s>" element)
		(stack_line = "")
		(while (stringp (gets line in_port))
			(when (and start_getting (index line tailer))
				(line = (strcat "<" (car (parseString (cadr (parseString line "<")) ">")) ">"))
				(stack_line = (strcat stack_line line))
				;;
				(sect_ls = (append1 sect_ls stack_line))
				(stack_line = "")
				(start_getting = nil)
			)
			(when start_getting
				(line = (strcat "<" (car (parseString (cadr (parseString line "<")) ">")) ">"))
				(stack_line = (strcat stack_line line))
			)
			(when (and (null start_getting) (index line header))
				(line = (strcat "<" (car (parseString (cadr (parseString line "<")) ">")) ">"))
				(stack_line = line)
				(start_getting = t)
			)
		)
		
		(close in_port)
		
		(return sect_ls)
	)
)

(procedure get_xml_content(section element)
	;;; the format of the xml:
	;;;		section: <element>content<element/>
	(prog (sect_ls content)
		(unless (stringp section) (println "ArgErr: get_xml_content() - section is not a string") (return nil))
		(unless (stringp element) (println "ArgErr: get_xml_content() - element is not a string") (return nil))
		(unless (index section element) (println "ArgErr: get_xml_content() - element is not in section") (return nil))
		(unless (((strlen element) * 2) < (strlen section)) (println "ArgErr: get_xml_content() - length of section has to be larger than elements twice") (return nil))
		;;
		
		;;; get the content between 2 element
		(sect_ls = (parseString section "<>"))
		(sect_ls = (cdr (exists x sect_ls (index x element))))
		(sect_ls = (reverse (cdr (exists x (reverse sect_ls) (index x element)))))
		(content = (strcat "<" (buildString sect_ls "><") ">"))
		
		(return content)
	)
)

(procedure get_xml_attribute(section key)
	(prog (pattern val)
		(unless (stringp section) (println "ArgErr: get_xml_attribute() - section is not a string") (return nil))
		(unless (stringp key) (println "ArgErr: get_xml_attribute() - key is not a string") (return nil))
		(unless (index section key) (println "ArgErr: get_xml_attribute() - key is not in section") (return nil))
		;;
		
		(sprintf pattern "%s=\"\\([A-Za-z0-9_-]*\\)\" " key)
		(rexCompile pattern)
		(when (rexExecute section) (val = (rexSubstitute "\\1")))
		
		(return val)
	)
)



(procedure compare_pin_number()
	;;; compare the pin number in olb expoted xml and the pin inside the current pin
	(prog (element file_addr key content_ls sect_ls xml_pn_ls dra_pn_ls mis_xml_ls mis_dra_ls dra1 xml1 total result)
		;;; general information
		
		println( "Usage:")
		println( "	1.	Setup footprint_create_cmd.ile")
		println( "	2.	Get XML by [File>export>Library XML] in Capture-CIS 17.2")
		println( "	3.	Open the desired dra file either in 16.6 or 17.2")
		println( "	4.	Enter 'cpn' in command window")
		println( "	5.	Select the XML created at step 2")
		println( "	6.	The result will be shown on the popup and the command window")
		
		(element = "PinNumber")
		(key = "number")
		
		;;; get all pin in current dra
		(dra_pn_ls = axlDBGetDesign()->pins~>number)
		(dra_pn_ls = (sort dra_pn_ls 'alphalessp))
		(unless (dtpr dra_pn_ls) (println "ERROR: compare_pin_number() - Fail to find the pin on DRA") (return nil))
		
		;;; ask user to import xml
		(file_addr = (axlDMFileBrowse "ALLEGRO_XML" nil ?title "Please select a xml exported from an OLB"))
		(unless (stringp file_addr) (println "Please select a xml file to use the function") (return nil))
		(sect_ls = (get_xml_sections_from_file element file_addr))
		(content_ls = (mapcar (lambda (x) (get_xml_content x element)) sect_ls))
		(xml_pn_ls = (mapcar (lambda (x) (get_xml_attribute x key)) content_ls))
		(xml_pn_ls = (sort xml_pn_ls 'alphalessp))
		(unless (dtpr xml_pn_ls) (println "ERROR: compare_pin_number() - Fail to find the pin in xml") (return nil))
		
		;;; compare and report
		(total = (length xml_pn_ls))
		(when (eqv (length xml_pn_ls) (length dra_pn_ls))
			(result_ls = (mapcar (lambda (x y) (equal x y)) dra_pn_ls xml_pn_ls))
			(result = (forall x result_ls x))
		)
		
		(unless result
			(while (or (dtpr dra_pn_ls) (dtpr xml_pn_ls))
				;;; get the first element to check. dont care nil or not
				(dra1 = (car dra_pn_ls))
				(xml1 = (car xml_pn_ls))
				
				;;; after sorting. pin number sequence in order
				;;; skip fetching part if first elements are the same
				(unless (equal dra1 xml1)
					(if (member dra1 xml_pn_ls) then
						(xml_pn_ls = (remove dra1 xml_pn_ls))
					else
						(when (stringp dra1) (mis_xml_ls = (append1 mis_xml_ls dra1)))
					)
					(if (member xml1 dra_pn_ls) then
						(dra_pn_ls = (remove xml1 dra_pn_ls))
					else
						(when (stringp xml1) (mis_dra_ls = (append1 mis_dra_ls xml1)))
					)
				)
				
				;;; step to the next element
				(dra_pn_ls = (cdr dra_pn_ls))
				(xml_pn_ls = (cdr xml_pn_ls))
			)
		)
		
		(if result then
			(sprintf msg "Pass. The pin number in footprint is as same as in symbol. Total number of pin: [%d]" total)
			(axlUIConfirm msg)
			(println msg)
		else
			(axlUIConfirm "Mismatch: please check the message in command window. The process halt")
			(printf "\tMissing pin number in footprint: %L\n" mis_dra_ls)
			(printf "\tMissing pin number in symbol: %L\n" mis_xml_ls)
		)
		
		(return t)
	)
)

(procedure shape_to_append( @optional (ext 0))
	prog( ()
		(unless axlOKToProceed() (println "Please finish current command first") (printf pa_help) (return nil))
		(mypopup = (axlUIPopupDefine nil (list (list "Done" 'axlFinishEnterFun) (list "Cancel" 'axlCancelEnterFun))))
		(axlUIPopupSet mypopup)
		(println "Please select shape")
		(axlSetFindFilter ?enabled (list "NOALL" "SHAPES") ?onButtons (list "NOALL" "SHAPES"))
		
		;;
		while( axlSelect()
			shape_ls = axlGetSelSet()
			(printf "%d shapes have been selected\n" (length shape_ls))
		)
		
		;; deal with ext
		when( stringp( ext) (ext = atof( ext)))
		when( eqv( 0 ext)
			if( equal( "mil" axlDBGetDesignUnits())
				ext = 2.0
				ext = 0.0508
			)
		)
		
		;;;;; create shape one by one
		layer = axlGetActiveLayer()
		foreach( shape_id shape_ls
			poly_id = axlPolyFromDB( shape_id)
			poly_id = car( axlPolyExpand( poly_id ext 'NONE))
			result = axlDBCreateShape( poly_id t layer)
		)
	)
)

(procedure help_derek(@optional (show 1))
	(setq cmd_form "Command: %s\n\tForm: %s\n\tDescription: %s\n")
	
	(sprintf pin1_help cmd_form "pin1" "pin1" "Draw pin1 at 0:0 on [Package Geometry/SILKSCREEN_TOP] with line_wid:6 mils")

	(setq pp_des (buildString '("To place pins like GBA, the serial of pin number starts from up left"
								"padstack_name: The name of the pad"
								"col_serial: pin number in column. <a>-<b> defines the continuous number or letter. , to split words"
								"row_serial: pin number in row. <a>-<b> defines the continuous number or letter. , to split words"
								"col_pitch: The pitch for each 2 pins in vertical"
								"row_pitch: The pitch for each 2 pins in horizontal"
								"example: pp smd10x10 1-3,5 E-C,B 0.9 1.3") "\n\t\t"))
	(sprintf pp_help cmd_form "pp" "pp <padstack_name> <col_serial> <row_serial> <col_pitch> <row_pitch>" pp_des)
	
	(setq ppp_des (buildString '("To place pins like QFP"
								"\tps_nm_hor: Pad name in horizontal"
								"\tps_nm_ver: Pad name in vertical"
								"\tside_num: The number of pin for each side"
								"\tpitch: The pitch for each 2 pins"
								"\tedge: The distance between a pin and its opposite one"
								"\tclockwise: The pin number serial is eithe in cw[1] or ccw[0]. Default is ccw"
								"\texample: ppp smd10x12 smd12x10 5 0.65 4.8 1" ) "\n\t\t"))
	(sprintf ppp_help cmd_form "ppp" "ppp <ps_nm_hor> <ps_nm_ver> <side_num> <pitch> <edge> [<clockwise>]" ppp_des)
	
	;;;;;
	(setq pppp_des (buildString '("To place multiple pins or shapes in circularity"
								"\tpppp <circle shape diameter> <number of shape> <diameter of ring>: Create multiple circle in shape on active layer"
								"\tpppp <pad name> <pin number serial> <diameter of ring>: Place multiple pads") "\n\t\t"))
	(sprintf pppp_help cmd_form "pppp" "pppp <object> <serial> <diameter>" pppp_des)
	
	(sprintf apn_help cmd_form "apn" "apn" "Active layer to [PACKAGE GEOMETRY/PIN_NUMBER]")
	(sprintf ast_help cmd_form "ast" "ast" "Active layer to [PACKAGE GEOMETRY/SILKSCREEN_TOP]")
	(sprintf apt_help cmd_form "apt" "apt" "Active layer to [PACKAGE GEOMETRY/PLACE_BOUND_TOP]")
	(sprintf apb_help cmd_form "apb" "apb" "Active layer to [PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM]")
	(sprintf adt_help cmd_form "adt" "adt" "Active layer to [PACKAGE GEOMETRY/DFA_BOUND_TOP]")
	(sprintf aat_help cmd_form "aat" "aat" "Active layer to [PACKAGE GEOMETRY/ASSEMBLY_TOP]")
	(sprintf ant_help cmd_form "ant" "ant" "Active layer to [MANUFACTURING/NO_PROBE_TOP]")
	(sprintf akb_help cmd_form "akb" "akb" "Active layer to [PACKAGE KEEPOUT/BOTTOM]")
	
	(setq gg_des (buildString '("To view or edit grid"
								"\tgg: Show current grid and unit information"
								"\tgg <x> <y>: change the grid x and y") "\n\t\t"))
	(sprintf gg_help cmd_form "gg" "gg [<grid_x>] [<grid_y>]" gg_des)
	
	(setq ll_des (buildString '("To create a [rectangle/oblong/circle] line on active layer with line_wid: 0"
								"\tll: If you used the ll or ss before, it can copy the old value. Otherwise, nothing will be activated"
								"\tll <side>: Create a square"
								"\tll <diameter> 0: Create a circle"
								"\tll <x> <y>: Create a rectangle x by y"
								"\tll <-x> <y>: Create a oblong x by y") "\n\t\t"))
	(sprintf ll_help cmd_form "ll" "ll [<x>] [<y>]" ll_des)
	
	(setq ss_des (buildString '("To create a [rectangle/oblong/circle] shape on active layer"
								"\tss: If you used the ll or ss before, it can copy the old value. Otherwise, nothing will be activated"
								"\tss <side>: Create a square"
								"\tss <diameter> 0: Create a circle"
								"\tss <x> <y>: Create a rectangle x by y"
								"\tss <-x> <y>: Create an oblong x by y") "\n\t\t"))
	(sprintf ss_help cmd_form "ss" "ss [<x>] [<y>]" ss_des)
	
	(sprintf tt_help cmd_form "tt" "tt <text>" "To create text at 0:0 on [COMPONENT VALUE/DISPLAY_TOP] [REF DES/SILKSCREEN_TOP] [REF DES/ASSEMBLY_TOP]")
	
	(setq xx_des (buildString '("To shift the next pick vertically and horizontally"
								"x and y: the current coordination"
								"nx and ny: the delta to the next coordination"
								"xx x y nx ny: At the beginning, use this command to setup"
								"xx: After setting up, use this command to pick the next coordination") "\n\t\t"))
	(sprintf xx_help cmd_form "xx" "xx <x> <y> <nx> <ny>" xx_des)
	
	(sprintf gm_help cmd_form "gm" "gm" "Change unit to mm")
	
	(sprintf gl_help cmd_form "gl" "gl" "Change unit to mils")
	
	(setq dfa_des (buildString '("View the DFA group while no argument is inputed"
								"\tEnter one argument as the DFA group. You can see the update after re-opening") "\n\t\t"))
	(sprintf dfa_help cmd_form "dfa" "dfa [<dfa group>]" dfa_des)
	
	(sprintf ds_help cmd_form "ds" "ds" "Add shapes by Flex rule on PTH or NPTH")
	
	(sprintf xl_help cmd_form "xl" "xl" "Cut all visible line in box")
	
	(sprintf sl_help cmd_form "sl" "sl" "Create a line by a shape on active layer with line_wid: 0")
	
	(sprintf sa_help cmd_form "sa" "sa" "Append selected shape. Default is 2 mil")
	
	(setq ii_des (buildString '("To view the board by following options. Default is 1"
								"\tii 0: Hide everything"
								"\tii 1: Show everything"
								"\tii 2: Show active layer if it were hided currently. Vice versa"
								"\tii 3: Show active layer and hide the rest if the active layer were hided currently. Vice verse") "\n\t\t"))
	(sprintf ii_help cmd_form "ii" "ii [<opt>]" ii_des)
	
	(setq ps_des (buildString '("To create rectangle actived shape(s) on selected pins"
								"ps: To create single shape from top-left pins to left-down pin with 5 extension"
								"<extension>: define the extension from pin(s)"
								"<splite>: 0 to create single shape. 1 to create multiple shapes by pin"
								"example: ps 15 0") "\n\t\t"))
	(sprintf ps_help cmd_form "ps" "ps <extension> <splite>" ps_des)
	
	(sprintf pxy_help cmd_form "pxy" "pxy" "Get the center coordination of selected pins")
	
	(setq meh_des (buildString '("To create mechanical hole, the editor has to be symbol editor"
								"meh <pad_nm>: it is normally used to create pth me-hole"
								"\tthe area from drill hole to pad edge should be defined in pin"
								"meh <pad_nm> <etch_hor> <etch_ver>: it is normally used to create npth me-hole"
								"\tetch_hor and etch_ver are used to create etch/top(bottom) with 24 extension void") "\n\t\t"))
	(sprintf meh_help cmd_form "meh" "meh <pad_nm> [<etch_hor> <etch_ver>]" meh_des)
	
	(sprintf stdf_help cmd_form "stdf" "stdf <pad_nm> <height>" "To create stand-off by this pad name and height")
	
	(setq fla_des (buildString '("This command is used to create flash in mils. Please open it in aflash editor"
								"fla <drill_diameter>: Create a circle flash."
								"\tDefault tube width is 20. Go down if the tube width were too large"
								"fla <drill_width> <drill_height>: Create a oblong flash."
								"\tDefault tube width on arc is 15. The tube width would become 5 if the tube width is too large"
								"\tDefault tube width on side is 25. The tube width would become 5 if the tube width is too large") "\n\t\t"))
	(sprintf fla_help cmd_form "fla" "fla <drill_width> <drill_height>" fla_des)
	
	(sprintf cpn_help cmd_form "cpn" "cpn" "To compare the pin number in dra and the pin number in xml, exported from OLB")
	
	;;
	(when (zerop show)
		(printf apn_help)
		(printf ast_help)
		(printf apt_help)
		(printf apb_help)
		(printf adt_help)
		(printf aat_help)
		(printf ant_help)
		(printf akb_help)
		(printf pin1_help)
		(printf pp_help)
		(printf ppp_help)
		(printf pppp_help)
		(printf ss_help)
		(printf gg_help)
		(printf ll_help)
		(printf tt_help)
		(printf xx_help)
		(printf gm_help)
		(printf gl_help)
		(printf dfa_help)
		(printf ds_help)
		(printf xl_help)
		(printf sl_help)
		(printf ii_help)
		(printf ps_help)
		(printf pxy_help)
		(printf fla_help)
		(printf meh_help)
		(printf stdf_help)
		(printf cpn_help)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(axlCmdRegister "pp" 'align_pin_bga)
(axlCmdRegister "ppp" 'align_pin_qfp)
(axlCmdRegister "pppp" 'align_pin_circle)
(axlCmdRegister "apn" 'active_pin_num)
(axlCmdRegister "ast" 'active_silk_top)
(axlCmdRegister "apt" 'active_place_top)
(axlCmdRegister "apb" 'active_place_bot)
(axlCmdRegister "adt" 'active_dfa_top)
(axlCmdRegister "aat" 'active_assem_top)
(axlCmdRegister "ant" 'active_prob_top)
(axlCmdRegister "akb" 'active_pk_bot) ;; active package keepout/bottom
(axlCmdRegister "akt" 'active_pk_top) ;; active package keepout/bottom
(axlCmdRegister "att" 'active_past_top)
(axlCmdRegister "atb" 'active_past_bot)
(axlCmdRegister "ara" 'active_route_keepout_all)
(axlCmdRegister "gg" 'set_grid)
(axlCmdRegister "ll" 'set_line)
(axlCmdRegister "ss" 'set_shape)
(axlCmdRegister "tt" 'set_text)
(axlCmdRegister "xx" 'set_pick)
(axlCmdRegister "gm" 'to_mm)
(axlCmdRegister "gl" 'to_mils)
(axlCmdRegister "dfa" 'set_dfa)
(axlCmdRegister "ds" 'add_dip_shape)
(axlCmdRegister "xl" 'scissor_line)
(axlCmdRegister "sl" 'shape_to_line)
(axlCmdRegister "ls" 'line_to_shape)
(axlCmdRegister "sa" 'shape_to_append)
(axlCmdRegister "ii" 'set_view)
(axlCmdRegister "ps" 'pin_add_shape)
(axlCmdRegister "pxy" 'get_pins_center)
(axlCmdRegister "meh" 'create_me_hole)
(axlCmdRegister "stdf" 'create_stdf)
(axlCmdRegister "fla" 'create_flash)
(axlCmdRegister "cpn" 'compare_pin_number)
(axlCmdRegister "hh" 'help_derek)
(help_derek 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function key (in cmd)

(axlSetFunckey "t" "toggle" t)

;(axlSetFunckey "s" "setwindow form.find;FORM find shapes YES" t)
;(axlSetFunckey "t" "setwindow form.find;FORM find text YES" t)
;(axlSetFunckey "p" "setwindow form.find;FORM find pins YES" t)
;(axlSetFunckey "l" "setwindow form.find;FORM find lines YES" t)
;(axlSetFunckey "o" "setwindow form.find;FORM find other_segs YES" t)
;(axlSetFunckey "a" "setwindow form.find;FORM find all_on" t)
;(axlSetFunckey "f" "setwindow form.find;FORM find all_off" t)

;(axlSetFunckey "cp" "setwindow form.mini;FORM mini class PACKAGE GEOMETRY" t)
;(axlSetFunckey "cm" "setwindow form.mini;FORM mini class MANUFACTURING" t)
;(axlSetFunckey "cn" "setwindow form.mini;FORM mini subclass NO_PROBE_TOP" t)
;(axlSetFunckey "cd" "setwindow form.mini;FORM mini subclass DFA_BOUND_TOP" t)
;(axlSetFunckey "ca" "setwindow form.mini;FORM mini subclass ASSEMBLY_TOP" t)
;(axlSetFunckey "cs" "setwindow form.mini;FORM mini subclass SILKSCREEN_TOP" t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; alias (general)

(axlSetAlias "z" "zcopy shape")
(axlSetAlias "ep" "property edit")
(axlSetAlias "g" "grid toggle")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (setSkillPath (buildString (append1 getSkillPath()  "C:/skill")))

; skill (encrypt "c:/skill/footprint_create_cmd.il" "c:/skill/footprint_create_cmd.ile")
; (load "footprint_create_cmd.ile")
; (load "footprint_create_cmd.il")









