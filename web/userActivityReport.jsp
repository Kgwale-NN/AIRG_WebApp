<%@ page import="java.sql.*, airg.DatabaseConnection, java.text.*, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    int loggedUserId = (Integer) session.getAttribute("userId");

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
    <title>User Activity Report - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #ff6b35; }
        .filter-box { margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .btn { background: #ff6b35; color: white; border: none; padding: 6px 12px; border-radius: 5px; cursor: pointer; text-decoration: none; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; }
    </style>
</head>
<body>
<div class="container">
    <h1>👥 User Activity Report</h1>
    <div class="filter-box">
        <form method="get">
            <label>From:</label>
            <input type="date" name="fromDate" value="<%= fromDate %>">
            <label>To:</label>
            <input type="date" name="toDate" value="<%= toDate %>">
            <input type="submit" value="Apply Filter" class="btn">
        </form>
    </div>
    <div style="margin-bottom: 10px;">
        <a href="exportUserActivityCSV.jsp?fromDate=<%= fromDate %>&toDate=<%= toDate %>" class="btn">Export to CSV</a>
    </div>

    <%
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DatabaseConnection.getConnection();
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT u.id, u.name, u.email, u.role, ");
            // ✅ FIX: Use DATE(column) to compare only the date part, ignoring time
            sql.append("(SELECT COUNT(*) FROM airg_recipes WHERE created_by = u.id AND DATE(created_date) BETWEEN ? AND ?) as recipes_added, ");
            sql.append("(SELECT COUNT(*) FROM airg_ratings WHERE user_id = u.id AND DATE(rated_date) BETWEEN ? AND ?) as ratings_given, ");
            sql.append("(SELECT COUNT(*) FROM airg_favorites WHERE user_id = u.id AND DATE(added_date) BETWEEN ? AND ?) as favorites_added ");
            sql.append("FROM airg_users u WHERE 1=1 ");
            if (!isAdmin) {
                sql.append(" AND u.id = ? ");
            }
            sql.append("ORDER BY u.name");

            pstmt = conn.prepareStatement(sql.toString());
            int idx = 1;
            for (int i = 0; i < 3; i++) {
                pstmt.setString(idx++, fromDate);
                pstmt.setString(idx++, toDate);
            }
            if (!isAdmin) {
                pstmt.setInt(idx++, loggedUserId);
            }
            rs = pstmt.executeQuery();
    %>
    <table>
        <tr><th>User</th><th>Email</th><th>Role</th><th>Recipes Added</th><th>Ratings Given</th><th>Favorites Added</th></tr>
        <% while (rs.next()) { %>
            <tr>
                <td><%= rs.getString("name") %> (ID <%= rs.getInt("id") %>)</td>
                <td><%= rs.getString("email") %></td>
                <td><%= rs.getString("role") %></td>
                <td><%= rs.getInt("recipes_added") %></td>
                <td><%= rs.getInt("ratings_given") %></td>
                <td><%= rs.getInt("favorites_added") %></td>
            </tr>
        <% } %>
    </table>
    <%
        } catch (Exception e) {
            out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
            e.printStackTrace();
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