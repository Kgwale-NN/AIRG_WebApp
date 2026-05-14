<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>

<!DOCTYPE html>
<html>
<head>
    <title>Scale Recipe - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; max-width: 700px; margin: 0 auto; }
        select, input[type=number] { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; padding: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; text-decoration: none; }
        .error { color: red; }
        .info { background: #f0f0f0; padding: 10px; margin: 10px 0; }
    </style>
</head>
<body>
<div class="container">
    <h1>📏 Scale Recipe Servings</h1>

    <%
        String recipeId = request.getParameter("recipe_id");
        String newServingsStr = request.getParameter("new_servings");
        String action = request.getParameter("action");
        int originalServings = 0;
        String recipeTitle = "";
        boolean showScaled = false;

        // Get original servings and title when a recipe is selected
        if (recipeId != null && !recipeId.trim().isEmpty()) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DatabaseConnection.getConnection();
                pstmt = conn.prepareStatement("SELECT title, servings FROM airg_recipes WHERE id = ?");
                pstmt.setInt(1, Integer.parseInt(recipeId));
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    recipeTitle = rs.getString("title");
                    originalServings = rs.getInt("servings");
                }
            } catch (Exception e) {
                out.println("<p class='error'>Error loading recipe: " + e.getMessage() + "</p>");
            } finally {
                if (rs != null) try { rs.close(); } catch(Exception e){}
                if (pstmt != null) try { pstmt.close(); } catch(Exception e){}
                if (conn != null) DatabaseConnection.closeConnection(conn);
            }
        }

        // If scale button is clicked, show scaled quantities
        if ("scale".equals(action) && newServingsStr != null && !newServingsStr.trim().isEmpty()) {
            showScaled = true;
        }
    %>

    <!-- Step 1: Select a recipe -->
    <form method="get">
        <label>Select a recipe:</label>
        <select name="recipe_id" onchange="this.form.submit()">
            <option value="">-- Select Recipe --</option>
            <%
                Connection conn = null;
                Statement stmt = null;
                ResultSet rs = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    stmt = conn.createStatement();
                    rs = stmt.executeQuery("SELECT id, title, servings FROM airg_recipes ORDER BY title");
                    while (rs.next()) {
                        int rid = rs.getInt("id");
                        String selected = (recipeId != null && recipeId.equals(String.valueOf(rid))) ? "selected" : "";
                        out.println("<option value='" + rid + "' " + selected + ">" + rs.getString("title") + " (servings: " + rs.getInt("servings") + ")</option>");
                    }
                } catch (Exception e) {
                    out.println("<option>Error loading recipes</option>");
                } finally {
                    if (rs != null) try { rs.close(); } catch(Exception e){}
                    if (stmt != null) try { stmt.close(); } catch(Exception e){}
                    if (conn != null) DatabaseConnection.closeConnection(conn);
                }
            %>
        </select>
        <noscript><input type="submit" value="Load Recipe"></noscript>
    </form>

    <%
        if (recipeId != null && !recipeId.trim().isEmpty() && originalServings > 0) {
    %>
    <!-- Step 2: Enter new servings -->
    <form method="get">
        <input type="hidden" name="recipe_id" value="<%= recipeId %>">
        <input type="hidden" name="action" value="scale">
        <label>Current servings: <%= originalServings %></label>
        <label>New number of servings:</label>
        <input type="number" name="new_servings" min="1" value="<%= newServingsStr != null ? newServingsStr : "" %>" required>
        <input type="submit" value="Scale Recipe">
    </form>
    <%
        }

        if (showScaled && recipeId != null && !recipeId.trim().isEmpty() && newServingsStr != null) {
            int newServings = 0;
            try {
                newServings = Integer.parseInt(newServingsStr);
            } catch (NumberFormatException e) {
                out.println("<p class='error'>Please enter a valid number of servings.</p>");
                return;
            }
            double factor = (double) newServings / originalServings;
    %>
        <div class="info">
            <strong><%= recipeTitle %></strong><br>
            Original servings: <%= originalServings %> → New servings: <%= newServings %><br>
            Scaling factor: <%= String.format("%.2f", factor) %>
        </div>
        <h3>Scaled Ingredient Quantities</h3>
        <%
            Connection conn2 = null;
            PreparedStatement pstmt2 = null;
            ResultSet rs2 = null;
            try {
                conn2 = DatabaseConnection.getConnection();
                pstmt2 = conn2.prepareStatement(
                    "SELECT i.name, ri.quantity, ri.quantity_unit " +
                    "FROM airg_recipe_ingredients ri " +
                    "JOIN airg_ingredients i ON ri.ingredient_id = i.id " +
                    "WHERE ri.recipe_id = ?"
                );
                pstmt2.setInt(1, Integer.parseInt(recipeId));
                rs2 = pstmt2.executeQuery();
                boolean hasIngredients = false;
        %>
        <table>
            <tr><th>Ingredient</th><th>Original Quantity</th><th>Scaled Quantity</th><th>Unit</th></tr>
            <%
                while (rs2.next()) {
                    hasIngredients = true;
                    String name = rs2.getString("name");
                    double qty = rs2.getDouble("quantity");
                    String unit = rs2.getString("quantity_unit");
                    double scaledQty = qty * factor;
            %>
                <tr>
                    <td><%= name %></td>
                    <td align="right"><%= qty %></td>
                    <td align="right"><%= String.format("%.2f", scaledQty) %></td>
                    <td><%= unit != null ? unit : "-" %></td>
                </tr>
            <%
                }
                if (!hasIngredients) {
                    out.println("<tr><td colspan='4'>No ingredients found for this recipe.</td></tr>");
                }
            %>
        </table>
        <%
            } catch (Exception e) {
                out.println("<p class='error'>Error loading ingredients: " + e.getMessage() + "</p>");
            } finally {
                if (rs2 != null) try { rs2.close(); } catch(Exception e){}
                if (pstmt2 != null) try { pstmt2.close(); } catch(Exception e){}
                if (conn2 != null) DatabaseConnection.closeConnection(conn2);
            }
        %>
    <%
        } else if (showScaled) {
            out.println("<p class='error'>Please select a recipe and enter a valid number of servings.</p>");
        }
    %>

    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>