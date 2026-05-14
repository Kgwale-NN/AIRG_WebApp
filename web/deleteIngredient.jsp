<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>

<!DOCTYPE html>
<html>
<head>
    <title>Delete Ingredient - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        h1 { color: #ff6b35; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; }
        .warning { background: #fff3cd; color: #856404; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; }
        .btn-cancel { background: #6c757d; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-left: 10px; }
        input[type=submit] { background: #28a745; color: white; border: none; padding: 10px 20px; cursor: pointer; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🗑️ Delete Ingredient</h1>
    <a href="listIngredients.jsp" class="back-link">← Back to Ingredients</a>

    <div class="form-container">
        <%
        String id = request.getParameter("id");
        String confirm = request.getParameter("confirm");
        String message = "";
        String messageType = "";

        if(id == null || id.trim().isEmpty()) {
            response.sendRedirect("listIngredients.jsp");
            return;
        }

        // If confirmed, delete
        if(confirm != null && confirm.equals("yes")) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            try {
                conn = DatabaseConnection.getConnection();
                pstmt = conn.prepareStatement("DELETE FROM airg_ingredients WHERE id=?");
                pstmt.setInt(1, Integer.parseInt(id));
                int result = pstmt.executeUpdate();
                if(result > 0) {
                    message = "✅ Ingredient deleted successfully!";
                    messageType = "success";
                    // Redirect after 2 seconds
                    response.setHeader("Refresh", "2; URL=listIngredients.jsp");
                } else {
                    message = "❌ Ingredient not found.";
                    messageType = "error";
                }
            } catch(Exception e) {
                message = "❌ Error: " + e.getMessage();
                messageType = "error";
            } finally {
                if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        }

        if(!message.isEmpty()) {
        %>
            <div class="<%= messageType %>"><%= message %></div>
        <%
        }

        // Show confirmation if not yet confirmed
        if(confirm == null && message.isEmpty()) {
            // Get ingredient name for display
            String ingredientName = "";
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DatabaseConnection.getConnection();
                pstmt = conn.prepareStatement("SELECT name FROM airg_ingredients WHERE id=?");
                pstmt.setInt(1, Integer.parseInt(id));
                rs = pstmt.executeQuery();
                if(rs.next()) ingredientName = rs.getString("name");
            } catch(Exception e) { ingredientName = "this ingredient";
            } finally {
                if(rs != null) try { rs.close(); } catch(Exception e) {}
                if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        %>
            <div class="warning">
                <strong>⚠️ WARNING:</strong> Are you sure you want to delete "<strong><%= ingredientName %></strong>"?<br>
                This action <strong>CANNOT</strong> be undone!
                <form method="post" style="margin-top: 15px;">
                    <input type="hidden" name="id" value="<%= id %>">
                    <input type="hidden" name="confirm" value="yes">
                    <input type="submit" value="✅ Yes, Delete Permanently">
                    <a href="listIngredients.jsp" class="btn-cancel">❌ Cancel</a>
                </form>
            </div>
        <%
        }
        %>
    </div>
</body>
</html>