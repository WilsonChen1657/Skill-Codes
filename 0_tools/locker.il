;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction

; Start Date: _Derek20210929

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init_Derek20210929()
	setq( _layout_id_ls list( "tpiarlin" "tpibewen" "tpidehsu" "tpiepeng" "tpijchen" "tpiyalee" "tpirhsiu" "tpisting" "tpistdai" "tpitshen" "tpiwelyu" "tpichali"))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_user_id_Derek20210929()
	prog( ( user_id)
		user_id = axlDBGetDesign()->prop->LAST_SAVED_NAME
		
		return( user_id)
	)
)

procedure( is_layout_member_Derek20210929( user_id)
	prog( ( result)
		result = dtpr( member( user_id _layout_id_ls))
		
		return( result)
	)
)

procedure( locker_main_Derek20210929()
	prog( ( user_id result)
		init_Derek20210929()
		
		user_id = get_user_id_Derek20210929()
		result = is_layout_member_Derek20210929( user_id)
		
		unless( result
			axlUIConfirm( "You have to be a member of Flex TDC Layout member to use this tool -- by Derek Hsu")
		)
		
		return( result)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "locker" 'locker_main_Derek20210929)
; (locker_main_Derek20210929)
; skill (encrypt "c:/skill/locker_v1.il" "c:/skill/locker_v1.ile")
; (load "locker_v1.il")
; (load "locker_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup