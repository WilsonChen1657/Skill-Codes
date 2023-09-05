;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
; 
; Developer: Derek Hsu
; Starting Date: 4/12/2021 - _Derek04122021
; Introduction: create void on drill on top/bottom
;			the drill may be from pth/npth nc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; enviromnent

procedure( init_Derek04122021()
	setq( _me_hole_top_layer "BOARD GEOMETRY/ME_HOLE_TOP")
	setq( _me_hole_bot_layer "BOARD GEOMETRY/ME_HOLE_BOT")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of enviromnent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_pin_dip_Derek04122021()
	prog( (dip_pin_ls)
		sym_ls = setof( x axlDBGetDesign()->symbols stringp( x->refdes))
		
		foreach( sym_id sym_ls
			pin_ls = setof( x sym_id->pins x->isThrough)
			
			dip_pin_ls = append( dip_pin_ls pin_ls)
		)
		
		return( dip_pin_ls)
	)
)

procedure( get_path_Derek04122021( pin_id)
	prog( ( poly)
		poly = car( axlPolyFromDrillHole( pin_id))
		
		return( poly)
	)
)

procedure( get_pins_path_Derek04122021( dip_pin_ls)
	; pin_id = car( axlGetSelSet())
	prog( (path vod_path_ls)
		foreach( pin_id dip_pin_ls
			path = get_path_Derek04122021( pin_id)
			vod_path_ls = append1( vod_path_ls path)
		)
		
		return( vod_path_ls)
	)
)

procedure( create_vods_Derek04122021( layer path_ls)
	let( (void_id)
		foreach( path path_ls
			void_id = car( axlDBCreateShape( path nil layer))
		)
	)
)

procedure( new_layer_Derek04122021( layer)
	let( ( shape_ls)
		unless( axlIsLayer( layer) axlLayerCreateNonConductor( layer))
		
		shape_ls = axlDBGetShapes( layer)
		axlDeleteObject( shape_ls)
	)
)

procedure( new_vods_Derek04122021( layer vod_path_ls)
	let( ()
		new_layer_Derek04122021( layer)
		create_vods_Derek04122021( layer vod_path_ls)
	)
)

procedure( create_void_on_drl_main_Derek04122021()
	prog( ()
		unless( axlOKToProceed() println( "Please done the current function to execute this function") (return nil))
		;;
		
		init_Derek04122021()
		
		;;;;; get target pins
		dip_pin_ls = get_pin_dip_Derek04122021()
		
		;;;;; get data (layer, path)
		vod_path_ls = get_pins_path_Derek04122021( dip_pin_ls)
		
		;;;;; create void
		new_vods_Derek04122021( _me_hole_top_layer vod_path_ls)
		new_vods_Derek04122021( _me_hole_bot_layer vod_path_ls)
		
		sprintf( msg "The unfilled shape of drill of PTH/NPTH has been created on %s and %s" _me_hole_top_layer _me_hole_bot_layer)
		printf( "\n\n%s\n\n" msg)
		axlUIConfirm( msg)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "create_void_on_drl" 'create_void_on_drl_main_Derek04122021)
; create_void_on_drl_main_Derek04122021()
; skill (encrypt "C:/skill/create_void_on_drl_v1.il" "C:/skill/create_void_on_drl_v1.ile")
; (load "create_void_on_drl_v1.ile")
; (load "create_void_on_drl_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup