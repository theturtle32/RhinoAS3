package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.Token;
	import org.mozilla.javascript.exception.IllegalStateError;

	/**
	 * AST node for keyword literals:  currently, {@code this},
	 * {@code null}, {@code true}, {@code false}, and {@code debugger}.
	 * Node type is one of
	 * {@link Token#THIS},
	 * {@link Token#NULL},
	 * {@link Token#TRUE},
	 * {@link Token#FALSE}, or
	 * {@link Token#DEBUGGER}.
	 */
	public class KeywordLiteral extends AstNode
	{
		public function KeywordLiteral(pos:int=-1,len:int=-1,nodeType:int=Token.ERROR)
		{
			super(pos, len);
			if (nodeType !== Token.ERROR)
				setType(nodeType);
		}
		
		/**
		 * Sets node token type
		 * @throws IllegalArgumentException if {@code nodeType} is unsupported
		 */
		override public function setType(type:int):Node {
			if (!(type === Token.THIS
				  || type === Token.NULL
				  || type === Token.TRUE
				  || type === Token.FALSE
				  || type === Token.DEBUGGER))
				throw new ArgumentError("Invalid node type: " + type);
			this.type = type;
			return this;
		}
		
		/**
		 * Returns true if the token type is {@link Token#TRUE} or
		 * {@link Token#FALSE}.
		 */
		public function isBooleanLiteral():Boolean {
			return type === Token.TRUE || type === Token.FALSE;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			switch (getType()) {
				case Token.THIS:
					sb += "this";
					break;
				case Token.NULL:
					sb += "null";
					break;
				case Token.TRUE:
					sb += "true";
					break;
				case Token.FALSE:
					sb += "false";
					break;
				case Token.DEBUGGER:
					sb += "debugger;\n";
					break;
				default:
					throw new IllegalStateError("Invalid keyword literal type: "
						+ getType());
			}
			return sb;
		}
		
		/**
		 * Visits this node.  There are no children to visit.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}