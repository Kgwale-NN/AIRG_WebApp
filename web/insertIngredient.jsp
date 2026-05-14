<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Add Ingredient - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        h1 { color: #ff6b35; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 400px; margin: 0 auto; }
        input, select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; color: #155724; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        .error-list { margin: 0 0 10px 0; padding-left: 20px; }
    </style>
</head>
<body>
    <h1>➕ Add New Ingredient</h1>
    <a href="listIngredients.jsp" class="back-link">← Back to Ingredients</a>

    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        // ✅ FIXED: diamond operator removed
        List<String> errors = new ArrayList<String>();
        
        // Preserve entered values
        String enteredName = "";
        String enteredUnit = "";
        
        if(request.getMethod().equalsIgnoreCase("POST")) {
            String name = request.getParameter("name");
            String unit = request.getParameter("unit");
            
            enteredName = (name != null) ? name : "";
            enteredUnit = (unit != null) ? unit : "";
            
            // --- 1. Empty field check ---
            if(name == null || name.trim().isEmpty()) {
                errors.add("Ingredient name is required.");
            }
            
            // --- 2. Field length checks (database: name VARCHAR(100), unit VARCHAR(50)) ---
            if(name != null && name.length() > 100) {
                errors.add("Ingredient name is too long (maximum 100 characters).");
            }
            if(unit != null && unit.length() > 50) {
                errors.add("Unit is too long (maximum 50 characters).");
            }
            
            // --- 3. Duplicate ingredient check (optional business rule) ---
            if(name != null && !name.trim().isEmpty() && errors.isEmpty()) {
                Connection connCheck = null;
                PreparedStatement pstmtCheck = null;
                ResultSet rsCheck = null;
                try {
                    connCheck = DatabaseConnection.getConnection();
                    pstmtCheck = connCheck.prepareStatement(
                        "SELECT id FROM airg_ingredients WHERE name = ?"
                    );
                    pstmtCheck.setString(1, name.trim());
                    rsCheck = pstmtCheck.executeQuery();
                    if(rsCheck.next()) {
                        errors.add("An ingredient with this name already exists. Please use a different name.");
                    }
                } catch(Exception e) {
                    // ignore check errors
                } finally {
                    if(rsCheck != null) try { rsCheck.close(); } catch(Exception e) {}
                    if(pstmtCheck != null) try { pstmtCheck.close(); } catch(Exception e) {}
                    if(connCheck != null) DatabaseConnection.closeConnection(connCheck);
                }
            }
            
            if(errors.isEmpty()) {
                Connection conn = null;
                PreparedStatement pstmt = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    String sql = "INSERT INTO airg_ingredients (name, unit) VALUES (?, ?)";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, name);
                    pstmt.setString(2, unit);
                    int result = pstmt.executeUpdate();
                    if(result > 0) {
                        message = "✅ Ingredient '" + name + "' added successfully!";
                        messageType = "success";
                        // Clear form after success
                        enteredName = "";
                        enteredUnit = "";
                    } else {
                        message = "❌ Failed to add ingredient.";
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
            <label>Ingredient Name *:</label>
            <input type="text" name="name" value="<%= enteredName %>" required>
            
            <label>Unit (e.g., g, cup, tbsp, piece):</label>
            <input type="text" name="unit" value="<%= enteredUnit %>">
            
            <input type="submit" value="Add Ingredient">
        </form>
    </div>
</body>
</html>