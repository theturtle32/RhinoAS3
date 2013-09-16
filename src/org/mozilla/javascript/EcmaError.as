package org.mozilla.javascript
{
	public class EcmaError extends RhinoException
	{
		private var errorName:String;
		private var errorMessage:String;
		
		public function EcmaError(errorName:String, errorMessage:String,
								  sourceName:String, lineNumber:int,
								  lineSource:String, columnNumber:int)
		{
			super(message);
			recordErrorOrigin(sourceName, lineNumber, lineSource, columnNumber);
			this.errorName = errorName;
			this.errorMessage = errorMessage;
		}
		
		public function details():String
		{
			return errorName+": "+errorMessage;
		}
		
		/**
		 * Gets the name of the error.
		 *
		 * ECMA edition 3 defines the following
		 * errors: EvalError, RangeError, ReferenceError,
		 * SyntaxError, TypeError, and URIError. Additional error names
		 * may be added in the future.
		 *
		 * See ECMA edition 3, 15.11.7.9.
		 *
		 * @return the name of the error.
		 */
		public function getName():String
		{
			return errorName;
		}
		
		/**
		 * Gets the message corresponding to the error.
		 *
		 * See ECMA edition 3, 15.11.7.10.
		 *
		 * @return an implementation-defined string describing the error.
		 */
		public function getErrorMessage():String
		{
			return errorMessage;
		}
		
		/**
		 * @deprecated Use {@link RhinoException#sourceName()} from the super class.
		 */
		public function getSourceName():String
		{
			return sourceName();
		}
		
		/**
		 * @deprecated Use {@link RhinoException#lineNumber()} from the super class.
		 */
		public function getLineNumber():int
		{
			return lineNumber();
		}
		
		/**
		 * @deprecated
		 * Use {@link RhinoException#columnNumber()} from the super class.
		 */
		public function getColumnNumber():int {
			return columnNumber();
		}
		
		/**
		 * @deprecated Use {@link RhinoException#lineSource()} from the super class.
		 */
		public function getLineSource():String  {
			return lineSource();
		}
		
		/**
		 * @deprecated
		 * Always returns <b>null</b>.
		 */
		public function getErrorObject():*
		{
			return null;
		}

	}
}