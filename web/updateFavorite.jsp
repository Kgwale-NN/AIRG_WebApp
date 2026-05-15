<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Edit Favorite - AIRG</title>
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
    <h1>✏️ Edit Favorite</h1>
    <a href="listFavorites.jsp" class="back-link">← Back to Favorites</a>
    <div class="form-container">
        <%
        String oldUserId = request.getParameter("user_id");
        String oldRecipeId = request.getParameter("recipe_id");
        String message = "";
        String messageType = "";
        // ✅ FIXED: diamond operator replaced with explicit type
        List<String> errors = new ArrayList<String>();
        
        // Preserve selected new values for repopulation on error
        String selectedNewUserId = "";
        String selectedNewRecipeId = "";
        
        if (oldUserId == null || oldRecipeId == null || oldUserId.trim().isEmpty() || oldRecipeId.trim().isEmpty()) {
            response.sendRedirect("listFavorites.jsp");
            return;
        }
        
        int oldUid = 0, oldRid = 0;
        try {
            oldUid = Integer.parseInt(oldUserId);
            oldRid = Integer.parseInt(oldRecipeId);
        } catch (NumberFormatException e) {
            out.println("<div class='error'>Invalid favorite identifier.</div>");
            return;
        }
        
        // Process update
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String newUserIdStr = request.getParameter("new_user_id");
            String newRecipeIdStr = request.getParameter("new_recipe_id");
            
            selectedNewUserId = (newUserIdStr != null) ? newUserIdStr : "";
            selectedNewRecipeId = (newRecipeIdStr != null) ? newRecipeIdStr : "";
            
            // --- 1. Empty field checks ---
            if (newUserIdStr == null || newUserIdStr.trim().isEmpty()) {
                errors.add("Please select a user.");
            }
            if (newRecipeIdStr == null || newRecipeIdStr.trim().isEmpty()) {
                errors.add("Please select a recipe.");
            }
            
            int newUserId = 0, newRecipeId = 0;
            
            // --- 2. Numeric validation ---
            if (newUserIdStr != null && !newUserIdStr.trim().isEmpty()) {
                try {
                    newUserId = Integer.parseInt(newUserIdStr);
                } catch (NumberFormatException e) {
                    errors.add("Invalid user selection.");
                }
            }
            if (newRecipeIdStr != null && !newRecipeIdStr.trim().isEmpty()) {
                try {
                    newRecipeId = Integer.parseInt(newRecipeIdStr);
                } catch (NumberFormatException e) {
                    errors.add("Invalid recipe selection.");
                }
            }
            
            // --- 3. Duplicate check (excluding the current pair) ---
            if (errors.isEmpty()) {
                // If the new pair is the same as the old one, no need to update (and it's not a duplicate problem)
                if (newUserId == oldUid && newRecipeId == oldRid) {
                    errors.add("No changes detected. The favorite is already set to this user and recipe.");
                } else {
                    Connection connCheck = null;
                    PreparedStatement pstmtCheck = null;
                    ResultSet rsCheck = null;
                    try {
                        connCheck = DatabaseConnection.getConnection();
                        pstmtCheck = connCheck.prepareStatement(
                            "SELECT id FROM airg_favorites WHERE user_id = ? AND recipe_id = ?"
                        );
                        pstmtCheck.setInt(1, newUserId);
                        pstmtCheck.setInt(2, newRecipeId);
                        rsCheck = pstmtCheck.executeQuery();
                        if (rsCheck.next()) {
                            errors.add("This user already has that recipe in favorites. Duplicate not allowed.");
                        }
                    } catch (Exception e) {
                        // ignore, fallback to database exception
                    } finally {
                        if (rsCheck != null) try { rsCheck.close(); } catch(Exception e) {}
                        if (pstmtCheck != null) try { pstmtCheck.close(); } catch(Exception e) {}
                        if (connCheck != null) DatabaseConnection.closeConnection(connCheck);
                    }
                }
            }
            
            // --- If no errors, perform update (delete old + insert new) ---
            if (errors.isEmpty()) {
                Connection conn = null;
                PreparedStatement pstmt = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    // Start transaction
                    conn.setAutoCommit(false);
                    
                    // Delete old favorite
                    pstmt = conn.prepareStatement("DELETE FROM airg_favorites WHERE user_id=? AND recipe_id=?");
                    pstmt.setInt(1, oldUid);
                    pstmt.setInt(2, oldRid);
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    // Insert new favorite
                    pstmt = conn.prepareStatement("INSERT INTO airg_favorites (user_id, recipe_id) VALUES (?, ?)");
                    pstmt.setInt(1, newUserId);
                    pstmt.setInt(2, newRecipeId);
                    int res = pstmt.executeUpdate();
                    
                    if (res > 0) {
                        conn.commit();
                        message = "✅ Favorite updated successfully!";
                        messageType = "success";
                        // Redirect after 2 seconds
                        response.setHeader("Refresh", "2; URL=listFavorites.jsp");
                    } else {
                        conn.rollback();
                        message = "❌ Failed to update favorite.";
                        messageType = "error";
                    }
                } catch (Exception e) {
                    try { if (conn != null) conn.rollback(); } catch (Exception ex) {}
                    if (e.getMessage().contains("Duplicate entry")) {
                        message = "⚠️ This user already has that recipe in favorites. No duplicate allowed.";
                    } else {
                        message = "❌ Database error: " + e.getMessage();
                    }
                    messageType = "error";
                } finally {
                    if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
                    if (conn != null) {
                        try { conn.setAutoCommit(true); } catch (Exception e) {}
                        DatabaseConnection.closeConnection(conn);
                    }
                }
            } else {
                messageType = "error";
            }
        }
        
        // Load current user and recipe names for display (only for initial GET or after error)
        String currentUserName = "";
        String currentRecipeTitle = "";
        if (!request.getMethod().equalsIgnoreCase("POST") || !errors.isEmpty()) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DatabaseConnection.getConnection();
                pstmt = conn.prepareStatement("SELECT name FROM airg_users WHERE id=?");
                pstmt.setInt(1, oldUid);
                rs = pstmt.executeQuery();
                if (rs.next()) currentUserName = rs.getString("name");
                rs.close(); pstmt.close();
                
                pstmt = conn.prepareStatement("SELECT title FROM airg_recipes WHERE id=?");
                pstmt.setInt(1, oldRid);
                rs = pstmt.executeQuery();
                if (rs.next()) currentRecipeTitle = rs.getString("title");
            } catch (Exception e) {
                out.println("<div class='error'>Error loading data: " + e.getMessage() + "</div>");
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception e) {}
                if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
                if (conn != null) DatabaseConnection.closeConnection(conn);
            }
        %>
        
        <% if (!message.isEmpty()) { %>
            <div class="<%= messageType %>"><%= message %></div>
        <% } %>
        
        <% if (!errors.isEmpty()) { %>
            <div class="error">
                <strong>Please correct the following errors:</strong>
                <ul class="error-list">
                    <% for (String err : errors) { %>
                        <li><%= err %></li>
                    <% } %>
                </ul>
            </div>
        <% } %>
        
        <form method="post">
            <input type="hidden" name="old_user_id" value="<%= oldUserId %>">
            <input type="hidden" name="old_recipe_id" value="<%= oldRecipeId %>">
            
            <label>Current User:</label>
            <input type="text" value="<%= currentUserName %>" disabled style="background:#eee;">
            
            <label>Current Recipe:</label>
            <input type="text" value="<%= currentRecipeTitle %>" disabled style="background:#eee;">
            
            <label>New User:</label>
            <select name="new_user_id" required>
                <option value="">-- Select User --</option>
                <%
                Connection conn2 = null;
                Statement stmt2 = null;
                ResultSet rs2 = null;
                try {
                    conn2 = DatabaseConnection.getConnection();
                    stmt2 = conn2.createStatement();
                    rs2 = stmt2.executeQuery("SELECT id, name FROM airg_users ORDER BY name");
                    while (rs2.next()) {
                        int uid = rs2.getInt("id");
                        String selected = "";
                        if (!selectedNewUserId.isEmpty() && uid == Integer.parseInt(selectedNewUserId)) {
                            selected = "selected";
                        } else if (selectedNewUserId.isEmpty() && uid == oldUid) {
                            selected = "selected";
                        }
                        out.println("<option value='" + uid + "' " + selected + ">" + rs2.getString("name") + "</option>");
                    }
                } catch (Exception e) { out.println("<option>Error loading users</option>");
                } finally { if (rs2 != null) try { rs2.close(); } catch (Exception e) {}
                            if (stmt2 != null) try { stmt2.close(); } catch (Exception e) {}
                            if (conn2 != null) DatabaseConnection.closeConnection(conn2); }
                %>
            </select>
            
            <label>New Recipe:</label>
            <select name="new_recipe_id" required>
                <option value="">-- Select Recipe --</option>
                <%
                Connection conn3 = null;
                Statement stmt3 = null;
                ResultSet rs3 = null;
                try {
                    conn3 = DatabaseConnection.getConnection();
                    stmt3 = conn3.createStatement();
                    rs3 = stmt3.executeQuery("SELECT id, title FROM airg_recipes ORDER BY title");
                    while (rs3.next()) {
                        int rid = rs3.getInt("id");
                        String selected = "";
                        if (!selectedNewRecipeId.isEmpty() && rid == Integer.parseInt(selectedNewRecipeId)) {
                            selected = "selected";
                        } else if (selectedNewRecipeId.isEmpty() && rid == oldRid) {
                            selected = "selected";
                        }
                        out.println("<option value='" + rid + "' " + selected + ">" + rs3.getString("title") + "</option>");
                    }
                } catch (Exception e) { out.println("<option>Error loading recipes</option>");
                } finally { if (rs3 != null) try { rs3.close(); } catch (Exception e) {}
                            if (stmt3 != null) try { stmt3.close(); } catch (Exception e) {}
                            if (conn3 != null) DatabaseConnection.closeConnection(conn3); }
                %>
            </select>
            
            <input type="submit" value="Update Favorite">
        </form>
        <%
        } else {
            // After successful POST, show message and redirect (handled by header refresh)
            if (!message.isEmpty()) {
                out.println("<div class='" + messageType + "'>" + message + "</div>");
            }
        }
        %>
    </div>
</body>
</html>