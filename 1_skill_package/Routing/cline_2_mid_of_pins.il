; (load "cline2MidOfPins.il")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( finish()
	axlFinishEnterFun()
	_toRun = 2
)

procedure( cancel()
	axlCancelEnterFun()
	_toRun = 1
)

procedure( stop()
	axlCancelEnterFun()
	_toRun = 0
)

_popup = axlUIPopupDefine( nil list( list( "Done" 'finish) list( "Cancel" 'cancel) list( "Stop" 'stop)))
_tolerance = 0.1
_fixCline = t

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( Select2Cline2Pin()
	let( ( optList objList)
		optList = list( "NOALL" "CLINESEGS" "PINS" "VIAS")
		axlSetFindFilter( ?enabled optList ?onButtons optList)
		
		axlUIPopupSet( _popup)
		while( axlSelect()
			axlUIPopupSet( _popup)
			objList = axlGetSelSet()
			_pin2 = setof( x objList member( x->objType list( "pin" "via")))
			_cline2 = setof( x objList equal( "line" x->objType))
			
			printf( "Copper: %L\n" _pin2)
			printf( "Cline: %L\n" _cline2)
			if( and( eqv( 2 length( _cline2)) eqv( 2 length( _pin2))) then
				println( "Info: You selected 2 clines and 2 pin/vias")
			else
				printf( "Warning: Select2Cline2Pin() - Please select 2 clines(curr: %d) and 2 pin/vias( curr: %d)" length( _cline2) length( _pin2))
				_toRun = 1
			)
		)
		
		optList = list( "NOALL")
		axlSetFindFilter( ?enabled optList ?onButtons optList)
		axlClearSelSet()
		axlUIPopupSet( nil)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( cline2MidOfPinsMain()
	prog( ()
		unless( axlOKToProceed() println( "Please finish current command to use this function") return( nil))
		
		_toRun = 2
		while( not( zerop( _toRun))
			println( "Please select 2 clines and 2 pin/vias to move to the middle of array of pins")
			_cline2 = _pin2 = nil
			Select2Cline2Pin()

			if( and( eqv( 2 _toRun) dtpr( _cline2) dtpr( _pin2))
				MoveClines()
				printf( "Warning: cline2MidOfPinsMain() - Please select 2 clines(curr: %d) and 2 pin/vias( curr: %d)" length( _cline2) length( _pin2))
			)
			
			
			printf( "\n")
		)
		
		println( "The process is done")
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

defun( getSlopeByLine ( lineId)
	prog( ( xyStart xyEnd division fraction slope)
		xyStart = car( lineId->startEnd)
		xyEnd = cadr( lineId->startEnd)
		
		division = cadr( xyEnd) - cadr( xyStart)
		fraction = car( xyEnd) - car( xyStart)
		
		if( zerop( fraction)
			slope = nil
			slope = division / fraction
		)
		
		
		return( slope)
	)
)

procedure( CompesateClineAngle( clineId slopeType)
	prog( ( compesateAngle clineCenterXy)
		compesateAngle = GetCompesateAngle( clineId slopeType)
		if( numberp( compesateAngle) then
			printf( "compesateAngle: %L\n" compesateAngle)
			unless( zerop( compesateAngle)
				clineCenterXy = axlMidPointLine( clineId->startEnd)
				axlTransformObject( clineId ?angle compesateAngle ?origin clineCenterXy)
			)
		else
			printf( "Fail to get compesate angle from cline[%L]\n" clineId->startEnd)
		)
		
		
		return( t)
	)
)

procedure( DeleteAndCreateCline( clineId moveDeltaXy)
	prog( ( startEnd layer netName width prop path newClineId)
		when( and( zerop( car( moveDeltaXy)) zerop( cadr( moveDeltaXy))) return( nil))
		
		axlTransformObject( clineId ?move moveDeltaXy)
		
	;	startEnd = clineId->startEnd
	;	layer = clineId->layer
	;	netName = clineId->net->name
	;	width = clineId->width
	;	prop = clineId->prop->??
		
	;	axlDeleteObject( clineId)
		
	;	startEnd = mapcar( lambda( (xy) axlMXYAdd( xy moveDeltaXy)) startEnd)
		
	;	path = axlPathStart( startEnd width)
	;	newClineId = caar( axlDBCreatePath( path layer netName nil prop))
		
		
		return( newClineId)
	)
)

procedure( WriteScr2FixClineSeg( xy)
	prog( ( fileName outPort x y lineList)
		printf( "Start to fix cline seg on point[%L]\n" xy)
		fileName = "FixClineSeg.scr"
		
		x = car( xy)
		y = cadr( xy)
		
		lineList = list( "version 17.2"
					"setwindow pcb"
					"trapsize 28"
					"generaledit"
					"fix"
					"setwindow form.find"
					"FORM find all_off"
					"FORM find cline_segs YES"
					"setwindow pcb"
					sprintf( nil "pick grid %f %f" x y)
					sprintf( nil "prepopup %f %f" (x + 1.0) (y + 6.0))
					"done"
					"generaledit")
		
		;;;;;
		when( isFile( fileName) deleteFile( fileName))
		outPort = outfile( fileName "w")
		foreach( line lineList fprintf( outPort "%s\n" line))
		close( outPort)
		
		;;;;;
		axlUIConfirm( sprintf( nil "Start to fix cline seg on point[%L]\n" xy))
		sprintf( cmd "replay %s/%s" getWorkingDir() fileName)
		axlShellPost( cmd)
		axlUIConfirm( "Done" xy)
		
		
		return( t)
	)
)

procedure( MoveClines()
	prog( ( clineId1 clineId2 cline1CenterXy cline2CenterXy slopeType clineGap compesateAngle moveDeltaXy_2)
		clineId1 = car( _cline2)
		clineId2 = cadr( _cline2)
		
		;;;;;
		slopeType = GetSlopeType( clineId1)
		printf( "The slope type of these clines is [%L]\n" slopeType)
		
		;;;;; the gap of the cline has to be gotten by move the cline
		clineGap = getClineGap( clineId1 clineId2)
		unless( clineGap println( "Fail to get gap between clines") return( nil))
		printf( "The gap of current clines: %f\n" (clineGap - clineId1->width))
		
		;;;;; rotate 2 cline crossing with 2 pins
		CompesateClineAngle( clineId1 slopeType)
		CompesateClineAngle( clineId2 slopeType)
		
		;;;;; move 2 clines to the middle
	;	println( clineId1->??)
	;	println( clineId2->??)
		moveDeltaXy_2 = GetMoveDeltaXy2( slopeType clineGap clineId1 clineId2)
		when( dtpr( moveDeltaXy_2)
			DeleteAndCreateCline( clineId1 car( moveDeltaXy_2))
			DeleteAndCreateCline( clineId2 cadr( moveDeltaXy_2))
		)
		
		;when( _fixCline
			;cline1CenterXy = axlMidPointLine( clineId1->startEnd)
			;cline2CenterXy = axlMidPointLine( clineId2->startEnd)
			;;;; add property
			;axlDBAddProp( car( axlChangeLine2Cline( clineId1)) list( 'FIXED t))
			;axlDBAddProp( car( axlChangeLine2Cline( clineId2)) list( 'FIXED t))
			;WriteScr2FixClineSeg( cline1CenterXy)
			;WriteScr2FixClineSeg( cline2CenterXy)
			
			;axlUIConfirm( "These 2 clines have been fixed")
		;)
		
		
		t
	)
)

defun( getXyByLineCline ( xy2 clineId)
	prog( ( a_b_distance)
		a_b_distance = axl_ol_ol2( xy2 clineId->startEnd)
		
		if( zerop( caddr( a_b_distance))
			return( car( a_b_distance))
			return( nil)
		)
	)
)

procedure( printMove( title a aDelta b bDelta)
	let( ( aFinal bFinal)
		
		if( dtpr( a) then
			aFinal = axlMXYAdd( a aDelta)
			bFinal = axlMXYAdd( b bDelta)
		else
			aFinal = a + aDelta
			bFinal = b + bDelta
		)
		
		printf( "Move cline1: %s[%L] delta[%L] to[%L]\n" title a aDelta aFinal)
		printf( "Move cline2: %s[%L] delta[%L] to[%L]\n" title b bDelta bFinal)
	)
)

defun( GetMoveDeltaXy2 ( slopeType clineGap clineId1 clineId2)
	prog( ( pinId1 pinId2 pin2Xy cline1XPin2Xy cline2XPin2Xy cline1ClosePin1 clineGapD2 pin2CenterXy
			pin2CenterX pin2CenterY clineX1 clineY1 clineX2 clineY2 deltaX1 deltaX2 deltaY1 deltaY2 clineGapD2DSqrt2 moveDeltaXy_2 )
		pinId1 = car( _pin2)
		pinId2 = cadr( _pin2)
		pin2Xy = _pin2~>xy
		
		cline1XPin2Xy = getXyByLineCline( pin2Xy clineId1)
		cline2XPin2Xy = getXyByLineCline( pin2Xy clineId2)
		unless( and( cline1XPin2Xy cline2XPin2Xy)
			println( "Fail to get cross points between clines and pins")
			return( nil)
		)
		printf( "\tIntersection [%L] on cline1[[%L]\n\tIntersection [%L] on cline2[[%L]\n" cline1XPin2Xy clineId1~>startEnd cline2XPin2Xy clineId2~>startEnd)
		
		cline1ClosePin1 = ( axlDistance( cline1XPin2Xy pinId1->xy) < axlDistance( cline1XPin2Xy pinId2->xy))
		printf( "Is cline1 close to pin1: %L\n" cline1ClosePin1)
		if( cline1ClosePin1
			printf( "\tCline[%L] closes to pin[%L]\n\tCline[%L] closes to pin[%L]\n" clineId1~>startEnd pinId1->xy clineId2~>startEnd pinId2->xy)
			printf( "\tCline[%L] closes to pin[%L]\n\tCline[%L] closes to pin[%L]\n" clineId1~>startEnd pinId2->xy clineId2~>startEnd pinId1->xy)
		)
		
		clineGapD2 = clineGap / 2.0
		clineGapD2DSqrt2 = clineGapD2 / axlSQRT2
		
		pin2CenterXy = axlMidPointLine( pin2Xy)
		pin2CenterX = car( pin2CenterXy)
		pin2CenterY = cadr( pin2CenterXy)
		
		clineX1 = car( cline1XPin2Xy)
		clineY1 = cadr( cline1XPin2Xy)
		
		clineX2 = car( cline2XPin2Xy)
		clineY2 = cadr( cline2XPin2Xy)
		
		caseq( slopeType
			( 'vertical
			;	if( cline1ClosePin1 then
				deltaX1 = pin2CenterX - clineX1 - clineGapD2
				deltaX2 = pin2CenterX - clineX2 + clineGapD2
			;	else
			;		deltaX2 = pin2CenterX - clineX2 - clineGapD2
			;		deltaX1 = pin2CenterX - clineX1 + clineGapD2
			;	)
				moveDeltaXy_2 = list( list( deltaX1 0.0) list( deltaX2 0.0))
				
				printMove( 'X clineX1 deltaX1 clineX2 deltaX2)
			)
			( 'horizontal
			;	if( cline1ClosePin1 then
				deltaY1 = pin2CenterY - clineY1 + clineGapD2
				deltaY2 = pin2CenterY - clineY2 - clineGapD2
			;	else
			;		deltaY2 = pin2CenterY - clineY2 + clineGapD2
			;		deltaY1 = pin2CenterY - clineY1 - clineGapD2
			;	)
				moveDeltaXy_2 = list( list( 0.0 deltaY1) list( 0.0 deltaY2))
				
				printMove( 'Y clineY1 deltaY1 clineY2 deltaY2)
			)
			( 'toRightUp
				if( cline1ClosePin1 then
					deltaX1 = pin2CenterX - clineX1 - clineGapD2DSqrt2
					deltaY1 = pin2CenterY - clineY1 + clineGapD2DSqrt2
					deltaX2 = pin2CenterX - clineX2 + clineGapD2DSqrt2
					deltaY2 = pin2CenterY - clineY2 - clineGapD2DSqrt2
				else
					deltaX1 = pin2CenterX - clineX1 + clineGapD2DSqrt2
					deltaY1 = pin2CenterY - clineY1 - clineGapD2DSqrt2
					deltaX2 = pin2CenterX - clineX2 - clineGapD2DSqrt2
					deltaY2 = pin2CenterY - clineY2 + clineGapD2DSqrt2
				)
				when( axlGeoEqual( deltaX1 deltaY1) (deltaX1 = deltaY1 = 0.0))
				when( axlGeoEqual( deltaX2 deltaY2) (deltaX2 = deltaY2 = 0.0))
				moveDeltaXy_2 = list( list( deltaX1 deltaY1) list( deltaX2 deltaY2))
				
				printMove( 'XY list( clineX1 clineY1) list( deltaX1 deltaY1) list( clineX2 clineY2) list( deltaX2 deltaY2))
			)
			( 'toLeftUp
				if( cline1ClosePin1 then
					deltaX1 = pin2CenterX - clineX1 - clineGapD2DSqrt2
					deltaY1 = pin2CenterY - clineY1 - clineGapD2DSqrt2
					deltaX2 = pin2CenterX - clineX2 + clineGapD2DSqrt2
					deltaY2 = pin2CenterY - clineY2 + clineGapD2DSqrt2
				else
					deltaX1 = pin2CenterX - clineX1 + clineGapD2DSqrt2
					deltaY1 = pin2CenterY - clineY1 + clineGapD2DSqrt2
					deltaX2 = pin2CenterX - clineX2 - clineGapD2DSqrt2
					deltaY2 = pin2CenterY - clineY2 - clineGapD2DSqrt2
				)
				when( axlGeoEqual( deltaX1 deltaY1) (deltaX1 = deltaY1 = 0.0))
				when( axlGeoEqual( deltaX2 deltaY2) (deltaX2 = deltaY2 = 0.0))
				moveDeltaXy_2 = list( list( deltaX1 deltaY1) list( deltaX2 deltaY2))
				
				printMove( 'XY list( clineX1 clineY1) list( deltaX1 deltaY1) list( clineX2 clineY2) list( deltaX2 deltaY2))
			)
			( t
				printf( "Yet to define slopeType[%L]\n" slopeType)
				return( nil)
			)
		)
		
		
		return( moveDeltaXy_2)
	)
)

procedure( getClineGap( clineId1 clineId2)
	; clineId1 = car( axlGetSelSet())
	; clineId2 = cadr( axlGetSelSet())
	prog( ( clineLayer netclassId phyCset neckGap primaryGap neckWidth primaryWidth clineGap)
		slope = getSlopeByLine( clineId1)
		
		;;;; while cline is in vertical
		unless( slope
			clineGap = abs( caar( clineId1->startEnd) - caar( clineId2->startEnd))
			return( clineGap)
		)
		
		cline1Xy = car( clineId1->startEnd)
		cline2Xy = car( clineId2->startEnd)
		
		;; y = mx + b -> b = y - mx
		cline1B = cadr( cline1Xy) - slope * car( cline1Xy)
		cline2B = cadr( cline2Xy) - slope * car( cline2Xy)
		
		;; d = |b2 - b1| / sqrt( m^2 + 1)
		clineGap = abs( cline2B - cline1B) / sqrt( slope**2 + 1)
		
		
		return( clineGap)
	)
)

defun( getAngleBySlope ( slope)
	prog( ( arcTan angle)
		if( slope then
			arcTan = atan( slope)
			angle = 180.0 * arcTan / axlPI
		else
			angle = 90.0
		)
		
		
		return( angle)
	)
)

defun( GetCompesateAngle ( clineId slopeType)
	; clineId = car( axlGetSelSet())
	prog( ( finalAngle slope currentAngle compesateAngle)
		caseq( slopeType
			( 'vertical (finalAngle = 90.0))
			( 'toLeftUp (finalAngle = 135.0))
			( 'horizontal (finalAngle = 0.0))
			( 'toRightUp (finalAngle = 45.0))
			( t
				println( "Yet to define slopeType[%L]\n" slopeType)
				return( nil)
			)
		)
		unless( finalAngle return( nil))
		
		slope = getSlopeByLine( clineId)
		currentAngle = getAngleBySlope( slope)
		compesateAngle = finalAngle - currentAngle
		
		;; it make no sense to rotate a line for 180
		when( axlGeoEqual( 180.0 compesateAngle) (compesateAngle = 0.0))
		
		return( compesateAngle)
	)
)

defun( GetSlopeType ( lineId)
	;; lineId = car( axlGetSelSet())
	prog( ( slope)
		slope = getSlopeByLine( lineId)
		printf( "Get slope: %L\n" slope)
		
		unless( slope return( 'vertical))
		when( (slope < (-1 - _tolerance)) return( 'vertical))
		when( (slope <= (-1 + _tolerance)) return( 'toLeftUp))
		when( (slope < (1 - _tolerance)) return( 'horizontal))
		when( (slope <= (1 + _tolerance)) return( 'toRightUp))
		return( 'vertical)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(axlCmdRegister "cline2MidOfPins" 'cline2MidOfPinsMain)

 (cline2MidOfPinsMain)
; skill encrypt( "c:/skill/cline2MidOfPins.il" "C:/skill/cline2MidOfPins.ile")
; (load "cline2MidOfPins.il")
; (load "cline2MidOfPins.ile")