package org.mozilla.javascript.ast
{
	/**
	 * AST node for an Object literal (also called an Object initialiser in
	 * Ecma-262).  The elements list will always be non-{@code null}, although
	 * the list will have no elements if the Object literal is empty.<p>
	 *
	 * Node type is {@link Token#OBJECTLIT}.<p>
	 *
	 * <pre><i>ObjectLiteral</i> :
	 *       <b>{}</b>
	 *       <b>{</b> PropertyNameAndValueList <b>}</b>
	 * <i>PropertyNameAndValueList</i> :
	 *       PropertyName <b>:</b> AssignmentExpression
	 *       PropertyNameAndValueList , PropertyName <b>:</b> AssignmentExpression
	 * <i>PropertyName</i> :
	 *       Identifier
	 *       StringLiteral
	 *       NumericLiteral</pre>
	 */
	public class ObjectLiteral extends AstNode implements IDestructuringForm
	{
		private static const NO_ELEMS:Vector.<ObjectProperty> = new Vector.<ObjectProperty>(0);
		
		private var elements:Vector.<ObjectProperty>;
		protected var _isDestructuring:Boolean;
		
		public function ObjectLiteral(pos:int=-1, len:int=-1)
		{
			super(pos, len);
		}
		
		/**
		 * Returns the element list.  Returns an immutable empty list if there are
		 * no elements.
		 */
		public function getElements():Vector.<ObjectProperty> {
			return elements !== null ? elements : NO_ELEMS;
		}
		
		/**
		 * Sets the element list, and updates the parent of each element.
		 * Replaces any existing elements.
		 * @param elements the element list.  Can be {@code null}.
		 */
		public function setElements(elements:Vector.<ObjectProperty>):void {
			this.elements = elements;
			if (this.elements !== null) {
				for each (var element:ObjectProperty in this.elements) {
					element.setParent(this);
				}
			}
		}
		
		/**
		 * Adds an element to the list, and sets its parent to this node.
		 * @param element the property node to append to the end of the list
		 * @throws IllegalArgumentException} if element is {@code null}
		 */
		public function addElement(element:ObjectProperty):void {
			assertNotNull(element);
			if (elements === null) {
				elements = new Vector.<ObjectProperty>();
			}
			elements.push(element);
			element.setParent(this);
		}
		
		/**
		 * Marks this node as being a destructuring form - that is, appearing
		 * in a context such as {@code for ([a, b] in ...)} where it's the
		 * target of a destructuring assignment.
		 */
		public function setIsDestructuring(destructuring:Boolean):void {
			_isDestructuring = destructuring;
		}
		
		/**
		 * Returns true if this node is in a destructuring position:
		 * a function parameter, the target of a variable initializer, the
		 * iterator of a for..in loop, etc.
		 */
		public function isDestructuring():Boolean {
			return _isDestructuring;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			var nodeList:Vector.<AstNode> = new Vector.<AstNode>();
			for (var i:int=0; i < elements.length; i++) {
				nodeList[i] = elements[i];
			}
			sb += "{";
			if (elements !== null) {
				sb += printList(nodeList);
			}
			sb += "}";
			return sb;
		}
		
		/**
		 * Visits this node, then visits each child property node, in lexical
		 * (source) order.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				for each (var prop:ObjectProperty in elements) {
					prop.visit(v);
				}
			}
		}
	}
}