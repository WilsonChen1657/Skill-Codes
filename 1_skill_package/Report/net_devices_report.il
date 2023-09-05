;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
;Developer: Derek Hsu
;Starting Date: 6/16/2021 - _Derek06162021
;Introduction: export following data
;	1. netclass of net
;	2. net name - maybe concat more than one net name
;		1. if 2 nets share a 2 pins component, then combine these 2 together
;		2. remove power or ground signal
;	3. devices - the refdes on current net, sorted by pin count
;		1. upper bound is 10
;	4. extension: csv
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global

procedure( init()
	setq( _allegro_path getWorkingDir())
	
	;;;;; filename
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _date_time "%.4d%s%.2d-%.2d%.2d%.2d" _year _month _date _hour _minute _second)
	sprintf( _out_filename "net_devices_report-%s.csv" _date_time)
	sprintf( _out_fileaddr "%s/%s" _allegro_path _out_filename)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_children_of_net( net_id)
	prog( ( children)
		foreach( br net_id->branches
			children = append( children br->children)
		)
		
		return( children)
	)
)

procedure( is_shape_in_net( net_id)
	prog( ( child_ls shape_ls is_any)
		child_ls = get_children_of_net( net_id)
		shape_ls = setof( x child_ls x->objType == "shape")
		is_any = !zerop( length( shape_ls))
		
		return( is_any)
	)
)

procedure( get_syms_in_net( net_id)
	prog( ( pin_ls sym_ls)
		pin_ls = axlPinsOfNet( net_id 'pin)
		sym_ls = pin_ls~>parent
		
		return( sym_ls)
	)
)

procedure( get_netclass_on_net( net_id)
	prog( ( netclass_id netclass_name)
		unless( net_id return( ""))
		
		netclass_id = axlNetClassGet( net_id 'physical t)
		netclass_name = netclass_id->name || ""
		
		return( netclass_name)
	)
)

procedure( get_nets()
	prog( ( net_ls)
		net_ls = axlDBGetDesign()->nets
		
		;;;;; remove dummy net
		net_ls = setof( x net_ls !axlIsDummyNet( x))
		
		;;;;; to remove power and ground
		net_ls = setof( x net_ls !is_shape_in_net( x))
		
		;;;;; to remove net attaching less then 2 component
		net_ls = setof( x net_ls length( get_syms_in_net( x)) > 1)
		
		;;;;; to remove net without netclass
		net_ls = setof( x net_ls get_netclass_on_net( x) != "")
		
		return( net_ls)
	)
)

procedure( get_pin_count( sym_id)
	prog( ( pin_ls pin_count)
		pin_ls = sym_id->pins
		
		pin_ls = setof( x pin_ls x->name != "")
		
		pin_ls = setof( x pin_ls !axlIsDummyNet( x->net))
		
		pin_count = length( pin_ls)
		
		return( pin_count)
	)
)

procedure( map_net_by_2pin_comp( net_ls)
	prog( ( pin2sym_ls pin_2 net_2 net2_ls)
		pin2sym_ls = setof( x axlDBGetDesign()->symbols get_pin_count( x) == 2)
		
		foreach( sym_id pin2sym_ls
			pin_2 = sym_id->pins
			when( forall( p pin_2 memq( p->net net_ls))
				net_2 = pin_2~>net
				net2_ls = append1( net2_ls net_2)
				
				foreach( net_id net_2
					net_ls = remq( net_id net_ls)
				)
			)
		)
		
		net_ls = mapcar( 'list net_ls)
		net2_ls = append( net2_ls net_ls)
		
		return( net2_ls)
	)
)

procedure( get_output_netclass( net_2)
	prog( ( netclass1 netclass2 netclass)
		netclass1 = get_netclass_on_net( car( net_2))
		netclass2 = get_netclass_on_net( cadr( net_2))
		
		cond(
			( netclass1 == netclass2
				netclass = netclass1
			)
			( netclass2 == ""
				netclass = netclass1
			)
			( netclass1 != netclass2
				netclass = strcat( netclass1 "|" netclass2)
			)
			( t
				netclass = ""
			)
		)
		
		return( netclass)
	)
)

procedure( compare_ref( sym1_id sym2_id)
	prog( ( pin_count1 pin_count2 compare)
		pin_count1 = get_pin_count( sym1_id)
		pin_count2 = get_pin_count( sym2_id)
		
		cond(
			( pin_count1 == pin_count2
				compare = strcmp( sym1_id->refdes sym2_id->refdes) > 0
			)
			( t
				compare = pin_count1 > pin_count2
			)
		)
		
		return( compare)
	)
)

procedure( get_output_syms( net_2)
	prog( (sym1_ls sym2_ls sym_ls)
		sym1_ls = get_syms_in_net( car( net_2))
		sym2_ls = get_syms_in_net( cadr( net_2))
		
		sym2_ls = setof( x sym2_ls !memq( x sym1_ls))
		
		sym_ls = append( sym1_ls sym2_ls)
		
		sym_ls = sort( sym_ls 'compare_ref)
		
		refdes = buildString( sym_ls~>refdes "|")
		
		
		return( refdes)
	)
)

procedure( get_output_netname( net_2)
	prog( ( net_name1 net_name2 net_name)
		net_name1 = car( net_2)->name || ""
		net_name2 = cadr( net_2)->name || ""
		
		cond(
			( net_name1 == net_name2
				net_name = net_name1
			)
			( net_name2 == ""
				net_name = net_name1
			)
			( net_name1 != net_name2
				net_name = strcat( net_name1 "|" net_name2)
			)
			( t
				net_name = ""
			)
		)
		
		return( net_name)
	)
)

procedure( get_output_lines( net2_ls)
	prog( ( foramt line line_ls net_name netclass refdes )
		format = "%s,%s,%s"
		
		sprintf( header format "NetClass" "NetName" "Devices")
		
		foreach( net_2 net2_ls
			
			;;;;; get net name
			net_name = get_output_netname( net_2)
			
			;;;;; get netclass
			netclass = get_output_netclass( net_2)
			
			;;;;; get refdes
			refdes = get_output_syms( net_2)
			
			;;;;; combine to a line
			sprintf( line format netclass net_name refdes)
			
			line_ls = append1( line_ls line)
		)
		
		line_ls = sort( line_ls 'alphalessp)
		
		line_ls = append( list( header) line_ls)
		
		return( line_ls)
	)
)

procedure( write_lines( line_ls)
	prog( ( out_port)
		out_port = outfile( _out_fileaddr "w")
		unless( outportp( out_port)
			println( "ERROR: write_lines() - Fail to write file")
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
	)
)

procedure( net_devices_report_main()
	prog( ()
		unless( axlOKToProceed()
			println( "Please done the current function to keep continue")
			return( nil)
		)
		
		init()
		
		;;;;; get all net
		net_ls = get_nets()
		; output (net_id ...)
		
		;;;;; combine net
		net2_ls = map_net_by_2pin_comp( net_ls)
		; input ( net_id ...)
		; output ( (net_id [net_id])...)
		
		;;;;; get output format
		line_ls = get_output_lines( net2_ls)
		; input ( ( (netclass [netclass]) (net_id [net_id]) (refdes_id...))...)
		; output netclass,netName,devices...
		
		;;;;; export csv
		write_lines( line_ls)
		
		;done_message()
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "net_devices_report" 'net_devices_report_main)
 (net_devices_report_main)
; skill (encrypt "c:/skill/net_devices_report_v1.il" "c:/skill/net_devices_report_v1.ile")
; (load "net_devices_report_v1.ile")
; (load "net_devices_report_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;