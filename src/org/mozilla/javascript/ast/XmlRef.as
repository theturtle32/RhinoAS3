package org.mozilla.javascript.ast
{
	/**
	 * Base class for E4X XML attribute-access or property-get expressions.
	 * Such expressions can take a variety of forms. The general syntax has
	 * three parts:<p>
	 *
	 * <ol>
	 *  <li>optional: an {@code @}</li>  (specifying an attribute access)</li>
	 *  <li>optional: a namespace (a {@code Name}) and double-colon</li>
	 *  <li>required:  either a {@code Name} or a bracketed [expression]</li>
	 * </ol>
	 *
	 * The property-name expressions (examples:  {@code ns::name}, {@code @name})
	 * are represented as {@link XmlPropRef} nodes.  The bracketed-expression
	 * versions (examples:  {@code ns::[name]}, {@code @[name]}) become
	 * {@link XmlElemRef} nodes.<p>
	 *
	 * This node type (or more specifically, its subclasses) will
	 * sometimes be the right-hand child of a {@link PropertyGet} node or
	 * an {@link XmlMemberGet} node.  The {@code XmlRef} node may also
	 * be a standalone primary expression with no explicit target, which
	 * is valid in certain expression contexts such as
	 * {@code company..employee.(@id &lt; 100)} - in this case, the {@code @id}
	 * is an {@code XmlRef} that is part of an infix '&lt;' expression
	 * whose parent is an {@code XmlDotQuery} node.<p>
	 */
	public class XmlRef extends AstNode
	{
		protected var ns:Name;
		protected var atPos:int = -1;
		protected var colonPos:int = -1;
		
		public function XmlRef(pos:int=-1, len:int=-1)
		{
			super(pos, len);
		}
		
		/**
		 * Return the namespace.  May be {@code @null}.
		 */
		public function getNamespace():Name {
			return ns;
		}
		
		/**
		 * Sets namespace, and sets its parent to this node.
		 * Can be {@code null}.
		 */
		public function setNamespace(ns:Name):void {
			this.ns = ns;
			if (ns !== null)
				ns.setParent(this);
		}
		
		/**
		 * Returns {@code true} if this expression began with an {@code @}-token.
		 */
		public function isAttributeAccess():Boolean {
			return atPos >= 0;
		}
		
		/**
		 * Returns position of {@code @}-token, or -1 if this is not
		 * an attribute-access expression.
		 */
		public function getAtPos():int {
			return atPos;
		}
		
		/**
		 * Sets position of {@code @}-token, or -1
		 */
		public function setAtPos(atPos:int):void {
			this.atPos = atPos;
		}
		
		/**
		 * Returns position of {@code ::} token, or -1 if not present.
		 * It will only be present if the namespace node is non-{@code null}.
		 */
		public function getColonPos():int {
			return colonPos;
		}
		
		/**
		 * Sets position of {@code ::} token, or -1 if not present
		 */
		public function setColonPos(colonPos:int):void {
			this.colonPos = colonPos;
		}
	}
}