<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<%
String id = request.getParameter("id");
String confirm = request.getParameter("confirm");
if(id != null && confirm != null && confirm.equals("yes")) {
    Connection conn = null;
    PreparedStatement pstmt = null;
    try {
        conn = DatabaseConnection.getConnection();
        pstmt = conn.prepareStatement("DELETE FROM airg_users WHERE id=?");
        pstmt.setInt(1, Integer.parseInt(id));
        int res = pstmt.executeUpdate();
        if(res > 0) {
            response.sendRedirect("listUsers.jsp?deleted=true");
        } else {
            out.println("User not found.");
        }
    } catch(Exception e) {
        out.println("Error: " + e.getMessage());
    } finally {
        if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if(conn != null) DatabaseConnection.closeConnection(conn);
    }
} else if(id != null) {
%>
<!DOCTYPE html>
<html>
<head>
    <title>Delete User - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .confirm-box { background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; text-align: center; }
        .btn { display: inline-block; margin: 10px; padding: 10px 20px; text-decoration: none; border-radius: 5px; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-secondary { background: #6c757d; color: white; }
    </style>
</head>
<body>
    <div class="confirm-box">
        <h1>Confirm Deletion</h1>
        <p>Are you sure you want to permanently delete this user?</p>
        <a href="deleteUser.jsp?id=<%= id %>&confirm=yes" class="btn btn-danger">Yes, Delete</a>
        <a href="listUsers.jsp" class="btn btn-secondary">Cancel</a>
    </div>
</body>
</html>
<%
} else {
    response.sendRedirect("listUsers.jsp");
}
%>