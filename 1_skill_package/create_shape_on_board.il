;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction

; Developer: Derek Hsu
; Starting Date: 3/26/2019
; Description:
;	1. create numbers of shape align the board outline. the feature is including
;		1. route keepin shape: all the routing has to be within the void of this shape (this shape should be a circle)
;		2. route keepout shape: all the routing has to be out of the shape (this shape may be a block)
;		3. package keepin shape: all the package(footprint) has to be within the void of this shape
;	2. the default setting:
;		1. route keepout/GND: 20 mil
;		2. route keepout/ETCH: 30 mil
;		3. route keepout/PWR: 40 mil
;		4. route keepin/all: 20 mil
;		5. package keepin/all: 80 mil
;	3. the placement of the shape
;		1. the shape will align the inner side of the biggest board outline
;		2. the shape will align the outer side of the numbers of board outline inside of the boundary
;	4. the function in form
;		1. the content of the grid:
;			1. layer: the layer name set in teh xsection
;			2. type: gnd/etch/pwr
;			3. rko: the width for route keepout shape
;			4. rki: the width for route keepin shape
;			5. pki: the width for package keepin shape
;		2. buttons
;			1. create: create all the shape above
;			2. clear: remove all the shape aligning the board outline
;			3. close: close this form
;			4. help: the description of this form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; init

(procedure init()
	(setq _shape_on_board_form_name "shape_on_board_form.form")
	
	;;;;; the summary of the etch
	(setq _etch_ls (axlGetParam "paramLayerGroup:ETCH")->groupMembers)
	(setq _total_etch (length _etch_ls))
	
	;;;;; the default value of the shape away from board outline
	(setq _rko_gn_out_wid 20.0) ; _rko_gn_wid
	(setq _rko_et_out_wid 30.0)
	(setq _rko_pw_out_wid 40.0)
	(setq _rki_al_out_wid 20.0)
	(setq _pki_al_out_wid 120.0)
	(setq _rko_gn_in_wid 20.0)
	(setq _rko_et_in_wid 30.0)
	(setq _rko_pw_in_wid 40.0)
	(setq _rki_al_in_wid 20.0)
	(setq _pki_al_in_wid 120.0)
	
	;;; id
	(setq _rko_et_out "rko_et_out")
	(setq _rko_gn_out "rko_gn_out")
	(setq _rko_pw_out "rko_pw_out")
	(setq _rki_al_out "rki_al_out")
	(setq _pki_al_out "pki_al_out")
	(setq _rko_et_in "rko_et_in")
	(setq _rko_gn_in "rko_gn_in")
	(setq _rko_pw_in "rko_pw_in")
	(setq _rki_al_in "rki_al_in")
	(setq _pki_al_in "pki_al_in")
	
	;;;;; the min and the max of the float value of the grid
	(setq _min_mil 1.0)
	(setq _max_mil 200.0)
	
	;;;;; the definition of the column of the grid
	(setq _grid_layer_col 1)
	(setq _grid_type_col 2)
	(setq _grid_rko_col 3)
	(setq _grid_rki_col 4)
	(setq _grid_pki_col 5)
	
	;;;;; general information
	(setq _etch "ETCH")
	(setq _gnd "GND")
	(setq _pwr "PWR")
	(setq _vcc "VCC")
	(setq _created_shape_prop (list 'CLIP_DRAWING "BOARD_OUTLINE"))
	(setq _type_options (list _pwr _gnd _etch))
	(setq _bg_outline "BOARD GEOMETRY/OUTLINE")
	(setq _rki_all "ROUTE KEEPIN/ALL")
	(setq _pki_all "PACKAGE KEEPIN/ALL")
	(setq _rko_cls "ROUTE KEEPOUT")
	(setq _rko_ls (axlGetParam "paramLayerGroup:ROUTE KEEPOUT")->groupMembers)
	(setq _rko_ls (mapcan (lambda (m) (unless (equal "ALL" m) (list (strcat _rko_cls "/" m)))) _rko_ls))
	(setq _boundary_ly_ls (append1 (append1 _rko_ls _rki_all) _pki_all))
	(setq _no_fill_sh_ly_ls (list _pki_all _rki_all))
	(setq _outline_hole_ls get_brdoutline_ishole_ls())
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of init

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

(procedure create_shape_on_board_form()
	;;; define name of the grid
	(prog (out_port etch_ls type_ls button_y)
		(unless (outportp (out_port = (outfile _shape_on_board_form_name "w"))) (println "create_shape_on_board_form() - Fail to write file") (return nil))
		
		;;;;; header of the form
		(fprintf out_port "FILE_TYPE=FORM_DEFN VERSION=%d\n" 1)   
		(fprintf out_port "FORM TOOLWINDOW \n")
		(fprintf out_port "FIXED\n")
		(fprintf out_port "PORT %d %d\n" 86 90)
		(fprintf out_port "HEADER \"Create Shape On Board\"\n\n")
		
		(fprintf out_port (strcat "POPUP <type_options>" (buildString '("\"PWR\"\"PWR\"" 
																		"\"GND\"\"GND\""
																		"\"ETCH\"\"ETCH\""
																		) ",") ".\n\n"))
		
		(fprintf out_port "TILE\n\n")
		
		;;;;; navigator bar
		;;; all
		(fprintf out_port "GROUP \"GAP (OUT\\IN)\"\n")
		(fprintf out_port "FLOC %d %d\n" 1 1)
		(fprintf out_port "TSSIZE %d %d\n" 27 24)
		(fprintf out_port "ENDGROUP\n\n")
		
		;;; rko
		(out_x = 9)
		(in_x = 18)
		(slash_x = 17)
		(title_x = 4)
		(group_x = 2)
		(group_wid = 25)
		
		(fprintf out_port "GROUP \"%s\"\n" 'RKO)
		(fprintf out_port "FLOC %d %d\n" group_x 3)
		(fprintf out_port "TSSIZE %d %d\n" group_wid 11)
			
			;; blank for gap - rko - etch - out/in
			(line_y = 5)
			(fprintf out_port "TEXT \"%s:\" \n" 'ETCH)
			(fprintf out_port "FLOC %d %d\n" title_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rko_et_out)	
			(fprintf out_port "FLOC %d %d\n" out_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "TEXT \"\\\" \n")
			(fprintf out_port "FLOC %d %d\n" slash_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rko_et_in)	
			(fprintf out_port "FLOC %d %d\n" in_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
			
			;; blank for gap - rko - gnd - out/in
			(line_y = 8)
			(fprintf out_port "TEXT \"%s:\" \n" 'GND)
			(fprintf out_port "FLOC %d %d\n" title_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rko_gn_out)	
			(fprintf out_port "FLOC %d %d\n" out_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "TEXT \"\\\" \n")
			(fprintf out_port "FLOC %d %d\n" slash_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rko_gn_in)	
			(fprintf out_port "FLOC %d %d\n" in_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
			
			;; blank for gap - rko - pwr - out/in
			(line_y = 11)
			(fprintf out_port "TEXT \"%s:\" \n" 'PWR)
			(fprintf out_port "FLOC %d %d\n" title_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rko_pw_out)	
			(fprintf out_port "FLOC %d %d\n" out_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "TEXT \"\\\" \n")
			(fprintf out_port "FLOC %d %d\n" slash_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rko_pw_in)	
			(fprintf out_port "FLOC %d %d\n" in_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
		(fprintf out_port "ENDGROUP\n\n")
		
		;;; rki
		(fprintf out_port "GROUP \"%s\"\n" 'RKI)
		(fprintf out_port "FLOC %d %d\n" group_x 14)
		(fprintf out_port "TSSIZE %d %d\n" group_wid 5)
			(line_y = 16)
			(fprintf out_port "TEXT \"%s:\" \n" 'ALL)
			(fprintf out_port "FLOC %d %d\n" title_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rki_al_out)	
			(fprintf out_port "FLOC %d %d\n" out_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "TEXT \"\\\" \n")
			(fprintf out_port "FLOC %d %d\n" slash_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _rki_al_in)	
			(fprintf out_port "FLOC %d %d\n" in_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
		(fprintf out_port "ENDGROUP\n\n")
		
		;;; pki
		(fprintf out_port "GROUP \"%s\"\n" 'PKI)
		(fprintf out_port "FLOC %d %d\n" group_x 19)
		(fprintf out_port "TSSIZE %d %d\n" group_wid 5)
			(line_y = 21)
			(fprintf out_port "TEXT \"%s:\" \n" 'ALL)
			(fprintf out_port "FLOC %d %d\n" title_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _pki_al_out)	
			(fprintf out_port "FLOC %d %d\n" out_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
			
			(fprintf out_port "TEXT \"\\\" \n")
			(fprintf out_port "FLOC %d %d\n" slash_x line_y)
			(fprintf out_port "ENDTEXT\n")
			
			(fprintf out_port "FIELD %s\n" _pki_al_in)	
			(fprintf out_port "FLOC %d %d\n" in_x line_y)
			(fprintf out_port "REALFILLIN %d %d\n" 6 6)
			(fprintf out_port "MIN %.2f\n" _min_mil)
			(fprintf out_port "MAX %.2f\n" _max_mil)
			(fprintf out_port "ENDFIELD\n")
		(fprintf out_port "ENDGROUP\n\n")
		
		;;;;; grid for data
		(fprintf out_port "GRID %s\n" 'shape_grid)
		(fprintf out_port "FLOC %d %d\n" 29 1)
		(fprintf out_port "FSIZE %d %d\n" 56 24)
		(fprintf out_port "OPTIONS HLINES VLINES USERSIZE MULTISELROW\n")
		(fprintf out_port "GHEAD TOP\n")
		(fprintf out_port "HEADSIZE %d\n" 2)
		(fprintf out_port "OPTIONS %s\n" "3D")
		(fprintf out_port "ENDGHEAD\n")
		(fprintf out_port "ENDGRID\n\n")
		
		;;;;; buttons
		(button_y = 26)
		
		(fprintf out_port "FIELD %s\n" 'apply)
		(fprintf out_port "FLOC %d %d\n" 2 button_y)
		(fprintf out_port "MENUBUTTON \"%s\" %d %d\n" "APPLY" 6 2)
		(fprintf out_port "ENDFIELD\n\n")
		
		(fprintf out_port "FIELD %s\n" 'create)
		(fprintf out_port "FLOC %d %d\n" 11 button_y)
		(fprintf out_port "MENUBUTTON \"%s\" %d %d\n" "CREATE" 6 2)
		(fprintf out_port "ENDFIELD\n\n")
		
		(fprintf out_port "FIELD %s\n" 'clear)
		(fprintf out_port "FLOC %d %d\n" 21 button_y)
		(fprintf out_port "MENUBUTTON \"%s\" %d %d\n" "CLEAR" 6 2)
		(fprintf out_port "ENDFIELD\n\n")
		
		(fprintf out_port "FIELD %s\n" 'close)
		(fprintf out_port "FLOC %d %d\n" 30 button_y)
		(fprintf out_port "MENUBUTTON \"%s\" %d %d\n" "CLOSE" 6 2)
		(fprintf out_port "ENDFIELD\n\n")
		
		(fprintf out_port "FIELD %s\n" 'form_help)
		(fprintf out_port "FLOC %d %d\n" 76 button_y)
		(fprintf out_port "MENUBUTTON \"%s\" %d %d\n" "HELP" 6 2)
		(fprintf out_port "ENDFIELD\n\n")
		
		;;;;; tail of the form
		(fprintf out_port "ENDTILE\n\n")
		(fprintf out_port "ENDFORM\n")
		
		(close out_port)
		
		(return t)
	)
)

(procedure get_type_value(type option @optional form)
	(prog (result)
		(unless (stringp type) (printf "ArgErr: get_type_value() - [type] is not string") (return nil))
		;;
		
		(caseq option
			('color
				(cond
					((equal _pwr type) (result = 'yellow))
					((equal _gnd type) (result = 'red))
					((equal _etch type) (result = 'green))
					(t (printf "get_type_value() - option[%s] does not support type[%s]\n" option type))
				)
			)
			('rko
				(cond
					((equal _pwr type) (result = _rko_pw_out))
					((equal _gnd type) (result = _rko_gn_out))
					((equal _etch type) (result = _rko_et_out))
					(t (printf "get_type_value() - option[%s] does not support type[%s]\n" option type))
				)
			)
			('out_wid
				(cond
					((equal _pwr type) (result = _rko_pw_out_wid))
					((equal _gnd type) (result = _rko_gn_out_wid))
					((equal _etch type) (result = _rko_et_out_wid))
					(t (printf "get_type_value() - option[%s] does not support type[%s]\n" option type))
				)
			)
			('in_wid
				(cond
					((equal _pwr type) (result = _rko_pw_in_wid))
					((equal _gnd type) (result = _rko_gn_in_wid))
					((equal _etch type) (result = _rko_et_in_wid))
					(t (printf "get_type_value() - option[%s] does not support type[%s]\n" option type))
				)
			)
			('rko_type
				(cond
					((member type (list _rko_et_out _rko_et_in)) (result = _etch))
					((member type (list _rko_gn_out _rko_gn_in)) (result = _gnd))
					((member type (list _rko_pw_out _rko_pw_in)) (result = _pwr))
					(t (printf "get_type_value() - option[%s] does not support type[%s]\n" option type))
				)
			)
			(t (printf "get_type_value() - Not support optin[%s]\n" option))
		)
		
		(return result)
	)
)

(procedure create_form_row(shape_on_board_form layer type rko_out rki_out pki_out rko_in rki_in pki_in)
	(prog (color cell val)
		(unless (axlIsFormType shape_on_board_form) (println "ArgErr: create_form_row() - Fail Form ID") (return nil))
		(unless (axlIsLayer (strcat _etch "/" layer)) (println "ArgErr: create_form_row() - Fail Layer") (return nil))
		(unless (member type _type_options) (println "ArgErr: create_form_row() - Missing options") (return nil))
		(unless (and (numberp rko_out) (plusp rko_out)) (printf "ArgErr: create_form_row(%L) - Missing rko_out number\n" rko_out) (return nil))
		(unless (and (numberp rki_out) (plusp rki_out)) (println "ArgErr: create_form_row() - Missing rki_out number") (return nil))
		(unless (and (numberp pki_out) (plusp pki_out)) (println "ArgErr: create_form_row() - Missing pki_out number") (return nil))
		(unless (and (numberp rko_in) (plusp rko_in)) (println "ArgErr: create_form_row() - Missing rko_in number") (return nil))
		(unless (and (numberp rki_in) (plusp rki_in)) (println "ArgErr: create_form_row() - Missing rki_in number") (return nil))
		(unless (and (numberp pki_in) (plusp pki_in)) (println "ArgErr: create_form_row() - Missing pki_in number") (return nil))
		;;
		
		;;; create a new row to first line
		(axlFormGridInsertRows shape_on_board_form "shape_grid" 0 1)
		
		;;; column for layer
		(cell = axlFormGridNewCell())
		(cell->row = 1)
		(cell->col = 1)
		(cell->value = layer)
		(cell->noEdit = t)
		(axlFormSetField shape_on_board_form "shape_grid" cell)
		
		;;; column for type
		(cell = axlFormGridNewCell())
		(cell->row = 1)
		(cell->col = 2)
		(cell->value = type)
		(cell->noEdit = nil)
		(color = (get_type_value type 'color))
		(when (symbolp color) (cell->backColor = color))
		(axlFormSetField shape_on_board_form "shape_grid" cell)
		
		;;; column for rko
		(cell = axlFormGridNewCell())
		(cell->row = 1)
		(cell->col = 3)
		(sprintf val "%.2f\\%.2f" rko_out rko_in)
		(cell->value = val)
		(cell->noEdit = nil)
		(axlFormSetField shape_on_board_form "shape_grid" cell)
		
		;;; column for rki
		(cell = axlFormGridNewCell())
		(cell->row = 1)
		(cell->col = 4)
		(sprintf val "%.2f\\%.2f" rki_out rki_in)
		(cell->value = val)
		(cell->noEdit = nil)
		(axlFormSetField shape_on_board_form "shape_grid" cell)
		
		;;; column for pki
		(cell = axlFormGridNewCell())
		(cell->row = 1)
		(cell->col = 5)
		(sprintf val "%.2f\\%.2f" pki_out pki_in)
		(cell->value = val)
		(cell->noEdit = nil)
		(axlFormSetField shape_on_board_form "shape_grid" cell)
		
		;;; update th egrid setting
		(axlFormGridUpdate shape_on_board_form "shape_grid")
	)
)

(procedure set_shape_on_board_form(shape_on_board_form)
	(let (col etch_ls type_ls rko_out rko_in)
		(data_wid = 8)
		;;; the column of the layer
		(col = make_formGridCol())
		(col->fieldType = 'TEXT)
		(col->colWidth = 8)
		(col->align = 'left)
		(col->headText = "LAYER")
		(col->scriptLabel = "grid_ly")
		(axlFormGridInsertCol shape_on_board_form "shape_grid" col)
		
		;;; the column of the type
		(col = make_formGridCol())
		(col->fieldType = 'ENUMSET)
		(col->colWidth = 5)
		(col->align = 'left)
		(col->headText = "TYPE")
		(col->scriptLabel = "grid_tp")
		(col->popup = "type_options")
		(axlFormGridInsertCol shape_on_board_form "shape_grid" col)
		
		;;; the column of the route keepout
		(col = make_formGridCol())
		(col->fieldType = 'TEXT)
		(col->colWidth = data_wid)
		(col->align = 'left)
		(col->headText = "RKO")
		(col->scriptLabel = "grid_rko")
		(col->decimals = 2)
		(axlFormGridInsertCol shape_on_board_form "shape_grid" col)
		
		;;; the column of  the route keepin
		(col = make_formGridCol())
		(col->fieldType = 'TEXT)
		(col->colWidth = data_wid)
		(col->align = 'left)
		(col->headText = "RKI")
		(col->scriptLabel = "grid_rki")
		(axlFormGridInsertCol shape_on_board_form "shape_grid" col)
		
		;;; the column of the package keepin
		(col = make_formGridCol())
		(col->fieldType = 'TEXT)
		(col->colWidth = data_wid)
		(col->align = 'left)
		(col->headText = "PKI")
		(col->scriptLabel = "grid_pki")
		(axlFormGridInsertCol shape_on_board_form "shape_grid" col)
		
		;;; setup row
		(etch_ls = (reverse _etch_ls))
		(type_ls = (get_layer_types etch_ls))
		;;
		(foreach (etch type) etch_ls type_ls
			(rko_out = (get_type_value type 'out_wid))
			(rko_in = (get_type_value type 'in_wid))
			;;
			(create_form_row shape_on_board_form etch type rko_out _rki_al_out_wid _pki_al_out_wid rko_in _rki_al_in_wid _pki_al_in_wid)
		)
		
		;;; refresh the grid
		(axlFormGridUpdate shape_on_board_form "shape_grid")
		
		;;; setup left side value
		(axlFormSetField shape_on_board_form _rko_et_out _rko_et_out_wid)
		(axlFormSetField shape_on_board_form _rko_gn_out _rko_gn_out_wid)
		(axlFormSetField shape_on_board_form _rko_pw_out _rko_pw_out_wid)
		(axlFormSetField shape_on_board_form _rki_al_out _rki_al_out_wid)
		(axlFormSetField shape_on_board_form _pki_al_out _pki_al_out_wid)
		;;
		(axlFormSetField shape_on_board_form _rko_et_in _rko_et_in_wid)
		(axlFormSetField shape_on_board_form _rko_gn_in _rko_gn_in_wid)
		(axlFormSetField shape_on_board_form _rko_pw_in _rko_pw_in_wid)
		(axlFormSetField shape_on_board_form _rki_al_in _rki_al_in_wid)
		(axlFormSetField shape_on_board_form _pki_al_in _pki_al_in_wid)
		
		;;; set APPLY as the default button
		(axlFormDefaultButton shape_on_board_form "apply")
	)
)

(procedure set_grid(shape_on_board_form row col val)
	(prog (cell color)
		(unless val (println "ArgErr: set_grid() - value is nil") (return nil))
		(unless (and (plusp row) (integerp row)) (println "ArgErr: set_grid() - row is not positive integer") (return nil))
		(unless (and (plusp col) (integerp col)) (println "ArgErr: set_grid() - col is not positive integer") (return nil))
		;;
		
		(cell = axlFormGridNewCell())
		(cell->row = row)
		(cell->col = col)
		(cell = (axlFormGridGetCell shape_on_board_form "shape_grid" cell))
		(unless cell (printf "set_grid() - Fail to set cell%L on grid\n" (list row col)) (return nil))
		
		;;;; change color if the column is in type
		(when (eqv _grid_type_col col)
			(color = (get_type_value val 'color))
			(cell->backColor = color)
		)
		
		;;;; set value
		(cell->value = val)
		(axlFormSetField shape_on_board_form "shape_grid" cell)
		
		;;;; update grid
		(axlFormGridUpdate shape_on_board_form "shape_grid")
		
		(return t)
	)
)

(procedure get_layers_by_type(action type @optional (c2num t))
	;;; c2num - convert to number
	(prog (cell c etch_ls)
		(unless (member type _type_options) (printf "ArgErr: get_layers_by_type() - type[%L] has to be IN _type_options" type) (return nil))
		;;
		(cell = axlFormGridNewCell())
		(for row 1 _total_etch
			(cell->col = _grid_type_col)
			(cell->row = row)
			(c = (axlFormGridGetCell action "shape_grid" cell))
			;;
			(when (equal type c->value)
				(cell->col = _grid_layer_col)
				(c = (axlFormGridGetCell action "shape_grid" cell))
				(etch_ls = (append1 etch_ls c->value))
			)
		)
		
		(when c2num
			(etch_ls = (mapcar (lambda (e) (add1 (listnindex _etch_ls e))) etch_ls))
		)
		
		(return etch_ls)
	)
)

(procedure get_boundary_table(action)
	;;; return the shape by ((gap shape_layer_ls)...)
	(let (boundary_table cell layer rko_layer rko rki pki layer_ls)
	
		(boundary_table = (makeTable "boundary_table" nil))
		
		(cell = axlFormGridNewCell())
		(for row 1 _total_etch
			(cell->row = row)
			
			;;; get layer name on current row
			(cell->col = _grid_layer_col)
			(layer = (axlFormGridGetCell action "shape_grid" cell)->value)
			(rko_layer = (strcat _rko_cls "/" layer))
			
			;;; get route keepout on current row
			(cell->col = _grid_rko_col)
			(rko = (axlFormGridGetCell action "shape_grid" cell)->value)
			
			;;; get route keepin on current row
			(cell->col = _grid_rki_col)
			(rki = (axlFormGridGetCell action "shape_grid" cell)->value)
			
			;;; get package keepin on current row
			(cell->col = _grid_pki_col)
			(pki = (axlFormGridGetCell action "shape_grid" cell)->value)
			
			;;; store layer to corresponded gap key
			(boundary_table[rko] = (append1 boundary_table[rko] rko_layer))
			(boundary_table[rki] = (append1 boundary_table[rki] _rki_all))
			(boundary_table[pki] = (append1 boundary_table[pki] _pki_all))
		)
		
		;;; remove duplicate layer in the same gap
		(foreach gap boundary_table
			(layer_ls = boundary_table[gap])
			(layer_ls = (get_uni_list layer_ls))
			(boundary_table[gap] = layer_ls)
		)
		
		; (foreach gap boundary_table (printf "%.2f: %L\n" gap boundary_table[gap]))
		
		boundary_table
	)
)

(procedure get_oi_bundle_data(action gap_id)
	;;; receive either out or in gap identification and return bundle data 
	(prog (cell out in result)
		(unless (stringp gap_id) (println "ArgErr: get_oi_bundle_data() - gap_id is not string") (return nil))
		;;
		
		(cell = axlFormGridNewCell())
		(cond
			((member gap_id (list _rko_et_out _rko_et_in))
				(out = (axlFormGetField action _rko_et_out))
				(in = (axlFormGetField action _rko_et_in))
			)
			((member gap_id (list _rko_gn_out _rko_gn_in))
				(out = (axlFormGetField action _rko_gn_out))
				(in = (axlFormGetField action _rko_gn_in))
			)
			((member gap_id (list _rko_pw_out _rko_pw_in))
				(out = (axlFormGetField action _rko_pw_out))
				(in = (axlFormGetField action _rko_pw_in))
			)
			((member gap_id (list _rki_al_out _rki_al_in))
				(out = (axlFormGetField action _rki_al_out))
				(in = (axlFormGetField action _rki_al_in))
			)
			((member gap_id (list _pki_al_out _pki_al_in))
				(out = (axlFormGetField action _pki_al_out))
				(in = (axlFormGetField action _pki_al_in))
			)
			(t
				(printf "Fail to map gap_id: %s\n" gap_id)
			)
		)
		
		(when (and (floatp out) (floatp in))
			(sprintf result "%.2f\\%.2f" out in)
		)
		
		(return result)
	)
)

(procedure shape_on_board_form_action(action)
	(prog (field col row val rko_type data rko rki pki row_ls)
		(field = action->curField)
		(val = action->curValue)
		;;
		(cond
			((equal "shape_grid" field)
				(col = action->col)
				(row = action->row)
				;;
				(when (eqv _grid_type_col col)
					;; change rko/rki/pki value
					(set_grid action row _grid_type_col val)
					
					;;; update rko value in current row
					(rko_type = (get_type_value val 'rko))
					(data = (get_oi_bundle_data action rko_type))
					(set_grid action row _grid_rko_col data)
					
					;;; update rki value in current row
					(data = (get_oi_bundle_data action _rki_al_out))
					(set_grid action row _grid_rki_col data)
					
					;;; update pki value in current row
					(data = (get_oi_bundle_data action _pki_al_out))
					(set_grid action row _grid_pki_col data)
				)
			)
			((member field (list _rko_et_out _rko_gn_out _rko_pw_out _rko_et_in _rko_gn_in _rko_pw_in))
				(type = (get_type_value field 'rko_type))
				(row_ls = (get_layers_by_type action type))
				;;
				(cell = axlFormGridNewCell())
				(cell->col = _grid_rko_col)
				(data = (get_oi_bundle_data action field))
				(cell->value = data)
				;;
				(foreach row row_ls
					(cell->row = row)
					(axlFormSetField action "shape_grid" cell)
				)
				;;
				(axlFormGridUpdate action "shape_grid")
			)
			((member field (list _rki_al_out _rki_al_in))
				(cell = axlFormGridNewCell())
				(cell->col = _grid_rki_col)
				(data = (get_oi_bundle_data action field))
				(cell->value = data)
				;;
				(for row 1 _total_etch
					(cell->row = row)
					(axlFormSetField action "shape_grid" cell)
				)
				;;
				(axlFormGridUpdate action "shape_grid")
			)
			((member field (list _pki_al_out _pki_al_in))
				(cell = axlFormGridNewCell())
				(cell->col = _grid_pki_col)
				(data = (get_oi_bundle_data action field))
				(cell->value = data)
				;;
				(for row 1 _total_etch
					(cell->row = row)
					(axlFormSetField action "shape_grid" cell)
				)
				;;
				(axlFormGridUpdate action "shape_grid")
			)
			((equal "apply" field)
				;;; display current information...
				(boundary_table = (get_boundary_table action))
				(println "To-be-created shape by gap size")
				(foreach gap boundary_table (printf "Gap: %s\n\t%L\n" gap boundary_table[gap]))
			)
			((equal "create" field)
				;;; create all the shape with 0 width
				(boundary_table = (get_boundary_table action))
				(create_shape_on_boundary boundary_table)
			)
			((equal "clear" field)
				;;; remove all the shape from the board outline
				remove_shape_on_board_outline()
			)
			((equal "close" field)
				;;; close the form
				(axlFormClose action)
				axlCancelEnterFun()
			)
			((equal "form_help" field)
				;;; display help document
			)
		)
		
		(return t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

(procedure get_uni_list(obj_ls)
	;;; remove duplicate elements from list
	(prog (result)
		(unless (dtpr obj_ls) (println "ArgErr: get_uni_list() - Arg is nil") (return nil))
		;;
		
		(ele1 = (car obj_ls))
		(cond
			((integerp ele1)
				(result = (maplist (lambda (x) (if (memv (car x) (cadr x)) nil (car x))) obj_ls))
				(result = (setof x result x))
			)
			((floatp ele1)
				(result = (maplist (lambda (x) (if (exists y (cdr x) (axlGeoEqual (car x) y)) nil (car x))) obj_ls))
				(result = (setof x result x))
			)
			((symbolp ele1)
				(result = (maplist (lambda (x) (if (memq (car x) (cdr x)) nil (car x))) obj_ls))
				(result = (setof x result x))
			)
			((stringp ele1)
				(result = (maplist (lambda (x) (if (member (car x) (cdr x)) nil (car x))) obj_ls))
				(result = (setof x result x))
			)
			(t
				(printf "get_uni_list() - Fail to identify elements from %L\n" obj_ls)
				(return nil)
			)
		)
		
		(return result)
	)
)

(procedure get_poly_from_outline(outline expand is_belt)
	;;  outline = (car axlGetSelSet())
	(prog (poly_ls solid_outline_poly expanded_poly_ls operation outline_path solid_poly_ls result)
		(unless (equal "path" outline->objType) (println "ArgErr: get_poly_from_outline() - outline is not a path object") (return nil))
		(unless (plusp expand) (println "ArgErr: get_poly_from_outline() - expand is not a number") (return nil))
		(unless (booleanp is_belt) (println "ArgErr: get_poly_from_outline() - is_belt is not in boolean type") (return nil))
		;;
		
		;;; create poly in belt
		(expand = (float expand))
		(poly_ls = (axlPolyFromDB outline))
		(expanded_poly_ls = (axlPolyExpand poly_ls expand 'ALL_ARC))
		
		;;; create poly in real type of outline
		(outline_path = (axlDB2Path outline))
		(solid_poly_ls = (axlPolyFromDB outline_path))
		
		;;; merge
		(operation = (if is_belt 'AND 'OR))
		(result = (axlPolyOperation expanded_poly_ls solid_poly_ls operation))
		
		; (axlDBCreateShape poly t "ETCH/TOP")
		; (foreach p result (axlDBCreateShape p t "ETCH/TOP"))
		; (foreach p poly_ls (axlDBCreateShape p t "ETCH/TOP"))
		; (foreach p solid_poly_ls (axlDBCreateShape p t "ETCH/TOP"))
		; (foreach p expanded_poly_ls (axlDBCreateShape p t "ETCH/TOP"))
		;  (axlVisibleUpdate t)
		
		(return result)
	)
)

(procedure get_belts_solids_table(gap_ls)
	;;; gap_ls: ("39.00\\40.00" "120.00\\120.00" "30.00\\30.00" "20.00\\20.00") /// (outer_gap//inner_gap)
	;;; outer_gap will be created in belt
	;;; inner_gap will be created in solid
	;;; return format: ([gap]:(([belt poly]...) ([solid poly]...))...)
	(prog (belts_solids_table outline_hole_ls outline_ls hole_ls oi_ls belt_gap solid_gap solid_poly_ls belt_poly_ls)
		(unless (dtpr gap_ls) (return nil))
		(unless (forall g gap_ls (stringp g)) (println "ArgErr: get_belts_solids_table() - Arg is not string list") (return nil))
		;;
		
		;;
		(belts_solids_table = (makeTable "belts_solids_table" nil))
		
		;;
		(outline_hole_ls = _outline_hole_ls)
		(outline_ls = (mapcan (lambda (x) (unless (cadr x) (list (car x)))) outline_hole_ls))
		(hole_ls = (mapcan (lambda (x) (when (cadr x) (list (car x)))) outline_hole_ls))
		
		(foreach gap_oi gap_ls
			(oi_ls = (parseString gap_oi "\\"))
			(belt_gap = (atof (car oi_ls)))
			(solid_gap = (atof (cadr oi_ls)))
			(belt_poly_ls = solid_poly_ls = nil)
			;;
			(when (dtpr outline_ls)
				(belt_poly_ls = (mapcar (lambda (x) (get_poly_from_outline x belt_gap t)) outline_ls))
			)
			;;
			(when (dtpr hole_ls)
				(solid_poly_ls = (mapcar (lambda (x) (get_poly_from_outline x solid_gap nil)) hole_ls))
			)
			;;
			(belts_solids_table[gap_oi] = (list belt_poly_ls solid_poly_ls))
		)
		
		(return belts_solids_table)
	)
)

(procedure create_shape(poly ly_nm)
	(prog (fill)
		(unless (equal "polygon" poly->objType) (println "ArgErr: create_shape() - poly is not in polygon type") (return nil))
		(unless (stringp ly_nm) (println "ArgErr: create_shape() - ly_nm is not string") (return nil))
		(unless (axlIsLayer ly_nm) (println "ArgErr: create_shape() - ly_nm is not a layer name") (return nil))
		;;
		
		(fill = t)
		(when (exists s _no_fill_sh_ly_ls (equal ly_nm s))
			;;; the shape in this section can not be fill-type
			(fill = nil)
			(hole_ls = poly->holes)
			;;
			(when (dtpr hole_ls)
				(num_hole = (length hole_ls))
				;;
				(if (onep num_hole) then
					(poly = (car (axlPolyFromHole (car hole_ls))))
				else
					(printf "create_shape() - More than one hole[%d] one current poly on layer[%s]\n" num_hole ly_nm)
				)
			)
		)
		
		(shape_id = (car (axlDBCloak 'axlDBCreateShape( poly fill ly_nm) 'shape)))
		
		(return shape_id)
	)
)

(procedure create_shape_on_boundary(boundary_table)
	;;; create all the shape on relative layer
	;;; key: gap of the shape from the board outline
	;;; value: the uni list of layer for shapes
	;;; hint: for hole of the board: place rko only
	(prog (belts_solids_table gap_ls last_sh_id gap_ovpath_ls)
		(gap_ls = boundary_table->?)
		(unless (dtpr gap_ls) (println "ArgErr: create_shape_on_boundary() - No gap in boundary_table") (return nil))
		;;
		
		;;; get ("poly in belt" "poly in solid") by gap table
		(belts_solids_table = (get_belts_solids_table gap_ls))
		
		;;; create shape by poly
		(foreach gap gap_ls
			(layer_ls = boundary_table[gap])
			(belts_solids_ls = belts_solids_table[gap])
			(poly_belt_ls = (setof x (car belts_solids_ls) x))
			(poly_solid_ls = (setof x (cadr belts_solids_ls) x))
			;;
			
			(foreach ly_nm layer_ls
				(foreach poly_ls poly_belt_ls
					(unless (dtpr poly_ls) (poly_ls = (list poly_ls)))
					(last_sh_id = nil)
					;;
					(foreach poly poly_ls
						(shape_id = (create_shape poly ly_nm))
					;	(shape_id = (car (axlDBCloak 'axlDBCreateShape( poly t ly_nm) 'shape)))
						;;
						(if last_sh_id then
							(last_sh_id = (axlShapeMerge shape_id last_sh_id))
						else
							(last_sh_id = shape_id)
						)
					)
					;;
					(axlDBAddProp last_sh_id _created_shape_prop)
				)
				(foreach poly_ls poly_solid_ls
					(unless (dtpr poly_ls) (poly_ls = (list poly_ls)))
					(last_sh_id = nil)
					;;
					(foreach poly poly_ls
						(shape_id = (create_shape poly ly_nm))
					;	(shape_id = (car (axlDBCloak 'axlDBCreateShape( poly t ly_nm) 'shape)))
						;;
						(if last_sh_id then
							(last_sh_id = (axlShapeMerge shape_id last_sh_id))
						else
							(last_sh_id = shape_id)
						)
					)
					;;
					(axlDBAddProp last_sh_id _created_shape_prop)
				)
			)
		)
		
		(return t)
	)
)

(procedure is_pt_in_poly(pt se_ls)
	;;; the coordination in xy_ls has to be in cyclic
	(prog (result thru_left_line_cnt)
		(unless (dtpr pt) (println "ArgErr: is_pt_in_poly() - pt is nil") (return nil))
		(unless (dtpr se_ls)(println "ArgErr: is_pt_in_poly() - xy is not a list") (return nil))
		;;
		
		(px = (car pt))
		(py = (cadr pt))
		
		(thru_left_line_cnt = 0)
		(foreach se se_ls
			;;; ((x1 y1) (x2 y2))
			(x1 = (caar se))
			(y1 = (cadar se))
			(x2 = (caadr se))
			(y2 = (cadadr se))
			
			;;; check whether the point is in the vertical range of se
			(when (or (and (y2 <= py) (y1 > py)) (and (y2 > py) (y1 <= py)))
				;;; use angle bisector theorem to get projected x
				(vt = ((py - y2) / (y1 - y2)))
				(x = (x2 + vt * (x1 - x2)))
				
				;; count 1 if 
				(when (px < x) thru_left_line_cnt++)
			)
		)
		
		;;;
		(result = (oddp thru_left_line_cnt))
		
		(return result)
	)
)

(procedure is_hole_in_board(tar_li outline_ls)
	;;; if xy, which is supposed to be the center of the shape, is in the hole of the board, then to return t
	;;; if xy is in the even number(2,4...) of board outlines, then xy is in the hole of the board
	(prog (tar_seg_ls is_hole tar_se tar_xy1 tar_xy2 xy1_is_hole xy2_is_hole )
		(unless tar_li (println "ArgErr: is_hole_in_board() - tar_li is nil") (return nil))
		(unless (dtpr outline_ls) (println "ArgErr: is_hole_in_board() - outline_ls is not a list") (return nil))
		;;
		
		(tar_seg_ls = tar_li->segments)
		(foreach tar_seg tar_seg_ls
			(unless is_hole
				;;; get start/end point from a segment
				(tar_se = tar_seg->startEnd)
				(tar_xy1 = (car tar_se))
				(tar_xy2 = (cadr tar_se))
				
				;;; check either start or end point is in any outline
				(xy1_is_hole = (exists outline outline_ls (is_pt_in_poly tar_xy1 outline->segments~>startEnd)))
				(xy2_is_hole = (exists outline outline_ls (is_pt_in_poly tar_xy2 outline->segments~>startEnd)))
				
				;;; if one of the point is in any outline, this inter section can be regard as a hole.
				(is_hole = (or xy1_is_hole xy2_is_hole))
			)
		)
		
		(return is_hole)
	)
)

(procedure get_brdoutline_ishole_ls()
	(let (outline_ls line_hole_ls)
		;;; show board outline layer only
		(display_layers _bg_outline)
		
		;;; get all board outline on current layer
		(axlSetFindFilter ?enabled "lines" ?onButtons "lines")
		axlAddSelectAll()
		(outline_ls = axlGetSelSet())
		axlClearSelSet()
		
		;;; detect whether is hole on a board
		(if (onep (length outline_ls)) then
			(line_hole_ls = (list (list (car outline_ls) nil)))
		else
			(line_hole_ls = (mapcar (lambda (x) (list x (is_hole_in_board x (remq x outline_ls)))) outline_ls))
		)
		
		line_hole_ls
	)
)

(procedure display_layers(layer_ls)
	;;; display all the layer in the layer list
	(prog ()
		(unless layer_ls (return nil))
		(unless (dtpr layer_ls) (layer_ls = (list layer_ls)))
		(unless (forall x layer_ls (axlIsLayer x)) (println "ArgErr: display_layers() - not layers") (return nil))
		;;
		
		;;; mark all invisiable
		(axlVisibleDesign nil)
		
		;;; mark all layer in layer_ls visible
		(foreach layer layer_ls (axlVisibleLayer layer t))
		
		;;; update canvas
		(axlVisibleUpdate t)
	)
)

(procedure remove_shape_on_board_outline()
	;;;; the content has to be updated later. to remove the shape with certainty property
	(let (sh_ls prop_val prop_val_eval outline_sh_ls)
		(sh_ls = (axlDBGetShapes nil))
		
		(prop_val = (cadr _created_shape_prop))
		(sprintf prop_val_eval "s->prop->%s" (car _created_shape_prop))
		(outline_sh_ls = (mapcan (lambda (s) (when (equal prop_val (evalstring prop_val_eval)) (list s))) sh_ls))
		
		(if (dtpr outline_sh_ls) then
			(foreach sh_id outline_sh_ls
				(printf "Removing board outline shape on layer[%s]\n" sh_id->layer)
				(axlDeleteObject sh_id)
			)
		else
			(println "None of the shape has been removed")
		)
		
		(axlVisibleUpdate t)
	)
)

(procedure get_layer_types(etch_ls)
	(prog (result)
		(unless (forall e etch_ls (axlIsLayer (strcat "ETCH/" (e || "")))) (println "ArgErr: get_layer_types() - Not etch layers") (return nil))
		;;
		
		(foreach layer etch_ls
			(layer = (upperCase layer))
			(et_ly_nm = (strcat _etch "/" layer))
			(ly_id = (axlLayerGet et_ly_nm))
			(type = ly_id->type)
			;;
			(case type
				("CONDUCTOR"
					(result = (append1 result _etch))
				)
				("PLANE"
					(if (or (index layer _vcc) (index layer _pwr))
						(result = (append1 result _pwr))
						(result = (append1 result _gnd))
					)
				)
				(t
					(printf "Fail to define layer[%s], the default would be PWR\n" layer)
					(result = (append1 result _pwr))
				)
			)
		)
		
		(return result)
	)
)

(defun create_shape_on_board_main ()
	(prog (vis_ls)
		(unless axlOKToProceed() (println "Please done current executing function to keep continue") (return nil))
		;;
		
		(vis_ls = axlVisibleGet())
		
		init()
		
		;;;;; check at least one board outline exists
		(unless _outline_hole_ls (println "No board outline has been found") (return nil))
		
		;;;;; create form and setup
		(unless create_shape_on_board_form() (return nil))
		
		;;; create th eform id
		(shape_on_board_form = (axlFormCreate gensym() _shape_on_board_form_name '("east" "outer") 'shape_on_board_form_action t))
		(unless (axlIsFormType shape_on_board_form) (return nil))
		
		;;; initlize the data of the form and fill up the grid
		(set_shape_on_board_form shape_on_board_form)
		
		;;; make all the cell, which is not noEdit, changable
;		(axlFormGridEvents shape_on_board_form "shape_grid" 'change)
;		(axlFormGridEvents shape_on_board_form "shape_grid" nil)
		
		;;; display the the form
		(axlFormDisplay shape_on_board_form)
		
		(axlVisibleSet vis_ls)
		(axlVisibleUpdate t)
		(println "Create shapes aligning board outline successfully. Please check this out")
		
		
		(return t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "create_shape_on_board" 'create_shape_on_board_main)
create_shape_on_board_main()
; skill (encrypt "c:/skill/create_shape_on_board_v1.il" "c:/skill/create_shape_on_board_v1.ile")
; (load "create_shape_on_board_v1.ile")
; (load "create_shape_on_board_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup