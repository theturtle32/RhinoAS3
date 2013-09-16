package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node representing an E4X {@code foo.(bar)} query expression.
	 * The node type (operator) is {@link Token#DOTQUERY}.
	 * Its {@code getLeft} node is the target ("foo" in the example),
	 * and the {@code getRight} node is the filter expression node.<p>
	 *
	 * This class exists separately from {@link InfixExpression} largely because it
	 * has different printing needs.  The position of the left paren is just after
	 * the dot (operator) position, and the right paren is the final position in the
	 * bounds of the node.  If the right paren is missing, the node ends at the end
	 * of the filter expression.
	 */
	public class XmlDotQuery extends InfixExpression
	{
		private var rp:int = -1;
		
		public function XmlDotQuery(pos:int=-1, len:int=-1, operator:int=-1, left:AstNode=null, right:AstNode=null, operatorPos:int=-1)
		{
			super(pos, len, operator, left, right, operatorPos);
			type = Token.DOTQUERY;
		}
		
		/**
		 * Returns right-paren position, -1 if missing.<p>
		 *
		 * Note that the left-paren is automatically the character
		 * immediately after the "." in the operator - no whitespace is
		 * permitted between the dot and lp by the scanner.
		 */
		public function getRp():int {
			return rp;
		}
		
		/**
		 * Sets right-paren position
		 */
		public function setRp(rp:int):void {
			this.rp = rp;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + getLeft().toSource(0) + ".(" + getRight().toSource(0) + ")";
		}
	}
}