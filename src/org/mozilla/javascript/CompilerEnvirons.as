package org.mozilla.javascript
{
	import org.as3commons.collections.Set;

	public class CompilerEnvirons
	{
		private var errorReporter:ErrorReporter;
		private var languageVersion:int;
		private var generateDebugInfo:Boolean;
		private var reservedKeywordAsIdentifier:Boolean;
		private var allowMemberExprAsFunctionName:Boolean;
		private var xmlAvailable:Boolean;
		private var optimizationLevel:int;
		private var generatingSource:Boolean;
		private var strictMode:Boolean;
		private var warningAsError:Boolean;
		private var generateObserverCount:Boolean;
		private var recordingComments:Boolean;
		private var recordingLocalJsDocComments:Boolean;
		private var _recoverFromErrors:Boolean;
		private var warnTrailingComma:Boolean;
		private var ideMode:Boolean;
		private var allowSharpComments:Boolean;
		public var activationNames:Set; // Java type: Set<String>
		
		public function CompilerEnvirons()
		{
		}
		
		public function isRecordingComments():Boolean {
			return recordingComments;
		}
		
		public function setRecordingComments(record:Boolean):void {
			recordingComments = record;
		}
		
		public function isRecordingLocalJsDocComments():Boolean {
			return recordingLocalJsDocComments;
		}
		
		public function setRecordingLocalJsDocComments(record:Boolean):void {
			recordingLocalJsDocComments = record;
		}
				
		public function getLanguageVersion():int {
			return languageVersion;
		}
		
		public function isReservedKeywordAsIdentifier():Boolean {
			return reservedKeywordAsIdentifier;
		}
		
		public function getErrorReporter():ErrorReporter {
			return errorReporter;
		}
		
		public function getWarnTrailingComma():Boolean {
			return warnTrailingComma;
		}
		
		public function setWarnTrailingComma(warn:Boolean):void {
			warnTrailingComma = warn;
		}
		
		public function isStrictMode():Boolean {
			return strictMode;
		}
		
		public function isXmlAvailable():Boolean {
			return xmlAvailable;
		}
		
		public function setXmlAvailable(flag:Boolean):void {
			xmlAvailable = flag;
		}
		
		/**
		 * Turn on or off full error recovery.  In this mode, parse errors do not
		 * throw an exception, and the parser attempts to build a full syntax tree
		 * from the input.  Useful for IDEs and other frontends.
		 */
		public function setRecoverFromErrors(recover:Boolean):void {
			_recoverFromErrors = recover;
		}
		
		public function recoverFromErrors():Boolean {
			return _recoverFromErrors;
		}
		
		/**
		 * Puts the parser in "IDE" mode.  This enables some slightly more expensive
		 * computations, such as figuring out helpful error bounds.
		 */
		public function setIdeMode(ide:Boolean):void {
			ideMode = ide;
		}
		
		public function isIdeMode():Boolean {
			return ideMode;
		}
		
		public function getActivationNames():Set {
			return activationNames;
		}
		
		public function setActivationNames(activationNames:Set):void {
			this.activationNames = activationNames;
		}
		
		/**
		 * Extension to ECMA: if 'function &lt;name&gt;' is not followed
		 * by '(', assume &lt;name&gt; starts a {@code memberExpr}
		 */
		public function isAllowMemberExprAsFunctionName():Boolean {
			return allowMemberExprAsFunctionName;
		}
	}
}