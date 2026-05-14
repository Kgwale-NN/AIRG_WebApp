<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Delete Rating - AIRG</title>
</head>
<body>
<%
String id = request.getParameter("id");
if(id != null && !id.trim().isEmpty()) {
    Connection conn = null;
    PreparedStatement pstmt = null;
    try {
        conn = DatabaseConnection.getConnection();
        pstmt = conn.prepareStatement("DELETE FROM airg_ratings WHERE id=?");
        pstmt.setInt(1, Integer.parseInt(id));
        int res = pstmt.executeUpdate();
    } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    finally {
        if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if(conn != null) DatabaseConnection.closeConnection(conn);
    }
}
response.sendRedirect("listRatings.jsp");
%>
</body>
</html>