package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node representing an expression in a statement context.  The node type is
	 * {@link Token#EXPR_VOID} if inside a function, or else
	 * {@link Token#EXPR_RESULT} if inside a script.
	 */
	public class ExpressionStatement extends AstNode
	{
		private var expr:AstNode;
		
		/**
		 * Called by the parser to set node type to EXPR_RESULT
		 * if this node is not within a Function.
		 */
		public function setHasResult():void {
			type = Token.EXPR_RESULT;
		}
		
		/**
		 * Constructs a new {@code ExpressionStatement} wrapping
		 * the specified expression.  Sets this node's position to the
		 * position of the wrapped node, and sets the wrapped node's
		 * position to zero.  Sets this node's length to the length of
		 * the wrapped node.
		 * @param expr the wrapped expression
		 * @param hasResult {@code true} if this expression has side
		 * effects.  If true, sets node type to EXPR_RESULT, else to EXPR_VOID.
		 */
		public function ExpressionStatement(pos:int=-1, len:int=-1, expr:AstNode=null, hasResult:Boolean=false) {
			if (expr !== null) {
				pos = expr.getPosition();
				len = expr.getLength();
				setExpression(expr);
			}
			super(pos, len);
			type = hasResult ? Token.EXPR_RESULT : Token.EXPR_VOID;
		}
		
		public function getExpression():AstNode {
			return expr;
		}
		
		public function setExpression(expression:AstNode):void {
			assertNotNull(expression);
			expr = expression;
			expression.setParent(this);
			setLineno(expression.getLineno());
		}
		
		/**
		 * Returns true if this node has side effects
		 * @throws IllegalStateException if expression has not yet
		 * been set.
		 */
		override public function hasSideEffects():Boolean {
			return type === Token.EXPR_RESULT || expr.hasSideEffects();
		}
		
		override public function toSource(depth:int=0):String {
			return expr.toSource(depth) + ";\n";
		}
		
		/**
		 * Visits this node, then the wrapped statement
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				expr.visit(v);
			}
		}
	}
}