package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for an indexed property reference, such as {@code foo['bar']} or
	 * {@code foo[2]}.  This is sometimes called an "element-get" operation, hence
	 * the name of the node.<p>
	 *
	 * Node type is {@link Token#GETELEM}.<p>
	 *
	 * The node bounds extend from the beginning position of the target through the
	 * closing right-bracket.  In the presence of a syntax error, the right bracket
	 * position is -1, and the node ends at the end of the element expression.
	 */
	public class ElementGet extends AstNode
	{
		private var target:AstNode;
		private var element:AstNode;
		private var lb:int = -1;
		private var rb:int = -1;
		
		public function ElementGet(pos:int=-1, len:int=-1, target:AstNode=null, element:AstNode=null)
		{
			if (target !== null && element !== null) {
				setTarget(target);
				setElement(element);
			}
			else if (target === null && element === null) {
				super(pos, len);
			}
			else {
				throw new ArgumentError("Illegal invocation");
			}
			type = Token.GETELEM;
		}
		
		/**
		 * Returns the object on which the element is being fetched.
		 */
		public function getTarget():AstNode {
			return target;
		}
		
		/**
		 * Sets target object, and sets its parent to this node.
		 * @param target expression evaluating to the object upon which
		 * to do the element lookup
		 * @throws IllegalArgumentException if target is {@code null}
		 */
		public function setTarget(target:AstNode):void {
			assertNotNull(target);
			this.target = target;
			target.setParent(this);
		}
		
		/**
		 * Returns the element being accessed
		 */
		public function getElement():AstNode {
			return element;
		}
		
		/**
		 * Sets the element being accessed, and sets its parent to this node.
		 * @throws IllegalArgumentException if element is {@code null}
		 */
		public function setElement(element:AstNode):void {
			assertNotNull(element);
			this.element = element;
			element.setParent(this);
		}
		
		/**
		 * Returns left bracket position
		 */
		public function getLb():int {
			return lb;
		}
		
		/**
		 * Sets left bracket position
		 */
		public function setLb(lb:int):void {
			this.lb = lb;
		}
		
		/**
		 * Returns right bracket position, -1 if missing
		 */
		public function getRb():int {
			return rb;
		}
		
		/**
		 * Sets right bracket position, -1 if not present
		 */
		public function setRb(rb:int):void {
			this.rb = rb;
		}
		
		public function setParens(lb:int, rb:int):void {
			this.lb = lb;
			this.rb = rb;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + target.toSource(0) + "[" + element.toSource(0) + "]";
		}
		
		/**
		 * Visits this node, the target, and the index expression.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				target.visit(v);
				element.visit(v);
			}
		}

	}
}