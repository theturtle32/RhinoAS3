package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Throw statement.  Node type is {@link Token#THROW}.<p>
	 *
	 * <pre><i>ThrowStatement</i> :
	 *      <b>throw</b> [<i>no LineTerminator here</i>] Expression ;</pre>
	 */
	public class ThrowStatement extends AstNode
	{
		private var expression:AstNode;
		
		public function ThrowStatement(pos:int=-1, len:int=-1, expr:AstNode=null)
		{
			super(pos, len);
			type = Token.THROW;
			if (expr !== null) {
				setExpression(expr);
			}
		}
		
		/**
		 * Returns the expression being thrown
		 */
		public function getExpression():AstNode {
			return expression;
		}
		
		/**
		 * Sets the expression being thrown, and sets its parent
		 * to this node.
		 * @throws IllegalArgumentException} if expression is {@code null}
		 */
		public function setExpression(expression:AstNode):void {
			assertNotNull(expression);
			this.expression = expression;
			expression.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) +
				   "throw " +
				   expression.toSource(0) +
				   ";\n";
		}
		
		/**
		 * Visits this node, then the thrown expression.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				expression.visit(v);
			}
		}

	}
}