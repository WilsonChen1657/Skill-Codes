;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 10/21/2021 - _Derek20211021
; Introduction:  create diffpair net name file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variable

procedure( init1_Derek20211021()
	setq( _diffpair_filename "diffpair_netname.csv")
	setq( _netclass_header "NetClass")
	setq( _netname_header "NetName")
	setq( _header_ls list( _netclass_header _netname_header))
)

procedure( init2_Derek20211021()
	setq( _phy_netclass_ls get_phy_netclasses_on_board_Derek20211021())
	
	;;;;; [group]:(netname,...)
	setq( _diffpair_table get_diffpair_table_Derek20211021())
	
	;;;;; [impedance]:(group,...)
	setq( _impedance_to_netclasses_table get_impedance_to_netclasses_table_Derek20211021())
	setq( _netclass_to_impedance_table get_netclass_to_impedance_table_Derek20211021())
)

procedure( remove_duplicated_string_Derek20211021( string_ls)
	prog( ()
		string_ls = maplist( lambda( (xs) unless( member( car( xs) cdr( xs)) car( xs))) string_ls)
		string_ls = remq( nil string_ls)
		
		return( string_ls)
	)
)

procedure( get_netclass_to_impedance_table_Derek20211021()
	;;;;; you have to have _impedance_to_netclasses_table before using this function
	prog( ( data_table group_name_ls)
		unless( dtpr( _impedance_to_netclasses_table->?)
			return( nil)
		)
		
		data_table = makeTable( 'netclass_to_impedance nil)
		
		foreach( impedance _impedance_to_netclasses_table->?
			group_name_ls = _impedance_to_netclasses_table[ impedance]
			
			foreach( group_name group_name_ls
				data_table[ group_name] = impedance
			) 
		)
		
		return( data_table)
	)
)

procedure( get_impedance_to_netclasses_table_Derek20211021()
	prog( ( data_table diffpair_ls net_id parent_group_id group_name impedance)
		data_table = makeTable( 'impedance_to_netclasses nil)
		
		diffpair_ls = get_group_on_board_Derek20211021( "DIFF_PAIR")
		
		foreach( diffpair_id diffpair_ls
			net_id = car( diffpair_id->groupMembers)
			parent_group_id = get_phy_parent_group_Derek20211021( net_id)
			group_name = parent_group_id->name || ""
			impedance = get_impedance_from_netclass_Derek20211021( group_name) || ""
			
			unless( impedance == ""
				data_table[ impedance] = append1( data_table[ impedance] group_name)
			)
		)
		
		foreach( impedance data_table->?
			group_name_ls = data_table[ impedance]
			group_name_ls = remove_duplicated_string_Derek20211021( group_name_ls)
			data_table[ impedance] = group_name_ls
		)
		
		return( data_table)
	)
)

procedure( get_diffpair_table_Derek20211021()
	prog( ( data_table diffpair_ls diffpair_name net_id parent_group_id group_name netname_ls check_is_hs)
		data_table = makeTable( 'diffpair nil)
		
		diffpair_ls = get_group_on_board_Derek20211021( "DIFF_PAIR")
		
		foreach( diffpair_id diffpair_ls
			net_id = car( diffpair_id->groupMembers)
			parent_group_id = get_phy_parent_group_Derek20211021( net_id)
			group_name = parent_group_id->name || ""
			
			netname_ls = get_netnames_from_diffpair_Derek20211021( diffpair_id)
			data_table[ group_name] = append( data_table[ group_name] netname_ls)
			
			when( group_name == ""
				diffpair_name = diffpair_id->name
				check_is_hs = print_sentence_Derek20211021( "WARNING: get_diffpair_table() - Fail to get parent group from diffpair: %s" list( diffpair_name))
			)
		)
		
		when( dtpr( data_table[ ""])
			sentence = "The diffpair displayed in Command will be ignored. Please add these into a netclass, having something like _Z80 if you want to apply these as a HS diffpair"
			printf( "\n\n%s\n\n" sentence)
			axlUIConfirm( sentence)
			
			data_table[ ""] = nil
		)
		
		return( data_table)
	)
)

procedure( print_sentence_Derek20211021( format arg_ls)
	prog( ( sentence)
		sentence = apply( 'lsprintf format arg_ls)
		printf( "%s\n" sentence)
		
		return( t)
	)
)

procedure( get_netnames_from_diffpair_Derek20211021( diffpair_id)
	; net_id = car( axlGetSelSet())
	prog( ( member_ls netname_ls)
		foreach( net_id diffpair_id->groupMembers
			if( net_id->type == "XNET" then
				member_ls = net_id->groupMembers~>name
			else
				member_ls = list( net_id->name)
			)
			
			netname_ls = append( netname_ls member_ls)
		)
		
		return( netname_ls)
	)
)

procedure( get_phy_parent_group_Derek20211021( net_id)
	; net_id = car( axlGetSelSet())
	prog( ( parent_group_ls)
		parent_group_ls = net_id->parentGroups
		
		;;;;; most of the time, name of differential pair wouldn't have meaningful name
		parent_group_ls = setof( x parent_group_ls x->type != "DIFF_PAIR")
		
		;;;;; get group in physical domain only. in Flex rule, most of the impedance and remarkable netclass name should be in the physical grouop
		parent_group_ls = setof( x parent_group_ls x->physical)
		
		;;;;; get physical netclass
		parent_group_id = car( setof( x parent_group_ls x->type == "NETCLASS"))
		
		unless( parent_group_id
			parent_group_id = car( setof( x parent_group_ls x->type == "NETGROUP"))
		)
		
		unless( parent_group_id
			parent_group_id = car( setof( x parent_group_ls x->type == "BUS"))
		)
		
		return( parent_group_id)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_group_on_board_Derek20211021( type)
	prog( ( group_ls)
		group_ls = setof( x axlDBGetDesign()->groups x->type == type)
		
		return( group_ls)
	)
)

procedure( get_phy_netclasses_on_board_Derek20211021()
	prog( ( netclass_id_ls phy_netclass_ls)
		netclass_id_ls = get_group_on_board_Derek20211021( "NETCLASS")
		phy_netclass_ls = setof( x netclass_id_ls x->physical)
		
		return( phy_netclass_ls)
	)
)

procedure( get_impedance_from_netclass_Derek20211021( netclass_name)
	; netclass_name = "CLOCK-DIFF-W5-4.75-4.75D8-9-6_Z85_PH"
	prog( ( impedance)
		unless( netclass_name return( nil))
		
		rexCompile( "_Z\\([0-9]+\\)")
		when( rexExecute( netclass_name)
			impedance = rexSubstitute( "\\1")
		)
		
		return( impedance)
	)
)

procedure( filter_wanted_diffpair_Derek20211021( input_impedances input_netclasses skip_impedances skip_netclasses)
	let( ()
		;;;;; 
		when( dtpr( input_impedances)
			foreach( netclass_name _diffpair_table->?
				impedance = get_impedance_from_netclass_Derek20211021( netclass_name)
				
				unless( memv( impedance input_impedances)
					_diffpair_table[ netclass_name] = nil
				)
			)
		)
		
		when( dtpr( input_netclasses)
			foreach( netclass_name _diffpair_table->?
				unless( member( netclass_name input_netclasses)
					_diffpair_table[ netclass_name] = nil
				)
			)
		)
		
		when( dtpr( skip_impedances)
			foreach( netclass_name _diffpair_table->?
				impedance = get_impedance_from_netclass_Derek20211021( netclass_name)
				
				when( memv( impedance skip_impedances)
					_diffpair_table[ netclass_name] = nil
				)
			)
		)
		
		when( dtpr( skip_netclasses)
			foreach( netclass_name _diffpair_table->?
				when( member( netclass_name skip_netclasses)
					_diffpair_table[ netclass_name] = nil
				)
			)
		)
	)
)

procedure( question_wanted_diffpair_netclasses_Derek20211021()
	prog( ( question enter_string entered_group_name_ls group_name_ls removing_group_name_ls valid)
		question = "Please enter netclasses, divided by comma, to remove netclassed from high speed part"
		enter_string = axlEnterString( ?prompts list( question)) || ""
		
		unless( enter_string == ""
			group_name_ls = _diffpair_table->?
			entered_group_name_ls = axlStringCSVParse( enter_string t)
			valid = forall( group_name entered_group_name_ls exists( gn group_name_ls gn == group_name))
		)
		
		if( valid then
			removing_group_name_ls = entered_group_name_ls
		else
			printf( "ERROR: question_wanted_diffpair_netclasses() - Some of group are not exists. [%L]\n" entered_group_name_ls)
		)
		
		return( removing_group_name_ls)
	)
)

procedure( question_wanted_diffpair_impedance_Derek20211021()
	prog( ( impedance_ls impedances question enter_string entered_impedance_ls valid group_name_ls removing_group_name_ls)
		impedance_ls = _impedance_to_netclasses_table->?
		impedances = buildString( impedance_ls ",")
		
		sprintf( question "Please enter impedances, divided by comma, to remove the corresponded netclass from high speed part [%L]" impedances)
		enter_string = axlEnterString( ?prompts list( question)) || ""
		
		unless( enter_string == ""
			entered_impedance_ls = axlStringCSVParse( enter_string t)
			valid = forall( impedance entered_impedance_ls exists( z impedance_ls z == impedance))
		)
		
		when( valid
			;;;;; convert impedance to all corresponded netclass
			foreach( impedance entered_impedance_ls
				group_name_ls = _impedance_to_netclasses_table[ impedance]
				removing_group_name_ls = append( removing_group_name_ls group_name_ls)
			)
		)
		
		unless( valid || enter_string == ""
			printf( "ERROR: question_wanted_diffpair_impedance() - Some of impedance are not found. [%L]\n" entered_impedance_ls)
		)
		
		
		return( removing_group_name_ls)
	)
)

procedure( question_wanted_diffpair_Derek20211021( question_to_filter question_to_impedances question_to_netclasses)
	let( ( removing_group_name_ls)
		when( question_to_filter
			answer = axlUIMultipleChoice( "Please choose either netclass or impedance to filter out the high speed"
					list( "Enter by Impedance" "Enter by Netclass") "High Speed Filter Selector")
			
			question_to_impedances = answer == 0
			question_to_netclasses = answer == 1
		)
		
		
		cond(
			( question_to_impedances
				removing_group_name_ls = question_wanted_diffpair_impedance_Derek20211021()
			)
			( question_to_netclasses
				removing_group_name_ls = question_wanted_diffpair_netclasses_Derek20211021()
			)
		)
		
		foreach( group_name removing_group_name_ls
			printf( "INFO: question_wanted_diffpair() - Get rid of group[%s] from high speed part\n" group_name)
			_diffpair_table[ group_name] = nil
		)
	)
)

procedure( print_info_Derek20211021()
	let( ( part_ls sentences)
		printf( "INFO: print_info() - Found following netclass/netgroup/bus has diffpair:\n\t%s\t%s\t%s\n" "Impedance" " NetClass" "NetName_n")
		foreach( netclass_name _diffpair_table->?
			impedance = _netclass_to_impedance_table[ netclass_name] || "None"
			netname_n = length( _diffpair_table[ netclass_name])
			
			printf( "\t%s\t%s\t%d\n" impedance netclass_name netname_n)
		)
		
		;;;;;
		printf( "INFO: print_info() - Found following impedance's corresponded groupo has diffpair:\n\t%s\t%s\n" "Impedance" "NetClass_n")
		foreach( impedance _impedance_to_netclasses_table->?
			netclass_n = length( _impedance_to_netclasses_table[ impedance])
			
			printf( "\t%s\t%d\n" impedance netclass_n)
		)
	)
)

procedure( write_file_Derek20211021( filename)
	prog( ( out_port netname_ls)
		out_port = outfile( filename "w")
		unless( outportp( out_port)
			printf( "ERROR: write_file() - Fail to write file, [%L]\n" filename)
			return( nil)
		)
		
		format = "%s,%s\n"
		
		line = apply( 'lsprintf format _header_ls)
		fprintf( out_port "%s" line)
		
		foreach( netclass_name _diffpair_table->?
			netname_ls = _diffpair_table[ netclass_name]
			
			foreach( netname netname_ls
				fprintf( out_port format netclass_name netname)
			)
		)
		
		
		close( out_port)
		
		return( t)
	)

)

procedure( read_file_Derek20211021( filename)
	prog( ( in_port data_table parts index_ls value value_ls)
		in_port = infile( filename)
		unless( inportp( in_port)
			println( "ERROR: read_file() - Fail to read file: %s\n" filename)
			return( nil)
		)
		
		data_table = makeTable( 'diffpair_association_read nil)
		
		;;;;; get the index of headers
		gets( line in_port)
		parts = axlStringCSVParse( line t)
		index_ls = mapcar( lambda( (x) listnindex( parts x)) _header_ls)
		
		;;;;; fill in content to the table
		while( gets( line in_port)
			parts = axlStringCSVParse( line t)
			
			foreach( ( ind header) index_ls _header_ls
				value = nth( ind parts)
				value_ls = data_table[ header]
				data_table[ header] = append1( value_ls value)
			)
		)
		
		
		close( in_port)
		
		
		return( data_table)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; callback

procedure( diffpair_association_dps_Derek20211021( @key
		(out_filename nil))
	prog( ( net_ls diffpair_ls)
		net_ls = diffpair_association_nets_Derek20211021( ?out_filename out_filename)
		diffpair_ls = remove_duplicated_string_Derek20211021( net_ls~>diffpair)
		
		
		return( diffpair_ls)
	)
)

procedure( diffpair_association_nets_Derek20211021( @key
		(out_filename nil))
	prog( ( netname_ls net_ls)
		netname_ls = diffpair_association_netname_Derek20211021( ?out_filename out_filename)
		net_ls = mapcar( lambda( (x) axlDBFindByName( 'net x)) netname_ls)
		
		return( net_ls)
	)
)

procedure( diffpair_association_netname_Derek20211021( @key
		(out_filename nil))
	prog( ( netname_key netname_ls)
		diffpair_association_main_Derek20211021( ?question_to_filter t ?out_filename out_filename)
		netname_key = diffpair_association_key_Derek20211021( ?netname_key t)
		netname_ls = diffpair_association_column_Derek20211021( netname_key ?out_filename out_filename)
		
		return( netname_ls)
	)
)

procedure(  diffpair_association_column_Derek20211021( key @key
		(out_filename nil))
	prog( ( data_table data_ls)
		unless( key return( nil))
		unless( member( key _header_ls)
			printf( "ERROR: diffpair_association_column() - Yet to support this key: %L\n" key)
			return( nil)
		)
		;;;;;
		
		data_table = diffpair_association_read_Derek20211021( ?out_filename out_filename)
		data_ls = data_table[ key]
		
		
		return( data_ls)
	)
)

procedure( diffpair_association_key_Derek20211021( @key
		(netclass_key nil)
		(netname_key nil))
	prog( ( key)
		init1_Derek20211021()
		
		cond(
			( netclass_key
				key = _netclass_header
			)
			( netname_key
				key = _netname_header
			)
			( t
				printf( "WARNING: diffpair_association_key() - Please set an option to use this function\n")
			)
		)
		
		return( key)
	)
)

procedure( diffpair_association_read_Derek20211021( @key
		(out_filename nil))
	prog( ( diffpair_filename data_table) 
		init1_Derek20211021()
		
		diffpair_filename = out_filename || _diffpair_filename
		data_table = read_file_Derek20211021( diffpair_filename)
		
		return( data_table)
	)
)

procedure( diffpair_association_main_Derek20211021( @key
		(input_impedances nil)
		(input_netclasses nil) 
		(skip_impedances nil)
		(skip_netclasses nil)
		(question_to_impedances nil)
		(question_to_netclasses nil)
		(question_to_filter nil)
		(out_filename nil)
		(display_report nil))
	prog( ()
		unless( axlOKToProceed() println( "Please done current function to use this program") return( nil))
		unless( locker_main_Derek20210929() return( nil))
		;;
		
		init1_Derek20211021()
		init2_Derek20211021()
		
		unless( dtpr( _diffpair_table->?)
			println( "INFO: diffpair_association_main() - None of diffpair has netclass/bus/netgroup. No diffpair csv file will be created")
			return( nil)
		)
		
		print_info_Derek20211021()
		
		;;;;;
		filter_wanted_diffpair_Derek20211021( input_impedances input_netclasses skip_impedances skip_netclasses)
		
		;;;;; update diffpair_table by question
		question_wanted_diffpair_Derek20211021( question_to_filter question_to_impedances question_to_netclasses)
		
		;;;;; out_filename
		diffpair_filename = out_filename || _diffpair_filename
		result = write_file_Derek20211021( diffpair_filename)
		unless( result return( nil))
		
		axlUIConfirm( "Diffpair net has been exported. Please check this out")
		
		when( display_report
			axlUIViewFileCreate( diffpair_filename "Diffpair Report" nil)
		)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of callback

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "diffpair_association" 'diffpair_association_main_Derek20211021)
; (diffpair_association_main_Derek20211021)
; (diffpair_association_main_Derek20211021 ?question_to_impedances t)
; (diffpair_association_main_Derek20211021 ?question_to_netclasses t)
; (diffpair_association_main_Derek20211021 ?question_to_filter t)
; skill encrypt( "C:/skill/diffpair_association_v1.il" "C:/skill/diffpair_association_v1.ile")
; (load "diffpair_association_v1.ile")
; (load "diffpair_association_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup