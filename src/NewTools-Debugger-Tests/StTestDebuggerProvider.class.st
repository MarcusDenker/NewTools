"
Utilitary class to provide various kind of debuggers, interrupted context and debug sessions for testing purposes
"
Class {
	#name : #StTestDebuggerProvider,
	#superclass : #Object,
	#instVars : [
		'session'
	],
	#category : #'NewTools-Debugger-Tests-Utils'
}

{ #category : #helpers }
StTestDebuggerProvider >> debuggerWithDNUContext [
	[ Object new toto ]
		on: Error
		do: [ :err | 
			self sessionFor: err signalerContext.
			^ self newDebugger ]
]

{ #category : #helpers }
StTestDebuggerProvider >> debuggerWithErrorContext [
	[ 1 / 0 ]
		on: Error
		do: [ :err | 
			self sessionFor: err signalerContext.
			^ self newDebugger ]
]

{ #category : #helpers }
StTestDebuggerProvider >> debuggerWithFailingTestContext [
	[ self produceTestFailure ]
		on: TestFailure
		do: [ :err | 
			self sessionFor: err signalerContext.
			^ self newDebugger ]
]

{ #category : #helpers }
StTestDebuggerProvider >> debuggerWithMissingClassContext [
	[ MissingClass new]
		on: Error
		do: [ :err | 
			self sessionFor: err signalerContext copy.
			^ self newDebugger ]
]

{ #category : #helpers }
StTestDebuggerProvider >> debuggerWithMissingSubclassResponsibilityContext [
	[ StDummyDebuggerPresenter new unimplementedSubclassResponsibility ]
		on: Error
		do: [ :err | 
			self sessionFor: err signalerContext.
			^ self newDebugger ]
]

{ #category : #helpers }
StTestDebuggerProvider >> debuggerWithRunnableContext [
	[ Halt now ]
		on: Halt
		do: [ :err | 
			self sessionFor: err signalerContext.
			^ self newDebugger ]
]

{ #category : #helpers }
StTestDebuggerProvider >> newDebugger [
	^ StDebugger basicNew
		session: session;
		yourself
]

{ #category : #helpers }
StTestDebuggerProvider >> produceTestFailure [
	TestCase new fail
]

{ #category : #helpers }
StTestDebuggerProvider >> sessionFor: aContext [
	| process |
	process := Process
		forContext: aContext
		priority: Processor userInterruptPriority.
	session := DebugSession
		named: 'test session'
		on: process
		startedAt: aContext
]

{ #category : #helpers }
StTestDebuggerProvider >> terminate [ 
	session ifNotNil:[session terminate].
	session := nil
]