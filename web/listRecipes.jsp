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
    <title>All Recipes - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        h1 { color: #ff6b35; }
        table { border-collapse: collapse; width: 100%; background: white; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #ff6b35; color: white; }
        tr:nth-child(even) { background: #f2f2f2; }
        .back-link { margin-bottom: 20px; display: inline-block; color: #ff6b35; text-decoration: none; }
        .action-link { margin: 0 5px; color: #ff6b35; text-decoration: none; }
    </style>
</head>
<body>
    <h1>All Recipes</h1>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
    <% if (isAdmin) { %>
        <a href="insertRecipe.jsp" style="margin-left:20px;">➕ Add New Recipe</a>
    <% } %>

    <%
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        stmt = conn.createStatement();
        String sql = "SELECT r.id, r.title, r.cuisine_type, r.prep_time, r.servings, u.name as chef " +
                     "FROM airg_recipes r " +
                     "LEFT JOIN airg_users u ON r.created_by = u.id " +
                     "ORDER BY r.id";
        rs = stmt.executeQuery(sql);
    %>
    <table>
        <tr>
            <th>ID</th><th>Title</th><th>Cuisine</th><th>Prep Time</th><th>Servings</th><th>Created By</th><th>Actions</th>
        </tr>
        <% while(rs.next()) { %>
        <tr>
            <td><%= rs.getInt("id") %></td>
            <td><%= rs.getString("title") %></td>
            <td><%= rs.getString("cuisine_type") != null ? rs.getString("cuisine_type") : "-" %></td>
            <td><%= rs.getInt("prep_time") %></td>
            <td><%= rs.getInt("servings") %></td>
            <td><%= rs.getString("chef") != null ? rs.getString("chef") : "Unknown" %></td>
            <td>
                <% if (isAdmin) { %>
                    <a href="updateRecipe.jsp?id=<%= rs.getInt("id") %>" class="action-link">✏️ Edit</a>
                    <a href="deleteRecipe.jsp?id=<%= rs.getInt("id") %>" class="action-link" onclick="return confirm('Delete this recipe?')">🗑️ Delete</a>
                <% } else { %>
                    --
                <% } %>
            </td>
        </tr>
        <% } %>
    </table>
    <%
    } catch(Exception e) {
        out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
    } finally {
        if(rs != null) try { rs.close(); } catch(Exception e) {}
        if(stmt != null) try { stmt.close(); } catch(Exception e) {}
        if(conn != null) DatabaseConnection.closeConnection(conn);
    }
    %>
</body>
</html>