;/********************************************************************************************** General Information
;*			Editor: Derek Hsu
;*	 Starting Date: 04/13/2017
;*	  Introduction: Seek multi clines by type, which is Single or Differential(85, 95, 100 ohm), on each layer. 
;*					said clines has to fit proper length as the following describe.
;*		   Purpose: Make this time consuming process automatically done by Skill program.
;*		  Standard:
;*					1. For DDR, Clines length close to 2000 mil
;*					2. For else, Clines length greater then 2000 and smaller then 3000 (mil). Closing 3000 mil is better
;*	  Used Command:
;*					1. axlDbGetDesign()
;*					
;**********************************************************************************************/

;********************************************************************************************** Progress
;	progress
;	
;	store the original setting
;	
;	loop through etch layer {
;		(get all clines)
;			- (or (get all clines with the length between 2000 and 3000) (get if the clines is in DDR, then to be 2000))
;		(get net by clines)
;			- (the segment of the net can't be more than 4)
;		(find two pins from each nets)
;		(find closest ground pin in area 60 to 80 mil)
;		(store it)
;		(sort it by Z(ohm), length of cline, length to gnd pin)
;	}
;	
;	report
;
;	set back the original setting
;**********************************************************************************************

;********************************************************************************************** Data Format
;
;	definition:
;	TDR_Table=( (layer ((ohm cline length pin probe)(ohm cline length pin probe) (ohm cline length pin probe)))
;			  (layer ((ohm cline length pin probe)(ohm cline length pin probe) (ohm cline length pin probe)))
;			  (layer ((ohm cline length pin probe)(ohm cline length pin probe) (ohm cline length pin probe)))
;			  (layer ((ohm cline length pin probe)(ohm cline length pin probe) (ohm cline length pin probe))))
;	data type = (ohm: string, net: string(dbid), pin: string(dbid), probe: string(dbid))
;
;	output: 
;	TDR_Table=( ("Top" ((50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200)))
;			  ("L3_Int3" ((50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200)))
;			  ("L5_Int5" ((50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200)))
;			  ("Bottom" ((50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200)
;					 (50 "Cline_name" 2999.33 100:100 200:200))))
;
;	schematic
;	(('layer "Top") ('clines ((('ohm 50) ('cline "P1V2_VDDQ_FD") ('length 2999.33) ('pin x:y) ('probe x:y))
;							 (('ohm 90) ('cline "P1V2_VDDQ_FD") ('length 2999.33) ('pin x:y) ('probe x:y))
;							 (('ohm 85) ('cline "P1V2_VDDQ_FD") ('length 2999.33) ('pin x:y) ('probe x:y))
;							 (('ohm 100) ('cline "P1V2_VDDQ_FD") ('length 2999.33) ('pin x:y) ('probe x:y))))
;
;********************************************************************************************** setup information

;********************************************************************************************** version control



;;;;;(load "TDR_test_report.il")

(setq filename "TDR_test_report")
(setq version "1.0")

printf( "%s ,ver: %s\n\n", filename version)

;********************************************************************************************** main code start from here

(defun _saveSelSet ()
    (list (axlGetSelSet) (axlGetFindFilter nil) (axlGetFindFilter t)))
	
(defun _restoreSelSet (oldSelSet "l")
    (axlSetFindFilter ?enabled (cons "noall" (nth 1 oldSelSet))
		      ?onButtons (cons "noall" (nth 2 oldSelSet)))
    (axlSingleSelectObject (car oldSelSet))
    t)

(procedure get_gnd_pin(layer)
	(let ((net_gnd_list list()) 
		(pin_gnd_list list()) 
		(pin_gnd_layer_list list()) 
		(is_mirr (equal layer "BOTTOM")))
			; clear the selected object
			(axlClearSelSet)
			axlSetFindFilter( ?enabled (list "noall" "nets") ?onButtons (list "noall" "nets"))
			(axlAddSelectAll)
			;printf("There are %d nets on %s.\n" length(axlGetSelSet()) layer)
			(foreach one axlGetSelSet() 
					(when (equal one->name "GND") 
							(setq net_gnd_list append1(net_gnd_list one))))
			;printf("There are %d GND nets on %s.\n" length(net_gnd_list) layer)
			(foreach one net_gnd_list 
					(setq pin_gnd_list 
							append(pin_gnd_list axlPinsOfNet(one 'pin))))
			;printf("There are totally %d GND pins.\n" length(pin_gnd_list))
			(foreach one pin_gnd_list 
					(when (eq one->isMirrored is_mirr) 
							(setq pin_gnd_layer_list append1(pin_gnd_layer_list one))))
			;printf("There are %d GND pins on %s.\n" length(pin_gnd_layer_list) layer)
			pin_gnd_layer_list)
)
	
(defun global_variable ()

	(setq TDR_Table makeTable("main")); this is the main table what is to store the result
	(setq tdr_ubound_len 4000)
	(setq tdr_lbound_len 2000)
	(setq tdr_fit_len 3000)
	(setq ohm_standard 35)
	(setq measure_ubound 80)
	(setq measure_lbound 60)
	(setq boardname axlCurrentDesign())
	(setq boardname_str strcat( boardname ".brd"))
	(setq etch_layer_list axlGetParam("paramLayerGroup:ETCH")->groupMembers)
	(setq oldSetData (_saveSelSet))
	(setq pin_gnd_top (get_gnd_pin "TOP"))
	(setq pin_gnd_bot (get_gnd_pin "BOTTOM"))
)

(procedure set_visible_layer(layer_group layer_name) ; etch top
	
	(foreach this_layer etch_layer_list
		;"paramLayerGroup:ETCH/paramLayer:TOP"
		(setq param strcat("paramLayerGroup:" layer_group "/paramLayer:" this_layer))
		(setq etch_show (axlGetParam param))
		
		;printf("\nparam: %s", param) ; this is a testing
		etch_show->visible = (equal (upperCase this_layer) (upperCase layer_name))
		;haha = if((etch_show->visible) "true" "false")
		;printf("\n%s %s %s", (upperCase this_layer) (upperCase layer_name) haha)
		(axlSetParam etch_show)
	)
	
	;visible has to be updated after changing the visible setting
	axlVisibleUpdate(t)
)

(defun get_filter_dbid_list (feature)
	(axlClearSelSet)
	(axlSetFindFilter ?enabled (list "noall" feature) ?onButtons (list feature)) ; may use invisible
	(axlAddSelectAll)
	(setq sel_set (axlGetSelSet)) ; (setq a (axlGetSelSet))
	;printf("\n%s", car(sel_set))
	sel_set)

(procedure get_ohm_byPhysical( phy) ; CRITICAL_W50/S10[10] , I2C-DIFF_W50D15/S15[15]
	(let (result)
		rexCompile( "W[0-9]+[^0-9]" )
		rexExecute(phy) ; rexExecute("I2C-DIFF_W50D15/S15[15]") / rexExecute("CRITICAL_W50/S10[10]")
		;get number from W50D
		result = (when rexExecute(phy) 
						(setq result rexSubstitute( "\\0" )) 
						(setq result substring(result 2 strlen(result)-2))
						(atoi result))
		result)
)

(procedure between(val lb ub) (and (geqp val lb) (leqp val ub)))

(defun get_closest_pinProbePair (pin_list) ; there are only two pins in the list
	(let ((fit_pin nil) (fit_probe nil))
		(foreach end pin_list ; each line has a right end and left end
			cond(((end->isMirrored == nil) ; this pin is on the top
					(foreach probe pin_gnd_top
						(when (between axlDistance(end->xy probe->xy) measure_lbound measure_ubound)
							;printf("1: %s, 2: %s, Dis: %f.\n", end->name probe->name axlDistance(end->xy probe->xy))
							(setq fit_pin end)
							(setq fit_probe probe))))
				 ((end->isMirrored == t) ; this pin is on the bottom
					(foreach probe pin_gnd_bot 
						(when (between axlDistance(end->xy probe->xy) measure_lbound measure_ubound)
							;printf("1: %s, 2: %s, Dis: %f.\n", end->name probe->name axlDistance(end->xy probe->xy))
							(setq fit_pin end)
							(setq fit_probe probe))))
			)
		)
	(list fit_pin fit_probe))
)

(procedure is_qualified_net(net cline ohm pin_list all_ohm_type)
	(and (greaterp ohm ohm_standard) (eq length(pin_list) 2))
)

(defun through_layer ()
	axlClearSelSet()
	;(set_visible_layer "ETCH" "L14_Int6")
	(setq all_cline (get_filter_dbid_list "CLINES"))
	printf("The number of all_cline is %d\n", length(all_cline))
	(setq all_cline_inRange remove( nil mapcar( 'lambda( (x) 
												(if (and (greaterp axlDBGetLength(x) tdr_lbound_len) 
												(lessp axlDBGetLength(x) tdr_ubound_len)) x nil)) all_cline)))
	printf("The number of all_cline_inRange is %d\n", length(all_cline_inRange))
	(setq all_net_inRange mapcar( 'lambda( (x) x->net) all_cline_inRange ))
	(setq all_ohm_inRange mapcar( 'lambda( (x) axlNetClassGet(x 'physical t)->name) all_net_inRange))
	(setq all_ohm_inRange mapcar( 'lambda( (x) get_ohm_byPhysical(x)) all_ohm_inRange))
	printf("The number of all_ohm_inRange is %d\n", length(all_ohm_inRange))
	
	; reset the temp table to store new data
	(setq all_ohm_type '())
	(foreach x all_ohm_inRange (unless (member x all_ohm_type) (setq all_ohm_type append1(all_ohm_type x))))
	temp_table = makeTable("default")
	;(ohm: integer, cline: string(dbid), pin: string(dbid), probe: string(dbid))
	(foreach x all_ohm_type (if (greaterp x ohm_standard) temp_table[x] = (list nil nil nil nil))) ; 35 is the minimun ohm
	(foreach (net cline ohm) all_net_inRange all_cline_inRange all_ohm_inRange
		;printf("\nnet: %s, cline: %s, ohm: %d\n", net cline ohm)
		pin_list = axlPinsOfNet(net 'pin)
		;printf("total pin num: %d.\n", length(pin_list)) ; test point
		(when is_qualified_net(net cline ohm pin_list all_ohm_type)
			(if (member nil temp_table[ohm])
				then ; if there is nothing in the temp_table then initialize the table
					pin_probe_dbid = get_closest_pinProbePair(pin_list)
					(if (member nil pin_probe_dbid)
						then ; if i can't find probe pin by pin_list
							temp_table[ohm] = (list ohm cline (car pin_list) nil)
						else ; if i can find probe pin by pin_list
							;printf("selected pin: %s, probe: %s, dis: %f", (car pin_probe_dbid)->name (cadr pin_probe_dbid)->name axlDistance((car pin_probe_dbid)->xy (cadr pin_probe_dbid)->xy))
							temp_table[ohm] = (list ohm cline (car pin_probe_dbid) (cadr pin_probe_dbid))
					)
				else ; if there is sth here, then compare the condition to get the best one
					;printf("new_cline_len: %f, old_cline: %s\n", axlDBGetLength(cline) (nth 1 temp_table[ohm]))
					(setq new_cline_len (axlDBGetLength(cline) - tdr_fit_len))
					(setq old_cline_len (axlDBGetLength((nth 1 temp_table[ohm])) - tdr_fit_len))
					(when (abs(old_cline_len) > abs(new_cline_len)) ; this is the key logical to find out the cline
						pin_probe_dbid = get_closest_pinProbePair(pin_list)
						(unless (member nil pin_probe_dbid)
							temp_table[ohm] = (list ohm cline (car pin_probe_dbid) (cadr pin_probe_dbid))
						)
					) ; if the new point is much closer to 3000
			)
		)
	)
	;(println "result as following") ; testing
	;(println all_ohm_type)
	;(foreach one all_ohm_type println(temp_table[one])) ; testing
	;(println "result end")
	TDR_Table[this_layer] = tableToList(temp_table)
	

;	(foreach this_layer etch_layer_list
;		
;		(set_visible_layer "ETCH" this_layer)
;		(setq all_cline (set_get_filter_objects))
;		;printf("The number of all_cline is %d\n", length(all_cline))
;		(setq all_cline_inRange (get_length_between all_cline 2000 4000))
;		;printf("The number of all_cline_in_range is %d\n", length(all_cline_in_range))
;	) 

) ; end of defun through_layer

(defun tdr_main ()
	
	;;;;; setup global variable
	(global_variable)
	
	;;;;; go through all etch layer
	(through_layer)
	
	;;;;; reset all setting
)

(tdr_main)

(axlCmdRegister "tdr_test" 'tdr_main)

;;;;;(load "TDR_test_report.il")

