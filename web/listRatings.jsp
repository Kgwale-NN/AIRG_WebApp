<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
%>
<!DOCTYPE html>
<html>
<head>
    <title>Ratings - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        h1 { color: #ff6b35; }
        table { border-collapse: collapse; width: 100%; background: white; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .back-link { margin-bottom: 20px; display: inline-block; color: #ff6b35; text-decoration: none; }
        .action-link { margin: 0 5px; color: #ff6b35; text-decoration: none; }
    </style>
</head>
<body>
    <h1>⭐ User Ratings</h1>
    <a href="index.jsp" class="back-link">← Dashboard</a>
    <% if (isAdmin) { %>
        <a href="addRating.jsp" style="margin-left:20px;">➕ Add Rating</a>
    <% } %>

    <%
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        stmt = conn.createStatement();
        String sql = "SELECT r.id, u.name AS user_name, u.id AS user_id, " +
                     "rec.title AS recipe_title, rec.id AS recipe_id, " +
                     "r.rating, r.review, r.rated_date AS rated_date " +
                     "FROM airg_ratings r " +
                     "JOIN airg_users u ON r.user_id = u.id " +
                     "JOIN airg_recipes rec ON r.recipe_id = rec.id " +
                     "ORDER BY r.id DESC";
        rs = stmt.executeQuery(sql);
    %>
    <table>
        <tr>
            <th>ID</th>
            <th>User</th>
            <th>Recipe</th>
            <th>Rating</th>
            <th>Review</th>
            <th>Date</th>
            <th>Actions</th>
        </tr>
        <% while (rs.next()) {
            int ratingId = rs.getInt("id");
            String userName = rs.getString("user_name");
            int userId = rs.getInt("user_id");
            String recipeTitle = rs.getString("recipe_title");
            int recipeId = rs.getInt("recipe_id");
            int rating = rs.getInt("rating");
            String review = rs.getString("review");
            Timestamp ratedDate = rs.getTimestamp("rated_date");
        %>
        <tr>
            <td><%= ratingId %></td>
            <td><%= userName %> (ID <%= userId %>)</td>
            <td><%= recipeTitle %> (ID <%= recipeId %>)</td>
            <td><%= rating %> / 5</td>
            <td><%= review != null ? review : "-" %></td>
            <td><%= ratedDate != null ? ratedDate.toString().substring(0,19) : "-" %></td>
            <td>
                <% if (isAdmin) { %>
                    <a href="updateRating.jsp?id=<%= ratingId %>" class="action-link">✏️ Edit</a>
                    <a href="deleteRating.jsp?id=<%= ratingId %>" class="action-link" onclick="return confirm('Delete this rating?')">🗑️ Delete</a>
                <% } else { %>
                    --
                <% } %>
            </td>
        </tr>
        <% } %>
    </table>
    <%
    } catch (Exception e) {
        out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (stmt != null) try { stmt.close(); } catch (Exception e) {}
        if (conn != null) DatabaseConnection.closeConnection(conn);
    }
    %>
</body>
</html>