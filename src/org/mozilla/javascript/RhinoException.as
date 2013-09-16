package org.mozilla.javascript
{
	import org.mozilla.javascript.exception.IllegalStateError;

	public class RhinoException extends Error
	{
		private static var useMozillaStackStyle:Boolean = false;
		
		private var _sourceName:String;
		private var _lineNumber:int;
		private var _lineSource:String;
		private var _columnNumber:int;
		
		internal var interpreterStackInfo:Object;
		internal var interpreterLineData:Vector.<int>;
		
		public function RhinoException(message:*="", id:*=0)
		{
			super(message, id);
		}
		
		/**
		 * Get the uri of the script source containing the error, or null
		 * if that information is not available.
		 */
		public final function sourceName():String
		{
			return _sourceName;
		}
		
		/**
		 * Initialize the uri of the script source containing the error.
		 *
		 * @param sourceName the uri of the script source responsible for the error.
		 *                   It should not be <tt>null</tt>.
		 *
		 * @throws IllegalStateException if the method is called more then once.
		 */
		public final function initSourceName(sourceName:String):void
		{
			if (sourceName === null) throw new ArgumentError();
			if (this._sourceName !== null) throw new IllegalStateError();
			this._sourceName = sourceName;
		}
		
		/**
		 * Returns the line number of the statement causing the error,
		 * or zero if not available.
		 */
		public final function lineNumber():int
		{
			return _lineNumber;
		}
		
		/**
		 * Initialize the line number of the script statement causing the error.
		 *
		 * @param lineNumber the line number in the script source.
		 *                   It should be positive number.
		 *
		 * @throws IllegalStateException if the method is called more then once.
		 */
		public final function initLineNumber(lineNumber:int):void
		{
			if (lineNumber <= 0) throw new ArgumentError(lineNumber.toString());
			if (this._lineNumber > 0) throw new IllegalStateError();
			this._lineNumber = lineNumber;
		}
		
		/**
		 * The column number of the location of the error, or zero if unknown.
		 */
		public final function columnNumber():int
		{
			return _columnNumber;
		}
		
		/**
		 * Initialize the column number of the script statement causing the error.
		 *
		 * @param columnNumber the column number in the script source.
		 *                     It should be positive number.
		 *
		 * @throws IllegalStateException if the method is called more then once.
		 */
		public final function initColumnNumber(columnNumber:int):void
		{
			if (columnNumber <= 0) throw new ArgumentError(columnNumber.toString());
			if (this._columnNumber > 0) throw new IllegalStateError();
			this._columnNumber = columnNumber;
		}
		
		/**
		 * The source text of the line causing the error, or null if unknown.
		 */
		public final function lineSource():String
		{
			return _lineSource;
		}
		
		/**
		 * Initialize the text of the source line containing the error.
		 *
		 * @param lineSource the text of the source line responsible for the error.
		 *                   It should not be <tt>null</tt>.
		 *
		 * @throws IllegalStateError if the method is called more then once.
		 */
		public final function initLineSource(lineSource:String):void
		{
			if (lineSource == null) throw new ArgumentError();
			if (this._lineSource !== null) throw new IllegalStateError();
			this._lineSource = lineSource;
		}
		
		internal final function recordErrorOrigin(sourceName:String, lineNumber:int,
											lineSource:String, columnNumber:int):void
		{
			// XXX: for compatibility allow for now -1 to mean 0
			if (lineNumber === -1) {
				lineNumber = 0;
			}
			
			if (sourceName !== null) {
				initSourceName(sourceName);
			}
			if (lineNumber !== 0) {
				initLineNumber(lineNumber);
			}
			if (lineSource !== null) {
				initLineSource(lineSource);
			}
			if (columnNumber !== 0) {
				initColumnNumber(columnNumber);
			}
		}

	}
}