<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    int loggedUserId = (Integer) session.getAttribute("userId");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Favorites - AIRG</title>
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
    <h1>Favorites</h1>
    <a href="index.jsp" class="back-link">← Dashboard</a>
    <% if (isAdmin) { %>
        <a href="addFavorite.jsp" style="margin-left:20px;">Add Favorite</a>
    <% } %>

    <%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        String sql;
        if (isAdmin) {
            sql = "SELECT f.user_id, u.name as user_name, f.recipe_id, r.title as recipe_title " +
                  "FROM airg_favorites f " +
                  "JOIN airg_users u ON f.user_id = u.id " +
                  "JOIN airg_recipes r ON f.recipe_id = r.id " +
                  "ORDER BY u.name";
            pstmt = conn.prepareStatement(sql);
        } else {
            sql = "SELECT f.user_id, u.name as user_name, f.recipe_id, r.title as recipe_title " +
                  "FROM airg_favorites f " +
                  "JOIN airg_users u ON f.user_id = u.id " +
                  "JOIN airg_recipes r ON f.recipe_id = r.id " +
                  "WHERE f.user_id = ? " +
                  "ORDER BY u.name";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, loggedUserId);
        }
        rs = pstmt.executeQuery();
    %>
    <table>
        <tr><th>User</th><th>Recipe</th><th>Actions</th></tr>
        <% while (rs.next()) { %>
        <tr>
            <td><%= rs.getString("user_name") %> (ID <%= rs.getInt("user_id") %>)</td>
            <td><%= rs.getString("recipe_title") %> (ID <%= rs.getInt("recipe_id") %>)</td>
            <td>
                <% if (isAdmin) { %>
                    <a href="updateFavorite.jsp?user_id=<%= rs.getInt("user_id") %>&recipe_id=<%= rs.getInt("recipe_id") %>" class="action-link">✏️ Edit</a>
                    <a href="deleteFavorite.jsp?user_id=<%= rs.getInt("user_id") %>&recipe_id=<%= rs.getInt("recipe_id") %>" class="action-link" onclick="return confirm('Remove this favorite?')">🗑️ Delete</a>
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
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
        if (conn != null) DatabaseConnection.closeConnection(conn);
    }
    %>
</body>
</html>