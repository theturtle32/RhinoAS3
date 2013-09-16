package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for an E4X XML {@code [expr]} member-ref expression.
	 * The node type is {@link Token#REF_MEMBER}.<p>
	 *
	 * Syntax:<p>
	 *
	 * <pre> @<i><sub>opt</sub></i> ns:: <i><sub>opt</sub></i> [ expr ]</pre>
	 *
	 * Examples include {@code ns::[expr]}, {@code @ns::[expr]}, {@code @[expr]},
	 * {@code *::[expr]} and {@code @*::[expr]}.<p>
	 *
	 * Note that the form {@code [expr]} (i.e. no namespace or
	 * attribute-qualifier) is not a legal {@code XmlElemRef} expression,
	 * since it's already used for standard JavaScript {@link ElementGet}
	 * array-indexing.  Hence, an {@code XmlElemRef} node always has
	 * either the attribute-qualifier, a non-{@code null} namespace node,
	 * or both.<p>
	 *
	 * The node starts at the {@code @} token, if present.  Otherwise it starts
	 * at the namespace name.  The node bounds extend through the closing
	 * right-bracket, or if it is missing due to a syntax error, through the
	 * end of the index expression.<p>
	 */
	public class XmlElemRef extends XmlRef
	{
		private var indexExpr:AstNode;
		private var lb:int = -1;
		private var rb:int = -1;
		
		public function XmlElemRef(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.REF_MEMBER;
		}
		
		/**
		 * Returns index expression: the 'expr' in {@code @[expr]}
		 * or {@code @*::[expr]}.
		 */
		public function getExpression():AstNode {
			return indexExpr;
		}
		
		/**
		 * Sets index expression, and sets its parent to this node.
		 * @throws IllegalArgumentException if {@code expr} is {@code null}
		 */
		public function setExpression(expr:AstNode):void {
			assertNotNull(expr);
			indexExpr = expr;
			expr.setParent(this);
		}
		
		/**
		 * Returns left bracket position, or -1 if missing.
		 */
		public function getLb():int {
			return lb;
		}
		
		/**
		 * Sets left bracket position, or -1 if missing.
		 */
		public function setLb(lb:int):void {
			this.lb = lb;
		}
		
		/**
		 * Returns left bracket position, or -1 if missing.
		 */
		public function getRb():int {
			return rb;
		}
		
		/**
		 * Sets right bracket position, -1 if missing.
		 */
		public function setRb(rb:int):void {
			this.rb = rb;
		}
		
		/**
		 * Sets both bracket positions.
		 */
		public function setBrackets(lb:int, rb:int):void {
			this.lb = lb;
			this.rb = rb;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			if (isAttributeAccess()) {
				sb += "@";
			}
			if (ns !== null) {
				sb += (ns.toSource(0) + "::");
			}
			sb += ("[" + indexExpr.toSource(0) + "]");
			return sb;
		}
		
		/**
		 * Visits this node, then the namespace if provided, then the
		 * index expression.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				if (ns !== null) {
					ns.visit(v);
				}
				indexExpr.visit(v);
			}
		}
	}
}