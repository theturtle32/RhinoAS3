package org.mozilla.javascript
{
	public class Context
	{
		
		public static const VERSION_1_2:int = 120;
		public static const VERSION_1_7:int = 170;
		public static const VERSION_1_8:int = 180;
		
		public function Context()
		{
		}
		
		/**
		 * Report a runtime error using the error reporter for the current thread.
		 *
		 * @param message the error message to report
		 * @see org.mozilla.javascript.ErrorReporter
		 */
		public static function reportRuntimeError(message:String):Error 
		{
//			int[] linep = { 0 };
//			String filename = getSourcePositionFromStack(linep);
//			return Context.reportRuntimeError(message, filename, linep[0], null, 0);
			return new Error("Unimplemented reportRuntimeError " + message);
		}
		
		internal static function getSourcePositionFromStack(linep:Vector.<int>):String
		{
						return null;
		}
	}
}