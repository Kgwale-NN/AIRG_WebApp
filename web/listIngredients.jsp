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
    <title>Manage Ingredients - AIRG</title>
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
    <h1>🥕 Manage Ingredients</h1>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
    <% if (isAdmin) { %>
        <a href="insertIngredient.jsp" style="margin-left:20px;">➕ Add New Ingredient</a>
    <% } %>

    <%
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        stmt = conn.createStatement();
        rs = stmt.executeQuery("SELECT id, name, unit FROM airg_ingredients ORDER BY name");
    %>
    <table>
        <tr><th>ID</th><th>Ingredient Name</th><th>Unit</th><th>Actions</th></tr>
        <% while(rs.next()) { %>
        <tr>
            <td><%= rs.getInt("id") %></td>
            <td><%= rs.getString("name") %></td>
            <td><%= rs.getString("unit") != null ? rs.getString("unit") : "-" %></td>
            <td>
                <% if (isAdmin) { %>
                    <a href="updateIngredient.jsp?id=<%= rs.getInt("id") %>" class="action-link">✏️ Edit</a>
                    <a href="deleteIngredient.jsp?id=<%= rs.getInt("id") %>" class="action-link" onclick="return confirm('Delete this ingredient?')">🗑️ Delete</a>
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