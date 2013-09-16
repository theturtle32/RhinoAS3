package org.mozilla.javascript
{
	/**
	 * This is interface defines a protocol for the reporting of
	 * errors during JavaScript translation or execution.
	 *
	 * @author Norris Boyd
	 */
	public interface ErrorReporter
	{
		/**
		 * Report a warning.
		 *
		 * The implementing class may choose to ignore the warning
		 * if it desires.
		 *
		 * @param message a String describing the warning
		 * @param sourceName a String describing the JavaScript source
		 * where the warning occured; typically a filename or URL
		 * @param line the line number associated with the warning
		 * @param lineSource the text of the line (may be null)
		 * @param lineOffset the offset into lineSource where problem was detected
		 */
		function warning(message:String, sourceName:String, line:int,
			lineSource:String, lineOffset:int):void;

		/**
		 * Report an error.
		 *
		 * The implementing class is free to throw an exception if
		 * it desires.
		 *
		 * If execution has not yet begun, the JavaScript engine is
		 * free to find additional errors rather than terminating
		 * the translation. It will not execute a script that had
		 * errors, however.
		 *
		 * @param message a String describing the error
		 * @param sourceName a String describing the JavaScript source
		 * where the error occured; typically a filename or URL
		 * @param line the line number associated with the error
		 * @param lineSource the text of the line (may be null)
		 * @param lineOffset the offset into lineSource where problem was detected
		 */
		function error(message:String, sourceName:String, line:int,
			lineSource:String, lineOffset:int):void;
		
		/**
		 * Creates an EvaluatorException that may be thrown.
		 *
		 * runtimeErrors, unlike errors, will always terminate the
		 * current script.
		 *
		 * @param message a String describing the error
		 * @param sourceName a String describing the JavaScript source
		 * where the error occured; typically a filename or URL
		 * @param line the line number associated with the error
		 * @param lineSource the text of the line (may be null)
		 * @param lineOffset the offset into lineSource where problem was detected
		 * @return an EvaluatorException that will be thrown.
		 */
		function runtimeError(message:String, sourceName:String,
			line:int, lineSource:String,
			lineOffset:int):EvaluatorException;
	}
}