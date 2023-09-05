;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; developer: Derek Hsu
; Starting Date: 2021/07/14
; introduction: in some cases, misc nets closing to high speed under BGA has to do backdrill, otherwise, coupling may cause
;		the impedance interference
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init()
	setq( _allegro_path getWorkingDir())
	
	setq( _hs_sym_pincount_lbound 10)
	
	defstruct( aside_struct surface ls_pin_id hs_pin_id pitch)
	
	;;;;; filename
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _out_filename "msic_aside_hs_under_sym-%s.csv" _date_time)
	sprintf( _out_fileaddr "%s/%s" _allegro_path _out_filename)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_nets_in_diffpair()
	prog( ( diffpair_ls hs_net_ls)
		diffpair_ls = axlDBGetDesign()->diffpair
		
		foreach( diffpair_id diffpair_ls
			hs_net_ls = append( hs_net_ls diffpair_id->groupMembers)
		)
		
		hs_net_ls = remove_duplicated( hs_net_ls)
		
		return( hs_net_ls)
	)
)

procedure( remove_duplicated( dataset_ls)
	prog( ()
		dataset_ls = reverse( dataset_ls)
		
		dataset_ls = maplist( lambda( (xs) unless( exists( x cdr( xs) x == car( xs)) car( xs))) dataset_ls)
		dataset_ls = remq( nil dataset_ls)
		
		dataset_ls = reverse( dataset_ls)
		
		return( dataset_ls)
	)
)

procedure( get_pin_with_hs()
	prog( (hs_pin_ls pin_on_net_ls)
		hs_net_ls = get_nets_in_diffpair()
		
		foreach( net_id hs_net_ls
			pin_on_net_ls = axlPinsOfNet( net_id 'pin)
			hs_pin_ls = append( hs_pin_ls pin_on_net_ls)
			
			hs_pin_ls = remove_duplicated( hs_pin_ls)
		)
		
		;;;;; remove RLC
		hs_pin_ls = setof( x hs_pin_ls length( x->parent->pins) > _hs_sym_pincount_lbound)
		
		;;;;; remove power diffpair
		hs_pin_ls = setof( x hs_pin_ls is_common_net( x->net))
		
		return( hs_pin_ls)
	)
)

procedure( get_subclass( layer)
	prog( (subclass)
		subclass = cadr( parseString( layer "/")) || ""
		
		return( subclass)
	)
)

procedure( get_pitch_from_sym( sym_id)
	prog( ( number_pin_ls pin_ls pin1_id pin2_id pin3_id pitch1 pitch2 pitch)
		unless( sym_id->pins
			return( 0.0)
		)
		
		pin_ls = sym_id->pins
		
		;;;;; get a pin from symbol pin list
		pin1_id = nth( (length( pin_ls) / 2) pin_ls)
		pin1_xy = pin1_id->xy
		
		rest_pin_ls = remq( pin1_id pin_ls)
		rest_distance_pin_ls = mapcar( lambda( (x) list( axlDistance( pin1_xy x->xy) x)) rest_pin_ls)
		rest_distance_pin_ls = sortcar( rest_distance_pin_ls 'lessp)
		pitch = caar( rest_distance_pin_ls)
		
		return( pitch)
	)
)

procedure( get_box( xy extent)
	prog( ( x y left_down_xy right_up_xy box)
		unless( xy && plusp( extent)
			return( list( list( 0.0 0.0) list( 0.0 0.0)))
		)
		
		x = car( xy)
		y = cadr( xy)
		
		left_down_xy = list( x - extent y - extent)
		right_up_xy = list( x + extent y + extent)
		
		box = list( left_down_xy right_up_xy)
		
		return( box)
	)
)

procedure( get_aside_pin_in_box( center_pin_id box)
	prog( ( sym_pin_ls inbox_pin_ls)
		sym_pin_ls = center_pin_id->parent->pins
		inbox_pin_ls = setof( pin_id sym_pin_ls axlIsPointInsideBox( pin_id->xy box))
		inbox_pin_ls = remq( center_pin_id inbox_pin_ls)
		
		return( inbox_pin_ls)
	)
)

procedure( is_power_net_name( net_name)
	; net_name = "P3V3_SFP_MAR_H "
	prog( ( is_pwr)
		unless( stringp( net_name)
			return( nil)
		)
		
		is_pwr = rexMatchp( "P[0-9]*V[0-9]*" net_name)
		
		return( is_pwr)
	)
)

procedure( is_common_net( net_id)
	prog( ( net_name)
		net_name = net_id->name
		unless( net_name return( nil))
		
		when( net_name == "" return( nil))
		
		when( index( net_name "GND") return( nil))
		
		when( is_power_net_name( net_name) return( nil))
		
		return( t)
	)
)

procedure( get_aside_lspin_in_box( hs_pin_ls hs_pin_id box)
	prog( ( ls_pin_ls)
		ls_pin_ls = get_aside_pin_in_box( hs_pin_id box)
		ls_pin_ls = setof( x ls_pin_ls is_common_net( x->net))
		ls_pin_ls = setof( x ls_pin_ls !memq( x hs_pin_ls))
		
		return( ls_pin_ls)
	)
)

procedure( get_lspins_aside_hs( hs_pin_ls)
	; hs_pin_id = car( hs_pin_ls)
	prog( ( pitch boxls_pin_ls surface aside_stru aside_stru_ls)
		foreach( hs_pin_id hs_pin_ls
			surface = hs_pin_id->parent->layer
			pitch = get_pitch_from_sym( hs_pin_id->parent)
			box = get_box( hs_pin_id->xy pitch)
			ls_pin_ls = get_aside_lspin_in_box( hs_pin_ls hs_pin_id box)
				
			foreach( ls_pin_id ls_pin_ls
				aside_stru = make_aside_struct( ?surface surface
						?ls_pin_id ls_pin_id
						?hs_pin_id hs_pin_id
						?pitch pitch)
				aside_stru_ls = append1( aside_stru_ls aside_stru)
			)
		)
		
		return( aside_stru_ls)
	)
)

procedure( get_output_line( format dataset)
	prog( ( surface refdes pitch hs_xy hs_netname ls_xy ls_netname line)
		surface = dataset->surface
		refdes = dataset->hs_pin_id->parent->refdes
		sprintf( pitch "%.2f" dataset->pitch)
		sprintf( hs_xy "%L" dataset->hs_pin_id->xy)
		hs_netname = dataset->hs_pin_id->net->name
		sprintf( ls_xy "%L" dataset->ls_pin_id->xy)
		ls_netname = dataset->ls_pin_id->net->name
		
		sprintf( line format surface refdes pitch hs_xy hs_netname ls_xy ls_netname)
		
		return( line)
	)
)

procedure( get_output_lines( dataset_ls)
	prog( ( format title line line_ls)
		format = "%-10s,%-20s,%-8s,%-20s,%-35s,%-20s,%-35s"
		
		sprintf( description
			"\n\n\tThis tool is used to find low speed nets next to a high speed net under symbols, whose pin count is greater than %d\n\n"
			_hs_sym_pincount_lbound
		)
		
		sprintf( title format "Surface" "Refdes" "Pitch" "HS_xy" "HS_Net" "LS_xy" "LS_Net")
		
		foreach( dataset dataset_ls
			line = get_output_line( format dataset)
			
			line_ls = append1( line_ls line)
		)
		
		line_ls = sort( line_ls 'alphalessp)
		
		line_ls = append( list( description title) line_ls)
		
		return( line_ls)
	)
)

procedure( write_file( line_ls)
	prog( ( out_port)
		out_port = outfile( _out_fileaddr "w")
		unless( outportp( out_port)
			println( "ERROR: write_file() - Fail to write file")
			return( nil)
		)
		
		foreach( line line_ls
			fprintf( out_port "%s\n" line)
		)
		
		close( out_port)
	)
)

procedure( done_message()
	prog( (msg)
		msg = "Successfully generate the *.csv to current directory. Please check this out"
		
		printf( "%s\n" msg)
		axlUIConfirm( msg)
		
		when( isFile( _out_fileaddr)
			axlUIViewFileCreate( _out_fileaddr _out_fileaddr nil)
		)
	)
)

procedure( msic_aside_hs_under_sym_main()
	prog( ()
	
		init()
	
		;;;;; get symbol with highspeed signal
		hs_pin_ls = get_pin_with_hs()
		
		;;;;; get low speed next to highspeed
		lspin_aside_hs_ls = get_lspins_aside_hs( hs_pin_ls)
		
		;;;;; convert data to output form
		line_ls = get_output_lines( lspin_aside_hs_ls)
		
		;;;;; write file
		write_file( line_ls)
		
		;;;;; done message
		done_message()
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "msic_aside_hs_under_sym" 'msic_aside_hs_under_sym_main)
 (msic_aside_hs_under_sym_main)
; skill (encrypt "c:/skill/msic_aside_hs_under_sym_v1.il" "c:/skill/msic_aside_hs_under_sym_v1.ile")
; (load "msic_aside_hs_under_sym_v1.ile")
; (load "msic_aside_hs_under_sym_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup