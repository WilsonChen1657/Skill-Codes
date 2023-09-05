;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
; Author: Derek Hsu
; Starting Date: 06/28/2017 - _Derek06282017
; purpose: import the fab_note.txt to allegro panel
; usage: 1. open txt file
; 		2. read data and write it into the allegro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable
(defun init_Derek06282017 ()
	(setq text_num "16")
	(setq text_heigh axlGetParam(strcat("paramTextBlock:" text_num))->height)
	(setq display_layer "BOARD GEOMETRY/ASSEMBLY_NOTES")

	(setq start_x 31500.0)
	(setq start_y 6000.0)
	(setq tab 450.0)
	(setq line_y 125)

	(setq _csv_address nil)
	(setq _csv_ls list())
	(setq _backdrill_ls list())
	(setq alphabet vector("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"))
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; main function

(procedure remove_garbage_sign_Derek06282017(line_ls)
	(let ((result_ls list()))
		(foreach line line_ls
			(when (stringp line)
				(result_ls = (mapcar 'lambda( (line) (if rexMatchp("\n" line) rexReplace(line "" 0) line)) line_ls))
				(result_ls = (mapcar 'lambda( (line) (if rexMatchp("\"" line) rexReplace(line "" 0) line)) result_ls))
			)
		)
	
	result_ls)
)

(procedure move_down_Derek06282017(y @optional (height line_y)) (y - height))

(procedure create_text_Derek06282017(center_xy text @optional (origin "left")) 
	(myorient = make_axlTextOrientation(?textBlock text_num ?rotation 0.0 ?mirrored nil ?justify origin))
	axlDBCreateText( text, center_xy, myorient, display_layer, nil)
)

(procedure string_to_list_Derek06282017(str)
	(result_ls = list())
	(for ele 1 strlen(str) (result_ls = (append1 result_ls (symbolToString (getchar str ele)))))
	result_ls
)

(procedure read_text_file_Derek06282017(file_address)
	(let ((line nil) (result_ls list()))
		(in_port = (infile file_address))
		(while gets(line in_port) (result_ls = append1(result_ls line)))
		close(in_port)
	result_ls)
)

(procedure get_layer_num_Derek06282017(this_layer next_b)
	(layer_num = nil)
	(when rexMatchp("L[0-9]+" this_layer)
		(if next_b
			(layer_num = (concat "L" (add1 (atoi (substring rexSubstitute("\\0") 2)))))
			(layer_num = (concat "L" (sub1 (atoi (substring rexSubstitute("\\0") 2)))))
		)
	)
	
	(symbolToString layer_num)
)

(procedure get_alphabet_Derek06282017(num)
	(result = nil)
	
	(when (integerp num)
		(quotient = (num / 26))
		(remainder = (remainder num 26))
		(if (quotient > 0) (result = (strcat alphabet[(sub1 quotient)] alphabet[remainder])) (result = alphabet[remainder]))
	)
	
	result
)

(procedure get_backdrill_Derek06282017()
	; "A. VIA BACKDRILL, DRILLING FROM BOTTOM TO L9_GND4, HAS TO BE CEASED BY L8, OR SAID BACKDRILL DEPTH HAS TO BE 10 MIL LESS BY +/-5 MIL TOLERANCE."
	(alphabet_count = 0)
	(result_ls = list())
	(pin_from_top_running = nil)
	(pin_from_bot_running = nil)
	(via_from_top_running = nil)
	(via_from_bot_running = nil)
	
	(file_address = axlDMFileBrowse("ALLEGRO_TEXT" nil ?title "Please select the Backdrill Setup & Analysis file."))
	(if file_address
		(_backdrill_ls = read_text_file_Derek06282017(file_address))
		println("The Backdrill Setup & Analysis file has not been inputed.")
	)
	
	(if _backdrill_ls then
		(foreach line _backdrill_ls
			;                      to layer L9_GND4                  ...      44
			(when (line && (equal "to" (car (parseString line " "))))
				(content = nil)
				(layer = (caddr (parseString line " ")))
				(cond 
					(via_from_top_running
						(content = (strcat "VIA BACKDRILL, DRILLING FROM TOP TO " layer ", HAS TO BE STOPPED BY " get_layer_num_Derek06282017(layer t) ", OR SAID BACKDRILL DEPTH HAS TO BE 10 MIL LESS BY +/-5 MIL TOLERANCE."))
					) 
					(via_from_bot_running
						(content = (strcat "VIA BACKDRILL, DRILLING FROM BOTTOM TO " layer ", HAS TO BE STOPPED BY " get_layer_num_Derek06282017(layer nil) ", OR SAID BACKDRILL DEPTH HAS TO BE 10 MIL LESS BY +/-5 MIL TOLERANCE."))
					)
					(pin_from_top_running
						(content = (strcat "PIN BACKDRILL, DRILLING FROM TOP TO " layer ", HAS TO BE STOPPED BY " get_layer_num_Derek06282017(layer t) ", OR SAID BACKDRILL DEPTH HAS TO BE 10 MIL LESS BY +/-5 MIL TOLERANCE."))
					)
					(pin_from_bot_running
						(content = (strcat "PIN BACKDRILL, DRILLING FROM BOTTOM TO " layer ", HAS TO BE STOPPED BY " get_layer_num_Derek06282017(layer nil) ", OR SAID BACKDRILL DEPTH HAS TO BE 10 MIL LESS BY +/-5 MIL TOLERANCE."))
					)
				)
				(when content
					sprintf(content "%s. %s" get_alphabet_Derek06282017(alphabet_count) content)
					(alphabet_count = (add1 alphabet_count))
					(result_ls = (append1 result_ls content))
				)
			)
		
			(when line
				(when (nindex line "Via backdrill plunges from the top    side") (via_from_top_running = t))
				(when (nindex line "Via backdrill plunges from the bottom side") (via_from_top_running = nil) (via_from_bot_running = t))
				(when (nindex line "Via backdrill plunges from any layer") (via_from_bot_running = nil))
				(when (nindex line "Pin backdrill plunges from the top    side") (pin_from_top_running = t))
				(when (nindex line "Pin backdrill plunges from the bottom side") (pin_from_top_running = nil) (pin_from_bot_running = t))
				(when (nindex line "Pin backdrill plunges from any layer") (pin_from_bot_running = nil))
			)
		)
		(result_ls = (append (list "BACKDRILL INFORMATION") result_ls))
	else
		(result_ls = list())
	)
	
	result_ls
)

(procedure respond_question_Derek06282017(line)
	(question = nil)
	(answer = t)
	(question_count = 1)
	
	;;;;; yes no question, decide whether to go through the rest of the question
	(when rexMatchp("{??:[a-zA-Z0-9 ]+}" line)
		(question = rexSubstitute("\\0"))
		(question = (substring question 5 (strlen(question) - 5)))
		(answer = axlUIYesNo( question nil 'no ))
		(line = (rexReplace line "" 1))
	)
	
	;;;;; normal question , may ask more than one times
	rexCompile("{?:[a-zA-Z0-9 ]+}")
	(while (and answer (rexExecute line))
		(question = (rexSubstitute "\\0"))
		(question = (substring question 4 (strlen(question) - 4)))
		(answer = (axlEnterString ?prompts (list question)))
		;println(answer)
		(when answer (line = (rexReplace line answer 1)))
		;println(line)
	)
	
	(if answer line nil)
)

(procedure get_bevel_Derek06282017()
	; ,GOLD FINGER BEVEL WIDTH {?:bevel width is } MM
	; ,GOLD FINGER BEVEL HEIGHT  {?:bevel height is } MM
	; ,GOLD FINGER BEVEL DEGREE  {?:bevel degree is }
	(result_ls = list())
	(alphabet_count = 0)
	(content = nil)
	
	(when (answer = (axlEnterString ?prompts (list "GOLD FINGER BEVEL WIDTH?")))
		(sprintf content "%s. GOLD FINGER BEVEL WIDTH %s MM" get_alphabet_Derek06282017(alphabet_count) answer)
		(alphabet_count = (add1 alphabet_count))
		(result_ls = (append1 result_ls content))
	)
	
	(when (answer = (axlEnterString ?prompts (list "GOLD FINGER BEVEL HEIGHT?")))
		(sprintf content "%s. GOLD FINGER BEVEL HEIGHT %s MM" get_alphabet_Derek06282017(alphabet_count) answer)
		(alphabet_count = (add1 alphabet_count))
		(result_ls = (append1 result_ls content))
	)
	
	(when (answer = (axlEnterString ?prompts (list "GOLD FINGER BEVEL DEGREE?")))
		(sprintf content "%s. GOLD FINGER BEVEL DEGREE %s" get_alphabet_Derek06282017(alphabet_count) answer)
		(alphabet_count = (add1 alphabet_count))
		(result_ls = (append1 result_ls content))
	)
	
	(if result_ls (append (list "BEVEL INFORMATION") result_ls) list())
)

(procedure output_file_Derek06282017()
	(let ((row nil) (tmp_x nil) (tmp_y start_y) (item 1))
		(foreach line _csv_ls
			;println(line)
			(divide_pos = (nindex line ","))
			;println(divide_pos)
			(when (and numberp(divide_pos) (divide_pos > 1))
				(contents = list())
				(front = substring(line 1 (sub1 divide_pos)))
				(back = substring(line (add1 divide_pos)))
				
				(contents = (list back))
				(when (and back (nindex back "?:")) (contents = (list respond_question_Derek06282017(back))) (front = "*"))
				(when (and (car contents) (nindex (car contents) "{*:backdrill}")) (contents = get_backdrill_Derek06282017()))
				(when (and (car contents) (nindex (car contents) "{*:beveltype}")) (contents = get_bevel_Derek06282017()))
				
				(isTopic = t)
				(foreach row contents
					;;; get the current tab
					(if (onep (length contents))
						(tmp_x = (start_x + strlen(front) * tab))
						(if isTopic (tmp_x = (start_x + strlen((front = "*")) * tab)) (tmp_x = (start_x + strlen((front = "**")) * tab)))
					)
					;;;;; no matter is the multiple items, turn isTopic to false after first item
					(when isTopic (isTopic = nil))
					
					(when (and row (equal front "?"))
						(answer = axlUIYesNo( row nil 'no ))
						(when answer (front = "*"))
					)
				
					(when (and row (forall x (string_to_list_Derek06282017 front) (equal x "*")))
						;;; if the section is topi , then add serial
						(when (onep strlen(front)) (sprintf row "%d. %s" item row) (item = (add1 item)))
						
						;;; draw text
						(create_text_Derek06282017 tmp_x:tmp_y row)
						(tmp_y = move_down_Derek06282017(tmp_y))
					)
				)
			)
		)
	t)
)

(defun get_csv_file_ls_Derek06282017 (file_address)
	(let ((csv_line nil) (get_file nil))
		(in_port = (infile file_address))
		(if in_port (get_file = t) (get_file = nil))
		
		(while gets(csv_line in_port); fscanf(in_port "%s" csv_line)
			;println(csv_line)
			(when rexMatchp("[0-9a-zA-Z]+" csv_line) (_csv_ls = append1(_csv_ls csv_line)))
		)
		close(in_port)
	get_file)
)

(defun fab_note_main_Derek06282017 ()
	;;;;; initial global varible
	init_Derek06282017()
	
	(_csv_address = axlDMFileBrowse("COMMA_SEPARATED_VALUE" nil ?title "Please select a Fab_note.csv file."))
	(output_fab_note_b = nil)
	
	(if isFile(_csv_address)
		get_csv_file_ls_Derek06282017(_csv_address)
		println("Please select a fab_note.csv again.")
	)
	
	(if (and _csv_ls listp(_csv_ls))
		(_csv_ls = remove_garbage_sign_Derek06282017(_csv_ls))
		println("The csv file has not inputed successfully.")
	)
	
	(if (and _csv_ls listp(_csv_ls))
		(output_fab_note_b = output_file_Derek06282017())
		println("Something happened while cutting the \n sign.")
	)
	
	(if output_fab_note_b then
		println("The fab note has been reported successfully.")
		t
	else
		println("The fab note has not been reported.")
		nil
	)
)

;(fab_note_main_Derek06282017)
; setSkillPath( '( "." "C:/skill_release" "C:/skill" "C:/Cadence/SPB_16.6/share/pcb/examples/skill" "C:/Cadence/SPB_16.6/share/pcb/etc/skill" "C:/Cadence/SPB_16.6/share/local/pcb/scripts"))
(axlCmdRegister "fab_note" 'fab_note_main_Derek06282017)
;; encrypt( "c:/skill/fab_note_creator_v1.il" "c:/skill/fab_note_creator_v1.ile")
;; (load "fab_note_creator_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of main function