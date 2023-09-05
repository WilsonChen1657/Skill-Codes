;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
; AUTHOR: DEREK HSU
; STARTING DATE: 07/04/2017 - _Derek07042017
; PURPOSE: GET 2S3W DATA FORM FOR TUNING THE DIFFPAIR BUMP. (SPACING 2 TIMES AND WIDTH 3 TIMES
; USAGE: OPEN THE TOOL, YOU WILL GET THE DEFAULT 2S3W DEFINED HEIHT AND LENGTH OF THE BUMP. LATER ON, YOU CAN IMPORT THE VALUE TO THE PHASE_TUNE DIRECTLY BY A BUTTON
; DATA FORM: NONE
; 	(SPACING)[     ]X[     ] = [     ](LENGTH)
; 	  (WIDTH)[     ]X[     ] = [     ](HEIGHT)
; 				{IMPORT TO PHASE TUNE}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global varuable
procedure( init_Derek07042017()
	setq( _display_form_name "phase_tune_aid.form")
	setq( _phase_help_filename "phase_help.txt")
	setq( spacing nil)
	setq( width nil)
	setq( _coef_wid 3.0)
	setq( _coef_hei 0.9)
	setq( _want_import nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; form

procedure( write_phase_tune_aid_form_Derek07042017()
	prog( ( out_port entry_y )
		out_port = outfile( _display_form_name "w")
		unless( outportp( out_port) println( "ArgErr: phase_tune_aid_form_builder() - Fail to write file") return( nil))
		
		fprintf( out_port "FILE_TYPE=FORM_DEFN VERSION=1\n")   
		fprintf( out_port "FORM TOOLWINDOW \n")	
		fprintf( out_port "FIXED\n")
		fprintf( out_port "PORT %d %d\n" 36 50)
		fprintf( out_port "HEADER \"Phase Tune Aid v1.0\"\n")
		fprintf( out_port "TILE\n")
		
		entry_y = 1
		
		;;;;;;;;;; LENGTH PART
		fprintf( out_port "TEXT \"Diff &W\" \n")
		fprintf( out_port "FLOC %d %d\n" 1 entry_y)
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD len_base\n") ; base number
		fprintf( out_port "FLOC %d %d\n" 6 entry_y)
		fprintf( out_port "REALFILLIN 5 5\n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "TEXT \"*\" \n")
		fprintf( out_port "FLOC %d %d\n" 13 entry_y)
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD len_coef\n") ; coefficient	
		fprintf( out_port "FLOC %d %d\n" 15 entry_y)
		fprintf( out_port "REALFILLIN %d %d\n" 5 5)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "TEXT \"=\" \n")
		fprintf( out_port "FLOC %d %d\n" 22 entry_y)
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD len_res\n") ; result	
		fprintf( out_port "FLOC %d %d\n" 24 entry_y)
		fprintf( out_port "REALFILLIN %d %d\n" 5 5)
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "TEXT \"Bump &L\" \n")
		fprintf( out_port "FLOC %d %d\n" 31 entry_y)
		fprintf( out_port "ENDTEXT\n")

		;;;;;;;;;; HEIGHT PART
		entry_y = entry_y + 2
		
		fprintf( out_port "TEXT \"Diff &S\" \n")
		fprintf( out_port "FLOC 1 3\n")
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD hei_base\n") ; base number
		fprintf( out_port "FLOC 6 3\n")
		fprintf( out_port "REALFILLIN 5 5\n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "TEXT \"*\" \n")
		fprintf( out_port "FLOC 13 3\n")
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD hei_coef\n") ; coefficient	
		fprintf( out_port "FLOC 15 3\n")
		fprintf( out_port "REALFILLIN 5 5\n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "TEXT \"=\" \n")
		fprintf( out_port "FLOC 22 3\n")
		fprintf( out_port "ENDTEXT\n")
		
		fprintf( out_port "FIELD hei_res\n") ; result	
		fprintf( out_port "FLOC 24 3\n")
		fprintf( out_port "REALFILLIN 5 5\n")
		fprintf( out_port "ENDFIELD\n")
		
		fprintf( out_port "TEXT \"Bump &H\" \n")
		fprintf( out_port "FLOC 31 3\n")
		fprintf( out_port "ENDTEXT\n")
		
		;;;;;;;;;; BUTTON ON THE BUTTOM
		fprintf( out_port "FIELD phase_zero\n")
		fprintf( out_port "FLOC 1 1\n")
		fprintf( out_port "MENUBUTTON \"zero\" 8 1\n")
		fprintf( out_port "ENDFIELD\n\n")
		
		fprintf( out_port "FIELD phase_import\n")
		fprintf( out_port "FLOC 3 5\n")
		fprintf( out_port "MENUBUTTON \"Import\" 8 1\n")
		fprintf( out_port "ENDFIELD\n\n")
		
		fprintf( out_port "FIELD phase_close\n")
		fprintf( out_port "FLOC 15 5\n")
		fprintf( out_port "MENUBUTTON \"Close\" 8 1\n")
		fprintf( out_port "ENDFIELD\n\n")

		fprintf( out_port "FIELD phase_help\n")
		fprintf( out_port "FLOC 27 5\n")
		fprintf( out_port "MENUBUTTON \"Help\" 8 1\n")
		fprintf( out_port "ENDFIELD\n\n")
		
		fprintf( out_port "ENDTILE\n")
		fprintf( out_port "ENDFORM\n")
		
		close( out_port)
		
		
		return( t)
	)
)

procedure( set_phase_form_data_Derek07042017( out_form)
	prog( ()
		;;;;; set default button
		axlFormSetFieldVisible( out_form "phase_zero" 0)
		
		;;;;; block some of the textbox
		axlFormSetFieldEditable( out_form "len_base" nil)
		axlFormSetFieldEditable( out_form "len_res" nil)
		axlFormSetFieldEditable( out_form "hei_base" nil)
		axlFormSetFieldEditable( out_form "hei_res" nil)
		
		;;;;; initialize the default value
		axlFormSetField( out_form "len_coef" _coef_wid)
		axlFormSetField( out_form "hei_coef" _coef_hei)
	
		return( t)
	)
)

procedure( phase_form_action_Derek07042017( out_form)
	(result = nil)
	setq( choice out_form->curField)
	(case out_form->curField
		("phase_import"
			;println("press: phase_import")
			(_want_import = t)
			axlCancelEnterFun()
			axlFormClose(out_form)
		)
		("phase_close"
			;println("press: phase_close")
			axlCancelEnterFun()
			axlFormClose(out_form)
		)
		("phase_help"
			;println("press: phase_help")
			(if isFile(_phase_help_filename)
				axlUIViewFileCreate( _phase_help_filename "Phase Tune Aid - Help" nil)
				axlUIConfirm( (strcat "Unable to Open Help File, Check Permissions is on." getWorkingDir()))
			)
		)
		("hei_coef"
			;println("press: hei_coef")
			(when (numberp (result = out_form->curValue)) (_coef_hei = result))
			(when ((numberp _coef_hei) && (numberp spacing)) axlFormSetField( out_form "hei_res" (spacing * _coef_hei)))
		)
		("len_coef"
			;println("press: len_coef")
			(when (numberp (result = out_form->curValue)) (_coef_wid = result))
			(when ((numberp _coef_wid) && (numberp width)) axlFormSetField( out_form "len_res" (width * _coef_wid)))
		)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN FUNCTION ; (car axlGetSelSet())

procedure( get_located_layer_Derek07042017( picked_cline_seg) (cadr (parseString picked_cline_seg->layer "/"))) ; get_located_layer_Derek07042017((car axlGetSelSet()))

procedure( get_physical_cset_Derek07042017( picked_cline_seg) (axlNetClassGet picked_cline_seg 'physical t)->prop->PHYSICAL_CONSTRAINT_SET) ; get_physical_cset_Derek07042017((car axlGetSelSet()))

procedure( get_prim_gap_Derek07042017( picked_cline_seg) axlCNSGetPhysical(get_physical_cset_Derek07042017(picked_cline_seg) get_located_layer_Derek07042017(picked_cline_seg) 'dp_primary_gap )) ; get_prim_gap_Derek07042017((car axlGetSelSet()))

procedure( get_width_Derek07042017( picked_cline_seg) picked_cline_seg->width)

procedure( picking_Derek07042017()
	(picked_cline_seg = nil)
	
	axlClearSelSet()
	(while axlSelect()
		(picked_cline_seg = (car axlGetSelSet()))
		(when (width = get_width_Derek07042017(picked_cline_seg))
			;printf("width:%f, coef: %f\n" width axlFormGetField(out_form "len_coef"))
			axlFormSetField( out_form "len_base" width)
			axlFormSetField( out_form "len_res" (width * axlFormGetField(out_form "len_coef")))
		)
		(when (spacing = get_prim_gap_Derek07042017(picked_cline_seg))
			;printf("air gap:%f, coef: %f\n" spacing axlFormGetField(out_form "hei_coef"))
			axlFormSetField( out_form "hei_base" spacing)
			axlFormSetField( out_form "hei_res" (spacing * axlFormGetField(out_form "hei_coef")))
		)
		axlClearSelSet()
	)
)

procedure( write_help_file_Derek07042017()
	;_phase_help_filename
	(help_port = (outfile _phase_help_filename "w"))
	fprintf( help_port "This is introduction.\n If you have any question, please contact Derek.")
	close(help_port)
)

procedure( phase_tune_aid_main_Derek07042017()
	prog( ( heigh_command len_command)
		;;;;; initial global variable
		init_Derek07042017()
		
		;; set filter
		(axlSetFindFilter ?enabled (list "NOALL" "CLINESEGS") ?onButtons (list "NOALL" "CLINESEGS"))
		
		;; create the form
		write_phase_tune_aid_form_Derek07042017()
		write_help_file_Derek07042017()
		
		(out_form = (axlFormCreate (gensym) _display_form_name '("east" "outer") 'phase_form_action_Derek07042017 t))
		
		(if (axlIsFormType out_form) then
			set_phase_form_data_Derek07042017(out_form)
			axlFormDisplay(out_form)
			picking_Derek07042017()
		else
			(println "Phase form has not been created successfully.")
		)
		;; if the form is created then open the form

		(when _want_import
			(if ((numberp spacing) && (numberp _coef_hei) && (not ((zerop spacing) || (zerop _coef_hei)))) then
				sprintf(heigh_command "FORM mini dptune_height %f" (spacing * _coef_hei))
				println("The height has been imported.")
			else
				println("Err: The result of the spacing is not correct.")
			)
			(if ((numberp width) && (numberp _coef_wid) && (not ((zerop width) || (zerop _coef_wid)))) then
				sprintf(len_command "FORM mini dptune_length %f" (width * _coef_wid))
				println("The width has been imported.")
			else
				println("Err: The result of the width is not correct.")
			)
			(when ((stringp heigh_command) && (stringp len_command)) axlShellPost(strcat("phase_tune; " heigh_command "; " len_command)))
		)
	)
)

;(phase_tune_aid_main_Derek07042017)
(axlCmdRegister "phase_tune_aid" 'phase_tune_aid_main_Derek07042017)
; skill encrypt( "c:/skill/phase_tune_aid_v1.il" "c:/skill/phase_tune_aid_v1.ile")
;  axlCancelEnterFun()
; (load "phase_tune_aid_v1.il")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; END OF FUNCTION