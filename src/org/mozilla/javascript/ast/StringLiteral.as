package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.ScriptRuntime;
	import org.mozilla.javascript.Token;

	/**
	 * AST node for a single- or double-quoted string literal.
	 * Node type is {@link Token#STRING}.<p>
	 */
	public class StringLiteral extends AstNode
	{
		private var value:String;
		private var quoteChar:String;
		
		public function StringLiteral(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.STRING;
		}
		
		/**
		 * Returns the node's value:  the parsed string with or without the enclosing quotes
		 * @return the node's value, a {@link String} of unescaped characters
		 * that includes the delimiter quotes.
		 */
		public function getValue(includeQuotes:Boolean = false):String {
			if (!includeQuotes)
				return value;
			return quoteChar + value + quoteChar;
		}
		
		/**
		 * Sets the node's value.  Do not include the enclosing quotes.
		 * @param value the node's value
		 * @throws IllegalArgumentException} if value is {@code null}
		 */
		public function setValue(value:String):void {
			assertNotNull(value);
			this.value = value;
		}
		
		/**
		 * Returns the character used as the delimiter for this string.
		 */
		public function getQuoteCharacter():String {
			return quoteChar;
		}
		
		public function setQuoteCharacter(c:String):void {
			quoteChar = c;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + quoteChar + ScriptRuntime.escapeString(value, quoteChar) + quoteChar;
		}
		
		/**
		 * Visits this node.  There are no children to visit.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}

	}
}