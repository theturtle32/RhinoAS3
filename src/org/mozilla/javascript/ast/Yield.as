package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for JavaScript 1.7 {@code yield} expression or statement.
	 * Node type is {@link Token#YIELD}.<p>
	 *
	 * <pre><i>Yield</i> :
	 *   <b>yield</b> [<i>no LineTerminator here</i>] [non-paren Expression] ;</pre>
	 */
	public class Yield extends AstNode
	{
		private var value:AstNode;
		
		public function Yield(pos:int=-1, len:int=-1, value:AstNode=null)
		{
			super(pos, len);
			type = Token.YIELD;
			if (value !== null) {
				setValue(value);
			}
		}
		
		/**
		 * Returns yielded expression, {@code null} if none
		 */
		public function getValue():AstNode {
			return value;
		}
		
		/**
		 * Sets yielded expression, and sets its parent to this node.
		 * @param expr the value to yield. Can be {@code null}.
		 */
		public function setValue(expr:AstNode):void {
			this.value = expr;
			if (expr !== null)
				expr.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			return value === null
					? "yield"
					: "yield " + value.toSource(0);
		}
		
		/**
		 * Visits this node, and if present, the yielded value.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this) && value !== null) {
				value.visit(v);
			}
		}
	}
}