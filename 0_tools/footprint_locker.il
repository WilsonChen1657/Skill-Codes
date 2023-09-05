/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/07/05                                                      #
#  Reference: locker                                                           #
#  Purpose:                                                                    #
#       To check if user is authorized to use footprint tools                  #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable
setq( _footprint_locker_initialized nil)
procedure( Init_footprintlocker()
	setq( _footprint_user_ls list( '( "shdselli" "AC-E2-D3-3C-91-EC") '( "tpirhsiu" "B0-0C-D1-6E-CF-04")
									 '( "tpistdai" "B4-B6-86-93-5F-15") '( "tpiwelyu" "E4-E7-49-50-EF-83")))
	setq( _admin_ls list( '( "tpiwiche" "C4-65-16-83-88-28")))
	setq( _authorized_ls append( _admin_ls _footprint_user_ls))
	
	setq( _locker_path "W:/footprint_building_aid_skill/0-0_Locker/")
	setq( _pwd_path strcat( _locker_path "flex.txt"))
	setq( _input_pwd nil)
	setq( _pwd_index 4)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_footprintlocker( @optional ( check_ok_to_proceed t))
	prog( ( user_id result)
		when( check_ok_to_proceed
			unless( axlOKToProceed()
				println( "Please done the current function to keep continue")
				return( nil)
			)
		)
		
		unless( _footprint_locker_initialized
			Init_footprintlocker()
			_footprint_locker_initialized = t
		)
		
		unless( CheckExpireDate_locker( _pwd_path)
			return( nil)
		)
		
		result = IsAuthorized_locker()
		unless( result
			result = CheckPwd_locker()
		)
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "footprint_locker" 'Main_footprintlocker)
/*
(encrypt "c:/skill/footprint_locker_v1d1.il" "c:/skill/footprint_locker_v1d1.ile")
(load "footprint_locker_v1d1.il")
(load "footprint_locker_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup