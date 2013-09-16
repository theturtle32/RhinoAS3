package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for an E4X (Ecma-357) embedded XML literal.  Node type is
	 * {@link Token#XML}.  The parser generates a simple list of strings and
	 * expressions.  In the future we may parse the XML and produce a richer set of
	 * nodes, but for now it's just a set of expressions evaluated to produce a
	 * string to pass to the {@code XML} constructor function.<p>
	 */
	public class XmlLiteral extends AstNode
	{
		private var fragments:Vector.<XmlFragment> = new Vector.<XmlFragment>();
		
		public function XmlLiteral(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.XML;
		}
		
		/**
		 * Returns fragment list - a list of expression nodes.
		 */
		public function getFragments():Vector.<XmlFragment> {
			return fragments;
		}
		
		/**
		 * Sets fragment list, removing any existing fragments first.
		 * Sets the parent pointer for each fragment in the list to this node.
		 * @param fragments fragment list.  Replaces any existing fragments.
		 * @throws IllegalArgumentException} if {@code fragments} is {@code null}
		 */
		public function setFragments(fragments:Vector.<XmlFragment>):void {
			assertNotNull(fragments);
			this.fragments = fragments;
			for each (var fragment:XmlFragment in this.fragments) {
				fragment.setParent(this);
			}
		}
		
		/**
		 * Adds a fragment to the fragment list.  Sets its parent to this node.
		 * @throws IllegalArgumentException} if {@code fragment} is {@code null}
		 */
		public function addFragment(fragment:XmlFragment):void {
			assertNotNull(fragment);
			fragments.push(fragment);
			fragment.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = "";
			for each (var frag:XmlFragment in fragments) {
				sb += frag.toSource(0);
			}
			return sb;
		}
		
		/**
		 * Visits this node, then visits each child fragment in lexical order.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				for each (var frag:XmlFragment in fragments) {
					frag.visit(v);
				}
			}
		}
	}
}