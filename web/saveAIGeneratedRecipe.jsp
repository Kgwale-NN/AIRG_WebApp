<%@ page import="java.sql.*, airg.DatabaseConnection, java.net.*" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<%
    String recipeText = request.getParameter("recipe");
    String ingredientsUsed = request.getParameter("ingredients");
    if (recipeText != null && !recipeText.isEmpty()) {
        // Here you would parse the recipeText to extract title, instructions, etc.
        // For simplicity, we just insert a basic record.
        String title = "AI Generated: " + ingredientsUsed.substring(0, Math.min(50, ingredientsUsed.length()));
        String instructions = recipeText;
        int userId = (Integer) session.getAttribute("userId");
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement("INSERT INTO airg_recipes (title, instructions, created_by) VALUES (?, ?, ?)")) {
            pstmt.setString(1, title);
            pstmt.setString(2, instructions);
            pstmt.setInt(3, userId);
            pstmt.executeUpdate();
            out.println("<h3>? Recipe saved successfully!</h3>");
            out.println("<a href='listRecipes.jsp'>View my recipes</a>");
        } catch (Exception e) {
            out.println("<p class='error'>Error saving recipe: " + e.getMessage() + "</p>");
        }
    } else {
        out.println("<p class='error'>No recipe data received.</p>");
    }
%>
<br><a href="index.jsp">? Back to Dashboard</a>