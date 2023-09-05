;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 06/04/2019 - _Derek06042019
; background:
; 	1. creating artwork by
; 		1. create fundamental film
; 		2. create film including drill
;	2. for version control
;		1. [17.2]: board geometry/design_outline
;		2. [16.6]: board geometry/outline
;	3. layers
;		1. silk_top
;		2. paste_top
;		3. mask_top
;		4. films for etch
;		5. mask_bot
;		6. paste_bot
;		7. silk_bot
;		8. drill
;		9. drill-1-2
;		10. drill-1-3
;		11. drill-(total-2)-(total)
;		12. drill-(total-1)-(total)
;		13. films for backdrill
;		13. pcb_fab
;		14. panel
;		15. pcba_top
;		16. pcba_bot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek06042019()
	;;; basic information
	setq( _via_cls "VIA CLASS")
	setq( _pin_cls "PIN")
	setq( _etch_cls "ETCH")
	setq( _df_cls "DRAWING FORMAT")
	setq( _mf_cls "MANUFACTURING")
	setq( _nl_form "NCLEGEND-%d-%d")
	setq( _outer_ly_ls list( "TOP" "BOTTOM"))
	setq( _artwork_filename "art_param.txt")
	
	;;; general information
	setq( _allegro_version axlVersion( 'version))
	setq( _allegro_accuracy cadr( axlDBGetDesignUnits()))
	setq( _etch_ly_ls axlGetParam("paramLayerGroup:ETCH")->groupMembers)
	setq( _etch_total axlGetParam("paramLayerGroup:ETCH")->nChildren)
	setq( _class_ls axlClasses())
	setq( _exists_backdrill is_backdrill_Derek06042019())
	setq( _exists_laser_via is_laser_via_Derek06042019())
	
	
	;;; single layer name definition
	
	setq( _pg_sst_ly "PACKAGE GEOMETRY/SILKSCREEN_TOP")
	setq( _pg_pmt_ly "PACKAGE GEOMETRY/PASTEMASK_TOP")
	setq( _pg_smt_ly "PACKAGE GEOMETRY/SOLDERMASK_TOP")
	setq( _pg_ssb_ly "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM")
	setq( _pg_pmb_ly "PACKAGE GEOMETRY/PASTEMASK_BOTTOM")
	setq( _pg_smb_ly "PACKAGE GEOMETRY/SOLDERMASK_BOTTOM")
	
	setq( _bg_ol_ly if( (_allegro_version > 17.0) "BOARD GEOMETRY/DESIGN_OUTLINE" "BOARD GEOMETRY/OUTLINE"))
	setq( _bg_ol_ls if( (_allegro_version > 17.0) list( "BOARD GEOMETRY/DESIGN_OUTLINE" "BOARD GEOMETRY/CUTOUT") list( "BOARD GEOMETRY/OUTLINE")))
	
	setq( _bg_lg_ly "BOARD GEOMETRY/LOGO")
	setq( _bg_lgm_ly "BOARD GEOMETRY/LOGO_MIRROR")
	setq( _bg_sst_ly "BOARD GEOMETRY/SILKSCREEN_TOP")
	setq( _bg_smt_ly "BOARD GEOMETRY/SOLDERMASK_TOP")
	setq( _bg_ssb_ly "BOARD GEOMETRY/SILKSCREEN_BOTTOM")
	setq( _bg_smb_ly "BOARD GEOMETRY/SOLDERMASK_BOTTOM")
	setq( _bg_amn_ly "BOARD GEOMETRY/ASSEMBLY_NOTES")
	
	setq( _df_sst_ly "DRAWING FORMAT/SILKSCREEN_TOP")
	setq( _df_pmt_ly "DRAWING FORMAT/PASTEMASK_TOP")
	setq( _df_smt_ly "DRAWING FORMAT/SOLDERMASK_TOP")
	setq( _df_ssb_ly "DRAWING FORMAT/SILKSCREEN_BOTTOM")
	setq( _df_pmb_ly "DRAWING FORMAT/PASTEMASK_BOTTOM")
	setq( _df_smb_ly "DRAWING FORMAT/SOLDERMASK_BOTTOM")
	setq( _df_ndl_ly "DRAWING FORMAT/NCDRILL_LEGEND")
	setq( _df_top_ly "DRAWING FORMAT/TOP")
	setq( _df_bot_ly "DRAWING FORMAT/BOTTOM")
	
	setq( _vc_pmt_ly "VIA CLASS/PASTEMASK_TOP")
	setq( _vc_smt_ly "VIA CLASS/SOLDERMASK_TOP")
	setq( _vc_pmb_ly "VIA CLASS/PASTEMASK_BOTTOM")
	setq( _vc_smb_ly "VIA CLASS/SOLDERMASK_BOTTOM")
	setq( _vc_top_ly "VIA CLASS/TOP")
	setq( _vc_bot_ly "VIA CLASS/BOTTOM")
	
	setq( _pn_pmt_ly "PIN/PASTEMASK_TOP")
	setq( _pn_smt_ly "PIN/SOLDERMASK_TOP")
	setq( _pn_pmb_ly "PIN/PASTEMASK_BOTTOM")
	setq( _pn_smb_ly "PIN/SOLDERMASK_BOTTOM")
	setq( _pn_fmt_ly "PIN/FILMMASKTOP")
	setq( _pn_top_ly "PIN/TOP")
	setq( _pn_fmb_ly "PIN/FILMMASKBOTTOM")
	setq( _pn_bot_ly "PIN/BOTTOM")
	
;	setq( _mf_ppo_ly "MANUFACTURING/PHOTOPLOT_OUTLINE")
	setq( _mf_nl_tb_ly sprintf( nil "MANUFACTURING/NCLEGEND-1-%d" _etch_total))
;	setq( _mf_nl_t2_ly "MANUFACTURING/NCLEGEND-1-3")
;	setq( _mf_nl_t1_ly "MANUFACTURING/NCLEGEND-1-2")
;	setq( _mf_nl_b2_ly sprintf( nil "MANUFACTURING/NCLEGEND-%d-%d" (_etch_total - 2) _etch_total))
;	setq( _mf_nl_b1_ly sprintf( nil "MANUFACTURING/NCLEGEND-%d-%d" (_etch_total - 1) _etch_total))
	
	setq( _et_top_ly "ETCH/TOP")
	setq( _et_bot_ly "ETCH/BOTTOM")
	
	setq( _rd_sst_ly "REF DES/SILKSCREEN_TOP")
	setq( _rd_ssb_ly "REF DES/SILKSCREEN_BOTTOM")
	
;	setq( _cv_sst_ly "COMPONENT VALUE/SILKSCREEN_TOP")
;	setq( _cv_ssb_ly "COMPONENT VALUE/SILKSCREEN_BOTTOM")
	
	;;;; special layer from setup_pcb_form_data tool
	setq( _df_pfb_ly "DRAWING FORMAT/PCB_FAB")
	setq( _df_pnl_ly "DRAWING FORMAT/PANEL")
	setq( _df_pbt_ly "DRAWING FORMAT/PCBA_TOP")
	setq( _df_pbb_ly "DRAWING FORMAT/PCBA_BOT")
	setq( _bg_bdf_ly "BOARD GEOMETRY/BOARD_FORM")
	setq( _bg_bfm_ly "BOARD GEOMETRY/BOARD_FORM_MIRROR")
	setq( _bg_bfk_ly "BOARD GEOMETRY/BOARD_FORM_KEY")
	setq( _bg_bkm_ly "BOARD GEOMETRY/BOARD_FORM_KEY_MIRROR")
	setq( _bg_frm_ly "BOARD GEOMETRY/FRAME")
	
	;;; film package definition
	setq( _film_silk_top_ly_ls append( list( _pg_sst_ly _df_sst_ly _bg_sst_ly _rd_sst_ly _bg_lg_ly) _bg_ol_ls))
	setq( _film_silk_bot_ly_ls append( list( _pg_ssb_ly _df_ssb_ly _bg_ssb_ly _rd_ssb_ly _bg_lgm_ly) _bg_ol_ls))
	
	setq( _film_paste_top_ly_ls append( list( _vc_pmt_ly _pn_pmt_ly _pg_pmt_ly _df_pmt_ly _bg_lg_ly) _bg_ol_ls))
	setq( _film_paste_bot_ly_ls append( list( _vc_pmb_ly _pn_pmb_ly _pg_pmb_ly _df_pmb_ly _bg_lgm_ly) _bg_ol_ls))
	
	setq( _film_mask_top_ly_ls append( list( _vc_smt_ly _pn_smt_ly _pg_smt_ly _df_smt_ly _bg_smt_ly _bg_lg_ly) _bg_ol_ls))
	setq( _film_mask_bot_ly_ls append( list( _vc_smb_ly _pn_smb_ly _pg_smb_ly _df_smb_ly _bg_smb_ly _bg_lgm_ly) _bg_ol_ls))
	
	setq( _film_drl_tb_ls append( list( _mf_nl_tb_ly _bg_lg_ly _df_ndl_ly) _bg_ol_ls))
	setq( _film_gen_drl_ls append( list( _bg_lg_ly _df_ndl_ly) _bg_ol_ls))
	setq( _film_gen_bd_ls append( list( _bg_lg_ly _df_ndl_ly) _bg_ol_ls))
	
	setq( _film_top_ls append( list( _pn_fmt_ly _vc_top_ly _pn_top_ly _et_top_ly _df_top_ly _bg_lg_ly) _bg_ol_ls))
	setq( _film_bot_ls append( list( _pn_fmb_ly _vc_bot_ly _pn_bot_ly _et_bot_ly _df_bot_ly _bg_lgm_ly) _bg_ol_ls))
;	setq( _film_gen_int_ls append( list( _bg_lg_ly) _bg_ol_ls))
;	setq( _film_gen_vcc_ls append( list( _bg_lg_ly) _bg_ol_ls))
;	setq( _film_gen_gnd_ls append( list( _bg_lg_ly) _bg_ol_ls))
	setq( _film_gen_not_diele_ls append( list( _bg_lg_ly) _bg_ol_ls))
	
	setq( _film_panel_old_ls append( list( _bg_amn_ly _bg_lg_ly _df_pnl_ly) _bg_ol_ls))
	
	setq( _film_pcb_fab_ls append( list( _df_pfb_ly _bg_bdf_ly _bg_amn_ly _bg_frm_ly _bg_lg_ly) _bg_ol_ls))
	setq( _film_panel_ls append( list( _bg_bdf_ly _bg_amn_ly _bg_frm_ly _bg_lg_ly _df_pnl_ly) _bg_ol_ls))
	setq( _film_pcba_top_ls append( list( _pg_sst_ly _rd_sst_ly _pn_top_ly _bg_sst_ly _bg_bdf_ly _bg_frm_ly _bg_lg_ly _df_pbt_ly) _bg_ol_ls))
	setq( _film_pcba_bot_ls append( list( _pg_ssb_ly _rd_ssb_ly _pn_bot_ly _bg_ssb_ly _bg_bfm_ly _bg_frm_ly _bg_lgm_ly _df_pbb_ly) _bg_ol_ls))
	
	;;; artwork setting		;;;;; create pcba top/bottom
	;; t_filename
	;; n_rotate_code
	;; n_x_offset
	;; n_y_offset
	;; n_undef_line_width -- for some reason, the value will be divided by 100
	;; n_shape_bound
	;; n_plot_mode
	;; n_mirrored
	;; n_full_contact
	;; n_supp_unconnect
	;; n_draw_pad
	;; n_aper_rot
	;; n_fill_out_shapes
	;; n_vector_based
	setq( _line_width (5 * 10**_allegro_accuracy))
	setq( _shape_bound (10**_allegro_accuracy))
	setq( _artwork_pos_sets list(0 0 0 _line_width _shape_bound 1 0 0 0 0 0 0 1))
	setq( _artwork_neg_sets list(0 0 0 _line_width _shape_bound 1 1 0 0 0 0 0 1))
	; (axlfcreate p_top '(0 0 0 600 10000 1 0 0 0 0 0 0 1) pcba_top_layer)
	
	setq( _xsect_gnd_rex "^L[0-9]+_GND[0-9]+$")
	setq( _xsect_int_rex "^L[0-9]+_INT[0-9]+$")
	setq( _xsect_vcc_rex "^L[0-9]+_VCC[0-9]+$")
	setq( _xsect_int_vcc_rex "^L[0-9]+_INT-VCC[0-9]+$")
	setq( _xsect_int_gnd_rex "^L[0-9]+_INT-GND[0-9]+$")
	setq( _xsect_vcc_gnd_rex "^L[0-9]+_VCC-GND[0-9]+$")
	setq( _xsect_gen_rex "^L\\([0-9]+\\)_\\([-A-Z]+[0-9]+\\)$")
	setq( _xsect_prename_rex "[|A-Z]+")
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_padstack_startend_Derek06042019( padstack_id)
	prog( ( etch_ls pad_ls number_ls)
		unless( equal( "padstack" padstack_id->objType) println( "ArgErr: get_padstack_startend() - padstack_id is not a padstack object") return( nil))
		;;
		
		etch_ls = append( list( nil) mapcar( lambda( (x) strcat( _etch_cls "/" x)) _etch_ly_ls))
		pad_ls = padstack_id->pads
		pad_ls = setof( p pad_ls and( equal( "REGULAR" p->type) index( p->layer "ETCH/") p->figure))
		when( ( length( pad_ls) > 1)
			number_ls = mapcar( lambda( (x) listnindex( etch_ls x->layer)) pad_ls)
		)
		
		return( number_ls)
	)
)

procedure( is_laser_via_Derek06042019()
	;; padstack_id = (car padstack_ls)
	prog( ( padstack_ls start_end start_end_ls start end)
		padstack_ls = axlGetAllViaList()
		padstack_ls = setof( v padstack_ls not( v->isThrough))
		
		; mapcar( 'get_padstack_startend_Derek06042019 padstack_ls)
		foreach( padstack_id padstack_ls
			start_end = get_padstack_startend_Derek06042019( padstack_id)
			when( dtpr( start_end)
				start_end = list( car( start_end) lastelem( start_end))
				
				;;; check is not exists
				start = car( start_end)
				end = cadr( start_end)
				unless( exists( se start_end_ls and( eqv( start car( se)) eqv( end cadr( se))))
					start_end_ls = append1( start_end_ls start_end)
				)
				
			;	printf( "[%s] - %L\n" padstack_id->name start_end_ls)
			)
		)
		
		if( dtpr( start_end_ls)
			printf( "\tFound following laser via on board[from/to]: %L\n" start_end_ls)
			printf( "\tNo laser via has been found\n")
		)
		
		return( start_end_ls)
	)
)

procedure( is_backdrill_Derek06042019()
	;;; ncbg = "NCBACKDRILL-1-13"
	prog( ( subclass_ls start_end_ls start end)
		subclass_ls = axlGetParam( "paramLayerGroup:MANUFACTURING")->groupMembers
		subclass_ls = setof( x subclass_ls index( x "NCBACKDRILL"))
		
		foreach( subclass subclass_ls
			sect3 = parseString( subclass "-")
			start = cadr( sect3)
			end = caddr( sect3)
			start_end_ls = append1( start_end_ls list( subclass start end))
		)
		
		if( dtpr( start_end_ls)
			printf( "\tThis board has backdrill[name/from/to]: %L\n" mapcar( 'car start_end_ls))
			printf( "\tThis board has no backdrill\n")
		)
		
		return( start_end_ls)
	)
)

procedure( check_etch_Derek06042019()
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

procedure( create_layer_Derek06042019( layer)
	prog( ( class)
		unless( stringp( layer) println( "ArgErr: create_layer() - layer is not a string") return( nil))
		class = car( parseString( layer "/"))
		unless( member( class _class_ls) printf( "ArgErr: create_layer() - class[%s] is invalid in allegro\n" class) return( nil))
		;;
		
		unless( axlIsLayer( layer)
			axlLayerCreateNonConductor( layer)
			printf( "create_layer() - Creating layer [%s]\n" layer)
		)
		
		return( t)
	)
)

procedure( check_layer_Derek06042019( artwork_version)
	;; artwork_version: 0 1
	;;;		1. last version having pcb_fab/pcba_top/pcba_bot film
	;;;		2. old version of artwork
	prog( ( start end subclass warn layer)
		unless( memv( artwork_version list( 0 1)) println( "ArgErr: check_layer() - artwork_version has to be 0 or 1") return( nil))
		;;
		
		warn = "Warning: check_layer() -"
		
		when( onep( artwork_version)
			unless( axlIsLayer( _df_pbt_ly) printf( "%s layer[%s] does not exists. Get it by importing pcb_form_data\n" warn _df_pbt_ly))
			unless( axlIsLayer( _df_pnl_ly) printf( "%s layer[%s] does not exists. Get it by importing pcb_form_data\n" warn _df_pnl_ly))
			unless( axlIsLayer( _df_pbb_ly) printf( "%s layer[%s] does not exists. Get it by importing pcb_form_data\n" warn _df_pbb_ly))
			unless( axlIsLayer( _df_pfb_ly) printf( "%s layer[%s] does not exists. Get it by importing pcb_form_data\n" warn _df_pfb_ly))
			
			unless( axlIsLayer( _bg_bdf_ly) printf( "%s layer[%s] does not exists. Get it by importing Flex_pcb_form\n" warn _bg_bdf_ly))
			unless( axlIsLayer( _bg_bfm_ly) printf( "%s layer[%s] does not exists. Get it by importing Flex_pcb_form\n" warn _bg_bfm_ly))
			unless( axlIsLayer( _bg_bfk_ly) printf( "%s layer[%s] does not exists. Get it by importing Flex_pcb_form\n" warn _bg_bfk_ly))
			unless( axlIsLayer( _bg_bkm_ly) printf( "%s layer[%s] does not exists. Get it by importing Flex_pcb_form\n" warn _bg_bkm_ly))
			unless( axlIsLayer( _bg_frm_ly) printf( "%s layer[%s] does not exists. Please convert your panel frame to this layer\n" warn _bg_frm_ly))
		)
		
		foreach( start_end _exists_laser_via
			start = car( start_end)
			end = cadr( start_end)
			;;
			sprintf( subclass _nl_form start end)
			sprintf( layer "%s/%s" _mf_cls subclass)
			create_layer_Derek06042019( layer)
		)
		
		;;;; create refdes
		create_layer_Derek06042019( _rd_sst_ly)
		create_layer_Derek06042019( _rd_ssb_ly)
		
		return( t)
	)
)

procedure( create_sub_df_Derek06042019()
	;;; in this function, excepting to creating following layer
	;;; VIA CLASS/L2_GND1 and PIN/L2_GND1 and ETCH/L2_GND1 and DRAWING FORMAT/GND1
	let( ( (etch_ly_ls _etch_ly_ls) gnd_ls int_ls vcc_ls layer)
		
		etch_ly_ls = setof( x etch_ly_ls not( member( x _outer_ly_ls)))
		foreach( etch_ly etch_ly_ls
			;;;; create via class/ etch layer
			sprintf( layer "%s/%s" _via_cls etch_ly)
			create_layer_Derek06042019( layer)
			
			;;;; create pin / etch layer
			sprintf( layer "%s/%s" _pin_cls etch_ly)
			create_layer_Derek06042019( layer)
			
			;;;; create etch layer
			sprintf( layer "%s/%s" _etch_cls etch_ly)
			create_layer_Derek06042019( layer)
			
			;;;; create drawing format etch layer
			subclass = cadr( parseString( etch_ly "_"))
			sprintf( layer "%s/%s" _df_cls subclass)
			create_layer_Derek06042019( layer)
		)
	)
)

procedure( create_etch_film_table_Derek06042019( )
	let( ( layer_ls subclass df_ly vc_ly pn_ly et_ly film_etch_table)
		
		film_etch_table = makeTable( "flm_etch_table" nil)
		
		foreach( etch_ly _etch_ly_ls
			cond(
				( equal( "TOP" etch_ly)
					layer_ls = _film_top_ls
				)
				( equal( "BOTTOM" etch_ly)
					layer_ls = _film_bot_ls
				)
				( t
					subclass = cadr( parseString( etch_ly "_"))
					;;
					sprintf( df_ly "%s/%s" _df_cls subclass)
					sprintf( vc_ly "%s/%s" _via_cls etch_ly)
					sprintf( pn_ly "%s/%s" _pin_cls etch_ly)
					sprintf( et_ly "%s/%s" _etch_cls etch_ly)
					
					layer_ls = append( _film_gen_not_diele_ls list( df_ly vc_ly pn_ly et_ly))
				)
;				( index( etch_ly "INT")
;					subclass = cadr( parseString( etch_ly "_"))
;					;;
;					sprintf( df_ly "%s/%s" _df_cls subclass)
;					sprintf( vc_ly "%s/%s" _via_cls etch_ly)
;					sprintf( pn_ly "%s/%s" _pin_cls etch_ly)
;					sprintf( et_ly "%s/%s" _etch_cls etch_ly)
;					
;					layer_ls = append( _film_gen_int_ls list( df_ly vc_ly pn_ly et_ly))
;				)
;				( index( etch_ly "GND")
;					subclass = cadr( parseString( etch_ly "_"))
;					;;
;					sprintf( df_ly "%s/%s" _df_cls subclass)
;					sprintf( vc_ly "%s/%s" _via_cls etch_ly)
;					sprintf( pn_ly "%s/%s" _pin_cls etch_ly)
;					sprintf( et_ly "%s/%s" _etch_cls etch_ly)
;					
;					layer_ls = append( _film_gen_gnd_ls list( df_ly vc_ly pn_ly et_ly))
;				)
;				( index( etch_ly "VCC")
;					subclass = cadr( parseString( etch_ly "_"))
;					;;
;					sprintf( df_ly "%s/%s" _df_cls subclass)
;					sprintf( vc_ly "%s/%s" _via_cls etch_ly)
;					sprintf( pn_ly "%s/%s" _pin_cls etch_ly)
;					sprintf( et_ly "%s/%s" _etch_cls etch_ly)
;					
;					layer_ls = append( _film_gen_vcc_ls list( df_ly vc_ly pn_ly et_ly))
;				)
			)
			
			;;;
			film_etch_table[ etch_ly] = layer_ls
		)
		
		film_etch_table
	)
)

procedure( create_artwork_table_Derek06042019( artwork_version film_etch_table)
	;;; artwork_version:
	;;; 1 to create film including pcb_fab/pcba_top/pcba_bot
	;;; 0 to create film including drill
	;;; value of artwork_table ( is_mirrored layer_ls)
	prog( ( artwork_table cnt)
		unless( memv( artwork_version list( 0 1)) println( "ArgErr: create_artwork_table() - artwork_version has to be 0 or 1") return( nil))
		;;
		
		cnt = 1
		artwork_table = makeTable( "artwork_table" nil)
		
		sprintf( film_nm "%.2d-SILK-TOP" cnt++)
		artwork_table[ film_nm] = list( nil _film_silk_top_ly_ls)
		
		sprintf( film_nm "%.2d-PASTE-TOP" cnt++)
		artwork_table[ film_nm] = list( nil _film_paste_top_ly_ls)
		
		sprintf( film_nm "%.2d-MASK-TOP" cnt++)
		artwork_table[ film_nm] = list( nil _film_mask_top_ly_ls)
		
		foreach( etch_ly _etch_ly_ls
			sprintf( film_nm "%.2d-%s" cnt++ etch_ly)
			artwork_table[ film_nm] = list( nil film_etch_table[ etch_ly])
		)
		
		sprintf( film_nm "%.2d-MASK-BOT" cnt++)
		artwork_table[ film_nm] = list( nil _film_mask_bot_ly_ls)
		
		sprintf( film_nm "%.2d-PASTE-BOT" cnt++)
		artwork_table[ film_nm] = list( nil _film_paste_bot_ly_ls)
		
		sprintf( film_nm "%.2d-SILK-BOT" cnt++)
		artwork_table[ film_nm] = list( nil _film_silk_bot_ly_ls)
		
		sprintf( film_nm "%.2d-DRILL" cnt++)
		artwork_table[ film_nm] = list( nil _film_drl_tb_ls)
		
		foreach( sect2 _exists_laser_via
			start = car( sect2)
			end = cadr( sect2)
			;;
			sprintf( layer1 "%s/NCLEGEND-%d-%d" _mf_cls start end)
			layer_ls = append1( _film_gen_drl_ls layer1)
			;;
			sprintf( film_nm "%.2d-DRILL-%d-%d" cnt++ start end)
			artwork_table[ film_nm] = list( nil layer_ls)
		)
		
		foreach( sect3 _exists_backdrill
			subclass = car( sect3)
			start = cadr( sect3)
			end = caddr( sect3)
			;;
			sprintf( layer1 "%s/%s" _mf_cls subclass)
			sprintf( layer2 "%s/%s" _df_cls subclass)
			layer_ls = append( _film_gen_bd_ls list( layer1 layer2))
			;;
			sprintf( film_nm "%.2d-BD-%s-%s" cnt++ start end)
			artwork_table[ film_nm] = list( nil layer_ls)
		)
		
		if( onep( artwork_version) then
			sprintf( film_nm "%.2d-PCB-FAB" cnt++)
			artwork_table[ film_nm] = list( nil _film_pcb_fab_ls)
			
			sprintf( film_nm "%.2d-PANEL" cnt++)
			artwork_table[ film_nm] = list( nil _film_panel_ls)
			
			sprintf( film_nm "%.2d-PCBA-TOP" cnt++)
			artwork_table[ film_nm] = list( nil _film_pcba_top_ls)
			
			sprintf( film_nm "%.2d-PCBA-BOT" cnt++)
			artwork_table[ film_nm] = list( t _film_pcba_bot_ls)
		else			
			sprintf( film_nm "%.2d-PANEL" cnt++)
			artwork_table[ film_nm] = list( nil _film_panel_old_ls)
		)
		
		return( artwork_table)
	)
)

procedure( remove_film_with_serial_Derek06042019()
	let( ( film_ls art_nm)
		film_ls = axlGetParam( "artwork")->groupMembers
		film_ls = setof( f film_ls plusp( atoi( car( parseString( f "-")))))
		;;
		foreach( f_nm film_ls
			art_nm = strcat( "artwork:" f_nm)
			film_id = axlGetParam( art_nm)
			axlDeleteObject( film_id)
		)
	)
)

procedure( is_former_film_sequence_Derek06042019( a b)
	prog( ( a_num b_num)
		unless( stringp( a) println( "ArgErr: is_former_film_sequence() - a is not a string") return( nil))
		unless( stringp( b) println( "ArgErr: is_former_film_sequence() - b is not a string") return( nil))
		;;
		
		a_num = car( parseString( a "-"))
		b_num = car( parseString( b "-"))
		
		if( and( stringp( a_num) stringp( b_num) plusp( atoi( a_num)) plusp( atoi( b_num))) then
			a_num = atoi( a_num)
			b_num = atoi( b_num)
			
			result = (a_num < b_num)
		else
			printf( "ERROR: is_former_film_sequence() - Fail to get serial number from [%s] and [%s]\n" a b)
		)
		
		return( result)
	)
)

procedure( create_artwork_Derek06042019( artwork_table)
	;;; value of artwork_table ( is_mirrored layer_ls)
	;; film_sets = _artwork_pos_sets
	;; axlfcreate( "haha" film_sets _film_silk_top_ly_ls)
	;; axlGetParam( "artwork")->??
	prog( ( film_nm_ls contents layer_ls film_sets)
		unless( tablep( artwork_table) println( "ArgErr: create_artwork() - artwork_table is not a table") return( nil))
		;;
		
		film_nm_ls = artwork_table->?
		film_nm_ls = sort( film_nm_ls 'is_former_film_sequence_Derek06042019)
		
		foreach( film_nm film_nm_ls
			contents = artwork_table[ film_nm]
			is_mirrored = car( contents)
			layer_ls = cadr( contents)
			
			;;;; create the layer if it's not exists. the layer has to be exists to insert into artwork
			foreach( layer layer_ls create_layer_Derek06042019( layer))
			
			;;;; create artwork
			film_sets = if( is_mirrored _artwork_neg_sets _artwork_pos_sets)
			axlfcreate( film_nm film_sets layer_ls)
		)
	)
)

procedure( write_artwork_param_Derek06042019( )
	prog( ( out_port)
		out_port = outfile( _artwork_filename "w")
		unless( outportp( out_port) println( "ERROR: write_artwork_param() - Fail to write file") return( nil))
		
		fprintf( out_port "DEVICE-TYPE           GERBER_RS274X\n")
		fprintf( out_port "OUTPUT-UNITS          INCHES\n")
		fprintf( out_port "FILM-SIZE             5000000 5000000\n")
		fprintf( out_port "FORMAT                5.5\n")
		fprintf( out_port "ABORT-ON-ERROR        NO\n")
		fprintf( out_port "SCALE                 1\n")
		fprintf( out_port "SUPPRESS-LEAD-ZEROES  YES\n")
		fprintf( out_port "SUPPRESS-TRAIL-ZEROES NO\n")
		fprintf( out_port "SUPPRESS-EQUAL        YES\n")
		fprintf( out_port "UNDEF-APT-CONT        NO\n")
		
		close( out_port)
		
		
		return( nil)
	)
)

procedure( setup_artwork_main_Derek06042019()
	prog( ( result)
		unless( axlOKToProceed() println( "Please done the current function to keep continue") return( nil))
		result = axlUIYesNo( "The film with serial number(ex: [01]-SILK-TOP) will be overwrite. Would you like to keep continue?" "Update artwork confirm" 'yes)
		unless( result return( nil))
		
		init_Derek06042019()
		
		;;;; check all the layer is exists
		unless( dtpr( _etch_ly_ls) println( "ERROR: Fail to get etch layer name") return( nil))
		
		;;;; check naming of the etch
		result = check_etch_Derek06042019()
		unless( result println( "Please correct the etch layer name to use this program") return( nil))
		
		;;;; asking for advance artwork package or a fundamental one
		artwork_version = axlUIYesNoCancel( "Would you like to have artwork version Jun-2019, whose film includs PCB_FAB/PCBA_TOP/PCBA_BOT?"
								"Artwork Version confirm - since Jun-2019" 'yes)
		when( eqv( 2 artwork_version) return( nil))
		
		;;;; check certain layer
		check_layer_Derek06042019( artwork_version)
		
		;;;; create drawing format int?/gnd?/vcc? layer
		create_sub_df_Derek06042019()
		
		;;;; create etch artwork
		film_etch_table = create_etch_film_table_Derek06042019()
		unless( tablep( film_etch_table) println( "Fail to get etch film content") return( nil))
		
		;;;; create film name
		artwork_table = create_artwork_table_Derek06042019( artwork_version film_etch_table)
		unless( tablep( artwork_table) println( "Fail to get artwork name and its content") return( nil))
		
		;;;; remove the film with serial number
		remove_film_with_serial_Derek06042019()
		
		;;;; write artwork parameter
		write_artwork_param_Derek06042019()
		
		;;;; create the film
		create_artwork_Derek06042019( artwork_table)
		
		println( "[Setup Artwork] process is done. Please check your artwork setting")
		axlUIConfirm( "[Setup Artwork] process is done. Please check your artwork setting")
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "setup_artwork" 'setup_artwork_main_Derek06042019)
; (setup_artwork_main_Derek06042019)
; skill (encrypt "C:/skill/setup_artwork_v1.il" "C:/skill/setup_artwork_v1.ile")
; (load "setup_artwork_v1.ile")
; (load "setup_artwork_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup