package org.mozilla.javascript
{
	public class DefaultErrorReporter implements ErrorReporter
	{
		internal static var instance:DefaultErrorReporter = new DefaultErrorReporter();
		
		private var forEval:Boolean;
		private var chainedReporter:ErrorReporter;
		
		private static const TYPE_ERROR_NAME:String = "TypeError";
		private static const DELIMETER:String = ": ";
		private static const PREFIX:String = TYPE_ERROR_NAME + DELIMETER;
		
		public function DefaultErrorReporter()
		{
			
		}
		
		public static function forEval(reporter:ErrorReporter):ErrorReporter {
			var r:DefaultErrorReporter = new DefaultErrorReporter();
			r.forEval = true;
			r.chainedReporter = reporter;
			return r;
		}
		
		public function warning(message:String, sourceName:String, line:int, lineSource:String, lineOffset:int):void
		{
			if (chainedReporter !== null) {
				chainedReporter.warning(
					message, sourceName, line, lineSource, lineOffset);
			} else {
				// Do nothing
			}
		}
		
		public function error(message:String, sourceName:String, line:int, lineSource:String, lineOffset:int):void
		{
			if (forEval) {
				// Assume error message strings that start with "TypeError: "
				// should become TypeError exceptions. A bit of a hack, but we
				// don't want to change the ErrorReporter interface.
				var error:String = "SyntaxError";
				if (message.indexOf(PREFIX) === 0) {
					error = TYPE_ERROR_NAME;
					message = message.substring(PREFIX.length);
				}
				throw ScriptRuntime.constructError3(error, message, sourceName,
												   line, lineSource, lineOffset);
			}
			if (chainedReporter !== null) {
				chainedReporter.error(
					message, sourceName, line, lineSource, lineOffset);
			} else {
				throw runtimeError(
					message, sourceName, line, lineSource, lineOffset);
			}
		}
		
		public function runtimeError(message:String, sourceName:String, line:int, lineSource:String, lineOffset:int):EvaluatorException
		{
			if (chainedReporter !== null) {
				return chainedReporter.runtimeError(
					message, sourceName, line, lineSource, lineOffset);
			} else {
				return new EvaluatorException(
					message, sourceName, line, lineSource, lineOffset);
			}
			return new EvaluatorException();
		}
	}
}