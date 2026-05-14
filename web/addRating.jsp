<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Add Rating - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 450px; margin: 0 auto; }
        input, select, textarea { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Add Rating</h1>
    <a href="listRatings.jsp" class="back-link">← Back to Ratings</a>
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        if(request.getMethod().equalsIgnoreCase("POST")) {
            int userId = Integer.parseInt(request.getParameter("user_id"));
            int recipeId = Integer.parseInt(request.getParameter("recipe_id"));
            int rating = Integer.parseInt(request.getParameter("rating"));
            String review = request.getParameter("review");
            Connection conn = null;
            PreparedStatement pstmt = null;
            try {
                conn = DatabaseConnection.getConnection();
                String sql = "INSERT INTO airg_ratings (user_id, recipe_id, rating, review) VALUES (?, ?, ?, ?)";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, userId);
                pstmt.setInt(2, recipeId);
                pstmt.setInt(3, rating);
                pstmt.setString(4, review);
                int res = pstmt.executeUpdate();
                if(res > 0) {
                    message = "✅ Rating added successfully!";
                    messageType = "success";
                } else {
                    message = "❌ Failed to add rating.";
                    messageType = "error";
                }
            } catch(Exception e) {
                if(e.getMessage().contains("Duplicate entry")) {
                    message = "⚠️ This user has already rated this recipe. Use Edit instead.";
                } else {
                    message = "❌ Error: " + e.getMessage();
                }
                messageType = "error";
            } finally {
                if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
        %>
        <% if(!message.isEmpty()) { %>
            <div class="<%= messageType %>"><%= message %></div>
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
                        out.println("<option value='" + rs2.getInt("id") + "'>" + rs2.getString("name") + "</option>");
                    }
                } catch(Exception e) { out.println("<option>Error loading users</option>");
                } finally { if(rs2 != null) try { rs2.close(); } catch(Exception e) {}
                            if(stmt2 != null) try { stmt2.close(); } catch(Exception e) {}
                            if(conn2 != null) DatabaseConnection.closeConnection(conn2); }
                %>
            </select>
            <label>Recipe:</label>
            <select name="recipe_id" required>
                <option value="">-- Select Recipe --</option>
                <%
                conn2 = DatabaseConnection.getConnection();
                stmt2 = conn2.createStatement();
                rs2 = stmt2.executeQuery("SELECT id, title FROM airg_recipes ORDER BY title");
                while(rs2.next()) {
                    out.println("<option value='" + rs2.getInt("id") + "'>" + rs2.getString("title") + "</option>");
                }
                rs2.close(); stmt2.close(); conn2.close();
                %>
            </select>
            <label>Rating (1-5):</label>
            <input type="number" name="rating" min="1" max="5" required>
            <label>Review (optional):</label>
            <textarea name="review" rows="3"></textarea>
            <input type="submit" value="Add Rating">
        </form>
    </div>
</body>
</html>