;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; introduction

; Developer: Derek Hsu
; Starting date: 11/22/2019 - _Derek11222019
; puropse: 
;	1. to compansate the length mismatching
;		1. add bump to cline segment if it does not connect to pin or via
;		2. extend out the routing if the cline segment connects to pin or via

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global variable

procedure( init()
	setq( _mon_ls list( nil "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	sscanf( getCurrentTime() "%s %d %d:%d:%d %d" _month _date _hour _minute _second _year)
	sprintf( _now "%.4d%.2d%.2d_%.2d%.2d%.2d" _year listnindex( _mon_ls _month) _date _hour _minute _second)
	
	unless( stringp( axlGetVariable( "ads_sdlog")) axlSetVariable( "ads_sdlog" "log"))
	setq( _logDir axlGetVariable( "ads_sdlog"))
	sprintf( _logFileName "./%s/Cline2MidOfPins-%s.log" _logDir _now)
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	setq( _selected2ClineSeg nil)
	setq( _selected2Out nil)
	
	setq( _constantForSpacing 2)
	setq( _constantForWidth 3)
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	setq( _formDiffpairEqualizerName "diffpairEqualizer.form")
	setq( _formDiffpairEqualizerHandle 'diffpairEqualizer)
	
	setq( _formKeyPinDelayType "pinDelayType")
	setq( _pinDelayType nil)
	
	setq( _formKeyPinDelayDiagram1 "pinDelayDia1")
	setq( _formKeyPinDelayDiagram2 "pinDelayDia2")
	setq( _formKeyPinDelayDiagram3 "pinDelayDia3")
	setq( _formKeyPinDelayDiagram4 "pinDelayDia4")
	setq( _formKeyBumpDeployment "bumpDeployment")
	
	setq( _bmpPinDelayDiagram1 strcat( _formKeyPinDelayDiagram1 ".bmp"))
	setq( _bmpPinDelayDiagram2 strcat( _formKeyPinDelayDiagram2 ".bmp"))
	setq( _bmpPinDelayDiagram3 strcat( _formKeyPinDelayDiagram3 ".bmp"))
	setq( _bmpPinDelayDiagram4 strcat( _formKeyPinDelayDiagram4 ".bmp"))
	setq( _bmpBumpDeployment strcat( _formKeyBumpDeployment ".bmp"))
	
	setq( _formKeyMaxBumpLength "maxBumpLength")
	setq( _lineWidth nil)
	setq( _maxBumpLength nil)
	setq( _formKeyMaxBumpHeight "maxBumpHeight")
	setq( _lineSpacing nil)
	setq( _maxBumpHeight nil)
	
	setq( _formKeyNet1Name "net1Name")
	setq( _formKeyNet2Name "net2Name")
	setq( _formKeyCline1Layer "cline1Layer")
	setq( _formKeyCline2Layer "cline2Layer")
	setq( _formKeyPin1Left "pin1Left")
	setq( _formKeyPin1Right "pin1Right")
	setq( _formKeyPin2Left "pin2Left")
	setq( _formKeyPin2Right "pin2Right")
	
	setq( _formKeyNet1PinDelayLeft "net1DelayLeft")
	setq( _net1PinDelayLeft nil)
	setq( _formKeyNet2PinDelayLeft "net2DelayLeft")
	setq( _net2PinDelayLeft nil)
	setq( _formKeyNet1Distance "net1Distance")
	setq( _net1Distance nil)
	setq( _formKeyNet2Distance "net2Distance")
	setq( _net2Distance nil)
	setq( _formKeyNet1PinDelayRight "net1PinDelayRight")
	setq( _net1PinDelayRight nil)
	setq( _formKeyNet2PinDelayRight "net2PinDelayRight")
	setq( _pinDelayRight nil)
	setq( _formKeyNet1Total "net1Total")
	setq( _net1Total nil)
	setq( _formKeyNet2Total "net2Total")
	setq( _net2Total nil)
	
	setq( _formKeyCline1PinDelayLeft "cline1PinDelayLeft")
	setq( _cline1PinDelayLeft nil)
	setq( _formKeyCline2PinDelayLeft "cline2PinDelayLeft")
	setq( _cline2PinDelayLeft nil)
	setq( _formKeyCline1Distance "cline1Distance")
	setq( _cline1Distance "cline1Distance")
	setq( _formKeyCline2Distance "cline2Distance")
	setq( _cline2Distance "cline2Distance")
	setq( _formKeyCline1PinDelayRight "cline1PinDelayRight")
	setq( _cline1PinDelayRight nil)
	setq( _formKeyCline2PinDelayRight "cline2PinDelayRight")
	setq( _cline2PinDelayRight nil)
	setq( _formKeyCline1Total "cline1Total")
	setq( _cline1Total nil)
	setq( _formKeyCline2Total "cline2Total")
	setq( _cline2Total nil)
	
	setq( _formKeyTuneForNet "tuneForNet")
	setq( _formKeyTuneForCline "tuneForCline")
	setq( _formKeyTuneType "tuneType")
	setq( _tuneType nil)
	
	setq( _formKeyMaxNumberOfBump "maxNumberOfBump")
	setq( _maxNumberOfBump 3)
	
	setq( _formKeyLengthMatchTolerance "lengthMatchTolerance")
	setq( _lengthMatchTolerance 1.0)
	
	setq( _formKeyEqualizerMode "equalizerMode")
	setq( _equalizerTunePinDelay "Pin Delay")
	setq( _equalizerTuneBump "Tune Bump")
	setq( _equalizerNone "None")
	setq( _equalizerMode nil)
	
	setq( _formKeySelect "select")
	setq( _formKeyDone "done")
	setq( _formKeyTune "tune")
	setq( _formKeyClose "close")
	
	
	t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of global variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Form

procedure( writeFormThumbnail( outPort field x y width height)
	let( ()
		fprintf( outPort "FIELD %sPicture\n" field)
		fprintf( outPort "THUMBNAIL %s\n" field)
		fprintf( outPort "OPTIONS %s\n" "stretch")
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "FSIZE %d %d\n" width height)
		fprintf( outPort "ENDFIELD\n")
	)
)

procedure( writeFormReal( outPort field x y fillinLength @optional valueMax valueMin)
	let( ()
		fprintf( outPort "FIELD %s\n" field)
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "REALFILLIN %d %d\n" fillinLength fillinLength)
		when( numberp( valueMax) fprintf( outPort "MAX %f\n" valueMax))
		when( numberp( valueMin) fprintf( outPort "MIN %f\n" valueMin))
		fprintf( outPort "ENDFIELD\n")
	)
)

procedure( writeFormInt( outPort field x y fillinLength @optional valueMax valueMin)
	let( ()
		fprintf( outPort "FIELD %s\n" field)
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "INTFILLIN %d %d\n" fillinLength fillinLength)
		when( numberp( valueMax) fprintf( outPort "MAX %f\n" valueMax))
		when( numberp( valueMin) fprintf( outPort "MIN %f\n" valueMin))
		fprintf( outPort "ENDFIELD\n")
	)
)

procedure( writeFormStr( outPort field x y fillinLength)
	let( ()
		fprintf( outPort "FIELD %s\n" field)
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "STRFILLIN %d %d\n" fillinLength (fillinLength + 20))
		fprintf( outPort "ENDFIELD\n")
	)
)

procedure( writeFormText( outPort text x y)
	let( ()
		fprintf( outPort "TEXT \"%s\" \n" text)
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "ENDTEXT\n")
	)
)

procedure( writeFormGroup( outPort name x y width height)
	prog( ()
		fprintf( outPort "GROUP \"%s\"\n" name)
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "TSSIZE %d %d\n" width height)
		fprintf( outPort "ENDGROUP\n")
	)
)

procedure( writeFormCheckList( outPort field x y name radioLabel)
	let( ()
		fprintf( outPort "FIELD %s\n" field)
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "CHECKLIST \"%s\" \"%s\" \n" name radioLabel)
		fprintf( outPort "ENDFIELD\n")
	)
)

procedure( writeFormButton( outPort field name x y buttonWidth buttonHeight)
	let( ()
		fprintf( outPort "FIELD %s\n" field)
		fprintf( outPort "FLOC %d %d\n" x y)
		fprintf( outPort "MENUBUTTON \"%s\" %d %d\n" name buttonWidth buttonHeight)
		fprintf( outPort "ENDFIELD\n")
	)
)

procedure( writeFormStatusLineReturnY( outPort x y title field1 field2 field3 field4 fillinLength)
	prog( ()
		writeFormText( outPort title x y)
		x = x + 4
		writeFormReal( outPort field1 x y fillinLength)
		x = x + fillinLength + 2
		writeFormReal( outPort field2 x y fillinLength)
		x = x + fillinLength + 2
		writeFormReal( outPort field3 x y fillinLength)
		x = x + fillinLength + 2
		writeFormReal( outPort field4 x y fillinLength)
		
		
		return( y)
	)
)

procedure( writeFormClineSegInfo( outPort x y title fieldName fieldPinLeft fieldPinRight fieldLayer)
	let( ( fillinLength)
		writeFormText( outPort title x y)
		
		x = x + 14
		fillinLength = 25
		writeFormStr( outPort fieldName x y fillinLength)
		
		x = x + fillinLength + 3
		fillinLength = 15
		writeFormStr( outPort fieldPinLeft x y fillinLength)
		
		x = x + fillinLength + 3
		writeFormStr( outPort fieldPinRight x y fillinLength)
		
		x = x + fillinLength + 3
		writeFormStr( outPort fieldLayer x y fillinLength)
	)
)

procedure( WriteDiffpairEualizerForm()
	prog( ( outPort)
		outPort = outfile( _formDiffpairEqualizerName "w")
		unless( outportp( outPort) println( "ERROR: Fail  to write diffpair equalizer form file") return( nil))
		;;
		
		formWidth = 102
		formY = 100
		radioWidth = 3
		groupWidth = 50
		
		fprintf( outPort "FILE_TYPE=FORM_DEFN VERSION=1\n") 
		fprintf( outPort "FORM TOOLWINDOW \n")
		fprintf( outPort "FIXED\n")
		fprintf( outPort "PORT %d %d\n" formWidth formY)
		fprintf( outPort "HEADER \"Differential Pair Equalizer Panel\"\n")
		fprintf( outPort "TILE\n")
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		startX = 1
		startY = 1
		
		groupStartX = startX
		groupStartY = startY
		
		x = groupStartX + radioWidth
		y = groupStartY + 2
		
		bmpWidth = 20
		bmpHeight = 10
		
			x = groupStartX + 1
			writeFormCheckList( outPort _formKeyPinDelayDiagram1 x y "" _formKeyPinDelayType)
			
			x = x + radioWidth
			writeFormThumbnail( outPort _formKeyPinDelayDiagram1 x y bmpWidth bmpHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			x = x + bmpWidth + 1
			writeFormCheckList( outPort _formKeyPinDelayDiagram2 x y "" _formKeyPinDelayType)
			
			x = x + radioWidth
			writeFormThumbnail( outPort _formKeyPinDelayDiagram2 x y bmpWidth bmpHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		y = y + bmpHeight + 2
		
			x = groupStartX + 1
			writeFormCheckList( outPort _formKeyPinDelayDiagram3 x y "" _formKeyPinDelayType)
			
			x = x + radioWidth
			writeFormThumbnail( outPort _formKeyPinDelayDiagram3 x y bmpWidth bmpHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			x = x + bmpWidth + 1
			writeFormCheckList( outPort _formKeyPinDelayDiagram4 x y "" _formKeyPinDelayType)
			
			x = x + radioWidth
			writeFormThumbnail( outPort _formKeyPinDelayDiagram4 x y bmpWidth bmpHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		groupHeight = y + bmpHeight
		writeFormGroup( outPort "Pin Delay Type" groupStartX groupStartY groupWidth groupHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		groupStartX = groupStartX + groupWidth + 1
		y = groupStartY + 2
		fillinLength = 10
		
		bmpWidth = 47
		bmpHeight = 18
		
		x = groupStartX + 1
		writeFormThumbnail( outPort _formKeyBumpDeployment x y bmpWidth bmpHeight)
		
		x = x + 7
		fillinX = x + 20
		
		y = y + bmpHeight + 1
		writeFormText( outPort sprintf( nil "B/C/D <= (%d * Line Width)" _constantForWidth) x y)
		writeFormReal( outPort _formKeyMaxBumpLength fillinX y fillinLength 30.0 0.0)
		
		y = y + 2
		writeFormText( outPort sprintf( nil "A <= (%d * Spacing)" _constantForSpacing) x y)
		writeFormReal( outPort _formKeyMaxBumpHeight fillinX y fillinLength 20.0 0.0)
		
		groupHeight = y - groupStartY + 2
		writeFormGroup( outPort "Equalizer" groupStartX groupStartY groupWidth groupHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		x = startX + 1
		y = y + 3
		
		writeFormClineSegInfo( outPort x y "Cline Segment1:" _formKeyNet1Name _formKeyPin1Left _formKeyPin1Right _formKeyCline1Layer)
		
		x = startX + 1
		y = y + 2
		
		writeFormClineSegInfo( outPort x y "Cline Segment2:" _formKeyNet2Name _formKeyPin2Left _formKeyPin2Right _formKeyCline2Layer)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		groupStartX = startX
		groupStartY = y + 3
		fillinLength = 9
		
		x = groupStartX + 1
		y = groupStartY + 2
		
		writeFormText( outPort "              Pin Delay           Distance           Pin Delay              Total" x y)
		y = y + 2
		y = writeFormStatusLineReturnY( outPort x y "CS1"
			_formKeyNet1PinDelayLeft _formKeyNet1Distance _formKeyNet1PinDelayRight _formKeyNet1Total fillinLength)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		x = groupStartX + 1
		y = y + 2
		y = writeFormStatusLineReturnY( outPort x y "CS2"
			_formKeyNet2PinDelayLeft _formKeyNet2Distance _formKeyNet2PinDelayRight _formKeyNet2Total fillinLength)
		
		groupHeight = y - groupStartY + 3
		writeFormGroup( outPort "Net" groupStartX groupStartY groupWidth groupHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		groupStartX = startX + groupWidth + 1
		fillinLength = 9
		
		x = groupStartX + 1
		y = groupStartY + 2
		
		writeFormText( outPort "              Pin Delay           Distance           Pin Delay              Total" x y)
		y = y + 2
		y = writeFormStatusLineReturnY( outPort x y "CS1"
			_formKeyCline1PinDelayLeft _formKeyCline1Distance _formKeyCline1PinDelayRight _formKeyCline1Total fillinLength)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		x = groupStartX + 1
		y = y + 2
		y = writeFormStatusLineReturnY( outPort x y "CS2"
			_formKeyCline2PinDelayLeft _formKeyCline2Distance _formKeyCline2PinDelayRight _formKeyCline2Total fillinLength)
		
		groupHeight = y - groupStartY + 3
		writeFormGroup( outPort "Cline" groupStartX groupStartY groupWidth groupHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		yBottom = y + 4
		
		y = yBottom
		
		x = startX + 1
		writeFormText( outPort "Tune for:" x y)
		x = x + 7
		writeFormCheckList( outPort _formKeyTuneForNet x y "Net" _formKeyTuneType)
		x = x + 6
		writeFormCheckList( outPort _formKeyTuneForCline x y "Cline" _formKeyTuneType)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		y = y + 2
		
		x = startX + 1
		writeFormText( outPort "Max number of Bump:" x y)
		x = x + 20
		writeFormInt( outPort _formKeyMaxNumberOfBump x y 10)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		y = y + 2
		
		x = startX + 1
		writeFormText( outPort "Length Match Tolerance:" x y)
		x = x + 20
		writeFormReal( outPort _formKeyLengthMatchTolerance x y 10 10.0 0.0)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		y = y + 2
		
		x = startX + 1
		writeFormText( outPort "Current Equalization Mode: " x y)
		x = x + 20
		writeFormStr( outPort _formKeyEqualizerMode x y 10)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		y = y - 2
		
		buttonWidth = 10
		buttonHeight = 2
		
		x = 42
		writeFormButton( outPort _formKeySelect "Select" x y buttonWidth buttonHeight)
		x = x + buttonWidth + 2
		writeFormButton( outPort _formKeyTune "Tune" x y buttonWidth buttonHeight)
		x = x + buttonWidth + 2
		writeFormButton( outPort _formKeyDone " Done" x y buttonWidth buttonHeight)
		x = x + buttonWidth + 4
		writeFormButton( outPort _formKeyClose "Close" x y buttonWidth buttonHeight)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		fprintf( outPort "ENDTILE\n")
		fprintf( outPort "ENDFORM\n")
		
		close( outPort)
		
		return( t)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		close( outPort)
		
		
		return( t)
	)
)

procedure( SetForm( outForm)
	prog( ()
		axlFormSetFieldEditable( outForm _formKeyNet1Name nil)
		axlFormSetFieldEditable( outForm _formKeyNet2Name nil)
		axlFormSetFieldEditable( outForm _formKeyPin1Left nil)
		axlFormSetFieldEditable( outForm _formKeyPin1Right nil)
		axlFormSetFieldEditable( outForm _formKeyPin2Left nil)
		axlFormSetFieldEditable( outForm _formKeyPin2Right nil)
		axlFormSetFieldEditable( outForm _formKeyCline1Layer nil)
		axlFormSetFieldEditable( outForm _formKeyCline2Layer nil)
		
		axlFormSetFieldEditable( outForm _formKeyNet1PinDelayLeft nil)
		axlFormSetFieldEditable( outForm _formKeyNet2PinDelayLeft nil)
		axlFormSetFieldEditable( outForm _formKeyNet1Distance nil)
		axlFormSetFieldEditable( outForm _formKeyNet2Distance nil)
		axlFormSetFieldEditable( outForm _formKeyNet1PinDelayRight nil)
		axlFormSetFieldEditable( outForm _formKeyNet2PinDelayRight nil)
		axlFormSetFieldEditable( outForm _formKeyNet1Total nil)
		axlFormSetFieldEditable( outForm _formKeyNet2Total nil)
		
		axlFormSetFieldEditable( outForm _formKeyCline1PinDelayLeft nil)
		axlFormSetFieldEditable( outForm _formKeyCline2PinDelayLeft nil)
		axlFormSetFieldEditable( outForm _formKeyCline1Distance nil)
		axlFormSetFieldEditable( outForm _formKeyCline2Distance nil)
		axlFormSetFieldEditable( outForm _formKeyCline1PinDelayRight nil)
		axlFormSetFieldEditable( outForm _formKeyCline2PinDelayRight nil)
		axlFormSetFieldEditable( outForm _formKeyCline1Total nil)
		axlFormSetFieldEditable( outForm _formKeyCline2Total nil)
		
		axlFormSetField( outForm _formKeyPinDelayDiagram1 t)
		_pinDelayType = _formKeyPinDelayDiagram1
		
		axlFormSetField( outForm _formKeyTuneForNet t)
		_tuneType = _formKeyTuneForNet
		
		axlFormSetField( outForm _formKeyMaxNumberOfBump _maxNumberOfBump)
		
		axlFormSetField( outForm _formKeyLengthMatchTolerance _lengthMatchTolerance)
		
		axlFormSetFieldEditable( outForm _formKeyEqualizerMode nil)
		axlFormSetField( outForm _formKeyEqualizerMode _equalizerNone)
		
		
		return( t)
	)
)

procedure( getToParallelClineSegList( ClineSeg)
	prog( ()
		
	)
)

procedure( Tune2PinDelay()
	prog( ( shortClineSeg deltaDistance)
		;;;;; get a shorter cline segment for tuning and another cline segment for positioning bumps
		shortClineSeg = GetShortClineSegFromSelected2ClineSeg()
		pinOnShort = car( setof( x _selected2Out eq( shortClineSeg->net x->net)))
		
		anotherClineSeg = car( remq( shortClineSeg _selected2ClineSeg))
		pinOnAnother = car( remq( pinOnShort _selected2Out))
		
		;;;; get delta between 2 cline segment
		deltaDistance = GetDeltaDistance()
		unless( deltaDistance return( nil))
		
		;;;; show the information
		;; --------------------- get closer end
		cond(
			( equal( _pinDelayType _formKeyPinDelayDiagram1)
				;;;; simply connect to parallel cline segment
			)
			( equal( _pinDelayType _formKeyPinDelayDiagram2)
				;;;; 
			)
			( equal( _pinDelayType _formKeyPinDelayDiagram3))
			( equal( _pinDelayType _formKeyPinDelayDiagram4))
			( t
				println( "Error: Yet to define pin delay type [%s]\n" _pinDelayType)
				return( nil)
			)
		)
		
		;;;; create xy list of new cline segments --- get the back pin position if pin delay type is 2 3 4
		;;;; delete and create new cline segment
	)
)

procedure( CallBackForm( outForm)
	prog( ( curField curValue)
		curField = outForm->curField
		curValue = outForm->curValue
		
		cond(
			( member( curField list( _formKeyPinDelayDiagram1 _formKeyPinDelayDiagram2 _formKeyPinDelayDiagram3 _formKeyPinDelayDiagram4))
				_pinDelayType = curField
				unless( equal( _equalizerNone axlFormGetField( outForm _formKeyEqualizerMode))
					axlFormSetField( outForm _formKeyEqualizerMode curField)
				)
			)
			( equal( _formKeyMaxBumpHeight curField)
				if( and( numberp( _lineSpacing) (curValue < _lineSpacing)) then
					printf( "Warning: Max of bump height has to be greater than [%f]\n" _lineSpacing)
					axlFormSetField( outForm _formKeyMaxBumpHeight _lineSpacing + 1.0)
				else
					_maxBumpHeight = axlFormGetField( outForm _formKeyMaxBumpHeight)
				)
			)
			( equal( _formKeyMaxBumpLength curField)
				_maxBumpLength = axlFormGetField( outForm _formKeyMaxBumpLength)
			)
			( equal( _formKeyTuneForCline curField)
				_tuneType = _formKeyTuneForCline
			)
			( equal( _formKeyTuneForNet curField)
				_tuneType = _formKeyTuneForNet
			)
			( equal( _formKeyMaxNumberOfBump curField)
				_maxNumberOfBump = curValue
			)
			( equal( _formKeyLengthMatchTolerance curField)
				_lengthMatchTolerance = curValue
			)
			( equal( _formKeySelect curField)
				SelectPinsClineSegs( outForm)
			)
			( equal( _formKeyDone curField)
				axlFinishEnterFun()
			)
			( equal( _formKeyTune curField)
				if( dtpr( _selected2ClineSeg) then
					cond(
						( equal( _equalizerMode _equalizerTuneBump) Tune2ClineSeg())
						( equal( _equalizerMode _equalizerTunePinDelay) Tune2PinDelay())
					)
					
					FillUpForm( outForm)
					_selected2ClineSeg = nil
				else
					println( "Warning: Please Select pair of cline segments to do equalization, otherwise, select 2 pins and at least a cline segments to do the pin delay adjustment")
				)
			)
			( equal( _formKeyClose curField)
				axlFinishEnterFun()
				axlClearSelSet()
				axlFormClose( outForm)
			)
		)
		
		
		return( t)
	)
)

procedure( GetClineGap( startEnd1 startEnd2 clineWidth)
	prog( ( clineLayer netclassId phyCset neckGap primaryGap neckWidth primaryWidth clineDistance clineGap)
		slope = axlLineSlope( startEnd1)
		
		;;;; while cline is in vertical
		unless( slope
			clineDistance = abs( caar( startEnd1) - caar( startEnd2))
			clineGap = clineDistance - clineWidth
			return( clineGap)
		)
		
		cline1Xy = car( startEnd1)
		cline2Xy = car( startEnd2)
		
		;; y = mx + b -> b = y - mx
		cline1B = cadr( cline1Xy) - slope * car( cline1Xy)
		cline2B = cadr( cline2Xy) - slope * car( cline2Xy)
		
		;; d = |b2 - b1| / sqrt( m^2 + 1)
		clineDistance = abs( cline2B - cline1B) / sqrt( slope**2 + 1)
		clineGap = clineDistance - clineWidth
		
		return( clineGap)
	)
)

procedure( GetPinPairOfNet( netId)
	prog( ( xnetId pinList symbolList pinPair)
		xnetId = netId->xnet
		
		when( eq( netId xnetId)
			pinPair = axlPinsOfNet( netId 'pin)
			return( pinPair)
		)
		
		pinList = mapcan( lambda( (x) axlPinsOfNet( x 'pin)) xnetId->groupMembers)
		symbolList = pinList~>parent
		;;;; remove the pin if its symbol is connected more than once
		foreach( pinId pinList
			when( onep( length( setof( x symbolList eq( pinId->parent x))))
				pinPair = append1( pinPair pinId)
			)
		)
		
		
		return( pinPair)
	)
)

procedure( FillUpFormClineSeg( outForm pin1Left pin1Right pin2Left pin2Right cline1Layer cline2Layer)
	let( ( pinName)
		axlFormSetField( outForm _formKeyNet1Name pin1Left->net->name)
		
		pinName = upperCase( axlDbidName( pin1Left) || "")
		axlFormSetField( outForm _formKeyPin1Left pinName)
		
		pinName = upperCase( axlDbidName( pin1Right) || "")
		axlFormSetField( outForm _formKeyPin1Right pinName)
		axlFormSetField( outForm _formKeyCline1Layer cline1Layer)
		
		axlFormSetField( outForm _formKeyNet2Name pin2Left->net->name)
		
		pinName = upperCase( axlDbidName( pin2Left) || "")
		axlFormSetField( outForm _formKeyPin2Left pinName)
		
		pinName = upperCase( axlDbidName( pin2Right) || "")
		axlFormSetField( outForm _formKeyPin2Right pinName)
		axlFormSetField( outForm _formKeyCline2Layer cline2Layer)
		
		
		t
	)
)

procedure( FillUpFormNetGroup( outForm pin1Left pin1Right pin2Left pin2Right)
	let( ( )
		_net1PinDelayLeft = GetFirstFloatInString( pin1Left->prop->PIN_DELAY)
		axlFormSetField( outForm _formKeyNet1PinDelayLeft _net1PinDelayLeft)
		
		if( eq( pin1Left->net pin1Right->net)
			_net1Distance = axlDBGetLength( pin1Left->net)
			_net1Distance = axlDBGetLength( pin1Left->net) + axlDBGetLength( pin1Right->net)
		)
		axlFormSetField( outForm _formKeyNet1Distance _net1Distance)
		
		_net1PinDelayRight = GetFirstFloatInString( pin1Right->prop->PIN_DELAY)
		axlFormSetField( outForm _formKeyNet1PinDelayRight _net1PinDelayRight)
		
		_net1Total = _net1PinDelayLeft + _net1Distance + _net1PinDelayRight
		axlFormSetField( outForm _formKeyNet1Total _net1Total)
		
		;;;
		
		_net2PinDelayLeft = GetFirstFloatInString( pin2Left->prop->PIN_DELAY)
		axlFormSetField( outForm _formKeyNet2PinDelayLeft _net2PinDelayLeft)
		
		if( eq( pin2Left->net pin2Right->net)
			_net2Distance = axlDBGetLength( pin2Left->net)
			_net2Distance = axlDBGetLength( pin2Left->net) + axlDBGetLength( pin2Right->net)
		)
		axlFormSetField( outForm _formKeyNet2Distance _net2Distance)
		
		_net2PinDelayRight = GetFirstFloatInString( pin2Right->prop->PIN_DELAY)
		axlFormSetField( outForm _formKeyNet2PinDelayRight _net2PinDelayRight)
		
		_net2Total = _net2PinDelayLeft + _net2Distance + _net2PinDelayRight
		axlFormSetField( outForm _formKeyNet2Total _net2Total)
		
		
		t
	)
)

procedure( FillUpFormClineGroupPinDelay( outForm connObj pin1Left pin1Right pin2Left pin2Right)
	prog( ()
		unless( equal( "pin" connObj->objType) return( t))
		
		;;;
		cond(
			( axlGeoPointsEqual( pin1Left->xy connObj->xy)
				_cline1PinDelayLeft = GetFirstFloatInString( pin1Left->prop->PIN_DELAY)
				axlFormSetField( outForm _formKeyCline1PinDelayLeft _cline1PinDelayLeft)
			)
			( axlGeoPointsEqual( pin1Right->xy connObj->xy)
				_cline1PinDelayRight = GetFirstFloatInString( pin1Right->prop->PIN_DELAY)
				axlFormSetField( outForm _formKeyCline1PinDelayRight _cline1PinDelayRight)
			)
			( axlGeoPointsEqual( pin2Left->xy connObj->xy)
				_cline2PinDelayLeft = GetFirstFloatInString( pin2Left->prop->PIN_DELAY)
				axlFormSetField( outForm _formKeyCline2PinDelayLeft _cline2PinDelayLeft)
			)
			( axlGeoPointsEqual( pin2Right->xy connObj->xy)
				_cline2PinDelayRight = GetFirstFloatInString( pin2Right->prop->PIN_DELAY)
				axlFormSetField( outForm _formKeyCline2PinDelayRight _cline2PinDelayRight)
			)
		)
		
		
		return( t)
	)
)

procedure( FillUpFormClineGroup( outForm clineSeg1 clineSeg2 pin1Left pin1Right pin2Left pin2Right)
	; clineSeg1 = car( axlGetSelSet())
	; a = car( axlGetSelSet())
	prog( ( cline1 cline2 cline1ConnObjList cline2ConnObjList connObj)
		cline1 = clineSeg1->parent
		cline2 = clineSeg2->parent
		
		cline1ConnObjList = mapcan( lambda( (x) x) axlDBGetConnect( cline1))
		cline2ConnObjList = mapcan( lambda( (x) x) axlDBGetConnect( cline2))
		
		unless( eqv( 2 length( cline1ConnObjList))
			printf( "Warning: More than 2 ends(pin/via)  on [%s] on [%s]\n" cline1->net->name cline1->layer) return( nil))
		unless( eqv( 2 length( cline2ConnObjList))
			printf( "Warning: More than 2 ends(pin/via)  on [%s] on [%s]\n" cline2->net->name cline2->layer) return( nil))
		
		;;;;
		_cline1PinDelayLeft = _cline1PinDelayRight = _cline2PinDelayLeft = _cline2PinDelayRight = 0.0
		axlFormSetField( outForm _formKeyCline1PinDelayLeft _cline1PinDelayLeft)
		axlFormSetField( outForm _formKeyCline1PinDelayRight _cline1PinDelayRight)
		axlFormSetField( outForm _formKeyCline2PinDelayLeft _cline2PinDelayLeft)
		axlFormSetField( outForm _formKeyCline2PinDelayRight _cline2PinDelayRight)
		FillUpFormClineGroupPinDelay( outForm car( cline1ConnObjList) pin1Left pin1Right pin2Left pin2Right)
		FillUpFormClineGroupPinDelay( outForm cadr( cline1ConnObjList) pin1Left pin1Right pin2Left pin2Right)
		FillUpFormClineGroupPinDelay( outForm car( cline2ConnObjList) pin1Left pin1Right pin2Left pin2Right)
		FillUpFormClineGroupPinDelay( outForm cadr( cline2ConnObjList) pin1Left pin1Right pin2Left pin2Right)
		
		;;;;;
		_cline1Distance = axlDBGetLength( cline1)
		axlFormSetField( outForm _formKeyCline1Distance _cline1Distance)
		
		_cline1Total = _cline1PinDelayLeft + _cline1Distance + _cline1PinDelayRight
		axlFormSetField( outForm _formKeyCline1Total _cline1Total)
		
		_cline2Distance = axlDBGetLength( cline2)
		axlFormSetField( outForm _formKeyCline2Distance _cline2Distance)
		
		_cline2Total = _cline2PinDelayLeft + _cline2Distance + _cline2PinDelayRight
		axlFormSetField( outForm _formKeyCline2Total _cline2Total)
		
		
		t
	)
)

procedure( ResetForm( outForm)
	let( ()
		axlFormSetField( outForm _formKeyMaxBumpLength nil)
		axlFormSetField( outForm _formKeyMaxBumpHeight nil)
		
		axlFormSetField( outForm _formKeyNet1Name nil)
		axlFormSetField( outForm _formKeyPin1Left nil)
		axlFormSetField( outForm _formKeyPin1Right nil)
		axlFormSetField( outForm _formKeyCline1Layer nil)
		
		axlFormSetField( outForm _formKeyNet2Name nil)
		axlFormSetField( outForm _formKeyPin2Left nil)
		axlFormSetField( outForm _formKeyPin2Right nil)
		axlFormSetField( outForm _formKeyCline2Layer nil)
		
		axlFormSetField( outForm _formKeyNet1PinDelayLeft nil)
		axlFormSetField( outForm _formKeyNet1Distance nil)
		axlFormSetField( outForm _formKeyNet1PinDelayRight nil)
		axlFormSetField( outForm _formKeyNet1Total nil)
		
		axlFormSetField( outForm _formKeyNet2PinDelayLeft nil)
		axlFormSetField( outForm _formKeyNet2Distance nil)
		axlFormSetField( outForm _formKeyNet2PinDelayRight nil)
		axlFormSetField( outForm _formKeyNet2Total nil)
		
		axlFormSetField( outForm _formKeyCline1PinDelayLeft nil)
		axlFormSetField( outForm _formKeyCline1Distance nil)
		axlFormSetField( outForm _formKeyCline1PinDelayRight nil)
		axlFormSetField( outForm _formKeyCline1Total nil)
		
		axlFormSetField( outForm _formKeyCline2PinDelayLeft nil)
		axlFormSetField( outForm _formKeyCline2Distance nil)
		axlFormSetField( outForm _formKeyCline2PinDelayRight nil)
		axlFormSetField( outForm _formKeyCline2Total nil)
		
		axlFormSetField( outForm _formKeyEqualizerMode _equalizerNone)
		
		
		t
	)
)

procedure( FillUpForm( outForm)
	; clineSeg1 = car( axlGetSelSet())
	; clineSeg2 = cadr( axlGetSelSet())
	let( ( clineSeg1 clineSeg2 clineSeg1Width clineSeg2Width cline1Layer cline2Layer net1 net2
			net1Name net2Name net1PinPair net2PinPair pin1Left pin1Right pin2Left pin2Right valueString )
			
		clineSeg1 = car( _selected2ClineSeg)
		clineSeg2 = cadr( _selected2ClineSeg)
		clineSeg1StartEnd = clineSeg1->startEnd
		clineSeg2StartEnd = clineSeg2->startEnd
		clineSeg1Width = clineSeg1->width
		clineSeg2Width = clineSeg2->width
		cline1Layer = clineSeg1->layer
		cline2Layer = clineSeg2->layer
		net1 = clineSeg1->net
		net2 = clineSeg2->net
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; check differential pair things
		net1Name = net1->name
		net2Name = net2->name
		unless( equal( cline1Layer cline2Layer)
			printf( "The layer of Cline[%s, %s] is not the same\n" net1Name net2Name) ResetForm( outForm) return( nil))
		unless( stringp( net1->diffpair->name)
			printf( "Net[%s] is not in diffpair\n" net1Name) ResetForm( outForm) return( nil))
		unless( stringp( net2->diffpair->name)
			printf( "Net[%s] is not in diffpair\n" net2Name) ResetForm( outForm) return( nil))
		unless( axlGeoEqual( clineSeg1Width clineSeg2Width)
			printf( "The line width of clineSeg[%s, %s]  is not the same\n") ResetForm( outForm) return( nil))
		unless( eq( net1->diffpair net2->diffpair)
			println( "Net[%s, %s] are not in same diffpair\n" net1Name net2Name) ResetForm( outForm) return( nil))
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; spacing and line width
		
		net1FormName = axlFormGetField( outForm _formKeyNet1Name)
		unless( member( net1FormName list( net1Name net2Name))
			_lineWidth = clineSeg1Width
			_maxBumpLength = _constantForWidth * _lineWidth
			sprintf( valueString "%f" _maxBumpLength)
			axlFormSetField( outForm _formKeyMaxBumpLength valueString)
			
			_lineSpacing = GetClineGap( clineSeg1StartEnd clineSeg2StartEnd _lineWidth)
			_maxBumpHeight = _constantForSpacing * _lineSpacing
			sprintf( valueString "%f" _maxBumpHeight)
			axlFormSetField( outForm _formKeyMaxBumpHeight valueString)
		)
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; check the symbol of pin is on the same side
		
		net1PinPair = GetPinPairOfNet( net1)
		net2PinPair = GetPinPairOfNet( net2)
		unless( eq( car( net1PinPair)->parent car( net2PinPair)->parent) (net2PinPair = reverse( net2PinPair)))
		pin1Left = car( net1PinPair)
		pin1Right = cadr( net1PinPair)
		pin2Left = car( net2PinPair)
		pin2Right = cadr( net2PinPair)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		FillUpFormClineSeg( outForm pin1Left pin1Right pin2Left pin2Right cline1Layer cline2Layer)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; fillin net group
		
		FillUpFormNetGroup( outForm pin1Left pin1Right pin2Left pin2Right)
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; fillin cline group
		
		FillUpFormClineGroup( outForm clineSeg1 clineSeg2 pin1Left pin1Right pin2Left pin2Right)
		
		
		t
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of form

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; function

procedure( GetFirstFloatInString( valueString)
	prog( ( valueFloat)
		unless( stringp( valueString) return( 0.0))
		
		rexCompile( "\\([0-9]*[.]*[0-9]*\\)")
		unless( rexExecute( valueString) return( 0.0))
		
		valueFloat = rexSubstitute( "\\0")
		valueFloat = atof( valueFloat)
		
		
		return( valueFloat)
	)
)

procedure( WriteLog( lineList @optional (writeInCommand nil))
	prog( ( outPort)
		unless( dtpr( lineList) (lineList = list( lineList)))
		
		outPort = outfile( _logFileName "a")
		unless( outportp( outPort) println( "Fail to write file") return( nil))
		foreach( line lineList fprintf( outPort "%s\n" line))
		close( outPort)
		
		when( writeInCommand
			foreach( line lineList printf( "%s\n" line))
		)
		
		return( t)
	)
)

procedure( GetClineSegOnPin( layer pinId)
	; pinId = car( axlGetSelSet())
	prog( ( clineList xyPin segments segId clineSegId)
		clineList = axlDBGetConnect( pinId)
		unless( onep( length( clineList)) printf( "Warning: The number of cline on pin[%s] is not 1\n" axlDbidName( pinId)) return( nil))
		
		;;;
		xyPin = pinId->xy
		
		segments = car( clineList)->segments
		while( and( null( clineSegId) dtpr( segments))
			segId = car( segments)
			when( exists( x segId and( axlGeoPointsEqual( xyPin x->xy) equal( layer x->layer)))
				clineSegId = segId
			)
			
			segments = cdr( segments)
		)
		
		
		return( clineSegId)
	)
)

procedure( GetAreaOf3Points( xyA xyB xyC)
	prog( ( vectorAB vectorAC area)
		vectorAB = axlMXYSub( xyB xyA)
		vectorAC = axlMXYSub( xyC xyA)
		
		;;; vector A Cross vector B = distance A * distance B * sin()
		;;; result = Ax * By - Ay * Bx
		area = car( vectorAB) * cadr( vectorAC) - cadr( vectorAB) * car( vectorAC)
		area = abs( area)
		
		return( area)
	)
)

procedure( GetVectorOfSlope( xyStart xyEnd xyAnotherStartEnd amplitude isGoToCrest)
	prog( ( uniVector xyAnotherStart xyAnotherEnd xyFinal xyFinal1 xyFinal2 area1 area2 xyFinal uniVectorFinal)
		uniVector = axlMXYMult( axlMUniVector( xyStart xyEnd) (amplitude * axlSQRT2))
		xyFinal = axlMXYAdd( xyStart uniVector)
		xyFinal1 = axlGeoRotatePt( 45.0 xyFinal xyStart)
		xyFinal2 = axlGeoRotatePt( -45.0 xyFinal xyStart)
		
		xyAnotherStart = car( xyAnotherStartEnd)
		xyAnotherEnd = cadr( xyAnotherStartEnd)
		area1 = GetAreaOf3Points( xyAnotherStart xyAnotherEnd xyFinal1)
		area2 = GetAreaOf3Points( xyAnotherStart xyAnotherEnd xyFinal2)
		
		if( isGoToCrest then
			;;;; go way from origin cline segment, the final xy should be the further point from another line
			;;;; on the othe hand, getting a larger area
			xyFinal = if( (area1 > area2) xyFinal1 xyFinal2)
		else
			;;;; go back to origin cline segment from crest, should be closer point  from another line
			;;;; on the other hand, getting a smaller area
			xyFinal = if( (area1 < area2) xyFinal1 xyFinal2)
		)
		uniVectorFinal = axlMXYSub( xyFinal xyStart)
		
		return( uniVectorFinal)
	)
)

procedure( createClineSegList( clineSegXYList shortClineSegEnd anotherClineSeg numberOfBump amplitude vectorBump vector3W)
	prog( ( xyAnotherStartEnd uniVectorGo uniVectorBack xyStart xyCrest1 xyCrest2 xyEnd )
		xyAnotherStartEnd = anotherClineSeg->startEnd
		
		shortClineSegStart = lastelem( clineSegXYList)
		uniVectorGo = GetVectorOfSlope( shortClineSegStart shortClineSegEnd xyAnotherStartEnd amplitude t)
		uniVectorBack = GetVectorOfSlope( shortClineSegStart shortClineSegEnd xyAnotherStartEnd amplitude nil)
		
		;;;;;
		xyStart = axlMXYAdd( shortClineSegStart vector3W)
		for( thOfBump 1 numberOfBump
			xyCrest1 = axlMXYAdd( xyStart uniVectorGo)
			xyCrest2 = axlMXYAdd( xyCrest1 vector3W)
			xyEnd = axlMXYAdd( xyCrest2 uniVectorBack)
			clineSegXYList = append( clineSegXYList list( xyStart xyCrest1 xyCrest2 xyEnd))
			
			;;;; go to next wave
			xyStart = axlMXYAdd( xyEnd vector3W)
		)
		
		
		return( clineSegXYList)
	)
)

procedure( DeleteClineSegCreateClineReturnClineSegList( clineSeg clineSegXYList)
	prog( ( layer netName path ClineId clineSegList startEnd isGetSeg)
		layer = clineSeg->layer
		netName = clineSeg->net->name
		
		;;;; remove old cline segment
		axlDeleteObject( clineSeg)
		
		;;;;
		path = axlPathStart( clineSegXYList _lineWidth)
		ClineId = caar( axlDBCreatePath( path layer netName))
		
		;;;;
		startEnd = list( car( clineSegXYList) lastelem( clineSegXYList))
		foreach( segId ClineId->segments
			when( exists( xy segId->startEnd exists( se startEnd axlGeoPointsEqual( xy se)))
				;;;; get the last one
				when( isGetSeg
					clineSegList = append1( clineSegList segId)
				)
				
				;;;; switch the status of getting seg
				isGetSeg = not( isGetSeg)
			)
			when( isGetSeg
				;;;; getting from first match
				clineSegList = append1( clineSegList segId)
			)
		)
		
		
		return( clineSegList)
	)
)

procedure( GetShortClineSegFromSelected2ClineSeg()
	prog( ( shortClineSeg anotherClineSeg)
		if( equal( _tuneType _formKeyTuneForNet) then
			if( (_net1Total < _net2Total) then
				shortClineSeg = car( _selected2ClineSeg)
				anotherClineSeg = cadr( _selected2ClineSeg)
			else
				shortClineSeg = cadr( _selected2ClineSeg)
				anotherClineSeg = car( _selected2ClineSeg)
			)
		else
			if( (_cline1Total < _cline2Total) then
				shortClineSeg = car( _selected2ClineSeg)
				anotherClineSeg = cadr( _selected2ClineSeg)
			else
				shortClineSeg = cadr( _selected2ClineSeg)
				anotherClineSeg = car( _selected2ClineSeg)
			)
		)
		printf( "\tInfo: Shorter net[%s]\n" shortClineSeg->net->name)
		printf( "\tInfo: Another net[%s]\n" anotherClineSeg->net->name)
		
		
		return( shortClineSeg)
	)
)

procedure( GetDeltaDistance()
	prog( ( deltaDistance)
		if( equal( _tuneType _formKeyTuneForNet)
			deltaDistance = abs( _net1Total - _net2Total)
			deltaDistance = abs( _cline1Total - _cline2Total)
		)
		printf( "    Final: The mismatch of diffpair is [%f]\n" deltaDistance)
		
		unless( (deltaDistance > _lengthMatchTolerance)
			printf( "\tInfo: The mismatch of 2 net/cline is [%f] within [%f]. The cline segment would not be tuned\n" deltaDistance _lengthMatchTolerance)
			return( nil)
		)
		
		
		return( deltaDistance)
	)
)

procedure( UpdateSelected2ClineSeg( clineSegId)
	let( ()
		if( stringp( car( _selected2ClineSeg)->objType)
			_selected2ClineSeg = list( car( _selected2ClineSeg) clineSegId)
			_selected2ClineSeg = list( clineSegId cadr( _selected2ClineSeg))
		)
	)
)

procedure( Tune2ClineSeg()
	prog( ( shortClineSeg anotherClineSeg deltaDistance)
		;;;;; get a shorter cline segment for tuning and another cline segment for positioning bumps
		shortClineSeg = GetShortClineSegFromSelected2ClineSeg()
		
		;;;; get delta between 2 cline segment
		deltaDistance = GetDeltaDistance()
		unless( deltaDistance return( nil))
		
		;;;; 
		shortClineSegStart = car( shortClineSeg->startEnd)
		shortClineSegEnd = cadr( shortClineSeg->startEnd)
		shortClineSegLength = axlDistance( shortClineSegStart shortClineSegEnd)
		
		;;;; the slope of side of bump is always 45 degree. So, the total length of a bump is 1 length + 2 side of delta height
		bumpLength = _maxBumpLength + (_maxBumpHeight - _lineSpacing) * 2
		waveLength = bumpLength + _maxBumpLength
		
		;;;; remove head(3w) and tail(3w) from cline segment and then divide by 
		maxNumberOfBump = int( (shortClineSegLength - _maxBumpLength) / waveLength)
		when( (maxNumberOfBump > _maxNumberOfBump) (maxNumberOfBump = _maxNumberOfBump))
		when( (maxNumberOfBump < 1)
			printf( "Warning: The length of cline segment has to be longer then (wave + lengthOfBump)[%f] to add bumps. Current cline segment [%f]\n"
				(waveLength + _maxBumpLength) shortClineSegLength)
			return( t)
		)
		printf( "\tInfo: The length of a wave is less than [%f]\n" waveLength)
		
		fullCompensateLength = (_maxBumpHeight - _lineSpacing) * (axlSQRT2 - 1) * 2
		printf( "\tInfo: A full bump can compansate length in [%f]\n" fullCompensateLength)
		printf( "\tInfo: Maximum number of bump can be added on cline segment[%s] is [%d]\n" shortClineSeg->net->name maxNumberOfBump)
		
		;;;;; get the number of full bump and fit bump
		numberOfFullBump = int( deltaDistance / fullCompensateLength)
		fitCompensateLength = deltaDistance - numberOfFullBump * fullCompensateLength
		when( (fitCompensateLength <= _lengthMatchTolerance) (fitCompensateLength = 0.0))
		
		cond(
			( (numberOfFullBump > maxNumberOfBump)
				printf( "\tInfo: Need to select a new cline segment for length matching. Require additional full bump[%d]\n"
					(numberOfFullBump - maxNumberOfBump))
				
				numberOfFullBump = maxNumberOfBump
				numberOfFitBump = 0
			)
			( and( (numberOfFullBump == maxNumberOfBump) not( zerop( fitCompensateLength)))
				numberOfFitBump = 0
				
				println( "\tInfo: Need to select a new cline segment for length matching. Require to compensate[%f]\n" fitCompensateLength)
			)
			( and( (numberOfFullBump < maxNumberOfBump) not( zerop( fitCompensateLength)))
				numberOfFitBump = 1
				
				printf( "\tInfo: Creating full bump[%d] and fit bump[%d]. Require 1 fit bump to compensate[%f]\n" numberOfFullBump numberOfFitBump fitCompensateLength)
			)
			( t
				numberOfFitBump = 0
				
				printf( "\tInfo: Creating full bump[%d]\n" numberOfFullBump)
			)
		)
		println( "Start to tune")
		
		;;;;; create bump
		anotherClineSeg = car( remq( shortClineSeg _selected2ClineSeg))
		uniVectorShortClineSeg =  axlMUniVector( shortClineSegStart shortClineSegEnd)
		vectorFullBump = axlMXYMult( uniVectorShortClineSeg bumpLength)
		vectorFitBump = axlMXYMult( uniVectorShortClineSeg (_maxBumpLength + fitCompensateLength))
		vector3W = axlMXYMult( uniVectorShortClineSeg _maxBumpLength)
		
		clineSegXYList = list( shortClineSegStart)
		
		amplitude = _maxBumpHeight - _lineSpacing
		clineSegXYList = createClineSegList( clineSegXYList shortClineSegEnd anotherClineSeg
			numberOfFullBump amplitude vectorFullBump vector3W)
		
		amplitude = fitCompensateLength / 2 / (axlSQRT2 - 1)
		clineSegXYList = createClineSegList( clineSegXYList shortClineSegEnd anotherClineSeg
			numberOfFitBump amplitude vectorFitBump vector3W)
		
		clineSegXYList = append1( clineSegXYList shortClineSegEnd)
		
		printf( "\tInfo: Creating a bump at %L\n" clineSegXYList)
		clineSegList = DeleteClineSegCreateClineReturnClineSegList( shortClineSeg clineSegXYList)
		
		;;;;; fill back the _selected2ClineSeg data
		UpdateSelected2ClineSeg( lastelem( clineSegList))
		
		
		return( t)
	)
)

procedure( SelectPinsClineSegs( outForm)
	; a = car( axlGetSelSet())
	prog( ( filterOptionList selectedObjList outList outListLen clineSegListLen mode)
		filterOptionList = list( "NOALL" "PINS" "CLINESEGS")
		axlSetFindFilter( ?enabled filterOptionList ?onButtons filterOptionList)
		
		;;;;;
		while( axlSelect()
			println( "Please Select pair of cline segments to do equalization, otherwise, select 2 pins and at least a cline segments to do the pin delay adjustment")
			selectedObjList = axlGetSelSet()
			outList = setof( x selectedObjList equal( "pin" x->objType))
			_selected2ClineSeg = setof( x selectedObjList equal( "line" x->objType))
			
			outListLen = length( outList)
			clineSegListLen = length( _selected2ClineSeg)
			
			println( "============================================================================================================")
			cond(
				( and( eqv( 2 outListLen) plusp( clineSegListLen))
					println( "This section is used to adjust pin delay")
					_equalizerMode = _equalizerTunePinDelay
					
					layer = car( _selected2ClineSeg)->layer
					clineSeg1 = GetClineSegOnPin( layer car( outList))
					clineSeg2 = GetClineSegOnPin( layer cadr( outList))
					if( and( clineSeg1 clineSeg2 eq( clineSeg1->net->diffpair clineSeg2->net->diffpair)) then
						_selected2ClineSeg = list( clineSeg1 clineSeg2)
						_selected2Out = outList
						FillUpForm( outForm)
					else
						println( "Warning: The net connected these 2 pins are not in same diffpair")
						_selected2ClineSeg = _selected2Out = nil
					)
				)
				( and( zerop( outListLen) eqv( 2 clineSegListLen))
					println( "This section is used to do equalize")
					_equalizerMode = _equalizerTuneBump
					
					FillUpForm( outForm)
				)
				( t
					printf( "The composition of the selected objectives is not correct\n\tNumber of pin/via: %d\n\tNumber of cline segments: %d\n"
						outListLen clineSegListLen)
					_equalizerMode = _equalizerNone
					_selected2ClineSeg = nil
				)
			)
			axlFormSetField( outForm _formKeyEqualizerMode _equalizerMode)
		)
		println( "The selection process is done")
		
		;;;;;
		filterOptionList = list( "NOALL")
		axlSetFindFilter( ?enabled filterOptionList ?onButtons filterOptionList)
		axlClearSelSet()
		
		
		t
	)
)

procedure( diffpairEualizerMain()
	prog( ()
		unless( axlOKToProceed() println( "Please finish current command to use this function") return( nil))
		
		init()
		
		;;;;; check
		
		unless( isFile( _bmpPinDelayDiagram1) printf( "ERROR: Fail to get file [%s]\n" _bmpPinDelayDiagram1) return( nil))
		unless( isFile( _bmpPinDelayDiagram2) printf( "ERROR: Fail to get file [%s]\n" _bmpPinDelayDiagram2) return( nil))
		unless( isFile( _bmpPinDelayDiagram3) printf( "ERROR: Fail to get file [%s]\n" _bmpPinDelayDiagram3) return( nil))
		unless( isFile( _bmpPinDelayDiagram4) printf( "ERROR: Fail to get file [%s]\n" _bmpPinDelayDiagram4) return( nil))
		unless( isFile( _bmpBumpDeployment) printf( "ERROR: Fail to get file [%s]\n" _bmpBumpDeployment) return( nil))
		
		;;;;; check
		
		WriteDiffpairEualizerForm()
		outForm = axlFormCreate( gensym() _formDiffpairEqualizerName '( "east" "outer") 'CallBackForm nil)
		SetForm( outForm)
		axlFormDisplay( outForm)
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup

(axlCmdRegister "diffpair_equalizer" 'diffpairEualizerMain)
;axlCancelEnterFun()
(diffpairEualizerMain)
; skill encrypt( "c:/skill/diffpair_equalizer_v1.il" "C:/skill/diffpair_equalizer_v1.ile")
; (load "diffpair_equalizer_v1.il")
; (load "diffpair_equalizer_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of setup