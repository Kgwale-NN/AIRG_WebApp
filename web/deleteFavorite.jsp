<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Delete Favorite - AIRG</title>
</head>
<body>
<%
String userId = request.getParameter("user_id");
String recipeId = request.getParameter("recipe_id");
if(userId != null && recipeId != null) {
    Connection conn = null;
    PreparedStatement pstmt = null;
    try {
        conn = DatabaseConnection.getConnection();
        pstmt = conn.prepareStatement("DELETE FROM airg_favorites WHERE user_id=? AND recipe_id=?");
        pstmt.setInt(1, Integer.parseInt(userId));
        pstmt.setInt(2, Integer.parseInt(recipeId));
        pstmt.executeUpdate();
    } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    finally {
        if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if(conn != null) DatabaseConnection.closeConnection(conn);
    }
}
// Redirect to list page
response.sendRedirect("listFavorites.jsp");
%>
</body>
</html>