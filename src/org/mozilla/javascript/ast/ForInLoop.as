package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	public class ForInLoop extends Loop
	{
		protected var iterator:AstNode;
		protected var iteratedObject:AstNode;
		protected var inPosition:int = -1;
		protected var eachPosition:int = -1;
		protected var _isForEach:Boolean;
		
		public function ForInLoop(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.FOR;
		}
		
		/**
		 * Returns loop iterator expression
		 */
		public function getIterator():AstNode {
			return iterator;
		}
		
		/**
		 * Sets loop iterator expression:  the part before the "in" keyword.
		 * Also sets its parent to this node.
		 * @throws ArgumentError if {@code iterator} is {@code null}
		 */
		public function setIterator(iterator:AstNode):void {
			assertNotNull(iterator);
			this.iterator = iterator;
			iterator.setParent(this);
		}
		
		/**
		 * Returns object being iterated over
		 */
		public function getIteratedObject():AstNode {
			return iteratedObject;
		}
		
		/**
		 * Sets object being iterated over, and sets its parent to this node.
		 * @throws ArgumentError if {@code object} is {@code null}
		 */
		public function setIteratedObject(object:AstNode):void {
			assertNotNull(object);
			this.iteratedObject = object;
			object.setParent(this);
		}
		
		/**
		 * Returns whether the loop is a for-each loop
		 */
		public function isForEach():Boolean {
			return _isForEach;
		}
		
		/**
		 * Sets whether the loop is a for-each loop
		 */
		public function setIsForEach(isForEach:Boolean):void {
			this._isForEach = isForEach;
		}
		
		/**
		 * Returns position of "in" keyword
		 */
		public function getInPosition():int {
			return inPosition;
		}
		
		/**
		 * Sets position of "in" keyword
		 * @param inPosition position of "in" keyword,
		 * or -1 if not present (e.g. in presence of a syntax error)
		 */
		public function setInPosition(inPosition:int):void {
			this.inPosition = inPosition;
		}
		
		/**
		 * Returns position of "each" keyword
		 */
		public function getEachPosition():int {
			return eachPosition;
		}
		
		/**
		 * Sets position of "each" keyword
		 * @param eachPosition position of "each" keyword,
		 * or -1 if not present.
		 */
		public function setEachPosition(eachPosition:int):void {
			this.eachPosition = eachPosition;
		}
		
		private function trim(s:String):String {
			// FIXME: Using Regexp for trim since AS3 has no trim function
			return (s === null) ? null : s.replace(/^\s+|\s+$/g, '');
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) +
							"for ";
			if (isForEach()) {
				sb += "each ";
			}
			sb += ("(" +
				   iterator.toSource(0) +
				   " in " +
				   iteratedObject.toSource(0) +
				   ") ");
			if (body.getType() === Token.BLOCK) {
				sb += (trim(body.toSource(depth)) + "\n");
			} else {
				sb += "\n" + body.toSource(depth+1);
			}
			return sb;	  
		}
		
		/**
		 * Visits this node, the iterator, the iterated object, and the body.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				iterator.visit(v);
				iteratedObject.visit(v);
				body.visit(v);
			}
		}
	}
}