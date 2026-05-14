<%@ page import="java.sql.*, airg.DatabaseConnection, java.text.*, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    String cuisineFilter = request.getParameter("cuisine");
    if (cuisineFilter == null) cuisineFilter = "";
    String fromDate = request.getParameter("fromDate");
    String toDate = request.getParameter("toDate");
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    Calendar cal = Calendar.getInstance();
    if (fromDate == null || fromDate.isEmpty()) {
        cal.set(Calendar.DAY_OF_MONTH, 1);
        fromDate = sdf.format(cal.getTime());
    }
    if (toDate == null || toDate.isEmpty()) {
        toDate = sdf.format(new java.util.Date());
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Ingredient Usage Report - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #ff6b35; }
        .filter-box { margin-bottom: 20px; }
        select, input { padding: 5px; margin-right: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .btn { background: #ff6b35; color: white; border: none; padding: 6px 12px; border-radius: 5px; cursor: pointer; text-decoration: none; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; }
    </style>
</head>
<body>
<div class="container">
    <h1>🥕 Ingredient Usage Report</h1>
    <div class="filter-box">
        <form method="get">
            <label>Cuisine:</label>
            <select name="cuisine">
                <option value="">-- All --</option>
                <option value="Italian" <%= "Italian".equals(cuisineFilter) ? "selected" : "" %>>Italian</option>
                <option value="Asian" <%= "Asian".equals(cuisineFilter) ? "selected" : "" %>>Asian</option>
                <option value="Healthy" <%= "Healthy".equals(cuisineFilter) ? "selected" : "" %>>Healthy</option>
                <option value="Breakfast" <%= "Breakfast".equals(cuisineFilter) ? "selected" : "" %>>Breakfast</option>
            </select>
            <label>From:</label>
            <input type="date" name="fromDate" value="<%= fromDate %>">
            <label>To:</label>
            <input type="date" name="toDate" value="<%= toDate %>">
            <input type="submit" value="Apply Filters" class="btn">
        </form>
    </div>
    <div style="margin-bottom: 10px;">
        <a href="exportIngredientCSV.jsp?cuisine=<%= cuisineFilter %>&fromDate=<%= fromDate %>&toDate=<%= toDate %>" class="btn">Export to CSV</a>
    </div>

    <%
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DatabaseConnection.getConnection();
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT i.id, i.name, i.unit, COUNT(DISTINCT ri.recipe_id) as usage_count ");
            sql.append("FROM airg_ingredients i ");
            sql.append("JOIN airg_recpe_ingredients ri ON i.id = ri.ingredient_id ");
            sql.append("JOIN airg_recipes r ON ri.recipe_id = r.id ");
            sql.append("WHERE r.created_date BETWEEN ? AND ? ");
            if (!cuisineFilter.isEmpty()) {
                sql.append(" AND r.cuisine_type = ? ");
            }
            sql.append("GROUP BY i.id ORDER BY usage_count DESC");
            pstmt = conn.prepareStatement(sql.toString());
            pstmt.setString(1, fromDate);
            pstmt.setString(2, toDate);
            int idx = 3;
            if (!cuisineFilter.isEmpty()) {
                pstmt.setString(idx++, cuisineFilter);
            }
            rs = pstmt.executeQuery();
    %>
    <table>
        <tr><th>Ingredient</th><th>Unit</th><th>Number of Recipes Used In</th></tr>
        <% while (rs.next()) { %>
            <tr>
                <td><%= rs.getString("name") %></td>
                <td><%= rs.getString("unit") != null ? rs.getString("unit") : "-" %></td>
                <td><%= rs.getInt("usage_count") %></td>
            </tr>
        <% } %>
    </table>
    <%
        } catch (Exception e) {
            out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
            if (conn != null) DatabaseConnection.closeConnection(conn);
        }
    %>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>