;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; brcm_export_idf.il
; 
; Alex Diaz, BRCM
; Sep 2020
;
; 
; This script outputs the IDF files with the .emn and .emp file extensions using the built in idf_out command.
;  It then modifies the files by replacing the auto generated DEVICE_TYPE values with the BRCM_PN.
;  Parts placed as "OPEN" do not have the BRCMPN available and will have "OPEN_" as a prefix in the .emn and .emp files.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

axlCmdRegister( "brcm_export_idf" 'brcm_export_idf ?cmdType "general")

(defun brcm_export_idf ()
	
	currDesign = axlCurrentDesign()
	
	; idf_out uses the BOARD_THICKNESS design property if it exists.  This property value does not sync with the cross section.  
	; Remove the design's BOARD_THICKNESS property so the idf output uses the cross section board thickness info.
	axlDBDeleteProp( nil, "board_thickness")
	
	; idf filter config file
	idf_outConfigFilename = "BRCM_iDfFilterOut.config"
	
	; name type "PTC" will give .emn and .emp file extensions 
	idf_outNameType = "PTC"
	
	idf_outName = currDesign
	
	emnFilename = strcat("./" idf_outName ".emn")
	
	empFilename = strcat("./" idf_outName ".emp")
	
	
	; write the filter config file
	
	configString = "( filter    Route_Keepout_sym  Route_Keepout_board    Via_Keepout_sym  Via_Keepout_board  Vias  Panel_Outline  Package_Keepin  Package_Keepout  Unplaced_Comp  )"
	
	fp = outfile(idf_outConfigFilename "w")
	
	fprintf(fp "%s" configString)
	
	close(fp)
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; generate the mapping list
	;
	symdef_list = axlDBGetDesign()->symdefs	
	
	mapData = nil
	
	(foreach symdef_dbid symdef_list
	
		(if symdef_dbid->type == "PACKAGE" then
		
			(foreach instance symdef_dbid->instances
			
				refdes = instance->refdes
				
				;; get the compdef properties
				brcm_pn   = instance->component->prop->BRCMPN
				
				device_type = instance->component->deviceType
				;printf("Device type is %s\n" device_type)
				
				; no BRCMPN?
				(if brcm_pn == nil then
					printf("brcm_pn is nil\n");
					brcm_pn = device_type
					
				)
				
				; handle "OPEN" parts
				(if brcm_pn == "OPEN" then
				
					brcm_pn = strcat("OPEN_" device_type)
					
				);
				
				; add to the mapData if not already there
				(if device_type != nil then
				
					(if assoc(device_type mapData) == nil then
					
						mapData = cons(list(device_type brcm_pn) mapData)
						
					)
				)
				
			);end-foreach
			
		);end-if
		
	);foreach
	
	; sort mapData back to original order (not really needed)
	mapDataList = reverse(mapData)
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; export the idf file using the idf_out command
	;
	
	;For t_cmdFmt, the formatting should include everything except the design filename.
	;Place a %s where the design should appear. To get a %s while doing a sprintf, use a “%%s”
	;axlRunBatchDBProgram(
	;				t_prog
	;				t_cmdFmt
	;				... see help doc for more.
	
	sprintf(idfcom "idf_out %%s -d %s -o %s -c %s" idf_outNameType idf_outName idf_outConfigFilename)
	
	axlRunBatchDBProgram("idf_out" idfcom ?noExitMsgs t ?noLogview t)
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; update the .emp and .emn files.
	;
	
	; get the .emp file contents
	empString = ""
	
	fp = infile( strcat(empFilename) )
	
	while( gets( entry fp ) != 'nil
		
		empString = strcat(empString entry)

	);

	close( fp )
	
	; get the .emn file contents
	fp = infile( strcat(emnFilename) )
	
	emnString = ""
	
	while( gets( entry fp ) != 'nil
	
		emnString = strcat(emnString entry)

	);
	
	close( fp )
	
	; regex search and replace the DEVICE_TYPE with the BRCM_PN
	(foreach x mapDataList
	
		; nth(0 x) is the Cadence generated unique device name
		; nth(1 x) is the mapped BRCMPN
		
		; need the spaces before and after in the regex pattern to ensure the word match (don't want to match partial DEVICE_TYPE even though it should never happen)
		regexStr = strcat(" " nth(0 x) " ")
		
		rexCompile(regexStr)
		
		replace = strcat(" " nth(1 x) " ")
		
		empString = rexReplace(empString replace 0)
		
		emnString = rexReplace(emnString replace 0)
		
	);
	
	; write the new emp file
	fp = outfile(empFilename "w")
	
	fprintf(fp "%s" empString)
	
	close(fp)
	
	; write the new emn file
	fp = outfile(emnFilename "w")
	
	fprintf(fp "%s" emnString)
	
	close(fp)
	
	axlUIConfirm("Broadcom IDF output is complete.")
	
);