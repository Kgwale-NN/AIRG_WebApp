<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // If user is already logged in, redirect to dashboard
    if (session.getAttribute("userId") != null) {
        response.sendRedirect("index.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Login - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; max-width: 400px; margin: 0 auto; }
        input { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .error { color: red; margin-bottom: 15px; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; text-decoration: none; }
    </style>
</head>
<body>
<div class="container">
    <h1>🔐 Login to AIRG</h1>
    <%
        String message = "";
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DatabaseConnection.getConnection();
                pstmt = conn.prepareStatement("SELECT id, name, role FROM airg_users WHERE email=? AND password=?");
                pstmt.setString(1, email);
                pstmt.setString(2, password);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    // Login successful – store user info in session
                    session.setAttribute("userId", rs.getInt("id"));
                    session.setAttribute("userName", rs.getString("name"));
                    session.setAttribute("userRole", rs.getString("role"));
                    // Redirect to dashboard
                    response.sendRedirect("index.jsp");
                    return;
                } else {
                    message = "Invalid email or password. Please try again.";
                }
            } catch (Exception e) {
                message = "Database error: " + e.getMessage();
            } finally {
                if (rs != null) try { rs.close(); } catch(Exception e) {}
                if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if (conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
    %>
    <% if (!message.isEmpty()) { %>
        <div class="error"><%= message %></div>
    <% } %>
    <form method="post">
        <label>Email:</label>
        <input type="email" name="email" required>
        <label>Password:</label>
        <input type="password" name="password" required>
        <input type="submit" value="Login">
    </form>
    <a href="register.jsp" class="back-link">Don't have an account? Register here</a><br>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>