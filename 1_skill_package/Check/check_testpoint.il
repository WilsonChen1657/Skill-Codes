;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction

; Developer: Derek Hsu
; starting date: 2/12/2019 - _Derek02122019
; Description
;		1. Check all loaded via fitting the rule of item 29 of gerber out checklist 
;			1. 10 mils FHS vias are used for the All thru Test point and solder mask opening on the both side 
;			2. Test point side : solder mask opening size = Pad size + 4 mil
;			3. Opposite side : solder mask opening size = Drill size + 6 mil
;		2. setup the testpoint
;			1. Via (drill hole diameter:8 pad diameter:18) -> TOP: "TP18_8TMP30NP", BOTTOM: "TP18_8BMP30NP"
;			2. Via (drill hole diameter:10 pad diameter:20) -> TOP: "TP20_10TMP30NP", BOTTOM: "TP20_10BMP30NP"
;			3. Check "Replace vias"
;			Hint: Only operate loaded via type
;		3. Output Result
;			1. "Pass the examination" ==> Everything is okay
;			2. "[Drill Size: %.2f] has to be smaller than [%.2f]" ==> drill diameter has to be <= 10
;			3. "[Pad size: %.2f] has to be greater than [%.2f]" ==> testpoint layer's pad size has to be >= 30
;			4. "[Certain Soldermask: %s, %.2f] has to be [Pad Size: %.2f] + [%2.f]" ==> certain soldermask layer: soldermask open size = pad + 4
;			5. "[Opposite Soldermask: %s, Dia: %.2f] has to be [Pad Size: %.2f] + [%.2f]" ==> opposite soldermask layer: soldermask open size = drill + 6
;			PS: Only check used via types on the board

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

(defun init_Derek02122019 ()
	(setq etch_top "ETCH/TOP")
	(setq etch_bot "ETCH/BOTTOM")
	(setq psm_top "SOLDERMASK_TOP")
	(setq psm_bot "SOLDERMASK_BOTTOM")
	;;
	(setq tp_prm_nm "testprep.prm")
	;;
	(setq finish_hole_max 10.0)
	(setq tp_pad_min_dia 30.0)
	(setq certain_sm_pad_ext 4.0) ;; the soldermask size on the testpoint side has to be pad size +2+2
	(setq opposite_sm_drill_ext 6.0) ;; the soldermask size on the testpoint side has to be pad size +3+3
)

(procedure get_pad_diameter_Derek02122019(obj_id)
	;;; only deal with pin/padstack/via, the layer will always etch/top
	;;; the type of the obj_id must be circle, otherwise, nil
	(prog (pad_id pad_ls pad_box diameter)
		(unless (or (is_vias_Derek02122019 obj_id) (is_pins_Derek02122019 obj_id)) (println "[POOL] get_pad_diameter() - Arg has to be pin/via/padstack") (return nil))
		;;
		
		(pad_ls = obj_id->pads)
		(pad_id = (car (setof p pad_ls (and (equal "ETCH/TOP" p->layer) (equal "REGULAR" p->type) (equal "CIRCLE" p->figureName)))))
		
		(when pad_id
			(pad_box = pad_id->bBox)
			(diameter = (abs ((caar pad_box) - (caadr pad_box))))
		)
		
		(return diameter)
	)
)

(procedure get_drill_diameter_Derek02122019(obj_id)
	;; only deal with pad/padstack/via, otherwise, nil
	;; return diameter, otherwise. nil
	(prog (diameter)
		(unless (or (is_vias_Derek02122019 obj_id) (is_pins_Derek02122019 obj_id)) (println "[POOL] get_drill_diameter() - Arg has to be pin/via/padstack") (return nil))
		;;
		
		(drl_def = obj_id->definition)
		(hole_type = drl_def->holeType)
		(when (equal "circle_drill" hole_type) (diameter = drl_def->drillDiameter))
		
		(return diameter)
	)
)

(procedure is_vias_Derek02122019(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (forall x obj_ls (equal "via" x->objType)))
		
		(return result)
	)
)

(procedure is_pins_Derek02122019(obj_ls)
	(prog (result)
		(unless (dtpr obj_ls) (obj_ls = (list obj_ls)))
		(result = (forall x obj_ls (member x->objType '("pin" "padstack"))))
		
		(return result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

(procedure check_tp_thru_via_Derek02122019(tp_thru_via_ls)
	;;; this function is based on item 29 at the layout checklist
	;;		10mils FHS vias are used for the All thru Test point and solder mask opening on the both side 
	;;		test point side : solder mask opening size = Pad size + 4 mil
	;;		opposite side : solder mask opening size = Drill size + 6 mil  
	(prog (info_ls tp_pad_dia tp_layer pad_ls soldermask_ly oppo_soldermask_ly drill_dia pad_id box result)
		(unless (dtpr tp_thru_via_ls) (return nil))
		(unless (forall v tp_thru_via_ls (and v->isThrough (equal "via" v->objType))) (println "ArgErr: check_tp_thru_via(0)") (return nil))
		;;
		
		(foreach via_id tp_thru_via_ls
			(info_ls = tp_pad_dia = nil)
			(tp_layer = via_id->testPoint)
			(pad_ls = via_id->pads)
			(soldermask_ly = (if (equal etch_top tp_layer) psm_top psm_bot))
			(oppo_soldermask_ly = (if (equal psm_top soldermask_ly) psm_bot psm_top))
			(drill_dia = (get_drill_diameter_Derek02122019 via_id))
			
			
			;;; drill diameter has to be <= 10
			(when (drill_dia > finish_hole_max)
				(sprintf info "[Drill Size: %.2f] has to be smaller than [%.2f]" drill_dia finish_hole_max)
				(info_ls = (append1 info_ls info))
			)
			
			
			;;; tp_layer: top/bottom's pad size has to be >=30
			(pad_id = (car (setof p pad_ls (and (equal tp_layer p->layer) (equal "REGULAR" p->type)))))
			(box = pad_id->bBox)
			(tp_pad_dia = (abs ((caar box) - (caadr box))))
			(when (tp_pad_dia < tp_pad_min_dia)
				(sprintf info "[Pad size: %.2f] has to be greater than [%.2f]" tp_pad_dia tp_pad_min_dia)
				(info_ls = (append1 info_ls info))
			)
			
			
			;;; certain soldermask layer: soldermask open size = pad + 4
			(when (numberp tp_pad_dia)
				(pad_id = (car (setof p pad_ls (and (index p->layer soldermask_ly) (equal "REGULAR" p->type)))))
				(box = pad_id->bBox)
				(tp_sm_pad_dia = (abs ((caar box) - (caadr box))))
				(unless (axlGeoEqual (tp_pad_dia + certain_sm_pad_ext) tp_sm_pad_dia)
					(sprintf info "[Certain Soldermask: %s, %.2f] has to be [Pad Size: %.2f] + [%2.f]"
						soldermask_ly tp_sm_pad_dia tp_pad_dia certain_sm_pad_ext)
					(info_ls = (append1 info_ls info))
				)
			)
			
			
			;;; opposite soldermask layer: soldermask open size = drill + 6
			(when (numberp drill_dia)
				(pad_id = (car (setof p pad_ls (and (index p->layer oppo_soldermask_ly) (equal "REGULAR" p->type)))))
				(box = pad_id->bBox)
				(tp_sm_pad_dia = (abs ((caar box) - (caadr box))))
				(unless (axlGeoEqual (tp_pad_dia + opposite_sm_drill_ext) tp_sm_pad_dia)
					(sprintf info "[Opposite Soldermask: %s, Dia: %.2f] has to be [Pad Size: %.2f] + [%.2f]"
						oppo_soldermask_ly tp_sm_pad_dia tp_pad_dia opposite_sm_drill_ext)
					(info_ls = (append1 info_ls info))
				)
			)
			
			
			;;; collect
			(unless (dtpr info_ls) (info_ls = (list "Pass the examination")))
			(result = (append1 result (list via_id info_ls)))
		)
		
		(return result)
	)
)

(procedure get_tp_via_Derek02122019()
	(prog (net_ls via_ls tp_thru_via_ls)
	
		;;; get all the net from board
		(net_ls = axlDBGetDesign()->nets)
		
		;;; get all via from nets
		(via_ls = (mapcan (lambda (n) (mapcan (lambda (b) (setof c b->children (equal "via" c->objType))) n->branches)) net_ls))
		
		;;; get all through testpoint via from via list
		(tp_thru_via_ls = (setof v via_ls (and (stringp v->testPoint) v->isThrough)))
		
		;;; filter to uni via list
		(tp_thru_via_ls = (maplist (lambda (vs) (if (member (car vs)->name (cdr vs)~>name) nil (car vs))) tp_thru_via_ls))
		(tp_thru_via_ls = (setof v tp_thru_via_ls v))
		
		(return tp_thru_via_ls)
	)
)

(procedure get_vias_by_drl_pad_Derek02122019(drl_dia pad_dia)
	;;; this function is used to filter out the specific type of via by drill diameter and pad diameter
	(prog (via_nm_ls via_ls )
		(unless (and (plusp drl_dia) (plusp pad_dia)) (printf "get_vias_by_drl_pad() - Fail Args:%L\n" (list drl_dia pad_dia)) (return nil))
		;;
		
		;;; parent function may pass the integer or float number, otherwise, the result would be nil
		(drl_dia = (float drl_dia))
		(pad_dia = (float pad_dia))
		;;
		
		;;; get all via type name
		(via_nm_ls = (axlCnsGetViaList "DEFAULT"))
		(via_ls = (mapcar (lambda (v) (axlDBFindByName 'padstack v)) via_nm_ls))
		
		;;; filter out testpoint
		;;; test via can only exist on either side, therefore, use through property to identify whether it's a test via or not.
		;;; (a via is usually in through type)
		(via_ls = (mapcan (lambda (v) (when v->isThrough (list v))) via_ls))
		
		;;; get via whose drill diameter is equal to drl_dia
		(via_ls = (mapcan (lambda (v) (when (axlGeoEqual drl_dia v->drillDiameter) (list v))) via_ls))
		
		;;; get via whose pad diameter is equal to pad_dia
		;;; get_pad_hv function is a child from skill pool built by Derek
		(via_ls = (mapcan (lambda (v) (when (axlGeoEqual pad_dia (get_pad_diameter_Derek02122019 v)) (list v))) via_ls))
		
		;;; if there is TP term in via name, then to regard it as a testpoint
		(via_ls = (mapcan (lambda (v) (unless (onep (nindex (upperCase v->name) "TP")) (list v))) via_ls))
		
		
		;;; the result may have test via if the via is in through characteristic
		(return via_ls)
	)
)

(procedure get_probe_parm1_type_xml_Derek02122019(pad_nm top_pad_nm bot_pad_nm)
	;;;;; sample
		;	<probe_parm1_type>
		;		<rev>1</rev>
		;		<flags>1</flags>
		;		<existingPadstack>SMT Testpad</existingPadstack>
		;		<topReplacementPadstack>TP-C30TMP</topReplacementPadstack>
		;		<botReplacementPadstack>TP-C30BMP</botReplacementPadstack>
		;	</probe_parm1_type>
	(prog (form_content form_head rev_str flg_str exi_str top_str bot_str result)
		(unless (and (stringp pad_nm) (stringp top_pad_nm) (stringp bot_pad_nm))
			(printf "get_probe_parm1_type_xml() - ArgErr%L\n" (list pad_nm top_pad_nm bot_pad_nm))
			(return nil)
		)
		;;
		(when (or (equal (upperCase pad_nm) (upperCase top_pad_nm)) (equal (upperCase pad_nm) (upperCase bot_pad_nm))) (return nil))
		(unless (axlLoadPadstack top_pad_nm) (printf "get_probe_parm1_type_xml_Derek02122019() - Fail to find padstack[%s]\n" top_pad_nm) (return nil))
		(unless (axlLoadPadstack bot_pad_nm) (printf "get_probe_parm1_type_xml_Derek02122019() - Fail to find padstack[%s]\n" bot_pad_nm) (return nil))
		
		(form_content = "\t\t<%s>%s</%s>\n")
		(form_head = "\n\t<%s>\n%s\t</%s>\n")
		
		(sprintf rev_str form_content "rev" "1" "rev")
		(sprintf flg_str form_content "flags" "1" "flags")
		(sprintf exi_str form_content "existingPadstack" pad_nm "existingPadstack")
		(sprintf top_str form_content "topReplacementPadstack" top_pad_nm "topReplacementPadstack")
		(sprintf bot_str form_content "botReplacementPadstack" bot_pad_nm "botReplacementPadstack")
		
		(result = (strcat rev_str flg_str exi_str top_str bot_str))
		(result = (sprintf nil form_head "probe_parm1_type" result "probe_parm1_type"))
		
		(return result)
	)
)

(procedure get_probe_parm2_type_xml_Derek02122019(rev flg probe_t probe_s probe_f)
	;;;;; sample
	; <probe_parm2_type>
    ; <rev>1</rev>
    ; <flags>1</flags>
    ; <probeType>30</probeType>
    ; <probeSpacing>50.00 MIL</probeSpacing>
    ; <probeFigure>18</probeFigure>
    ; </probe_parm2_type>
	(prog (form_content form_head)
		(unless (plusp rev) (println "ArgErr: get_probe_parm2_type_xml() - rev is not positive integer") (return nil))
		(unless (plusp flg) (println "ArgErr: get_probe_parm2_type_xml() - flags is not positive integer") (return nil))
		(unless (plusp probe_t) (println "ArgErr: get_probe_parm2_type_xml() - probeType is not positive integer") (return nil))
		(unless (plusp probe_s) (println "ArgErr: get_probe_parm2_type_xml() - probeSpacing is not positive integer") (return nil))
		(unless (plusp probe_f) (println "ArgErr: get_probe_parm2_type_xml() - probeFigure is not positive integer") (return nil))
		;;
		
		(form_content = "\t\t<%s>%n</%s>\n")
		(form_head = "\n\t<%s>\n%s\t</%s>\n")
		
		(sprintf rev_str form_content "rev" rev "rev")
		(sprintf flg_str form_content "flags" flg "flags")
		(sprintf prt_str form_content "probeType" probe_t "probeType")
		(sprintf prs_str "\t\t<probeSpacing>%.2f MIL</probeSpacing>\n" probe_s)
		(sprintf prf_str form_content "probeFigure" probe_f "probeFigure")
		
		(result = (strcat rev_str flg_str prt_str prs_str prf_str))
		(result = (sprintf nil form_head "probe_parm2_type" result "probe_parm2_type"))
		
		(return result)
	)
)

(procedure import_testprep_Derek02122019()
	(prog (via8_p18_ls prm via_ls out_port xml)
		;;; get all via list with drill hole 8 and pad 18 to assign them the testpoint
		(via_p_ls = (get_vias_by_drl_pad_Derek02122019 8 18))
		
		;;; create testpoint param file
		(unless (outportp (out_port = (outfile tp_prm_nm))) (println "import_testprep() - Fail to create param file") (return nil))
		
		;;; the xml header 
		(fprintf out_port "<?xml version=\"%.1f\" encoding=\"%s\" standalone=\"%s\" ?>\n<CadenceAllegroParameter xmlns=\"\">\n" 1.0 "UTF-8" "no")
		
		;;; the parameter header
		(version = (axlVersion 'pVersion))
		(fprintf out_port "\n\t<parameter_header>\n\t\t<version>%s</version>\n\t</parameter_header>\n\n" version)
		
		;;;;; manufacture > testprep parameter
		;;;; padstack selection
		(fprintf out_port (get_probe_parm1_type_xml_Derek02122019 "SMT Testpad" "TP-C30TMP" "TP-C30BMP"))
		(fprintf out_port (get_probe_parm1_type_xml_Derek02122019 "Thru Via" "TP18_8TMP30HP" "TP18_8BMP30HP"))
		(via_p_ls = (get_vias_by_drl_pad_Derek02122019 8 18))
		(foreach via_id via_p_ls
			(xml = (get_probe_parm1_type_xml_Derek02122019 via_id->name "TP18_8TMP30NP" "TP18_8BMP30NP"))
			(when (stringp xml) (fprintf out_port xml))
		)
		(via_p_ls = (get_vias_by_drl_pad_Derek02122019 10 20))
		(foreach via_id via_p_ls
			(xml = (get_probe_parm1_type_xml_Derek02122019 via_id->name "TP20_10TMP30NP" "TP20_10BMP30NP"))
			(when (stringp xml) (fprintf out_port xml))
		)
		
		;;; general parameter
		(fprintf out_port (get_probe_parm2_type_xml_Derek02122019 1 1 30 50.0 18))
		
		;;; end of xml header
		(fprintf out_port "\n</CadenceAllegroParameter>\n")
		
		(close out_port)
		
		;;; import testpoint param file
		(axlImportXmlDBRecords tp_prm_nm)
		
		;;; check replac via option
		(prm = (axlGetParam "testprep"))
		(prm->replaceVias = t)
		(axlSetParam prm)
		
		(println "The testpoint setting has been updated and the 'replace via' has been checked")
	)
)

(defun test_point_check_main_Derek02122019 ()
	(prog (tp_thru_via_ls issued_via_ls via_id info_ls nm info ans)
		(unless axlOKToProceed() (println "Please done current function to use this program") (return nil))
		;;
		
		init_Derek02122019()
		
		;;;;; import testpoint setting?
		(ans = (axlUIYesNo "Do you want to overwrite testpoint setting?"))
		(when ans import_testprep_Derek02122019())
		
		;;;;; get all testpoint via
		(tp_thru_via_ls = get_tp_via_Derek02122019())
		(unless (dtpr tp_thru_via_ls) (println "None of through type test via has been found") (return nil))
		
		;;;;; check all testpoint via
		(issued_via_ls = (check_tp_thru_via_Derek02122019 tp_thru_via_ls))
		
		;;;;; output to log file
		(foreach vi issued_via_ls
			(via_id = (car vi))
			(info_ls = (cadr vi))
			;;
			(nm = via_id->name)
			(info = (buildString info_ls "\n\t"))
			(printf "VIA[%s] has issues: \n\t%s\n" nm info)
		)
		
		(return t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "test_point_check" 'test_point_check_main_Derek02122019)
; test_point_check_main_Derek02122019()
; skill (encrypt "c:/skill/test_point_check_v1.il" "c:/skill/test_point_check_v1.ile")
; (load "test_point_check_v1.ile")
; (load "test_point_check_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup