;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction

; Developer: Derek Hsu
; Starting _date: 5/10/2019 - _Derek05102019
; purpose: check high speed via
; compatitable allegro version: 16.6, 17.2
; Description:
;	1. objective: via footprint having 4 via
;	2. check item
;		1. 2 outer vias have to connect to GND
;		2. 2 inner vias have to connect to differential net
;		2. the impedance on footprint(??_[*]dp) and the physical constraint on net
;		3. the impedance on footprint() and the physical constraint on connected footprint
;		4. check laser or through via
;		5. check path
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

(procedure init_Derek05102019()
	;;; general global variable
	(setq _allegro_version (axlVersion 'version))
	(setq _gnd "GND")
	(setq _etch_ls (append (list nil) (mapcar (lambda (g) (strcat "ETCH/" g)) (axlGetParam "paramLayerGroup:ETCH")->groupMembers)))
	(setq _etch_total (sub1 (length _etch_ls)))
	(setq _max_laser_ly 3)
	
	;;; get log file name
	(unless (axlGetVariable "ads_sdlog") (axlSetVariable "ads_sdlog" "log"))
	(setq _log_dir (axlGetVariable "ads_sdlog"))
	(unless (isDir _log_dir) (createDir _log_dir))
	(setq _mon_ls (list nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	(setq _curr_time_ls (parseString getCurrentTime() " "))
	(setq _date (sprintf nil "%s%.2d%s" (nth 3 _curr_time_ls) (listnindex _mon_ls (nth 0 _curr_time_ls)) (nth 1 _curr_time_ls)))
	(setq _time (buildString (parseString (nth 2 _curr_time_ls) ":") ""))
	(setq _now (strcat _date "-" _time))
	(setq _log_f_nm (sprintf nil "high_speed_via_%s.log" _now))
	(setq _log_addr (strcat getWorkingDir() "/" _log_dir "/" _log_f_nm))
	
	;;; get all signal via pair from via footprint
	;;; ---------------------- for some reason, the etchChildren will disappear during the runtime. therefore, extract these out first
	(setq _via_sym_ls get_via_ft_Derek05102019())
	(setq _io_v2_ls (mapcar 'get_io_vias_Derek05102019 _via_sym_ls))
	(setq _sig_v2_ls (mapcar 'car _io_v2_ls))
	(setq _gnd_v2_ls (mapcar 'cadr _io_v2_ls))
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

(procedure get_via_ft_Derek05102019()
	;;; get all via footprint
	;;; a = (car axlGetSelSet())
	(let (sym_ls via_sym_ls)
		;;; reset the design and get the best result of the etchChildren
		(axlShell "generaledit")
		
		;;; getting symbols
		(sym_ls = axlDBGetDesign()->symbols)
		
		;;; filter out the symbol having any pin
		(sym_ls = (setof s sym_ls (zerop (length s->pins))))
		
		;;; leave the symbols only have via
		(sym_ls = (setof s sym_ls s->etchChildren))
		(via_sym_ls = (mapcan (lambda (s) (when (forall c s->etchChildren (equal "via" c->objType)) (list s))) sym_ls))
		
		via_sym_ls
	)
)

(procedure write_log_Derek05102019(contents @optional (show_window nil))
	(prog (out_port)
		(unless (dtpr contents) (contents = (list contents)))
		(unless (outportp (out_port = (outfile _log_addr "a"))) (println "ERROR: write_log() - Fail to open file") (return nil))
		(unless (booleanp show_window) (println "ArgErr: write_log() - show_window is not a boolean") (return nil))
		;;
		
		(foreach cs contents
			(if (dtpr cs) then
				(foreach c cs
					(fprintf out_port "\t%s\n" c)
					(when show_window (printf "\t%s\n" c))
				)
			else
				(fprintf out_port "%s\n" cs)
				(when show_window (printf "%s\n" cs))
			)
		)
		
		(close out_port)
	)
)

(procedure get_io_vias_Derek05102019(sym_id)
	;;; type has to be 'i2 or 'o2
	;;;		'inner: inner 2 vias. if inner 2 vias exists, it should always be signal
	;;;		'outer: outer 2 vias. if outer 2 vias exists, it should always be ground
	;; (sym_id = (car via_sym_ls))
	;; via_sym_ls~>etchChildren
	(prog (via_ls via_len sym_xy contents result)
		(unless (equal "symbol" sym_id->objType) (println "ArgErr: get_io_vias() - sym_id is not a symbol") (return nil))
		(via_ls = sym_id->etchChildren)
		(unless (dtpr via_ls) (println "ArgErr: get_io_vias() - Fail to find via list from symbol") (return nil))
		(unless (forall v via_ls (equal "via" v->objType)) (println "ArgErr:  get_io_vias() - via_ls is not a via type list") (return nil))
		;;
		
		(via_len = (length via_ls))
		(sym_xy = sym_id->xy)
		(cond
			((eqv 2 via_len)
				(result = (list via_ls nil))
			)
			((or (eqv 4 via_len) (eqv 3 via_len))
				;;; this is a through via section
				;;; after getting the center of the footprint, the signal via should be inner 2 and the gnd should be outer 2
				(xy_ls = via_ls~>xy)
				;;; the sequence should be (gnd gnd sig sig)
				(via_ls = (sort via_ls (lambda (a b) ((axlDistance sym_xy a->xy) > (axlDistance sym_xy b->xy)))))
				;;
				(result = (list (cddr via_ls) (cddr (reverse via_ls))))
			)
			(t
				(sprintf contents "ERROR: get_io_vias_Derek05102019() - the via symbol has undefined number of via(%d) at %L" via_len (car via_ls)->xy)
				(write_log_Derek05102019 contents t)
			)
		)
		
		(return result)
	)
)

(procedure get_constraint_nm_8via_Derek05102019(via_id type)
	;; via_id = (car axlGetSelSet())
	(prog (parent_group netclass result)
		(unless (equal "via" via_id->objType) (println "ArgErr: get_constraint_nm_8via() - via_id is not a via type object") (return nil))
		(unless (memq type (list 'netclass 'physical)) (println "ArgErr: get_constraint_nm_8via() - type is neither netclass nor physical") (return nil))
		;;
		
		;;; get netclass id
		(parent_group = via_id->net->parentGroups)
		(netclass = (setof p parent_group (and (equal "NETCLASS" p->type) p->physical)))
		(unless (onep (length netclass)) (println "ERROR: get_constraint_nm_8via() - Fail to find netclass") (return nil))
		(netclass = (car netclass))
		
		;;; get
		(caseq type
			('netclass (result = netclass->name))
			('physical (result = netclass->prop->PHYSICAL_CONSTRAINT_SET))
			(t (printf "ERROR: get_constraint_nm_8via() - Not define type[%s]\n" type))
		)
		
		(return result)
	)
)

(procedure get_impedance_8name_Derek05102019(nm type)
	;;; for the type
	;;;		dp: [via footprint name] (V_J3DAC_85DP)
	;;;		z: [netclass name] (W5D6.5-6_Z85)
	;;;		w: [physical&spacing constraint name] (P3E-MEZZ-TX_W85/S30.8-13.5[30.8-22.5])
	(prog (result)
		(unless (stringp nm) (println "ArgErr: get_impedance_8name() - nm is not a string") (return nil))
		(unless (memq type (list 'dp 'z 'w)) (printf "ArgErr: get_impedance_8name() - type [%s] is not defined\n" type) (return nil))
		;;
		
		(nm = (upperCase nm))
		(caseq type
			('dp (rexCompile "_\\([0-9]+\\)DP$"))
			('z (rexCompile "_Z\\([0-9]+\\)"))
			('w (rexCompile "_W\\([0-9]+\\)"))
		)
		(when (rexExecute nm) (result = (rexSubstitute "\\1")))
		
		(return result)
	)
)


(procedure check_path_Derek05102019()
	;;; ckeck the path whether is to T
	(let (via_sym_ls sym_ls contents)
		;;; get uni symbol by symbol name
		(via_sym_ls = _via_sym_ls)
		(sym_ls = (maplist (lambda (s) (if (member (car s)->name (cdr s~>name)) nil (car s))) via_sym_ls))
		(sym_ls = (setof s sym_ls s))
		
		;;; check the location of each symbol
		;;; LIBRARY_PATH is the psm path. the first character is used to be the certain drive, nevertheless, it should be in T
		(sym_ls = (mapcan (lambda (s) (unless (eq 'T (getchar s->definition->prop->LIBRARY_PATH 1)) (list s))) sym_ls))
		
		;;; write log
		(contents = (list "\nThe high speed via is not in T drive:" (list "Name,Address")))
		(if (dtpr sym_ls) then
			(contents = (append1 contents (mapcar (lambda (s) (strcat s->name "," s->definition->prop->LIBRARY_PATH)) sym_ls)))
		else
			(contents = (append1 contents (list "None")))
		)
		
		(write_log_Derek05102019 contents)
		
		t
	)
)

(procedure check_impedance_Derek05102019()
	;;; check impedance between via name(V_J3DAC_85DP) and netclass(W5D6.5-6_Z85) and physical&spacing constraint name(P3E-MEZZ-TX_W85/S30.8-13.5[30.8-22.5])
	;; (a = (car sig_vias_ls))
	;; fail_4nm_ls: fail to fetch name
	;; fail_4imp_ls: fail to fetch impedance value
	;; fail_1imp_ls: impedances are not equal
	(let ((sig_v2_ls _sig_v2_ls) sym_nm sym_xy via1_id via_xy via_cls via_cons sym_imp
			via_cls_imp via_cons_imp fail_4nm_ls fail_4imp_ls fail_1imp_ls net_nm contents)
		(foreach v2 sig_v2_ls
			(foreach via_id v2
				(via_xy = via_id->xy)
				(net_nm = via_id->net->name)
				(sym_nm = via_id->symbolEtch->name)
				(sym_xy = via_id->symbolEtch->xy)
				(via_cls = (get_constraint_nm_8via_Derek05102019 via_id 'netclass))
				(via_cons = (get_constraint_nm_8via_Derek05102019 via_id 'physical))
				
				(if (and (stringp via_cls) (stringp via_cons)) then
					;;; get impedance from each section
					(sym_imp = (get_impedance_8name_Derek05102019 sym_nm 'dp))
					(via_cls_imp = (get_impedance_8name_Derek05102019 via_cls 'w))
					(via_cons_imp = (get_impedance_8name_Derek05102019 via_cons 'z))
					;;
					(if (and (stringp sym_imp) (stringp via_cls_imp) (stringp via_cons_imp)) then
						(unless (and (equal sym_imp via_cls_imp) (equal sym_imp via_cons_imp))
							(fail_1imp_ls = (append1 fail_1imp_ls (list via_xy sym_nm via_cls via_cons)))
						)
						;;; if the process go over this line, then the symbol perfectly match
					else
						;;; fail to get impedance from symbol name, netclass or constraint
						(unless (stringp sym_imp)
							(fail_4imp_ls = (append1 fail_4imp_ls (list sym_xy net_nm "symbol_name" sym_nm)))
						)
						(unless (and (stringp via_cls_imp) (stringp via_cons_imp))
							(fail_4imp_ls = (append1 fail_4imp_ls (list via_xy net_nm via_cls via_cons)))
						)
					)
				else
					;;; fail to get name from via and symbol
					(unless (and (stringp via_cls) (stringp via_cons))
						(fail_4nm_ls = (append1 fail_4nm_ls (list via_xy net_nm via_cls via_cons)))
					)
				)
			)
		)
		
		;;; write log for 'fail to fetch name'
		(contents = (list "\nFail to get net related from via" "\tvia_xy,net_name,netclass,phy/spc_constraint"))
		(if (dtpr fail_4nm_ls)
			(foreach v4 fail_4nm_ls (contents = (append1 contents (sprintf nil "\t%L,%L,%L,%L" (car v4) (cadr v4) (caddr v4) (cadddr v4)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		;;; write log for 'fail to fetch impedance'
		(contents = (list "\nFail to get related impedance from net" "\tvia/symbol_xy,net_name,netclass,phy/spc_constraint"))
		(if (dtpr fail_4imp_ls)
			(foreach v4 fail_4imp_ls (contents = (append1 contents (sprintf nil "\t%L,%L,%L,%L" (car v4) (cadr v4) (caddr v4) (cadddr v4)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		;;; write log for 'not equal impedance' error( "myFunc" "Bad List")
		(contents = (list "\nMismatch impedance among symbol, netclass and phy/spc constraint" "\tvia_xy,symbol_impedance,netclass,phy/spc_constraint"))
		(if (dtpr fail_1imp_ls)
			(foreach v4 fail_1imp_ls (contents = (append1 contents (sprintf nil "\t%L,%L,%L,%L" (car v4) (cadr v4) (caddr v4) (cadddr v4)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		t
	)
)

(procedure get_via_etch_layer_Derek05102019(via_id)
	;; via_id = (car axlGetSelSet())
	(prog (etch_ls result)
		(unless (equal "via" via_id->objType) (println "ArgErr: get_via_etch_layer() - via_id is not a via") (return nil))
		;;
		
		(etch_ls = (cdr _etch_ls))
		(foreach ly_nm etch_ls
			(pad_id = (axlDBGetPad via_id ly_nm "REGULAR"))
			(figure = pad_id->figure)
			(when figure
				(result = (append1 result ly_nm))
			)
		)
		
		(return result)
	)
)

(procedure is_laser_via_8layer_Derek05102019(layer_ls)
	(prog (ly_num_ls start end cnt result)
		(unless (dtpr layer_ls) (println "ArgErr: is_laser_via_8layer() - layer_ls is nil") (return nil))
		(unless (forall x layer_ls (member x _etch_ls))
			(println "ArgErr: is_laser_via_8layer() - elements in layer_ls are not in etch")
			(return nil)
		)
		(unless ((length layer_ls) <= _max_laser_ly) (println "ArgErr: is_laser_via_8layer() - too much layer for laser via") (return nil))
		(unless (exists ly layer_ls (member ly (list "ETCH/TOP" "ETCH/BOTTOM")))
			(println "ArgErr: is_laser_via_8layer() - not found top/bottom in layer_ls")
			(return nil)
		)
		;;
		
		(ly_num_ls = (mapcar (lambda (x) (listnindex _etch_ls x)) layer_ls))
		(start = (car ly_num_ls))
		(end = (lastelem ly_num_ls))
		
		;;
		(cnt = start)
		(result = t)
		(for i start end (if (eqv i cnt) cnt++ (result = nil)))
		
		(return result)
	)
)

(procedure check_ground_Derek05102019()
	;;; for checking the gnd of 2-layer lase via
	(let ((gnd_v2_ls _gnd_v2_ls) (sig_v2_ls _sig_v2_ls) via_id via_xy via_net_nm fail_thru_gnd_ls
			fail_lsr_gnd_ls contents pad_etch_lys obj_ls name_ls )
		;;; check the gnd via of the outer 2 via from through via optimization
		(foreach v2 gnd_v2_ls
			(foreach via_id v2
				(via_net_nm = via_id->net->name)
				;;
				(unless (equal _gnd via_net_nm)
					(fail_thru_gnd_ls = (append1 fail_thru_gnd_ls (list via_id via_net_nm)))
				)
			)
		)
		
		;;; check 2-layer lase via whether is connected to gnd or not
		(foreach (gv2 sv2) gnd_v2_ls sig_v2_ls
			;;; when 2 or 1 outer ground via are nil, then 2 inner signal via could be 3-layer or 2-layer laser via
			(when (forall v gv2 (null v))
				(foreach via_id sv2
					(pad_etch_lys = (get_via_etch_layer_Derek05102019 via_id))
					(if (is_laser_via_8layer_Derek05102019 pad_etch_lys) then
						;;; for 3-layer laser via, it will be connected to signal
						;;; for 2-layer laser via, it will be connected to ground
						(when (eqv 2 (length pad_etch_lys))
							(obj_ls = (axlDBGetConnect via_id))
							(name_ls = obj_ls~>net~>name)
							(if (forall n name_ls (equal "GND" n)) then
								;;; for this section, the via is successfully passed
							else
								(via_xy = via_id->xy)
								(fail_lsr_gnd_ls = (append1 fail_lsr_gnd_ls (list via_xy name_ls)))
							)
						)
					else
						(sprintf contents "ERROR: check_ground() - layers of via[%L] are not in order[%L]" via->xy pad_etch_lys)
						(write_log contents t)
					)
				)
			)
		)
		
		;;; write log
		(contents = (list "\nFor through via optimization, outer vias are not connected to GND" "\tvia_xy,net_name"))
		(if (dtpr fail_thru_gnd_ls)
			(foreach v2 fail_thru_gnd_ls (contents = (append1 contents (sprintf nil "\t%L,%L" (car v2)->xy (cadr v2)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		;;; write_log
		(contents = (list "\nFor 2-layer laser via optimization, vias are not connected to GND" "\tvia_xy,net_name"))
		(if (dtpr fail_lsr_gnd_ls)
			(foreach v2 fail_lsr_gnd_ls (contents = (append1 contents (sprintf nil "\t%L,%L" (car v2) (cadr v2)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		;;; assign gnd to via
		(when (dtpr fail_thru_gnd_ls)
			(sprintf contents "There are [%d] vias should be connected to ground but not. Would you like to automatically update?" (length fail_thru_gnd_ls))
			(answer = (axlUIYesNo contents "Assign via to ground"))
			(when answer
				(foreach v2 fail_thru_gnd_ls
					(via_id = (car v2))
					(printf "Via at [%L] has been updated from [%s] to [GND]\n" via_id->xy via_id->net->name)
					(axlDBAssignNet via_id "GND" nil)
					;(axlDBAssignNet via_id "P3V3" nil)
				)
				(axlUIConfirm "All the via in command has been updated. Please check" "Assign via to ground")
			)
		)
	
		
		t
	)
)

(procedure is_laser_layer_Derek05102019(ly1_nm ly2_nm)
	(prog (ly1_num ly2_num laser_bot_least result)
		(unless (member ly1_nm _etch_ls) (println "ArgErr: is_laser_layer() - ly1_nm is not in _etch_ls") (return nil))
		(unless (member ly2_nm _etch_ls) (println "ArgErr: is_laser_layer() - ly2_nm is not in _etch_ls") (return nil))
		;;
		(ly1_num = (listnindex _etch_ls ly1_nm))
		(ly2_num = (listnindex _etch_ls ly2_nm))
		(laser_bot_least = (_etch_total - _max_laser_ly))
		
		(cond
			((and (onep ly1_num) (ly2_num <= _max_laser_ly)) (result = t))
			((and (onep ly2_num) (ly1_num <= _max_laser_ly)) (result = t))
			((and (eqv _etch_total ly1_num) (ly2_num > laser_bot_least)) (result = t))
			((and (eqv _etch_total ly2_num) (ly1_num > laser_bot_least)) (result = t))
		)
		
		(return result)
	)
)

(procedure check_laser_thru_Derek05102019()
	;; via_id = (car axlGetSelSet())
	;;; fail_num_ls: the number of connected net to via is more than 2 or 0
	;;; fail_thr_ls: via is in through but laser via is enough
	;;; fail_lsr_ls: via is in laser but it has to be through
	(let ((sig_v2_ls _sig_v2_ls) via_xy is_through obj_ls path_ls ly1_nm ly2_nm is_laser fail_num_ls fail_thr_ls fail_lsr_ls contents)
		(foreach v2 sig_v2_ls
			(foreach via_id v2
				(via_xy = via_id->xy)
				(is_through = via_id->isThrough)
				(obj_ls = (axlDBGetConnect via_id))
				(path_ls = (setof p obj_ls (and p->isEtch (equal "path" p->objType))))
				;;
				(if (and (dtpr path_ls) (eqv 2 (length path_ls))) then
					;;
					(ly1_nm = (car path_ls)->layer)
					(ly2_nm = (cadr path_ls)->layer)
					(is_laser = (is_laser_layer_Derek05102019 ly1_nm ly2_nm))
					
					;;
					(if is_through then
						;;; if it were a through via, the connected net should away from top/bottom for at least 3 layers
						(if is_laser then
							(fail_thr_ls = (append1 fail_thr_ls (list via_xy ly1_nm ly2_nm)))
						else
							;;; all the via passing through this section is perfectly right
						)
					else
						;;; if it were a laser via, the layer of the connected net should be as same as the layer indicated on the symbol name
						(if is_laser then
							;;; all the via passing through this section is perfectly right
						else
							(fail_lsr_ls = (append1 fail_lsr_ls (list via_xy ly1_nm ly2_nm)))
						)
					)
				else
					;;; fail to get net from this via or more than 2 net have been found
					(fail_num_ls = (append1 fail_num_ls (append1 (list via_xy) path_ls~>layer)))
				)
			)
		)
		
		;;; write log
		(contents = (list "\nMissing number(2) of net to via" "\tvia_xy,net_list"))
		(if (dtpr fail_num_ls)
			(foreach v2 fail_num_ls (contents = (append1 contents (sprintf nil "\t%L,%L" (car v2) (cadr v2)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		;;; write log
		(contents = (list "\nUsing through via, however, laser via is enough" "\tvia_xy,from_layer,to_layer"))
		(if (dtpr fail_thr_ls)
			(foreach v3 fail_thr_ls (contents = (append1 contents (sprintf nil "\t%L,%L,%L" (car v3) (cadr v3) (caddr v3)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		;;; write log
		(contents = (list "\nUsing laser via, however, it's necessary to use through via" "\tvia_xy,from_layer,to_layer"))
		(if (dtpr fail_lsr_ls)
			(foreach v3 fail_lsr_ls (contents = (append1 contents (sprintf nil "\t%L,%L,%L" (car v3) (cadr v3) (caddr v3)))))
			(contents = (append1 contents "\tNone"))
		)
		(write_log_Derek05102019 contents)
		
		t
	)
)

(procedure check_via_ft_Derek05102019()
	;;; check via opt by many section
	(let ()
		;;; check psm location
		(write_log_Derek05102019 "\n============================ Start checking path ===============================")
		check_path_Derek05102019()
		
		;;; check impedance among symbol name, netgroup name and physical/spacign constraint name
		(write_log_Derek05102019 "\n============================ Start checking impedance ==========================")
		check_impedance_Derek05102019()
		
		;;; check ground
		(write_log_Derek05102019 "\n============================ Start checking ground =============================")
		check_ground_Derek05102019()
		
		;;; check through and laser via
		(write_log_Derek05102019 "\n============================ Start checking thru & laser =======================")
		check_laser_thru_Derek05102019()
	)
)

(procedure check_hs_via_main_Derek05102019()
	(prog ()
		;;; init_Derek05102019
		init_Derek05102019()
		
		(unless (dtpr _via_sym_ls) (println "No high speed via footprint has been found") (return nil))
		
		;;; create header of log
		(contents = (list "================================================================================"
						"This is the high speed via checking report"
						"Company: Flex - TDC"
						(sprintf nil "\tDate: %s" _date)
						(sprintf nil "\tTime: %s" _time)
						(sprintf nil "\tVersion: %.1f" _allegro_version) 
						(sprintf nil "\tDesign Name: %s" axlCurrentDesign())
						"================================================================================"))
		
		(write_log_Derek05102019 contents)

		;;; start checking
		check_via_ft_Derek05102019()
		
		;;; create form
		(axlUIViewFileCreate _log_addr "Check high speed via log" nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_hs_via" 'check_hs_via_main_Derek05102019)
; check_hs_via_main_Derek05102019()
; skill (encrypt "c:/skill/check_hs_via_v1.il" "c:/skill/check_hs_via_v1.ile")
; (load "check_hs_via_v1.ile")
; (load "check_hs_via_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup