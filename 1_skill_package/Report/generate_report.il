/*
################################################################################
#                                                                              #
#  Developer: Wilson Chen                                                      #
#  Start Date: 2023/07/24                                                      #
#  Reference: locker, utility_program                                          #
#  Purpose:                                                                    #
#       To generate report with report name                                    #
#  Usage:                                                                      #
#       Report command can find in %CDSROOT%\share\pcb\batchhelp\report.txt    #
#                                                                              #
################################################################################
*/

;region Global variable

procedure( Init_generatereport()
	setq( _all_report_ls list( "Backdrill Report" "Component Pin Report" "Net List Report" "Net Single Pin and No Pin" "Testprep Report"))
	setq( _log_dir strcat( getWorkingDir() "/" axlGetVariable( "ads_sdlog") "/"))
)

;endregion

;region Main

procedure( Main_generatereport( report_name)
	prog( ()
		unless( Main_locker()
			return( nil)
		)

		Init_generatereport()
		if( and( stringp( report_name) !blankstrp( report_name)) then
			if( equal( report_name "all reports") then
				foreach( report _all_report_ls
					GenerateReport_generatereport( report)
				)

				; sum net between board
				Main_sumnetbetweenboard()
				; refdes assembly
				Main_resizerefdesassembly( t)
				; net device
				Main_netdevicesreport()
			else
				GenerateReport_generatereport( report_name)
			)
			
			return( t)
		else
			printf( "[report_name]:%L should be a string!" cmd_format)
			return( nil)
		)
	)
)

;endregion

;region Main

procedure( GenerateReport_generatereport( report_name)
	let( ( file_name msg)
		case( report_name
			( "Backdrill Report"
				file_name = "backdrill.html"
			)
			( "Component Pin Report"
				file_name = "cpn_rep.rpt"
			)
			( "Net List Report"
				file_name = "net_rep.rpt"
			)
			( "Net Single Pin and No Pin"
				file_name = "Net_Single_Pin_and_No_Pin.rpt"
			)
			( "Summary Drawing Report"
				file_name = list( "sum_rep.rpt" "dangling_lines.rpt")
			)
			( "Net Loop Report"
				file_name = "netLoop_rep.rpt"
			)
			( "Symbol Library Path Report"
				file_name = "slp_rep.rpt"
			)
			( "Padstack Usage Report"
				file_name = "psu_rep.rpt"
			)
			( "Testprep Report"
				file_name = "test_prep.rpt"
			)
			( t
				; no report found
			)
		)
		
		when( stringp( file_name)
			file_name = list( file_name)
		)

		axlReportGenerate( report_name t car( file_name))
		if( forall( x file_name and( x isFile( x))) then
			foreach( file file_name
				axlOSFileCopy( file strcat( _log_dir file) nil)
				when( !equal( file car( file_name))
					axlUIViewFileCreate( file file nil)
				)
			)
		else
			sprintf( msg "Fail to create %L" file_name)
			PrintMsg_utilityprogram( msg ?level 'warn)
		)
	)
)

;endregion

;region Setup
axlCmdRegister( "generate_report" 'Main_generatereport)
/*
(encrypt "c:/skill/generate_report_v1d1.il" "c:/skill/generate_report_v1d1.ile")
(load "generate_report_v1d1.il")
(load "generate_report_v1d1.ile")
*/
;endregion