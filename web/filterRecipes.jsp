<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>

<!DOCTYPE html>
<html>
<head>
    <title>Filter Recipes by Cuisine - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { max-width: 900px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        select { width: 100%; padding: 10px; margin: 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; padding: 10px 20px; cursor: pointer; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; text-decoration: none; }
        .info { margin-top: 20px; font-style: italic; color: #666; }
    </style>
</head>
<body>
<div class="container">
    <h1>🎛️ Filter Recipes by Cuisine</h1>
    <form method="get">
        <label>Select Cuisine Type:</label>
        <select name="cuisine">
            <option value="">-- All Cuisines --</option>
            <%
                Connection connCuisine = null;
                Statement stmtCuisine = null;
                ResultSet rsCuisine = null;
                String selectedCuisine = request.getParameter("cuisine");
                try {
                    connCuisine = DatabaseConnection.getConnection();
                    stmtCuisine = connCuisine.createStatement();
                    // Get distinct cuisine types from existing recipes (ignore null/empty)
                    rsCuisine = stmtCuisine.executeQuery("SELECT DISTINCT cuisine_type FROM airg_recipes WHERE cuisine_type IS NOT NULL AND cuisine_type != '' ORDER BY cuisine_type");
                    while (rsCuisine.next()) {
                        String cuisine = rsCuisine.getString("cuisine_type");
                        String selected = (cuisine.equals(selectedCuisine)) ? "selected" : "";
                        out.println("<option value='" + cuisine + "' " + selected + ">" + cuisine + "</option>");
                    }
                } catch (Exception e) {
                    out.println("<option disabled>Error loading cuisines</option>");
                } finally {
                    if (rsCuisine != null) try { rsCuisine.close(); } catch(Exception e) {}
                    if (stmtCuisine != null) try { stmtCuisine.close(); } catch(Exception e) {}
                    if (connCuisine != null) DatabaseConnection.closeConnection(connCuisine);
                }
            %>
        </select>
        <input type="submit" value="Filter">
    </form>

    <%
        // Now display recipes based on selected cuisine (if any)
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        try {
            conn = DatabaseConnection.getConnection();
            stmt = conn.createStatement();
            String sql = "SELECT id, title, cuisine_type, prep_time, servings FROM airg_recipes";
            if (selectedCuisine != null && !selectedCuisine.trim().isEmpty()) {
                sql += " WHERE cuisine_type = '" + selectedCuisine + "'";
            }
            sql += " ORDER BY title";
            rs = stmt.executeQuery(sql);
    %>
    <h2>Recipes</h2>
    <table>
        <tr><th>Title</th><th>Cuisine</th><th>Prep Time (min)</th><th>Servings</th><th></th></tr>
        <%
            boolean hasResults = false;
            while (rs.next()) {
                hasResults = true;
        %>
        <tr>
            <td><%= rs.getString("title") %></td>
            <td><%= rs.getString("cuisine_type") != null ? rs.getString("cuisine_type") : "-" %></td>
            <td><%= rs.getInt("prep_time") %></td>
            <td><%= rs.getInt("servings") %></td>
            <td><a href="listRecipes.jsp">View</a></td>
        </tr>
        <%
            }
            if (!hasResults) {
                out.println("<tr><td colspan='5'>No recipes found for the selected cuisine.</div>\n</body>\n</html>");
            }
        %>
    </table>
    <%
        } catch (Exception e) {
            out.println("<p class='error' style='color:red'>Error: " + e.getMessage() + "</p>");
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (stmt != null) try { stmt.close(); } catch(Exception e) {}
            if (conn != null) DatabaseConnection.closeConnection(conn);
        }
    %>

    <div class="info">
        <strong>Note:</strong> Cuisine options are dynamically loaded from existing recipes.  
        If you add a new cuisine type (e.g., "African"), it will automatically appear here.
    </div>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>