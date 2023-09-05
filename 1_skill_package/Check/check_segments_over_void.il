;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
; Editor: Derek Hsu
; Starting Date: 10/12/2017 - _Derek10122017
; Description: Segments over void
; Usage: input a net txt file and implement sov
; Input format:
;	<net_term>:<mil>
; Output format:
; 	Layer, location, spacing, net_name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

(defun init_Derek10122017 ()
	(defstruct net_mil_struct net_name mil)
	(defstruct sov_data_struct term layer location spacing net_name)
	
	(setq etch_layer_ls axlGetParam("paramLayerGroup:ETCH")->groupMembers)
	
	(setq sov_net_mil_filename "sov_net_mil_data.ini")
	(setq sov_net_info_fileAddress (strcat getWorkingDir() "/" sov_net_mil_filename))
	
	(setq sov_log_filename "sov_%.2f_mil.txt")
	(setq sov_log_fileAddress (strcat getWorkingDir() "/" sov_log_filename))
	
	(setq sov_form_name "sov_form_customize.form")
	(setq sov_form_address (strcat getWorkingDir() "/" sov_form_name))
	
	(sscanf getCurrentTime() "%s %d %d:%d:%d %s" mon date hr min sec year)
	(setq sov_result_filename (sprintf nil "%s_sov_result_%.2d%.2d%.2d_%.2d%s%s.csv" axlCurrentDesign() hr min sec date mon year))
	(setq sov_result_fileAddress (strcat getWorkingDir() "/sov/" sov_result_filename))
	(unless (isDir (strcat getWorkingDir() "/sov/")) (createDir (strcat getWorkingDir() "/sov/")))
	
	(setq sov_report_filename "sov_customized_report")
	(setq sov_report_fileAddress (strcat getWorkingDir() "/" sov_report_filename))
	
	
	(setq sov_input_content (buildString (list "<term of net>:<spacing>"
												"SAS:5"
												"SATA:5" ;"*:5"
												) "\n"))
	(setq highlight_sov_scr (buildString (list "version 16.6"
										"setwindow pcb"
										"enved"
										"setwindow form.prfedit"
										"FORM prfedit sov_active_only NO"
										"FORM prfedit sov_skip_plane_check NO"
										"FORM prfedit sov_spacing %f"
										"FORM prfedit apply"
										"FORM prfedit done"
										"setwindow pcb"
										"highlight sov"
										"setwindow text"
										"save"
										"fillin \"%s\""
										"setwindow text"
										"close"
										"setwindow pcb") ";"))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FORM

(defun sov_form_builder_Derek10122017 ()
	;;;;; head
	(when (outportp (out_port = outfile(sov_form_address "w")))
		fprintf(out_port "FILE_TYPE=FORM_DEFN VERSION=2\n")
		fprintf(out_port "FORM TOOLWINDOW \n")	
		fprintf(out_port "FIXED\n")
		fprintf(out_port "PORT %d %d\n" 28 44)
		fprintf(out_port "HEADER \"Import Net & Symbol for Backdrill Setup\"\n")
		fprintf(out_port "TILE\n")
		
		;;;;; content
		fprintf(out_port "FIELD run_sov\n")
		fprintf(out_port "FLOC %d %d\n" 1 1)
		fprintf(out_port "MENUBUTTON \"RUN HIGHLIGHT SOV\" %d %d\n" 27 3)
		fprintf(out_port "ENDFIELD\n\n")
		
		fprintf(out_port "FIELD sort_sov\n")
		fprintf(out_port "FLOC %d %d\n" 1 4)
		fprintf(out_port "MENUBUTTON \"SORT SOV LOG\" %d %d\n" 27 3)
		fprintf(out_port "ENDFIELD\n\n")
		
		;;;;; tail
		fprintf(out_port "ENDTILE\n")
		fprintf(out_port "ENDFORM\n")
		close(out_port)
	)
)

(defun sov_form_action_Derek10122017 (sov_form)
	(prog ()
		(case sov_form->curField
			("run_sov"
				(foreach (log_fileAddress mil_val) log_fileAddress_ls mil_ls
					printf("Processing the sov by spacing %f.\n" mil_val)
					(axlShellPost (sprintf nil highlight_sov_scr mil_val log_fileAddress))
				)
			)
			("sort_sov"
				;;;;; filtout the result into one file
				(if (forall x log_fileAddress_ls (isFile x)) then
					(sov_data_ls = (collect_sov_log_file_Derek10122017 log_fileAddress_ls net_mil_ls))
				else
					println("Fail to get the log file from 'highlight sov' command.")
					return(nil)
				)
				
				;;;;; write result into csv file
				(if (dtpr sov_data_ls) then
					write_csv_file_Derek10122017(sov_data_ls)
				else
					(axlFormClose sov_form)
					axlUIConfirm("No sov data has been found.")
					return(nil)
				)
						
				;;;;; delete the original sov
				(foreach log_file log_fileAddress_ls (deleteFile log_file))
				
				;;;;; show up the report
				(if (isFile sov_result_fileAddress) then
					axlReportRegister('sov_custom_report_Derek10122017 sov_report_filename "This report shows up SOV by multiple net-mil input.")
					axlShell((sprintf nil "reports '%s'" sov_report_filename))
				else
					println("Fail to collect data from log file.")
					return(nil)
				)
				
				(axlFormClose sov_form)
			)
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of FORM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

(procedure write_file_Derek10122017(fileAddress words)
	(when (outportp (out_port = (outfile fileAddress "w")))
		(fprintf out_port words)
		(close out_port)
	)
)

(procedure get_net_mil_from_file_Derek10122017(fileAddress)
	(net_mil_ls = list())
	
	(when (inportp (in_port = (infile fileAddress)))
		(while (stringp gets(line in_port))
			(when (and (not (equal "#" (getchar line 1)))
						(dtpr (line_ls = (parseString line ":")))
						(stringp (net = (car line_ls)))
						(numberp (mil = (atof (cadr line_ls)))))
				(line_data = (make_net_mil_struct ?net_name net ?mil mil))
				(net_mil_ls = (append1 net_mil_ls line_data))
			)
		)
	)
	
	net_mil_ls
)

;(procedure dehighlight_all_net()
;	(foreach sub_layer etch_layer_ls (axlVisibleLayer (strcat "ETCH/" sub_layer) t))
;	axlSetFindFilter( ?enabled (list "noall" "nets") ?onButtons (list "noall" "nets"))
;	axlClearSelSet()
;	axlAddSelectAll()
;	axlDehighlightObject(axlGetSelSet())
;	axlClearSelSet()
;	(axlVisibleUpdate t)
;)

(procedure collect_sov_log_file_Derek10122017(log_fileAddress_ls net_mil_ls)
	(sov_data_ls = list())
	
	(foreach address log_fileAddress_ls
		(term_ls = (mapcan (lambda (x) (when (equal address (sprintf nil sov_log_fileAddress x->mil)) (list x->net_name))) net_mil_ls))
	
		(when (inportp (in_port = (infile address)))
			(while (gets line in_port)
				(when (term = (exists x term_ls (or (equal x "*") (rexMatchp x line))))
					(term = (car term))
					(data_ls = (parseString line))
					
					(when (and (dtpr data_ls)
								(eqv 5 (length data_ls))
								(axlIsLayer (strcat "ETCH/" (nth 0 data_ls)))
								(floatp (atof (nth 3 data_ls))))
						(location = (strcat (substring (nth 1 data_ls) 2) ":" (substring (nth 2 data_ls) 1 ((strlen (nth 2 data_ls)) - 1))))
						(sov_data = (make_sov_data_struct ?term term
															?layer (nth 0 data_ls)
															?location location
															?spacing (atof (nth 3 data_ls))
															?net_name (nth 4 data_ls)))
						(sov_data_ls = (append1 sov_data_ls sov_data))
					)
				)
			)
			
			(close in_port)
		)
	)
	
	sov_data_ls
)

(procedure write_csv_file_Derek10122017(words)
	(when (outportp (out_port = (outfile sov_result_fileAddress "w")))
		(fprintf out_port "TERM,LAYER,LOCATION,SPACING,NET_NAME\n")
		(foreach word words
			(fprintf out_port "%s,%s,%s,%.2f,%s\n" word->term word->layer word->location word->spacing word->net_name)
		)
		(close out_port)
	)
)

(procedure sov_custom_report_Derek10122017(@optional (reportName sov_report_filename))
	(let (one fp line section (text ""))
		(fp = axlDMOpenFile("ALLEGRO_HTML" reportName "w"))
		
		fprintf(fp, "\n<html>\n")
		fprintf(fp, strcat("\n<head><title>" reportName "</title></head>\n"))
		fprintf(fp, "<body>\n")
		
		fprintf(fp, "\n<table align=center border=1><caption><b><u>This report shows up SOV by multiple net-mil input.</u></b></caption>\n")

		(when (inportp (in_port = (infile sov_result_fileAddress)))
			(while fscanf(in_port "%s" line)
				(text = "")
				;println(line)
				(foreach one parseString(line ",")
					(if (nindex one ":") then
						(section = parseString(one ":"))
						sprintf(section
								 "<td nowrap=true><a href=\"xprobe:xy:%s,%s\">%s %s</a></td>\n"
								 (car section) (cadr section) (car section) (cadr section))
						(text = strcat(text section))
					else
						(text = strcat(text "<td nowrap=true>" one "</td>\n"))
					)
				)
				fprintf(fp, strcat("<tr>\n" text "</tr>\n"))
			)
			
			close(in_port)
		)
		
		fprintf(fp, "</table>\n")
		fprintf(fp, "</body>\n")
		fprintf(fp, "</html>\n")
		
		close(fp)
	t)
)

;(procedure get_projection_point(start_end point)
;	;;;;; the formula is 
;	;;;;; a*x+b*y+c = 0  <==> m*x-y+c = 0
;	;;;;; x = x0-a*(a*x0+b*y0+c)/(a^2+b^2)
;	;;;;; y = y0-b*(a*x0+b*y0+c)/(a^2+b^2)
;	(pj_pt = list())
;	
;	(when (and (eqv 2 (length start_end)) (forall x start_end (dtpr x)) (dtpr point))
;		(start_pt = (car start_end))
;		(end_pt = (cadr start_end))
;		(m = (axlLineSlope start_end))
;		
;		;;;;; a*x+b*y+c = 0
;		(a = m)
;		(b = -1)
;		(c = (-m * (car start_pt) + (cadr start_pt))) ; c = -m*x + y
;		
;		;;;;; (a*x0+b*y0+c)/(a^2+b^2)
;		(follow_part = ((a * (car point) + b * (cadr point) + c) / (a**2 + b**2)))
;		(x = ((car point) - a * follow_part))
;		(y = ((cadr point) - b * follow_part))
;		
;		(pj_pt = (list x y))
;	)
;	
;	pj_pt
;)

;(procedure shortest_distance_to_segment(start_end point)
;	(shortest_dis = nil)
;
;	;;;;; start_end is the different end of a segment; the point is the coordination of the center of a void
;	(when (and (eqv 2 (length start_end)) (forall x start_end (dtpr x)) (dtpr point))
;		;;;;; get projection point to a line
;		(pj_pt = get_projection_point(start_end point))
;		
;		;;;;; if the projection point is in the segment, then the shortest distance is from projection point to point.
;		;;;;; Otherwise, it is the point to the start or end point
;		
;		(if (axlIsPointOnLine pj_pt start_end) then
;			(shortest_dis = (axlDistance point pj_pt))
;		else
;			(shortest_dis = (apply 'min (list (axlDistance point (car start_end)) (axlDistance point (cadr start_end)))))
;		)
;	)
;	
;	shortest_dis
;)

;(procedure get_ref_plan(this_layer)
;	(ref_layer_ls = list())
;	
;	(last_layer = (cadr (member this_layer (reverse etch_layer_ls))))
;	(next_layer = (cadr (member this_layer etch_layer_ls)))
;	
;	(cond
;		((and (nindex "GND" last_layer) (nindex "GND" next_layer))
;			(ref_layer_ls = (list last_layer next_layer))
;		)
;		((nindex "GND" last_layer) (ref_layer_ls = (list last_layer)))
;		((nindex "GND" next_layer) (ref_layer_ls = (list next_layer)))
;		((nindex "VCC" last_layer) (ref_layer_ls = (list last_layer)))
;		((nindex "VCC" next_layer) (ref_layer_ls = (list next_layer)))
;	)
;	
;	ref_layer_ls
;)

(defun segments_over_void_main_Derek10122017 ()
	(prog ()
		(when (and (boundp 'sov_form) sov_form (not sov_form->doneState))
			printf("The %s has been opened.\n" sov_form->form)
			return(nil)
		)
	
		init_Derek10122017()
		
		;;;;; check if the input form is exists or create a new one
		(unless (isFile sov_net_info_fileAddress) write_file_Derek10122017(sov_net_info_fileAddress sov_input_content))
		
		;;;;; retrieve the data inside
		(if (isFile sov_net_info_fileAddress) then
			(net_mil_ls = (get_net_mil_from_file_Derek10122017 sov_net_info_fileAddress))
		else
			printf("Fail to make: %s\n" sov_net_info_fileAddress)
			return(nil)
		)
		
		;;;;; get the minimun mil value
		(if (dtpr net_mil_ls) then
			(mil_ls = (maplist (lambda (x) (if (memv (car x) (cdr x)) nil (car x))) net_mil_ls~>mil))
			(mil_ls = (setof x mil_ls x))
		else
			printf("Fail to retrieve data from %s\n" sov_net_info_fileAddress)
			return(nil)
		)
		
		;;;;; create log file name list
		(log_fileAddress_ls = (mapcar (lambda (x) (sprintf nil sov_log_fileAddress x)) mil_ls))
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; create form
		sov_form_builder_Derek10122017()
		(sov_form = (axlFormCreate (gensym) sov_form_address '("east" "outer") 'sov_form_action_Derek10122017 t))
		;(deleteFile sov_form_address)
		(if sov_form then
			axlFormDisplay(sov_form)
			;set_import_backdrill_form_Derek07242017()
		else
			println("The sov form won't be displayed.")
		)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setting

; (segments_over_void_main_Derek10122017)
(axlCmdRegister "segments_over_void" 'segments_over_void_main_Derek10122017)
; skill encrypt( "C:/skill/segments_over_void_v1.il" "C:/skill/segments_over_void_v1.ile")
; (load "segments_over_void_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setting