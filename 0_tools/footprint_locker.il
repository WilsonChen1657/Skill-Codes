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
									'( "tpistdai" "7C-57-58-3F-CD-A7" "D4-D8-53-01-2E-AD") '( "tpiwelyu" "E4-E7-49-50-EF-83" "C0-18-03-B5-BB-24")
									'( "tpisting" "10-62-E5-6C-3C-68" "B4-B6-86-4B-4D-C5" "C8-F7-50-F8-38-99" "E0-73-E7-A8-D3-EB")
									'( "tpiyalee" "10-62-E5-6C-3B-F6" "6C-02-E0-69-F3-1B" "AC-19-8E-32-26-B1")
									'( "tpiarlin" "C8-F7-50-F8-28-74" "70-D8-23-FE-8E-90")))
	setq( _admin_ls list( '( "tpiwiche" "C4-65-16-83-88-28")))
	setq( _authorized_ls append( _admin_ls _footprint_user_ls))
	
	setq( _locker_path strcat( _pcb_footprint_path "../Tools/Locker/"))
	setq( _pwd_path strcat( _locker_path "flex.txt"))
	setq( _input_pwd nil)
	setq( _pwd_index 4)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_footprintlocker( @optional ( check_ok_to_proceed t))
	prog( ( result)
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
(encrypt "c:/skill/footprint_locker_v1d8.il" "c:/skill/footprint_locker_v1d8.ile")
(load "footprint_locker_v1d8.il")
(load "footprint_locker_v1d8.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup