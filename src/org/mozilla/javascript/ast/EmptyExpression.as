package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for an empty expression.  Node type is {@link Token#EMPTY}.<p>
	 *
	 * To create an empty statement, wrap it with an {@link ExpressionStatement}.
	 */
	public class EmptyExpression extends AstNode
	{
		public function EmptyExpression(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.EMPTY;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth);
		}
		
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}