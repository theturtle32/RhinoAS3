package org.mozilla.javascript.ast
{
	/**
	 * AST node for an Array literal.  The elements list will always be
	 * non-{@code null}, although the list will have no elements if the Array literal
	 * is empty.<p>
	 *
	 * Node type is {@link Token#ARRAYLIT}.<p>
	 *
	 * <pre><i>ArrayLiteral</i> :
	 *        <b>[</b> Elisionopt <b>]</b>
	 *        <b>[</b> ElementList <b>]</b>
	 *        <b>[</b> ElementList , Elisionopt <b>]</b>
	 * <i>ElementList</i> :
	 *        Elisionopt AssignmentExpression
	 *        ElementList , Elisionopt AssignmentExpression
	 * <i>Elision</i> :
	 *        <b>,</b>
	 *        Elision <b>,</b></pre>
	 */
	public class ArrayLiteral extends AstNode implements IDestructuringForm
	{
		private static const NO_ELEMS:Vector.<AstNode> = new Vector.<AstNode>(0);
		
		private var elements:Vector.<AstNode>;
		private var destructuringLength:int;
		private var skipCount:int;
		private var _isDestructuring:Boolean;
		
		public function ArrayLiteral(pos:int=-1, len:int=-1)
		{
			super(pos, len);
		}
		
		/**
		 * Returns the element list
		 * @return the element list.  If there are no elements, returns an immutable
		 *         empty list.  Elisions are represented as {@link EmptyExpression}
		 *         nodes.
		 */
		public function getElements():Vector.<AstNode> {
			return elements !== null ? elements : NO_ELEMS;
		}
		
		/**
		 * Sets the element list, and sets each element's parent to this node.
		 * @param elements the element list.  Can be {@code null}.
		 */
		public function setElements(elements:Vector.<AstNode>):void {
			this.elements = elements;
			if (this.elements !== null) {
				for each (var e:AstNode in this.elements) {
					e.setParent(this);
				}
			}
		}
		
		/**
		 * Adds an element to the list, and sets its parent to this node.
		 * @param element the element to add
		 * @throws IllegalArgumentException if element is {@code null}.  To indicate
		 *         an empty element, use an {@link EmptyExpression} node.
		 */
		public function addElement(element:AstNode):void {
			assertNotNull(element);
			if (elements === null)
				elements = new Vector.<AstNode>();
			elements.push(element);
			element.setParent(this);
		}
		
		/**
		 * Returns the number of elements in this {@code Array} literal,
		 * including empty elements.
		 */
		public function getSize():int {
			return elements === null ? 0 : elements.length;
		}
		
		/**
		 * Returns element at specified index.
		 * @param index the index of the element to retrieve
		 * @return the element
		 * @throws IndexOutOfBoundsException if the index is invalid
		 */
		public function getElement(index:int):AstNode {
			if (elements === null)
				throw new Error("Index out of bounds: no elements");
			return elements[index];
		}
		
		/**
		 * Returns destructuring length
		 */
		public function getDestructuringLength():int {
			return destructuringLength;
		}
		
		/**
		 * Sets destructuring length.  This is set by the parser and used
		 * by the code generator.  {@code for ([a,] in obj)} is legal,
		 * but {@code for ([a] in obj)} is not since we have both key and
		 * value supplied.  The difference is only meaningful in array literals
		 * used in destructuring-assignment contexts.
		 */
		public function setDestructuringLength(destructuringLength:int):void {
			this.destructuringLength = destructuringLength;
		}
		
		/**
		 * Used by code generator.
		 * @return the number of empty elements
		 */
		public function getSkipCount():int {
			return skipCount;
		}
		
		/**
		 * Used by code generator.
		 * @param count the count of empty elements
		 */
		public function setSkipCount(count:int):void {
			skipCount = count;
		}
		
		/**
		 * Marks this node as being a destructuring form - that is, appearing
		 * in a context such as {@code for ([a, b] in ...)} where it's the
		 * target of a destructuring assignment.
		 */
		public function setIsDestructuring(destructuring:Boolean):void
		{
			_isDestructuring = destructuring;
		}
		
		/**
		 * Returns true if this node is in a destructuring position:
		 * a function parameter, the target of a variable initializer, the
		 * iterator of a for..in loop, etc.
		 */
		public function isDestructuring():Boolean
		{
			return _isDestructuring;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			sb += "[";
			if (elements !== null) {
				sb += printList(elements);
			}
			sb += "]";
			return sb;
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				for each (var e:AstNode in getElements()) {
					e.visit(v);
				}
			}
		}
	}
}