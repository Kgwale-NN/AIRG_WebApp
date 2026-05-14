<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Add Favorite - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 450px; margin: 0 auto; }
        select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; padding: 10px; width: 100%; }
        .success { background: #d4edda; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        .error-list { margin: 0 0 10px 0; padding-left: 20px; }
    </style>
</head>
<body>
    <h1>➕ Add Favorite</h1>
    <a href="listFavorites.jsp" class="back-link">← Back to Favorites</a>
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        List<String> errors = new ArrayList<String>();  // ✅ FIXED: removed diamond operator
        
        // Preserve selected values
        String selectedUserId = "";
        String selectedRecipeId = "";
        
        if(request.getMethod().equalsIgnoreCase("POST")) {
            String userIdStr = request.getParameter("user_id");
            String recipeIdStr = request.getParameter("recipe_id");
            
            selectedUserId = (userIdStr != null) ? userIdStr : "";
            selectedRecipeId = (recipeIdStr != null) ? recipeIdStr : "";
            
            // --- 1. Empty field checks ---
            if(userIdStr == null || userIdStr.trim().isEmpty()) {
                errors.add("Please select a user.");
            }
            if(recipeIdStr == null || recipeIdStr.trim().isEmpty()) {
                errors.add("Please select a recipe.");
            }
            
            int userId = 0;
            int recipeId = 0;
            
            // --- 2. Numeric validation (though dropdown should give numbers) ---
            if(userIdStr != null && !userIdStr.trim().isEmpty()) {
                try {
                    userId = Integer.parseInt(userIdStr);
                } catch(NumberFormatException e) {
                    errors.add("Invalid user selection.");
                }
            }
            if(recipeIdStr != null && !recipeIdStr.trim().isEmpty()) {
                try {
                    recipeId = Integer.parseInt(recipeIdStr);
                } catch(NumberFormatException e) {
                    errors.add("Invalid recipe selection.");
                }
            }
            
            // --- 3. Duplicate favorite check (before hitting DB) ---
            if(errors.isEmpty()) {
                Connection connCheck = null;
                PreparedStatement pstmtCheck = null;
                ResultSet rsCheck = null;
                try {
                    connCheck = DatabaseConnection.getConnection();
                    pstmtCheck = connCheck.prepareStatement(
                        "SELECT id FROM airg_favorites WHERE user_id = ? AND recipe_id = ?"
                    );
                    pstmtCheck.setInt(1, userId);
                    pstmtCheck.setInt(2, recipeId);
                    rsCheck = pstmtCheck.executeQuery();
                    if(rsCheck.next()) {
                        errors.add("This user has already favorited this recipe.");
                    }
                } catch(Exception e) {
                    // ignore, fallback to DB exception handling
                } finally {
                    if(rsCheck != null) try { rsCheck.close(); } catch(Exception e) {}
                    if(pstmtCheck != null) try { pstmtCheck.close(); } catch(Exception e) {}
                    if(connCheck != null) DatabaseConnection.closeConnection(connCheck);
                }
            }
            
            // --- If no errors, insert favorite ---
            if(errors.isEmpty()) {
                Connection conn = null;
                PreparedStatement pstmt = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    pstmt = conn.prepareStatement("INSERT INTO airg_favorites (user_id, recipe_id) VALUES (?, ?)");
                    pstmt.setInt(1, userId);
                    pstmt.setInt(2, recipeId);
                    int res = pstmt.executeUpdate();
                    if(res > 0) {
                        message = "✅ Favorite added successfully!";
                        messageType = "success";
                        // Clear selections after success
                        selectedUserId = "";
                        selectedRecipeId = "";
                    } else {
                        message = "❌ Failed to add favorite.";
                        messageType = "error";
                    }
                } catch(Exception e) {
                    if(e.getMessage().contains("Duplicate entry")) {
                        message = "❌ This user already favorited this recipe (duplicate).";
                    } else {
                        message = "❌ Database error: " + e.getMessage();
                    }
                    messageType = "error";
                } finally {
                    if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                    if(conn != null) DatabaseConnection.closeConnection(conn);
                }
            } else {
                messageType = "error";
            }
        }
        %>
        
        <% if(!message.isEmpty()) { %>
            <div class="<%= messageType %>"><%= message %></div>
        <% } %>
        
        <% if(!errors.isEmpty()) { %>
            <div class="error">
                <strong>Please correct the following errors:</strong>
                <ul class="error-list">
                    <% for(String err : errors) { %>
                        <li><%= err %></li>
                    <% } %>
                </ul>
            </div>
        <% } %>
        
        <form method="post">
            <label>User:</label>
            <select name="user_id" required>
                <option value="">-- Select User --</option>
                <%
                Connection conn2 = null;
                Statement stmt2 = null;
                ResultSet rs2 = null;
                try {
                    conn2 = DatabaseConnection.getConnection();
                    stmt2 = conn2.createStatement();
                    rs2 = stmt2.executeQuery("SELECT id, name FROM airg_users ORDER BY name");
                    while(rs2.next()) {
                        int uid = rs2.getInt("id");
                        String selected = (selectedUserId != null && selectedUserId.equals(String.valueOf(uid))) ? "selected" : "";
                        out.println("<option value='" + uid + "' " + selected + ">" + rs2.getString("name") + "</option>");
                    }
                } catch(Exception e) {
                    out.println("<option disabled>Error loading users</option>");
                } finally {
                    if(rs2 != null) try { rs2.close(); } catch(Exception e) {}
                    if(stmt2 != null) try { stmt2.close(); } catch(Exception e) {}
                    if(conn2 != null) DatabaseConnection.closeConnection(conn2);
                }
                %>
            </select>
            
            <label>Recipe:</label>
            <select name="recipe_id" required>
                <option value="">-- Select Recipe --</option>
                <%
                Connection conn3 = null;
                Statement stmt3 = null;
                ResultSet rs3 = null;
                try {
                    conn3 = DatabaseConnection.getConnection();
                    stmt3 = conn3.createStatement();
                    rs3 = stmt3.executeQuery("SELECT id, title FROM airg_recipes ORDER BY title");
                    while(rs3.next()) {
                        int rid = rs3.getInt("id");
                        String selected = (selectedRecipeId != null && selectedRecipeId.equals(String.valueOf(rid))) ? "selected" : "";
                        out.println("<option value='" + rid + "' " + selected + ">" + rs3.getString("title") + "</option>");
                    }
                } catch(Exception e) {
                    out.println("<option disabled>Error loading recipes</option>");
                } finally {
                    if(rs3 != null) try { rs3.close(); } catch(Exception e) {}
                    if(stmt3 != null) try { stmt3.close(); } catch(Exception e) {}
                    if(conn3 != null) DatabaseConnection.closeConnection(conn3);
                }
                %>
            </select>
            
            <input type="submit" value="Add Favorite">
        </form>
    </div>
</body>
</html>