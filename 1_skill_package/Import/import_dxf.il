/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/02/15                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To import dxf and copy data to dxf subclass ( dxft & dxfb )            #
#  Usage:                                                                      #
#       1. Select dxf file to dxf in                                           #
#       2. Select objects to copy to dxft                                      #
#       3. Select objects to copy to dxfb ( ask to rotate 180 after mirror )   #
#       4. Align dxft with dxfb by select                                      #
#       5. Delete ME_DXF layer                                                 #
#       6. Align data on brd with dxf                                          #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_importdxf()
	setq( _today_datetime ParseDateTimeStrToFormat_utilityprogram( getCurrentTime()))
	rexCompile( "[.]")
	setq( _today rexReplace( substring( _today_datetime 1 10) "" 0))
	
	setq( _dxf_in_subclass "ME_DXF")
	setq( _dxf_in_layer strcat( "BOARD GEOMETRY/" _dxf_in_subclass))
	setq( _dxft_subclass strcat( _today "_DXFT"))
	setq( _dxft_layer strcat( "BOARD GEOMETRY/" _dxft_subclass))
	setq( _dxfb_subclass strcat( _today "_DXFB"))
	setq( _dxfb_layer strcat( "BOARD GEOMETRY/" _dxfb_subclass))
	
	setq( _align_dxf_line_ls nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main

procedure( Main_importdxf()
	prog( ( result)
		unless( Main_locker()
			return( nil)
		)
		
		Init_importdxf()
		RunDxfIn_importdxf()
		when( axlIsLayer( _dxf_in_layer)
			PlaceDxf_importdxf()
		)
		
		printf( "INFO: Main_importdxf() - Deleting layer %L\n" _dxf_in_layer)
		DeleteLayer_utilityprogram( _dxf_in_layer)
		
		result = axlUIYesNo( "Do you have data to align with DXF?" "Import DXF" 'no)
		when( result
			AlignDxfWithBrd_importdxf()
		)
		
		msg = "Import DXF complete!"
		printf( "INFO: Main_importdxf() - %s\n" msg)
		axlUIConfirm( msg)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( RunDxfIn_importdxf()
	let( ( cmd_ls cmd)
		cmd_ls = list( "dxf in"
						; select dxf
						"FORM dxfInMain browsedxf"
						"FORM dxfInMain units MM "
						"FORM dxfInMain texttable NO "
						"FORM dxfInMain incremental YES "
						"FORM dxfInMain fillshapes NO ")
		; edit/view layers
		layer_cmd_ls = list( "FORM dxfInMain editcnvprofile "
						"FORM dxfInMapping selectall YES "
						"FORM dxfInMapping classenum BOARD GEOMETRY ")
		unless( axlIsLayer( _dxf_in_layer)
			layer_cmd_ls = append( layer_cmd_ls list( "FORM dxfInMapping newsubclass "
													sprintf( nil "fillin \"%s\" " _dxf_in_subclass)))
		)
		
		layer_cmd_ls = append1( layer_cmd_ls sprintf( nil "FORM dxfInMapping subclassenum %s " _dxf_in_subclass))
		cmd_ls = append( cmd_ls layer_cmd_ls)
		
		map_cmd_ls = list( "FORM dxfInMapping map "
							"FORM dxfInMapping done  "
							"FORM dxfInMain import "
							"FORM dxfInMain cancel ")
		cmd_ls = append( cmd_ls map_cmd_ls)
		cmd = buildString( cmd_ls ";")
		axlShell( cmd)
	)
)

procedure( PlaceDxf_importdxf()
	prog( ( result angle msg)
		printf( "INFO: PlaceDxf() - Start")
		_align_dxf_line_ls = nil
		CopyDxf_importdxf( _dxft_layer)
		result = axlUIYesNo( "Do you need to rotate 180 degree after mirror on DXFB?" "Import DXF - Copy to DXFB" 'yes)
		angle = if( result 180 0)
		CopyDxf_importdxf( _dxfb_layer ?mirror t ?angle angle)
		
		printf( "INFO: PlaceDxf() - Copy Dxf complete\n")
	)
)

procedure( CopyDxf_importdxf( target_layer @key (mirror nil) (angle 0))
	prog( ( msg obj_ls copy_obj_ls result)
		printf( "INFO: CopyDxf() - Start copying to %s" target_layer)
		if( axlIsLayer( target_layer)
			axlDeleteByLayer( target_layer)
			axlLayerCreateNonConductor( target_layer)
		)
		
		axlVisibleDesign( nil)
		axlVisibleLayer( _dxf_in_layer t)
		msg = strcat( "SETP 1/2 : Select objects to copy to " target_layer)
		obj_ls = SelectObjectList_importdxf( msg _dxf_in_layer)
		unless( dtpr( obj_ls)
			return( nil)
		)
		
		copy_obj_ls = axlCopyObject( obj_ls ?mirror mirror ?angle angle)
		result = axlChangeLayer( copy_obj_ls target_layer)
		
		axlVisibleDesign( nil)
		axlVisibleLayer( target_layer t)
		; select a line circle to align
		msg = "SETP 2/2 : Select a object to align with"
		obj_ls = SelectObjectList_importdxf( msg target_layer)
		dxf_line_id = car( obj_ls)
		_align_dxf_line_ls = append1( _align_dxf_line_ls dxf_line_id)
		
		when( length( _align_dxf_line_ls) == 2
			mid_point1 = axlMidPointLine( nth( 0 _align_dxf_line_ls)->bBox)
			mid_point2 = axlMidPointLine( nth( 1 _align_dxf_line_ls)->bBox)
			move = axlMXYAdd( mid_point1 list( -nth( 0 mid_point2) -nth( 1 mid_point2)))
			axlTransformObject( copy_obj_ls ?move move)
		)
		
		when( result
			printf( "INFO: CopyDxf() - Copy to [%s] complete!" target_layer)
		)
		
		return( result)
	)
)

procedure( SelectObjectList_importdxf( msg @optional (target_layer nil) (filter nil))
	prog( ( obj_ls)
		SetFindFilter_utilityprogram( filter)
		axlUIConfirm( msg)
		obj_ls = SelectObjectByUser_utilityprogram( nil ?prompt msg)
		when( target_layer
			obj_ls = setof( x obj_ls equal( x->layer target_layer))
		)
		
		return( obj_ls)
	)
)

procedure( AlignDxfWithBrd_importdxf()
	let( ( msg obj_ls dxf_line_id mid_point base_pin_id move)
		axlVisibleDesign( nil)
		axlVisibleLayer( _dxft_layer t)
		; select a line circle to align
		msg = "SETP 1/2 : Select a object to align"
		obj_ls = SelectObjectList_importdxf( msg _dxft_layer)
		dxf_line_id = car( obj_ls)
		mid_point = axlMidPointLine( dxf_line_id->bBox)
		
		; align content
		axlVisibleDesign( nil)
		axlVisibleLayer( "PIN/TOP" t)
		axlZoomFit( 0)
		; select a pin to align
		msg = "SETP 2/2 : Select a PIN to align"
		obj_ls = SelectObjectList_importdxf( msg nil '(pins))
		base_pin_id = car( obj_ls)
	
		move = axlMXYAdd( base_pin_id->xy list( -nth( 0 mid_point) -nth( 1 mid_point)))
		
		; Get all object on dxft & dxfb to move
		obj_ls = GetAll_utilityprogram( _dxft_layer)
		obj_ls = append( obj_ls GetAll_utilityprogram( _dxfb_layer))
		
		axlTransformObject( obj_ls ?move move)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "import_dxf" 'Main_importdxf ?cmdType "general")
/*
(encrypt "c:/skill/import_dxf_v1d1.il" "c:/skill/import_dxf_v1d1.ile")
(load "import_dxf_v1d1.il")
(load "import_dxf_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup