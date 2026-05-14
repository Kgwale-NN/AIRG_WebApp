<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    String minRatingStr = request.getParameter("minRating");
    int minRating = 1;
    if (minRatingStr != null && !minRatingStr.isEmpty()) {
        try { minRating = Integer.parseInt(minRatingStr); } catch(NumberFormatException e) {}
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Popular Recipes Report - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #ff6b35; }
        .filter-box { margin-bottom: 20px; }
        input, button { padding: 5px 10px; margin-right: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .btn { background: #ff6b35; color: white; border: none; padding: 6px 12px; border-radius: 5px; cursor: pointer; text-decoration: none; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; }
    </style>
</head>
<body>
<div class="container">
    <h1>⭐ Popular Recipes Report</h1>
    <div class="filter-box">
        <form method="get">
            <label>Minimum rating (1-5):</label>
            <input type="number" name="minRating" min="1" max="5" value="<%= minRating %>">
            <input type="submit" value="Apply Filter" class="btn">
        </form>
    </div>

    <div style="margin-bottom: 10px;">
        <a href="exportPopularCSV.jsp?minRating=<%= minRating %>" class="btn">Export to CSV</a>
    </div>

    <%
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT r.id, r.title, r.cuisine_type, r.prep_time, r.servings, " +
                         "AVG(rat.rating) as avg_rating, COUNT(rat.id) as num_ratings " +
                         "FROM airg_recipes r " +
                         "LEFT JOIN airg_ratings rat ON r.id = rat.recipe_id " +
                         "GROUP BY r.id " +
                         "HAVING avg_rating >= ? " +
                         "ORDER BY avg_rating DESC";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, minRating);
            rs = pstmt.executeQuery();
    %>
    <table>
        <tr><th>Title</th><th>Cuisine</th><th>Prep Time</th><th>Servings</th><th>Average Rating</th><th>Number of Ratings</th></tr>
        <% while (rs.next()) { %>
            <tr>
                <td><%= rs.getString("title") %></td>
                <td><%= rs.getString("cuisine_type") != null ? rs.getString("cuisine_type") : "-" %></td>
                <td><%= rs.getInt("prep_time") %></td>
                <td><%= rs.getInt("servings") %></td>
                <td><%= String.format("%.1f", rs.getDouble("avg_rating")) %> / 5</td>
                <td><%= rs.getInt("num_ratings") %></td>
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