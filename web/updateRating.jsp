<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
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
        .error-list { margin: 0 0 10px 0; padding-left: 20px; }
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
        List<String> errors = new ArrayList<String>();

        if (id == null || id.trim().isEmpty()) {
            response.sendRedirect("listRatings.jsp");
            return;
        }

        // Process update
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String ratingStr = request.getParameter("rating");
            String review = request.getParameter("review");

            // --- Empty check ---
            if (ratingStr == null || ratingStr.trim().isEmpty())
                errors.add("Rating is required.");

            int rating = 0;
            // --- Numeric & range ---
            if (ratingStr != null && !ratingStr.trim().isEmpty()) {
                try {
                    rating = Integer.parseInt(ratingStr);
                    if (rating < 1 || rating > 5)
                        errors.add("Rating must be between 1 and 5.");
                } catch (NumberFormatException e) {
                    errors.add("Rating must be a valid number.");
                }
            }

            // --- Review length (max 500) ---
            if (review != null && review.length() > 500)
                errors.add("Review is too long (max 500 characters).");

            if (errors.isEmpty()) {
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
                    message = "❌ Database error: " + e.getMessage();
                    messageType = "error";
                } finally {
                    if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                    if (conn != null) DatabaseConnection.closeConnection(conn);
                }
            } else {
                messageType = "error";
            }
        }

        // Load current data
        int currentRating = 0;
        String currentReview = "";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
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
            out.println("<div class='error'>Error loading rating: " + e.getMessage() + "</div>");
            return;
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
            if (conn != null) DatabaseConnection.closeConnection(conn);
        }
        %>

        <% if (!message.isEmpty()) { %>
            <div class="<%= messageType %>"><%= message %></div>
        <% } %>
        <% if (!errors.isEmpty()) { %>
            <div class="error">
                <strong>Please correct:</strong>
                <ul class="error-list">
                    <% for (String err : errors) { %>
                        <li><%= err %></li>
                    <% } %>
                </ul>
            </div>
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