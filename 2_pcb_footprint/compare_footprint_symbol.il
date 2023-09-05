/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/03/30                                                      #
#  Reference: utility_program                                                  #
#  Purpose:                                                                    #
#       To compare .dra file with files in W:\Library-Flex\Footprint-Symbol    #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable
procedure( init_comparefootprintsymbol()
	setq( _footprint_symbol_path "W:/Library-Flex/Footprint-Symbol/")
	setq( _footprint_symbol_ls cddr( getDirFiles( _footprint_symbol_path)))
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main
procedure( main_comparefootprintsymbol(@key (base_date_str "20200501"))
	prog( (base_time local_dir local_symbol_ls local_dra_ls w_dra_ls dra_table dra_addr modified_time time_str)
		load( "utility_program.ile")
		init_comparefootprintsymbol()

		base_time = ParseDate_utilityprogram(base_date_str)
		
		; select a Directory
		local_dir = axlDMDirectoryBrowse("W:/Library-Checking/Check/Rita/ok/" t ?title "Select a directory of symbols")
		; Directory path don't end with /
		local_dir = strcat( local_dir "/")
println( "get file list")
		local_symbol_ls = cddr( getDirFiles( local_dir))
		local_dra_ls = setof( x local_symbol_ls index( x ".dra"))
		
		w_dra_ls = setof( x _footprint_symbol_ls index( x ".dra"))
		; filter list in local
		w_dra_ls = setof( x w_dra_ls x member( x local_dra_ls))

		rowA = GetAlphabetByNumber_utilityprogram(1)
		rowB = GetAlphabetByNumber_utilityprogram(2)
		rowC = GetAlphabetByNumber_utilityprogram(3)
		rowD = GetAlphabetByNumber_utilityprogram(4)
		rowE = GetAlphabetByNumber_utilityprogram(5)
		
println( "create table")
		i = 1
		dra_table = makeTable( "dra_table" nil)
		
		col = i++
		table_setvalue_comparefootprintsymbol(dra_table rowA col "File name")
		table_setvalue_comparefootprintsymbol(dra_table rowB col "W:/ modified time")
		table_setvalue_comparefootprintsymbol(dra_table rowC col "ok modified time")
		table_setvalue_comparefootprintsymbol(dra_table rowE col "Base time")
		table_setvalue_comparefootprintsymbol(dra_table rowE col+1 ParseDateTimeToString_utilityprogram( base_time))
println( "start compare")
		foreach( dra w_dra_ls
			local_dra_addr = strcat( local_dir dra)
			w_dra_addr = strcat( _footprint_symbol_path dra)
			; get time modified
			local_modified_time = fileTimeModified(local_dra_addr)
			w_modified_time = fileTimeModified(w_dra_addr)
			
			cond(
				( (w_modified_time > local_modified_time)
					col = i++
					table_setvalue_comparefootprintsymbol(dra_table rowA col dra)
					table_setvalue_comparefootprintsymbol(dra_table rowB col ParseDateTimeToString_utilityprogram( w_modified_time))
					table_setvalue_comparefootprintsymbol(dra_table rowC col ParseDateTimeToString_utilityprogram( local_modified_time))
					table_setvalue_comparefootprintsymbol(dra_table rowD col "w > local")

				)
				( (w_modified_time > base_time)
					col = i++
					table_setvalue_comparefootprintsymbol(dra_table rowA col dra)
					table_setvalue_comparefootprintsymbol(dra_table rowB col ParseDateTimeToString_utilityprogram( w_modified_time))
					table_setvalue_comparefootprintsymbol(dra_table rowC col ParseDateTimeToString_utilityprogram( local_modified_time))
					table_setvalue_comparefootprintsymbol(dra_table rowD col "w > base")
				)
			)
		)
println( "finish compare")
		file_name = "compart_result.csv"
		OutputCSV_utilityprogram( file_name dra_table)
		printf( "compare finish. %s/%s" getWorkingDir() file_name)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( table_setvalue_comparefootprintsymbol( table row col value)
	prog( (field)
		field = strcat( row sprintf( nil "%d" col))
		table[ field] = value
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup 

(axlCmdRegister "compare_footprint_symbol" 'main_comparefootprintsymbol)
; (encrypt( "c:/skill/compare_footprint_symbol_1_22_0_1.il" "c:/skill/compare_footprint_symbol_1_22_0_1.ile"))
; (load "compare_footprint_symbol_1_22_0_1.il")
; (load "compare_footprint_symbol_1_22_0_1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup