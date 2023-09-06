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
								'( "tpibewen" "B0-0C-D1-6E-CD-A6" "6C-02-E0-69-F2-6B") '( "tpidehsu" "")
								'( "tpiepeng" "C8-D9-D2-A7-8A-CB") '( "tpijchen" "B4-B6-86-E6-86-58")
								'( "tpiyalee" "10-62-E5-6C-3B-F6" "6C-02-E0-69-F3-1B") '( "tpirhsiu" "B0-0C-D1-6E-CF-04")
								'( "tpisting" "10-62-E5-6C-3C-68" "B4-B6-86-4B-4D-C5") '( "tpistdai" "B4-B6-86-93-5F-15")
								'( "tpitshen" "E4-E7-49-3A-41-32")))
	setq( _si_id_ls list( '( "tpialcha" "") '( "tpiandyu" "")
							'( "tpidavil" "") '( "tpijalee" "")
							'( "tpijayeh" "") '( "tpijeflu" "")
							'( "tpilyliu" "") '( "tpimwang" "")
							'( "tpirihua" "") '( "tpiwenhu" "")))
	setq( _manager_id_ls list( '( "tpichali" "C4-65-16-84-F5-1F") '( "tpiwelyu" "E4-E7-49-50-EF-83" "C0-18-03-B5-BB-24") '( "tpijench" "84-A9-3E-44-76-ED")))
	setq( _admin_ls list( '( "tpiwiche" "C4-65-16-83-88-28")))
	setq( _authorized_ls append( _admin_ls append( _manager_id_ls append( _layout_id_ls _si_id_ls))))
	
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
	prog( ( user_id user_data local_mac authorized)
		user_id = GetUserId_locker()
		unless( user_id
			return( nil)
		)
		
		authorized = CheckMacAddressExists_locker()
		/*
		local_mac = GetMacAddress_locker()
		authorized = setof( x _authorized_ls member( local_mac cdr( x)))
		*/
		unless( authorized
			sprintf( msg "You have to be a member of Flex TDC Layout member to use this tool [%L] -- by Wilson Chen" local_mac)
			axlUIConfirm( msg)
			return( nil)
		)
		
		printf( "Hello %s\n" car( authorized))
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
		port = GetIpConfig_locker()
		unless( port
			return( nil)
		)
		
		suffix = ""
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

procedure( CheckMacAddressExists_locker()
	prog( ( port user_data)
		port = GetIpConfig_locker()
		unless( port
			return( nil)
		)
		
		while( gets( line port)
			when( index( line "Physical Address")
				mac = car( last( parseString( line ": \n")))
				user_data = setof( x _authorized_ls member( mac cdr( x)))
				when( user_data
					axlDMClose( port)
					return( car( user_data))
				)
			)
		)
		 
		axlDMClose( port)
		return( nil)
	)
)

procedure( GetIpConfig_locker()
	prog( ( log_dir file_name log_path port)
		unless( axlGetVariable( "ads_sdlog")
			axlSetVariable( "ads_sdlog" "log")
		)
		
		log_dir = axlGetVariable( "ads_sdlog") || ""
		unless( or( zerop( strlen( log_dir)) isDir( log_dir))
			createDir( log_dir)
		)
		
		sscanf( getCurrentTime() "%s %d %d:%d:%d %d" month date hour minute second year)
		sprintf( file_name "ipconfig-%.4d%s%.2d.log" year month date)
		sprintf( log_path "%s/%s" log_dir file_name)

		unless( isFile( log_path)
			system( strcat( "ipconfig/all > " log_path))
		)
		
		port = infile( log_path)
		unless( inportp( port)
			deleteFile( log_path)
			printf( "Fail to get %s\n" log_path)
			return( nil)
		)
		
		return( port)
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
(encrypt "c:/skill/locker_v1d8.il" "c:/skill/locker_v1d8.ile")
(load "locker_v1d8.il")
(load "locker_v1d8.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup