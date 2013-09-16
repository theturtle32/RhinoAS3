package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * A variable declaration or initializer, part of a {@link VariableDeclaration}
	 * expression.  The variable "target" can be a simple name or a destructuring
	 * form.  The initializer, if present, can be any expression.<p>
	 *
	 * Node type is one of {@link Token#VAR}, {@link Token#CONST}, or
	 * {@link Token#LET}.<p>
	 */
	public class VariableInitializer extends AstNode
	{
		private var target:AstNode;
		private var initializer:AstNode;
		
		public function VariableInitializer(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.VAR;
		}
		
		/**
		 * Sets the node type.
		 * @throws IllegalArgumentException if {@code nodeType} is not one of
		 * {@link Token#VAR}, {@link Token#CONST}, or {@link Token#LET}
		 */
		public function setNodeType(nodeType:int):void {
			if (nodeType !== Token.VAR
				&& nodeType !== Token.CONST
				&& nodeType !== Token.LET)
				throw new ArgumentError("invalid node type");
			setType(nodeType);
		}
		
		/**
		 * Returns true if this is a destructuring assignment.  If so, the
		 * initializer must be non-{@code null}.
		 * @return {@code true} if the {@code target} field is a destructuring form
		 * (an {@link ArrayLiteral} or {@link ObjectLiteral} node)
		 */
		public function isDestructuring():Boolean {
			return !(target is Name);
		}
		
		/**
		 * Returns the variable name or destructuring form
		 */
		public function getTarget():AstNode {
			return target;
		}
		
		/**
		 * Sets the variable name or destructuring form, and sets
		 * its parent to this node.
		 * @throws IllegalArgumentException if target is {@code null}
		 */
		public function setTarget(target:AstNode):void {
			// Don't throw exception if target is an "invalid" node type.
			// See mozilla/js/tests/js1_7/block/regress-350279.js
			if (target === null)
				throw new ArgumentError("invalid target arg");
			this.target = target;
			target.setParent(this);
		}
		
		/**
		 * Returns the initial value, or {@code null} if not provided
		 */
		public function getInitializer():AstNode {
			return initializer;
		}
		
		/**
		 * Sets the initial value expression, and sets its parent to this node.
		 * @param initializer the initial value.  May be {@code null}.
		 */
		public function setInitializer(initializer:AstNode):void {
			this.initializer = initializer;
			if (initializer !== null)
				initializer.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			sb += target.toSource(0);
			if (initializer !== null)
				sb += (" = " + initializer.toSource(0));
			return sb;
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				target.visit(v);
				if (initializer !== null) {
					initializer.visit(v);
				}
			}
		}
	}
}