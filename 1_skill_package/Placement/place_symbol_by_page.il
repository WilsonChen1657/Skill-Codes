;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;
;Developer: Derek Hsu
;Starting Date: 12/18/2019
;Purpose:
;	1. group symbol by page. A symbol may have number of pages
;	2. place symbols into a white rectangle by its group, if and only if it has single group
;	3. upon the design_outline, the symbols with multiple page group will be placed in the first row
;	4. 1 page will be placed from left down to right-down on second row and ascent
;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( init()
	setq( _allegro_version axlVersion( 'version))
	setq( _allegro_unit car( axlDBGetDesignUnits()))
	setq( _layerPGPBT "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
	setq( _layerOutline if( (_allegro_version > 17) "BOARD GEOMETRY/DESIGN_OUTLINE" "BOARD GEOMETRY/OUTLINE"))
	
	setq( _groupType "generic")
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	setq( _functionTag "PLACESYMBOLBYPAGE")
	sprintf( _symGroupNameForm "%s_%%s" _functionTag)
	
	sprintf( _pageLayer "BOARD GEOMETRY/%s" _functionTag)
	unless( axlIsLayer( _pageLayer) axlLayerCreateNonConductor( _pageLayer))
	axlVisibleLayer( _pageLayer t)
	
	setq( _pageShapeProp list( 'CLIP_DRAWING _functionTag))
	setq( _pageTextForm "PAGE:%.3d")
	setq( _textBlock 8)
	
	sprintf( _sheetGroupName "%s_SHEET" _functionTag)
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	setq( _pageLength 3000)
	setq( _pageWidth 1600)
	setq( _pagePad 50)
	setq( _pageGap 100)
	setq( _pageMaxColNum 10)
	
	setq( _symbolGap 10)
	setq( _symbolAreaSplite if( equal( "mils" _allegro_unit) 200000 (200000 / 39.37)))
	
	setq( _outlineStartXY nil)
	setq( _pageStartXY nil)
	setq( _currentSymBotLeftX nil)
	setq( _currentSymBotLeftY nil)
	setq( _currentSymMaxX nil)
	setq( _currentSymMaxY nil)
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	setq( _toleranceOfSymArea if( equal( "mils" _allegro_unit) 10 (10 / 39.37)))
	setq( _totalPage nil)
	setq( _currentPage 0)
	
	
	t
)

procedure( GetCurrentSymMaxXY() list( _currentSymMaxX _currentSymMaxY))

procedure( SetCurrentSymMaxXY( x y @optional (toReset nil))
	prog( ()
		when( toReset
			when( numberp( x) (_currentSymMaxX = x))
			when( numberp( y) (_currentSymMaxY = y))
			
			return( t)
		)
		
		;;;;;
		when( numberp( x)
			unless( _currentSymMaxX (_currentSymMaxX = x))
			when( ( x > _currentSymMaxX) (_currentSymMaxX = x))
		)
		
		;;;;;
		when( numberp( y)
			unless( _currentSymMaxY (_currentSymMaxY = y))
			when( ( y > _currentSymMaxY) (_currentSymMaxY = y))
		)
		
		
		return( t)
	)
)

procedure( OffsetCurrentSymXY( moveX moveY @optional (offsetX 0) (offsetY 0))
	let( ( xy deltaX deltaY )
		xy = GetCurrentSymBotLeftXY()
		
		unless( moveX (moveX = 0))
		unless( moveY (moveY = 0))
		
		deltaX = moveX + offsetX
		deltaY = moveY + offsetY
		
		xy = axlMXYAdd( xy list( deltaX deltaY))
		SetCurrentSymBotLeftXY( xy)
	)
)

procedure( SetCurrentSymBotLeftXY( xy @optional (offsetX 0) (offsetY 0))
	let( ()
		_currentSymBotLeftX = car( xy) + offsetX
		_currentSymBotLeftY = cadr( xy) + offsetY
	)
)

procedure( GetCurrentSymBotLeftXY()
	prog( ( xy)
		xy = list( _currentSymBotLeftX _currentSymBotLeftY)
		
		
		return( xy)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( GetPageFromSym( symId toString)
	; physicalPath = "@bt_evt_sib_sas3_ee_sch_v41_20191104.bluetail_sib_sas3_sch(sch_1):page48_ins24033300@other.\\m_hole_c.normal\\(chips)"
	prog( ( pageList physicalPath page )
		rexCompile( ":page\\([0-9]+\\)_")
		foreach( func symId->component->functions
			physicalPath = func->prop~>PHYSICAL_PATH
			when( rexExecute( physicalPath)
				page = rexSubstitute( "\\1")
				unless( toString (page = atoi( page)))
				pageList = append1( pageList page)
			)
		)
		
		;;;;; remove duplicate
		pageList = maplist( lambda( (x) unless( memv( car( x) cdr( x)) car( x))) pageList)
		pageList = remq( nil pageList)
		
		
		return( pageList)
	)
)

procedure( AddToGroup( groupName objectList)
	prog( ( groupId)
		unless( objectList return( nil))
		unless( dtpr( objectList) (objectList = list( objectList)))
		
		groupId = car( setof( g axlDBGetDesign()->groups equal( groupName g->name)))
		if( groupId then
			axlDBAddGroupObjects( groupId objectList)
		else
			groupId = axlDBCreateGroup( groupName _groupType objectList)
		)
		
		axlDBRefreshId( groupId)
		
		
		return( groupId)
	)
)

procedure( GroupSymbolByPageReturnTable( symList)
	prog( ( groupTable pageList pageString groupName symInPageList )
		groupTable = makeTable( 'placeSymbolByPage nil)
		
		foreach( symId symList
			pageList = GetPageFromSym( symId nil)
			
			foreach( page pageList
				groupTable[ page] = append1( groupTable[ page] symId)
			)
		)
		
		foreach( page groupTable
			sprintf( pageString "%d" page)
			sprintf( groupName _symGroupNameForm pageString)
			symInPageList = groupTable[ page]
			
			AddToGroup( groupName symInPageList)
		)
		
		
		return( groupTable)
	)
)

procedure( GetSymWithMultiGroup( symList)
	prog( ( symWithMultiGroupList groupNameList)
		foreach( symId symList
			groupNameList = symId->parentGroups~>name
			pageList = GetPageFromSym( symId t)
			
			when( ( length( pageList) > 1)
				;;;; re-assign group
				pagePostfix = buildString( pageList "_")
				sprintf( groupName _symGroupNameForm pagePostfix)
				RemoveSymFromGroup( symId)
				AddToGroup( groupName symId)
				
				;;;;;
				symWithMultiGroupList = append1( symWithMultiGroupList symId)
			)
		)
		
		symWithMultiGroupList = sort( symWithMultiGroupList 'SortSymList)
		
		
		return( symWithMultiGroupList)
	)
)

procedure( GetSymArea( symId)
	prog( ( shapeList areaList area)
		shapeList = GetShapeListFromSym( symId)
		areaList = mapcar( 'GetAreaFromObject shapeList)
		
		area = 0
		foreach( a areaList (area = area + a))
		
		
		return( area)
	)
)

procedure( GetSymTooBig( symList)
	; symId = car( axlGetSelSet())
	prog( ( symTooBigList shapeId area)
		foreach( symId symList
			area = GetSymArea( symId)
			
			when( (area > _symbolAreaSplite)
				symTooBigList = append1( symTooBigList symId)
			)
		)
		
		symTooBigList = sort( symTooBigList 'SortSymList)
		
		
		return( symTooBigList)
	)
)

procedure( GetXyListFromObject( objectId)
	prog( ( path segList xyEnd xyList)
		if( and( onep( objectId->nSegs) car( objectId->segments)->isCircle) then
			radius = car( objectId->segments)->radius
			xyCenter = car( objectId->segments)->xy
			xy1 = axlMXYAdd( xyCenter list( 0 radius))
			xy2 = axlMXYSub( xyCenter list( 0 radius))
			xyList = list( xy1 xy2)
		else
			path = axlDB2Path( objectId)
			segList = axlPathGetPathSegs( path)
			foreach( segId segList
				when( equal( "arc" segId->objType)
					xyEnd = axlPathSegGetArcCenter( segId)
					xyList = append1( xyList xyEnd)
				)
				xyEnd = axlPathSegGetEndPoint( segId)
				xyList = append1( xyList xyEnd)
			)
		)
		
		unless( dtpr( xyList) println( "ERROR: GetXyListFromObject() - Fail to get xy list") return( nil))
		
		return( xyList)
	)
)

procedure( GetAreaFromObject( objectId)
	; https://www.wikihow.com/Calculate-the-Area-of-a-Polygon
	; xyList = list( list( -3 -2) list( -1 4) list(6 1) list( 3 10) list(-4 9))
	; objectId = car( axlGetSelSet())
	prog( ( xyList countOfRow diameter radius multiplyXbyYProduction multiplyYbyXProduction area)
		xyList = GetXyListFromObject( objectId)
		countOfRow = sub1( length( xyList))
		
		;;;;; circle
		when( onep( countOfRow)
			diameter = axlDistance( car( xyList) cadr( xyList))
			radius = diameter / 2
			area = radius * radius * axlPI
			
			return( area)
		)
		
		;;;;; irregular ploygon
		xyList = append1( xyList car( xyList))
		
		multiplyXbyYProduction = 0
		for( i 0 countOfRow
			production = car( nth( i xyList)) * cadr( nth( add1( i) xyList))
			multiplyXbyYProduction = multiplyXbyYProduction + production
		)
		
		multiplyYbyXProduction = 0
		for( i 0 countOfRow
			production = cadr( nth( i xyList)) * car( nth( add1( i) xyList))
			multiplyYbyXProduction = multiplyYbyXProduction + production
		)
		
		area = (multiplyXbyYProduction - multiplyYbyXProduction) / 2
		area = abs( area)
		
		
		return( area)
	)
)

procedure( GetShapeListFromSym( symId)
	; symId = car( axlGetSelSet())
	prog( ( shapeList)
		shapeList = setof( c symId->children equal( "shape" c->objType))
		shapeList = setof( s shapeList equal( _layerPGPBT s->layer))
		
		
		return( shapeList)
	)
)

procedure( GetTopLeftXY( xyList)
	prog( ( diameter radius xyCenter xList yList xMin yMax xy)
		unless( dtpr( xyList) return( nil))
		;;;
		
		cond(
			( eqv( 2 length( xyList))
				diameter = axlDistance( car( xyList) cadr( xyList))
				radius = diameter / 2
				xyCenter = axlMidPointLine( xyList)
				
				xy = axlMXYAdd( xyCenter list( -radius radius))
			)
			( ( length( xyList) > 2)
				;;;; polygon
				xList = mapcar( 'car xyList)
				yList = mapcar( 'cadr xyList)
				
				xMin = apply( 'min xList)
				yMax = apply( 'max yList)
				
				xy = list( xMin yMax)
			)
			( t
				printf( "ERROR: GetTopLeftXY() - Fail to identify xyList: %L\n" xyList)
				return( nil)
			)
		)
		
		
		return( xy)
	)
)

procedure( GetBotRightXY( xyList)
	prog( ( radius  xyCenter xList yList xMax yMin xy)
		unless( dtpr( xyList) return( nil))
		;;;
		
		cond(
			( eqv( 2 length( xyList))
				diameter = axlDistance( car( xyList) cadr( xyList))
				radius = diameter / 2
				xyCenter = axlMidPointLine( xyList)
				
				xy = axlMXYAdd( xyCenter list( radius -radius))
			)
			( ( length( xyList) > 2)
				xList = mapcar( 'car xyList)
				yList = mapcar( 'cadr xyList)
				
				xMax = apply( 'max xList)
				yMin = apply( 'min yList)
				
				xy = list( xMax yMin)
			)
			( t
				printf( "ERROR: GetBotRightXY() - Fail to identify xyList: %L\n" xyList)
				return( nil)
			)
		)
		
		
		return( xy)
	)
)

procedure( GetOutlineXyList()
	prog( ( shapeList visibleList xyList lineList)
		;;;;; get shape on outline
		shapeList = axlDBGetShapes( _layerOutline)
		when( dtpr( shapeList)
			shapeList = sort( shapeList lambda( ( a b) ( GetAreaFromObject( a) > GetAreaFromObject( b))))
			xyList = GetXyListFromObject( car( shapeList))
			
			return( xyList)
		)
		
		;;;;; get line on outline
		visibleList = axlVisibleGet()
		axlVisibleDesign( nil)
		axlVisibleLayer( _layerOutline t)
		axlSetFindFilter( ?enabled list( "NOALL" "LINES") ?onButtons list( "NOALL" "LINES"))
		axlAddSelectAll()
		lineList = axlGetSelSet()
		axlClearSelSet()
		axlSetFindFilter( ?enabled list( "NOALL") ?onButtons list( "NOALL"))
		axlVisibleSet( visibleList)
		
		lineList = sort( lineList lambda( (a b) ( GetAreaFromObject( a) > GetAreaFromObject( b))))
		xyList = GetXyListFromObject( car( lineList))
		
		
		return( xyList)
	)
)

procedure( GetOutlineStartXy()
	prog( ( xyList xy)
		xyList = GetOutlineXyList()
		xy = GetTopLeftXY( xyList)
		xy = axlMXYAdd( xy list( 0 _pageGap))
		
		
		return( xy)
	)
)

procedure( GetSymCenter( symId)
	prog( ( shapeList xyList xyTopLeft xyBotRight xySymCenter)
		shapeList = GetShapeListFromSym( symId)
		xyList = mapcan( 'GetXyListFromObject shapeList)
		xyTopLeft = GetTopLeftXY( xyList)
		xyBotRight = GetBotRightXY( xyList)
		
		xySymCenter = axlMidPointLine( list( xyTopLeft xyBotRight))
		
		
		return( xySymCenter)
	)
)

procedure( GetFinalSymXyFromBotLeft( symId)
	;;; symId = car( axlGetSelSet())
	prog( ( shapeId xyList xyTopLeft xyBotRight currentXY objectiveWidth objectiveHeight
			xMax yMax offsetX xySymCenter vectorCenterToOrigin xy xyFinal)
		shapeList = GetShapeListFromSym( symId)
		xyList = mapcan( 'GetXyListFromObject shapeList)
		xyTopLeft = GetTopLeftXY( xyList)
		xyBotRight = GetBotRightXY( xyList)
		
		xySymCenter = GetSymCenter( symId)
		vectorCenterToOrigin = axlMXYSub( symId->xy xySymCenter)
		
		objectiveWidth = abs( car( xyTopLeft) - car( xyBotRight))
		objectiveHeight = abs( cadr( xyTopLeft) - cadr( xyBotRight))
		currentXY = GetCurrentSymBotLeftXY()
		xyFinal = axlMXYAdd( currentXY list( ( objectiveWidth / 2) ( objectiveHeight / 2)))
		xyFinal = axlMXYAdd( xyFinal vectorCenterToOrigin)
		
		;;;; set current max y for moving row upon
		xMax = car( currentXY) + objectiveWidth
		yMax = cadr( currentXY) + objectiveHeight
		SetCurrentSymMaxXY( xMax yMax)
		
		;;;;; it has to be the last step, otherwise, the current xy would be shifted
		offsetX = objectiveWidth + _symbolGap
		OffsetCurrentSymXY( offsetX nil)
		
		
		return( xyFinal)
	)
)

procedure( TransformSym( symId xySymFinal angle)
	let( ( deltaXY xySymCenter)
		when( symId->isMirrored
			axlDBCloak( 'axlTransformObject( symId ?mirror t))
		)
		
		unless( axlGeoPointsEqual( xySymFinal symId->xy)
			deltaXY = axlMXYSub( xySymFinal symId->xy)
			axlDBCloak( 'axlTransformObject( symId ?move deltaXY))
		)
		
		unless( zerop( angle)
			xySymCenter = GetSymCenter( symId)
			axlDBCloak( 'axlTransformObject( symId ?angle angle ?origin xySymCenter))
		)
		
		
		t
	)
)

procedure( PlaceSymList( symList @optional (isInPage nil))
	let( ( symStartX symEndX xy xySymFinal previousSymMaxXY currentSymMaxXY)
		when( isInPage
			symStartX = car( GetCurrentSymBotLeftXY())
			symEndX = symStartX + _pageWidth - _pagePad - _pagePad
		)
		
		foreach( symId symList
			previousSymMaxXY = GetCurrentSymMaxXY()
			xySymFinal = GetFinalSymXyFromBotLeft( symId)
			currentSymMaxXY = GetCurrentSymMaxXY()
			
			when( and( isInPage ( car( currentSymMaxXY) > symEndX))
				SetCurrentSymMaxXY( symStartX cadr( previousSymMaxXY) t)
				
				xy = list( symStartX ( cadr( previousSymMaxXY) + _symbolGap))
				SetCurrentSymBotLeftXY( xy)
				
				xySymFinal = GetFinalSymXyFromBotLeft( symId)
			)
			
			TransformSym( symId xySymFinal 0.0)
		)
	)
)

procedure( UpdateGroupTable( groupTable symList)
	prog( ( symInGroupList)
		foreach( page groupTable
			symInGroupList = groupTable[ page]
			symInGroupList = setof( s symInGroupList memq( s symList))
			
			groupTable[ page] = symInGroupList
		)
		
		
		return( groupTable)
	)
)

procedure( CreateVoidShape( xyBotLeft xyTopRight)
	prog( ( xyTopLeft xyBotRight xyList path shapeId)
		xyTopLeft = list( car( xyBotLeft) cadr( xyTopRight))
		xyBotRight = list( car( xyTopRight) cadr( xyBotLeft))
		xyList = list( xyTopLeft xyTopRight xyBotRight xyBotLeft xyTopLeft)
		
		path = axlPathStart( xyList)
		
		shapeId = car( axlDBCreateShape( path nil _pageLayer))
		
		
		return( shapeId)
	)
)

procedure( CreateText( text xy justify)
	prog( ( textOrient textId)
		textOrient = make_axlTextOrientation( ?textBlock _textBlock ?rotation 0.0 ?mirrored nil ?justify justify)
		textId = caar( axlDBCreateText( text xy textOrient _pageLayer))
		
		
		return( textId)
	)
)

procedure( CreatePageText( page xy)
	prog( ( paramName textParam textXY pageText textId)
		sprintf( paramName "paramTextBlock:%d" _textBlock)
		textParam = axlGetParam( paramName)
		textXY = axlMXYSub( xy list( _pagePad (textParam->height + _pagePad)))
		
		sprintf( pageText _pageTextForm page)
		textId = CreateText( pageText textXY "right")
		
		
		return( textId)
	)
)

procedure( GetMaxPageInGroupTable( groupTable)
	prog( ( pageList pageMax)
		pageList = groupTable->?
		
		when( zerop( pageList)
			println( "ERROR: Fail to get total page")
			return( nil)
		)
		when( onep( pageList) return( car( pageList)))
		pageMax = apply( 'max groupTable->?)
;		println( "test 1")
;		pageMax = 13
		
		return( pageMax)
	)
)

procedure( CreateSheetOfPage( groupTable)
	let( ( colCount pageMax xyCurrentPageBotLeft deltaX deltaY xyCurrentPageTopRight shapeId textId)
		colCount = 0
		pageMax = GetMaxPageInGroupTable( groupTable)
		xyCurrentPageBotLeft = _pageStartXY
		
		deltaX = _pageWidth + _pageGap
		deltaY = _pageLength + _pageGap
		
		for( page 1 pageMax
			when( dtpr( groupTable[ page])
				xyCurrentPageTopRight = axlMXYAdd( xyCurrentPageBotLeft list( _pageWidth _pageLength))
				;;;;; create void shape
				shapeId = CreateVoidShape( xyCurrentPageBotLeft xyCurrentPageTopRight)
				
				;;;;; create page text
				textId = CreatePageText( page xyCurrentPageTopRight)
				
				;;;;; add to group
				AddToGroup( _sheetGroupName list( shapeId textId))
				
				;;;; shift to next
				if( colCount++ < _pageMaxColNum then
					xyCurrentPageBotLeft = axlMXYAdd( xyCurrentPageBotLeft list( deltaX 0))
				else
					colCount = 0
					xyCurrentPageBotLeft = list( car( _pageStartXY) ( cadr( xyCurrentPageBotLeft) + deltaY))
				)
			)
		)
		
		
		t
	)
)

procedure( RemoveSheetOfPage()
	let( ( groupId)
		groupId = car( setof( g axlDBGetDesign()->groups equal( _sheetGroupName g->name)))
		axlDeleteObject( groupId->groupMembers)
	)
)

procedure( PlaceSymByPage( groupTable)
	let( ( xyCurrentPageBotLeft pageMax pageDeltaX pageDeltaY colCount symInGroupList )
		xyCurrentPageBotLeft = _pageStartXY
		SetCurrentSymBotLeftXY( xyCurrentPageBotLeft _pagePad _pagePad)
		
		pageMax = GetMaxPageInGroupTable( groupTable)
		pageDeltaX = _pageWidth + _pageGap
		pageDeltaY = _pageLength + _pageGap
		
		colCount = 0
		;; --------------------------------------------------------------------------------------------------------------------------------- 1 max
		for( page 1 pageMax
			symInGroupList = groupTable[ page]
			when( dtpr( symInGroupList)
				axlMeterUpdate( (100 * ++_currentPage) / _totalPage sprintf( nil "Place symbols on page [%d] (%d/%d)" page _currentPage _totalPage))
				SetCurrentSymMaxXY( car( xyCurrentPageBotLeft) cadr( xyCurrentPageBotLeft) t)
				
				PlaceSymList( symInGroupList t)
				
				;;;; shift to next
				if( colCount++ < _pageMaxColNum then
					xyCurrentPageBotLeft = axlMXYAdd( xyCurrentPageBotLeft list( pageDeltaX 0))
				else
					colCount = 0
					xyCurrentPageBotLeft = list( car( _pageStartXY) ( cadr( xyCurrentPageBotLeft) + pageDeltaY))
				)
				SetCurrentSymBotLeftXY( xyCurrentPageBotLeft _pagePad _pagePad)
			)
		)
	)
)

procedure( GetNetNameFromSym( symId)
	; symId = car( axlGetSelSet())
	; GetNetNameFromSym( car( axlGetSelSet()))
	prog( ( netNameList netName)
		netNameList = symId->pins~>net~>name
		netNameList = remove( "GND" netNameList)
		netNameList = remq( nil netNameList)
		
		when( zerop( length( netNameList)) return( "GND"))
		when( onep( length( netNameList)) return( car( netNameList)))
		
		netNameList = sort( netNameList lambda( ( a b)
			if( eqv( strlen( a) strlen( b)) onep( strcmp( a b)) ( strlen( a) < strlen( b)))))
		netName = car( netNameList)
		
		
		return( netName)
	)
)

procedure( SortSymList( symA symB)
	prog( ( areaA areaB netNameA netNameB result)
		;;;; put big symbol to the front
		areaA = GetSymArea( symA)
		areaB = GetSymArea( symB)
		when( ( abs( areaA - areaB) > _toleranceOfSymArea)
			result = areaA > areaB
			return( result)
		)
		
		;;; compare by net name
		netNameA = GetNetNameFromSym( symA)
		netNameB = GetNetNameFromSym( symB)
		
		result = onep( strcmp( netNameA netNameB))
		return( result)
	)
)

procedure( SortGroupTable( groupTable)
	prog( ( symInGroupList )
		foreach( page groupTable
			symInGroupList = groupTable[ page]
			symInGroupList = sort( symInGroupList 'SortSymList)
			groupTable[ page] = symInGroupList
		)
		
		
		return( groupTable)
	)
)

procedure( SelectSym()
	prog( ( optList popup symTotal symList optList)
		optList = list( "NOALL" "SYMBOLS")
		axlSetFindFilter( ?enabled optList ?onButtons optList)
		
		popup = axlUIPopupDefine( nil (list (list "Done" 'axlFinishEnterFun) (list "Cancel" 'axlCancelEnterFun)))
		axlUIPopupSet( popup)
		
		println( "Please select the symbols to group by page")
		while( axlSelect()
			symTotal = axlGetSelSetCount()
			symList = axlGetSelSet()
			printf( "Number of selected symbols [%d]\n" symTotal)
		)
		
		;;;;;
		axlClearSelSet()
		optList = list( "NOALL")
		axlSetFindFilter( ?enabled optList ?onButtons optList)
		
		
		return( symList)
	)
)

procedure( RemoveSymFromGroup( symId)
	let( ( groupList)
		groupList = axlDBGetGroupFromItem( symId _groupType)
		foreach( groupId groupList
			axlDBRemoveGroupObjects( groupId symId)
		)
		
		
		t
	)
)

procedure( placeSymbolByPageMain()
	prog( ()
		unless( axlOKToProceed() println( "Please done current command to use this function") return( nil))
		;;
		
		init()
		
		;;;;; Select symbol
		symList = axlDBGetDesign()->symbols
		;symList = SelectSym()
		
		;;;;; setup starting position
		_outlineStartXY = GetOutlineStartXy()
		unless( _outlineStartXY return( nil))
		SetCurrentSymBotLeftXY( _outlineStartXY)
		
		;;;;; group selected symbol by page
		foreach( symId symList RemoveSymFromGroup( symId))
		groupTable = GroupSymbolByPageReturnTable( symList)
		_totalPage = add1( GetMaxPageInGroupTable( groupTable))
		unless( _totalPage return( nil))
		printf( "Following pages will be processed: %L\n" sort( groupTable->? 'lessp))
		
		;;;;; get special symbol
		symWithMultiGroupList = GetSymWithMultiGroup( symList)
		printf( "The symbols existing in multiple pages: %L\n" symWithMultiGroupList~>name)
		symList = setof( s symList not( memq( s symWithMultiGroupList)))
		
		symTooBigList = GetSymTooBig( symList)
		printf( "The symbols are too bug to be in page: %L\n" symTooBigList~>name)
		symList = setof( s symList not( memq( s symTooBigList)))
		
		;;;;; creating meter
		axlMeterCreate( "Place sym meter" "Processing Page: " t)
		axlMeterUpdate( (100 * ++_currentPage) / _totalPage "Place big or having-multiple-group symbols")
		
		;;;;; place it to upon design_outline
		PlaceSymList( symWithMultiGroupList)
		PlaceSymList( symTooBigList)
		
		;;;;; sort out the current data
		groupTable = UpdateGroupTable( groupTable symList)
		groupTable = SortGroupTable( groupTable)
		
		;;;; set the starting point of the page
		_pageStartXY = list( car( _outlineStartXY) ( cadr( GetCurrentSymMaxXY()) + _pageGap))
		
		;;;;; starting to create page and so on
		RemoveSheetOfPage()
		CreateSheetOfPage( groupTable)
		println( "The sheet creating process is done")
		
		;;;;;
		PlaceSymByPage( groupTable)
		axlMeterDestroy()
		
		axlUIConfirm( "The process is done. Please check this out")
		
		
		return( t)
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(axlCmdRegister "placeSymbolByPage" 'placeSymbolByPageMain)
 (placeSymbolByPageMain)
; skill encrypt( "c:/skill/placeSymbolByPage_v1.il" "C:/skill/placeSymbolByPage_v1.ile")
; (load "placeSymbolByPage_v1.il")
; (load "placeSymbolByPage_v1.ile")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;