/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/05/13                                                      #
#  Reference:                                                                  #
#  Introduction:                                                               #
#       To load whole skill program of basic and pdb footprint to menu from    #
#       a specific path in W                                                   #
#  Memo:                                                                       #
#       You can't define the menu by x_location because 'GO_Skill' may not     #
#       be the last one                                                        #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global variable

procedure( Init_pcbfootprintskilltdcflex()
	setq( _message_for_skill_package "Please map the \\tpint035\\ECAD to W before using this function")
	setq( _skill_base_path "W:/footprint_building_aid_skill/")
	setq( _skill_package_path sprintf( nil "%s2-0_pcb_footprint/" _skill_base_path))
	setq( _skill_base_ls cddr( getDirFiles( _skill_base_path)))
	setq( _skill_package_ls cddr( getDirFiles( _skill_package_path)))
	setq( _skill_menu "GO_Skill")
	setq( _load_menu_cmd "pcb_footprint_skill_tdc_flex")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_pcbfootprintskilltdcflex()
	prog( ( file_addr_ls dir_ile_ls ile_cmd_ls)
		unless( axlOKToProceed() 
			println( "Please done current command to use this function") 
			return( nil)
		)
		
		println( "----------------------------------------------------------------------------------------------------------- Start to load pcb footprint menu")
		
		Init_pcbfootprintskilltdcflex()
		
		unless( dtpr( _skill_base_ls) && dtpr( _skill_package_ls)
			printf( "ERROR: main() - %s" _message_for_skill_package)
			return( nil)
		)

		;;;;; check W disk has been built or not
		unless( isDir( _skill_base_path)
			printf("No directory exists on path: %s\n" _skill_base_path)
			return(nil)
		)
		
		unless( isDir( _skill_package_path)
			printf("No directory exists on path: %s\n" _skill_package_path)
			return(nil)
		)

		_skill_base_ls = sort( _skill_base_ls 'CompareIndex_skillpackagetdcflex)
		_skill_package_ls = sort( _skill_package_ls 'CompareIndex_skillpackagetdcflex)
		
		file_addr_ls = mapcar( lambda( (x) strcat( _skill_base_path x)) _skill_base_ls)
		file_addr_ls = append( file_addr_ls mapcar( lambda( (x) strcat( _skill_package_path x)) _skill_package_ls))
		
		dir_ile_ls = GetIleList_skillpackagetdcflex( file_addr_ls)
		ile_cmd_ls = GetIleCmdList_skillpackagetdcflex( file_addr_ls)
		
		;;;;; create new menu
		CreateMenu_skillpackagetdcflex( append( _skill_base_ls _skill_package_ls) ile_cmd_ls)
		SetMenu_skillpackagetdcflex()
		DeleteMenuItem_skillpackagetdcflex( "footprint_symbol_panel")
		
		;;;;; load all file to the allegro
		LoadAllIle_skillpackagetdcflex( file_addr_ls dir_ile_ls)
		
		println( "----------------------------------------------------------------------------------------------------------- Finish loading menu")
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup 

(axlCmdRegister "reset_menu" 'ResetMenu_skillpackagetdcflex)
(axlCmdRegister "pcb_footprint_skill_tdc_flex" 'Main_pcbfootprintskilltdcflex)
/*
(encrypt "C:/skill/pcb_footprint_tdc_skill_flex_v1d1.il" "C:/skill/pcb_footprint_tdc_skill_flex_v1d1.ile")
(load "pcb_footprint_tdc_skill_flex_v1d1.il")
(load "pcb_footprint_tdc_skill_flex_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup