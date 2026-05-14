<%@page import="java.io.PrintWriter"%>
<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%
    response.setContentType("text/csv");
    response.setHeader("Content-Disposition", "attachment; filename=\"popular_recipes.csv\"");
    PrintWriter pw = response.getWriter();
    pw.println("Title,Cuisine,Prep Time,Servings,Average Rating,Number of Ratings");

    String minRatingStr = request.getParameter("minRating");
    int minRating = 1;
    if (minRatingStr != null && !minRatingStr.isEmpty()) {
        try { minRating = Integer.parseInt(minRatingStr); } catch(NumberFormatException e) {}
    }
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        String sql = "SELECT r.title, r.cuisine_type, r.prep_time, r.servings, " +
                     "AVG(rat.rating) as avg_rating, COUNT(rat.id) as num_ratings " +
                     "FROM airg_recipes r LEFT JOIN airg_ratings rat ON r.id = rat.recipe_id " +
                     "GROUP BY r.id HAVING avg_rating >= ? ORDER BY avg_rating DESC";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, minRating);
        rs = pstmt.executeQuery();
        while (rs.next()) {
            pw.println("\"" + rs.getString("title") + "\",\"" + (rs.getString("cuisine_type") != null ? rs.getString("cuisine_type") : "") + "\"," +
                       rs.getInt("prep_time") + "," + rs.getInt("servings") + "," +
                       String.format("%.1f", rs.getDouble("avg_rating")) + "," + rs.getInt("num_ratings"));
        }
    } catch (Exception e) {
        pw.println("Error," + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) DatabaseConnection.closeConnection(conn);
    }
%>