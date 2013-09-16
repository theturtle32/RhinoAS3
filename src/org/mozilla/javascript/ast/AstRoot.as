package org.mozilla.javascript.ast
{
	import org.as3commons.collections.SortedSet;
	import org.as3commons.collections.framework.ISetIterator;
	import org.as3commons.collections.framework.core.SortedSetIterator;
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.NodeIterator;
	import org.mozilla.javascript.Token;

	public class AstRoot extends ScriptNode
	{
		private var comments:SortedSet;
		private var inStrictMode:Boolean;
		
		public function AstRoot(pos:int = -1)
		{
			super(pos);
			type = Token.SCRIPT;
		}
		
		/**
		 * Returns comment set
		 * @return comment set, sorted by start position. Can be {@code null}.
		 */
		public function getComments():SortedSet {
			return comments;
		}
		
		public function setComments(comments:SortedSet):void {
			if (comments === null) {
				this.comments = null;
			} else {
				if (this.comments !== null)
					this.comments.clear();
				for each (var c:Comment in comments) {
					addComment(c);
				}
			}
		}
		
		/**
		 * Add a comment to the comment set.
		 * @param comment the comment node.
		 * @throws IllegalArgumentException if comment is {@code null}
		 */
		public function addComment(comment:Comment):void {
			assertNotNull(comment);
			if (comments === null) {
				comments = new SortedSet(new PositionComparator());
			}
			comments.add(comment);
			comment.setParent(this);
		}
		
		public function setInStrictMode(inStrictMode:Boolean):void {
			this.inStrictMode = inStrictMode;
		}
		
		public function isInStrictMode():Boolean {
			return inStrictMode;
		}
		
		/**
		 * Visits the comment nodes in the order they appear in the source code.
		 * The comments are not visited by the {@link #visit} function - you must
		 * use this function to visit them.
		 * @param visitor the callback object.  It is passed each comment node.
		 * The return value is ignored.
		 */
		public function visitComments(visitor:NodeVisitor):void {
			if (comments !== null) {
				var iterator:SortedSetIterator = SortedSetIterator(comments.iterator());
				while (iterator.hasNext()) {
					var c:Comment = iterator.next();
					visitor.visit(c);
				}
			}
		}
		
		/**
		 * Visits the AST nodes, then the comment nodes.
		 * This method is equivalent to calling {@link #visit}, then
		 * {@link #visitComments}.  The return value
		 * is ignored while visiting comment nodes.
		 * @param visitor the callback object.
		 */
		public function visitAll(visitor:NodeVisitor):void {
			visit(visitor);
			visitComments(visitor);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = "";
			var i:NodeIterator = iterator();
			while (i.hasNext()) {
				sb += AstNode(i.next()).toSource(depth);
			}
			return sb;
		}
		
		override public function debugPrint():String {
			var dpv:DebugPrintVisitor = new DebugPrintVisitor();
			visitAll(dpv);
			return dpv.toString();
		}
	}
}