;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
; Author: Derek Hsu
; Date: 06/21/2017
; purpose: to create a stack up table for informationing the architechture
; usage: convert the certain form of the stack up data to the shape, to the shape, line and text at the cursor
;
; input form (excel):
;	PCB Stack-up / Signle End / Differential / Reference Plane
;	Layer, Material:*, CopperCoverage(%), Design Thickness, Thickness / 50 Ohm / 100 Ohm (main routing), 100 Ohm (break out routing)
;	Glass Type	DK at 1 GHz	DK at 6 GHz			unit : mil	W	Zo	W	S	Zdiff	Zcommon	D	W	S	Zdiff	Zcommon	D	
;	Solder mask		Green Liquid	3.75	3.75		0.6 	0.6		
;	TOP	SIG	Copper	1/3 oz+plating			30	1.80 	1.8	4.5	48.87 	4	10	98.8	27.4	0.143 	3.5	6	97.7	30.5	0.142 	L2
;			p.p	1067	3.54	3.44		2.80 	2.68
;	L2	GND	Copper	1/2 oz			80	0.60 	0.60 
;			core	1037x2	3.56	3.49		3.50 	3.5
;	L3	SIG	Copper	1/2 oz			30	0.60 	0.6	4	49.25 	4	10	98.5 	25.2 	0.158 	3.5	5	98.1 	28.5 	0.158 	L2 & L4
;	.....
;	BOT	SIG	Copper	1/3 oz+plating			30	1.80 	1.8	4.5	48.87 	4	10	98.8	27.4	0.143 	3.5	6	97.7	30.5	0.142 	L13
;	Solder mask		Green Liquid	3.75	3.75		0.6 	0.6													
;	Copper Foil : Inner: , TOP/BOT: 			Total thickness:		1.62			63.7 													
;	Surface Finished : OSP			Specification:		1.60			63.0 													
;	Tolerance:		mm			±10 %	±10%		±10%					±10%					
;	data
;
; output form: 
;	The stack up is 14 layers. All impedence calculation are based on the used of ( IT-170GRA1 ) meterial."
;	Please use this meterial unless otherwise agreed with Flex.
;	.
;	Layer / Layer Name / Plane Description / Layer Thickness (mil) / Copper Weight (oz) / Single End / Differential / Rerence Plane
;	..........
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variale
(setq _csv_filename nil) ; tar stack up table csv, get by browser

;;;;; get from csv file
(setq _csv_ls list()) ; whole data in csv
(setq _csv_raw_ls list())
(setq _material_name nil) ; material name. ex: IT-170GRA1
(setq _ohm_ls list())
(setq _w_ls list()) ; this is the positon of each w from single end or differential
(setq _single_ls list()) ; single end list ; ((ohm:50 w:(...) z0:(...)) ...) 
(setq _diff_ls list()) ; differential list ; ((ohm:100 type:"main routing" w:(...) s:(...) z0:(...)) (ohm:100 type:"break out" w:(...) s:(...) z0:(...))
(setq _diff_type_ls list())
(setq _cop_wt_ls list()) ; copper weight ; ("1/3 oz+plating" "1067" ...)
(setq _toler nil)
(setq _total_thick nil)
(setq _unit_thickness nil)

;;; trick gloal access
(setq _sig_count 0)
(setq _gnd_count 0)
(setq _vcc_count 0)
;;;

;;;;; key words to get tar value
(setq key_Wid "W") ; width
(setq key_Z "Z0") ; impedence
(setq key_sp "S") ; spacing
(setq key_zd "Zdiff")
(setq text_num "16")
(setq text_heigh axlGetParam(strcat("paramTextBlock:" text_num))->height)
(setq display_layer "BOARD GEOMETRY/ASSEMBLY_NOTES")
(setq etch_layer_list axlGetParam("paramLayerGroup:ETCH")->groupMembers)

(setq table_x 31500.0)
(setq table_y 16600.0)
(setq shift_y 55)

(setq block_y1 125)
(setq block_y2 250)
(setq block_y3 375)
(setq block_x1 900)
(setq block_x1d2 450)
(setq block_x1d3 300)
(setq block_x2 1800)
(setq block_x3 2700)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of golobal variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; main function

(defun get_csv_file_ls (file_address)
	(in_port = (infile file_address))
	(while gets(csv_line in_port); fscanf(in_port "%s" csv_line)
		;println(csv_line)
		;;;;; remove the null data line, which has comma only
		(when rexMatchp("[0-9a-zA-Z]+" csv_line) (_csv_raw_ls = append1(_csv_raw_ls csv_line)))
		(csv_line = parseString(csv_line ","))
		(unless (equal "\n" (car csv_line)) (_csv_ls = append1( _csv_ls csv_line)))
	)
	close(in_port)
)

(procedure create_line(sh_box) axlDBCreateLine(sh_box 0 display_layer))

(procedure create_shape(sh_box) axlDBCreateRectangle(sh_box nil display_layer))

(procedure create_text(center_xy text @optional (origin "center")) 
	myorient = make_axlTextOrientation(?textBlock text_num ?rotation 0.0 ?mirrored nil ?justify origin)
	axlDBCreateText( text, center_xy, myorient, display_layer, nil)
)

(procedure create_shape_text(sh_box text_ls)
;create_shape_text( (list (list 7000 6200) (list 7500 6000)) (list "first" "second"))
	;;;;; create shape
	create_shape(sh_box)
	
	;;;;; create text 
	(count = 0)
	(one = (car sh_box))
	(another = (cadr sh_box))
	(if ((cadr one) > (cadr another)) (higher = one) (higher = another))
	(center_x = (((car one) + (car another)) / 2))
	(center_y = ((cadr higher) - text_heigh / 2 - shift_y))
	(if listp(text_ls)
		(foreach text text_ls
			(create_text center_x:(center_y - count * block_y1) text)
			(count = (add1 count))
		)
		(create_text center_x:center_y text_ls)
	)
	t
)

(procedure move_down(move_y @optional (height block_y1)) (move_y - height))

(procedure get_box_by_top_left(top_left len_xy)
	(list top_left (list ((car top_left) + (car len_xy)) ((cadr top_left) - (cadr len_xy)))))

(defun create_topic (move_x move_y)
	(tmp_x = (move_x + block_x1 * 2 + block_x2 * 3))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1:block_y1) "Unit:mil")
	(move_y = move_down(move_y))
	
	;;; layers
	create_shape_text(get_box_by_top_left(move_x:move_y block_x1:block_y3) "Layer")
	(tmp_x = (move_x + block_x1))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1:block_y3) "Layer Name")
	(tmp_x = (tmp_x + block_x1))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y3) "Plane Description")
	(tmp_x = (tmp_x + block_x2))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y3) "Layer Thickness (mil)")
	(tmp_x = (tmp_x + block_x2))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y3) "Copper Weight (oz)")
	(tmp_x = (tmp_x + block_x2))
	
	;;; single end
	(unless (zerop (length _single_ls))
		(tmp_len = ((length _single_ls) * block_x1))
		create_shape_text(get_box_by_top_left(tmp_x:move_y tmp_len:block_y1) "Single End")
		(foreach one _single_ls
			;;;
			(tmp_y = (move_y - block_y1))
			create_shape_text(get_box_by_top_left(tmp_x:tmp_y block_x1:block_y2) strcat(one " Ohm"))
			;;;
			(tmp_y = (move_y - block_y1 - block_y2))
			create_shape_text(get_box_by_top_left(tmp_x:tmp_y block_x1d2:block_y1) "W")
			(tmp_x = (tmp_x + block_x1d2))
			create_shape_text(get_box_by_top_left(tmp_x:tmp_y block_x1d2:block_y1) "Z0")
			(tmp_x = (tmp_x + block_x1d2))
		)
	)
	
	;;; differential ; _diff_type_ls
	(unless (zerop (length _diff_ls))
		(tmp_len = ((length _diff_ls) * block_x1))
		create_shape_text(get_box_by_top_left(tmp_x:move_y tmp_len:block_y1) "Differential")
		(foreach one _diff_ls
			;;;
			(tmp_y = (move_y - block_y1))
			(if _diff_type_ls then
				(diff_topic = (list strcat(one " Ohm") (car _diff_type_ls)))
				(_diff_type_ls = (cdr _diff_type_ls))
			else
				(diff_topic = strcat(one " Ohm"))
			)
			create_shape_text(get_box_by_top_left(tmp_x:tmp_y block_x1:block_y2) diff_topic)
			;;;
			(tmp_y = (move_y - block_y1 - block_y2))
			create_shape_text(get_box_by_top_left(tmp_x:tmp_y block_x1d3:block_y1) "W")
			(tmp_x = (tmp_x + block_x1d3))
			create_shape_text(get_box_by_top_left(tmp_x:tmp_y block_x1d3:block_y1) "S")
			(tmp_x = (tmp_x + block_x1d3))
			create_shape_text(get_box_by_top_left(tmp_x:tmp_y block_x1d3:block_y1) "Zdiff")
			(tmp_x = (tmp_x + block_x1d3))
		)
	)
	
	;;; reference
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1:block_y3) (list "Reference" "Plane"))
	(tmp_y = (move_y - block_y3))
	create_shape(get_box_by_top_left(tmp_x:tmp_y block_x1:block_y1))
)

(defun create_table_diele_row (plane thickness move_x move_y)
	(tmp_x = move_x)
	create_shape(get_box_by_top_left(tmp_x:move_y block_x1:block_y1))
	(tmp_x = (tmp_x + block_x1))
	create_shape(get_box_by_top_left(tmp_x:move_y block_x1:block_y1))
	(tmp_x = (tmp_x + block_x1))
	(if plane 
		create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y1) plane)
		create_shape(get_box_by_top_left(tmp_x:move_y block_x2:block_y1)))
	(tmp_x = (tmp_x + block_x2))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y1) thickness)
	(tmp_x = (tmp_x + block_x2))
	create_shape(get_box_by_top_left(tmp_x:move_y block_x2:block_y1))
)

(defun create_table_ele_row (layer_info ext_info reference move_x move_y)
	(ext_count = 0)
	(tmp_x = move_x)
	
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1:block_y1) (nth 0 layer_info))
	(tmp_x = (tmp_x + block_x1))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1:block_y1) (nth 1 layer_info))
	(tmp_x = (tmp_x + block_x1))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y1) (nth 2 layer_info))
	(tmp_x = (tmp_x + block_x2))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y1) (nth 3 layer_info))
	(tmp_x = (tmp_x + block_x2))
	create_shape_text(get_box_by_top_left(tmp_x:move_y block_x2:block_y1) (nth 4 layer_info))
	(tmp_x = (tmp_x + block_x2))
	
	(when ext_info
		(foreach tmp _single_ls
			;;; w
			create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1d2:block_y1) (nth ext_count ext_info))
			(tmp_x = (tmp_x + block_x1d2))
			(ext_count = (add1 ext_count))
			;;; z0
			create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1d2:block_y1) (nth ext_count ext_info))
			(tmp_x = (tmp_x + block_x1d2))
			(ext_count = (add1 ext_count))
		)
		
		(foreach tmp _diff_ls
			;;; w
			create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1d3:block_y1) (nth ext_count ext_info))
			(tmp_x = (tmp_x + block_x1d3))
			(ext_count = (add1 ext_count))
			;;; s
			create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1d3:block_y1) (nth ext_count ext_info))
			(tmp_x = (tmp_x + block_x1d3))
			(ext_count = (add1 ext_count))
			;;; zdiff
			create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1d3:block_y1) (nth ext_count ext_info))
			(tmp_x = (tmp_x + block_x1d3))
			(ext_count = (add1 ext_count))
		)
	)
	
	(when reference create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1:block_y1) reference))
	(when (and (null reference) (equal "SIG" (nth 2 layer_info))) create_shape_text(get_box_by_top_left(tmp_x:move_y block_x1:block_y1) "NONE"))
	t
)

(defun get_layer_info (main_ls)
	;printf("get_layer_info: %s\n" main_ls)
	(block_ls = parseString(main_ls ","))
	(resu_ls = list())
	
	;;;;; get layer
	(layer_id = (car block_ls))
	(case (upperCase layer_id)
		("TOP" (layer = "L1"))
		("BOT" (sprintf layer "L%d" (_sig_count + _gnd_count + _vcc_count + 2))) ; 2 is to represent top and bottom
		(t (layer = (car block_ls)))
	)
	(block_ls = (cdr block_ls))
	
	;;;;; get plane description
	(case (upperCase (car block_ls))
		("SIG" (plane = "SIG"))
		("GND" (plane = "GND"))
		("PWR" (plane = "PWR"))
		(t (plane = "NONE"))
	)
	
	;;;;; get layer name
	(case (upperCase (car block_ls))
		("SIG" 
			(case layer_id ; TOP, BOT, L?
				("TOP" (layer_name = "TOP"))
				("BOT" (layer_name = "BOT"))
				(t (_sig_count = add1(_sig_count)) (sprintf layer_name "INT%d" _sig_count))
			)
		)
		("GND" (_gnd_count = add1(_gnd_count)) (sprintf layer_name "GND%d" _gnd_count)) 
		("PWR" (_vcc_count = add1(_vcc_count)) (sprintf layer_name "VCC%d" _vcc_count))
		(t (_vcc_count = add1(_vcc_count)) (sprintf layer_name "NONE%d" _vcc_count))
	)
	
	;;;;; get glass type
	(glass = (upperCase (caddr block_ls))) ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~might have error
	(unless (nindex glass "OZ") (glass = "NONE"))
	
	
	;;;;; get thickness
	;printf("main_ls: %s\n" main_ls)
	(thickness = get_thickness(main_ls))
	
	(list layer layer_name plane thickness glass)
)

(procedure get_thickness(csv_line)
	(let ()
		(thickness = get_data_csv(csv_line _unit_thickness))
		(when (and thickness (nindex thickness "\n")) (thickness = substring(thickness 1 (strlen(thickness) - 1))))
		(unless (and thickness (atof thickness)) (thickness = "NONE"))
		thickness)
)

(procedure count_comma(csv_line)
	(let ((count 0) (skip_comma nil))
		(for char 1 strlen(csv_line)
			(when (eq getchar("\"" 1) getchar(csv_line char)) (skip_comma = (not skip_comma)))
			(when (and (not skip_comma) (eq getchar("," 1) getchar(csv_line char))) (count = (add1 count)))
		)
		;printf("count_comma: %d::::::::::::::::::::::: %s\n" count csv_line)
		count)
)

(procedure get_data_csv(csv_line num)
	(let ((tar nil) (tmp_tar nil) (line csv_line) (count 0))
		(when (minusp num) (num = ((count_comma csv_line) + num + 1)))
		(for tmp 1 num
			;printf("%d/%d\n" tmp num)
			;println(line)
			(pos_quotes = (nindex line "\""))
			(pos_comma = ((nindex line ",") || (strlen line))) ; get the next comma or the last set
			(tar = substring(line 1 (sub1 pos_comma)))
			(line = substring(line (add1 pos_comma) strlen(line)))
			;printf("tar:line (%s,  %s)\n" tar line)
			
			;;;;; this block is used to skip the double quotes in csv
			(when (and pos_quotes (pos_quotes < pos_comma))
				(pos_quotes = (nindex line "\""))
				(tar = strcat(substring(tar 2 strlen(tar)) "," substring(line 1 (sub1 pos_quotes))))
				(line = substring(line (plus 2 pos_quotes) strlen(line)))
			)
			;println(line)
		)
		(if (or (equal "\n" tar) (equal "" tar)) nil tar))
)

(defun get_ext_info (line)
	(ext_li = list())
	(ext_single_num = (length _single_ls))
	
	(for zone 0 ((length _w_ls) - 1)
		(block = comma_divide_str(line (nth zone _w_ls)))
		(block_ext_ls = (parseString (cadr block) ","))
		(unless (equal "\n" (car block_ext_ls))
			(if (zone < ext_single_num) then ; single mode, get w and z0
				(ext_li = append1(ext_li (car block_ext_ls)))
				(ext_li = append1(ext_li (cadr block_ext_ls)))
			else ; diff mode, get w, s, 
				(ext_li = append1(ext_li (car block_ext_ls)))
				(ext_li = append1(ext_li (cadr block_ext_ls)))
				(ext_li = append1(ext_li (caddr block_ext_ls)))
			)
		)
	)
	
	ext_li
)

(defun create_table_content (move_x move_y)
	(content_start = nil)
	;println("enter create_table_content")
	(foreach (line raw) _csv_ls _csv_raw_ls
		;println(raw)
		;println(line)
		(when (and (null content_start) exists_in_ls(line (list "SOLDER" "MASK" "GREEN" "LIQUID")))
			(content_start = t))
		(when (and content_start exists_in_ls(line (list "FOIL" "TOTAL" "RTF" "STD")))
			(content_start = nil))
		(when content_start
			(csv_main_ext = comma_divide_str(raw _unit_thickness))
			(if (exists_in_ls line (list "SIG" "GND" "PWR")) then ; sig plane
				; ,TOP,SIG,Copper,1/3 oz+plating,,,30,1.80 ,1.8,4.5,48.87 ,4,10,98.8,27.4,0.143 ,3.5,6,97.7,30.5,0.142 ,5,6,84.2,25.8,0.143 ,L2
				; ,L3,SIG,Copper,1/2 oz,,,30,0.60 ,0.6,4,49.25 ,4,10,98.5 ,25.2 ,0.158 ,3.5,5,98.1 ,28.5 ,0.158 ,5,6,84.9 ,23.2 ,0.158 ,L2 & L4
				; ,BOT,SIG,Copper,1/3 oz+plating,,,30,1.80 ,1.8,4.5,48.87 ,4,10,98.8,27.4,0.143 ,3.5,6,97.7,30.5,0.142 ,5,6,84.2,25.8,0.143 ,L13
				; t skip \n and so -1
				(reference = (car (last line)))
				(if (nindex reference "L") (reference = (substring reference 1 ((strlen reference) - 1))) (reference = nil))
				
				; return two string '( "main table row" "extension row" )
				; if there is no extension info, then _w_ls would be nil
				println("normal")
				println(line)
				println((car csv_main_ext))
				(layer_info = get_layer_info((car csv_main_ext))) ; l1, top, sig, 1.8, oz??
				(ext_info = get_ext_info(raw)) ; w,zo,w,s,zdiff,w,s,zdiff...
				create_table_ele_row(layer_info ext_info reference move_x move_y)
			else ; dielectrical
				; ,,Solder mask,,Green Liquid,3.75,3.75,,0.6 ,0.6,,,,,,,,,,,,,,,,,,
				; ,, ,p.p,1067,3.54,3.44,,2.80 ,2.68,,,,,,,,,,,,,,,,,,
				; ,,Dual Ply Req.,core,1037x2,3.56,3.49,,3.50 ,3.5,,,,,,,,,,,,,,,,,,
				println("dielectric")
				println(line)
				println((car csv_main_ext))
				(if (exists_in_ls line (list "SOLDER" "MASK" "DUAL" "PLY" "REQ")) (plane = (car line)) (plane = nil))
				(thickness = get_thickness((car csv_main_ext)))
				create_table_diele_row(plane thickness move_x move_y)
			)
			
			;;;;;; move down one row
			(move_y = move_down(move_y))
		)
	)
)

(defun create_table_tail (move_x move_y)
	(if _toler (toler = strcat("+/-" _toler)) (toler = "NONE"))
	(if _total_thick (tot = strcat("Total Thickness               " _total_thick " mil(" toler " mil)")) (tot = "NONE"))
	
	(tmp = (block_x1 + block_x2 * 3))
	create_shape_text(get_box_by_top_left(move_x:move_y tmp:block_y1) tot)
	(tmp_x = (move_x + tmp))
	
	(tmp = 0)
	(when _single_ls (tmp = ((length _single_ls) * block_x1)) create_shape_text(get_box_by_top_left(tmp_x:move_y tmp:block_y1) toler))
	(tmp_x = (tmp_x + tmp))
	
	(when _diff_ls (tmp = ((length _diff_ls) * block_x1)) create_shape_text(get_box_by_top_left(tmp_x:move_y tmp:block_y1) toler))
)

(defun create_table_line (move_x move_y)
	;;;;; raise up a line for single end
	(tmp_x = move_x)
	(high_y = (block_y1 * (((_sig_count + _gnd_count + _vcc_count + 2) * 2) + 1)))
	(foreach tmp _single_ls
		(tmp_x = (tmp_x + block_x1))
		create_line(get_box_by_top_left(tmp_x:move_y 0:-high_y))
	)
	
	;;;;; raise up a line for differential
	(foreach tmp _diff_ls
		(tmp_x = (tmp_x + block_x1))
		create_line(get_box_by_top_left(tmp_x:move_y 0:-high_y))
	)
	
	;;;;; raise up a line for reference plane
	(tmp_y = (move_y + block_y1))
	(tmp_x = (tmp_x + block_x1))
	create_line(get_box_by_top_left(tmp_x:tmp_y 0:-high_y))
	
)
	
(defun create_table ()
	(move_x = table_x)
	(move_y = table_y)
	
	;;;;; skip the topic
	(move_y = move_down(move_y))
	(move_y = move_down(move_y))
	
	;;;;; create topic
	create_topic(move_x move_y)
	(move_y = move_down(move_y block_y1)) ; unit : mil
	(move_y = move_down(move_y block_y3)) ; topic
	
	;;;;; create table content
	create_table_content(move_x move_y)
	(move_y = move_down(move_y (block_y1 * (2 * (_sig_count + _gnd_count + _vcc_count + 2) + 1))))
	
	;;;;; create tolerance
	(tmp_x = (move_x + block_x1))
	create_table_tail(tmp_x move_y)
	
	;;;;; many lines for extension
	(tmp_x = (move_x + block_x1 * 2 + block_x2 * 3))
	create_table_line(tmp_x move_y)
	; create_line
	
	;;;;; create material textline
	(text = strcat("The stack up is " sprintf(nil "%d" (_sig_count + _gnd_count + _vcc_count + 2)) " layers. All impedence calculation are based on the used of ( " _material_name " ) meterial."))
	create_text(table_x:table_y text "left")
	(move_y = move_down(table_y))
	create_text(table_x:move_y "Please use this material unless otherwise agreed with Flex." "left")
	(move_y = move_down(move_y))
)

(procedure get_material_name()
	(name = nil)
	(foreach line _csv_ls
		(while (line && (null name))
			(when (nindex (upperCase (car line)) "MATERIAL") (name = (cadr line)))
			(line = (cdr line))
		)
	)
	name
)

(procedure get_ohm_ls()
	;;; get all ohm
	(ohms = list())
	(previous = " ")
	(foreach line _csv_ls
		(when (and (null ohms) exists_in_ls(line (list "DESIGN" "LAYER" "MATERIAL" "BREAK" "ROUT" "OUT" "OHM")))
			(foreach ele line
				(when (and (not (nindex previous "MATERIAL")) rexMatchp("[0-9]+" ele)) (ohms = append1(ohms rexSubstitute("\\0"))))
				(previous = upperCase(ele))
			)
			;;; get diff type
			(foreach ele line (when rexMatchp("([a-z A-Z]+)" ele) (_diff_type_ls = (append1 _diff_type_ls rexSubstitute("\\0")))))
		)
	)
	ohms
)

(procedure get_single_diff()
	;;;;; for general case, there may not have single end or differential, so you need to use alter fector to determind the function
	rexCompile("^[zZ][oO]$")
	(single_num = 0)
	(count = 0)
	(found = nil)
	(tmp_ls = _ohm_ls)
	(foreach line _csv_ls
		(when ((null found) && exists_in_ls(line (list "UNIT" "GLASS" "ZDIFF" "ZCOMMOR")))
			(single_num = (length (rexMatchList "^[zZ][oO]$" line)))
			(for ele 1 single_num (_single_ls = append1(_single_ls (car tmp_ls))) (tmp_ls = (cdr tmp_ls)))
			(_diff_ls = tmp_ls)
			(found = t)
		)
	)
)

(procedure exists_in_ls(tar_ls key_ls)
	(found = nil)
	(foreach ele tar_ls ;; loop through all element in list 
		(unless found
			(foreach key key_ls ;; loop through all key
				(unless found (found = (nindex upperCase(ele) upperCase(key))))
			)
		)
	)
	found
)

(procedure exists_in_string(tar key_ls)
	(found = nil)
	(foreach key key_ls (unless found (found = (nindex upperCase(tar) upperCase(key)))))
	found
)

(procedure get_w_ls()
	; ",,,,Glass Type,DK at 1 GHz,DK at 6 GHz,,,unit : mil,W,Zo,W,S,Zdiff,Zcommon,D,W,S,Zdiff,Zcommon,D,W,S,Zdiff,Zcommon,D,"
	(ww = list())
	(comma_count = 0)
	(foreach line _csv_raw_ls
		(when (and (null ww) (exists_in_string line (list "UNIT" "GLASS" "ZDIFF" "ZCOMMOR")))
			(for char 1 strlen(line)
				;println(char)\,
				; (equal getchar("," 1) getchar(a 3))
				(when (equal getchar("," 1) getchar(line char)) (comma_count = (add1 comma_count)))
				(when (equal "W" upperCase(getchar(line char))) (ww = append1(ww comma_count)))
			)
			;println("ed")
		)
	)
	ww
)

(procedure comma_divide_str(raw_line comma_num)
	(real_pos = nil)
	(skip_comma = nil)
	(comma_count = 0)
	(total_len = strlen(raw_line))
	(when comma_num
		(for char 1 total_len
			(when (eq getchar("\"" 1) getchar(raw_line char)) (skip_comma = (not skip_comma)))
			(unless skip_comma
				(when (equal getchar("," 1) getchar(raw_line char)) (comma_count = (add1 comma_count)))
				(when (and (null real_pos) (eq comma_count comma_num)) (real_pos = char))
			)
		))
	
	(if real_pos
		(list (substring raw_line 1 real_pos) (substring raw_line real_pos total_len))
		(list raw_line))
)

(procedure get_total_thick()
	(tot_thi = nil) ; total thickness
	(foreach line _csv_ls
		(when (and (null tot_thi) (exists_in_ls line (list "FOIL" "RTF" "TOTAL")))
			(tot_thi = (car (reverse line)))
			(when (equal tot_thi "\n") (tot_thi = (cadr (reverse line))))
		)
	)
	(if tot_thi sprintf(nil "%.1f" (atof tot_thi)) nil)
)

(procedure get_toler()
	(toler = nil)
	(foreach line _csv_ls
		(when (and (null toler) (exists_in_ls line (list "TOLER" "TOLERANCE")))
			(toler = (car (reverse line)))
			(when (equal toler "\n") (toler = (cadr (reverse line))))
			(when (nindex toler "\n") (toler = substring(toler 1 ((strlen toler) - 1))))
			(if (nindex toler " ") (toler = substring(toler -4 4)) (toler = substring(toler -3 3)))
		)
	)
	toler
)

(procedure get_unit_thickness()
	(col = nil)
	(let ((col nil))
		(foreach line _csv_raw_ls
			(when (and (null col) exists_in_string(line (list "UNIT" "GLASS" "ZDIFF" "ZCOMMOR")))
				(total = (count_comma line))
				;println(line)
				;println(total)
				(for ele 1 total
					;printf("%d/%d\n" ele total)
					(data = get_data_csv(line ele))
					;println(data)
					(when (and data (null col) (nindex upperCase(data) "UNIT")) (col = ele))
					;println(col)
				)
			)
		)
		col)
)

(defun stack_up_table_main ()
	
	;;;;; user searches the file from window browser
	(csv_address = axlDMFileBrowse("COMMA_SEPARATED_VALUE" nil))
	
	(if (and csv_address isFile(csv_address)) then
		;;;;; get _csv_ls without null line
		get_csv_file_ls(csv_address)
		
		;;;;; get meterial name
		(unless (_material_name = get_material_name()) (_material_name = "NoName!!!!!") println("Material name has not found."))
		(unless (_unit_thickness = get_unit_thickness()) println("No thickness value has been found."))
		(unless (_w_ls = get_w_ls()) println("No W value has been found."))
		(unless (_ohm_ls = get_ohm_ls()) println("No ohm value has been found."))
		(unless (_toler = get_toler()) println("No tolerance has been found."))
		(unless (_total_thick = get_total_thick()) println("No Total thickness has been found."))
		(when _ohm_ls get_single_diff())
		(if _unit_thickness then
			create_table()
			println("The table has been created.")
		else
			pritnln("The table will not be created.")
		)
	else
		println("The file you selected is not a csv file. Please select again.")
	)
	;;;;; process the content to the shape and text to the certain layers. what also has the stick on the cursor
)

(stack_up_table_main)
(axlCmdRegister "stack_up" 'stack_up_table_main)
;; (load "stack_up_table_creater_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of main function