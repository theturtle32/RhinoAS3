package org.mozilla.javascript.ast
{
	import org.as3commons.collections.Map;
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.NodeIterator;
	import org.mozilla.javascript.Token;

	/**
	 * A JavaScript function declaration or expression.<p>
	 * Node type is {@link Token#FUNCTION}.<p>
	 *
	 * <pre><i>FunctionDeclaration</i> :
	 *        <b>function</b> Identifier ( FormalParameterListopt ) { FunctionBody }
	 * <i>FunctionExpression</i> :
	 *        <b>function</b> Identifieropt ( FormalParameterListopt ) { FunctionBody }
	 * <i>FormalParameterList</i> :
	 *        Identifier
	 *        FormalParameterList , Identifier
	 * <i>FunctionBody</i> :
	 *        SourceElements
	 * <i>Program</i> :
	 *        SourceElements
	 * <i>SourceElements</i> :
	 *        SourceElement
	 *        SourceElements SourceElement
	 * <i>SourceElement</i> :
	 *        Statement
	 *        FunctionDeclaration</pre>
	 *
	 * JavaScript 1.8 introduces "function closures" of the form
	 *  <pre>function ([params] ) Expression</pre>
	 *
	 * In this case the FunctionNode node will have no body but will have an
	 * expression.
	 */
	public class FunctionNode extends ScriptNode
	{
		/**
		 * There are three types of functions that can be defined. The first
		 * is a function statement. This is a function appearing as a top-level
		 * statement (i.e., not nested inside some other statement) in either a
		 * script or a function.<p>
		 *
		 * The second is a function expression, which is a function appearing in
		 * an expression except for the third type, which is...<p>
		 *
		 * The third type is a function expression where the expression is the
		 * top-level expression in an expression statement.<p>
		 *
		 * The three types of functions have different treatment and must be
		 * distinguished.<p>
		 */
		public static const FUNCTION_STATEMENT:int = 1;
		public static const FUNCTION_EXPRESSION:int = 2;
		public static const FUNCTION_EXPRESSION_STATEMENT:int = 3;
		
		public static const FORM_FUNCTION:int = 1;
		public static const FORM_GETTER:int = 2;
		public static const FORM_SETTER:int = 3;
		
		private static const NO_PARAMS:Vector.<AstNode> = new Vector.<AstNode>(0);
		
		private var functionName:Name;
		private var params:Vector.<AstNode>;
		private var body:AstNode;
		private var _isExpressionClosure:Boolean;
		private var functionForm:int = FORM_FUNCTION;
		private var lp:int = -1;
		private var rp:int = -1;
		
		// codegen variables
		private var functionType:int;
		private var needsActivation:Boolean;
		private var _isGenerator:Boolean;
		private var generatorResumePoints:Vector.<Node>;
		private var liveLocals:Map; // Map<Node,int[]>
		private var memberExprNode:AstNode;

		public function FunctionNode(pos:int=-1, name:Name=null)
		{
			super(pos);
			type = Token.FUNCTION;
			setFunctionName(name);
		}
		
		/**
		 * Returns function name
		 * @return function name, {@code null} for anonymous functions
		 */
		public function getFunctionName():Name {
			return functionName;
		}
		
		/**
		 * Sets function name, and sets its parent to this node.
		 * @param name function name, {@code null} for anonymous functions
		 */
		public function setFunctionName(name:Name):void {
			functionName = name;
			if (name !== null) {
				name.setParent(this);
			}
		}
		
		/**
		 * Returns the function name as a string
		 * @return the function name, {@code ""} if anonymous
		 */
		public function getName():String {
			return functionName !== null ? functionName.getIdentifier() : "";
		}
		
		/**
		 * Returns the function parameter list
		 * @return the function parameter list.  Returns an immutable empty
		 *         list if there are no parameters.
		 */
		public function getParams():Vector.<AstNode> {
			return params !== null ? params : NO_PARAMS;
		}
		
		/**
		 * Sets the function parameter list, and sets the parent for
		 * each element of the list.
		 * @param params the function parameter list, or {@code null} if no params
		 */
		public function setParams(params:Vector.<AstNode>):void {
			this.params = params;
		}
		
		/**
		 * Adds a parameter to the function parameter list.
		 * Sets the parent of the param node to this node.
		 * @param param the parameter
		 * @throws IllegalArgumentException if param is {@code null}
		 */
		public function addParam(param:AstNode):void {
			assertNotNull(param);
			if (params === null) {
				params = new Vector.<AstNode>();
			}
			params.push(param);
			param.setParent(this);
		}
		
		/**
		 * Returns true if the specified {@link AstNode} node is a parameter
		 * of this Function node.  This provides a way during AST traversal
		 * to disambiguate the function name node from the parameter nodes.
		 */
		public function isParam(node:AstNode):Boolean {
			return params === null ? false : params.indexOf(node) !== -1;
		}
		
		/**
		 * Returns function body.  Normally a {@link Block}, but can be a plain
		 * {@link AstNode} if it's a function closure.
		 *
		 * @return the body.  Can be {@code null} only if the AST is malformed.
		 */
		public function getBody():AstNode {
			return body;
		}
		
		/**
		 * Sets function body, and sets its parent to this node.
		 * Also sets the encoded source bounds based on the body bounds.
		 * Assumes the function node absolute position has already been set,
		 * and the body node's absolute position and length are set.<p>
		 *
		 * @param body function body.  Its parent is set to this node, and its
		 * position is updated to be relative to this node.
		 *
		 * @throws IllegalArgumentException if body is {@code null}
		 */
		public function setBody(body:AstNode):void {
			assertNotNull(body);
			this.body = body;
			if (body.getProp(Node.EXPRESSION_CLOSURE_PROP) === true) {
				setIsExpressionClosure(true);
			}
			var absEnd:int = body.getPosition() + body.getLength();
			body.setParent(this);
			this.setLength(absEnd - this.position);
			setEncodedSourceBounds(this.position, absEnd);
		}
		
		/**
		 * Returns left paren position, -1 if missing
		 */
		public function getLp():int {
			return lp;
		}
		
		/**
		 * Sets left paren position
		 */
		public function setLp(lp:int):void {
			this.lp = lp;
		}
		
		/**
		 * Returns right paren position, -1 if missing
		 */
		public function getRp():int {
			return rp;
		}

		/**
		 * Sets right paren position
		 */
		public function setRp(rp:int):void {
			this.rp = rp;
		}
		
		/**
		 * Sets both paren positions
		 */
		public function setParens(lp:int, rp:int):void {
			this.lp = lp;
			this.rp = rp;
		}
		
		/**
		 * Returns whether this is a 1.8 function closure
		 */
		public function isExpressionClosure():Boolean {
			return this._isExpressionClosure;
		}
		
		/**
		 * Sets whether this is a 1.8 function closure
		 */
		public function setIsExpressionClosure(isExpressionClosure:Boolean):void {
			this._isExpressionClosure = isExpressionClosure;
		}
		
		/**
		 * Return true if this function requires an Ecma-262 Activation object.
		 * The Activation object is implemented by
		 * {@link org.mozilla.javascript.NativeCall}, and is fairly expensive
		 * to create, so when possible, the interpreter attempts to use a plain
		 * call frame instead.
		 *
		 * @return true if this function needs activation.  It could be needed
		 * if there is a lexical closure, or in a number of other situations.
		 */
		public function requiresActivation():Boolean {
			return needsActivation;
		}
		
		public function setRequiresActivation():void {
			needsActivation = true;
		}
		
		public function isGenerator():Boolean {
			return _isGenerator;
		}
		
		public function setIsGenerator():void {
			_isGenerator = true;
		}

		public function addResumptionPoint(target:Node):void {
			if (generatorResumePoints === null)
				generatorResumePoints = new Vector.<Node>();
			generatorResumePoints.push(target);
		}
		
		public function getResumptionPoints():Vector.<Node> {
			return generatorResumePoints;
		}
		
		public function getLiveLocals():Map {
			return liveLocals;
		}
		
		public function addLiveLocals(node:Node, locals:Vector.<int>):void {
			if (liveLocals === null)
				liveLocals = new Map();
			liveLocals.add(node, locals);
		}
		
		override public function addFunction(fnNode:FunctionNode):int {
			var result:int = super.addFunction(fnNode);
			if (getFunctionCount() > 0) {
				needsActivation = true;
			}
			return result;
		}
		
		/**
		 * Returns the function type (statement, expr, statement expr)
		 */
		public function getFunctionType():int {
			return functionType;
		}
		
		public function setFunctionType(type:int):void {
			functionType = type;
		}
		
		public function isGettorOrSetter():Boolean {
			return functionForm === FORM_GETTER || functionForm === FORM_SETTER;
		}
		
		public function isGetter():Boolean {
			return functionForm === FORM_GETTER;
		}
		
		public function isSetter():Boolean {
			return functionForm === FORM_SETTER;
		}
		
		public function setFunctionIsGetter():void {
			functionForm = FORM_GETTER;
		}
		
		public function setFunctionIsSetter():void {
			functionForm = FORM_SETTER;
		}
		
		/**
		 * Rhino supports a nonstandard Ecma extension that allows you to
		 * say, for instance, function a.b.c(arg1, arg) {...}, and it will
		 * be rewritten at codegen time to:  a.b.c = function(arg1, arg2) {...}
		 * If we detect an expression other than a simple Name in the position
		 * where a function name was expected, we record that expression here.
		 * <p>
		 * This extension is only available by setting the CompilerEnv option
		 * "isAllowMemberExprAsFunctionName" in the Parser.
		 */
		public function setMemberExprNode(node:AstNode):void {
			memberExprNode = node;
			if (node !== null)
				node.setParent(this);
		}
		
		public function getMemberExprNode():AstNode {
			return memberExprNode;
		}
		
		override public function toSource(depth:int=0):String {
			throw new Error("FunctionNode$toString() not yet implemented.");
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				if (functionName !== null) {
					functionName.visit(v);
				}
				for each (var param:AstNode in getParams()) {
					param.visit(v);
				}
				getBody().visit(v);
				if (!isExpressionClosure) {
					if (memberExprNode !== null) {
						memberExprNode.visit(v);
					}
				}
			}
		}
	}
}