;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction
;
; Developer: Derek Hsu
; Start Date: 04/06/2020 - _Derek04062020
; Introduction:
;	1. check pth/npth/via by its name
;	2. if the name of the objective does not follow the naming rule, at least the finish hole should not be zero
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init_Derek04062020()
	setq( _month_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _today_time "%.4d%.2d%.2d-%.2d%.2d%.2d" _year listnindex( _month_ls _month) _date _hour _minute _second)
	sprintf( _log_filename "check_drill_hole-%s.log" _today_time)
	unless( axlGetVariable( "ads_sdlog") axlSetVariable( "ads_sdlog" "log"))
	
	;;;;; status definition
	setq( _StatusFail 0)
	setq( _StatusIgnore 1)
	setq( _StatusPass 2)
	
	;;;;; create log folder
	if( stringp( axlGetVariable( "ads_sdlog")) then
		sprintf( _log_path "./%s/" axlGetVariable( "ads_sdlog"))
		createDir( _log_path)
	else
		setq( _log_path nil)
	)
	
	;;;;; create log file
	if( stringp( _log_path)
		sprintf( _log_addr "%s%s" _log_path _log_filename)
		setq( _log_addr nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( getThruPadstackList_Derek04062020()
	prog( ( PadstackList ThruPadstackList)
		PadstackList = axlDBGetDesign()->padstacks
		ThruPadstackList = setof( x PadstackList not( equal( car( x->startEnd) cadr( x->startEnd))))
		
		
		return( ThruPadstackList)
	)
)

procedure( getFloatFromNumberWithDash_Derek04062020( NumberWithDash)
	prog( (FloatList Float)
		unless( stringp( NumberWithDash) return( nil))
		;;
		
		
		if( index( NumberWithDash "-") then
			FloatList = parseString( NumberWithDash "-")
			cond(
				( eqv( 2 length( FloatList))
					sprintf( Float "%s.%s" car( FloatList) cadr( FloatList))
					Float = atof( Float)
				)
				( onep( length( FloatList))
					Float = atof( car( FloatList))
				)
				( t
					printf( "ERROR: getFloatFromNumberWithDash() - Fail to get number term: %s\n" NumberWithDash)
				)
			)
		else
			Float = atof( NumberWithDash)
		)
		
		
		return( Float)
	)
)

procedure( getDrillDiameterFromName_Derek04062020( PadstackName)
	;; getDrillDiameterFromName_Derek04062020( "via8_p18_anti32_sm")
	;; PadstackName = "VIA8-9_P18_ANTI32_SM"
	;; PadstackName = "LV10C18_1-3_ANTI30"
	;; lv8c18_7-8_anti36_sm
	;; via15-3_p31_anti45-3_sm
	;; "VIA40_24FP"
	;; "TP18_8BMP30HP"
	;; "C10N156"
	;; "S39P24THAP70"
	;; "S56P41TH"
	prog( (NumberWithDash DrillDiameter)
		unless( stringp( PadstackName) return( nil))
		;;
		
		PadstackName = upperCase( PadstackName)
		
		
		;;;;; "TP18_8BMP30HP"
		rexCompile( "^TP[0-9]+_\\([0-9]+[-0-9]*\\)[TB]")
		when( rexExecute( PadstackName)
			NumberWithDash = rexSubstitute( "\\1")
			DrillDiameter = getFloatFromNumberWithDash_Derek04062020( NumberWithDash)
			return( DrillDiameter)
		)
		
		;;;;; "VIA40_24FP"
		rexCompile( "^VIA[0-9]+_\\([0-9]+[-0-9]*\\)[FHN]P")
		when( rexExecute( PadstackName)
			NumberWithDash = rexSubstitute( "\\1")
			DrillDiameter = getFloatFromNumberWithDash_Derek04062020( NumberWithDash)
			return( DrillDiameter)
		)
		
		;;;;; high speed through via
		rexCompile( "^VIA\\([0-9]+[-0-9]*\\)")
		when( rexExecute( PadstackName)
			NumberWithDash = rexSubstitute( "\\1")
			DrillDiameter = getFloatFromNumberWithDash_Derek04062020( NumberWithDash)
			return( DrillDiameter)
		)
		
		;;;;; high speed laser via
		rexCompile( "^LV\\([0-9]+[-0-9]*\\)")
		when( rexExecute( PadstackName)
			NumberWithDash = rexSubstitute( "\\1")
			DrillDiameter = getFloatFromNumberWithDash_Derek04062020( NumberWithDash)
			return( DrillDiameter)
		)
		
		;;;;; discrete via
		rexCompile( "[0-9]+[DPN]\\([0-9]+[-0-9]*\\)")
		when( rexExecute( PadstackName)
			NumberWithDash = rexSubstitute( "\\1")
			DrillDiameter = getFloatFromNumberWithDash_Derek04062020( NumberWithDash)
			return( DrillDiameter)
		)
		
		
		return( DrillDiameter)
	)
)

procedure( getStatusString_Derek04062020( Status)
	prog( (StatusString)
		cond(
			( eqv( _StatusFail Status) (StatusString = "Fail"))
			( eqv( _StatusPass Status) (StatusString = "Pass"))
			( eqv( _StatusIgnore Status) (StatusString = "Ignore"))
			( t (StatusString = "None"))
		)
		
		
		return( StatusString)
	)
)

procedure( getPadstackDataList_Derek04062020( ThruPadstackList)
	;;; status: 0(fail) 1(pass) 2(ignore)
	prog( ( HoleType Name Plating DrillDiameter Status Message DrillDiameterFromName DataEntry DataEntryList)
		foreach( PadstackId ThruPadstackList
			HoleType = PadstackId->holeType
			Name = PadstackId->name
			if( index( HoleType "circle") then
				Plating = PadstackId->plating
				DrillDiameter = PadstackId->drillDiameter
				if( or( zerop( DrillDiameter) null( DrillDiameter)) then
					Status = _StatusFail
					Message = "Drill Diameter is 0 or the diameter is not specified"
				else
					DrillDiameterFromName = getDrillDiameterFromName_Derek04062020( Name)
					if( floatp( DrillDiameterFromName) then
						Status = if( axlGeoEqual( DrillDiameter DrillDiameterFromName) _StatusPass _StatusFail)
						if( eqv( _StatusPass Status)
							Message = "Actual drill diameter is as same as the value of name"
							sprintf( Message "Actual drill diameter should be [%.2f]" DrillDiameterFromName)
						)
					else
						Status = _StatusIgnore
						Message = "Unrecognizable naming rule"
					)
				)
				
				DataEntry = list( Status Name DrillDiameter Plating Message)
				DataEntryList = append1( DataEntryList DataEntry)
			else
				printf( "This padstack is not in circle: %s\n" Name)
			)
		)
		
		;;;;;
		DataEntryList = sortcar( DataEntryList 'lessp)
		
		
		return( DataEntryList)
	)
)

procedure( writeLog_Derek04062020( PadstackDataList)
	; list( Status Name DrillDiameter Plating Message)
	prog( (OutPort DataEntryFormat Status Name DrillDiameter Plating Message)
		OutPort = outfile( _log_addr "w")
		unless( outportp( OutPort) println( "Fail to write log file") return( nil))
		
		DataEntryFormat = "%s,%s,%s,%s,%s\n"
		fprintf( OutPort DataEntryFormat "Status" "Name" "DrillDiameter" "Plating" "Message")
		foreach( PadstackData PadstackDataList
			Status = getStatusString_Derek04062020( car( PadstackData))
			Name = nth( 1 PadstackData)
			sprintf( DrillDiameter "%.2f" nth( 2 PadstackData))
			Plating = nth( 3 PadstackData)
			Message = nth( 4 PadstackData)
			fprintf( OutPort DataEntryFormat Status Name DrillDiameter Plating Message)
		)
		
		close( OutPort)
		
		printf( "INFO: writeLog() - Log file has been saved to %s\n" _log_addr)
		
		
		return( t)
	)
)

procedure( checkDrillHoleMain_Derek04062020()
	prog( ( ThruPadstackList PadstackDataList)
		unless( axlOKToProceed() println( "ERROR: checkDrillHoleMain() - Please done current commend to use this function") return( nil))
		
		;;;;; initial the variable and log file name
		init_Derek04062020()
		unless( stringp( _log_addr) println( "ERROR: checkDrillHoleMain() - Fail to create log file address") return( nil))
		
		;;;;; get all drill hole from the board file
		ThruPadstackList = getThruPadstackList_Derek04062020()
		unless( dtpr( ThruPadstackList) println( "WARNING: checkDrillHoleMain() - Fail to find through padstack on this board") return( nil))
		
		;;;;; get all the data, including fail and pass
		PadstackDataList = getPadstackDataList_Derek04062020( ThruPadstackList)
		
		;;;;; create log file
		writeLog_Derek04062020( PadstackDataList)
		
		;;;;;
		when( isFile( _log_addr)
			axlUIViewFileCreate( _log_addr "Check Drill Hole Report" nil)
		)
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "check_drill_hole" 'checkDrillHoleMain_Derek04062020)
; (checkDrillHoleMain_Derek04062020)
; skill (encrypt "c:/skill/check_drill_hole_v1.il" "c:/skill/check_drill_hole_v1.ile")
; (load "check_drill_hole_v1.ile")
; (load "check_drill_hole_v1.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup