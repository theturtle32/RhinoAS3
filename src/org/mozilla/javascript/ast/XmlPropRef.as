package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for an E4X XML {@code [expr]} property-ref expression.
	 * The node type is {@link Token#REF_NAME}.<p>
	 *
	 * Syntax:<p>
	 *
	 * <pre> @<i><sub>opt</sub></i> ns:: <i><sub>opt</sub></i> name</pre>
	 *
	 * Examples include {@code name}, {@code ns::name}, {@code ns::*},
	 * {@code *::name}, {@code *::*}, {@code @attr}, {@code @ns::attr},
	 * {@code @ns::*}, {@code @*::attr}, {@code @*::*} and {@code @*}.<p>
	 *
	 * The node starts at the {@code @} token, if present.  Otherwise it starts
	 * at the namespace name.  The node bounds extend through the closing
	 * right-bracket, or if it is missing due to a syntax error, through the
	 * end of the index expression.<p>
	 */
	public class XmlPropRef extends XmlRef
	{
		private var propName:Name;
		
		public function XmlPropRef(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.REF_NAME;
		}
		
		/**
		 * Returns property name.
		 */
		public function getPropName():Name {
			return propName;
		}
		
		/**
		 * Sets property name, and sets its parent to this node.
		 * @throws IllegalArgumentException if {@code propName} is {@code null}
		 */
		public function setPropName(propName:Name):void {
			assertNotNull(propName);
			this.propName = propName;
			propName.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			if (isAttributeAccess()) {
				sb += "@";
			}
			if (ns !== null) {
				sb += (ns.toSource(0) + "::");
			}
			sb += propName.toSource(0);
			return sb;
		}
		
		/**
		 * Visits this node, then the namespace if present, then the property name.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				if (ns !== null) {
					ns.visit(v);
				}
				propName.visit(v);
			}
		}
	}
}