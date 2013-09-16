package org.mozilla.javascript
{
	public class ScriptRuntime
	{
		public function ScriptRuntime()
		{
		}
		
		public static function isJSLineTerminator(c:int):Boolean {
			// Optimization for faster check for eol character:
			// they do not have 0xDFD0 bits set
			if ((c & 0xDFD0) !== 0) {
				return false;
			}
			return c === 10 || c === 13 || c === 0x2028 || c === 0x2029; // \r = 13, \n = 10
		}
		
		public static function getMessage(messageId:String, arguments:Array):String {
			
			return "ScriptRuntime.getMessage() not yet implemented.";
		}
		
		public static function getMessage0(messageId:String):String {
			return getMessage(messageId, null);
		}
		
		public static function getMessage1(messageId:String, arg1:Object):String {
			return getMessage(messageId, []);
		}
		
		/**
		 * For escaping strings printed by object and array literals; not quite
		 * the same as 'escape.'
		 */
		public static function escapeString(s:String, escapeQuote:String = null):String
		{
			if (escapeQuote === null)
				escapeQuote = '"';
			
			if (!(escapeQuote === '"' || escapeQuote === "'")) Kit.codeBug();
			var sb:String = null;
			
			for (var i:int = 0, L:int = s.length(); i != L; ++i) {
				var c:String = s.charAt(i);
				var cCode:int = c.charCodeAt(0);
				
				if (' ' <= c && c <= '~' && c !== escapeQuote && c !== '\\') {
					// an ordinary print character (like C isprint()) and not "
					// or \ .
					if (sb !== null) {
						sb += c;
					}
					continue;
				}
				if (sb === null) {
					sb = s;
				}
				
				var escape:String = "";
				switch (c) {
					case '\b':  escape = 'b';  break;
					case '\f':  escape = 'f';  break;
					case '\n':  escape = 'n';  break;
					case '\r':  escape = 'r';  break;
					case '\t':  escape = 't';  break;
					case String.fromCharCode(0xb):   escape = 'v';  break; // Java lacks \v.
					case ' ':   escape = ' ';  break;
					case '\\':  escape = '\\'; break;
				}
				var escapeCode:int = escape.length === 0 ? -1 : escape.charCodeAt(0);
				if (escape >= String.fromCharCode(0)) {
					// an \escaped sort of character
					sb += '\\';
					sb += escape;
				} else if (c === escapeQuote) {
					sb += '\\';
					sb += escapeQuote;
				} else {
					if (cCode < 256) {
						// 2-digit hex
						sb += "\\x";
					} else {
						// Unicode.
						sb += "\\u";
					}
					// append hexadecimal form of c left-padded with 0
					var hexVersion:String = c.charCodeAt(0).toString(16);
					if (hexVersion.length % 2 !== 0) {
						sb += "0";
					}
					sb += c.charCodeAt(0).toString(16);
				}
			}
			return (sb == null) ? s : sb;
		}
		
		public static function constructError(error:String, message:String):EcmaError {
			var linep:Vector.<int> = new Vector.<int>();
			var filename:String = Context.getSourcePositionFromStack(linep);
			return constructError3(error, message, filename, linep[0], null, 0);
		}
		
		public static function constructError2(
			error:String,
			message:String,
			lineNumberDelta:int
		):EcmaError
		{
			var linep:Vector.<int> = new Vector.<int>();
			var filename:String = Context.getSourcePositionFromStack(linep);
			if (linep[0] !== 0) {
				linep[0] += lineNumberDelta;
			}
			return constructError3(error, message, filename, linep[0], null, 0);
		}

		public static function constructError3(
			error:String,
			message:String,
			sourceName:String,
			lineNumber:int,
			lineSource:String,
			columnNumber:int
		):EcmaError
		{
			return new EcmaError(error, message, sourceName,
								 lineNumber, lineSource,columnNumber);
		}
		
	}
}