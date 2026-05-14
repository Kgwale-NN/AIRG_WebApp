<%@ page import="java.sql.*" %>
<%@ page import="airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>

<!DOCTYPE html>
<html>
<head>
    <title>Add Recipe - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        h1 { color: #ff6b35; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; }
        input, textarea, select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; color: #155724; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; margin-bottom: 20px; border-radius: 5px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>➕ Add New Recipe</h1>
    <a href="index.jsp" class="back-link">← Back to Home</a>
    
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        
        if(request.getMethod().equalsIgnoreCase("POST")) {
            String title = request.getParameter("title");
            String description = request.getParameter("description");
            String instructions = request.getParameter("instructions");
            String cuisine_type = request.getParameter("cuisine_type");
            int prep_time = Integer.parseInt(request.getParameter("prep_time"));
            int servings = Integer.parseInt(request.getParameter("servings"));
            int created_by = Integer.parseInt(request.getParameter("created_by"));
            
            Connection conn = null;
            CallableStatement cstmt = null;
            try {
                conn = DatabaseConnection.getConnection();
                // Call the stored procedure instead of direct INSERT
                String sql = "{CALL sp_InsertRecipeWithLog(?, ?, ?, ?, ?, ?, ?)}";
                cstmt = conn.prepareCall(sql);
                cstmt.setString(1, title);
                cstmt.setString(2, description);
                cstmt.setString(3, instructions);
                cstmt.setString(4, cuisine_type);
                cstmt.setInt(5, prep_time);
                cstmt.setInt(6, servings);
                cstmt.setInt(7, created_by);
                
                cstmt.execute();
                // If we reach here, no exception – assume success
                message = "✅ Recipe '" + title + "' added successfully!";
                messageType = "success";
            } catch(Exception e) {
                message = "❌ Error: " + e.getMessage();
                messageType = "error";
            } finally {
                if(cstmt != null) try { cstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
        %>
        
        <% if(!message.isEmpty()) { %>
            <div class="<%= messageType %>"><%= message %></div>
        <% } %>
        
        <form method="post">
            <label>Title:</label>
            <input type="text" name="title" required>
            
            <label>Description:</label>
            <textarea name="description" rows="2"></textarea>
            
            <label>Instructions:</label>
            <textarea name="instructions" rows="4" required></textarea>
            
            <label>Cuisine Type:</label>
            <input type="text" name="cuisine_type">
            
            <label>Prep Time (minutes):</label>
            <input type="number" name="prep_time" required>
            
            <label>Servings:</label>
            <input type="number" name="servings" required>
            
            <label>Created By:</label>
            <select name="created_by" required>
                <%
                Connection conn2 = null;
                Statement stmt2 = null;
                ResultSet rs2 = null;
                try {
                    conn2 = DatabaseConnection.getConnection();
                    stmt2 = conn2.createStatement();
                    rs2 = stmt2.executeQuery("SELECT id, name FROM airg_users");
                    while(rs2.next()) {
                        out.println("<option value='" + rs2.getInt("id") + "'>" + rs2.getString("name") + "</option>");
                    }
                } catch(Exception e) {
                    out.println("<option value='1'>Alice Home</option>");
                } finally {
                    if(rs2 != null) try { rs2.close(); } catch(Exception e) {}
                    if(stmt2 != null) try { stmt2.close(); } catch(Exception e) {}
                    if(conn2 != null) DatabaseConnection.closeConnection(conn2);
                }
                %>
            </select>
            
            <input type="submit" value="Add Recipe">
        </form>
    </div>
</body>
</html>