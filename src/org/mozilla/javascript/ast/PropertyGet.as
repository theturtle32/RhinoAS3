package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for the '.' operator.  Node type is {@link Token#GETPROP}.
	 */
	public class PropertyGet extends InfixExpression
	{
		public function PropertyGet(pos:int=-1, len:int=-1, target:AstNode=null, property:Name=null, dotPosition:int=-1)
		{
			super(pos, len, Token.GETPROP, target, property, dotPosition);
		}
		
		/**
		 * Returns the object on which the property is being fetched.
		 * Should never be {@code null}.
		 */
		public function getTarget():AstNode {
			return getLeft();
		}
		
		/**
		 * Sets target object, and sets its parent to this node.
		 * @param target expression evaluating to the object upon which
		 * to do the property lookup
		 * @throws IllegalArgumentException} if {@code target} is {@code null}
		 */
		public function setTarget(target:AstNode):void {
			setLeft(target);
		}
		
		/**
		 * Returns the property being accessed.
		 */
		public function getProperty():Name {
			return Name(getRight());
		}
		
		/**
		 * Sets the property being accessed, and sets its parent to this node.
		 * @throws IllegalArgumentException} if {@code property} is {@code null}
		 */
		public function setProperty(property:Name):void {
			setRight(property);
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + getLeft().toSource(0) + "." + getRight.toSource(0);
		}
		
		/**
		 * Visits this node, the target expression, and the property name.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				getTarget().visit(v);
				getProperty().visit(v);
			}
		}
	}
}