package org.mozilla.javascript
{
	import org.mozilla.javascript.ast.Comment;
	import org.mozilla.javascript.ast.Jump;
	import org.mozilla.javascript.ast.Name;
	import org.mozilla.javascript.ast.NumberLiteral;
	import org.mozilla.javascript.ast.Scope;
	import org.mozilla.javascript.ast.ScriptNode;

	public class Node
	{
		public static const
			FUNCTION_PROP:int = 1,
			LOCAL_PROP:int = 2,
			LOCAL_BLOCK_PROP:int = 3,
			REGEXP_PROP:int = 4,
			CASEARRAY_PROP:int = 5,
			
		//  the following properties are defined and manipulated by the
		//  optimizer -
		//  TARGETBLOCK_PROP - the block referenced by a branch node
		//  VARIABLE_PROP - the variable referenced by a BIND or NAME node
		//  ISNUMBER_PROP - this node generates code on Number children and
		//                  delivers a Number result (as opposed to Objects)
		//  DIRECTCALL_PROP - this call node should emit code to test the function
		//                    object against the known class and call direct if it
		//                    matches.
			
			TARGETBLOCK_PROP:int     =  6,
			VARIABLE_PROP:int        =  7,
			ISNUMBER_PROP:int        =  8,
			DIRECTCALL_PROP:int      =  9,
			SPECIALCALL_PROP:int     = 10,
			SKIP_INDEXES_PROP:int    = 11, // array of skipped indexes of array literal
			OBJECT_IDS_PROP:int      = 12, // array of properties for object literal
			INCRDECR_PROP:int        = 13, // pre or post type of increment/decrement
			CATCH_SCOPE_PROP:int     = 14, // index of catch scope block in catch
			LABEL_ID_PROP:int        = 15, // label id: code generation uses it
			MEMBER_TYPE_PROP:int     = 16, // type of element access operation
			NAME_PROP:int            = 17, // property name
			CONTROL_BLOCK_PROP:int   = 18, // flags a control block that can drop off
			PARENTHESIZED_PROP:int   = 19, // expression is parenthesized
			GENERATOR_END_PROP:int   = 20,
			DESTRUCTURING_ARRAY_LENGTH:int = 21,
			DESTRUCTURING_NAMES:int  = 22,
			DESTRUCTURING_PARAMS:int = 23,
			JSDOC_PROP:int           = 24,
			EXPRESSION_CLOSURE_PROP:int = 25, // JS 1.8 expression closure pseudo-return
			DESTRUCTURING_SHORTHAND:int = 26, // JS 1.8 destructuring shorthand
			LAST_PROP:int            = 26;			
			
		// values of ISNUMBER_PROP to specify
		// which of the children are Number types
		public static const
			BOTH:int = 0,
			LEFT:int = 1,
			RIGHT:int = 2;
		
		public static const    // values for SPECIALCALL_PROP
			NON_SPECIALCALL:int  = 0,
			SPECIALCALL_EVAL:int = 1,
			SPECIALCALL_WITH:int = 2;
		
		public static const    // flags for INCRDECR_PROP
			DECR_FLAG:int = 0x1,
			POST_FLAG:int = 0x2;
		
		public static const    // flags for MEMBER_TYPE_PROP
			PROPERTY_FLAG:int    = 0x1, // property access: element is valid name
			ATTRIBUTE_FLAG:int   = 0x2, // x.@y or x..@y
			DESCENDANTS_FLAG:int = 0x4; // x..y or x..@i
			
		protected var type:int = Token.ERROR;
		internal var next:Node;
		internal var first:Node;
		internal var last:Node;
		protected var lineno:int = -1;
		
		/**
		 * Linked list of properties. Since vast majority of nodes would have
		 * no more then 2 properties, linked list saves memory and provides
		 * fast lookup. If this does not holds, propListHead can be replaced
		 * by UintMap.
		 */
		protected var propListHead:PropListItem;
			
		public function Node(nodeType:int,
							 child:Node = null,
							 left:Node = null,
							 mid:Node = null,
							 right:Node = null,
							 line:int = -1)
		{
			type = nodeType;
			if (line !== -1) {
				lineno = line;
			}
			if (child !== null) {
				first = last = child;
				child.next = null;
				return;
			}
			if (left !== null && right !== null) {
				if (mid === null) {
					first = left;
					last = right;
					left.next = right;
					right.next = null;
				}
				else {
					first = left;
					last = right;
					left.next = mid;
					mid.next = right;
					right.next = null;
				}
			}
		}
		
		public static function newNumber(number:Number):Node {
			var n:NumberLiteral = new NumberLiteral();
			n.setNumber(number);
			return n;
		}

		public static function newString(str:String = null, type:int = Token.STRING):Node {
			if (str === null) throw new ArgumentError("str cannot be null");
			var name:Name = new Name();
			name.setIdentifier(str);
			name.setType(type);
			return name;
		}
		
		public function getType():int {
			return type;
		}
		
		/**
		 * Sets the node type and returns this node.
		 */
		public function setType(type:int):Node {
			this.type = type;
			return this;
		}
		
		/**
		 * Gets the JsDoc comment string attached to this node.
		 * @return the comment string or {@code null} if no JsDoc is attached to
		 *     this node
		 */
		public function getJsDoc():String {
			var comment:Comment = getJsDocNode();
			if (comment !== null) {
				return comment.getValue();
			}
			return null;
		}
		
		/**
		 * Gets the JsDoc Comment object attached to this node.
		 * @return the Comment or {@code null} if no JsDoc is attached to
		 *     this node
		 */
		public function getJsDocNode():Comment {
			return Comment(getProp(JSDOC_PROP));
		}
		
		/**
		 * Sets the JsDoc comment string attached to this node.
		 */
		public function setJsDocNode(jsdocNode:Comment):void {
			putProp(JSDOC_PROP, jsdocNode);
		}
		
		public function hasChildren():Boolean {
			return first !== null;
		}
		
		public function getFirstChild():Node {
			return first;
		}
		
		public function getLastChild():Node {
			return last;
		}
		
		public function getNext():Node {
			return next;
		}
		
		public function setNext(next:Node):void {
			this.next = next;
		}
		
		public function getChildBefore(child:Node):Node {
			if (child === first)
				return null;
			var n:Node = first;
			while (n.next !== child) {
				n = n.next;
				if (n === null)
					throw new Error("node is not a child");
			}
			return n;
		}
		
		public function getLastSibling():Node {
			var n:Node = this;
			while (n.next !== null) {
				n = n.next;
			}
			return n;
		}
		
		public function addChildToFront(child:Node):void {
			child.next = first;
			first = child;
			if (last === null) {
				last = child;
			}
		}
		
		public function addChildToBack(child:Node):void {
			child.next = null;
			if (last === null) {
				first = last = child;
				return;
			}
			last.next = child;
			last = child;
		}
		
		public function addChildrenToFront(children:Node):void {
			var lastSib:Node = children.getLastSibling();
			lastSib.next = first;
			first = children;
			if (last === null) {
				last = lastSib;
			}
		}
		
		public function addChildrenToBack(children:Node):void {
			if (last !== null) {
				last.next = children;
			}
			last = children.getLastSibling();
			if (first === null) {
				first = children;
			}
		}
		
		/**
		 * Add 'child' before 'node'.
		 */
		public function addChildBefore(newChild:Node, node:Node):void {
			if (newChild.next !== null)
				throw new Error(
					"newChild had siblings in addChildBefore");
			if (first === node) {
				newChild.next = first;
				first = newChild;
				return;
			}
			var prev:Node = getChildBefore(node);
			addChildAfter(newChild, prev);
		}
		
		/**
		 * Add 'child' after 'node'.
		 */
		public function addChildAfter(newChild:Node, node:Node):void {
			if (newChild.next !== null)
				throw new Error(
					"newChild had siblings in addChildAfter");
			newChild.next = node.next;
			node.next = newChild;
			if (last === node)
				last = newChild;
		}
		
		public function removeChild(child:Node):void {
			var prev:Node = getChildBefore(child);
			if (prev === null)
				first = first.next;
			else
				prev.next = child.next;
			if (child === last) last = prev;
			child.next = null;
		}
		
		public function replaceChild(child:Node, newChild:Node):void {
			newChild.next = child.next;
			if (child === first) {
				first = newChild;
			} else {
				var prev:Node = getChildBefore(child);
				prev.next = newChild;
			}
			if (child === last)
				last = newChild;
			child.next = null;
		}
		
		public function replaceChildAfter(prevChild:Node, newChild:Node):void {
			var child:Node = prevChild.next;
			newChild.next = child.next;
			prevChild.next = newChild;
			if (child === next)
				last = newChild;
			child.next = null;
		}
		
		public function removeChildren():void {
			first = last = null;
		}
		
		public function iterator():NodeIterator {
			return new NodeIterator(this);
		}
		
		private static function propToString(propType:int):String {
			if (Token.printTrees) {
				// If Context.printTrees is false, the compiler
				// can remove all these strings.
				switch (propType) {
					case FUNCTION_PROP:        return "function";
					case LOCAL_PROP:           return "local";
					case LOCAL_BLOCK_PROP:     return "local_block";
					case REGEXP_PROP:          return "regexp";
					case CASEARRAY_PROP:       return "casearray";
						
					case TARGETBLOCK_PROP:     return "targetblock";
					case VARIABLE_PROP:        return "variable";
					case ISNUMBER_PROP:        return "isnumber";
					case DIRECTCALL_PROP:      return "directcall";
						
					case SPECIALCALL_PROP:     return "specialcall";
					case SKIP_INDEXES_PROP:    return "skip_indexes";
					case OBJECT_IDS_PROP:      return "object_ids_prop";
					case INCRDECR_PROP:        return "incrdecr_prop";
					case CATCH_SCOPE_PROP:     return "catch_scope_prop";
					case LABEL_ID_PROP:        return "label_id_prop";
					case MEMBER_TYPE_PROP:     return "member_type_prop";
					case NAME_PROP:            return "name_prop";
					case CONTROL_BLOCK_PROP:   return "control_block_prop";
					case PARENTHESIZED_PROP:   return "parenthesized_prop";
					case GENERATOR_END_PROP:   return "generator_end";
					case DESTRUCTURING_ARRAY_LENGTH:
						return "destructuring_array_length";
					case DESTRUCTURING_NAMES:  return "destructuring_names";
					case DESTRUCTURING_PARAMS: return "destructuring_params";
						
					default: Kit.codeBug();
				}
			}
			return null;
		}
		
		private function lookupProperty(propType:int):PropListItem {
			var x:PropListItem = propListHead;
			while (x !== null && propType !== x.type) {
				x = x.next;
			}
			return x;
		}
		
		private function ensureProperty(propType:int):PropListItem {
			var item:PropListItem = lookupProperty(propType);
			if (item === null) {
				item = new PropListItem();
				item.type = propType;
				item.next = propListHead;
				propListHead = item;
			}
			return item;
		}
		
		public function removeProp(propType:int):void {
			var x:PropListItem = propListHead;
			if (x !== null) {
				var prev:PropListItem = null;
				while (x.type !== propType) {
					prev = x;
					x = x.next;
					if (x === null) { return; }
				}
				if (prev === null) {
					propListHead = x.next;
				} else {
					prev.next = x.next;
				}
			}
		}
		
		public function getProp(propType:int):Object {
			var item:PropListItem = lookupProperty(propType);
			if (item === null) { return null; }
			return item.objectValue;
		}
		
		public function getIntProp(propType:int, defaultValue:int):int {
			var item:PropListItem = lookupProperty(propType);
			if (item === null) { return defaultValue; }
			return item.intValue;
		}
		
		public function getExistingIntProp(propType:int):int {
			var item:PropListItem = lookupProperty(propType);
			if (item === null) { Kit.codeBug(); }
			return item.intValue;
		}
		
		public function putProp(propType:int, prop:Object):void {
			if (prop === null) {
				removeProp(propType);
			} else {
				var item:PropListItem = ensureProperty(propType);
				item.objectValue = prop;
			}
		}
		
		public function putIntProp(propType:int, prop:int):void {
			var item:PropListItem = ensureProperty(propType);
			item.intValue = prop;
		}
		
		/**
		 * Return the line number recorded for this node.
		 * @return the line number
		 */
		public function getLineno():int {
			return lineno;
		}
		
		public function setLineno(lineno:int):void {
			this.lineno = lineno;
		}
		
		/** Can only be called when <tt>getType() == Token.NUMBER</tt> */
		public function getDouble():Number {
			return NumberLiteral(this).getNumber();
		}
		
		public function setDouble(number:Number):void {
			NumberLiteral(this).setNumber(number);
		}
		
		/** Can only be called when node has String context. */
		public function getString():String {
			return Name(this).getIdentifier();
		}
		
		/** Can only be called when node has String context. */
		public function setString(s:String):void {
			if (s === null) Kit.codeBug();
			Name(this).setIdentifier(s);
		}
		
		/** Can only be called when node has String context. */
		public function getScope():Scope {
			return Name(this).getScope();
		}
		
		/** Can only be called when node has String context. */
		public function setScope(s:Scope):void {
			if (s === null) Kit.codeBug();
			if (!(this is Name)) {
				throw Kit.codeBug();
			}
			Name(this).setScope(s);
		}
		
		public static function newTarget():Node {
			return new Node(Token.TARGET);
		}
		
		public function labelId():int {
			if (type !== Token.TARGET && type !== Token.YIELD) Kit.codeBug();
			return getIntProp(LABEL_ID_PROP, -1);
		}
		
		public function setLabelId(labelId:int):void {
			if (type !== Token.TARGET && type !== Token.YIELD) Kit.codeBug();
			putIntProp(LABEL_ID_PROP, labelId);
		}
		
		/**
		 * Does consistent-return analysis on the function body when strict mode is
		 * enabled.
		 *
		 *   function (x) { return (x+1) }
		 * is ok, but
		 *   function (x) { if (x &lt; 0) return (x+1); }
		 * is not becuase the function can potentially return a value when the
		 * condition is satisfied and if not, the function does not explicitly
		 * return value.
		 *
		 * This extends to checking mismatches such as "return" and "return <value>"
		 * used in the same function. Warnings are not emitted if inconsistent
		 * returns exist in code that can be statically shown to be unreachable.
		 * Ex.
		 * <pre>function (x) { while (true) { ... if (..) { return value } ... } }
		 * </pre>
		 * emits no warning. However if the loop had a break statement, then a
		 * warning would be emitted.
		 *
		 * The consistency analysis looks at control structures such as loops, ifs,
		 * switch, try-catch-finally blocks, examines the reachable code paths and
		 * warns the user about an inconsistent set of termination possibilities.
		 *
		 * Caveat: Since the parser flattens many control structures into almost
		 * straight-line code with gotos, it makes such analysis hard. Hence this
		 * analyser is written to taken advantage of patterns of code generated by
		 * the parser (for loops, try blocks and such) and does not do a full
		 * control flow analysis of the gotos and break/continue statements.
		 * Future changes to the parser will affect this analysis.
		 */
		
		/**
		 * These flags enumerate the possible ways a statement/function can
		 * terminate. These flags are used by endCheck() and by the Parser to
		 * detect inconsistent return usage.
		 *
		 * END_UNREACHED is reserved for code paths that are assumed to always be
		 * able to execute (example: throw, continue)
		 *
		 * END_DROPS_OFF indicates if the statement can transfer control to the
		 * next one. Statement such as return dont. A compound statement may have
		 * some branch that drops off control to the next statement.
		 *
		 * END_RETURNS indicates that the statement can return (without arguments)
		 * END_RETURNS_VALUE indicates that the statement can return a value.
		 *
		 * A compound statement such as
		 * if (condition) {
		 *   return value;
		 * }
		 * Will be detected as (END_DROPS_OFF | END_RETURN_VALUE) by endCheck()
		 */
		public static const END_UNREACHED:int = 0;
		public static const END_DROPS_OFF:int = 1;
		public static const END_RETURNS:int = 2;
		public static const END_RETURNS_VALUE:int = 4;
		public static const END_YIELDS:int = 8;
		
		/**
		 * Checks that every return usage in a function body is consistent with the
		 * requirements of strict-mode.
		 * @return true if the function satisfies strict mode requirement.
		 */
		public function hasConsistentReturnUsage():Boolean {
			var n:int = endCheck();
			return (n & END_RETURNS_VALUE) === 0 ||
				   (n & (END_DROPS_OFF|END_RETURNS|END_YIELDS)) === 0;
		}
		
		/**
		 * Returns in the then and else blocks must be consistent with each other.
		 * If there is no else block, then the return statement can fall through.
		 * @return logical OR of END_* flags
		 */
		public function endCheckIf():int {
			var th:Node, el:Node;
			var rv:int = END_UNREACHED;
			
			th = next;
			el = Jump(this).target;
			
			rv = th.endCheck();
			
			if (el !== null)
				rv |= el.endCheck();
			else
				rv |= END_DROPS_OFF;
			
			return rv;
		}
		
		/**
		 * Consistency of return statements is checked between the case statements.
		 * If there is no default, then the switch can fall through. If there is a
		 * default,we check to see if all code paths in the default return or if
		 * there is a code path that can fall through.
		 * @return logical OR of END_* flags
		 */
		private function endCheckSwitch():int {
			var rv:int = END_UNREACHED;
			
			// examine the cases
			//         for (n = first.next; n != null; n = n.next)
			//         {
			//             if (n.type == Token.CASE) {
			//                 rv |= ((Jump)n).target.endCheck();
			//             } else
			//                 break;
			//         }
			
			//         // we don't care how the cases drop into each other
			//         rv &= ~END_DROPS_OFF;
			
			//         // examine the default
			//         n = ((Jump)this).getDefault();
			//         if (n != null)
			//             rv |= n.endCheck();
			//         else
			//             rv |= END_DROPS_OFF;
			
			//         // remove the switch block
			//         rv |= getIntProp(CONTROL_BLOCK_PROP, END_UNREACHED);
			
			return rv;
		}
		
		/**
		 * If the block has a finally, return consistency is checked in the
		 * finally block. If all code paths in the finally returns, then the
		 * returns in the try-catch blocks don't matter. If there is a code path
		 * that does not return or if there is no finally block, the returns
		 * of the try and catch blocks are checked for mismatch.
		 * @return logical OR of END_* flags
		 */
		private function endCheckTry():int
		{
			var rv:int = END_UNREACHED;
			
			// a TryStatement isn't a jump - needs rewriting
			
			// check the finally if it exists
			//         n = ((Jump)this).getFinally();
			//         if(n != null) {
			//             rv = n.next.first.endCheck();
			//         } else {
			//             rv = END_DROPS_OFF;
			//         }
			
			//         // if the finally block always returns, then none of the returns
			//         // in the try or catch blocks matter
			//         if ((rv & END_DROPS_OFF) != 0) {
			//             rv &= ~END_DROPS_OFF;
			
			//             // examine the try block
			//             rv |= first.endCheck();
			
			//             // check each catch block
			//             n = ((Jump)this).target;
			//             if (n != null)
			//             {
			//                 // point to the first catch_scope
			//                 for (n = n.next.first; n != null; n = n.next.next)
			//                 {
			//                     // check the block of user code in the catch_scope
			//                     rv |= n.next.first.next.first.endCheck();
			//                 }
			//             }
			//         }
			
			return rv;
		}
		
		/**
		 * Return statement in the loop body must be consistent. The default
		 * assumption for any kind of a loop is that it will eventually terminate.
		 * The only exception is a loop with a constant true condition. Code that
		 * follows such a loop is examined only if one can statically determine
		 * that there is a break out of the loop.
		 * <pre>
		 *  for(&lt;&gt; ; &lt;&gt;; &lt;&gt;) {}
		 *  for(&lt;&gt; in &lt;&gt; ) {}
		 *  while(&lt;&gt;) { }
		 *  do { } while(&lt;&gt;)
		 * </pre>
		 * @return logical OR of END_* flags
		 */
		private function endCheckLoop():int
		{
			var n:Node,
				rv:int = END_UNREACHED;
			
			// To find the loop body, we look at the second to last node of the
			// loop node, which should be the predicate that the loop should
			// satisfy.
			// The target of the predicate is the loop-body for all 4 kinds of
			// loops.
			for (n = first; n.next != last; n = n.next) {
				/* skip */
			}
			if (n.type !== Token.IFEQ)
				return END_DROPS_OFF;
			
			// The target's next is the loop body block
			rv = Jump(n).target.next.endCheck();
			
			// check to see if the loop condition is true
			if (n.first.type == Token.TRUE)
				rv &= ~END_DROPS_OFF;
			
			// look for effect of breaks
			rv |= getIntProp(CONTROL_BLOCK_PROP, END_UNREACHED);
			
			return rv;
		}
		
		/**
		 * A general block of code is examined statement by statement. If any
		 * statement (even compound ones) returns in all branches, then subsequent
		 * statements are not examined.
		 * @return logical OR of END_* flags
		 */
		private function endCheckBlock():int
		{
			var n:Node,
				rv:int = END_DROPS_OFF;
			
			// check each statment and if the statement can continue onto the next
			// one, then check the next statement
			for (n=first; ((rv & END_DROPS_OFF) != 0) && n != null; n = n.next)
			{
				rv &= ~END_DROPS_OFF;
				rv |= n.endCheck();
			}
			return rv;
		}
		
		/**
		 * A labelled statement implies that there maybe a break to the label. The
		 * function processes the labelled statement and then checks the
		 * CONTROL_BLOCK_PROP property to see if there is ever a break to the
		 * particular label.
		 * @return logical OR of END_* flags
		 */
		private function endCheckLabel():int
		{
			var rv:int = END_UNREACHED;
			
			rv = next.endCheck();
			rv |= getIntProp(CONTROL_BLOCK_PROP, END_UNREACHED);
			
			return rv;
		}
		
		/**
		 * When a break is encountered annotate the statement being broken
		 * out of by setting its CONTROL_BLOCK_PROP property.
		 * @return logical OR of END_* flags
		 */
		private function endCheckBreak():int
		{
			var n:Node = Jump(this).getJumpStatement();
			n.putIntProp(CONTROL_BLOCK_PROP, END_DROPS_OFF);
			return END_UNREACHED;
		}
		
		/**
		 * endCheck() examines the body of a function, doing a basic reachability
		 * analysis and returns a combination of flags END_* flags that indicate
		 * how the function execution can terminate. These constitute only the
		 * pessimistic set of termination conditions. It is possible that at
		 * runtime certain code paths will never be actually taken. Hence this
		 * analysis will flag errors in cases where there may not be errors.
		 * @return logical OR of END_* flags
		 */
		protected function endCheck():int
		{
			switch(type)
			{
				case Token.BREAK:
					return endCheckBreak();
					
				case Token.EXPR_VOID:
					if (this.first != null)
						return first.endCheck();
					return END_DROPS_OFF;
					
				case Token.YIELD:
					return END_YIELDS;
					
				case Token.CONTINUE:
				case Token.THROW:
					return END_UNREACHED;
					
				case Token.RETURN:
					if (this.first != null)
						return END_RETURNS_VALUE;
					else
						return END_RETURNS;
					
				case Token.TARGET:
					if (next != null)
						return next.endCheck();
					else
						return END_DROPS_OFF;
					
				case Token.LOOP:
					return endCheckLoop();
					
				case Token.LOCAL_BLOCK:
				case Token.BLOCK:
					// there are several special kinds of blocks
					if (first == null)
						return END_DROPS_OFF;
					
					switch(first.type) {
						case Token.LABEL:
							return first.endCheckLabel();
							
						case Token.IFNE:
							return first.endCheckIf();
							
						case Token.SWITCH:
							return first.endCheckSwitch();
							
						case Token.TRY:
							return first.endCheckTry();
							
						default:
							return endCheckBlock();
					}
					
				default:
					return END_DROPS_OFF;
			}
		}
		
		public function hasSideEffects():Boolean
		{
			switch (type) {
				case Token.EXPR_VOID:
				case Token.COMMA:
					if (last != null)
						return last.hasSideEffects();
					else
						return true;
					
				case Token.HOOK:
					if (first == null ||
						first.next == null ||
						first.next.next == null)
						Kit.codeBug();
					return first.next.hasSideEffects() &&
					first.next.next.hasSideEffects();
					
				case Token.AND:
				case Token.OR:
					if (first == null || last == null)
						Kit.codeBug();
					return first.hasSideEffects() || last.hasSideEffects();
					
				case Token.ERROR:         // Avoid cascaded error messages
				case Token.EXPR_RESULT:
				case Token.ASSIGN:
				case Token.ASSIGN_ADD:
				case Token.ASSIGN_SUB:
				case Token.ASSIGN_MUL:
				case Token.ASSIGN_DIV:
				case Token.ASSIGN_MOD:
				case Token.ASSIGN_BITOR:
				case Token.ASSIGN_BITXOR:
				case Token.ASSIGN_BITAND:
				case Token.ASSIGN_LSH:
				case Token.ASSIGN_RSH:
				case Token.ASSIGN_URSH:
				case Token.ENTERWITH:
				case Token.LEAVEWITH:
				case Token.RETURN:
				case Token.GOTO:
				case Token.IFEQ:
				case Token.IFNE:
				case Token.NEW:
				case Token.DELPROP:
				case Token.SETNAME:
				case Token.SETPROP:
				case Token.SETELEM:
				case Token.CALL:
				case Token.THROW:
				case Token.RETHROW:
				case Token.SETVAR:
				case Token.CATCH_SCOPE:
				case Token.RETURN_RESULT:
				case Token.SET_REF:
				case Token.DEL_REF:
				case Token.REF_CALL:
				case Token.TRY:
				case Token.SEMI:
				case Token.INC:
				case Token.DEC:
				case Token.IF:
				case Token.ELSE:
				case Token.SWITCH:
				case Token.WHILE:
				case Token.DO:
				case Token.FOR:
				case Token.BREAK:
				case Token.CONTINUE:
				case Token.VAR:
				case Token.CONST:
				case Token.LET:
				case Token.LETEXPR:
				case Token.WITH:
				case Token.WITHEXPR:
				case Token.CATCH:
				case Token.FINALLY:
				case Token.BLOCK:
				case Token.LABEL:
				case Token.TARGET:
				case Token.LOOP:
				case Token.JSR:
				case Token.SETPROP_OP:
				case Token.SETELEM_OP:
				case Token.LOCAL_BLOCK:
				case Token.SET_REF_OP:
				case Token.YIELD:
					return true;
					
				default:
					return false;
			}
		}
		
		/**
		 * Recursively unlabel every TARGET or YIELD node in the tree.
		 *
		 * This is used and should only be used for inlining finally blocks where
		 * jsr instructions used to be. It is somewhat hackish, but implementing
		 * a clone() operation would take much, much more effort.
		 *
		 * This solution works for inlining finally blocks because you should never
		 * be writing any given block to the class file simultaneously. Therefore,
		 * an unlabeling will never occur in the middle of a block.
		 */
		public function resetTargets():void
		{
			if (type == Token.FINALLY) {
				resetTargets_r();
			} else {
				Kit.codeBug();
			}
		}
		
		private function resetTargets_r():void
		{
			if (type == Token.TARGET || type == Token.YIELD) {
				setLabelId(-1);
			}
			var child:Node = first;
			while (child != null) {
				child.resetTargets_r();
				child = child.next;
			}
		}
		
		public function toString():String {
			if (Token.printTrees) {
				throw new Error("printTrees functionality not yet implemented in Node class.");
			}
			return type.toString();
		}
		
		public function toStringTree(treeTop:ScriptNode):String {
			throw new Error("Node$toStringTree(ScriptNode) not yet implemented.");
		}
		
		private static function toStringTreeHelper(treeTop:ScriptNode, n:Node, printIds:Object, level:int):String {
			if (Token.printTrees) {
				throw new Error("Node#toStringTreeHelper() not yet implemented.");
			}
			return "";
		}
		
		private static function getneratePrintIds(n:Node, map:Object):void {
			if (Token.printTrees) {
				throw new Error("Node#generatePrintIds() not yet implemented."); 
			}
		}
		
		private static function appendPrintId(n:Node, printIds:Object):String {
			if (Token.printTrees) {
				throw new Error("Node#appendPrintId() not yet implemented.");
			}
			return "";
		}
	}
}

class PropListItem {
	public var next:PropListItem;
	public var type:int;
	public var intValue:int;
	public var objectValue:Object;
}