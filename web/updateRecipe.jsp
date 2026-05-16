<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    int loggedUserId = (Integer) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    
    String recipeIdParam = request.getParameter("recipe_id");
    if (recipeIdParam == null || recipeIdParam.trim().isEmpty()) {
        response.sendRedirect("listRecipes.jsp");
        return;
    }
    int recipeId = Integer.parseInt(recipeIdParam);
    
    // Ownership check
    Connection checkConn = null;
    PreparedStatement checkStmt = null;
    ResultSet checkRs = null;
    try {
        checkConn = DatabaseConnection.getConnection();
        checkStmt = checkConn.prepareStatement("SELECT created_by FROM airg_recipes WHERE id = ?");
        checkStmt.setInt(1, recipeId);
        checkRs = checkStmt.executeQuery();
        if (checkRs.next()) {
            int ownerId = checkRs.getInt("created_by");
            if (!isAdmin && ownerId != loggedUserId) {
                response.sendRedirect("listRecipes.jsp");
                return;
            }
        } else {
            response.sendRedirect("listRecipes.jsp");
            return;
        }
    } catch (Exception e) {
        response.sendRedirect("listRecipes.jsp");
        return;
    } finally {
        if (checkRs != null) try { checkRs.close(); } catch(Exception e) {}
        if (checkStmt != null) try { checkStmt.close(); } catch(Exception e) {}
        if (checkConn != null) DatabaseConnection.closeConnection(checkConn);
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Update Recipe - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; }
        input, textarea, select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; }
        .error-list { margin: 0 0 10px 0; padding-left: 20px; }
    </style>
</head>
<body>
    <h1>✏️ Update Recipe</h1>
    <a href="index.jsp" class="back-link">← Back to Home</a>
    <div class="form-container">
        <%
        String message = "", messageType = "";
        List<String> errors = new ArrayList<String>();

        String currentTitle = "", currentDescription = "", currentInstructions = "";
        String currentCuisine = "", currentPrepTime = "", currentServings = "";

        // Load current data for the form
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement("SELECT * FROM airg_recipes WHERE id = ?");
            pstmt.setInt(1, recipeId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                currentTitle = rs.getString("title");
                currentDescription = rs.getString("description") != null ? rs.getString("description") : "";
                currentInstructions = rs.getString("instructions");
                currentCuisine = rs.getString("cuisine_type") != null ? rs.getString("cuisine_type") : "";
                currentPrepTime = String.valueOf(rs.getInt("prep_time"));
                currentServings = String.valueOf(rs.getInt("servings"));
            } else {
                out.println("<p class='error'>Recipe not found.</p>");
                return;
            }
        } catch (Exception e) {
            out.println("<p class='error'>Error loading recipe: " + e.getMessage() + "</p>");
            return;
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
            if (conn != null) DatabaseConnection.closeConnection(conn);
        }

        // Process update
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String title = request.getParameter("title");
            String description = request.getParameter("description");
            String instructions = request.getParameter("instructions");
            String cuisine_type = request.getParameter("cuisine_type");
            String prep_time_str = request.getParameter("prep_time");
            String servings_str = request.getParameter("servings");

            // Empty checks
            if (title == null || title.trim().isEmpty()) errors.add("Title is required.");
            if (instructions == null || instructions.trim().isEmpty()) errors.add("Instructions are required.");
            if (prep_time_str == null || prep_time_str.trim().isEmpty()) errors.add("Preparation time required.");
            if (servings_str == null || servings_str.trim().isEmpty()) errors.add("Servings required.");

            int prep_time = 0, servings = 0;
            // Numeric & range
            if (prep_time_str != null && !prep_time_str.trim().isEmpty()) {
                try {
                    prep_time = Integer.parseInt(prep_time_str);
                    if (prep_time < 0) errors.add("Prep time cannot be negative.");
                    else if (prep_time > 999) errors.add("Prep time too high (max 999).");
                } catch (NumberFormatException e) { errors.add("Prep time must be a number."); }
            }
            if (servings_str != null && !servings_str.trim().isEmpty()) {
                try {
                    servings = Integer.parseInt(servings_str);
                    if (servings < 1) errors.add("Servings at least 1.");
                    else if (servings > 100) errors.add("Servings max 100.");
                } catch (NumberFormatException e) { errors.add("Servings must be a number."); }
            }
            if (title != null && title.length() > 200) errors.add("Title too long (max 200).");

            if (errors.isEmpty()) {
                Connection connUp = null;
                PreparedStatement pstmtUp = null;
                try {
                    connUp = DatabaseConnection.getConnection();
                    String sql = "UPDATE airg_recipes SET title=?, description=?, instructions=?, cuisine_type=?, prep_time=?, servings=? WHERE id=?";
                    pstmtUp = connUp.prepareStatement(sql);
                    pstmtUp.setString(1, title);
                    pstmtUp.setString(2, description);
                    pstmtUp.setString(3, instructions);
                    pstmtUp.setString(4, cuisine_type);
                    pstmtUp.setInt(5, prep_time);
                    pstmtUp.setInt(6, servings);
                    pstmtUp.setInt(7, recipeId);
                    if (pstmtUp.executeUpdate() > 0) {
                        message = "✅ Recipe updated successfully!";
                        messageType = "success";
                        // Reload current values after update
                        currentTitle = title;
                        currentDescription = description;
                        currentInstructions = instructions;
                        currentCuisine = cuisine_type;
                        currentPrepTime = String.valueOf(prep_time);
                        currentServings = String.valueOf(servings);
                    } else {
                        message = "❌ No changes or recipe not found.";
                        messageType = "error";
                    }
                } catch (Exception e) {
                    message = "❌ Database error: " + e.getMessage();
                    messageType = "error";
                } finally {
                    if (pstmtUp != null) try { pstmtUp.close(); } catch(Exception e) {}
                    if (connUp != null) DatabaseConnection.closeConnection(connUp);
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
            <div class="error"><strong>Please correct:</strong><ul class="error-list"><% for(String err:errors){ %><li><%= err %></li><% } %></ul></div>
        <% } %>

        <form method="post">
            <label>Title *:</label>
            <input type="text" name="title" value="<%= currentTitle %>" required>
            <label>Description:</label>
            <textarea name="description" rows="2"><%= currentDescription %></textarea>
            <label>Instructions *:</label>
            <textarea name="instructions" rows="4" required><%= currentInstructions %></textarea>
            <label>Cuisine Type:</label>
            <input type="text" name="cuisine_type" value="<%= currentCuisine %>">
            <label>Prep Time (minutes) *:</label>
            <input type="number" name="prep_time" min="0" value="<%= currentPrepTime %>" required>
            <label>Servings *:</label>
            <input type="number" name="servings" min="1" value="<%= currentServings %>" required>
            <input type="submit" value="Update Recipe">
        </form>
    </div>
</body>
</html>