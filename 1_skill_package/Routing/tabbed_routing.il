/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/04/20                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To load Tabbed Routing with picture                                    #
#                                                                              #
################################################################################
*/

procedure( Main_tabbedrouting()
    let( ( skill_path bmp_path)
        skill_path = strcat( _skill_package_path "2-Route_Tabbed_Routing/")
        bmp_path = strcat( skill_path "graft.bmp")
        local_bmp_path = CopyFileToWorkDir_tabbedrouting( bmp_path)

        axlShell( "graft")

        ;deleteFile( local_bmp_path)
    )
)

procedure( CopyFileToWorkDir_tabbedrouting( file_path)
    prog( ( file_parts file_name local_path)
        unless( isFile( file_path)
            printf( "ERROR: Fail to get following file\n\t%s\n" file_path)
            return( nil)
        )
        
        file_parts = axlDMFileParts( file_path)
        file_name = nth( 2 file_parts)
        local_path = strcat( getWorkingDir() "/" file_name)
        unless( isFile( local_path)
            axlOSFileCopy( file_path local_path t)
        )

        return( local_path)
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup

axlCmdRegister( "tabbed_routing" 'Main_tabbedrouting)
/*
(encrypt "c:/skill/tabbed_routing_v1d1.il" "c:/skill/tabbed_routing_v1d1.ile")
(load "tabbed_routing_v1d1.il")
(load "tabbed_routing_v1d1.ile")
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End of Setup