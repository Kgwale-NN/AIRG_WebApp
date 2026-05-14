<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>   <!-- ✅ changed from loginCheck to adminCheck -->
<!DOCTYPE html>
<html>
<head>
    <title>Manage Users - AIRG</title>
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
    <h1>Manage Users</h1>
    <a href="index.jsp" class="back-link">← Dashboard</a>
    <a href="insertUser.jsp" style="margin-left:20px;">➕ Add New User</a>

    <%
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        stmt = conn.createStatement();
        rs = stmt.executeQuery("SELECT id, name, email, role, created_date FROM airg_users ORDER BY id");
    %>
    <table>
        <tr>
            <th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>Created Date</th><th>Actions</th>
        </tr>
        <% while(rs.next()) { %>
        <tr>
            <td><%= rs.getInt("id") %></td>
            <td><%= rs.getString("name") %></td>
            <td><%= rs.getString("email") %></td>
            <td><%= rs.getString("role") %></td>
            <td><%= rs.getTimestamp("created_date") %></td>
            <td>
                <a href="updateUser.jsp?id=<%= rs.getInt("id") %>" class="action-link">✏️ Edit</a>
                <a href="deleteUser.jsp?id=<%= rs.getInt("id") %>" class="action-link" onclick="return confirm('Delete this user?')">🗑️ Delete</a>
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