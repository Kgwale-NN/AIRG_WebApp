<%@page import="java.io.PrintWriter"%>
<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%
    response.setContentType("text/csv");
    response.setHeader("Content-Disposition", "attachment; filename=\"ingredient_usage.csv\"");
    PrintWriter pw = response.getWriter();
    pw.println("Ingredient,Unit,Number of Recipes Used In");

    String cuisineFilter = request.getParameter("cuisine");
    if (cuisineFilter == null) cuisineFilter = "";
    String fromDate = request.getParameter("fromDate");
    String toDate = request.getParameter("toDate");

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT i.name, i.unit, COUNT(DISTINCT ri.recipe_id) as usage_count ");
        sql.append("FROM airg_ingredients i ");
        sql.append("JOIN airg_recipe_ingredients ri ON i.id = ri.ingredient_id ");
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
        while (rs.next()) {
            pw.println("\"" + rs.getString("name") + "\",\"" + (rs.getString("unit") != null ? rs.getString("unit") : "") + "\"," + rs.getInt("usage_count"));
        }
    } catch (Exception e) {
        pw.println("Error," + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) DatabaseConnection.closeConnection(conn);
    }
%>