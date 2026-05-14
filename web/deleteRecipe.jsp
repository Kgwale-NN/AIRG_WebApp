<%@ page import="java.sql.*" %>
<%@ page import="airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Delete Recipe - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        h1 { color: #ff6b35; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; }
        select { width: 100%; padding: 10px; margin: 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #dc3545; color: white; border: none; padding: 10px 20px; cursor: pointer; border-radius: 5px; font-size: 16px; }
        input[type=submit]:hover { background: #c82333; }
        .success { background: #d4edda; color: #155724; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .warning { background: #fff3cd; color: #856404; padding: 10px; margin-bottom: 20px; border-radius: 5px; border: 1px solid #ffeeba; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        .btn-cancel { background: #6c757d; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-left: 10px; }
        .btn-cancel:hover { background: #5a6268; }
    </style>
</head>
<body>
    <h1>🗑️ Delete Recipe</h1>
    <a href="index.html" class="back-link">← Back to Home</a>
    
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        String recipeId = request.getParameter("recipe_id");
        String confirm = request.getParameter("confirm");
        
        // Process deletion if confirmed
        if(recipeId != null && confirm != null && confirm.equals("yes")) {
            Connection conn = null;
            CallableStatement cstmt = null;
            String recipeTitle = "";
            
            // First get the recipe title for the success message (before deletion)
            try {
                conn = DatabaseConnection.getConnection();
                String selectSql = "SELECT title FROM airg_recipes WHERE id=?";
                PreparedStatement pstmt = conn.prepareStatement(selectSql);
                pstmt.setInt(1, Integer.parseInt(recipeId));
                ResultSet rs = pstmt.executeQuery();
                if(rs.next()) {
                    recipeTitle = rs.getString("title");
                }
                rs.close();
                pstmt.close();
            } catch(Exception e) {
                recipeTitle = "the recipe";
            }
            
            // Perform deletion using stored procedure (affects audit_log + airg_recipes)
            try {
                conn = DatabaseConnection.getConnection();
                // Use a fixed user ID for now (1 = Alice Home). In a real app, you'd get from session.
                int userId = 1;
                String sql = "{CALL sp_DeleteRecipeWithLog(?, ?)}";
                cstmt = conn.prepareCall(sql);
                cstmt.setInt(1, Integer.parseInt(recipeId));
                cstmt.setInt(2, userId);
                cstmt.execute();
                
                message = "✅ Recipe '" + recipeTitle + "' deleted successfully!";
                messageType = "success";
                recipeId = null; // Clear selection after deletion
                confirm = null;
            } catch(Exception e) {
                message = "❌ Error: " + e.getMessage();
                messageType = "error";
            } finally {
                if(cstmt != null) try { cstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
        
        // Show success/error message
        if(!message.isEmpty()) {
        %>
            <div class="<%= messageType %>"><%= message %></div>
        <%
        }
        
        // Show confirmation if recipe selected but not confirmed
        if(recipeId != null && confirm == null && !recipeId.isEmpty()) {
            // Get recipe title to show in warning
            String recipeTitle = "";
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DatabaseConnection.getConnection();
                String sql = "SELECT title FROM airg_recipes WHERE id=?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, Integer.parseInt(recipeId));
                rs = pstmt.executeQuery();
                if(rs.next()) {
                    recipeTitle = rs.getString("title");
                }
            } catch(Exception e) {
                recipeTitle = "this recipe";
            } finally {
                if(rs != null) try { rs.close(); } catch(Exception e) {}
                if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        %>
        <div class="warning">
            <strong>⚠️ WARNING:</strong> Are you sure you want to delete "<strong><%= recipeTitle %></strong>"?<br>
            This action <strong>CANNOT</strong> be undone!
            <form method="post" style="margin-top: 15px;">
                <input type="hidden" name="recipe_id" value="<%= recipeId %>">
                <input type="hidden" name="confirm" value="yes">
                <input type="submit" value="✅ Yes, Delete Permanently" style="background:#28a745;">
                <a href="deleteRecipe.jsp" class="btn-cancel">❌ Cancel</a>
            </form>
        </div>
        <%
        }
        
        // Show dropdown to select recipe (if no recipe selected OR after successful deletion)
        if(recipeId == null || (messageType.equals("success") && confirm != null)) {
        %>
        <form method="get">
            <label>Select Recipe to Delete:</label>
            <select name="recipe_id" required>
                <option value="">-- Select Recipe --</option>
                <%
                Connection conn = null;
                Statement stmt = null;
                ResultSet rs = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    stmt = conn.createStatement();
                    rs = stmt.executeQuery("SELECT id, title FROM airg_recipes ORDER BY id");
                    while(rs.next()) {
                        out.println("<option value='" + rs.getInt("id") + "'>" + rs.getString("title") + " (ID: " + rs.getInt("id") + ")</option>");
                    }
                } catch(Exception e) {
                    out.println("<option disabled>Error loading recipes</option>");
                } finally {
                    if(rs != null) try { rs.close(); } catch(Exception e) {}
                    if(stmt != null) try { stmt.close(); } catch(Exception e) {}
                    if(conn != null) DatabaseConnection.closeConnection(conn);
                }
                %>
            </select>
            <input type="submit" value="Delete Recipe">
        </form>
        <%
        }
        %>
    </div>
</body>
</html>