package org.mozilla.javascript.ast
{
	/**
	 * AST node for an XML-text-only component of an XML literal expression.  This
	 * node differs from a {@link StringLiteral} in that it does not have quotes for
	 * delimiters.
	 */
	public class XmlString extends XmlFragment
	{
		private var xml:String;
		
		public function XmlString(pos:int=-1, s:String=null)
		{
			super(pos, -1);
			if (s !== null) {
				setXml(s);
			}
		}
		
		/**
		 * Sets the string for this XML component.  Sets the length of the
		 * component to the length of the passed string.
		 * @param s a string of xml text
		 * @throws IllegalArgumentException} if {@code s} is {@code null}
		 */
		public function setXml(s:String):void {
			assertNotNull(s);
			xml = s;
			setLength(s.length());
		}
		
		/**
		 * Returns the xml string for this component.
		 * Note that it may not be well-formed XML; it is a fragment.
		 */
		public function getXml():String {
			return xml;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + xml;
		}
		
		/**
		 * Visits this node.  There are no children to visit.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}

	}
}