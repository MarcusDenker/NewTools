"
Lists all the debuggers available in the image, along with their rank (provided they always return the same rank regardless of the debug session). Also list all the debug sessions stored in DebugSessionStorage.
"
Class {
	#name : #DebuggerSelectorPresenter,
	#superclass : #SpPresenter,
	#instVars : [
		'debuggerList',
		'debuggerListToolBar',
		'debugSessionList',
		'debugSessionListToolBar',
		'storageLimitLabel',
		'storageLimitInputField',
		'shouldUpdateStorageLimitInputField'
	],
	#category : #'NewTools-DebuggerSelector-Core'
}

{ #category : #specs }
DebuggerSelectorPresenter class >> defaultSpec [
	^ SpPanedLayout newHorizontal
		add:
			(SpBoxLayout newVertical
				add: 'Debuggers' height: 20;
				add: #debuggerList;
				add: #debuggerListToolBar
					withConstraints: [ :cstr | cstr height: 35 ];
				yourself);
		add:
			(SpBoxLayout newVertical
				add:
					(SpBoxLayout newHorizontal
						add: 'Debug Sessions' width: 200;
						add:
							(SpBoxLayout newHorizontal
								add: #storageLimitLabel width: 80;
								add: #storageLimitInputField width: 70;
								yourself);
						yourself)
					height: 20;
				add: #debugSessionList;
				add: #debugSessionListToolBar
					withConstraints: [ :cstr | cstr height: 35 ];
				yourself);
		yourself
]

{ #category : #specs }
DebuggerSelectorPresenter class >> initialExtent [
	^ 750@300
]

{ #category : #'world menu' }
DebuggerSelectorPresenter class >> menuCommandOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'List Debuggers and Debug Sessions')
		parent: #Debugging;
		order: 3;
		help: 'Shows the list all available debuggers in the image, and all the stored debug sessions. Allows to open stored debug sessions with any debugger';
		iconName: #glamorousTable;
		action: [ self open ]
]

{ #category : #api }
DebuggerSelectorPresenter class >> open [
	<example>
	| windowPresenter presenter |
	presenter := self new.
	windowPresenter := presenter openWithSpec.
	windowPresenter whenClosedDo: presenter getWhenClosedBlock.
	windowPresenter window extent: self initialExtent.
	^ windowPresenter
]

{ #category : #specs }
DebuggerSelectorPresenter class >> title [
	^ 'Debuggers and Debug Sessions'
]

{ #category : #helpers }
DebuggerSelectorPresenter >> addCorrectMainDebuggerButtonToToolBar: aToolBar [
	debuggerList selectedItems
		ifNotEmpty: [ :debuggerList_ | 
			DebuggerSelector singleton mainDebuggerClass == (debuggerList_ at: 1)
				ifTrue:
					[ "A debugger is selected in the list, and it is the main debugger class, so we add a button allowing the user to remove this debugger from the main debugger class"
					aToolBar
						addItem:
							(SpToolBarButton new
								label: 'Main Debugger';
								icon: (self iconNamed: #checkboxSelected);
								action: [ DebuggerSelector singleton setNoMainDebuggerClass.
									self refreshDebuggerList.
									self refreshDebuggerListToolBar ];
								help: 'Set this debugger to no longer be the main debugger').
					^ self ] ].

	"Otherwise (no debugger is selected, or a debugger is selected and it is not the main debugger class), we add a buttont allowing to set the selected debugger as main debugger"
	aToolBar
		addItem:
			(SpToolBarButton new
				label: 'Main Debugger';
				icon: (self iconNamed: #checkboxUnselected);
				action: [ debuggerList selectedItems
						ifEmpty: [ self inform: 'You need to select a debugger' ]
						ifNotEmpty:
							[ :debuggerList_ | DebuggerSelector singleton mainDebuggerClass: (debuggerList_ at: 1) ].
					self refreshDebuggerList.
					self refreshDebuggerListToolBar ];
				help: 'Set this debugger to be the main debugger')
]

{ #category : #helpers }
DebuggerSelectorPresenter >> compareRank: rank1 to: rank2 [
	rank1 isInteger
		ifFalse: [ ^ false ].	"If rank1 is not an integer, (typically a string), then it is smaller than rank2"
	rank2 isInteger
		ifFalse: [ ^ true ].	"If rank2 is not an integer, (typically a string), then it is smaller than rank1"
	^ rank1 >= rank2	"Otherwise, both ranks are int, we return the result of their comparison"
]

{ #category : #'button action' }
DebuggerSelectorPresenter >> debugDebugSessionAction [
	"Describe the action performed by the 'Debug' button under the Debug Session List.
	Requires a debug session to be selected in the list of debug sessions. If this condition is not met, inform the user and stop.
	If it is met, select a debugger according to the same algorithm used by the image (see class DebuggerSelector) and debug the selected debug session with it"

	| debugSession |
	debugSession := (debugSessionList selectedItems
		ifEmpty: [ self inform: 'You must selected a Debug Session to debug'.
			^ self ]
		ifNotEmpty: [ :selectedItems | selectedItems at: 1 ]) debugSession.
	DebuggerSelector singleton
		selectAndOpenDebuggerFor: debugSession
		withNotification: nil
]

{ #category : #'button action' }
DebuggerSelectorPresenter >> debugDebugSessionWithSpecificDebuggerAction [
	"Describe the action performed by the 'Debug With' button under the Debug Session List.
	Requires a debug session to be selected in the list of debug sessions, and a debugger to be selected in the list of debuggers. If these conditions are not met, inform the user and stop.
	If they are met, tell the selected debugger to open the selected debug session"

	| debugSession debuggerClass |
	debugSession := (debugSessionList selectedItems
		ifEmpty: [ self inform: 'You must selected a Debug Session to debug'.
			^ self ]
		ifNotEmpty: [ :selectedItems | selectedItems at: 1 ]) debugSession.
	debuggerClass := debuggerList selectedItems
		ifEmpty: [ self inform: 'You must select a debugger'.
			^ self ]
		ifNotEmpty: [ :selectedItems | selectedItems at: 1 ].
	debuggerClass rankDebugSession: debugSession.	"Give debuggerClass a chance to signal the DebugSessionCannotBeOpenedByThisDebugger exception if it cannot open debugSession"
	debuggerClass
		openOn: debugSession
		withFullView: true
		andNotification: nil
]

{ #category : #'presenter building' }
DebuggerSelectorPresenter >> debugSessionList [
	| timeOfStorageColumnWidth refsColumnWidth |
	timeOfStorageColumnWidth := 115.
	refsColumnWidth := 40.

	^ self newTable
		addColumn: ((SpStringTableColumn
			title: 'Refs'
			evaluated: [ :aDebugSessionStorageUnit | 
				aDebugSessionStorageUnit debugSession
					countObjectsThatWantToKeepMeAlive asString ])
			width: refsColumnWidth;
			yourself);
		addColumn: (SpStringTableColumn
			title: 'Name'
			evaluated: [ :aDebugSessionStorageUnit | aDebugSessionStorageUnit debugSession name ]);
		addColumn: ((SpStringTableColumn
			title: 'Time of Storage'
			evaluated: [ :aDebugSessionStorageUnit | self printDateAndTime: aDebugSessionStorageUnit timeOfCreation ])
			width: timeOfStorageColumnWidth;
			yourself);
		sortingBlock: [ :dbSessionUnitStorage1 :dbSessionUnitStorage2 | 
			self
				sortDebugSessionUnitStorage: dbSessionUnitStorage1
				and: dbSessionUnitStorage2 ];
		yourself
]

{ #category : #helpers }
DebuggerSelectorPresenter >> debuggerClassToNameOfDebugger: aDebuggerClass [
	"Returns the name of @aDebuggerClass, to be displayed in the list of debuggers. If @aDebuggerClass is the main debugger defined in DebuggerSelector, return the name as a Text styled in bold"

	aDebuggerClass == DebuggerSelector singleton mainDebuggerClass
		ifTrue: [ ^ aDebuggerClass asString asText
				allBold;
				yourself ]
		ifFalse: [ ^ aDebuggerClass asString ]
]

{ #category : #helpers }
DebuggerSelectorPresenter >> debuggerClassToRankToDisplay: aDebuggerClass [
	"Returns what should be displayed as the rank of @aDebuggerClass.
	Since we do not have a debug session to give this debugger, we try with nil. If it answers a rank, we display it, if it raises an exception, we assume it really needed a debug session to give a rank, so we display a string explaining that.
	In addition, if @aDebuggerClass is the main debugger class (see class DebuggerSelector), then its ranks should be displayed in bold"

	| result |
	result := [ (aDebuggerClass rankDebugSession: nil) asString ]
		on: Exception
		do: [ 'Depends on the debug session' ].
	aDebuggerClass == DebuggerSelector singleton mainDebuggerClass
		ifTrue: [ ^ result asText allBold yourself ]
		ifFalse: [ ^ result ]
]

{ #category : #'presenter building' }
DebuggerSelectorPresenter >> debuggerList [
	^ self newTable
		addColumn: (SpStringTableColumn
			title: 'Rank'
			evaluated: [ :aDebuggerClass | self debuggerClassToRankToDisplay: aDebuggerClass ]);
		addColumn: (SpStringTableColumn
			title: 'Debugger'
			evaluated: [ :debuggerClass | self debuggerClassToNameOfDebugger: debuggerClass ]);
		whenSelectionChangedDo: [ self refreshDebuggerListToolBar ];
		yourself
]

{ #category : #helpers }
DebuggerSelectorPresenter >> getBlockTryingToGetRankOfDebugger [
	"Returns a block taking a debugger as argument and returning the rank it would give to a nil debug session. If an exception is raised, the debugger really needs the debug session object to give a rank, so the block returns a string saying that. If no exception is raised, it means the debugger did not need an actual debug session object to answer, the block directly return the returned value"

	^ [ :aDebugger | 
	[ aDebugger rankDebugSession: nil ]
		on: Exception
		do: [ 'Depends on the debug session' ] ]
]

{ #category : #helpers }
DebuggerSelectorPresenter >> getSortingBlock [
	| rankBlock |
	rankBlock := self getBlockTryingToGetRankOfDebugger.
	^ [ :aDebuggerClass1 :aDebuggerClass2 | 
		| rank1 rank2 |
		rank1 := rankBlock value: aDebuggerClass1.
		rank2 := rankBlock value: aDebuggerClass2.
		self compareRank: rank1 to: rank2 ]
]

{ #category : #helpers }
DebuggerSelectorPresenter >> getWhenClosedBlock [
	"Returns the block to be executed when the windows containing this presenter is closed by the user"

	^ [ self setInitialSubscriptions: false ]
]

{ #category : #initialization }
DebuggerSelectorPresenter >> initialize [
	shouldUpdateStorageLimitInputField := true
]

{ #category : #initialization }
DebuggerSelectorPresenter >> initializePresenters [
	debuggerList := self debuggerList.
	debuggerListToolBar := self newToolBar.
	debugSessionList := self debugSessionList.
	debugSessionListToolBar := self makeDebugSessionListToolbar.
	storageLimitLabel := self newLabel
		label: 'storage limit:';
		help: self storageLimitHelp;
		yourself.
	storageLimitInputField := self newNumberInput
		help: self storageLimitHelp;
		numberType: Integer;
		minimum: 1;
		number: DebugSessionStorage singleton storageLimitForDebugSessionsNotKeptAlive;
		whenNumberChangedDo: [ :newNumber | 
			"Disable the automatic refreshing of this value in the UI during the update of the value, to avoid infinite loop"
			shouldUpdateStorageLimitInputField := false.
			DebugSessionStorage singleton
				storageLimitForDebugSessionsNotKeptAlive: newNumber.
			shouldUpdateStorageLimitInputField := true.
			self ].
	self setInitialSubscriptions: true.

	self refreshDebuggerList.
	self refreshDebuggerListToolBar.
	self refreshDebugSessionList.

]

{ #category : #'presenter building' }
DebuggerSelectorPresenter >> makeDebugSessionListToolbar [
	^ self newToolBar
		addItem:
			(SpToolBarButton new label: 'Debug';
				icon: (self iconNamed: #glamorousBug);
				action: [ self debugDebugSessionAction ];
				help:
					'Opens the selected debug session with the debugger the image would normally choose to debug it');
		addItem:
			(SpToolBarButton new label: 'Debug With';
				icon: (self iconNamed: #glamorousBug);
				action: [ self debugDebugSessionWithSpecificDebuggerAction ];
				help: 'Opens the selected debug session with the selected debugger');
		addItem:
			(SpToolBarButton new label: 'Inspect';
				icon: (self iconNamed: #smallFind);
				action: [ debugSessionList selectedItems
						ifNotEmpty: [ :selectedItems | (selectedItems at: 1) inspect ] ];
				help: 'Inspect the selected debug session');
		addItem:
			(SpToolBarButton new label: 'Terminate';
				icon: (self iconNamed: #remotesManagerRemoveRemote);
				action: [ debugSessionList selectedItems
						ifNotEmpty: [ :selectedItems | 
							DebugSessionStorage singleton terminate: (selectedItems at: 1).
							self refreshDebugSessionList ] ];
				help: 'Terminate the selected debug session (and the corresponding process), removing it from the list');
		addItem:
			(SpToolBarButton new label: 'Terminate All';
				icon: (self iconNamed: #glamorousTrash);
				action: [ DebugSessionStorage singleton terminateAll.
					self refreshDebugSessionList ];
				help: 'Terminate all debug sessions');
		yourself
]

{ #category : #'react to events' }
DebuggerSelectorPresenter >> onDebugSessionStorageLimitUpdate [
	shouldUpdateStorageLimitInputField ifFalse: [ ^ self ].

	shouldUpdateStorageLimitInputField := false.
	storageLimitInputField
		number: DebugSessionStorage singleton storageLimitForDebugSessionsNotKeptAlive.
	shouldUpdateStorageLimitInputField := true
]

{ #category : #'react to events' }
DebuggerSelectorPresenter >> onDebugSessionStorageUpdate [
	self refreshDebugSessionList
]

{ #category : #'react to events' }
DebuggerSelectorPresenter >> onMainDebuggerClassUpdate [
	self refreshDebuggerList.
	self refreshDebuggerListToolBar
]

{ #category : #helpers }
DebuggerSelectorPresenter >> printDateAndTime: aDateAndTime [
	| d |
	d := aDateAndTime.
	^ ' ' , d hour asString , ':' , d minute asString , ' '
		, d year asString , '-' , d month asString , '-'
		, d dayOfMonth asString
]

{ #category : #helpers }
DebuggerSelectorPresenter >> refreshDebugSessionList [
	debugSessionList items: DebugSessionStorage singleton storage
]

{ #category : #refresh }
DebuggerSelectorPresenter >> refreshDebuggerList [
	debuggerList items:
		(DebuggerSelector singleton getDebuggerClasses
			sort: self getSortingBlock)
]

{ #category : #refresh }
DebuggerSelectorPresenter >> refreshDebuggerListToolBar [
	debuggerListToolBar removeAllItems.
	debuggerListToolBar
		addItem:
			(SpToolBarButton new
				label: 'Browse';
				icon: (self iconNamed: #smallFind);
				action: [ debuggerList selectedItems
						ifEmpty: [ self inform: 'You need to select a debugger' ]
						ifNotEmpty:
							[ :debuggerList_ | (debuggerList_ at: 1) browse switchToMetaLevelScope: ClyClassSideScope ] ]);
		help: 'Browse the class of the selected debugger'.
	self addCorrectMainDebuggerButtonToToolBar: debuggerListToolBar
]

{ #category : #announcement }
DebuggerSelectorPresenter >> setInitialSubscriptions: aBoolean [
	"If @aBoolean is true, perform the initial subscriptions needed to keep the UI up to date. If it is false, unsubscribe. The point of having both the subscriptions and unsubscriptions in the same method is not to forget to add unsubscription statement in the future when new subscription are added"

	aBoolean
		ifTrue: [ DebugSessionStorage singleton addSubscriberOnStorageUpdate: self.
			DebugSessionStorage singleton
				addSubscriberOnStorageLimitUpdate: self.
			DebuggerSelector singleton
				addSubscriberOnMainDebuggerClassUpdate: self ]
		ifFalse: [ DebugSessionStorage singleton removeSubscriberOnStorageUpdate: self.
			DebugSessionStorage singleton
				removeSubscriberOnStorageLimitUpdate: self.
			DebuggerSelector singleton
				removeSubscriberOnMainDebuggerClassUpdate: self ]
]

{ #category : #helpers }
DebuggerSelectorPresenter >> sortDebugSessionUnitStorage: aDebugSessionUnitStorage and: aDebugSessionUnitStorage2 [
	"Return true if @aDebugSessionUnitStorage has been stored more recently than @aDebugSessionUnitStorage2"

	^ aDebugSessionUnitStorage timeOfCreation
		>= aDebugSessionUnitStorage2 timeOfCreation
]

{ #category : #'presenter building' }
DebuggerSelectorPresenter >> storageLimitHelp [
	^ 'Determines the maximum number of debug sessions to be stored. Oldest debug sessions are terminated first. Debug sessions currently opened in any debugger are never terminated and do not count towards this limit'
]