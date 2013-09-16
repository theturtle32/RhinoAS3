package org.mozilla.javascript
{
	import org.mozilla.javascript.exception.IllegalStateError;
	import org.mozilla.javascript.exception.NoSuchElementError;

	public class NodeIterator
	{
		public static const NOT_SET:Node = new Node(Token.ERROR);
		
		private var cursor:Node; // points to node to be returned next
		private var prev:Node = NOT_SET;
		private var prev2:Node;
		private var removed:Boolean = false;
		private var node:Node;

		public function NodeIterator(node:Node)
		{
			this.node = node;
			cursor = this.node.first;
		}
		
		public function hasNext():Boolean {
			return cursor !== null;
		}
		
		public function next():Node {
			if (cursor === null) {
				throw new NoSuchElementError();
			}
			removed = false;
			prev2 = prev;
			prev = cursor;
			cursor = cursor.next;
			return prev;
		}
		
		public function remove():void {
			if (prev === NOT_SET) {
				throw new IllegalStateError("next() has not been called");
			}
			if (removed) {
				throw new IllegalStateError(
					"remove() already called for current element");
			}
			if (prev === node.first) {
				node.first = prev.next;
			} else if (prev === node.last) {
				prev2.next = cursor;
			}
		}
	}
}