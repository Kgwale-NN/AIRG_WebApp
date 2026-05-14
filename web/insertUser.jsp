<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Add User - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 450px; margin: 0 auto; }
        input, select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        .error-list { margin: 0 0 10px 0; padding-left: 20px; }
    </style>
</head>
<body>
    <h1>➕ Add New User</h1>
    <a href="listUsers.jsp" class="back-link">← Back to Users</a>
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        // ✅ FIXED: removed diamond operator
        List<String> errors = new ArrayList<String>();
        
        // Preserve entered values
        String enteredName = "";
        String enteredEmail = "";
        String enteredRole = "home_cook";
        
        if(request.getMethod().equalsIgnoreCase("POST")) {
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String userRoleParam = request.getParameter("role");
            
            enteredName = name != null ? name : "";
            enteredEmail = email != null ? email : "";
            enteredRole = userRoleParam != null ? userRoleParam : "home_cook";
            
            // --- 1. Empty field checks ---
            if (name == null || name.trim().isEmpty()) {
                errors.add("Full name is required.");
            }
            if (email == null || email.trim().isEmpty()) {
                errors.add("Email address is required.");
            }
            if (password == null || password.trim().isEmpty()) {
                errors.add("Password is required.");
            }
            
            // --- 2. Email format validation (basic) ---
            if (email != null && !email.trim().isEmpty()) {
                String emailRegex = "^[A-Za-z0-9+_.-]+@(.+)$";
                if (!email.matches(emailRegex)) {
                    errors.add("Please enter a valid email address (e.g., name@example.com).");
                }
            }
            
            // --- 3. Field length checks (database limits) ---
            if (name != null && name.length() > 100) {
                errors.add("Full name is too long (maximum 100 characters).");
            }
            if (email != null && email.length() > 100) {
                errors.add("Email address is too long (maximum 100 characters).");
            }
            if (password != null && password.length() > 255) {
                errors.add("Password is too long (maximum 255 characters).");
            }
            
            // --- 4. Duplicate email check ---
            if (email != null && !email.trim().isEmpty() && errors.isEmpty()) {
                Connection connCheck = null;
                PreparedStatement pstmtCheck = null;
                ResultSet rsCheck = null;
                try {
                    connCheck = DatabaseConnection.getConnection();
                    pstmtCheck = connCheck.prepareStatement("SELECT id FROM airg_users WHERE email = ?");
                    pstmtCheck.setString(1, email);
                    rsCheck = pstmtCheck.executeQuery();
                    if (rsCheck.next()) {
                        errors.add("This email address is already registered. Please use a different email.");
                    }
                } catch(Exception e) {
                    // ignore
                } finally {
                    if (rsCheck != null) try { rsCheck.close(); } catch(Exception e) {}
                    if (pstmtCheck != null) try { pstmtCheck.close(); } catch(Exception e) {}
                    if (connCheck != null) DatabaseConnection.closeConnection(connCheck);
                }
            }
            
            // --- If no errors, insert user ---
            if (errors.isEmpty()) {
                Connection conn = null;
                PreparedStatement pstmt = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    String sql = "INSERT INTO airg_users (name, email, password, role) VALUES (?, ?, ?, ?)";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, name);
                    pstmt.setString(2, email);
                    pstmt.setString(3, password);
                    pstmt.setString(4, userRoleParam);
                    int res = pstmt.executeUpdate();
                    if(res > 0) {
                        message = "✅ User '" + name + "' added successfully!";
                        messageType = "success";
                        enteredName = "";
                        enteredEmail = "";
                        enteredRole = "home_cook";
                    } else {
                        message = "❌ Failed to add user.";
                        messageType = "error";
                    }
                } catch(Exception e) {
                    message = "❌ Database error: " + e.getMessage();
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
            <label>Full Name *:</label>
            <input type="text" name="name" value="<%= enteredName %>" required>
            
            <label>Email *:</label>
            <input type="email" name="email" value="<%= enteredEmail %>" required>
            
            <label>Password *:</label>
            <input type="password" name="password" required>
            
            <label>Role:</label>
            <select name="role">
                <option value="home_cook" <%= "home_cook".equals(enteredRole) ? "selected" : "" %>>Home Cook</option>
                <option value="beginner_cook" <%= "beginner_cook".equals(enteredRole) ? "selected" : "" %>>Beginner Cook</option>
                <option value="admin" <%= "admin".equals(enteredRole) ? "selected" : "" %>>Admin</option>
            </select>
            
            <input type="submit" value="Add User">
        </form>
    </div>
</body>
</html>