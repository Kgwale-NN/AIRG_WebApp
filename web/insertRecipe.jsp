<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    int loggedUserId = (Integer) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    String loggedUserName = (String) session.getAttribute("userName");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Add Recipe - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 600px; margin: 0 auto; }
        input, textarea, select { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        select[multiple] { height: 120px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; color: #155724; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        .error-list { margin: 0 0 10px 0; padding-left: 20px; }
    </style>
</head>
<body>
    <h1>➕ Add New Recipe</h1>
    <a href="index.jsp" class="back-link">← Back to Home</a>
    <div class="form-container">
        <%
        String message = "";
        String messageType = "";
        List<String> errors = new ArrayList<String>();

        String enteredTitle = "", enteredDesc = "", enteredInstructions = "";
        String enteredCuisine = "", enteredPrep = "", enteredServings = "";
        int selectedChefId = loggedUserId;
        String[] selectedIngredients = request.getParameterValues("ingredients");

        if (request.getMethod().equalsIgnoreCase("POST")) {
            String title = request.getParameter("title");
            String description = request.getParameter("description");
            String instructions = request.getParameter("instructions");
            String cuisine_type = request.getParameter("cuisine_type");
            String prep_time_str = request.getParameter("prep_time");
            String servings_str = request.getParameter("servings");
            String created_by_str = request.getParameter("created_by");
            selectedIngredients = request.getParameterValues("ingredients");

            enteredTitle = title != null ? title : "";
            enteredDesc = description != null ? description : "";
            enteredInstructions = instructions != null ? instructions : "";
            enteredCuisine = cuisine_type != null ? cuisine_type : "";
            enteredPrep = prep_time_str != null ? prep_time_str : "";
            enteredServings = servings_str != null ? servings_str : "";

            // --- Empty fields ---
            if (title == null || title.trim().isEmpty()) errors.add("Title is required.");
            if (instructions == null || instructions.trim().isEmpty()) errors.add("Instructions are required.");
            if (prep_time_str == null || prep_time_str.trim().isEmpty()) errors.add("Preparation time is required.");
            if (servings_str == null || servings_str.trim().isEmpty()) errors.add("Number of servings is required.");
            if (isAdmin && (created_by_str == null || created_by_str.trim().isEmpty()))
                errors.add("Please select a chef.");
            if (selectedIngredients == null || selectedIngredients.length == 0)
                errors.add("Please select at least one ingredient for this recipe.");

            int prep_time = 0, servings = 0, created_by = selectedChefId;

            // --- Numeric validation & ranges ---
            if (prep_time_str != null && !prep_time_str.trim().isEmpty()) {
                try {
                    prep_time = Integer.parseInt(prep_time_str);
                    if (prep_time < 0) errors.add("Preparation time cannot be negative.");
                    else if (prep_time > 999) errors.add("Preparation time too high (max 999 minutes).");
                } catch (NumberFormatException e) {
                    errors.add("Preparation time must be a valid number.");
                }
            }
            if (servings_str != null && !servings_str.trim().isEmpty()) {
                try {
                    servings = Integer.parseInt(servings_str);
                    if (servings < 1) errors.add("Servings must be at least 1.");
                    else if (servings > 100) errors.add("Servings cannot exceed 100.");
                } catch (NumberFormatException e) {
                    errors.add("Servings must be a valid number.");
                }
            }
            if (isAdmin && created_by_str != null && !created_by_str.trim().isEmpty()) {
                try {
                    created_by = Integer.parseInt(created_by_str);
                } catch (NumberFormatException e) {
                    errors.add("Invalid chef selection.");
                }
            }

            // --- Field length check ---
            if (title != null && title.length() > 200) errors.add("Title too long (max 200 characters).");

            // --- Insert recipe and ingredient links ---
            if (errors.isEmpty()) {
                Connection conn = null;
                CallableStatement cstmt = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    conn.setAutoCommit(false); // start transaction

                    String sql = "{CALL sp_InsertRecipeWithLog(?, ?, ?, ?, ?, ?, ?)}";
                    cstmt = conn.prepareCall(sql);
                    cstmt.setString(1, title);
                    cstmt.setString(2, description);
                    cstmt.setString(3, instructions);
                    cstmt.setString(4, cuisine_type);
                    cstmt.setInt(5, prep_time);
                    cstmt.setInt(6, servings);
                    cstmt.setInt(7, created_by);
                    cstmt.execute();

                    // Get the ID of the newly inserted recipe (not the audit_log ID)
                    String findRecipeSql = "SELECT id FROM airg_recipes WHERE title = ? AND created_by = ? ORDER BY id DESC LIMIT 1";
                    PreparedStatement pstmtFind = conn.prepareStatement(findRecipeSql);
                    pstmtFind.setString(1, title);
                    pstmtFind.setInt(2, created_by);
                    ResultSet rsFind = pstmtFind.executeQuery();
                    int newRecipeId = 0;
                    if (rsFind.next()) {
                        newRecipeId = rsFind.getInt(1);
                    }
                    rsFind.close();
                    pstmtFind.close();

                    if (newRecipeId == 0) {
                        throw new Exception("Could not retrieve new recipe ID.");
                    }

                    // Insert ingredient links (quantity = 1, unit = 'portion' as placeholder)
                    PreparedStatement pstmtIng = conn.prepareStatement(
                        "INSERT INTO airg_recipe_ingredients (recipe_id, ingredient_id, quantity, quantity_unit) VALUES (?, ?, 1, 'portion')"
                    );
                    for (String ingIdStr : selectedIngredients) {
                        int ingId = Integer.parseInt(ingIdStr);
                        pstmtIng.setInt(1, newRecipeId);
                        pstmtIng.setInt(2, ingId);
                        pstmtIng.addBatch();
                    }
                    pstmtIng.executeBatch();
                    pstmtIng.close();

                    conn.commit();
                    message = "✅ Recipe '" + title + "' added successfully with " + selectedIngredients.length + " ingredient(s)!";
                    messageType = "success";
                    // Clear form
                    enteredTitle = enteredDesc = enteredInstructions = enteredCuisine = enteredPrep = enteredServings = "";
                    selectedIngredients = null;
                } catch (Exception e) {
                    if (conn != null) try { conn.rollback(); } catch (Exception ex) {}
                    message = "❌ Database error: " + e.getMessage();
                    messageType = "error";
                } finally {
                    if (cstmt != null) try { cstmt.close(); } catch(Exception e) {}
                    if (conn != null) {
                        try { conn.setAutoCommit(true); } catch(Exception e) {}
                        DatabaseConnection.closeConnection(conn);
                    }
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
                <strong>Please correct:</strong>
                <ul class="error-list">
                    <% for (String err : errors) { %>
                        <li><%= err %></li>
                    <% } %>
                </ul>
            </div>
        <% } %>

        <form method="post">
            <label>Title *:</label>
            <input type="text" name="title" value="<%= enteredTitle %>" required>

            <label>Description:</label>
            <textarea name="description" rows="2"><%= enteredDesc %></textarea>

            <label>Instructions *:</label>
            <textarea name="instructions" rows="4" required><%= enteredInstructions %></textarea>

            <label>Cuisine Type:</label>
            <input type="text" name="cuisine_type" value="<%= enteredCuisine %>">

            <label>Prep Time (minutes) *:</label>
            <input type="number" name="prep_time" min="0" value="<%= enteredPrep.isEmpty() ? "15" : enteredPrep %>" required>

            <label>Servings *:</label>
            <input type="number" name="servings" min="1" value="<%= enteredServings.isEmpty() ? "2" : enteredServings %>" required>

            <% if (isAdmin) { %>
                <label>Created By *:</label>
                <select name="created_by" required>
                    <option value="">-- Select User --</option>
                    <%
                    Connection conn2 = null; Statement stmt2 = null; ResultSet rs2 = null;
                    try {
                        conn2 = DatabaseConnection.getConnection();
                        stmt2 = conn2.createStatement();
                        rs2 = stmt2.executeQuery("SELECT id, name FROM airg_users ORDER BY name");
                        while (rs2.next()) {
                            int uid = rs2.getInt("id");
                            String selected = (request.getParameter("created_by") != null && request.getParameter("created_by").equals(String.valueOf(uid))) ? "selected" : "";
                            out.println("<option value='" + uid + "' " + selected + ">" + rs2.getString("name") + "</option>");
                        }
                    } catch(Exception e) {
                        out.println("<option value='1'>Alice Home</option>");
                    } finally {
                        if (rs2 != null) try { rs2.close(); } catch(Exception e) {}
                        if (stmt2 != null) try { stmt2.close(); } catch(Exception e) {}
                        if (conn2 != null) DatabaseConnection.closeConnection(conn2);
                    }
                    %>
                </select>
            <% } else { %>
                <label>Created By:</label>
                <input type="hidden" name="created_by" value="<%= loggedUserId %>">
                <input type="text" value="<%= loggedUserName %>" disabled style="background:#eee;">
            <% } %>

            <label>Ingredients * (hold Ctrl to select multiple):</label>
            <select name="ingredients" multiple required size="5">
                <%
                Connection connIng = null; Statement stmtIng = null; ResultSet rsIng = null;
                try {
                    connIng = DatabaseConnection.getConnection();
                    stmtIng = connIng.createStatement();
                    rsIng = stmtIng.executeQuery("SELECT id, name FROM airg_ingredients ORDER BY name");
                    while (rsIng.next()) {
                        int ingId = rsIng.getInt("id");
                        String ingName = rsIng.getString("name");
                        String selected = "";
                        if (selectedIngredients != null) {
                            for (String s : selectedIngredients) {
                                if (s.equals(String.valueOf(ingId))) { selected = "selected"; break; }
                            }
                        }
                        out.println("<option value='" + ingId + "' " + selected + ">" + ingName + "</option>");
                    }
                } catch (Exception e) {
                    out.println("<option disabled>Error loading ingredients</option>");
                } finally {
                    if (rsIng != null) try { rsIng.close(); } catch(Exception e) {}
                    if (stmtIng != null) try { stmtIng.close(); } catch(Exception e) {}
                    if (connIng != null) DatabaseConnection.closeConnection(connIng);
                }
                %>
            </select>
            <small>Hold Ctrl (Windows) or Cmd (Mac) to select multiple ingredients.</small>

            <input type="submit" value="Add Recipe">
        </form>
    </div>
</body>
</html>