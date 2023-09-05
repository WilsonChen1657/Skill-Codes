/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/06/14                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To resize out frame according to brd content                           #
#                                                                              #
################################################################################
*/

;region Global variable

procedure( Init_resizeframe()
	let( ( width_height)
		;setq( _line_width GetUnitValueByMils_utilityprogram( 20))
		;setq( _hor_width GetUnitValueByMils_utilityprogram( 4120))
		;setq( _hor_height GetUnitValueByMils_utilityprogram( 340))
		;setq( _ver_height GetUnitValueByMils_utilityprogram( 6053))
		;setq( _ver_width _hor_height)
		setq( _layer_bg_frame "BOARD GEOMETRY/FRAME")
		setq( _layer_bg_frame_pcba "BOARD GEOMETRY/FRAME_PCBA")
		setq( _layer_bg_logo "BOARD GEOMETRY/LOGO")
		setq( _layer_bg_logo_m "BOARD GEOMETRY/LOGO_MIRROR")
		setq( _layer_bg_bf "BOARD GEOMETRY/BOARD_FORM")
		setq( _layer_bg_bf_m "BOARD GEOMETRY/BOARD_FORM_MIRROR")
		setq( _layer_bg_bfk "BOARD GEOMETRY/BOARD_FORM_KEY")
		setq( _layer_bg_bfk_m "BOARD GEOMETRY/BOARD_FORM_KEY_MIRROR")

		setq( _layer_bg_bf_pcba "BOARD GEOMETRY/BOARD_FORM_PCBA")
		setq( _layer_bg_bf_m_pcba "BOARD GEOMETRY/BOARD_FORM_MIRROR_PCBA")
		setq( _layer_bg_bfk_pcba "BOARD GEOMETRY/BOARD_FORM_KEY_PCBA")
		setq( _layer_bg_bfk_m_pcba "BOARD GEOMETRY/BOARD_FORM_KEY_MIRROR_PCBA")

		setq( _layer_bg_an "BOARD GEOMETRY/ASSEMBLY_NOTES")
		setq( _layer_bg_do "BOARD GEOMETRY/DESIGN_OUTLINE")
		setq( _layer_df_pcb_fab "DRAWING FORMAT/PCB_FAB")
		setq( _layer_df_panel "DRAWING FORMAT/PANEL")
		setq( _layer_df_pcba_top "DRAWING FORMAT/PCBA_TOP")
		setq( _layer_df_pcba_bot "DRAWING FORMAT/PCBA_BOT")

		setq( _frame_width 340) ; mils
		setq( _A_size_ls list( "A0" "A1" "A2" "A3"))
		setq( _A_size_table makeTable( 'A_type nil))
		width_height = list( 841 1189) ; mm
		foreach( size _A_size_ls
			_A_size_table[ size] = width_height
			width_height = list( round( cadr( width_height) / 2) car( width_height))
		)

		setq( _B_size_ls list( "B0" "B1" "B2" "B3"))
		setq( _B_size_table makeTable( 'B_type nil))
		width_height = list( 1000 1414) ; mm
		foreach( size _B_size_ls
			_B_size_table[ size] = width_height
			width_height = list( round( cadr( width_height) / 2) car( width_height))
		)
	)
)

;endregion

;region Main

procedure( Main_resizeframe()
    prog( ()
        unless( Main_locker()
            return( nil)
        )

		Init_resizeframe()

		; check if is old project
		sym_nm = "flex_pcb_control_form_v4"
		sym_ls = setof( x axlDBGetDesign()->symbols equal( upperCase( x->name) upperCase( sym_nm)))
		when( dtpr( sym_ls)
			sprintf( msg "Found [%s] on board\nAutomatic proceed [Artwork] & [Logo]" sym_nm)
			PrintMsg_utilityprogram( msg ?title "Main_resizeframe()" ?level 'warn)

			DeleteBoardFormContent_resizeframe( 'PCB_FAB_PANEL)
			axlDeleteObject( sym_ls)

			Main_setupboardinit( ?init_options '(no))
			Main_setupartwork()
			Main_setuplogo()
		)

		LoadFrame_resizeframe()
        return( t)
    )
)

;endregion

;region Main

procedure( LoadFrame_resizeframe()
	let( ()
		CreateFrame_resizeframe( 'PCB_FAB_PANEL)
		CreateFrame_resizeframe( 'PCBA)

		when( isCallable( 'Main_setuppcbformdata)
			Main_setuppcbformdata()
		)
	)
)

procedure( RelocateContent_resizeframe()
	let( ()
		RelocateBoardFormContent_resizeframe( 'PCB_FAB_PANEL)
		RelocateBoardFormContent_resizeframe( 'PCBA_TOP)
		RelocateBoardFormContent_resizeframe( 'PCBA_BOT)
		RelocateLogo_resizeframe()
	)
)

procedure( CreateFrame_resizeframe( type)
	let( ( layer_ls key_xy_ls obj_ls obj_ls_box hor ver hor_ver size sym_term sym_nm)
		case( type
			( 'PCB_FAB_PANEL
				layer_ls = list( _layer_bg_an _layer_df_pcb_fab _layer_df_panel _layer_bg_logo)
				baord_form_key_layer = _layer_bg_bfk
			)
			( 'PCBA
				layer_ls = list( _layer_df_pcba_top _layer_bg_logo _layer_df_pcba_bot _layer_bg_logo_m)
				baord_form_key_layer = list( _layer_bg_bfk_pcba _layer_bg_bfk_m_pcba)
			)
		)

		msg_title = "CreateFrame()"
		sprintf( msg "Creating frame of type[%s]" symbolToString( type))
		PrintMsg_utilityprogram( msg ?title msg_title)
		DeleteBoardFormContent_resizeframe( type)

		layer_ls = append( layer_ls list( _layer_bg_do))
		obj_ls = GetFindFilter_utilityprogram( layer_ls '(shapes lines text))
		obj_ls_box = axlDBGetExtents( obj_ls nil)
		
		hor = caadr( obj_ls_box) - caar( obj_ls_box)
		ver = cadadr( obj_ls_box) - cadar( obj_ls_box)
		; add board_form height (3080)
		board_form_height = 3100
		if( equal( _allegro_unit "mils")
			hor_ver = list( axlMKSConvert( hor "MILS" "MM") axlMKSConvert( (ver + board_form_height) "MILS" "MM"))
			hor_ver = list( hor (ver + GetUnitValueByMils_utilityprogram( board_form_height)))
		)

		;hor_ver = sort( hor_ver 'lessp)

		size = GetSizeByType_resizeframe( type hor_ver)
		cond(
			( eq( type 'PCB_FAB_PANEL)
				sym_term = "panel_frame_"
				center_xy = (10000:0)
			)
			( eq( type 'PCBA)
				sym_term = "pcba_frame_"
				obj_ls = GetAll_utilityprogram( _layer_bg_do)
				center_xy = axlMidPointLine( axlDBGetExtents( obj_ls nil))
			)
		)

		sym_nm = strcat( sym_term lowerCase( size))
		CreateSymbol_utilityprogram( sym_nm ?center_xy center_xy)

		sprintf( msg "Load frame [%L] complete" type)
		PrintMsg_utilityprogram( msg)
	)
)

procedure( GetSizeByType_resizeframe( type obj_size)
	let( ( size_ls size_table result_size check_size_ls)
		case( type
			( 'PCBA
				size_ls = reverse( _A_size_ls)
				size_table = _A_size_table
			)
			( 'PCB_FAB_PANEL
				size_ls = reverse( _B_size_ls)
				size_table = _B_size_table
			)
		)

		frame_width = axlMKSConvert( _frame_width "MILS" "MM") * 2
		result_size = nil
		check_size_ls = size_ls
		while( and( null( result_size) dtpr( check_size_ls))
			size = car( check_size_ls)
			width_height = sort( size_table[ size] 'greaterp)
			when( and( greaterp( (car( width_height) - frame_width) car( obj_size)) greaterp( (cadr( width_height) - frame_width) cadr( obj_size)))
				result_size = size
			)

			check_size_ls = remq( size check_size_ls)
		)

		unless( result_size
			; get biggest size
			result_size = car( reverse( size_ls))
			sprintf( msg "Contents in [%s] are too big, please reformat" symbolToString( type))
			PrintMsg_utilityprogram( msg ?title "GetSizeByType()" ?level 'warn)
		)

		result_size
	)
)

procedure( DeleteBoardFormContent_resizeframe( type)
	let( ( group_name content_layer baord_form_key_layer key_ls key_text_id target_xy
		text_ls text_id delete_text_ls)
		msg_title = "DeleteBoardFormContent()"
		cond(
			( eq( type 'PCB_FAB_PANEL)
				group_name = "PCB_FORM_CONTENT"
				content_layer = list( _layer_df_pcb_fab _layer_df_panel)
				baord_form_key_layer = _layer_bg_bfk
			)
			( eq( type 'PCBA)
				group_name = "PCB_FORM_CONTENT_PCBA"
				content_layer = list( _layer_df_pcba_top _layer_df_pcba_bot)
				baord_form_key_layer = list( _layer_bg_bfk_pcba _layer_bg_bfk_m_pcba)
			)
		)

		sprintf( msg "Deleting content on %L" content_layer)
		PrintMsg_utilityprogram( msg ?title msg_title)

		key_ls = GetTextList_utilityprogram( baord_form_key_layer)
		key_text_id = car( setof( x key_ls equal( x->text "[v1]")))
		target_xy = key_text_id->xy
		text_ls = GetTextList_utilityprogram( content_layer)
		text_id = car( setof( x text_ls axlGeoPointsEqual( x->xy target_xy)))

		delete_text_ls = car( setof( x text_id->parentGroups equal( x->name group_name)))->groupMembers
		when( dtpr( delete_text_ls)
			axlDeleteObject( delete_text_ls)
		)
	)
)

procedure( RelocateBoardFormContent_resizeframe( type)
	let( ( group_name content_layer baord_form_key_layer prompt key_ls v1_text_id text_id
			text_ls delta_x delta_y)
		cond(
			( eq( type 'PCB_FAB_PANEL)
				group_name = "PCB_FORM_CONTENT"
				content_layer = list( _layer_df_pcb_fab _layer_df_panel)
				baord_form_key_layer = _layer_bg_bfk
			)
			( eq( type 'PCBA_TOP)
				group_name = "PCB_FORM_CONTENT_PCBA"
				content_layer = _layer_df_pcba_top
				baord_form_key_layer = _layer_bg_bfk_pcba
			)
			( eq( type 'PCBA_BOT)
				group_name = "PCB_FORM_CONTENT_PCBA"
				content_layer = _layer_df_pcba_bot
				baord_form_key_layer = _layer_bg_bfk_m_pcba
			)
		)

		prompt = "Select AGILE. REV's \"01\" in Board form to relocate"
		MoveGroupText_resizeframe( content_layer baord_form_key_layer "[v1]" group_name prompt)
	)
)

procedure( RelocateLogo_resizeframe()
	let( ( key group_name prompt)
		key = "[layer]"
		group_name = "LOGO_LAYER_TEXT"
		prompt = "Select layer text in logo to relocate"
		MoveGroupText_resizeframe( _layer_df_pcb_fab _layer_bg_bfk key group_name prompt)
		; mirror
		group_name = "LOGO_LAYER_TEXT_MIRROR"
		MoveGroupText_resizeframe( _layer_df_pcba_bot _layer_bg_bfk_m key group_name prompt)
	)
)

procedure( MoveGroupText_resizeframe( layer key_layer key group_name @optional (prompt nil))
	prog( ( visible_list key_ls key_text_id target_xy text_ls text_id move_text_ls delta_x delta_y)
		msg_title = "MoveGroupText()"
		unless( or( and( stringp( layer) axlIsLayer( layer)) and( dtpr( layer) forall( x layer axlIsLayer( x))))
			PrintMsg_utilityprogram( "[layer] not found" ?title msg_title ?level 'error)
			return( nil)
		)

		unless( or( and( stringp( key_layer) axlIsLayer( key_layer)) and( dtpr( key_layer) forall( x key_layer axlIsLayer( x))))
			PrintMsg_utilityprogram( "[key_layer] not found" ?title msg_title ?level 'error)
			return( nil)
		)

		unless( stringp( key)
			PrintMsg_utilityprogram( "[key] should be a string" ?title msg_title ?level 'error)
			return( nil)
		)

		visible_list = axlVisibleGet()
		key_ls = GetTextList_utilityprogram( key_layer)
		key_text_id = car( setof( x key_ls equal( x->text key)))
		target_xy = key_text_id->xy
		text_ls = GetTextList_utilityprogram( layer)
		text_id = car( setof( x text_ls axlGeoPointsEqual( x->xy target_xy)))
		unless( text_id
			ZoomIn_utilityprogram( target_xy 2000)
			when( prompt
				axlUIConfirm( prompt)
			)
			
			axlVisibleDesign( nil)
			if( dtpr( layer) then
				foreach( ly layer
					axlVisibleLayer( ly t)
				)
			else
				axlVisibleLayer( layer t)
			)

			text_id = car( SelectObjectByUser_utilityprogram( '(text) ?prompt prompt))
		)
		
		move_text_ls = car( setof( x text_id->parentGroups equal( x->name group_name)))->groupMembers
		if( dtpr( layer)
			move_text_ls = setof( x move_text_ls member( x->layer layer))
			move_text_ls = setof( x move_text_ls equal( x->layer layer))
		)
		
		unless( dtpr( move_text_ls)
			sprintf( msg "No group text found on %L, please check again!" text_id->layer)
			PrintMsg_utilityprogram( msg ?title msg_title ?level 'warn)
			axlVisibleSet( visible_list)
			return( nil)
		)

		delta_x = xCoord( target_xy) - xCoord( text_id->xy)
		delta_y = yCoord( target_xy) - yCoord( text_id->xy)

		MoveObjects_utilityprogram( move_text_ls list( delta_x delta_y))
		axlVisibleSet( visible_list)
		return( t)
	)
)

;endregion

;region Setup
axlCmdRegister( "resize_frame" 'Main_resizeframe)
/*
(encrypt "c:/skill/resize_frame_v1d1.il" "c:/skill/resize_frame_v1d1.ile")
(load "resize_frame_v1d1.il")
(load "resize_frame_v1d1.ile")
*/
;endregion