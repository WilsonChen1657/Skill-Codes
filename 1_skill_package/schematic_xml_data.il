;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Starting Date: 08/19/2020 - _Derek08192020
; introduction: may have multiple function later 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek08192020()
	prog( ()
		setq( _xml_tag_CommonCorePart "CommonCorePart")
		setq( _xml_attr_OccId "OccId")
		setq( _xml_attr_Reference "Reference")
		setq( _schematic_xml_error_content nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( get_xml_addr_Derek08192020( xml_addr question_to_select)
	prog( ( title)
		when( stringp( xml_addr) && isFile( xml_addr) return( xml_addr))
		;;
		
		title = if( stringp( question_to_select) question_to_select "Please select a xml file exported from Capture CIS")
		xml_addr = axlDMFileBrowse( "ALLEGRO_XML" nil ?title title)
		
		return( xml_addr)
	)
)

procedure( get_output_csvname_Derek08192020( output_csvname)
	prog( ( file_part_ls path filename)
		when( stringp( output_csvname) return( output_csvname))
		;;
		
		;; ( file_path filename filename_with_ext ext)
		file_part_ls = axlDMFileParts( _xml_addr)
		filename = cadr( file_part_ls)
		
		file_part_ls = axlDMFileParts( axlGetDrawingName())
		path = car( file_part_ls)
		
		output_csvname = strcat( path "/" filename ".csv")
		
		return( output_csvname)
	)
)

procedure( read_xml_of_schematic_Derek08192020( xml_addr)
	prog( ( in_port CommonCorePart_element_ls)
		in_port = infile( xml_addr)
		unless( inportp( in_port) printf( "ERROR: read_xml() - Fail to read xml: %L\n" xml_addr) return( nil))
		;;
		
		gets( line in_port)
		while( !index( line _xml_tag_CommonCorePart)
			gets( line in_port)
		)
		
		;;;;;
		while( index( line _xml_tag_CommonCorePart)
			CommonCorePart_element = car( axlStringCSVParse( line t))
			CommonCorePart_element_ls = append1( CommonCorePart_element_ls CommonCorePart_element)
			gets( line in_port)
		)
		
		close( in_port)
		
		return( CommonCorePart_element_ls)
	)
)

procedure( get_value_in_element_by_key_Derek08192020( element key)
	; element = "<CommonCorePart OccId=\"40026\" PartNumber=\"\" Reference=\"C109\"/>"
	prog( ( section_ls attribute value)
		section_ls = axlStringCSVParse( element t " ")
		attribute = car( setof( x section_ls index( x key)))
		unless( attribute return( nil))
		
		value = cadr( parseQuotedString( attribute "\""))
		
		return( value)
	)
)

procedure( get_OccId_Reference_Derek08192020( CommonCorePart_element_ls)
	prog( ( OccId Reference OccId_Reference OccId_Reference_ls)
		foreach( CommonCorePart_element CommonCorePart_element_ls
			OccId = get_value_in_element_by_key_Derek08192020( CommonCorePart_element _xml_attr_OccId)
			Reference = get_value_in_element_by_key_Derek08192020( CommonCorePart_element _xml_attr_Reference)
			
			when( and( OccId Reference)
				OccId_Reference = list( OccId Reference)
				OccId_Reference_ls = append1( OccId_Reference_ls OccId_Reference)
			)
		)
		
		OccId_Reference_ls = sortcar( OccId_Reference_ls lambda( (a b) atoi( a) < atoi( b)))
		
		return( OccId_Reference_ls)
	)
)

procedure( write_csv_Derek08192020( data_ls output_csvname)
	prog( ( out_port)
		out_port = outfile( output_csvname "w")
		unless( outportp( out_port) printf( "ERROR: Fail to write csv: %L\n" output_csvname) return( nil))
		;;
		
		foreach( data data_ls
			line = buildString( data ",")
			
			fprintf( out_port "%s\n" line)
		)
		
		close( out_port)
		
		return( t)
	)
)

procedure( read_csv_Derek08192020( csvname @optional (to_sort nil))
	prog( ( in_port line data data_ls)
		in_port = infile( csvname)
		unless( inportp( in_port) printf( "ERROR: read_csv() - Fail to read csv file: %L\n" csvname) return( nil))
		;;
		
		while( gets( line in_port)
			data = axlStringCSVParse( line t)
			data_ls = append1( data_ls data)
		)
		
		close( in_port)
		
		when( to_sort
			data_ls = sortcar( data_ls lambda( (a b) atoi( a) < atoi( b)))
		)
		
		return( data_ls)
	)
)

procedure( merge_id_refdes_Derek08192020( old_data_ls new_data_ls)
	prog( ( old_id new_id old_value new_value data_ls old_extra_data_ls new_extra_data_ls)
		while( and( dtpr( old_data_ls) dtpr( new_data_ls))
			old_id = atoi( caar( old_data_ls))
			new_id = atoi( caar( new_data_ls))
			
			old_value = cadar( old_data_ls)
			new_value = cadar( new_data_ls)
			
			cond(
				( old_id == new_id
					data = list( old_value new_value)
					data_ls = append1( data_ls data)
					
					old_data_ls = cdr( old_data_ls)
					new_data_ls = cdr( new_data_ls)
				)
				( old_id < new_id
					old_extra_data_ls = append1( old_extra_data_ls car( old_data_ls))
					old_data_ls = cdr( old_data_ls)
				)
				( old_id > new_id
					new_extra_data_ls = append1( new_extra_data_ls car( old_data_ls))
					new_data_ls = cdr( new_data_ls)
				)
			)
		)
		
		when( dtpr( old_data_ls) old_extra_data_ls = append( old_extra_data_ls old_data_ls))
		when( dtpr( new_data_ls) new_extra_data_ls = append( new_extra_data_ls new_data_ls))
		
		when( dtpr( old_extra_data_ls)
			refdes_ls = mapcar( 'cadr old_extra_data_ls)
			sprintf( err_content "\tWARNING: merge_id_refdes() - Fail to map [old] refdes: %L" refdes_ls)
			_schematic_xml_error_content = append1( _schematic_xml_error_content err_content)
		)
		
		when( dtpr( new_extra_data_ls)
			refdes_ls = mapcar( 'cadr new_extra_data_ls)
			sprintf( err_content "\tWARNING: merge_id_refdes() - Fail to map [new] refdes: %L\n" refdes_ls)
			_schematic_xml_error_content = append1( _schematic_xml_error_content err_content)
		)
		
		return( data_ls)
	)
)

procedure( merge_2csv_Derek08192020( old_csvname new_csvname output_csvname)
	prog( ( old_data_ls new_data_ls data_ls)
		old_data_ls = read_csv_Derek08192020( old_csvname t)
		new_data_ls = read_csv_Derek08192020( new_csvname t)
		unless( and( old_data_ls new_data_ls) printf( "ERROR: merge_2csv() - Fail to get data from \n\t[%L] and \n\t[&L]\n") return( nil))
		
		_schematic_xml_error_content = nil
		data_ls = merge_id_refdes_Derek08192020( old_data_ls new_data_ls)
		
		write_csv_Derek08192020( data_ls output_csvname)
		
		if( dtpr( _schematic_xml_error_content)
			return( _schematic_xml_error_content)
			return( t)
		)
	)
)

procedure( schematic_xml_data_main_Derek08192020( @key (xml_addr nil) (question_to_select nil) (output_csvname nil))
	prog( ()
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		;;
		
		_xml_addr = get_xml_addr_Derek08192020( xml_addr question_to_select)
		if( _xml_addr
			printf( "INFO: schematic_xml_data_main() - Start to read xml file: %s\n" _xml_addr)
			return( nil)
		)
		
		_output_csvname = get_output_csvname_Derek08192020( output_csvname)
		printf( "INFO: schematic_xml_data_main() - Output CSV filename: %s\n" _output_csvname)
		
		;;;;; ------------------------------------------------
		
		init_Derek08192020()
		
		CommonCorePart_element_ls = read_xml_of_schematic_Derek08192020( _xml_addr)
		OccId_Reference_ls = get_OccId_Reference_Derek08192020( CommonCorePart_element_ls)
		
		write_csv_Derek08192020( OccId_Reference_ls _output_csvname)
		
		axlUIConfirm( sprintf( nil "XML[%s] has been extracted to [%s]. Please check this out" _xml_addr _output_csvname))
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "schematic_xml_data" 'schematic_xml_data_main_Derek08192020)
; schematic_xml_data_main_Derek08192020()
; skill (encrypt "c:/skill/schematic_xml_data_v1.il" "c:/skill/schematic_xml_data_v1.ile")
; (load "schematic_xml_data_v1.ile")
; (load "schematic_xml_data_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup