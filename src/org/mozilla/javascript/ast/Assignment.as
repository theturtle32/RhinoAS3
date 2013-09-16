package org.mozilla.javascript.ast
{
	/**
	 * AST node representing the set of assignment operators such as {@code =},
	 * {@code *=} and {@code +=}.
	 */
	public class Assignment extends InfixExpression
	{
		public function Assignment(pos:int=-1, len:int=-1, operator:int=-1, left:AstNode=null, right:AstNode=null, operatorPos:int=-1)
		{
			super(pos, len, operator, left, right, operatorPos);
		}
	}
}