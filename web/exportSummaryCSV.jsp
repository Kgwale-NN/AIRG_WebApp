<%@page import="java.io.PrintWriter"%>
<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%
    response.setContentType("text/csv");
    response.setHeader("Content-Disposition", "attachment; filename=\"summary_report.csv\"");
    PrintWriter pw = response.getWriter();
    pw.println("Action,Table,Record ID,User ID,Date");

    String fromDate = request.getParameter("fromDate");
    String toDate = request.getParameter("toDate");
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        stmt = conn.createStatement();
        String sql = "SELECT action, table_name, record_id, user_id, action_date FROM audit_log " +
                     "WHERE action_date BETWEEN '" + fromDate + "' AND '" + toDate + " 23:59:59' " +
                     "ORDER BY action_date DESC";
        rs = stmt.executeQuery(sql);
        while (rs.next()) {
            pw.println("\"" + rs.getString("action") + "\",\"" + rs.getString("table_name") + "\"," +
                       rs.getInt("record_id") + "," + rs.getInt("user_id") + ",\"" + rs.getTimestamp("action_date") + "\"");
        }
    } catch (Exception e) {
        pw.println("Error," + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (stmt != null) try { stmt.close(); } catch(Exception e) {}
        if (conn != null) DatabaseConnection.closeConnection(conn);
    }
%>