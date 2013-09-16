package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for E4X ".@" and ".." expressions, such as
	 * {@code foo..bar}, {@code foo..@bar}, {@code @foo.@bar}, and
	 * {@code foo..@ns::*}.  The right-hand node is always an
	 * {@link XmlRef}. <p>
	 *
	 * Node type is {@link Token#DOT} or {@link Token#DOTDOT}.
	 */
	public class XmlMemberGet extends InfixExpression
	{
		public function XmlMemberGet(pos:int=-1, len:int=-1, target:AstNode=null, ref:XmlRef=null, opPos:int=-1)
		{
			super(pos, len, Token.DOTDOT, target, ref, opPos);
		}
		
		/**
		 * Returns the object on which the XML member-ref expression
		 * is being evaluated.  Should never be {@code null}.
		 */
		public function getTarget():AstNode {
			return getLeft();
		}
		
		/**
		 * Sets target object, and sets its parent to this node.
		 * @throws IllegalArgumentException if {@code target} is {@code null}
		 */
		public function setTarget(target:AstNode):void {
			setLeft(target);
		}
		
		/**
		 * Returns the right-side XML member ref expression.
		 * Should never be {@code null} unless the code is malformed.
		 */
		public function getMemberRef():XmlRef {
			return XmlRef(getRight());
		}
		
		/**
		 * Sets the XML member-ref expression, and sets its parent
		 * to this node.
		 * @throws IllegalArgumentException if property is {@code null}
		 */
		public function setProperty(ref:XmlRef):void {
			setRight(ref);
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) +
				   getLeft().toSource(0) +
				   operatorToString(getType()) +
				   getRight().toSource(0);
		}
	}
}