package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for a parenthesized expression.
	 * Node type is {@link Token#LP}.<p>
	 */
	public class ParenthesizedExpression extends AstNode
	{
		private var expression:AstNode;
		
		public function ParenthesizedExpression(pos:int=-1, len:int=-1, expr:AstNode=null)
		{
			if (pos === -1 && len === -1) {
				if (expr === null) {
					pos = 0;
					len = 1;
				}
				else {
					pos = expr.getPosition();
					len = expr.getLength();
				}
			}
			super(pos, len);
			type = Token.LP;
			setExpression(expr);
		}
		
		/**
		 * Returns the expression between the parens
		 */
		public function getExpression():AstNode {
			return expression;
		}
		
		/**
		 * Sets the expression between the parens, and sets the parent
		 * to this node.
		 * @param expression the expression between the parens
		 * @throws IllegalArgumentException} if expression is {@code null}
		 */
		public function setExpression(expression:AstNode):void {
			assertNotNull(expression);
			this.expression = expression;
			expression.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + "(" + expression.toSource(0) + ")";
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				expression.visit(v);
			}
		}
	}
}