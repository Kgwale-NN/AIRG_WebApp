<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    int loggedUserId = (Integer) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    
    String recipeIdParam = request.getParameter("recipe_id");
    if (recipeIdParam == null || recipeIdParam.trim().isEmpty()) {
        response.sendRedirect("listRecipes.jsp");
        return;
    }
    int recipeId = Integer.parseInt(recipeIdParam);
    
    // Ownership check
    Connection checkConn = null;
    PreparedStatement checkStmt = null;
    ResultSet checkRs = null;
    try {
        checkConn = DatabaseConnection.getConnection();
        checkStmt = checkConn.prepareStatement("SELECT created_by FROM airg_recipes WHERE id = ?");
        checkStmt.setInt(1, recipeId);
        checkRs = checkStmt.executeQuery();
        if (checkRs.next()) {
            int ownerId = checkRs.getInt("created_by");
            if (!isAdmin && ownerId != loggedUserId) {
                response.sendRedirect("listRecipes.jsp");
                return;
            }
        } else {
            response.sendRedirect("listRecipes.jsp");
            return;
        }
    } catch (Exception e) {
        response.sendRedirect("listRecipes.jsp");
        return;
    } finally {
        if (checkRs != null) try { checkRs.close(); } catch(Exception e) {}
        if (checkStmt != null) try { checkStmt.close(); } catch(Exception e) {}
        if (checkConn != null) DatabaseConnection.closeConnection(checkConn);
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Delete Recipe - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; }
        .warning { background: #fff3cd; color: #856404; padding: 10px; margin-bottom: 20px; border-radius: 5px; border: 1px solid #ffeeba; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        .btn-cancel { background: #6c757d; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-left: 10px; }
        .btn-cancel:hover { background: #5a6268; }
        input[type=submit] { background: #28a745; color: white; border: none; padding: 10px 20px; cursor: pointer; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🗑️ Delete Recipe</h1>
    <a href="index.jsp" class="back-link">← Back to Home</a>
    
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        String confirm = request.getParameter("confirm");
        
        // Process deletion if confirmed
        if (confirm != null && confirm.equals("yes")) {
            Connection conn = null;
            CallableStatement cstmt = null;
            String recipeTitle = "";
            
            // Get recipe title for success message (no try-with-resources)
            Connection con = null;
            PreparedStatement pst = null;
            ResultSet rs = null;
            try {
                con = DatabaseConnection.getConnection();
                pst = con.prepareStatement("SELECT title FROM airg_recipes WHERE id = ?");
                pst.setInt(1, recipeId);
                rs = pst.executeQuery();
                if (rs.next()) recipeTitle = rs.getString("title");
            } catch (Exception e) {
                recipeTitle = "the recipe";
            } finally {
                if (rs != null) try { rs.close(); } catch(Exception e) {}
                if (pst != null) try { pst.close(); } catch(Exception e) {}
                if (con != null) DatabaseConnection.closeConnection(con);
            }
            
            // Perform deletion using stored procedure
            try {
                conn = DatabaseConnection.getConnection();
                String sql = "{CALL sp_DeleteRecipeWithLog(?, ?)}";
                cstmt = conn.prepareCall(sql);
                cstmt.setInt(1, recipeId);
                cstmt.setInt(2, loggedUserId);
                cstmt.execute();
                message = "✅ Recipe '" + recipeTitle + "' deleted successfully!";
                messageType = "success";
                // Redirect after 2 seconds
                response.setHeader("Refresh", "2; URL=listRecipes.jsp");
            } catch (Exception e) {
                message = "❌ Error: " + e.getMessage();
                messageType = "error";
            } finally {
                if (cstmt != null) try { cstmt.close(); } catch(Exception e) {}
                if (conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
        
        // Show message if any
        if (!message.isEmpty()) {
        %>
            <div class="<%= messageType %>"><%= message %></div>
        <%
        }
        
        // Show confirmation if not yet confirmed
        if (confirm == null && message.isEmpty()) {
            String recipeTitle = "";
            Connection con = null;
            PreparedStatement pst = null;
            ResultSet rs = null;
            try {
                con = DatabaseConnection.getConnection();
                pst = con.prepareStatement("SELECT title FROM airg_recipes WHERE id = ?");
                pst.setInt(1, recipeId);
                rs = pst.executeQuery();
                if (rs.next()) recipeTitle = rs.getString("title");
            } catch (Exception e) {
                recipeTitle = "this recipe";
            } finally {
                if (rs != null) try { rs.close(); } catch(Exception e) {}
                if (pst != null) try { pst.close(); } catch(Exception e) {}
                if (con != null) DatabaseConnection.closeConnection(con);
            }
        %>
        <div class="warning">
            <strong>⚠️ WARNING:</strong> Are you sure you want to delete "<strong><%= recipeTitle %></strong>"?<br>
            This action <strong>CANNOT</strong> be undone!
            <form method="post" style="margin-top: 15px;">
                <input type="hidden" name="recipe_id" value="<%= recipeIdParam %>">
                <input type="hidden" name="confirm" value="yes">
                <input type="submit" value="✅ Yes, Delete Permanently">
                <a href="listRecipes.jsp" class="btn-cancel">❌ Cancel</a>
            </form>
        </div>
        <%
        }
        %>
    </div>
</body>
</html>