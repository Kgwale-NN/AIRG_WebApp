<%@ page import="java.sql.*" %>
<%@ page import="airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Update Recipe - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        h1 { color: #ff6b35; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; }
        input, textarea, select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; color: #155724; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        select { width: 100%; padding: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>✏️ Update Recipe</h1>
    <a href="index.html" class="back-link">← Back to Home</a>
    
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        String recipeId = request.getParameter("recipe_id");
        
        // Process update after form submission
        if(request.getMethod().equalsIgnoreCase("POST") && recipeId != null && !recipeId.isEmpty()) {
            String title = request.getParameter("title");
            String description = request.getParameter("description");
            String instructions = request.getParameter("instructions");
            String cuisine_type = request.getParameter("cuisine_type");
            int prep_time = Integer.parseInt(request.getParameter("prep_time"));
            int servings = Integer.parseInt(request.getParameter("servings"));
            
            Connection conn = null;
            PreparedStatement pstmt = null;
            try {
                conn = DatabaseConnection.getConnection();
                String sql = "UPDATE airg_recipes SET title=?, description=?, instructions=?, cuisine_type=?, prep_time=?, servings=? WHERE id=?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, title);
                pstmt.setString(2, description);
                pstmt.setString(3, instructions);
                pstmt.setString(4, cuisine_type);
                pstmt.setInt(5, prep_time);
                pstmt.setInt(6, servings);
                pstmt.setInt(7, Integer.parseInt(recipeId));
                
                int result = pstmt.executeUpdate();
                if(result > 0) {
                    message = "✅ Recipe updated successfully!";
                    messageType = "success";
                } else {
                    message = "❌ Failed to update recipe.";
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
        
        // Show success/error message
        if(!message.isEmpty()) {
        %>
            <div class="<%= messageType %>"><%= message %></div>
        <%
        }
        
        // If no recipe selected OR update was successful, show dropdown
        if(recipeId == null || (request.getMethod().equalsIgnoreCase("POST") && messageType.equals("success"))) {
        %>
        <form method="get">
            <label>Select Recipe to Update:</label>
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
            <input type="submit" value="Load Recipe">
        </form>
        <%
        } else if(recipeId != null && !recipeId.isEmpty()) {
            // Show update form with current data
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DatabaseConnection.getConnection();
                String sql = "SELECT * FROM airg_recipes WHERE id=?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, Integer.parseInt(recipeId));
                rs = pstmt.executeQuery();
                if(rs.next()) {
        %>
        <form method="post">
            <input type="hidden" name="recipe_id" value="<%= recipeId %>">
            
            <label>Title:</label>
            <input type="text" name="title" value="<%= rs.getString("title") %>" required>
            
            <label>Description:</label>
            <textarea name="description" rows="2"><%= rs.getString("description") != null ? rs.getString("description") : "" %></textarea>
            
            <label>Instructions:</label>
            <textarea name="instructions" rows="4" required><%= rs.getString("instructions") %></textarea>
            
            <label>Cuisine Type:</label>
            <input type="text" name="cuisine_type" value="<%= rs.getString("cuisine_type") != null ? rs.getString("cuisine_type") : "" %>">
            
            <label>Prep Time (minutes):</label>
            <input type="number" name="prep_time" value="<%= rs.getInt("prep_time") %>" required>
            
            <label>Servings:</label>
            <input type="number" name="servings" value="<%= rs.getInt("servings") %>" required>
            
            <input type="submit" value="Update Recipe">
        </form>
        <%
                } else {
                    out.println("<p class='error'>Recipe not found!</p>");
                }
            } catch(Exception e) {
                out.println("<p class='error'>Error: " + e.getMessage() + "</p>");
            } finally {
                if(rs != null) try { rs.close(); } catch(Exception e) {}
                if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
        %>
        
        
    </div>
</body>
</html>