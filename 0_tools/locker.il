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

procedure( init_Derek20210929()
	setq( _layout_id_ls list( "shdselli" "tpiarlin" "tpibewen" "tpidehsu" "tpiepeng" "tpijchen" "tpiyalee" "tpirhsiu" "tpisting" "tpistdai" "tpitshen" "tpichali"))
	setq( _si_id_ls list( "tpialcha" "tpiandyu" "tpidavil" "tpijalee" "tpijayeh" "tpijeflu" "tpilyliu" "tpimwang" "tpirihua" "tpiwenhu"))
	setq( _manager_id_ls list( "tpichali" "tpiwelyu" "tpijench"))
	setq( _admin_ls list( "tpiwiche"))
	setq( _authorized_id_ls append( _admin_ls append( _manager_id_ls append( _layout_id_ls _si_id_ls))))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( locker_main_Derek20210929()
	prog( ( user_id result)
		init_Derek20210929()
		
		user_id = get_user_id_Derek20210929()
		result = is_layout_member_Derek20210929( user_id)
		
		unless( result
			axlUIConfirm( "You have to be a member of Flex TDC Layout member to use this tool -- by Wilson Chen")
		)
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( get_user_id_Derek20210929()
	prog( ( user_id)
		user_id = axlDBGetDesign()->prop->LAST_SAVED_NAME || ""
		when( user_id == ""
			println( "ERROR: get_user_id() - Fail to get your user ID. Please Save As to a new board file, otherwise, re-open your board file again")
			return( nil)
		)
		
		user_id = lowerCase( user_id)
		return( user_id)
	)
)

procedure( is_layout_member_Derek20210929( user_id)
	prog( ( result)
		unless( user_id return( nil))
		result = dtpr( member( user_id _authorized_id_ls))
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

(axlCmdRegister "locker" 'locker_main_Derek20210929)
; (locker_main_Derek20210929)
; skill (encrypt "c:/skill/locker_v1d3.il" "c:/skill/locker_v1d3.ile")
; (load "locker_v1d3.il")
; (load "locker_v1d3.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup