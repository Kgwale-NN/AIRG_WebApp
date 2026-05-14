<%@ page import="java.sql.*, airg.DatabaseConnection, java.text.*, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<%
    // Get date filter parameters (default to current month)
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
    <title>Management Summary - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #ff6b35; }
        .stats { display: flex; gap: 20px; flex-wrap: wrap; margin-bottom: 30px; }
        .stat-card { background: #f0f0f0; padding: 20px; border-radius: 10px; text-align: center; flex: 1; min-width: 120px; }
        .stat-number { font-size: 2rem; font-weight: bold; color: #ff6b35; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .filter-box { background: #f9fafb; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
        .btn { background: #ff6b35; color: white; padding: 6px 12px; border: none; border-radius: 5px; cursor: pointer; text-decoration: none; display: inline-block; margin: 5px; }
        .btn:hover { background: #e55a2b; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; text-decoration: none; }
        .section-title { margin-top: 30px; margin-bottom: 10px; font-size: 1.4rem; border-left: 4px solid #ff6b35; padding-left: 10px; }
    </style>
</head>
<body>
<div class="container">
    <h1>📊 Management Summary Report</h1>

    <!-- Filter form -->
    <div class="filter-box">
        <form method="get">
            <label>From Date:</label>
            <input type="date" name="fromDate" value="<%= fromDate %>">
            <label>To Date:</label>
            <input type="date" name="toDate" value="<%= toDate %>">
            <input type="submit" value="Apply Filter" class="btn">
        </form>
    </div>

    <%
        // Fetch statistics (total counts – not date‑filtered for simplicity)
        int totalUsers = 0, totalRecipes = 0, totalRatings = 0, totalFavorites = 0;
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        try {
            conn = DatabaseConnection.getConnection();
            stmt = conn.createStatement();
            rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_users");
            if (rs.next()) totalUsers = rs.getInt(1);
            rs.close();
            rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_recipes");
            if (rs.next()) totalRecipes = rs.getInt(1);
            rs.close();
            rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_ratings");
            if (rs.next()) totalRatings = rs.getInt(1);
            rs.close();
            rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_favorites");
            if (rs.next()) totalFavorites = rs.getInt(1);
            rs.close();
        } catch (Exception e) {
            out.println("<p style='color:red'>Error loading statistics: " + e.getMessage() + "</p>");
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (stmt != null) try { stmt.close(); } catch(Exception e) {}
            if (conn != null) DatabaseConnection.closeConnection(conn);
        }
    %>

    <div class="stats">
        <div class="stat-card"><div class="stat-number"><%= totalUsers %></div><div>Users</div></div>
        <div class="stat-card"><div class="stat-number"><%= totalRecipes %></div><div>Recipes</div></div>
        <div class="stat-card"><div class="stat-number"><%= totalRatings %></div><div>Ratings</div></div>
        <div class="stat-card"><div class="stat-number"><%= totalFavorites %></div><div>Favorites</div></div>
    </div>

    <div class="section-title">Recent Activity (Audit Log)</div>
    <div style="margin-bottom: 10px;">
        <a href="exportSummaryCSV.jsp?fromDate=<%= fromDate %>&toDate=<%= toDate %>" class="btn">Export to CSV</a>
    </div>
    <%
        conn = null;
        stmt = null;
        rs = null;
        try {
            conn = DatabaseConnection.getConnection();
            stmt = conn.createStatement();
            // Check if audit_log table exists
            DatabaseMetaData meta = conn.getMetaData();
            rs = meta.getTables(null, null, "audit_log", null);
            boolean auditExists = rs.next();
            rs.close();

            if (auditExists) {
                String sql = "SELECT action, table_name, record_id, user_id, action_date FROM audit_log " +
                             "WHERE action_date BETWEEN '" + fromDate + "' AND '" + toDate + " 23:59:59' " +
                             "ORDER BY action_date DESC LIMIT 20";
                rs = stmt.executeQuery(sql);
    %>
    <table>
        <tr><th>Action</th><th>Table</th><th>Record ID</th><th>User ID</th><th>Date</th></tr>
        <%
                boolean hasRows = false;
                while (rs.next()) {
                    hasRows = true;
        %>
        <tr>
            <td><%= rs.getString("action") %></td>
            <td><%= rs.getString("table_name") %></td>
            <td><%= rs.getInt("record_id") %></td>
            <td><%= rs.getInt("user_id") %></td>
            <td><%= rs.getTimestamp("action_date") %></td>
        </tr>
        <%
                }
                if (!hasRows) {
                    out.println("<tr><td colspan='5'>No activity recorded for the selected date range.</td></tr>");
                }
        %>
    </table>
    <%
            } else {
                out.println("<p><em>Audit log table not found. To enable this feature, create the 'audit_log' table as described in the stored procedures section.</em></p>");
            }
        } catch (Exception e) {
            out.println("<p style='color:red'>Error loading audit log: " + e.getMessage() + "</p>");
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (stmt != null) try { stmt.close(); } catch(Exception e) {}
            if (conn != null) DatabaseConnection.closeConnection(conn);
        }
    %>

    <div class="section-title">System Information</div>
    <ul>
        <li><strong>Database:</strong> MySQL (airg_db)</li>
        <li><strong>Web Server:</strong> GlassFish 4.1.1</li>
        <li><strong>Java Version:</strong> <%= System.getProperty("java.version") %></li>
        <li><strong>Server Time:</strong> <%= new java.util.Date() %></li>
    </ul>

    <a href="index.jsp" class="back-link">← Back to Main Dashboard</a>
</div>
</body>
</html>