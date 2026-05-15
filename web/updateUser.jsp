<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Edit User - AIRG</title>
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
    <h1>✏️ Edit User</h1>
    <a href="listUsers.jsp" class="back-link">← Back to Users</a>
    <div class="form-container">
        <%
        String id = request.getParameter("id");
        String message = "";
        String messageType = "";
        // ✅ FIXED: diamond operator replaced with explicit type
        List<String> errors = new ArrayList<String>();
        
        if(id == null || id.trim().isEmpty()) {
            response.sendRedirect("listUsers.jsp");
            return;
        }
        
        // Preserve entered values for repopulation on error
        String enteredName = "";
        String enteredEmail = "";
        String enteredRole = "";
        
        // Process update
        if(request.getMethod().equalsIgnoreCase("POST")) {
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            // ✅ FIX: Renamed variable to avoid conflict with 'role' from adminCheck.jsp
            String newRole = request.getParameter("role");
            
            enteredName = (name != null) ? name : "";
            enteredEmail = (email != null) ? email : "";
            enteredRole = (newRole != null) ? newRole : "";
            
            // --- 1. Empty fields ---
            if(name == null || name.trim().isEmpty()) {
                errors.add("Full name is required.");
            }
            if(email == null || email.trim().isEmpty()) {
                errors.add("Email address is required.");
            }
            if(newRole == null || newRole.trim().isEmpty()) {
                errors.add("Role is required.");
            }
            
            // --- 2. Email format ---
            if(email != null && !email.trim().isEmpty()) {
                String emailRegex = "^[A-Za-z0-9+_.-]+@(.+)$";
                if(!email.matches(emailRegex)) {
                    errors.add("Please enter a valid email address (e.g., name@example.com).");
                }
            }
            
            // --- 3. Field length checks ---
            if(name != null && name.length() > 100) {
                errors.add("Full name is too long (maximum 100 characters).");
            }
            if(email != null && email.length() > 100) {
                errors.add("Email address is too long (maximum 100 characters).");
            }
            
            // --- 4. Duplicate email check (excluding current user) ---
            if(email != null && !email.trim().isEmpty() && errors.isEmpty()) {
                Connection connCheck = null;
                PreparedStatement pstmtCheck = null;
                ResultSet rsCheck = null;
                try {
                    connCheck = DatabaseConnection.getConnection();
                    pstmtCheck = connCheck.prepareStatement(
                        "SELECT id FROM airg_users WHERE email = ? AND id != ?"
                    );
                    pstmtCheck.setString(1, email);
                    pstmtCheck.setInt(2, Integer.parseInt(id));
                    rsCheck = pstmtCheck.executeQuery();
                    if(rsCheck.next()) {
                        errors.add("This email address is already used by another user. Please choose a different email.");
                    }
                } catch(Exception e) {
                    // ignore minor errors during check
                } finally {
                    if(rsCheck != null) try { rsCheck.close(); } catch(Exception e) {}
                    if(pstmtCheck != null) try { pstmtCheck.close(); } catch(Exception e) {}
                    if(connCheck != null) DatabaseConnection.closeConnection(connCheck);
                }
            }
            
            // --- If no errors, perform update ---
            if(errors.isEmpty()) {
                Connection conn = null;
                PreparedStatement pstmt = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    pstmt = conn.prepareStatement(
                        "UPDATE airg_users SET name=?, email=?, role=? WHERE id=?"
                    );
                    pstmt.setString(1, name);
                    pstmt.setString(2, email);
                    pstmt.setString(3, newRole);   // ✅ Use renamed variable
                    pstmt.setInt(4, Integer.parseInt(id));
                    int res = pstmt.executeUpdate();
                    if(res > 0) {
                        message = "✅ User updated successfully!";
                        messageType = "success";
                        // Update the displayed values to the new ones
                        enteredName = name;
                        enteredEmail = email;
                        enteredRole = newRole;
                    } else {
                        message = "❌ No changes or user not found.";
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
        
        // Load current data from database (if not a POST with errors, or no POST yet)
        if(!request.getMethod().equalsIgnoreCase("POST") || !errors.isEmpty()) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DatabaseConnection.getConnection();
                pstmt = conn.prepareStatement("SELECT name, email, role FROM airg_users WHERE id=?");
                pstmt.setInt(1, Integer.parseInt(id));
                rs = pstmt.executeQuery();
                if(rs.next()) {
                    if(enteredName.isEmpty()) enteredName = rs.getString("name");
                    if(enteredEmail.isEmpty()) enteredEmail = rs.getString("email");
                    if(enteredRole.isEmpty()) enteredRole = rs.getString("role");
                } else {
                    out.println("<p class='error'>User not found.</p>");
                    return;
                }
            } catch(Exception e) {
                out.println("<p class='error'>Error: " + e.getMessage() + "</p>");
                return;
            } finally {
                if(rs != null) try { rs.close(); } catch(Exception e) {}
                if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if(conn != null) DatabaseConnection.closeConnection(conn);
            }
        }
        %>
        
        <% if(!message.isEmpty()) { %>
            <div class="<%= messageType %>"><%= message %></div>
        <% } %>
        
        <% if(!errors.isEmpty()) { %>
            <div class="error">
                <strong>Please correct the following errors:</strong>
                <ul class="error-list">
                    <% for(String err : errors) { %>
                        <li><%= err %></li>
                    <% } %>
                </ul>
            </div>
        <% } %>
        
        <form method="post">
            <input type="hidden" name="id" value="<%= id %>">
            <label>Full Name *:</label>
            <input type="text" name="name" value="<%= enteredName %>" required>
            
            <label>Email *:</label>
            <input type="email" name="email" value="<%= enteredEmail %>" required>
            
            <label>Role *:</label>
            <select name="role" required>
                <option value="home_cook" <%= "home_cook".equals(enteredRole) ? "selected" : "" %>>Home Cook</option>
                <option value="beginner_cook" <%= "beginner_cook".equals(enteredRole) ? "selected" : "" %>>Beginner Cook</option>
                <option value="admin" <%= "admin".equals(enteredRole) ? "selected" : "" %>>Admin</option>
            </select>
            
            <input type="submit" value="Update User">
        </form>
    </div>
</body>
</html>