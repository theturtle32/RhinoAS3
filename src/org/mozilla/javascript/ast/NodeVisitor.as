package org.mozilla.javascript.ast
{
	/**
	 * Simple visitor interface for traversing the AST.  The nodes are visited in
	 * an arbitrary order.  The visitor must cast nodes to the appropriate
	 * type based on their token-type.
	 */
	public interface NodeVisitor
	{
		/**
		 * Visits an AST node.
		 * @param node the AST node.  Will never visit an {@link AstRoot} node,
		 * since the {@code AstRoot} is where the visiting begins.
		 * @return {@code true} if the children should be visited.
		 * If {@code false}, the subtree rooted at this node is skipped.
		 * The {@code node} argument should <em>never</em> be {@code null} --
		 * the individual {@link AstNode} classes should skip any children
		 * that are not present in the source when they invoke this method.
		 */
		function visit(node:AstNode):Boolean;
	}
}