;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 06/11/2019 - _Derek06112019
;purpose: create logo textbox
;prerequest
;	1. key [layer] in layer [board geometry/board_form_key]
;text on layer
;	DRAWING FORMAT/TOP -> COMPONENT SIDE
;	DRAWING FORMAT/INT1 -> INNER1(LAYER:03)
;	DRAWING FORMAT/VCC1 -> VCC1 PLANE(LAYER:05)
;	DRAWING FORMAT/GND1 -> GND1 PLANE(LAYER:02)
;	DRAWING FORMAT/BOTTOM -> SOLDER SIDE
;	DRAWIGN FORMAT/SILKSCREEN_TOP -> SILKSCREEN TOP
;	DRAWING FORMAT/PASTEMASK_TOP -> COMPONENT PASTE
;	DRAWING FORMAT/SOLDERMASK_TOP -> COMPONENT MASK
;	DRAWIGN FORMAT/SILKSCREEN_BOTTOM -> SILKSCREEN BOTTOM
;	DRAWING FORMAT/PASTEMASK_BOTTOM -> SOLDER PASTE
;	DRAWING FORMAT/SOLDERMASK_BOTTOM -> SOLDER MASK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek06112019( )
	prog( ()
		;;;;; global variable
		setq( _key_layer "[layer]")
		setq( _bfy_lyname "BOARD GEOMETRY/BOARD_FORM_KEY")
		setq( _bfy_mirr_lyname "BOARD GEOMETRY/BOARD_FORM_KEY_MIRROR")
	
		;;; system variable
		setq( _allegro_version axlVersion( 'version))
		setq( _allegro_type axlDesignType( nil))
		
		;;;;; local variable
		
		setq( _text_group_name "LOGO_LAYER_TEXT")
		
		setq( _etch_ly_ls axlGetParam( "paramLayerGroup:ETCH")->groupMembers)
		
		setq( _cls_df "DRAWING FORMAT")
		setq( _cls_etch "ETCH")
		setq( _text_conductor_form "%s (LAYER:%.2d)")
		setq( _text_plane_form "%s PLANE (LAYER:%.2d)")
		setq( _text_top "COMPONENT SIDE")
		setq( _text_bot "SOLDER SIDE")
		setq( _text_silk_top "SILKSCREEN TOP")
		setq( _text_silk_bot "SILKSCREEN BOTTOM")
		setq( _text_past_top "COMPONENT PASTE")
		setq( _text_past_bot "SOLDER PASTE")
		setq( _text_mask_top "COMPONENT MASK")
		setq( _text_mask_bot "SOLDER MASK")
		setq( _text_panel "PANEL")
		setq( _text_pcb_fab "PCB FAB")
		setq( _text_pcba_top "PCBA TOP")
		setq( _text_pcba_bot "PCBA BOTTOM")
		setq( _text_drill_map "DRILL MAP")
		
		setq( _top "TOP")
		setq( _bottom "BOTTOM")
		setq( _st_ly "DRAWING FORMAT/SILKSCREEN_TOP")
		setq( _sb_ly "DRAWING FORMAT/SILKSCREEN_BOTTOM")
		setq( _pt_ly "DRAWING FORMAT/PASTEMASK_TOP")
		setq( _pb_ly "DRAWING FORMAT/PASTEMASK_BOTTOM")
		setq( _mt_ly "DRAWING FORMAT/SOLDERMASK_TOP")
		setq( _mb_ly "DRAWING FORMAT/SOLDERMASK_BOTTOM")
		setq( _pn_ly "DRAWING FORMAT/PANEL")
		setq( _pf_ly "DRAWING FORMAT/PCB_FAB")
		setq( _pbt_ly "DRAWING FORMAT/PCBA_TOP")
		setq( _pbb_ly "DRAWING FORMAT/PCBA_BOT")
		setq( _ndl_ly "DRAWING FORMAT/NCDRILL_LEGEND")
		
		setq( _outer_ly_ls list( "TOP" "BOTTOM"))
		
		setq( _xsect_gnd_rex "^L[0-9]+_GND[0-9]+$")
		setq( _xsect_int_rex "^L[0-9]+_INT[0-9]+$")
		setq( _xsect_vcc_rex "^L[0-9]+_VCC[0-9]+$")
		setq( _xsect_int_vcc_rex "^L[0-9]+_INT-VCC[0-9]+$")
		setq( _xsect_int_gnd_rex "^L[0-9]+_INT-GND[0-9]+$")
		setq( _xsect_vcc_gnd_rex "^L[0-9]+_VCC-GND[0-9]+$")
		setq( _xsect_gen_rex "^L\\([0-9]+\\)_\\([-A-Z]+[0-9]+\\)$")
		setq( _xsect_prename_rex "[|A-Z]+")
		
		setq( _xsect_int_vcc_form "%s_INT-VCC%d")
		setq( _xsect_int_gnd_form "%s_INT-GND%d")
		setq( _xsect_vcc_gnd_form "%s_VCC-GND%d")
		
		t
	)
)

procedure( init_check_Derek06112019( )
	prog( ()
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		when( (_allegro_version < 16.6) println( "Allegro verions has to be greater than 16.6") return( nil))
		unless( equal( "LAYOUT" _allegro_type) println( "Allegro has to be layout editor") return ( nil))
		
		unless( check_etch_Derek06112019( ) return( nil))
		
		unless( axlIsLayer( _bfy_lyname) printf( "Please create layer [%s] and add text '[layer]' to use this function\n" _bfy_lyname) return( nil))
		
		unless( axlIsLayer( _st_ly) axlLayerCreateNonConductor( _st_ly))
		unless( axlIsLayer( _sb_ly) axlLayerCreateNonConductor( _sb_ly))
		unless( axlIsLayer( _pt_ly) axlLayerCreateNonConductor( _pt_ly))
		unless( axlIsLayer( _pb_ly) axlLayerCreateNonConductor( _pb_ly))
		unless( axlIsLayer( _mt_ly) axlLayerCreateNonConductor( _mt_ly))
		unless( axlIsLayer( _mb_ly) axlLayerCreateNonConductor( _mb_ly))
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( check_etch_Derek06112019( )
	prog( ( etch_ly_ls result)
		
		etch_ly_ls = _etch_ly_ls
		
		result = member( "TOP" etch_ly_ls)
		unless( result println( "ArgErr: check_etch() - Fail to find 'TOP' in etch") return( nil))
		
		result = member( "BOTTOM" etch_ly_ls)
		unless( result println( "ArgErr: check_etch() - Fail to find 'BOTTOM' in etch") return( nil))
		
		etch_ly_ls = setof( e etch_ly_ls not( member( e _outer_ly_ls)))
		foreach( etch_ly etch_ly_ls
			cond(
				( rexMatchp( _xsect_gnd_rex etch_ly) )
				( rexMatchp( _xsect_int_rex etch_ly) )
				( rexMatchp( _xsect_vcc_rex etch_ly) )
				( rexMatchp( _xsect_int_vcc_rex etch_ly) )
				( rexMatchp( _xsect_int_gnd_rex etch_ly) )
				( rexMatchp( _xsect_vcc_gnd_rex etch_ly) )
				(t
					printf( "ERROR: check_etch() - Illegal Name of etch layer [%s]\n" etch_ly)
					result = nil
				)
			)
		)
		
		return( result)
	)
)

procedure( set_visible( visi_layers)
	prog( ()
		unless( and( stringp( visi_layers) axlIsLayer( visi_layers)) println( "ArgErr: set_visible() - visi_layers is not a string layer") return( nil))
		visi_layers = list( visi_layers)
		unless( forall( x visi_layers and( stringp( x) axlIsLayer( x))) println( "ArgErr: set_visible() - visi_layers is not a dtpr layer") return( nil))
		;;
		
		axlVisibleDesign( nil)
		foreach( layer visi_layers axlVisibleLayer( layer t))
		
		return( t)
	)
)

procedure( get_text( text_name text_layer)
	prog( ( opts text_ls )
		unless( stringp( text_name) println( "") return( nil))
		unless( and( stringp( text_layer) axlIsLayer( text_layer)) println( "") return( nil))
		;;; open layer
		set_visible( text_layer)
		
		;;; set find filter
		opts = list( "noall" "text")
		axlSetFindFilter( ?enabled opts ?onButtons opts)
		
		axlAddSelectAll()
		
		text_ls = axlGetSelSet()
		unless( dtpr( text_ls) printf( "Warning: get_text() - None of text[%s] has been found on layer[%s]\n" text_name text_layer) return( nil))
		
		axlClearSelSet()
		
		text_ls = setof( x text_ls equal( text_name x->text))
		
		return( text_ls)
	)
)

procedure( get_key_from_layer_Derek06112019( key_name layer_name)
	;; text_ls = setof( x text_ls index( x->layer "KEY"))
	;; text_ls = setof( x text_ls index( x->text "LAYER"))
	prog( ( text_ls text_id xy textblock result)
		unless( stringp( key_name) println( "ArgErr: get_key_from_layer() - key_name is not a string") return( nil))
		unless( stringp( layer_name) println( "ArgErr: get_key_from_layer() - layer_name is not a string") return( nil))
		unless( axlIsLayer( layer_name) println( "ArgErr: get_key_from_layer() = layer_name is not a layer name") return( nil))
		;;
		
		;;;; change visible layer
		set_visible( layer_name)
		
		;;;; get_text
		text_ls = get_text( key_name layer_name)
		
		unless( onep( length( text_ls))
			printf( "ERROR: get_key_from_layer() - More than 1 or none key[%s](%L) has been found on layer[%s]\n" key_name text_ls~>xy layer_name)
			return( nil)
		)
		
		text_id = car( text_ls)
		xy = text_id->xy
		textblock = text_id->textBlock
		result = list( xy textblock)
		
		return( result)
	)
)

procedure( get_text_group_Derek06112019( )
	let( ( group_ls group_id)
		group_ls = axlDBGetDesign()->groups
		group_ls = setof( x group_ls equal( _text_group_name x->name))
		
		group_id = car( group_ls)
		
		group_id
	)
)

procedure( remove_group_Derek06112019( )
	;; axlDBGetDesign()->groups~>name
	let( ( group_ls group_id text_ls )
		group_id = get_text_group_Derek06112019( )
		
		when( group_id
			text_ls = group_id->groupMembers
			
			when( dtpr( text_ls)
				axlDBRemoveGroupObjects( group_id text_ls)
				;axlDBDisbandGroup( group_id) ;; you can not actually delete a group. moreover, it may cause db error
				foreach( text_id text_ls
					printf( "Removing logo[%s] from layer[%s]\n" text_id->text text_id->layer)
					axlDeleteObject( text_id)
				)
			)
		)
		
		t
	)
)

procedure( create_text_Derek06112019( text xy textblock is_mirrored layer)
	prog( ( text_orient )
		unless( stringp( text) println( "ArgErr: create_text() - text is not a string") return( nil))
		unless( dtpr( xy) println( "ArgErr: create_text() - xy is not a dtpr") return( nil))
		unless( stringp( textblock) println( "ArgErr: create_text() - textblock is not a string") return( nil))
		unless( booleanp( is_mirrored) println( "ArgErr: create_text() - is_mirrored is not in boolean type") return( nil))
		unless( stringp( layer) println( "ArgErr: create_text() - layer is not a string") return( nil))
		unless( plusp( atoi( textblock)) println( "ArgErr: create_text() - textblock is not a string number") return( nil))
		unless( axlIsLayer( layer) println( "ArgErr: create_text() - layer is not exists") return( nil))
		;;
		
		text_orient = make_axlTextOrientation( ?textBlock textblock ?rotation 0.0 ?mirrored is_mirrored ?justify "center")
		text_id = axlDBCreateText( text xy text_orient layer)
		
		;;; it might be more than 1 text generated
		if( cadr( text_id) then
			;;; if second value is t, then there is a DRC created
			printf( "%s Fail to create text[%s] to layer[%s]\n" err text to_layer)
			text_id = nil
		else
			text_id = car( text_id)
			unless( onep( length( text_id))
				printf( "%s More then a text has been created %L\n" text_id~>text)
			)
		)
		
		return( text_id)
	)
)

procedure( get_etch_layer_text_Derek06112019( etch_ly)
	prog( ( layer_num type layer layer_type result)
		unless( stringp( etch_ly) println( "ArgErr: get_etch_layer_text() - etch_ly is not a string") return( nil))
		rexCompile( _xsect_gen_rex)
		
		if( rexExecute( etch_ly) then
			layer_num = rexSubstitute( "\\1")
			layer_num = atoi( layer_num)
			type = rexSubstitute( "\\2")
			
			layer = strcat( _cls_etch "/" etch_ly)
			layer_type = axlDBGetLayerType( layer)
			
			case( layer_type
				( "CONDUCTOR"
					rexCompile( _xsect_prename_rex)
					type = rexReplace( type "INNER" 1)
					sprintf( result _text_conductor_form type layer_num)
				)
				( "PLANE"
					sprintf( result _text_plane_form type layer_num)
				)
				( t
					printf( "ERROR: get_etch_layer_text() - Not support type[%s] for etch_ly[%s]\n" layer_type etch_ly)
				)
			)
		else
			printf( "ERROR: get_etch_layer_text() - Fail to do etch_ly[%s]\n" etch_ly)
		)
		
		return( result)
	)
)

procedure( create_text_on_layers_Derek06112019( xy_textblock xy_textblock_mirr)
	;; group_ls = setof( x axlDBGetDesign()->groups equal( _text_group_name x->name))
	prog( ( this_xy this_textblock xy textblock xy_mirr textblock_mirr is_mirrored text subclass text_id group_id)
		unless( dtpr( xy_textblock) println( "ArgErr: create_text_on_layers() - xy_textblock is not dtpr") return( nil))
		unless( dtpr( xy_textblock_mirr) println( "ArgErr: create_text_on_layers() - xy_textblock_mirr is not dtpr") return( nil))
		xy = car( xy_textblock)
		textblock = cadr( xy_textblock)
		
		xy_mirr = car( xy_textblock_mirr)
		textblock_mirr = cadr( xy_textblock_mirr)
		;;
		
		;;; create a new group
		group_id = get_text_group_Derek06112019( )
		unless( group_id (group_id = axlDBCreateGroup( _text_group_name "generic" nil)))
		unless( group_id println( "ERROR: create_text_on_layers() - Fail to create group") return( nil))
		
		;;; silkscreen top
		is_mirrored = nil
		text_id = create_text_Derek06112019( _text_silk_top xy textblock is_mirrored _st_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; pastmask top
		is_mirrored = nil
		text_id = create_text_Derek06112019( _text_past_top xy textblock is_mirrored _pt_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; soldermask top
		is_mirrored = nil
		text_id = create_text_Derek06112019( _text_mask_top xy textblock is_mirrored _mt_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; etch
		foreach( etch_ly _etch_ly_ls
			cond( 
				( equal( _top etch_ly)
					subclass = _top
					text = _text_top
					is_mirrored = nil
					
					this_xy = xy
					this_textblock = textblock
				)
				( equal( _bottom etch_ly)
					subclass = _bottom
					text = _text_bot
					is_mirrored = t
					
					this_xy = xy_mirr
					this_textblock = textblock_mirr
				)
				( t
					subclass = cadr( parseString( etch_ly "_"))
					text = get_etch_layer_text_Derek06112019( etch_ly)
					is_mirrored = nil
					
					this_xy = xy
					this_textblock = textblock
				)
			)
			;;
			when( and( stringp( text) stringp( subclass))
				layer = strcat( _cls_df "/" subclass)
				unless( axlIsLayer( layer) axlLayerCreateNonConductor( layer))
				text_id = create_text_Derek06112019( text this_xy this_textblock is_mirrored layer)
				when( text_id axlDBAddGroupObjects( group_id text_id))
			)
		)
		
		;;; silkscreen bottom
		is_mirrored = t
		text_id = create_text_Derek06112019( _text_silk_bot xy_mirr textblock_mirr is_mirrored _sb_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; pastmask bottom
		is_mirrored = t
		text_id = create_text_Derek06112019( _text_past_bot xy_mirr textblock_mirr is_mirrored _pb_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; soldermask bottom
		is_mirrored = t
		text_id = create_text_Derek06112019( _text_mask_bot xy_mirr textblock_mirr is_mirrored _mb_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; pcb fab
		is_mirrored = nil
		text_id = create_text_Derek06112019( _text_pcb_fab xy textblock is_mirrored _pf_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; panel
		is_mirrored = nil
		text_id = create_text_Derek06112019( _text_panel xy textblock is_mirrored _pn_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; pcba top
		is_mirrored = nil
		text_id = create_text_Derek06112019( _text_pcba_top xy textblock is_mirrored _pbt_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; pcba bot
		is_mirrored = t
		text_id = create_text_Derek06112019( _text_pcba_bot xy_mirr textblock_mirr is_mirrored _pbb_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		;;; drill map
		is_mirrored = nil
		text_id = create_text_Derek06112019( _text_drill_map xy textblock is_mirrored _ndl_ly)
		when( text_id axlDBAddGroupObjects( group_id text_id))
		
		return( t)
	)
)

procedure( create_logo_main_Derek06112019( )
	prog( ( orign_visi xy_textblock xy_textblock_mirr result)
		
		init_Derek06112019( )
		
		unless( init_check_Derek06112019( ) return( nil))
		
		orign_visi = axlVisibleGet()
		
		;;;; get key of [layer]
		xy_textblock = get_key_from_layer_Derek06112019( _key_layer _bfy_lyname)
		xy_textblock_mirr = get_key_from_layer_Derek06112019( _key_layer _bfy_mirr_lyname)
		
		unless( and( dtpr( xy_textblock) dtpr( xy_textblock_mirr))
			axlVisibleSet( orign_visi)
			return( nil)
		)
		
		;;;; remove group
		remove_group_Derek06112019( )
		
		;;;; create text in each layer
		result = create_text_on_layers_Derek06112019( xy_textblock xy_textblock_mirr)
		
		when( result
			axlUIConfirm( "'create logo' process has been done. Please check this out")
			println( "'create logo' process has been done. Please check this out")
		)
		
		;;;; restore the visible
		axlVisibleSet( orign_visi)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

axlCmdRegister( "create_logo" 'create_logo_main_Derek06112019)
; create_logo_main_Derek06112019()
; skill (encrypt "c:/skill/create_logo_v1.il" "c:/skill/create_logo_v1.ile")
; (load "create_logo_v1.ile")
; (load "create_logo_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup