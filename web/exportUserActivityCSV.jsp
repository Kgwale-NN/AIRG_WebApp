<%@page import="java.io.PrintWriter"%>
<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%
    response.setContentType("text/csv");
    response.setHeader("Content-Disposition", "attachment; filename=\"user_activity.csv\"");
    PrintWriter pw = response.getWriter();
    pw.println("User ID,Name,Email,Role,Recipes Added,Ratings Given,Favorites Added");

    String fromDate = request.getParameter("fromDate");
    String toDate = request.getParameter("toDate");
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    int loggedUserId = (Integer) session.getAttribute("userId");

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT u.id, u.name, u.email, u.role, ");
        sql.append("(SELECT COUNT(*) FROM airg_recipes WHERE created_by = u.id AND created_date BETWEEN ? AND ?) as recipes_added, ");
        sql.append("(SELECT COUNT(*) FROM airg_ratings WHERE user_id = u.id AND rated_date BETWEEN ? AND ?) as ratings_given, ");
        sql.append("(SELECT COUNT(*) FROM airg_favorites WHERE user_id = u.id AND added_date BETWEEN ? AND ?) as favorites_added ");
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
        while (rs.next()) {
            pw.println(rs.getInt("id") + ",\"" + rs.getString("name") + "\",\"" + rs.getString("email") + "\",\"" +
                       rs.getString("role") + "\"," + rs.getInt("recipes_added") + "," + rs.getInt("ratings_given") + "," +
                       rs.getInt("favorites_added"));
        }
    } catch (Exception e) {
        pw.println("Error," + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) DatabaseConnection.closeConnection(conn);
    }
%>