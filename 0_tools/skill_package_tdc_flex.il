;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; developer: Derek Hsu
; Starting Date: 02/01/2018 - _Derek02012018
; introduction: a package to load whole skill program to menu from a specific path in T
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

(defun init_Derek02012018 ()
	(setq skill_path_in_t "T:/Layout/SOP/skill_tool_by_Derek/")
	(setq skill_folder_ls (cddr (getDirFiles skill_path_in_t)))
	(setq skill_menu "GO_Skill")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

(procedure get_ile_ls_Derek02012018(file_addr_ls)
	(dir_ile_ls = nil)
	
	(foreach addr file_addr_ls
		(file_ls = (getDirFiles addr))
		(ile_ls = (mapcan (lambda (x) (when (index x ".ile") (list x))) file_ls))
		(unless (onep (length ile_ls))
			printf("More than 1 or no .ile file is found in path: %s\n" addr)
		)
		(dir_ile_ls = (append1 dir_ile_ls (car ile_ls)))
	)
	
	dir_ile_ls
)

(procedure load_all_ile_Derek02012018(file_addr_ls dir_ile_ls)
	(foreach (addr ile) file_addr_ls dir_ile_ls
		(when ile
			(ile_addr = (strcat addr "/" ile))
			(load ile_addr)
			printf("skill program has been load: %s\n" ile)
		)
	)
)

(procedure get_ile_cmd_ls_Derek02012018(file_addr_ls)
	(ile_cmd_ls = nil)
	
	(foreach addr file_addr_ls
		(file_ls = (getDirFiles addr))
		(txt_ls = (mapcan (lambda (x) (when (index x ".txt") (list x))) file_ls))
		(if (onep (length txt_ls)) then
			(txt_addr = (strcat addr "/" (car txt_ls)))
			
			(if (inportp (in_port = (infile txt_addr))) then
				(gets line in_port)
				
				(if (index line "command:") then
					(cmd = (cadr (parseString line ":")))
					(cmd = (substring cmd 1 (sub1 (strlen cmd))))
					(ile_cmd_ls = (append1 ile_cmd_ls cmd))
				else
					(ile_cmd_ls = (append1 ile_cmd_ls nil))
					printf("No command has been found in txt: %s\n" txt_addr)
				)
				
				(close in_port)
			else
				(ile_cmd_ls = (append1 ile_cmd_ls nil))
				printf("Txt can't be opened in path: %s\n" txt_addr)
			)
		else
			(ile_cmd_ls = (append1 ile_cmd_ls nil))
			printf("No command has been found in path: %s\n" addr)
		)
	)
	
	ile_cmd_ls
)

(defun create_menu_Derek02012018 (skill_folder_ls ile_cmd_ls)
	(dir_cmd_ls = (mapcar (lambda (x y) (list x y)) skill_folder_ls ile_cmd_ls))
	
	;;;;; remove nil command and remove ?-0 item
	(dir_cmd_ls = (mapcan (lambda (x) (when (cadr x) (list x))) dir_cmd_ls))
	(dir_cmd_ls = (mapcan (lambda (x) (unless (index (car x) "-0") (list x))) dir_cmd_ls))
	
	;;;;; create menu list
	
	(q = axlUIMenuFind(nil "skill_package_tdc_flex"))
	; (z = axlUIMenuInsert(nil "hello1" "echo hello1"))
	
	(this_pop = in_pop = "")
	(pre_group = (car (parseString (caar dir_cmd_ls) "-")))
	(foreach dir_cmd dir_cmd_ls
		(shift_sep = nil)
		(dir = (car dir_cmd))
		(disp = (buildString (cdr (parseString dir "_")) " "))
		(cmd = (cadr dir_cmd))
		(this_group = (car (parseString dir "-")))
		(this_pop = (if (integerp (atoi (pop = (cadr (parseString dir "-"))))) "" pop))
		
		;;;;; 
		(unless (or (equal "" this_pop) (equal this_pop in_pop))
			printf("1POP: %s, %s\n" this_pop in_pop)
			(unless (equal "" in_pop) (z = axlUIMenuInsert(nil 'end)))
			(unless (equal pre_group this_group)
				(z = axlUIMenuInsert(nil 'separator))
				(shift_sep = t)
			)
			(z = axlUIMenuInsert(nil 'popup this_pop))
			(in_pop = this_pop)
		)
		(when (and (zerop (strlen this_pop)) (neq "" in_pop))
			printf("2POP: %s, %s\n" this_pop in_pop)
			(in_pop = "")
			(z = axlUIMenuInsert(nil 'end))
		)
		
		;;;;; 
		(if (equal pre_group this_group) then
			printf("disp: %s, cmd: %s\n" disp cmd)
			(z = axlUIMenuInsert(nil disp cmd))
		else
			printf("group: %s, %s\n" pre_group this_group)
			printf("disp: %s, cmd: %s\n" disp cmd)
			(if shift_sep (shift_sep = nil) (z = axlUIMenuInsert(nil 'separator)))
			(z = axlUIMenuInsert(nil disp cmd))
			(pre_group = this_group)
		)
	)
	
	(when (neq "" in_pop)
		printf("3POP: %s, %s\n" this_pop in_pop)
		(this_pop = in_pop = "")
		(z = axlUIMenuInsert(nil 'end))
	)
	
	(q = axlUIMenuFind(nil "skill_package_tdc_flex"))
	axlUIMenuDelete(q)
)

(defun skill_package_tdc_flex_main_Derek02012018 ()
	(prog ()
		init_Derek02012018()

		;;;;; check T disk has been built or not
		(unless (isDir skill_path_in_t)
			printf("No directory exists on path: %s\n" skill_path_in_t)
			return(nil)
		)

		;;;;; find file in path
		(unless (dtpr skill_folder_ls)
			printf("No file has been found in path: %s\n" skill_path_in_t)
			return(nil)
		)
		
		(skill_folder_ls = (sort skill_folder_ls 'alphalessp))
		(file_addr_ls = (mapcar (lambda (x) (strcat skill_path_in_t x)) skill_folder_ls))
		(dir_ile_ls = get_ile_ls_Derek02012018(file_addr_ls))
		(ile_cmd_ls = get_ile_cmd_ls_Derek02012018(file_addr_ls))
		
		;;;;; create new menu
		create_menu_Derek02012018(skill_folder_ls ile_cmd_ls)
		
		;;;;; load all file to the allegro
		load_all_ile_Derek02012018(file_addr_ls dir_ile_ls)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup 

; (skill_package_tdc_flex_main_Derek02012018)
(axlCmdRegister "skill_package_tdc_flex" 'skill_package_tdc_flex_main_Derek02012018)
; skill encrypt( "C:/skill/skill_package_tdc_flex_v1.il" "C:/skill/skill_package_tdc_flex_v1.ile")
; (load "skill_package_tdc_flex_v1.il")
; (load "skill_package_tdc_flex_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup