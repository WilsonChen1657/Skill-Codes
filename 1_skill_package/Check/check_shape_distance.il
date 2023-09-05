/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2022/04/15                                                      #
#  Reference:                                                                  #
#  Purpose:                                                                    #
#       Check distance between Shapes                                          #
#  Net list file:                                                              #
#       12V net name.txt                                                       #
#                                                                              #
################################################################################
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Variable

procedure( Init_checkshapedistance()
	unless( axlGetVariable( "ads_sdlog")
		axlSetVariable( "ads_sdlog" "log")
	)

	setq( _log_dir (axlGetVariable( "ads_sdlog") || ""))
	unless( or( zerop( strlen( _log_dir)) isDir( _log_dir))
		createDir( _log_dir)
	)
	
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _log_shape_filename "check_shape_distance_to_shape-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	sprintf( _log_via_filename "check_shape_distance_to_via-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	sprintf( _log_pin_filename "check_shape_distance_to_pin-%.4d%s%.2d-%.2d%.2d%.2d.log" _year _month _date _hour _minute _second)
	sprintf( _check_shape_distance_to_shape_logname "%s/%s" _log_dir _log_shape_filename)
	sprintf( _check_shape_distance_to_via_logname "%s/%s" _log_dir _log_via_filename)
	sprintf( _check_shape_distance_to_pin_logname "%s/%s" _log_dir _log_pin_filename)
	
	setq( _def_shape_distance 20.00)
	setq( _def_via_distance 10.00)
	setq( _def_pin_distance 10.00)
	setq( _warning_ls nil)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Global Variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main
procedure( Main_checkshapedistance( check_item)
	prog( (browser_title browser_filter net_name_list_txt net_ls log_name out_port distance subclass_ls title)
		check_item = lowerCase( check_item)
		unless( or( check_item == "shape" check_item == "via" check_item == "pin")
			println( "ERROR: Main() - Please input shape, via, or pin to start the check!")
			return( nil)
		)
		
		Init_checkshapedistance()
		
		;;; Get net name list
		browser_title = "Please select a net name list"
		browser_filter = "All txt files(*.txt)"
		net_name_list_txt = axlDMFileBrowse( nil nil ?title browser_title ?optFilters browser_filter)
		
		net_ls = GetNetNameList_checkshapedistance( net_name_list_txt check_item)
		unless( dtpr( net_ls)
			printf( "ERROR: Main() - %s is empty" net_name_list_txt)
			return( nil)
		)
		
		;;; Creat Log
		case( check_item
			( "shape"
				log_name = _check_shape_distance_to_shape_logname
			)
			( "via"
				log_name = _check_shape_distance_to_via_logname
			)
			( "pin"
				log_name = _check_shape_distance_to_pin_logname
			)
		)
		
		out_port = outfile( log_name "w")
		unless( outportp( out_port)
			println( "ERROR: Main() - Fail to write log")
			return( nil)
		)
		
		fprintf( out_port "Board file name: %s\n" axlCurrentDesign())
		;fprintf( out_port "Schematic name: %s\n" _schematic_name)
		fprintf( out_port "Date-time: %L\n" getCurrentTime())
		fprintf( out_port "\n\n")
		
		fprintf( out_port "Introduction: To check distance between shape and %s\n" check_item)
		case( check_item
			( "shape"
				distance = _def_shape_distance
			)
			( "via"
				distance = _def_via_distance
			)
			( "pin"
				distance = _def_pin_distance
			)
		)
		
		fprintf( out_port "\tCheck distance smaller than %.2f%s\n" distance car( axlDBGetDesignUnits()))
		fprintf( out_port "\n\n")
		fprintf( out_port "=====================================================================================================\n")
		fprintf( out_port "\n\n")
		
		;;; Get Subclass list
		subclass_ls = axlSubclasses("ETCH")
		foreach( subclass subclass_ls
			has_data = nil
			; layer
			fprintf( out_port "[%s]\n" subclass)
			; header
			fprintf( out_port "\t%-25s,%-25s,%-15s,%s\n" "shape(net name)" sprintf( nil "%s(net name)" check_item) "distance" "Location")
			foreach( net_name net_ls
				case( check_item
					( "shape"
						result = CheckShapeToShape_checkshapedistance( out_port subclass net_name)
					)
					( "via"
						result = CheckShapeToVia_checkshapedistance( out_port subclass net_name)
					)
					( "pin"
						result = CheckShapeToPin_checkshapedistance( out_port subclass net_name)
					)
				)
				
				if( result then
					has_data = t
				)
			)
			
			unless( has_data
				fprintf( out_port "\tNo warning\n\n")
			)
		)

		close( out_port)
		sprintf( title "Check distance between shape to %s Report" check_item)
		axlUIViewFileCreate( log_name title nil)
		return( t)
	)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Function

procedure( GetNetNameList_checkshapedistance( net_name_list_txt check_item)
	prog( (data data_count net_ls)
		data = infile( net_name_list_txt)
		data_count = 0
		while( gets( str data)
			unless( blankstrp(str)
				; if need custom setting for min distance, set content in TXT first parameter start with #.
				; (e.g., #15, #10)
				if( data_count == 0 && rexMatchp( "^#[a-z]+#[0-9]+" str) then
					setting = parseString( str "#")
					distance = atof( cadr( setting))
					case( car( setting)
						( "shape"
							_def_shape_distance = distance
						)
						( "via"
							_def_via_distance = distance
						)
						( "pin"
							_def_pin_distance = distance
						)
					)
				else
					rexCompile("\n$")
					str = rexReplace(str "" 1)
					net_ls = append1( net_ls str)
				)
				
				data_count++
			)
		)
		
		return( net_ls)
	)
)

procedure( CheckShapeToShape_checkshapedistance( out_port subclass target_net @optional (min_distance _def_shape_distance))
	prog( (shape_ls target_shape_ls compare_shape_ls warning_count)
		shape_ls = GetShapes_checkshapedistance( subclass target_net)
		unless( shape_ls
			return( nil)
		)
		
		sprintf( etch_layer "ETCH/%s" subclass)
		compare_shape_ls = setof( x axlDBGetShapes( etch_layer) ( car( x->segments)->net->name != target_net))
		unless( dtpr(compare_shape_ls)
			return( nil)
		)
		
		result = CheckDistance_checkshapedistance( subclass shape_ls compare_shape_ls)
		return( result)
	)
)

procedure( CheckShapeToVia_checkshapedistance( out_port subclass target_net @optional (min_distance _def_via_distance))
	prog( (shape_ls via_ls warning_count)
		shape_ls = GetShapes_checkshapedistance( subclass target_net)
		unless( shape_ls
			return( nil)
		)
		
		sprintf( via_layer "VIA Class/%s" subclass)
		via_ls = GetViaList_utilityprogram( via_layer)
		via_ls = setof( x via_ls ( x->net->name != target_net))
		unless( dtpr(via_ls)
			return( nil)
		)
		
		; TODO 排除覆蓋的
		;foreach( via via_ls
			
		;)
		
		result = CheckDistance_checkshapedistance( subclass shape_ls via_ls)
		return( result)
	)
)

procedure( CheckShapeToPin_checkshapedistance( out_port subclass target_net @optional (min_distance _def_pin_distance))
	prog( (shape_ls pin_ls warning_count)
		shape_ls = GetShapes_checkshapedistance( subclass target_net)
		unless( shape_ls
			return( nil)
		)
		
		sprintf( pin_layer "PIN/%s" subclass)
		pin_ls = GetPinList_utilityprogram( pin_layer)
		pin_ls = setof( x pin_ls ( x->net->name != target_net))
		unless( dtpr(pin_ls)
			return( nil)
		)
		
		result = CheckDistance_checkshapedistance( subclass shape_ls pin_ls)
		return( result)
	)
)

procedure( GetShapes_checkshapedistance( subclass target_net)
	prog( (etch_layer shape_ls result_shape_ls)
		sprintf( etch_layer "ETCH/%s" subclass)
		shape_ls = axlDBGetShapes( etch_layer)
		unless( dtpr(shape_ls)
			return( nil)
		)
		
		result_shape_ls = setof( x shape_ls ( car( x->segments)->net->name == target_net))
		unless( dtpr(result_shape_ls)
			return( nil)
		)
		
		return( result_shape_ls)
	)
)

procedure( CheckDistance_checkshapedistance( subclass shape_ls compare_ls)
	prog( ( warning_count)
		if( car( compare_ls)->objType == "shape" then
			subclass = nil
		)
	
		warning_count = 0
		_warning_ls = nil
		foreach( shape shape_ls
			foreach( item compare_ls
				air_gap = axlAirGap( shape item subclass)
				distance = caddr( air_gap)
				if( distance < min_distance then
					WriteLog_checkshapedistance( out_port shape item air_gap)
					warning_count++
				)
			)
		)
		
		if( warning_count > 0 then
			return( t)
		)
		
		return( nil)
	)
)

procedure( WriteLog_checkshapedistance( out_port shape compare_item air_gap)
	; shape(net name)
	fprintf( out_port "\t%-25s," car( shape->segments)->net->name)
	; shape/via/pin(net name)
	if( compare_item->objType == "shape" then
		fprintf( out_port "%-25s," car( compare_item->segments)->net->name)
	else
		fprintf( out_port "%-25s," compare_item->net->name)
	)
	; distance
	fprintf( out_port "%-15f," caddr( air_gap))
	; location
	fprintf( out_port "%L\n" car( air_gap))
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Function

(axlCmdRegister "check_shape2" 'Main_checkshapedistance)
/*
skill encrypt( "C:/skill/check_shape_distance_v1d1.il" "C:/skill/check_shape_distance_v1d1.ile")
(load "check_shape_distance_v1d1.il")
(load "check_shape_distance_v1d1.ile")
*/