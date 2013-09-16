package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for an empty statement.  Node type is {@link Token#EMPTY}.<p>
	 *
	 */
	public class EmptyStatement extends AstNode
	{
		public function EmptyStatement(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.EMPTY;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + ";\n";
		}
		
		/**
		 * Visits this node.  There are no children.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}