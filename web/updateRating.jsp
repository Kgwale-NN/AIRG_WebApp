<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/adminCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>Edit Rating - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 10px; max-width: 450px; margin: 0 auto; }
        input, textarea { width: 100%; padding: 10px; margin: 8px 0 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; cursor: pointer; font-size: 16px; }
        .success { background: #d4edda; padding: 10px; margin-bottom: 20px; }
        .error { background: #f8d7da; padding: 10px; margin-bottom: 20px; }
        .back-link { color: #ff6b35; text-decoration: none; display: inline-block; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>✏️ Edit Rating</h1>
    <a href="listRatings.jsp" class="back-link">← Back to Ratings</a>
    <div class="form-container">
        <%
        String id = request.getParameter("id");
        String message = "";
        String messageType = "";

        if (id == null || id.trim().isEmpty()) {
            response.sendRedirect("listRatings.jsp");
            return;
        }

        // Process update
        if (request.getMethod().equalsIgnoreCase("POST")) {
            int rating = Integer.parseInt(request.getParameter("rating"));
            String review = request.getParameter("review");
            Connection conn = null;
            PreparedStatement pstmt = null;
            try {
                conn = DatabaseConnection.getConnection();
                pstmt = conn.prepareStatement("UPDATE airg_ratings SET rating=?, review=? WHERE id=?");
                pstmt.setInt(1, rating);
                pstmt.setString(2, review);
                pstmt.setInt(3, Integer.parseInt(id));
                int res = pstmt.executeUpdate();
                if (res > 0) {
                    message = "✅ Rating updated successfully!";
                    messageType = "success";
                    response.setHeader("Refresh", "2; URL=listRatings.jsp");
                } else {
                    message = "❌ No changes or rating not found.";
                    messageType = "error";
                }
            } catch (Exception e) {
                message = "❌ Error: " + e.getMessage();
                messageType = "error";
            } finally {
                if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
                if (conn != null) DatabaseConnection.closeConnection(conn);
            }
        }

        // Load current rating data
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        int currentRating = 0;
        String currentReview = "";
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement("SELECT rating, review FROM airg_ratings WHERE id=?");
            pstmt.setInt(1, Integer.parseInt(id));
            rs = pstmt.executeQuery();
            if (rs.next()) {
                currentRating = rs.getInt("rating");
                currentReview = rs.getString("review") != null ? rs.getString("review") : "";
            } else {
                out.println("<div class='error'>Rating not found.</div>");
                return;
            }
        } catch (Exception e) {
            out.println("<div class='error'>Error: " + e.getMessage() + "</div>");
            return;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
            if (conn != null) DatabaseConnection.closeConnection(conn);
        }
        %>

        <% if (!message.isEmpty()) { %>
            <div class="<%= messageType %>"><%= message %></div>
        <% } %>

        <form method="post">
            <label>Rating (1-5):</label>
            <input type="number" name="rating" min="1" max="5" value="<%= currentRating %>" required>

            <label>Review:</label>
            <textarea name="review" rows="4"><%= currentReview %></textarea>

            <input type="submit" value="Update Rating">
        </form>
    </div>
</body>
</html>