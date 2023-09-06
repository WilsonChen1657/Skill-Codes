/*
################################################################################
#                                                                              #
#  Developer: Derek Hsu, Wilson Chen                                           #
#  Start Date: 2021/10/29                                                      #
#  Reference:                                                                  #
#  Purpose:                                                                    #
#       To check if user is authorized to use tools                            #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable
setq( _locker_initialized nil)
setq( _suffix_ls '( "tpi.flextronics.com" "shd.flextronics.com" "hitronhub.home"))
procedure( Init_locker()
	setq( _layout_id_ls list( '( "shdselli" "AC-E2-D3-3C-91-EC") '( "tpiarlin" "C8-F7-50-F8-28-74")
								'( "tpibewen" "B0-0C-D1-6E-CD-A6") '( "tpidehsu" "")
								'( "tpiepeng" "C8-D9-D2-A7-8A-CB") '( "tpijchen" "B4-B6-86-E6-86-58")
								'( "tpiyalee" "10-62-E5-6C-3B-F6") '( "tpirhsiu" "B0-0C-D1-6E-CF-04")
								'( "tpisting" "10-62-E5-6C-3C-68") '( "tpistdai" "B4-B6-86-93-5F-15")
								'( "tpitshen" "")))
	setq( _si_id_ls list( '( "tpialcha" "") '( "tpiandyu" "")
							'( "tpidavil" "") '( "tpijalee" "")
							'( "tpijayeh" "") '( "tpijeflu" "")
							'( "tpilyliu" "") '( "tpimwang" "")
							'( "tpirihua" "") '( "tpiwenhu" "")))
	setq( _manager_id_ls list( '( "tpichali" "C4-65-16-84-F5-1F") '( "tpiwelyu" "E4-E7-49-50-EF-83") '( "tpijench" "84-A9-3E-44-76-ED")))
	setq( _admin_ls list( '( "tpiwiche" "C4-65-16-83-88-28")))
	setq( _authorized_ls append( _admin_ls append( _manager_id_ls append( _layout_id_ls _si_id_ls))))
	setq( _authorized_table makeTable( "authorized" nil))
	foreach( item _authorized_ls
		_authorized_table[ car( item)] = cdr( item)
	)
	
	setq( _locker_path "W:/footprint_building_aid_skill/0-0_Locker/")
	setq( _pwd_path strcat( _locker_path "flex.txt"))
	setq( _input_pwd nil)
	setq( _pwd_index 4)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_locker( @optional ( check_ok_to_proceed t))
	prog( ( user_id result)
		when( check_ok_to_proceed
			unless( axlOKToProceed()
				println( "Please done the current function to keep continue")
				return( nil)
			)
		)
		
		unless( _locker_initialized
			Init_locker()
		)
		
		unless( CheckExpireDate_locker( _pwd_path)
			return( nil)
		)
		
		result = IsAuthorized_locker()
		unless( result
			result = CheckPwd_locker()
		)
		
		_locker_initialized = t
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( CheckExpireDate_locker( file_path)
	prog( ( expire_date)
		unless( isFile( file_path)
			axlUIConfirm( strcat( file_path " not found"))
			return( nil)
		)
		
		expire_date = GetExpireDate_locker( file_path)
		unless( expire_date || stringToTime( getCurrentTime()) < expire_date
			axlUIConfirm( "Locker has expired!/nPlease contact Wilson Chen for extension")
			return( nil)
		)
		
		return( t)
	)
)

procedure( GetUserId_locker()
	prog( ( user_id)
		user_id = axlDBGetDesign()->prop->LAST_SAVED_NAME
		unless( stringp( user_id)
			msg = "Fail to get your user ID. Please Save As to a new board file, otherwise, re-open your board file again"
			axlUIConfirm( msg)
			printf( "ERROR: GetUserId() - %s\n" msg)
			return( nil)
		)
		
		user_id = lowerCase( user_id)
		return( user_id)
	)
)

procedure( IsAuthorized_locker()
	prog( ( result)
		user_id = GetUserId_locker()
		unless( user_id
			return( nil)
		)
		
		local_mac = GetMacAddress_locker()
		
		mac_ls = _authorized_table[ user_id]
		unless( mac_ls
			axlUIConfirm( "You have to be a member of Flex TDC Layout member to use this tool -- by Wilson Chen")
			return( nil)
		)
		
		unless( member( local_mac mac_ls)
			msg = "You can save as to a new board file, or re-open your board file again"
			axlUIConfirm( sprintf( nil "[%s] your MAC address [%s] is not allowed to use this tool\n%s -- by Wilson Chen" user_id local_mac msg))
			return( nil)
		)
		
		return( t)
	)
)

procedure( GetExpireDate_locker( file_fullname)
	prog( ()
		; 6 months = 15780000 seconds
		return( fileTimeModified( file_fullname) + 15780000)
	)
)

procedure( GetMacAddress_locker()
	prog( ( file_name port suffix mac)
		suffix = ""
		file_name = "ipconfig.txt"
		unless( isFile( file_name)
			system( strcat( "ipconfig/all > " file_name))
		)
		
		port = axlDMOpenFile( "TEMP" file_name "r")
		unless( port
			deleteFile( file_name)
			printf( "Fail to get %s\n" file_name)
			return( nil)
		)
		
		while( gets( line port)
			when( index( line "Connection-specific DNS Suffix")
				suffix = car( last( parseString( line ": \n")))
			)
			
			when( member( suffix _suffix_ls) && index( line "Physical Address")
				mac = car( last( parseString( line ": \n")))
				axlDMClose( port)
				return( mac)
			)
		)
		 
		axlDMClose( port)
		return( nil)
    )
)

procedure( CheckPwd_locker()
	prog( ( result)
		result = nil
		unless( _input_pwd
			_input_pwd = axlUIPrompt( "You are currently not authorized to use skill package!!\nPlease contact Wilson Chen for temporary password")
		)
			
		if( isFile( _pwd_path) then
			in_port = infile( _pwd_path)
			unless( inportp( in_port)
				printf( "ERROR: CheckPwd() - Fail to get password") 
				return( nil)
			)
			
			for( i 1 _pwd_index
				gets( line in_port)
			)
			
			line = car( parseString( line "\n"))
			result = line == _input_pwd
			unless( result
				axlUIConfirm( "Password incorrect!")
				_input_pwd = nil
			)
			
			close( in_port)
		)
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "locker" 'Main_locker)
/*
(encrypt "c:/skill/locker_v1d4.il" "c:/skill/locker_v1d4.ile")
(load "locker_v1d4.il")
(load "locker_v1d4.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup