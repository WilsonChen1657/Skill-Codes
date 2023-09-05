/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/06/28                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       After process gerber's (gbr) & (panel), and create GTD file in artwork #
#       dir then open GTD to update format and run other process in Macro      #
#                                                                              #
################################################################################
*/

;region Global variable

procedure( Init_flexgtd()
    setq( _work_name axlCurrentDesign())
    setq( _work_path getWorkingDir())
    setq( _work_addr axlGetDrawingName())
    setq( _art_dir strcat( axlGetVariable("ads_sdart") "/"))
    setq( _gtd_name strcat( _work_name ".GTD"))
    setq( _lock_name strcat( _work_name ".vlck"))
    setq( _color_index 1)
    defstruct( gtd_struct File LyrName FlashColor DrawColor Type)
)

;endregion

;region Main

procedure( Main_flexgtd()
    prog( ( artwork_ls other_ls data_ls)
        unless( Main_locker()
            return( nil)
        )

		Init_flexgtd()

        artwork_ls = GetArtworkData_flexgtd()
        other_ls = GetOtherData_flexgtd()
        data_ls = append( artwork_ls other_ls)
        WriteGTD_flexgtd( data_ls)

        PrintMsg_utilityprogram( "GTD created complete!\nManual run Macro:\n1. Netlist compare\n2. Export (gbr_pdf)\n3. Close file after save GTD" ?show_info t)
        RunFile_flexgtd( strcat( _art_dir _gtd_name))

        lock_path = strcat( _art_dir _lock_name)
        ; wait GerbTool to open
        while( null( isFile( lock_path))
            axlSleep( 1)
        )

        ; continue process after GTD closed
        while( isFile( lock_path)
            axlSleep( 1)
        )

        return( t)
    )
)

;endregion

;region Feature

procedure( GetArtworkData_flexgtd()
    let( ( film_ls top pcba_top pcba_bot drill after_drill data_ls)
        film_ls = axlGetParam( "artwork")->groupMembers
        ; remove pcba
        pcba_top = car( setof( x film_ls rexMatchp( "^[0-9][0-9]-PCBA-TOP" x)))
        film_ls = remq( pcba_top film_ls)
        pcba_bot = car( setof( x film_ls rexMatchp( "^[0-9][0-9]-PCBA-BOT" x)))
        film_ls = remq( pcba_bot film_ls)
        foreach( film film_ls
            name = strcat( film ".art")
            flash_color = GetColor_flexgtd()
            draw_color = GetColor_flexgtd()
            type = GetFilmType_flexgtd( film)
            data = make_gtd_struct( ?File name ?LyrName name ?FlashColor flash_color ?DrawColor draw_color ?Type type)
            data_ls = append1( data_ls data)
        )

        data_ls
    )
)

procedure( GetOtherData_flexgtd()
    let( ( artwork_path filename_ls file_ls data_ls)
        filename_ls = cddr( getDirFiles( _art_dir))
        drl_ls = setof( x filename_ls and( index( x ".drl") null( index( x "-bd-"))))
        drl_ls = sort( drl_ls 'SrotDrillFile_flexgtd)
        rou_ls = setof( x filename_ls index( x ".rou"))

        file_ls = append( drl_ls rou_ls)
        data_ls = nil
        foreach( file file_ls
            file_name = file
            name = file
            flash_color = GetColor_flexgtd()
            draw_color = GetColor_flexgtd()
            type = "NC"
            data = make_gtd_struct( ?File file_name ?LyrName name ?FlashColor flash_color ?DrawColor draw_color ?Type type)
            data_ls = append1( data_ls data)
        )

        data_ls
    )
)

procedure( SrotDrillFile_flexgtd( file_a file_b)
    prog( ()
        if( equal( strlen( file_a) strlen( file_b)) then
            return( alphalessp( file_a file_b))
        else
            return( strlen( file_a) < strlen( file_b))
        )
    )
)

procedure( GetColor_flexgtd()
    prog( ( color)
        sprintf( color "default%d" _color_index++)
        when( equal( _color_index 31)
            _color_index = 1
        )

        return( color)
    )
)

; "01-SILK-TOP" "02-PASTE-TOP" "03-MASK-TOP" "04-TOP" "57-PCBA-BOT"
procedure( GetFilmType_flexgtd( film_name)
    prog( ( artwork_param layer type film_type)
        artwork_param = axlGetParam( strcat( "artwork:" film_name))

        layer = car( setof( x artwork_param->groupMembers index( x "ETCH")))
        when( layer
            type = axlDBGetLayerType( layer)
        )

        cond(
            ( or( index( film_name "-TOP") index( film_name "-BOT") index( film_name "-BOTTOM"))
                name_ls = cdr( parseString( film_name "-"))
                when( member( "PCBA" name_ls)
                    name_ls = list( "Silk" cadr( name_ls))
                )

                film_type = buildString( name_ls  " ")
            )
            ( equal( type "CONDUCTOR")
                film_type = "Inner"
            )
            ( equal( type "PLANE")
                film_type = "Plane Pos"
            )
            ( t
                film_type = "other"
            )
        )

        return( film_type)
    )
)

procedure( WriteGTD_flexgtd( data_ls)
    let( ( path out_port layer_index)
        path = strcat( _art_dir _gtd_name)
        out_port = outfile( path "w")

        fprintf( out_port "{Program\tGerbTool for Layout\n")
        fprintf( out_port "\t{Version\t8.0}\n")
        fprintf( out_port "\t{Created  Jun 29 11:41:28 2023}\n")
        fprintf( out_port "}\n")
        fprintf( out_port "{Environment\n")
        fprintf( out_port "\t{FilesPath  .}\n")
        fprintf( out_port "}\n")
        fprintf( out_port "{Layers\n")

        layer_index = 1
        foreach( data data_ls
            WriteGerberData_flexgtd( out_port layer_index++ data)
        )
        
        fprintf( out_port "}\n")

        WriteFormatGerber_flexgtd( out_port)
        WriteFormatDrill_flexgtd( out_port)

        close( out_port)
    )
)

procedure( WriteGerberData_flexgtd( out_port layer_index data)
    let( ()
        fprintf( out_port " {Layer  %d\n" layer_index)
        fprintf( out_port "   {File        %s}\n" data->File)
        fprintf( out_port "   {LyrName     %s}\n" data->LyrName)
        fprintf( out_port "   {ApLis     }\n")
        fprintf( out_port "   {Visibility\tOn}\n")
        fprintf( out_port "   {FlashColor\t%s}\n" data->FlashColor)
        fprintf( out_port "   {DrawColor\t%s}\n" data->DrawColor)
        fprintf( out_port "   {Type\t\t%s}\n" data->Type)
        fprintf( out_port " }\n")
    )
)

procedure( WriteFormatGerber_flexgtd( out_port)
    let( ()
        fprintf( out_port "{Format Gerber\n")
        fprintf( out_port "\t{Dialect           RS274X}\n")
        fprintf( out_port "\t{m.n               5.5}\n")
        fprintf( out_port "\t{Mode              Absolute}\n")
        fprintf( out_port "\t{ZeroSuppression   Leading}\n")
        fprintf( out_port "\t{Terminator        0x2a, 0xD, 0xA}\n")
        fprintf( out_port "\t{Metric            No}\n")
        fprintf( out_port "\t{Modal             No}\n")
        fprintf( out_port "\t{UserData          Yes}\n")
        fprintf( out_port "\t{Nets              No}\n")
        fprintf( out_port "\t{Gcmds             Yes}\n")
        fprintf( out_port "\t{CharSet           ASCII}\n")
        fprintf( out_port "\t{Arcs360           No}\n")
        fprintf( out_port "\t{ArcsModal         Yes}\n")
        fprintf( out_port "\t{HonorCrLf         No}\n")
        fprintf( out_port "\t{Comments          Yes}\n")
        fprintf( out_port "\t{Flags             0}\n")
        fprintf( out_port "}\n")
    )
)

procedure( WriteFormatDrill_flexgtd( out_port)
    let( ()
        ;"-np.drl"
        fprintf( out_port "{Format Drill\n")
        fprintf( out_port "\t{Dialect           Excellon}\n")
        fprintf( out_port "\t{m.n               5.5}\n")
        fprintf( out_port "\t{Mode              Absolute}\n")
        fprintf( out_port "\t{ZeroSuppression   Leading}\n")
        fprintf( out_port "\t{Metric            No}\n")
        fprintf( out_port "\t{Modal             No}\n")
        fprintf( out_port "\t{UserData          No}\n")
        fprintf( out_port "\t{Nets              No}\n")
        fprintf( out_port "\t{FlattenCustoms    No}\n")
        fprintf( out_port "\t{GCmds             No}\n")
        fprintf( out_port "\t{CharSet           ASCII}\n")
        fprintf( out_port "\t{Arcs360           No}\n")
        fprintf( out_port "\t{ArcsModal         Yes}\n")
        fprintf( out_port "\t{HonorCRLF         No}\n")
        fprintf( out_port "\t{Comments          No}\n")
        fprintf( out_port "\t{DecRnM02          No}\n")
        fprintf( out_port "\t{Polarity          INDIVIDUALITEMS}\n")
        fprintf( out_port "}\n")
    )
)

procedure( OpenDesignFile_flexgtd( file_path)
    let( ( parts cmd)
        parts = axlDMFileParts( file_path)
        ; open dra file
        sprintf( cmd "open;
                     fillin \"%s\";
                     cd \"%s\";" file_path nth( 0 parts))
        axlShell( cmd)
    )
)

procedure( RunFile_flexgtd( file_path)
    let( ()
        shell( strcat( "start " file_path))
    )
)

;endregion

;region Setup
axlCmdRegister( "flex_gtd" 'Main_flexgtd)
/*
(encrypt "c:/skill/flex_gtd_v1d1.il" "c:/skill/flex_gtd_v1d1.ile")
(load "flex_gtd_v1d1.il")
(load "flex_gtd_v1d1.ile")
*/
;endregion