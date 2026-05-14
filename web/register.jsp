<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Register - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; max-width: 400px; margin: 0 auto; }
        input, select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; }
        .error { color: red; }
        .success { color: green; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; }
    </style>
</head>
<body>
<div class="container">
    <h1>📝 Register</h1>
    <%
        String message = "";
        boolean success = false;
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String role = request.getParameter("role"); // default 'home_cook'
            Connection conn = null;
            PreparedStatement pstmt = null;
            try {
                conn = DatabaseConnection.getConnection();
                // Check if email already exists
                PreparedStatement check = conn.prepareStatement("SELECT id FROM airg_users WHERE email=?");
                check.setString(1, email);
                ResultSet rs = check.executeQuery();
                if (rs.next()) {
                    message = "Email already registered. Please login.";
                } else {
                    pstmt = conn.prepareStatement("INSERT INTO airg_users (name, email, password, role) VALUES (?, ?, ?, ?)");
                    pstmt.setString(1, name);
                    pstmt.setString(2, email);
                    pstmt.setString(3, password); // In production, hash the password
                    pstmt.setString(4, role);
                    int res = pstmt.executeUpdate();
                    if (res > 0) {
                        message = "Registration successful! You can now login.";
                        success = true;
                    } else {
                        message = "Registration failed. Try again.";
                    }
                }
                rs.close();
                check.close();
            } catch(Exception e) {
                message = "Error: " + e.getMessage();
            } finally {
                if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if (conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
    %>
    <% if (!message.isEmpty()) { %>
        <div class="<%= success ? "success" : "error" %>"><%= message %></div>
    <% } %>
    <form method="post">
        <label>Full Name:</label> <input type="text" name="name" required>
        <label>Email:</label> <input type="email" name="email" required>
        <label>Password:</label> <input type="password" name="password" required>
        <label>Role:</label>
        <select name="role">
            <option value="home_cook">Home Cook</option>
            <option value="beginner_cook">Beginner Cook</option>
        </select>
        <input type="submit" value="Register">
    </form>
    <a href="login.jsp" class="back-link">Already have an account? Login</a><br>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>