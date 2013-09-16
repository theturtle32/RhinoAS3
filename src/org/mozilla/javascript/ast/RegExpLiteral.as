package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	public class RegExpLiteral extends AstNode
	{
		private var value:String;
		private var flags:String;
		
		public function RegExpLiteral(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.REGEXP;
		}
		
		/**
		 * Returns the regexp string without delimiters
		 */
		public function getValue():String {
			return value;
		}
		
		/**
		 * Sets the regexp string without delimiters
		 * @throws IllegalArgumentException} if value is {@code null}
		 */
		public function setValue(value:String):void {
			assertNotNull(value);
			this.value = value;
		}
		
		/**
		 * Returns regexp flags, {@code null} or "" if no flags specified
		 */
		public function getFlags():String {
			return flags;
		}
		
		/**
		 * Sets regexp flags.  Can be {@code null} or "".
		 */
		public function setFlags(flags:String):void {
			this.flags = flags;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + "/" + value + "/"
					+ (flags === null ? "" : flags);
		}
		
		/**
		 * Visits this node.  There are no children to visit.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}