package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Node representing comments.
	 * Node type is {@link Token#COMMENT}.<p>
	 *
	 * <p>JavaScript effectively has five comment types:
	 *   <ol>
	 *     <li>// line comments</li>
	 *     <li>/<span class="none">* block comments *\/</li>
	 *     <li>/<span class="none">** jsdoc comments *\/</li>
	 *     <li>&lt;!-- html-open line comments</li>
	 *     <li>^\\s*--&gt; html-close line comments</li>
	 *   </ol>
	 *
	 * <p>The first three should be familiar to Java programmers.  JsDoc comments
	 * are really just block comments with some conventions about the formatting
	 * within the comment delimiters.  Line and block comments are described in the
	 * Ecma-262 specification. <p>
	 *
	 * <p>SpiderMonkey and Rhino also support HTML comment syntax, but somewhat
	 * counterintuitively, the syntax does not produce a block comment.  Instead,
	 * everything from the string &lt;!-- through the end of the line is considered
	 * a comment, and if the token --&gt; is the first non-whitespace on the line,
	 * then the line is considered a line comment.  This is to support parsing
	 * JavaScript in &lt;script&gt; HTML tags that has been "hidden" from very old
	 * browsers by surrounding it with HTML comment delimiters. <p>
	 *
	 * Note the node start position for Comment nodes is still relative to the
	 * parent, but Comments are always stored directly in the AstRoot node, so
	 * they are also effectively absolute offsets.
	 */
	public class Comment extends AstNode
	{
		private var value:String;
		private var commentType:int;

		/**
		 * Constructs a new Comment
		 * @param pos the start position
		 * @param len the length including delimiter(s)
		 * @param type the comment type
		 * @param value the value of the comment, as a string
		 */
		public function Comment(pos:int, len:int, type:int, value:String)
		{
			super(pos, len);
			this.type = Token.COMMENT;
			this.commentType = type;
			this.value = value;
		}
		
		/**
		 * Returns the comment style
		 */
		public function getCommentType():int {
			return commentType;
		}
		
		/**
		 * Sets the comment style
		 * @param type the comment style, a
		 * {@link org.mozilla.javascript.Token.CommentType}
		 */
		public function setCommentType(type:int):void {
			this.commentType = type;
		}
		
		/**
		 * Returns a string of the comment value.
		 */
		public function getValue():String {
			return value;
		}
		
		override public function toSource(depth:int = 0):String {
			var sb:String = "";
			sb += makeIndent(depth);
			sb += value;
			return sb;
		}
		
		/**
		 * Comment nodes are not visited during normal visitor traversals,
		 * but comply with the {@link AstNode#visit} interface.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}