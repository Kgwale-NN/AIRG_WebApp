<%@ page import="java.sql.*, airg.DatabaseConnection, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>

<!DOCTYPE html>
<html>
<head>
    <title>Search Recipes by Ingredients - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { max-width: 900px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        input[type=text] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 5px; }
        input[type=submit] { background: #ff6b35; color: white; border: none; padding: 10px 20px; cursor: pointer; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #ff6b35; color: white; }
        .match-count { font-weight: bold; color: #ff6b35; }
        .back-link { display: inline-block; margin-top: 20px; color: #ff6b35; text-decoration: none; }
        .error { color: red; }
    </style>
</head>
<body>
<div class="container">
    <h1>🔍 Search Recipes by Ingredients</h1>
    <form method="get">
        <label>Enter ingredients (comma separated, e.g., tomato, garlic, pasta):</label>
        <input type="text" name="ingredients" value="<%= request.getParameter("ingredients") != null ? request.getParameter("ingredients") : "" %>">
        <input type="submit" value="Search">
    </form>

    <%
        String ingredientsInput = request.getParameter("ingredients");
        if (ingredientsInput != null && !ingredientsInput.trim().isEmpty()) {
            // Split and clean user input
            String[] inputIngredients = ingredientsInput.toLowerCase().split(",");
            Set<String> searchIngredients = new HashSet<String>();
            for (int i = 0; i < inputIngredients.length; i++) {
                String trimmed = inputIngredients[i].trim();
                if (!trimmed.isEmpty()) searchIngredients.add(trimmed);
            }

            if (searchIngredients.isEmpty()) {
                out.println("<p class='error'>Please enter at least one valid ingredient.</p>");
            } else {
                Connection conn = null;
                Statement stmt = null;
                ResultSet rs = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    stmt = conn.createStatement();
                    String sql = "SELECT r.id, r.title, r.cuisine_type, r.prep_time, r.servings, " +
                                 "GROUP_CONCAT(DISTINCT i.name ORDER BY i.name SEPARATOR ', ') as ingredient_names " +
                                 "FROM airg_recipes r " +
                                 "JOIN airg_recipe_ingredients ri ON r.id = ri.recipe_id " +
                                 "JOIN airg_ingredients i ON ri.ingredient_id = i.id " +
                                 "GROUP BY r.id";
                    rs = stmt.executeQuery(sql);
                    
                    // Use a list of maps (explicit types, no diamond operator)
                    java.util.List<java.util.Map<String, Object>> recipeMatches = new java.util.ArrayList<java.util.Map<String, Object>>();
                    while (rs.next()) {
                        int recipeId = rs.getInt("id");
                        String title = rs.getString("title");
                        String cuisine = rs.getString("cuisine_type");
                        int prepTime = rs.getInt("prep_time");
                        int servings = rs.getInt("servings");
                        String ingredientNames = rs.getString("ingredient_names");
                        
                        int matchCount = 0;
                        if (ingredientNames != null) {
                            String[] recipeIngs = ingredientNames.toLowerCase().split(", ");
                            for (String searchIng : searchIngredients) {
                                for (int j = 0; j < recipeIngs.length; j++) {
                                    if (recipeIngs[j].contains(searchIng) || searchIng.contains(recipeIngs[j])) {
                                        matchCount++;
                                        break;
                                    }
                                }
                            }
                        }
                        if (matchCount > 0) {
                            java.util.Map<String, Object> map = new java.util.HashMap<String, Object>();
                            map.put("id", new Integer(recipeId));
                            map.put("title", title);
                            map.put("cuisine", (cuisine != null ? cuisine : "-"));
                            map.put("prepTime", new Integer(prepTime));
                            map.put("servings", new Integer(servings));
                            map.put("matchCount", new Integer(matchCount));
                            recipeMatches.add(map);
                        }
                    }
                    
                    // Sort by matchCount descending using Collections.sort with comparator
                    java.util.Collections.sort(recipeMatches, new java.util.Comparator<java.util.Map<String, Object>>() {
                        public int compare(java.util.Map<String, Object> a, java.util.Map<String, Object> b) {
                            int aCount = ((Integer) a.get("matchCount")).intValue();
                            int bCount = ((Integer) b.get("matchCount")).intValue();
                            // descending order
                            if (aCount < bCount) return 1;
                            if (aCount > bCount) return -1;
                            return 0;
                        }
                    });
            %>
                    <h2>Results (<%= recipeMatches.size() %> recipes found)</h2>
                    <% if (recipeMatches.isEmpty()) { %>
                        <p>No recipes found containing any of the ingredients: <%= String.join(", ", searchIngredients) %></p>
                    <% } else { %>
                        <table>
                            <tr><th>Recipe</th><th>Cuisine</th><th>Prep Time</th><th>Servings</th><th>Matching Ingredients</th><th></th></tr>
                            <%
                                for (int i = 0; i < recipeMatches.size(); i++) {
                                    java.util.Map<String, Object> recipe = recipeMatches.get(i);
                            %>
                                <tr>
                                    <td><%= recipe.get("title") %></td>
                                    <td><%= recipe.get("cuisine") %></td>
                                    <td><%= recipe.get("prepTime") %> min</td>
                                    <td><%= recipe.get("servings") %></td>
                                    <td class="match-count"><%= recipe.get("matchCount") %></td>
                                    <td><a href="listRecipes.jsp">View</a></td>
                                </tr>
                            <% } %>
                        </table>
                    <% }
                } catch(Exception e) {
                    out.println("<p class='error'>Database error: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (rs != null) try { rs.close(); } catch(Exception e) {}
                    if (stmt != null) try { stmt.close(); } catch(Exception e) {}
                    if (conn != null) DatabaseConnection.closeConnection(conn);
                }
            }
        }
    %>
    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>