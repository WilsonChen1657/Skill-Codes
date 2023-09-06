;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Introduction
;
;Developer: Derek Hsu
;Starting Date: 06/12/2018 - _Derek06122018
;Introduction: this skill program is used to read xlsx file by unzipping it to 4 files, which are
;	1. _rels directory
;	2. docProps directory
;	3. xl directory
;	4. [Content_Type].xml
;	
;	all of the raw data
;	1. Cells values are stored in xl>worksheets>sheet?.xml
;		1. if it is a number value, then it'll be stored in this sheet?.xml
;		2. if it is a string value, then it'll be stored in xl>sharedStrings.xml
;	2. Sheetnames have been stored in xl>workbook.xml
;
;	trigger:
;	(when manipulate_xlsx_main_Derek06122018()
;		(xsection_address = (strcat getWorkingDir() "/" excel_csv_filename))
;	)
;	(unless xsection_address println("No file has been selected.") return(nil))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

(defun init_Derek06122018 ()
	setq( _sel_sheet_id nil)
	setq( sheetname_ls nil)
	setq( sharedstring_ls nil)
	setq( string_data_ls nil)
	setq( sheetname_filename "workbook.xml")
	setq( sharedstring_filename "sharedStrings.xml")
	setq( excel_form_name "Excel_Sheet_Selector.form")
	setq( excel_table_name "Excel_Sheet_Addr_Val.table")
	setq( excel_csv_filename "Excel_sheet.csv")
	setq( alphabet_ls (list nil 'A 'B 'C 'D 'E 'F 'G 'H 'I 'J 'K 'L 'M 'N 'O 'P 'Q 'R 'S 'T 'U 'V 'W 'X 'Y 'Z))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

(procedure get_attr_val_Derek06122018(attr section)
	(let (start start_len start2 len tmp1 tmp2 (found nil) result)
	(sprintf start " %s=" attr)
	;;
	(when (stringp section) (sect = (index section start)))
	(when (stringp sect) (tail1 = (index sect "\""))) ; go to value start
	(when (stringp tail1) (tail2 = (index (substring tail1 2) "\""))) ; go to value end
	;;
	(when (and sect tail1 tail2)
		(sect_len = (strlen sect))
		(result = (substring sect (add1 (strlen start)) ((strlen tail1) - (strlen tail2) + 1)))
	)
	
	result
	)
)

(procedure get_section_Derek06122018(key pos sentence)
	(let (start end1 end2 result tail tail1 tail2 tail_len)
		(end1 = "/>")
		(end2 = (strcat "</" key ">"))
		;;
		(if pos then
			(sentence = (substring sentence pos))
			(pos = 1)
		else
			(sprintf start "<%s " key)
			(pos = (nindex sentence start))
			(unless pos
				(sprintf start "<%s>" key)
				(pos = (nindex sentence start))
			)
		)
		;;
		(when (numberp pos)
			(tail1 = (nindex sentence end1))
			(tail2 = (nindex sentence end2))
			
			(when (and (null tail1) tail2)
				(tail = tail2)
				(tail_len = (strlen end2))
			)
			(when (and tail1 (null tail2))
				(tail = tail1)
				(tail_len = (strlen end1))
			)
			(when (and tail1 tail2)
				(when (and (pos < tail1) (tail1 < tail2))
					(tail = tail1)
					(tail_len = (strlen end1))
				)
				(when (and (pos < tail2) (tail1 > tail2))
					(tail = tail2)
					(tail_len = (strlen end2))
				)
			)
			;printf("sen:%s - pos:%d - tail:%d - res:%d\n" (substring sentence 1 5) pos tail (tail - pos + tail_len))
			(result = (substring sentence pos (tail - pos + tail_len)))
		)
		
		result
	)
)

(procedure get_section_val_Derek06122018(section)
	(let (start end result)
	(start = (nindex section ">"))
	(end = (rindex section "<"))
	(when end (end = ((strlen section) - (strlen end))))
	(when (and start end)
		(result = (substring section (add1 start) (end - start)))
	)
	
	result
	)
)

(procedure get_sheetnames_Derek06122018(file_addr)
	(let (in_port (line "") (all_line "") (key "<sheet ") section nm result_ls)
	(if (inportp (in_port = (infile file_addr))) then
		(while gets(line in_port) (all_line = (strcat all_line line)))
		(close in_port)
		;;
		(line = (index all_line key))
		(while line
			(section = get_section_Derek06122018("sheet" 1 line))
			(nm = (get_attr_val_Derek06122018 "name" section))
			(result_ls = (append1 result_ls nm))
			;;
			(line = (substring line (strlen section)))
			(line = (index line key))
		)
	else
		printf("Fail to open file: %s\n" file_addr)
	)
	
	(sheetname_ls = result_ls)
	)
)

(procedure get_sharedstrings_Derek06122018(file_addr)
	(let (in_port line (all_line "") (key1 "<t>") (key2 "<t ") section sect sect1 sect2 pos pos1 tmp result_ls)
	(if (inportp (in_port = (infile file_addr))) then
		(while gets(line in_port) (all_line = (strcat all_line line)))
		(close in_port)
		;;
		(section = (index all_line "<si>"))
		(while section
			(nm = "")
			(pos = (nindex section "</si>"))
			(sect = (substring section 1 (pos + 4))) ;; 4 is the strlen of </si>~~
			;;;
			(sect1 = (index sect key1))
			(sect2 = (index sect key2))
			(while (or sect1 sect2)
				;; printf("%L --- %L\n" (list sect1) (list sect2))
				(when (and (null sect1) sect2) (sect = sect2))
				(when (and sect1 (null sect2)) (sect = sect1))
				(when (and sect1 sect2)
					(if ((strlen sect1) < (strlen sect2)) (sect = sect2) (sect = sect1))
				)
				(pos1 = (nindex sect "</t>"))
				(tmp = (substring sect 1 (pos1 + 3)))
				(nm = (strcat nm (get_section_val_Derek06122018 tmp)))
				;;
				(sect = (substring sect pos1)) ;; 5 is the strlen of </si>
				(sect1 = (index sect key1))
				(sect2 = (index sect key2))
			)
			;;;
			(section = (substring section (pos + 5)))
			(section = (index section "<si>"))
			;;;
			(result_ls = (append1 result_ls nm))
		)
	else
		printf("Fail to open file: %s\n" file_addr)
	)
	
	(sharedstring_ls = result_ls)
	)
)

(procedure get_file_path_Derek06122018(file_addr)
	(prog ()
	(nm = (rindex file_addr "/"))
	(result = (substring file_addr 1 (add1 ((strlen file_addr) - (strlen nm)))))
	
	(return result)
	)
)

(procedure form_builder_Derek06122018()
	(let (out_port)
	(when (outportp (out_port = (outfile excel_form_name "w")))
	
		fprintf(out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf(out_port "FORM TOOLWINDOW \n")	
		fprintf(out_port "FIXED\n")
		fprintf(out_port "PORT %d %d\n" 24 50)
		fprintf(out_port "HEADER \"Excel Sheet Selector vDerek\"\n")
		fprintf(out_port "POPUP <sheet_name_pop>\"a\"\"a\".\n")
		fprintf(out_port "TILE\n")
		
		fprintf(out_port "TEXT \"Please Select a sheet in this excel\" \n")
		fprintf(out_port "FLOC %d %d\n" 1 1)
		fprintf(out_port "ENDTEXT\n")
		
		;;;;; list
		
		fprintf(out_port "FIELD sheetname_list\n")
		fprintf(out_port "FLOC %d %d\n" 1 3)
		fprintf(out_port "ENUMSET %d\n" 21)
		fprintf(out_port "OPTIONS prettyprint ownerdrawn\n")
		fprintf(out_port "POP \"sheet_name_pop\"\n") ;;;;; this section is used to reference the list
		fprintf(out_port "ENDFIELD\n")
		
		;;;;; button
		
		fprintf(out_port "FIELD ok\n")
		fprintf(out_port "FLOC %d %d\n" 1 6)
		fprintf(out_port "MENUBUTTON \"OK\" %d %d\n" 10 2)
		fprintf(out_port "ENDFIELD\n\n")
		
		fprintf(out_port "FIELD cancel\n")
		fprintf(out_port "FLOC %d %d\n" 14 6)
		fprintf(out_port "MENUBUTTON \"Cancel\" %d %d\n" 10 2)
		fprintf(out_port "ENDFIELD\n\n")
		
		fprintf(out_port "ENDTILE\n")
		fprintf(out_port "ENDFORM\n")
		
		(close out_port)
	)
	)
)

(procedure excel_form_action_Derek06122018(excel_sel_sheet_form)
	(case excel_sel_sheet_form->curField
		("sheetname_list"
			(_sel_sheet_id = excel_sel_sheet_form->curValue)
		)
		("ok"
			axlFormClose(excel_sel_sheet_form)
		)
		("cancel"
			(_sel_sheet_id = nil)
			axlFormClose(excel_sel_sheet_form)
		)
	)
)

(procedure create_form_Derek06122018()
	(prog (excel_sel_sheet_form i num_ls bind_ls)
	
	;;;
	form_builder_Derek06122018()
	
	;;;
	(excel_sel_sheet_form = (axlFormCreate (gensym) excel_form_name '("east" "outer") 'excel_form_action_Derek06122018 nil))
	
	;;;
	(if (axlIsFormType excel_sel_sheet_form) then
		(num_ls = bind_ls = nil)
		(for i 1 (length sheetname_ls) (num_ls = (append1 num_ls (sprintf nil "sheet%d" i))))
		(bind_ls = (mapcar 'list sheetname_ls num_ls))
		(axlFormBuildPopup excel_sel_sheet_form "sheetname_list" bind_ls)
		;;
		(axlFormDisplay excel_sel_sheet_form)
		(deleteFile excel_form_name)
	else
		(println "Fail to create Excel Selector form. Program halt.")
		(return nil)
	)
	
	(return t)
	)
)

(procedure get_sheet_content_Derek06122018(cell_table file_addr)
	(let (in_port (key "<c ") key_len tmp (line "") (all_line "") section nm addr pos)
	(if (inportp (in_port = (infile file_addr))) then
		(while (gets line in_port) (all_line = (strcat all_line line)))
		(close in_port)
		;;
		(key_len = (strlen key))
		(len = ((strlen all_line) - (strlen key)))
		;;
		(line = (index all_line key))
		(while line
			(section = (get_section_Derek06122018 "c" nil line))
			(nm = (get_section_Derek06122018 "v" nil section))
			;;
			(when nm
				(nm = (substring nm 4 ((strlen nm) - 7)))
				(when (nindex section "t=\"s\"")
					(nm = (nth (atoi nm) sharedstring_ls))
				)
				;;
				(addr = (get_attr_val_Derek06122018 "r" section))
				(addr = (substring addr 2 ((strlen addr) - 2)))
				;;
				(cell_table[addr] = nm)
			)
			;;
			(line = (substring line (strlen section)))
			(line = (index line key))
		)
	else
		printf("Fail to open file: %s\n" file_addr)
	)
	)
)

(procedure sort_addr_Derek06122018(a b)
	(prog (a1 a2 b1 b2 result)
		(a = (upperCase a))
		(b = (upperCase b))
		rexCompile("[A-Z]+")
		rexExecute(a)
		(a1 = rexSubstitute("\\0"))
		rexExecute(b)
		(b1 = rexSubstitute("\\0"))
		
		;(unless (equal a1 b1) (return (alphalessp a1 b1)))
		
		(a2 = (substring a (add1 (strlen a1))))
		(b2 = (substring b (add1 (strlen b1))))
		
		;(return ((atoi a2) < (atoi b2)))
		
		(result = (if (equal a2 b2) (alphalessp a1 b1) ((atoi a2) < (atoi b2))))
		(return result)
	)
)

(procedure output_cell_table_Derek06122018(cell_table file_addr)
	(let (out_port key val_ls)
	(if (outportp (out_port = (outfile file_addr "w"))) then
		(val_ls = (tableToList cell_table))
		(val_ls = (sortcar val_ls 'sort_addr_Derek06122018))
	
		(foreach key val_ls
			(fprintf out_port "[%s],%s\n" (car key) (cadr key))
		)
		(close out_port)
	else
		printf("Fail to open file: %s\n" file_addr)
	)
	)
)

(procedure get_char_number_Derek06122018(a)
	(let (len pos (result 0))
	(if (stringp a) then
		(len = (strlen a))
		(for i 1 len
			(pos = (len - i))
			(result = (result + (expt 26 pos) * (listnindex alphabet_ls (getchar a i))))
		)
	else
		(result = nil)
	)
	
	result
	)
)

(procedure get_max_len_from_keys_Derek06122018(val_ls)
	(let (key_ls result)
		;; get alphabet out of key
		rexCompile("[A-Z]+")
		(foreach x cell_table->? rexExecute(x) (key_ls = (append1 key_ls rexSubstitute("\\0"))))
		(key_ls = (maplist (lambda (x) (if (member (car x) (cdr x)) nil (car x))) key_ls))
		(key_ls = (mapcan (lambda (x) (when x (list x))) key_ls))
		;; convert alphabet to number
		(key_ls = (mapcar 'get_char_number_Derek06122018 key_ls))
		(key_ls = (mapcan (lambda (x) (when x (list x))) key_ls))
		(result = (apply 'max key_ls))
		
		result
	)
)

(procedure arr_to_list(mx data_arr)
	(let (line_ls)
		(for i 1 mx (line_ls = (append1 line_ls data_arr[i])))
		;;;;; add "" to data, which has comma
		(line_ls = (mapcar (lambda (x) (if (nindex x ",") (strcat "\"" x "\"") x)) line_ls))
		
		line_ls
	)
)

(procedure output_csv_Derek06122018(cell_table file_addr)
	(let (out_port key key_num key_alp val_ls sect mx csv_line_ls line_ls pre_key_num data_arr)
	(if (outportp (out_port = (outfile file_addr "w"))) then
		;;; sorting by row and then col is necessary for this function
		(val_ls = (tableToList cell_table))
		(val_ls = (sortcar val_ls 'sort_addr_Derek06122018))
		;;
		(mx = get_max_len_from_keys_Derek06122018(val_ls))
		(declare data_arr[(add1 mx)])
		(for i 1 mx (setarray data_arr i ""))
		
		;; create 2d list
		rexCompile("[A-Z]+")
		(pre_key_num = "")
		(foreach sect val_ls
			(key = (car sect))
			(val = (cadr sect))
			;;
			(when rexExecute(key)
				(key_alp = rexSubstitute("\\0"))
				(key_num = (substring key (add1 (strlen key_alp))))
				;printf("%s - %s - %s\n" key_alp key_num val)
				;; get data with identical row into a csv line
				(if (or (equal "" pre_key_num) (equal pre_key_num key_num)) then
					(pre_key_num = key_num)
					(pos = get_char_number_Derek06122018(key_alp)) ;; alphabet is the col of the excel
					(setarray data_arr pos val)
				else
					(line_ls = arr_to_list(mx data_arr))
					(csv_line_ls = (append1 csv_line_ls (buildString line_ls ",")))
					;;
					(for i 1 mx (setarray data_arr i ""))
					;;
					(pos = get_char_number_Derek06122018(key_alp)) ;; alphabet is the col of the excel
					(setarray data_arr pos val)
					(pre_key_num = key_num)
				)
			)
		)
		;;; take the last line
		(line_ls = arr_to_list(mx data_arr))
		(csv_line_ls = (append1 csv_line_ls (buildString line_ls ",")))
		
		;;; output to csv file
		(foreach line csv_line_ls (fprintf out_port "%s\n" line))
		
		(close out_port)
	else
		printf("Fail to open file: %s\n" file_addr)
	)
	)
)

(procedure filter_data_ls_Derek06122018()
	;;;;; remove \"
	rexCompile("\"")
	(sheetname_ls = (mapcar (lambda (x) rexReplace(x "" 0)) sheetname_ls))
	(sharedstring_ls = (mapcar (lambda (x) rexReplace(x "" 0)) sharedstring_ls))
	
	;;;;; replace \n
	rexCompile("\n")
	(sharedstring_ls = (mapcar (lambda (x) rexReplace(x "[enter]" 0)) sharedstring_ls))
	
	;;;;; replace &amp;
	rexCompile("&amp;")
	(sharedstring_ls = (mapcar (lambda (x) rexReplace(x "and" 0)) sharedstring_ls))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main Function

procedure( manipulate_xlsx_main_Derek06122018()
	(prog (file_addr old_file_ls new_file_ls file)
		init_Derek06122018()
		
		old_file_ls = (getDirFiles getWorkingDir())
		
		;;;;; ask to input xlsx name
		excel_addr = (axlDMFileBrowse nil nil ?title "Please select a xlsx file" ?optFilters "All xlsx files|*.xlsx|")
		unless( isFile( excel_addr) println( "No file has been selected. program halt") (return nil))
		unless( (equal ".xlsx" (substring excel_addr ((strlen excel_addr) - 4))) println("Please select a xlsx file") return( nil))
		
		;; add " to the section having spacing
		(excel_path = (get_file_path_Derek06122018 excel_addr))
		(excel_addr = (parseString excel_addr "/"))
		(excel_addr = (mapcar (lambda (x) (if (nindex x " ") (strcat "\"" x "\"") x)) excel_addr))
		
		;; convert skill read path to OS file path
		(excel_addr = (buildString excel_addr "\\"))
		
		;;;;; unzip the file
		;; check
		(unless (sh "\"C:\\Program Files\\7-Zip\\7z\"")
			println("Please install 7-zip to C:\\Program Files\\7-Zip\\7z")
			(return nil)
		)
		; (axlOSBackSlash getWorkingDir())
		(sprintf cmd "C:\\\"Program Files\"\\7-Zip\\7z e %s -y" excel_addr)
		
		(unless (sh cmd)
			println("Fail to extract the excel file. program halt")
			(return nil)
		)
		
		;;;;; get new file list
		(new_file_ls = (getDirFiles getWorkingDir()))
		(new_file_ls = (mapcan (lambda (x) (unless (member x old_file_ls) (list x))) new_file_ls))
		
		;;;;; get all sheetname
		println("Getting Sheet Name...")
		(file_addr = (strcat getWorkingDir() "/" sheetname_filename))
		(get_sheetnames_Derek06122018 file_addr)
		
		;;;;; get string list
		println("Getting SharedString Data...")
		(file_addr = (strcat getWorkingDir() "/" sharedstring_filename))
		(get_sharedstrings_Derek06122018 file_addr)
		;(for i 0 (sub1 (length sharedstring_ls)) printf("%d     %s\n" (i + 2) (nth i sharedstring_ls)))
		
		;;;;; filter data list / replace & to and / replace \n to [enter]
		filter_data_ls_Derek06122018()
		
		;;;;; ask which sheet the user wants / by form
		println("Creating Form...")
		create_form_Derek06122018()
		(unless _sel_sheet_id
			(foreach file new_file_ls (when (isFile file) (deleteFile file)))
			(return nil)
		)
		
		;;;;; create dictionary by selected sheets
		println("Getting Sheet Content...")
		(file_addr = (strcat getWorkingDir() "/" _sel_sheet_id ".xml"))
		(cell_table = makeTable("cell_table" nil))
		(get_sheet_content_Derek06122018 cell_table file_addr)

		;;;;; delete unzipped files and dir
		(foreach file new_file_ls (when (isFile file) (deleteFile file)))
		
		;;;;; output cell table
		println("Outputting Cell Table...")
		(file_addr = (strcat getWorkingDir() "/" excel_table_name))
		(deleteFile file_addr)
		(output_cell_table_Derek06122018 cell_table file_addr)
		
		;;;;; convert the table to csv
		println("Outputting csv file...")
		(file_addr = (strcat getWorkingDir() "/" excel_csv_filename))
		(deleteFile file_addr)
		(output_csv_Derek06122018 cell_table file_addr)
		
		;;;
		(return t)
	)
)

(defun manipulate_xlsx_first_main_Derek06122018 ()
	(prog (file_addr old_file_ls new_file_ls file)
	init_Derek06122018()
	
	(old_file_ls = (getDirFiles getWorkingDir()))
	
	;;;;; ask to input xlsx name
	(unless (excel_addr = (axlDMFileBrowse nil nil ?title "Please select a xlsx file" ?optFilters "All xlsx files|*.xlsx|"))
		println("No file has been selected. program halt")
		(return nil)
	)
	(unless (equal ".xlsx" (substring excel_addr ((strlen excel_addr) - 4)))
		println("Please select a xlsx file")
		(return nil)
	)
	
	;; add " to the section having spacing
	(excel_path = (get_file_path_Derek06122018 excel_addr))
	(excel_addr = (parseString excel_addr "/"))
	(excel_addr = (mapcar (lambda (x) (if (nindex x " ") (strcat "\"" x "\"") x)) excel_addr))
	
	;; convert skill read path to OS file path
	(excel_addr = (buildString excel_addr "\\"))
	
	;;;;; unzip the file
	;; check
	(unless (sh "\"C:\\Program Files\\7-Zip\\7z\"")
		println("Please install 7-zip to C:\\Program Files\\7-Zip\\7z")
		return(nil)
	)
	; (axlOSBackSlash getWorkingDir())
	(sprintf cmd "C:\\\"Program Files\"\\7-Zip\\7z e %s -y" excel_addr)
	
	(unless (sh cmd)
		println("Fail to extract the excel file. program halt")
		(return nil)
	)
	
	;;;;; get new file list
	(new_file_ls = (getDirFiles getWorkingDir()))
	(new_file_ls = (mapcan (lambda (x) (unless (member x old_file_ls) (list x))) new_file_ls))
	
	;;;;; get string list
	println("Getting SharedString Data...")
	(file_addr = (strcat getWorkingDir() "/" sharedstring_filename))
	(get_sharedstrings_Derek06122018 file_addr)
	;(for i 0 (sub1 (length sharedstring_ls)) printf("%d     %s\n" (i + 2) (nth i sharedstring_ls)))
	
	;;;;; filter data list
	filter_data_ls_Derek06122018()
	
	;;;;; to select the very first sheet in the excel
	(_sel_sheet_id = "sheet1")
	
	;;;;; create dictionary by selected sheets
	println("Getting Sheet Content...")
	(file_addr = (strcat getWorkingDir() "/" _sel_sheet_id ".xml"))
	(cell_table = makeTable("cell_table" nil))
	(get_sheet_content_Derek06122018 cell_table file_addr)

	;;;;; delete unzipped files and dir
	(foreach file new_file_ls (when (isFile file) (deleteFile file)))
	
	;;;;; output cell table
	println("Outputting Cell Table...")
	(file_addr = (strcat getWorkingDir() "/" excel_table_name))
	(deleteFile file_addr)
	(output_cell_table_Derek06122018 cell_table file_addr)
	
	;;;;; convert the table to csv
	println("Outputting csv file...")
	(file_addr = (strcat getWorkingDir() "/" excel_csv_filename))
	(deleteFile file_addr)
	(output_csv_Derek06122018 cell_table file_addr)
	
	;;;
	(return t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

(axlCmdRegister "manipulate_xlsx" 'manipulate_xlsx_main_Derek06122018)
(axlCmdRegister "manipulate_xlsx first" 'manipulate_xlsx_first_main_Derek06122018)
; (manipulate_xlsx_main_Derek06122018)
; skill (encrypt "c:/skill/manipulate_xlsx_v2.il" "c:/skill/manipulate_xlsx_v2.ile")
; (load "manipulate_xlsx_v2.ile")
; (load "manipulate_xlsx_v2.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup