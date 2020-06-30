Class {
	#name : #DebuggerFailure,
	#superclass : #Exception,
	#instVars : [
		'failedDebugger',
		'innerException'
	],
	#category : #'NewTools-DebuggerSelector-Core'
}

{ #category : #'instance creation' }
DebuggerFailure class >> of: aDebugger on: anException [
	^ self new
		debugger: aDebugger exception: anException;
		yourself
]

{ #category : #debugging }
DebuggerFailure >> debug [
	"open a debugger on myself"

	(DebugRequest newForException: self) submit
]

{ #category : #initialization }
DebuggerFailure >> debugger: aDebugger exception: anException [
	failedDebugger := aDebugger.
	innerException := anException
]

{ #category : #accessing }
DebuggerFailure >> failedDebugger [
	^ failedDebugger
]

{ #category : #accessing }
DebuggerFailure >> innerException [
	^ innerException
]

{ #category : #testing }
DebuggerFailure >> isDebuggerFailure [
	^true
]

{ #category : #testing }
DebuggerFailure >> isHandleableBy: aDebugger [
	^ aDebugger ~= failedDebugger
]

{ #category : #testing }
DebuggerFailure >> originException [
	^ innerException originException
]