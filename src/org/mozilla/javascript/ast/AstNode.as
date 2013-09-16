package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Kit;
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.Token;

	public class AstNode extends Node
	{
		protected var position:int = -1;
		protected var length:int = 1;
		protected var parent:AstNode;
		
		private static var operatorNames:Object = {};
		
		private static function classConstruct():Boolean {
			operatorNames[Token.IN] = "in";
			operatorNames[Token.TYPEOF] = "typeof";
			operatorNames[Token.INSTANCEOF] = "instanceof";
			operatorNames[Token.DELPROP] = "delete";
			operatorNames[Token.COMMA] = ",";
			operatorNames[Token.COLON] = ":";
			operatorNames[Token.OR] = "||";
			operatorNames[Token.AND] = "&&";
			operatorNames[Token.INC] = "++";
			operatorNames[Token.DEC] = "--";
			operatorNames[Token.BITOR] = "|";
			operatorNames[Token.BITXOR] = "^";
			operatorNames[Token.BITAND] = "&";
			operatorNames[Token.EQ] = "==";
			operatorNames[Token.NE] = "!=";
			operatorNames[Token.LT] = "<";
			operatorNames[Token.GT] = ">";
			operatorNames[Token.LE] = "<=";
			operatorNames[Token.GE] = ">=";
			operatorNames[Token.LSH] = "<<";
			operatorNames[Token.RSH] = ">>";
			operatorNames[Token.URSH] = ">>>";
			operatorNames[Token.ADD] = "+";
			operatorNames[Token.SUB] = "-";
			operatorNames[Token.MUL] = "*";
			operatorNames[Token.DIV] = "/";
			operatorNames[Token.MOD] = "%";
			operatorNames[Token.NOT] = "!";
			operatorNames[Token.BITNOT] = "~";
			operatorNames[Token.POS] = "+";
			operatorNames[Token.NEG] = "-";
			operatorNames[Token.SHEQ] = "===";
			operatorNames[Token.SHNE] = "!==";
			operatorNames[Token.ASSIGN] = "=";
			operatorNames[Token.ASSIGN_BITOR] = "|=";
			operatorNames[Token.ASSIGN_BITAND] = "&=";
			operatorNames[Token.ASSIGN_LSH] = "<<=";
			operatorNames[Token.ASSIGN_RSH] = ">>=";
			operatorNames[Token.ASSIGN_URSH] = ">>>=";
			operatorNames[Token.ASSIGN_ADD] = "+=";
			operatorNames[Token.ASSIGN_SUB] = "-=";
			operatorNames[Token.ASSIGN_MUL] = "*=";
			operatorNames[Token.ASSIGN_DIV] = "/=";
			operatorNames[Token.ASSIGN_MOD] = "%=";
			operatorNames[Token.ASSIGN_BITXOR] = "^=";
			operatorNames[Token.VOID] = "void";
			return true;
		}
		
		/**
		 * Constructs a new AstNode
		 * @param pos the start position
		 * @param len the number of characters spanned by the node in the source
		 * text
		 */
		public function AstNode(pos:int = -1, len:int = -1)
		{
			super(Token.ERROR);
			if (pos !== -1)
				position = pos;
			if (len !== -1) {
				length = len;
			}
		}
		
		/**
		 * Returns relative position in parent
		 */
		public function getPosition():int {
			return position;
		}
		
		/**
		 * Sets relative position in parent
		 */
		public function setPosition(position:int):void {
			this.position = position;
		}
		
		/**
		 * Returns the absolute document position of the node.
		 * Computes it by adding the node's relative position
		 * to the relative positions of all its parents.
		 */
		public function getAbsolutePosition():int {
			var pos:int = position;
			var parent:AstNode = this.parent;
			while (parent !== null) {
				pos += parent.getPosition();
				parent = parent.getParent();
			}
			return pos;
		}
		
		/**
		 * Returns node length
		 */
		public function getLength():int {
			return length;
		}
		
		/**
		 * Sets node length
		 */
		public function setLength(length:int):void {
			this.length = length;
		}
		
		/**
		 * Sets the node start and end positions.
		 * Computes the length as ({@code end} - {@code position}).
		 */
		public function setBounds(position:int, end:int):void {
			setPosition(position);
			setLength(end - position);
		}
		
		/**
		 * Make this node's position relative to a parent.
		 * Typically only used by the parser when constructing the node.
		 * @param parentPosition the absolute parent position; the
		 * current node position is assumed to be absolute and is
		 * decremented by parentPosition.
		 */
		public function setRelative(parentPosition:int):void {
			this.position -= parentPosition;
		}
		
		/**
		 * Returns the node parent, or {@code null} if it has none
		 */
		public function getParent():AstNode {
			return parent;
		}
		
		/**
		 * Sets the node parent.  This method automatically adjusts the
		 * current node's start position to be relative to the new parent.
		 * @param parent the new parent. Can be {@code null}.
		 */
		public function setParent(parent:AstNode):void {
			if (parent === this.parent) {
				return;
			}
			
			// Convert position back to absolute.
			if (this.parent !== null) {
				setRelative(-this.parent.getPosition());
			}
			
			this.parent = parent;
			if (parent !== null) {
				setRelative(parent.getPosition());
			}
		}
		
		/**
		 * Adds a child or function to the end of the block.
		 * Sets the parent of the child to this node, and fixes up
		 * the start position of the child to be relative to this node.
		 * Sets the length of this node to include the new child.
		 * @param kid the child
		 * @throws IllegalArgumentException if kid is {@code null}
		 */
		public function addChild(kid:AstNode):void {
			assertNotNull(kid);
			var end:int = kid.getPosition() + kid.getLength();
			setLength(end - this.getPosition());
			addChildToBack(kid);
			kid.setParent(this);
		}
				
		/**
		 * Returns the root of the tree containing this node.
		 * @return the {@link AstRoot} at the root of this node's parent
		 * chain, or {@code null} if the topmost parent is not an {@code AstRoot}.
		 */
		public function getAstRoot():AstRoot {
			var parent:AstNode = this;  // this node could be the AstRoot
			while (parent !== null && !(parent is AstRoot)) {
				parent = parent.getParent();
			}
			return AstRoot(parent);
		}
		
		/**
		 * Emits source code for this node.  Callee is responsible for calling this
		 * function recursively on children, incrementing indent as appropriate.<p>
		 *
		 * Note: if the parser was in error-recovery mode, some AST nodes may have
		 * {@code null} children that are expected to be non-{@code null}
		 * when no errors are present.  In this situation, the behavior of the
		 * {@code toSource} method is undefined: {@code toSource}
		 * implementations may assume that the AST node is error-free, since it is
		 * intended to be invoked only at runtime after a successful parse.<p>
		 *
		 * @param depth the current recursion depth, typically beginning at 0
		 * when called on the root node.
		 */
		public function toSource(depth:int = 0):String {
			throw new Error("toSource() not implemented by class");
		}
		
		public function makeIndent(indent:int):String {
			var sb:String = "";
			for (var i:int = 0; i < indent; i++) {
				sb += "  ";
			}
			return sb;
		}
		
		/**
		 * Returns the string name for this operator.
		 * @param op the token type, e.g. {@link Token#ADD} or {@link Token#TYPEOF}
		 * @return the source operator string, such as "+" or "typeof"
		 */
		public static function operatorToString(op:int):String {
			var result:String = operatorNames[op];
			if (result === null) {
				throw new ArgumentError("Invalid operator: " + op);
			}
			return result;
		}
		
		/**
		 * Visits this node and its children in an arbitrary order. <p>
		 *
		 * It's up to each node subclass to decide the order for processing
		 * its children.  The subclass also decides (and should document)
		 * which child nodes are not passed to the {@code NodeVisitor}.
		 * For instance, nodes representing keywords like {@code each} or
		 * {@code in} may not be passed to the visitor object.  The visitor
		 * can simply query the current node for these children if desired.<p>
		 *
		 * Generally speaking, the order will be deterministic; the order is
		 * whatever order is decided by each child node.  Normally child nodes
		 * will try to visit their children in lexical order, but there may
		 * be exceptions to this rule.<p>
		 *
		 * @param visitor the object to call with this node and its children
		 */
		public function visit(visitor:NodeVisitor):void {
			throw new Error("visit() not implemented by class");
		}
		
		/**
		 * Bounces an ArgumentError up if arg is {@code null}.
		 * @param arg any method argument
		 * @throws ArgumentError if the argument is {@code null}
		 */
		protected function assertNotNull(arg:Object):void {
			if (arg === null)
				throw new ArgumentError("arg cannot be null");
		}
		
		/**
		 * Prints a comma-separated item list into a {@link StringBuilder}.
		 * @param items a list to print
		 * @param sb a {@link StringBuilder} into which to print
		 */
		protected function printList(items:Vector.<AstNode>):String {
			var sb:String = "";
			var max:int = items.length;
			var count:int = 0;
			for each (var item:AstNode in items) {
				sb += item.toSource(0);
				if (count++ < max - 1) {
					sb += ", ";
				} else if (item is EmptyExpression) {
					sb += ",";
				}
			}
			return sb;
		}
		
		/**
		 * @see Kit#codeBug
		 */
		public static function codeBug():void {
			Kit.codeBug();
		}
		
		// TODO(stevey):  think of a way to have polymorphic toString
		// methods while keeping the ability to use Node.toString for
		// dumping the IR with Token.printTrees.  Most likely:  change
		// Node.toString to be Node.dumpTree and change callers to use that.
		// For now, need original toString, to compare output to old Rhino's.
		
		//     @Override
		//     public String toString() {
		//         return this.getClass().getName() + ": " +
		//             Token.typeToName(getType());
		//     }
		
		/**
		 * Returns the innermost enclosing function, or {@code null} if not in a
		 * function.  Begins the search with this node's parent.
		 * @return the {@link FunctionNode} enclosing this node, else {@code null}
		 */
		public function getEnclosingFunction():FunctionNode {
			var parent:AstNode = this.getParent();
			while (parent !== null && !(parent is FunctionNode)) {
				parent = parent.getParent();
			}
			return FunctionNode(parent);
		}
		
		/**
		 * Returns the innermost enclosing {@link Scope} node, or {@code null}
		 * if we're not nested in a scope.  Begins the search with this node's parent.
		 * Note that this is not the same as the defining scope for a {@link Name}.
		 *
		 * @return the {@link Scope} enclosing this node, else {@code null}
		 */
		public function getEnclosingScope():Scope {
			var parent:AstNode = this.getParent();
			while (parent !== null && !(parent is Scope)) {
				parent = parent.getParent();
			}
			return Scope(parent);
		}
		
		/**
		 * Permits AST nodes to be sorted based on start position and length.
		 * This makes it easy to sort Comment and Error nodes into a set of
		 * other AST nodes:  just put them all into a {@link java.util.SortedSet},
		 * for instance.
		 * @param other another node
		 * @return -1 if this node's start position is less than {@code other}'s
		 * start position.  If tied, -1 if this node's length is less than
		 * {@code other}'s length.  If the lengths are equal, sorts abitrarily
		 * on hashcode unless the nodes are the same per {@link #equals}.
		 */
		public function compareTo(other:AstNode):int {
			if (this === other) return 0;
			var abs1:int = this.getAbsolutePosition();
			var abs2:int = other.getAbsolutePosition();
			if (abs1 < abs2) return -1;
			if (abs2 < abs1) return 1;
			var len1:int = this.getLength();
			var len2:int = other.getLength();
			if (len1 < len2) return -1;
			if (len2 < len1) return 1;
			// return this.hashCode() - other.hashCode();
			// TODO: is hashCode() some kind of magic method provided by Java?
			return 0;
		}
		
		/**
		 * Returns the depth of this node.  The root is depth 0, its
		 * children are depth 1, and so on.
		 * @return the node depth in the tree
		 */
		public function depth():int {
			return parent === null ? 0 : 1 + parent.depth();
		}
		
		/**
		 * Return the line number recorded for this node.
		 * If no line number was recorded, searches the parent chain.
		 * @return the nearest line number, or -1 if none was found
		 */
		override public function getLineno():int {
			if (lineno !== -1)
				return lineno;
			if (parent !== null)
				return parent.getLineno();
			return -1;
		}
		
		/**
		 * Returns a debugging representation of the parse tree
		 * starting at this node.
		 * @return a very verbose indented printout of the tree.
		 * The format of each line is:  abs-pos  name position length [identifier]
		 */
		public function debugPrint():String {
			var dpv:DebugPrintVisitor = new DebugPrintVisitor();
			visit(dpv);
			return dpv.toString();
		}
		
		private static var classConstructed:Boolean = classConstruct();
		
	}
}

