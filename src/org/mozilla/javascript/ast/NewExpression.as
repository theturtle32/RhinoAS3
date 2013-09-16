package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * New expression. Node type is {@link Token#NEW}.<p>
	 *
	 * <pre><i>NewExpression</i> :
	 *      MemberExpression
	 *      <b>new</b> NewExpression</pre>
	 *
	 * This node is a subtype of {@link FunctionCall}, mostly for internal code
	 * sharing.  Structurally a {@code NewExpression} node is very similar to a
	 * {@code FunctionCall}, so it made a certain amount of sense.
	 */
	public class NewExpression extends FunctionCall
	{
		private var initializer:ObjectLiteral;
		
		public function NewExpression(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.NEW;
		}
		
		/**
		 * Returns initializer object, if any.
		 * @return extra initializer object-literal expression, or {@code null} if
		 * not specified.
		 */
		public function getInitializer():ObjectLiteral {
			return initializer;
		}
		
		/**
		 * Sets initializer object.  Rhino supports an experimental syntax
		 * of the form {@code new expr [ ( arglist ) ] [initializer]},
		 * in which initializer is an object literal that is used to set
		 * additional properties on the newly-created {@code expr} object.
		 *
		 * @param initializer extra initializer object.
		 * Can be {@code null}.
		 */
		public function setInitializer(initializer:ObjectLiteral):void {
			this.initializer = initializer;
			if (initializer !== null)
				initializer.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			sb += "new ";
			sb += target.toSource(0);
			sb += "(";
			if (arguments !== null) {
				sb += printList(this.arguments);
			}
			sb += ")";
			if (initializer !== null) {
				sb += " ";
				sb += initializer.toSource(0);
			}
			return sb;
		}
		
		/**
		 * Visits this node, the target, and each argument.  If there is
		 * a trailing initializer node, visits that last.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				target.visit(v);
				for each (var arg:AstNode in this.arguments) {
					arg.visit(v);
				}
				if (initializer !== null) {
					initializer.visit(v);
				}
			}
		}
	}
}