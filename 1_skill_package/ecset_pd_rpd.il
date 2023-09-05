;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
;Developer: Derek Hsu
;Starting Date: 01/08/2018 _Derek01082018
;Introduction: This is a tool for SI to setup Ecset, including relative propagation delay and min/max propagation delay
;Specification:
;	relative propagation delay: 
;		default is setting the pinpair to matchgroup, regardless of the net
;		min: 0
;		max: 90000
;	min/max propagation delay:
;		default is setting pinpair
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Varlable

(defun init_Derek01082018 ()
	(setq add_to_grid_net_ls nil)
	(setq restore_net_ls nil)
	
	(setq min_high_speed_impedence 70)
	(setq ecset_rpd_pd_form_name "ecset_rpd_pd.form")
	(setq ecset_rpd_pd_form_address (strcat getWorkingDir() "/" ecset_rpd_pd_form_name))
	
	defstruct(net_comp_slots net_id pin1_id pin2_id target check)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Varlable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Form

(procedure set_right_popup_Derek01082018()
	(pop_id = axlUIPopupDefine( nil (list (list "Done" 'axlFinishEnterFun) (list "Cancel" 'axlCancelEnterFun))))
	(axlUIPopupSet pop_id)
)

(defun ecset_rpd_pd_form_builder_Derek01082018 ()
	(when (outportp (out_port = (outfile ecset_rpd_pd_form_address "w")))
		(fprintf out_port "FILE_TYPE=FORM_DEFN VERSION=%d\n" 1)   
		(fprintf out_port "FORM TOOLWINDOW \n")
		(fprintf out_port "FIXED\n")
		(fprintf out_port "PORT %d %d\n" 69 90)
		(fprintf out_port "HEADER \"Ecset RPD/PD v%.1f\"\n\n" 1.0)
		
		;"\"------------------\"\"SEPERATOR\""
		;"\"Edit Comp Start\"\"edit_comp_start\""
		;"\"Edit Comp End\"\"edit_comp_end\""
		(fprintf out_port (strcat "POPUP <netlist_rc>" (buildString '("\"Mark\"\"grid_mark_tar\"" 
																		"\"unMark\"\"grid_unmark_tar\""
																		"\"------------------\"\"SEPERATOR\""
																		"\"Check\"\"grid_check\""
																		"\"unCheck\"\"grid_uncheck\""
																		"\"------------------\"\"SEPERATOR\""
																		"\"Sort\"\"grid_sort\""
																		"\"Sort Pair\"\"grid_sort_pair\""
																		"\"------------------\"\"SEPERATOR\""
																		"\"*Next...[?]/[?-?]\"\"grid_next\""
																		) ",") ".\n\n"))
		
		(fprintf out_port "TILE\n\n")
		
		(fprintf out_port "GROUP \"NETLIST\"\n")
		(fprintf out_port "FLOC %d %d\n" 1 1)
		(fprintf out_port "TSSIZE %d %d\n" 68 44)

			;;;;; net list grid
			(fprintf out_port "GRID netlist_grid\n")
			(fprintf out_port "FLOC %d %d\n" 2 3)
			(fprintf out_port "FSIZE %d %d\n" 66 34)
			(fprintf out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
			(fprintf out_port "POP \"netlist_rc\"\n")
			(fprintf out_port "GHEAD TOP\n")
			(fprintf out_port "HEADSIZE %d\n" 2)
			(fprintf out_port "OPTIONS %s\n" "3D")
			(fprintf out_port "ENDGHEAD\n")
			(fprintf out_port "ENDGRID\n\n")
			
			;;;;; option
			(fprintf out_port "GROUP \"Net Category\"\n")
			(fprintf out_port "FLOC %d %d\n" (cate_floc_x = 36) (cate_floc_y = 36))
			(fprintf out_port "TSSIZE %d %d\n" 32 4)
				(fprintf out_port "FIELD net_all\n")
				(fprintf out_port "FLOC %d %d\n" (cate_floc_x + 2) (cate_floc_y + 2))
				(fprintf out_port "CHECKLIST \"ALL\" \"net_options\" \n")
				(fprintf out_port "ENDFIELD\n")

				(fprintf out_port "FIELD net_hs\n")
				(fprintf out_port "FLOC %d %d\n" (cate_floc_x + 13) (cate_floc_y + 2))
				(fprintf out_port "CHECKLIST \"HS\" \"net_options\" \n")
				(fprintf out_port "ENDFIELD\n")
				
				(fprintf out_port "FIELD net_ls\n")
				(fprintf out_port "FLOC %d %d\n" (cate_floc_x + 24) (cate_floc_y + 2))
				(fprintf out_port "CHECKLIST \"LS\" \"net_options\" \n")
				(fprintf out_port "ENDFIELD\n")
			(fprintf out_port "ENDGROUP\n\n")
			
			
			;;;;; botton
			
			(fprintf out_port "FIELD net_search_bar\n") ; result	
			(fprintf out_port "FLOC %d %d\n" 2 38)
			(fprintf out_port "STRFILLIN %d %d\n" 21 30)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "FIELD net_fetch\n")
			(fprintf out_port "FLOC %d %d\n" 25 38)
			(fprintf out_port "MENUBUTTON \"Fetch Net\" %d %d\n" 4 1)
			(fprintf out_port "ENDFIELD\n\n")
			
			(fprintf out_port "FIELD add_by_comp\n")
			(fprintf out_port "FLOC %d %d\n" 2 41)
			(fprintf out_port "MENUBUTTON \"Add by Comp\" %d %d\n" 12 2)
			(fprintf out_port "ENDFIELD\n\n")
			
			(fprintf out_port "FIELD add_by_net\n")
			(fprintf out_port "FLOC %d %d\n" 14 41)
			(fprintf out_port "MENUBUTTON \"Add by Net\" %d %d\n" 12 2)
			(fprintf out_port "ENDFIELD\n\n")
			
			(fprintf out_port "FIELD clear_all\n")
			(fprintf out_port "FLOC %d %d\n" 26 41)
			(fprintf out_port "MENUBUTTON \"Clear All\" %d %d\n" 8 2)
			(fprintf out_port "ENDFIELD\n\n")
			
			(fprintf out_port "FIELD swap\n")
			(fprintf out_port "FLOC %d %d\n" 36 41)
			(fprintf out_port "MENUBUTTON \"Swap\" %d %d\n" 8 2)
			(fprintf out_port "ENDFIELD\n\n")
			
			(fprintf out_port "FIELD delete_check\n")
			(fprintf out_port "FLOC %d %d\n" 44 41)
			(fprintf out_port "MENUBUTTON \"Del Check\" %d %d\n" 12 2)
			(fprintf out_port "ENDFIELD\n\n")
			
			(fprintf out_port "FIELD restore\n")
			(fprintf out_port "FLOC %d %d\n" 56 41)
			(fprintf out_port "MENUBUTTON \"Restore\" %d %d\n" 12 2)
			(fprintf out_port "ENDFIELD\n\n")
		(fprintf out_port "ENDGROUP\n\n")
		
		;;;;;;;;;;
		(fprintf out_port "GROUP \"Relative Propagation Delay\"\n")
		(fprintf out_port "FLOC %d %d\n" (rpd_floc_x = 1) (rpd_floc_y = 45))
		(fprintf out_port "TSSIZE %d %d\n" 33 12)
			;;;;;;;;;;
			(fprintf out_port "TEXT \"Matchgroup:\" \n")
			(fprintf out_port "FLOC %d %d\n" (rpd_floc_x + 1) (rpd_floc_y + 2))
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD mg_name\n") ; result	
			(fprintf out_port "FLOC %d %d\n" (rpd_floc_x + 10) (rpd_floc_y + 2))
			(fprintf out_port "STRFILLIN %d %d\n" 21 30)
			(fprintf out_port "ENDFIELD\n")
			
			;;;;;;;;;;
			(fprintf out_port "TEXT \"Delta:Toler (Min/Max):\" \n")
			(fprintf out_port "FLOC %d %d\n" (rpd_floc_x + 1) (rpd_floc_y + 5))
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD rpd_min\n") ; result	
			(fprintf out_port "FLOC %d %d\n" (rpd_floc_x + 17) (rpd_floc_y + 5))
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "TEXT \"/\" \n")
			(fprintf out_port "FLOC %d %d\n" (rpd_floc_x + 24) (rpd_floc_y + 5))
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD rpd_max\n") ; result	
			(fprintf out_port "FLOC %d %d\n" (rpd_floc_x + 25) (rpd_floc_y + 5))
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "ENDFIELD\n")
			
			;;;;;;;;;;
			(fprintf out_port "FIELD exe_rpd\n")
			(fprintf out_port "FLOC %d %d\n" (rpd_floc_x + 9) (rpd_floc_y + 8))
			(fprintf out_port "MENUBUTTON \"Create\" %d %d\n" 15 2)
			(fprintf out_port "ENDFIELD\n\n")
		(fprintf out_port "ENDGROUP\n\n")
		
		;;;;;;;;;;
		(fprintf out_port "GROUP \"Propagation Delay\"\n")
		(fprintf out_port "FLOC %d %d\n" (pd_floc_x = 36) (pd_floc_y = 45)) ; 13
		(fprintf out_port "TSSIZE %d %d\n" 33 12)
			;;;;;;;;;;
			(fprintf out_port "TEXT \"Netgroup:\" \n")
			(fprintf out_port "FLOC %d %d\n" (pd_floc_x + 1) (pd_floc_y + 2))
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD ng_name\n") ; result	
			(fprintf out_port "FLOC %d %d\n" (pd_floc_x + 10) (pd_floc_y + 2))
			(fprintf out_port "STRFILLIN %d %d\n" 21 30)
			(fprintf out_port "ENDFIELD\n")
			
			;;;;;;;;;;
			(fprintf out_port "TEXT \"Prop Delay (Min/Max):\" \n")
			(fprintf out_port "FLOC %d %d\n" (pd_floc_x + 1) (pd_floc_y + 5))
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD pd_min\n") ; result	
			(fprintf out_port "FLOC %d %d\n" (pd_floc_x + 17) (pd_floc_y + 5))
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "TEXT \"/\" \n")
			(fprintf out_port "FLOC %d %d\n" (pd_floc_x + 24) (pd_floc_y + 5))
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD pd_max\n") ; result	
			(fprintf out_port "FLOC %d %d\n" (pd_floc_x + 25) (pd_floc_y + 5))
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "ENDFIELD\n")
			
			;;;;;;;;;;
			(fprintf out_port "FIELD exe_pd\n")
			(fprintf out_port "FLOC %d %d\n" (pd_floc_x + 9) (pd_floc_y + 8))
			(fprintf out_port "MENUBUTTON \"Create\" %d %d\n" 15 2)
			(fprintf out_port "ENDFIELD\n\n")
		(fprintf out_port "ENDGROUP\n\n")
		
		(fprintf out_port "ENDTILE\n\n")
		(fprintf out_port "ENDFORM\n")
		(close out_port)
	)
)

(defun set_ecset_rpd_pd_Derek01082018 (ecset_rpd_pd_form)
	;;;;; setup grid
	p = make_formGridCol()

	p->fieldType = 'CHECKITEM
	p->colWidth = 1
	p->align = 'center
	p->headText = "C"
	p->scriptLabel = "net_sel"
	axlFormGridInsertCol(ecset_rpd_pd_form "netlist_grid" p)
	
	p->fieldType = 'TEXT
	p->colWidth = 8
	p->align = 'right
	p->headText = "Net Name"
	p->scriptLabel = "net_name"
	axlFormGridInsertCol(ecset_rpd_pd_form "netlist_grid" p)
	
	p->fieldType = 'TEXT
	p->colWidth = 6
	p->align = 'left
	p->headText = "Component Start"
	p->scriptLabel = "comp_start"
	axlFormGridInsertCol(ecset_rpd_pd_form "netlist_grid" p)
	
	p->fieldType = 'TEXT
	p->colWidth = 6
	p->align = 'left
	p->headText = "Component End"
	p->scriptLabel = "comp_end"
	axlFormGridInsertCol(ecset_rpd_pd_form "netlist_grid" p)
	
	;;;;;
	;axlFormGridInsertRows(ecset_rpd_pd_form "netlist_grid" 0 1)
	
	;;;;;
	axlFormGridEvents(ecset_rpd_pd_form "netlist_grid" '(mrowselect change rightpopup))
	
	;;;;;
	axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
	
	;;;;; setup the rest
	(axlFormSetField ecset_rpd_pd_form "net_all" t)
	(axlFormSetField ecset_rpd_pd_form "mg_name" "Matchgroup_name_[0]")
	(axlFormSetField ecset_rpd_pd_form "rpd_min" 0.0)
	(axlFormSetField ecset_rpd_pd_form "rpd_max" 1000.0)
	(axlFormSetField ecset_rpd_pd_form "ng_name" "Netgroup_name_0")
	(axlFormSetField ecset_rpd_pd_form "pd_min" 0.0)
	(axlFormSetField ecset_rpd_pd_form "pd_max" 90000.0)
)

(defun ecset_rpd_pd_form_action_Derek01082018 (ecset_rpd_pd_form)
	(case ecset_rpd_pd_form->curField
		("net_fetch"
			(rex_term = axlFormGetField(ecset_rpd_pd_form "net_search_bar"))
			(rex_term = (upperCase rex_term))
			
			(if (neq "*" rex_term) then
				(net_ls = axlDBGetDesign()->nets)
				rexCompile(rex_term)
				(net_ls = (mapcan (lambda (x) (when (rexExecute x->name) (list x))) net_ls))
				
				convert_net_id_ls_to_entry_to_grid_Derek01082018(net_ls)
			else
				println("Single * is not accepted. Please use the wildcard(?, *) properly")
			)
		)
		("add_by_comp"
			(comp_ls = nil)
			axlSetFindFilter(?enabled '("noall" "components") ?onButtons '("noall" "components"))
			axlClearSelSet()
			set_right_popup_Derek01082018()
			
			(while axlSelect()
				(comp_ls = axlGetSelSet())
				printf("%d Components are selected.\n" axlGetSelSetCount())
				printf("Selected components: %L\n" comp_ls~>name)
			)
			
			(if ((length comp_ls) > 1) then
				(net_ls = get_net_by_comp_Derek01082018(comp_ls))
				convert_net_id_ls_to_entry_to_grid_Derek01082018(net_ls)
			else
				println("Warning: You have to select >=2 comopnents.")
			)
			
			axlSetFindFilter(?enabled "noall" ?onButtons "noall")
			println("Add components process has been done.")
		)
		("add_by_net"
			(net_ls = tmp_ls = nil)
			axlSetFindFilter(?enabled '("noall" "nets") ?onButtons '("noall" "nets"))
			axlClearSelSet()
			set_right_popup_Derek01082018()
			
			(while axlSelect()
				(net_ls = axlGetSelSet())
				printf("%d nets are selected.\n" axlGetSelSetCount())
				printf("Selected nets: %L\n" net_ls~>name)
			)
			
			(when ((length net_ls) > 0)
				(net_ls = (setof x net_ls not_gnd_pwr_Derek01082018(x)))
				convert_net_id_ls_to_entry_to_grid_Derek01082018(net_ls)
			)
			
			axlSetFindFilter(?enabled "noall" ?onButtons "noall")
			println("Add nets process has beeb done.")
		)
		("clear_all"
			clear_all_grid_Derek01082018()
			println("All Data row has been deleted.")
		)
		("swap"
			swap_grid_status_Derek01082018()
			println("The check status has been swap")
		)
		("delete_check"
			delete_check_row_Derek01082018()
			println("The checked rows have been deleted.")
		)
		("restore"
			(if ((length restore_net_ls) > 1) then
				;;;; the first one would be the current one, so get the second one
				(is_same_first = is_same_add_to_grid_net_ls_Derek01082018(add_to_grid_net_ls (car restore_net_ls)))
				
				(if is_same_first then ;;;; if previous function is out of 'restore', then go into this block
					(new_add_to_grid_net_ls = (cadr restore_net_ls))
					(restore_net_ls = (cddr restore_net_ls))
				else ;;; if the previous command is 'restore', then go into this block
					(new_add_to_grid_net_ls = (car restore_net_ls))
					(restore_net_ls = (cdr restore_net_ls))
				)
				restore_net_to_grid_Derek01082018(new_add_to_grid_net_ls)
				printf("Restore successfully. You still have another %d phase to restore\n" (length restore_net_ls))
			else
				println("No previous phase can be extracted")
			)
		)
		("net_all"
			(when ecset_rpd_pd_form->curValue
				axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `net_category_all_Derek01082018 nil)
				axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				println("Set all net to checked status")
			)
		)
		("net_hs"
			(when ecset_rpd_pd_form->curValue
				axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `net_category_set_hs_Derek01082018 t)
				axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				println("Mark all high speed")
			)
		)
		("net_ls"
			(when ecset_rpd_pd_form->curValue
				axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `net_category_set_hs_Derek01082018 nil)
				axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				println("Mark all low speed")
			)
		)
		("exe_rpd"
			set_relative_propagation_delay_Derek01082018()
			println("Relative propagation delay has been set")
		)
		("exe_pd"
			set_propagation_delay_Derek01082018()
			println("Propagation delay has been set")
		)
		("netlist_grid"
			(case ecset_rpd_pd_form->curValue
				("SEPERATOR" println("This is a seperator. - Derek said."))
				("grid_mark_tar"
					axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `set_a_row_target_Derek01082018 t)
					axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				)
				("grid_unmark_tar"
					axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `set_a_row_target_Derek01082018 nil)
					axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				)
				("grid_check"
					axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `set_check_by_row_ls_Derek01082018 t)
					axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				)
				("grid_uncheck"
					axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `set_check_by_row_ls_Derek01082018 nil)
					axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				)
				("grid_sort"
					sort_grid_net_ls_Derek01082018()
					add_net_to_grid_Derek01082018()
				)
				("grid_sort_pair"
					sort_grid_net_pair_ls_Derek01082018()
					add_net_to_grid_Derek01082018()
				)
				;("edit_comp_start" edit_start_component(t))
				;("edit_comp_end" edit_start_component(nil))
				("grid_next"
					axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `set_next_matchgroup_Derek01082018 nil)
					axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
				)
				(t
					(caseq ecset_rpd_pd_form->col
						(1
							(check = ecset_rpd_pd_form->curValue)
							(row = ecset_rpd_pd_form->row)
							(net_name = (get_cell_value_Derek01082018 row 2))
							((car (exists x add_to_grid_net_ls (equal net_name x->net_id->name)))->check = check)
						)
					)
				)
			)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

(procedure is_same_add_to_grid_net_ls_Derek01082018(grid1_ls grid2_ls)
	(result = t)
	
	(unless (eqv (length grid1_ls) (length grid2_ls)) (result = nil))
	
	(when result
		(foreach (x y) grid1_ls grid2_ls
			(unless (and (eq x->net_id y->net_id) (eq x->check y->check))
				(result = nil)
			)
		)
	)

	result
)

(procedure get_next_row_sequence_Derek01082018(row_ls)
	(total_len = (length add_to_grid_net_ls))
	
	(pre_row = tmp_row_ls = next_row_ls = nil)
	(foreach row row_ls
		(if pre_row then
			(if (eqv pre_row (sub1 row)) then
				(tmp_row_ls = (append1 tmp_row_ls row))
			else
				(len = (length tmp_row_ls))
				(tmp_row_ls = (mapcar (lambda (x) (x + len)) tmp_row_ls))
				(next_row_ls = (append next_row_ls tmp_row_ls))
				(tmp_row_ls = (list row))
			)
			
			(pre_row = row)
		else
			(pre_row = row)
			(tmp_row_ls = (append1 tmp_row_ls row))
		)
	)
	
	;;;;; add the very last group to the temp list
	(when (dtpr tmp_row_ls)
		(len = (length tmp_row_ls))
		(tmp_row_ls = (mapcar (lambda (x) (x + len)) tmp_row_ls))
		(next_row_ls = (append next_row_ls tmp_row_ls))
	)
	
	(next_row_ls = (setof x next_row_ls (x <= total_len)))
	
	next_row_ls
)

(procedure set_next_matchgroup_Derek01082018(something)
	(len = (length add_to_grid_net_ls))
	(row_ls = nil)
	(for row 1 len (when (get_cell_value_Derek01082018 row 1) (row_ls = (append1 row_ls row))))
	printf("Checked rows: %L\n" row_ls)
	
	(new_row_ls = get_next_row_sequence_Derek01082018(row_ls))
	printf("Orig: %L\nNext: %L\n" row_ls new_row_ls)
	
	;;;;; waive off the original check
	(foreach row row_ls (set_cell_value_Derek01082018 row 1 nil))
	
	;;;;; shift to the next check
	(foreach row new_row_ls (set_cell_value_Derek01082018 row 1 t))
	
	(unless (zerop (length new_row_ls))
		(mg_name = (axlFormGetField ecset_rpd_pd_form "mg_name"))
		
		(if (zerop (strlen mg_name)) then
			(first_check_net_name = (get_cell_value_Derek01082018 (car new_row_ls) 2))
			(no_tail = (buildString (reverse (cdr (reverse (parseString first_check_net_name "_")))) "_"))
			(new_mg_name = (strcat "MG_" no_tail "[0]"))
			(axlFormSetField ecset_rpd_pd_form "mg_name" new_mg_name)
		else
			(term = be_term = af_term = nil)
			(when (pos = (nindex mg_name "[")) (be_term = (substring mg_name 1 pos)))
			(af_term = (rindex mg_name "]"))
			(unless (or (null be_term) (null af_term))
				(term = (substring mg_name (add1 (strlen be_term)) ((strlen mg_name) - (strlen be_term) - (strlen af_term))))
			)
			
			(new_term = nil)
			(when (stringp term)
				(if (index term "-") then
					(num1 = (car (parseString term "-")))
					(num2 = (cadr (parseString term "-")))
					
					(when num1 (num1 = (atoi num1)))
					(when num2 (num2 = (atoi num2)))
					
					(if (or (null num1) (null num2)) then
						println("For the form [?-?], ? mark has to be a number")
					else
						(dist = (add1 (abs (num1 - num2))))
						(num1 = (num1 + dist))
						(num2 = (num2 + dist))
						(sprintf new_term "%s%d-%d%s" be_term num1 num2 af_term)
						(axlFormSetField ecset_rpd_pd_form "mg_name" new_term)
					)
				else
					(num = (atoi term))
					
					(if num then
						(num = (add1 num))
						(sprintf new_term "%s%d%s" be_term num af_term)
						(axlFormSetField ecset_rpd_pd_form "mg_name" new_term)
					else
						println("For the form [?], Please fill up the ? as a number")
					)
				)
			)
			
			(unless new_term
				println("Matchgroup name didn't be updated. Please follow the format '*[?]*' or '*[?-?]*' to do the matchgroup name prediction.(Hint: replace ? to integer)")
			)
		)
	)
)

(procedure set_a_row_target_Derek01082018(target)
	(row_ls = (axlFormGridSelected ecset_rpd_pd_form "netlist_grid"))
	(foreach row row_ls set_cell_value_Derek01082018(row 0 target))
)

;(procedure edit_start_component(is_start)
;	(comp_ls = nil)
;	(row_ls = (axlFormGridSelected ecset_rpd_pd_form "netlist_grid"))
;	
;	axlSetFindFilter(?enabled '("noall" "components") ?onButtons '("noall" "components"))
;	axlClearSelSet()
;	
;	(while axlSelect()
;		(comp_ls = axlGetSelSet())
;		printf("%d Components are selected.\n" axlGetSelSetCount())
;		printf("Selected components: %L\n" comp_ls~>name)
;	)
;	
;	(if (onep (length comp_ls)) then
;		(len = (length add_to_grid_net_ls))
;		(sel_comp_id = (car comp_ls))
;		(sel_pin_ls = sel_comp_id->pins)
;		
;		(for row 1 len
;			(when (memv row row_ls)
;				(net_name = (get_cell_value_Derek01082018 row 2))
;				(net_entry = (car (exists x add_to_grid_net_ls (equal x->net_id->name net_name))))
;				
;				(if (memq sel_comp_id (list net_entry->pin1_id->component net_entry->pin2_id->component)) then
;					printf("Net: %s has already included component: %s\n" net_name sel_comp_id->name)
;				else
;					(net_pin_ls = (axlPinsOfNet net_entry->net_id 'pin))
;					(sel_pin = (car (exists x net_pin_ls (memq x sel_pin_ls))))
;					(if sel_pin then
;						(if is_start
;							((car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->pin1_id = sel_pin)
;							((car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->pin2_id = sel_pin)
;						)
;						
;						(comp1 = (car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->pin1_id->component->name)
;						(comp2 = (car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->pin2_id->component->name)
;						printf("Update net: %s. Component: %L\n" net_name (list comp1 comp2))
;					else
;						printf("Net: %s doesn't connect to component: %s\n" net_name sel_comp_id->name)
;					)
;				)
;			)
;		)
;		
;		add_net_to_grid_Derek01082018()
;	else
;		println("You can only pick up one component")
;	)
;)

(procedure sort_slots_net_tail_number_Derek01082018(x y)
	(net1_num = net2_num = nil)
	(net1_name = x->net_id->name)
	(net2_name = y->net_id->name)
	
	rexCompile("[0-9]+$")
	
	(when (rexExecute net1_name) (net1_num = (atoi rexSubstitute("\\0"))))
	(when (rexExecute net2_name) (net2_num = (atoi rexSubstitute("\\0"))))
	
	(if (and net1_num net2_num) then
		(if (eqv net1_num net2_num) then
			(tail1 = (rindex net1_name "_"))
			(tail2 = (rindex net2_name "_"))
			
			(negativep (strcmp tail1 tail2))
		else
			(net1_num < net2_num)
		)
	else
		nil
	)
)

(procedure sort_grid_net_ls_Derek01082018()
	(row_ls = (axlFormGridSelected ecset_rpd_pd_form "netlist_grid"))
	printf("Selected rows: %L\n" row_ls)
	
	(if (or (zerop (length row_ls)) (onep (length row_ls))) then
		(cal_ls = add_to_grid_net_ls)
	else
		(row_net_name_ls = (mapcar (lambda (x) (get_cell_value_Derek01082018 x 2)) row_ls))
		(cal_ls = (mapcan (lambda (x) (when (member x->net_id->name row_net_name_ls) (list x))) add_to_grid_net_ls))
	)
	
	(when ((length cal_ls) > 0)
		(pre_cal_ls = cal_ls)
		(cal_ls = (sort cal_ls (lambda (x y) (negativep (strcmp x->net_id->name y->net_id->name)))))
		
		;;;;; check whether to reverse
		(move_ls = (mapcar (lambda (x y) (eq x->net_id y->net_id)) pre_cal_ls cal_ls))
		(when (forall x move_ls x) (cal_ls = (reverse cal_ls)))
		
		(if (or (zerop (length row_ls)) (onep (length row_ls))) then
			(add_to_grid_net_ls = cal_ls)
		else
			(result_ls = nil)
			(row_cnt = 0)
			(foreach entry add_to_grid_net_ls
				(if (member entry->net_id->name row_net_name_ls)
					(result_ls = (append1 result_ls (nth (row_cnt++) cal_ls)))
					(result_ls = (append1 result_ls entry))
				)
			)
			(add_to_grid_net_ls = result_ls)
		)
	)
)

(procedure sort_grid_net_pair_ls_Derek01082018()
	(row_ls = (axlFormGridSelected ecset_rpd_pd_form "netlist_grid"))
	printf("Selected rows: %L\n" row_ls)
	
	(if (or (zerop (length row_ls)) (onep (length row_ls))) then
		(cal_ls = add_to_grid_net_ls)
	else
		(row_net_name_ls = (mapcar (lambda (x) (get_cell_value_Derek01082018 x 2)) row_ls))
		(cal_ls = (mapcan (lambda (x) (when (member x->net_id->name row_net_name_ls) (list x))) add_to_grid_net_ls))
	)
	
	(when ((length cal_ls) > 0)
		(pre_cal_ls = cal_ls)
		(cal_ls = (sort cal_ls 'sort_slots_net_tail_number_Derek01082018))
		
		;;;;; to reverse the list if the sort result and the original element order remain the same
		(move_ls = (mapcar (lambda (x y) (eq x->net_id y->net_id)) pre_cal_ls cal_ls))
		(when (forall x move_ls x) (cal_ls = (reverse cal_ls)))
		
		(if (or (zerop (length row_ls)) (onep (length row_ls))) then
			(add_to_grid_net_ls = cal_ls)
		else
			(result_ls = nil)
			(row_cnt = 0)
			(foreach entry add_to_grid_net_ls
				(if (member entry->net_id->name row_net_name_ls)
					(result_ls = (append1 result_ls (nth (row_cnt++) cal_ls)))
					(result_ls = (append1 result_ls entry))
				)
			)
			(add_to_grid_net_ls = result_ls)
		)
	)
)

(procedure convert_net_id_ls_to_entry_to_grid_Derek01082018(net_ls)
	(if ((length net_ls) > 0) then
		(when (car net_ls)->objType (net_ls = transform_net_ls_to_entry_Derek01082018(net_ls)))
		
		(add_to_grid_net_ls = (append net_ls add_to_grid_net_ls))
		;;;;;
		singlify_add_to_grid_net_ls_Derek01082018()
		;;;;;
		add_net_to_grid_Derek01082018()
		printf("New %d were added, now %d nets in the grid\n" (length net_ls) (length add_to_grid_net_ls))
	else
		println("No elements in the selected net list")
	)
)

(procedure set_check_by_row_ls_Derek01082018(check)
	(row_ls = (axlFormGridSelected ecset_rpd_pd_form "netlist_grid"))
	(foreach row row_ls (set_cell_value_Derek01082018 row 1 check))
)

(procedure get_checked_net_entry_Derek01082018()
	(entry_ls = nil)
	(len = (length add_to_grid_net_ls))
	(net_name_ls = nil)
	
	(when (len > 0)
		(for row 1 len
			(when (get_cell_value_Derek01082018 row 1)
				(net_name = (get_cell_value_Derek01082018 row 2))
				(net_name_ls = (append1 net_name_ls net_name))
			)
		)
		
		(entry_ls = (mapcan (lambda (x) (when (member x->net_id->name net_name_ls) (list x))) add_to_grid_net_ls))
	)
	
	entry_ls
)

(procedure is_proper_manhattan(net_entry_ls pd_max)
	(manha_net_ls = to_check = nil)
	(max_manha = 0)
	
	(foreach entry net_entry_ls
		(net1 = entry->pin1_id->net)
		(net2 = entry->pin2_id->net)
		(net1_manha = (1.3 * (caddr (axlDBGetManhattan net1))))
		(net2_manha = (1.3 * (caddr (axlDBGetManhattan net2))))
		
		(if (eq net1 net2)
			(manha_net_ls = (append1 manha_net_ls net1_manha))
			(manha_net_ls = (append1 manha_net_ls (net2_manha + net2_manha)))
		)
	)
	
	printf("The inputed max propagation delay is %f\n" pd_max)
	(foreach (entry manha) net_entry_ls manha_net_ls
		(when (manha > pd_max)
			(max_manha = (max max_manha manha))
			(unless to_check (to_check = t))
		)
	)
	
	(when to_check
		(sprintf message "The maximun manhattan of nets is <%f>, but the max propagation delay is <%f>. Do you want to keep continue?" max_manha pd_max)
		(to_check = axlUIYesNo(message))
		(to_check = (not to_check))
	)
	
	(not to_check)
)

(procedure set_propagation_delay_Derek01082018()
	(prog ()
		(ng_name = axlFormGetField(ecset_rpd_pd_form "ng_name"))
		(pd_min = axlFormGetField(ecset_rpd_pd_form "pd_min"))
		(pd_max = axlFormGetField(ecset_rpd_pd_form "pd_max"))
		(pp_ls = pd_value = opt = nil)
		(net_entry_ls = get_checked_net_entry_Derek01082018())
		(sprintf pd_value "AD:AR:%.2f MIL:%.2f MIL" pd_min pd_max)
		
		(unless ((strlen ng_name) > 0)
			println("Please fill up the netgroup name or prop delay min/max")
			return(nil)
		)
		
		(unless is_proper_manhattan(net_entry_ls pd_max)
			println("The netgroup process has been canceled")
			return(nil)
		)
		
		(unless ((length net_entry_ls) > 0)
			println("You have to have at least one net to use this function.")
			return(nil)
		)
		
		(ng_id = axlDBCreateGroup(ng_name "net_group" nil))
		(pp_ls = (mapcar (lambda (x) (axlPinPair x->pin1_id x->pin2_id)) net_entry_ls))
		
		(unless ng_id
			(opt = axlUIYesNo(strcat("The netgroup \"" ng_name "\" is exists. Do you want to add checked net to this netgroup?")))
			(when opt (ng_id = (car (axlSelectByName "NET_GROUP" ng_name nil))))
		)
		
		(when ng_id
			(axlDBAddGroupObjects ng_id net_entry_ls~>net_id)
			(axlDBAddProp ng_id (list 'Propagation_Delay pd_value))
			(foreach pp_id pp_ls (axlDBAddProp pp_id (list 'Propagation_Delay pd_value)))
		)
	)
)

(procedure set_relative_propagation_delay_Derek01082018()
	(prog ()
		(mg_name = axlFormGetField(ecset_rpd_pd_form "mg_name"))
		(delta_min = axlFormGetField(ecset_rpd_pd_form "rpd_min"))
		(delta_max = axlFormGetField(ecset_rpd_pd_form "rpd_max"))
		(pp_ls = rpd_value = opt = nil)
		(net_entry_ls = get_checked_net_entry_Derek01082018())
		
		(unless ((strlen mg_name) > 0)
			println("Please fill up the matchgroup name or delta min/max")
			return(nil)
		)
		
		(if (delta_min >= 0)
			(sprintf rpd_value "%s:G:AD:AR:%.2f MIL:%.2f MIL" mg_name delta_min delta_max)
			(sprintf rpd_value "%s:G:AD:AR::%.2f MIL" mg_name delta_max)
		)
		
		(unless ((length net_entry_ls) > 0)
			println("You have to have at least one net to use this function.")
			return(nil)
		)
		
		(mg_id = axlMatchGroupCreate(mg_name))
		(unless mg_id
			(opt = axlUIYesNo(strcat("The matchgroup \"" mg_name "\" is exists. Do you want to add checked net to this matchgroup?")))
			(when opt (mg_id = (car (axlSelectByName "MATCH_GROUP" mg_name nil))))
		)
		
		(pp_ls = (mapcar (lambda (x) (axlPinPair x->pin1_id x->pin2_id)) net_entry_ls))
		(when mg_id
			(axlMatchGroupAdd mg_id pp_ls)
			(axlDBAddProp mg_id (list 'RELATIVE_PROPAGATION_DELAY rpd_value))
			(foreach pp_id pp_ls (axlMatchGroupProp mg_id pp_id rpd_value))
		)
	)
)

(procedure transform_net_ls_to_entry_Derek01082018(net_ls)
	(net_entry_ls = nil)
	
	(foreach net_id net_ls
		(when (pin_2 = get_farest_2_pin_Derek01082018(net_id))
			(net_entry = make_net_comp_slots(?net_id net_id ?pin1_id (car pin_2) ?pin2_id (cadr pin_2) ?target nil ?check t))
			(net_entry_ls = (append1 net_entry_ls net_entry))
		)
	)
	
	net_entry_ls
)

(procedure get_farest_2_pin_Derek01082018(net_id)
	(max_pp_2 = nil)
	(pin_ls = (axlPinsOfNet net_id 'pin))
	(len = (sub1 (length pin_ls))) ;; the counting should start from 0 and so sub 1
	
	(unless (onep net_id->nBranches)
		printf("Multiple branches in net: %s. The pinpair will be regard as the furthest 2 pins\n" net_id->name)
	)
	
	(if (len >= 1) then
		(max_pp_2 = (list (car pin_ls) (cadr pin_ls)))
		(max_pp_val = (axlDBPinPairLength (car max_pp_2) (cadr max_pp_2)))
		
		(for i 0 len
			(for j (add1 i) len
				(when ((tmp = (axlDBPinPairLength (nth i pin_ls) (nth j pin_ls))) > max_pp_val)
					(max_pp_val = tmp)
					(max_pp_2 = (list (nth i pin_ls) (nth j pin_ls)))
				)
			)
		)
	else
		printf("Less then 2 pins in net: %s\n" net_id->name)
	)
	
	max_pp_2
)

(procedure singlify_add_to_grid_net_ls_Derek01082018()
	(tmp_ls = (maplist (lambda (x) (if (member (car x)->net_id (cdr x)~>net_id) nil (car x))) add_to_grid_net_ls))
	(add_to_grid_net_ls = (mapcan (lambda (x) (when x (list x))) tmp_ls))
)

(procedure net_category_set_hs_Derek01082018(check)
	(foreach entry add_to_grid_net_ls
		(entry->check = (eq check is_high_speed_Derek01082018(entry->net_id)))
	)
	add_net_to_grid_Derek01082018()
)

(procedure net_category_all_Derek01082018(temp)
	(len = (length add_to_grid_net_ls))
	(when (len > 0) (for row 1 len set_cell_value_Derek01082018(row 1 t)))
)

(procedure swap_grid_status_Derek01082018()
	axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `swap_cell_check_Derek01082018 nil)
	axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
)

(procedure clear_all_grid_Derek01082018()
	printf("Total %d rows were deleted\n" (length add_to_grid_net_ls))
	
	(axlFormGridDeleteRows ecset_rpd_pd_form "netlist_grid" 1 (length add_to_grid_net_ls))
	(axlFormGridUpdate ecset_rpd_pd_form "netlist_grid")
	(add_to_grid_net_ls = nil)
)

(procedure delete_check_row_Derek01082018()
	(when (len > 0)
		(deleted_net_name_ls = (mapcan (lambda (x) (when x->check (list x->net_id->name))) add_to_grid_net_ls))
		(new_add_to_grid_net_ls = (mapcan (lambda (x) (unless x->check (list x))) add_to_grid_net_ls))
		
		(if new_add_to_grid_net_ls then
			add_net_to_grid_Derek01082018(new_add_to_grid_net_ls)
		else
			(restore_net_ls = (reverse (append1 (reverse restore_net_ls) add_to_grid_net_ls)))
			clear_all_grid_Derek01082018()
		)
		
		printf("Deleted net name:\n%L\n" deleted_net_name_ls)
	)
)

(procedure get_cell_value_Derek01082018(row col)
	(when (integerp row)
		cell = axlFormGridNewCell()
		
		cell->row = row
		cell->col = col
		
		(if (onep col)
			(axlFormGridGetCell ecset_rpd_pd_form "netlist_grid" cell)->check
			(axlFormGridGetCell ecset_rpd_pd_form "netlist_grid" cell)->value
		)
	)
)

(procedure swap_cell_check_Derek01082018(textCol)
	(foreach entry add_to_grid_net_ls (entry->check = (not entry->check)))
	add_net_to_grid_Derek01082018()
)

(procedure set_cell_value_Derek01082018(row col obj_id)
	(cell = axlFormGridNewCell())
	(cell->row = row)
	(net_name = (get_cell_value_Derek01082018 row 2))
	
	(caseq col
		(0
			(bg_color = (if obj_id 'yellow nil))
			(cell->value = nil)
			(cell->backColor = bg_color)
			(cell->col = 2)
			axlFormGridBatch(cell)
			(cell->col = 3)
			axlFormGridBatch(cell)
			(cell->col = 4)
			axlFormGridBatch(cell)
			
			(when (stringp net_name) ;;;; when no row in the grid, net_name will be nil
				((car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->target = obj_id)
			)
		)
		(1
			(cell->col = 1)
			(cell->backColor = nil)
			(cell->check = obj_id)
			(cell->value = nil)
			axlFormGridBatch(cell)
			
			(when (stringp net_name) ;;;; when no row in the grid, net_name will be nil
				((car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->check = obj_id)
			)
		)
		(2
			(cell->col = 2)
			(cell->value = obj_id->name)
			axlFormGridBatch(cell)
			
			(when (stringp net_name) ;;;; when no row in the grid, net_name will be nil
				((car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->net_id = obj_id)
			)
		)
		(3
			(cell->col = 3)
			(cell->value = obj_id->component->name)
			axlFormGridBatch(cell)
			
			(when (stringp net_name) ;;;; when no row in the grid, net_name will be nil
				((car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->pin1_id = obj_id)
			)
		)
		(4
			(cell->col = 4)
			(cell->value = obj_id->component->name)
			axlFormGridBatch(cell)
			
			(when (stringp net_name) ;;;; when no row in the grid, net_name will be nil
				((car (exists x add_to_grid_net_ls (equal x->net_id->name net_name)))->pin2_id = obj_id)
			)
		)
		(t
			printf("The col number %d does not allow\n" col)
		)
	)
)

(procedure set_multiple_cell_value_Derek01082018(textCol)
	(len = (length add_to_grid_net_ls))
	(row_cnt = 1)
	
	(foreach entry add_to_grid_net_ls
		(net_id = entry->net_id)
		(pin1_id = entry->pin1_id)
		(pin2_id = entry->pin2_id)
		(target = entry->target)
		(check = entry->check)
		
		(when (negativep (strcmp pin1_id->component->name pin2_id->component->name))
			(tmp = entry->pin1_id)
			(entry->pin1_id = entry->pin2_id)
			(entry->pin2_id = tmp)
			
			(pin1_id = entry->pin1_id)
			(pin2_id = entry->pin2_id)
		)
		
		set_cell_value_Derek01082018(row_cnt 0 target)
		set_cell_value_Derek01082018(row_cnt 1 check)
		set_cell_value_Derek01082018(row_cnt 2 net_id)
		set_cell_value_Derek01082018(row_cnt 3 pin1_id)
		set_cell_value_Derek01082018(row_cnt 4 pin2_id)
		
		(row_cnt = (add1 row_cnt))
	)
)

(procedure restore_net_to_grid_Derek01082018(new_add_to_grid_net_ls)
	clear_all_grid_Derek01082018()
	(add_to_grid_net_ls = new_add_to_grid_net_ls)
	(len = (length add_to_grid_net_ls))
	
	axlFormGridInsertRows(ecset_rpd_pd_form "netlist_grid" 0 len)
	axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `set_multiple_cell_value_Derek01082018 nil)
	axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
)

(procedure add_net_to_grid_Derek01082018(@optional (new_add_to_grid_net_ls nil))
	;;;;; if new is nil, then purly update the current status
	;;;;; otherwise, update the state to a new stage
	(unless new_add_to_grid_net_ls
		(new_add_to_grid_net_ls = add_to_grid_net_ls)
	)
	
	(when (dtpr add_to_grid_net_ls)
		clear_all_grid_Derek01082018()
		(restore_net_ls = (reverse (append1 (reverse restore_net_ls) new_add_to_grid_net_ls)))
		(add_to_grid_net_ls = new_add_to_grid_net_ls)
		
		axlFormGridInsertRows(ecset_rpd_pd_form "netlist_grid" 0 (length add_to_grid_net_ls))
		;axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
		axlFormGridSetBatch(ecset_rpd_pd_form "netlist_grid" `set_multiple_cell_value_Derek01082018 nil)
		axlFormGridUpdate(ecset_rpd_pd_form "netlist_grid")
	)
)

(procedure is_high_speed_Derek01082018(net_id)
	; net_id = (car axlGetSelSet())
	(result = t)
	(phy_cset = axlNetClassGet(net_id 'physical t)->prop->PHYSICAL_CONSTRAINT_SET)
	;printf("N: %s, Phy: %L\n" net_id->name phy_cset)
	
	(if (and (stringp phy_cset) (index phy_cset "Z")) then
		rexCompile("Z[0-9]+")
		rexExecute(phy_cset)
		(impedance = rexSubstitute("\\0"))
		(impedance = (substring impedance 2))
		(impedance = (atoi impedance))
		;printf("N: %s, Z: %L\n" net_id->name impedance)
		(result = (and (integerp impedance) (impedance >= min_high_speed_impedence)))
	else
		(result = nil)
	)
	
	result
)

(procedure not_gnd_pwr_Derek01082018(net_id)
	(prog ()
		(phy_cset = axlNetClassGet(net_id 'physical t)->name)
		
		(cond 
			((equal "" net_id->name) return(nil))
			((equal "GND" net_id->name) return(nil))
			((stringp phy_cset) return((not (index phy_cset "PWR"))))
			(t return(t))
		)
	)
)

(procedure get_net_by_comp_Derek01082018(comp_ls)
	(net_ls = nil)
	(len = (sub1 (length comp_ls)))
	
	(when (len > 0)
		(for i 0 len
			(for j (add1 i) len
				(comp_i = (nth i comp_ls))
				(comp_j = (nth j comp_ls))
				;;; get a net group
				(net1_ls = comp_i->pins~>net)
				(net1_ls = (setof x net1_ls not_gnd_pwr_Derek01082018(x)))
				;;; get another net group
				(net2_ls = comp_j->pins~>net)
				(net2_ls = (setof x net2_ls not_gnd_pwr_Derek01082018(x)))
				;;; merge net group
				(net_joint_ls = nil)
				(foreach net1 net1_ls
					(cond
						((memq net1 net2_ls)
							(net_joint_ls = (append1 net_joint_ls net1))
						)
						((xnet = (car (exists x net2_ls~>xnet (memq net1 x->groupMembers))))
							(net_joint_ls = (append1 net_joint_ls xnet))
						)
					)
				)
				;;;
				(net_entry_ls = nil)
				(foreach net_id net_joint_ls
					(pin_ls = (axlPinsOfNet net_id 'pin))
					(pin_i = (car (exists x pin_ls (eq x->component comp_i))))
					(pin_j = (car (exists x pin_ls (eq x->component comp_j))))
					(net_entry = make_net_comp_slots(?net_id net_id ?pin1_id pin_i ?pin2_id pin_j ?target nil ?check t))
					(net_entry_ls = (append1 net_entry_ls net_entry))
				)
				;;;
				(net_ls = (append net_ls net_entry_ls))
			)
		)
	)
	
	net_ls
)

(defun ecset_pd_rpd_main_Derek01082018 ()
	(prog ()
		init_Derek01082018()
		
		;;;;; create the rko form
		(ecset_rpd_pd_form_builder_Derek01082018)
		
		;;;;; build up the form
		(ecset_rpd_pd_form = (axlFormCreate (gensym) ecset_rpd_pd_form_name '("east" "outer") 'ecset_rpd_pd_form_action_Derek01082018 t))
		
		;;;;; setup form
		set_ecset_rpd_pd_Derek01082018(ecset_rpd_pd_form)
		
		;;;;; display
		axlFormDisplay(ecset_rpd_pd_form)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ENd of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

; (ecset_pd_rpd_main_Derek01082018)
(axlCmdRegister "ecset_pd_rpd" 'ecset_pd_rpd_main_Derek01082018)
; skill encrypt( "C:/skill/ecset_pd_rpd_v1.il" "C:/skill/ecset_pd_rpd_v1.ile")
; (load "ecset_pd_rpd_v1.il")
; (load "ecset_pd_rpd_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup