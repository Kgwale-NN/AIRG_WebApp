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
            <option value="Italian" <%= "Italian".equals(request.getParameter("cuisine")) ? "selected" : "" %>>Italian</option>
            <option value="Asian" <%= "Asian".equals(request.getParameter("cuisine")) ? "selected" : "" %>>Asian</option>
            <option value="Healthy" <%= "Healthy".equals(request.getParameter("cuisine")) ? "selected" : "" %>>Healthy</option>
            <option value="Breakfast" <%= "Breakfast".equals(request.getParameter("cuisine")) ? "selected" : "" %>>Breakfast</option>
            <option value="Casual" <%= "Casual".equals(request.getParameter("cuisine")) ? "selected" : "" %>>Casual</option>
            <option value="American" <%= "American".equals(request.getParameter("cuisine")) ? "selected" : "" %>>American</option>
        </select>
        <input type="submit" value="Filter">
    </form>

    <%
        String selectedCuisine = request.getParameter("cuisine");
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
                out.println("<tr><td colspan='5'>No recipes found for the selected cuisine.</td></tr>");
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
        <strong>Note:</strong> This filter uses the <code>cuisine_type</code> column in the <code>airg_recipes</code> table.
        You can add more cuisine types or extend to dietary restrictions by adding new columns or a separate table.
    </div>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>