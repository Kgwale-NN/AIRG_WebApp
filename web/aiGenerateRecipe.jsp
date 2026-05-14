<%@ page import="java.io.*, java.net.*, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="WEB-INF/loginCheck.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>AI Recipe Generator - AIRG</title>
    <style>
        body { font-family: Arial; margin: 50px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        textarea, input { width: 100%; padding: 10px; margin: 10px 0; border-radius: 5px; border: 1px solid #ccc; }
        button { background: #ff6b35; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
        .generated { background: #f9f9f9; padding: 20px; margin-top: 20px; border-left: 5px solid #ff6b35; }
        .error { color: red; }
    </style>
</head>
<body>
<div class="container">
    <h1>🧠 AI Recipe Generator</h1>
    <p>Enter ingredients you have (comma separated) – AI will create a new recipe just for you!</p>

    <form method="post">
        <label>Ingredients:</label>
        <textarea name="ingredients" rows="3" placeholder="e.g., chicken, rice, garlic, soy sauce" required><%= request.getParameter("ingredients") != null ? request.getParameter("ingredients") : "" %></textarea>
        <button type="submit">✨ Generate Recipe</button>
    </form>

    <%
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String ingredients = request.getParameter("ingredients");
            if (ingredients != null && !ingredients.trim().isEmpty()) {
                // Simulate AI generation (no API call – costs nothing)
                String[] items = ingredients.split(",");
                String mainIngredient = items[0].trim();
                // Capitalize first letter
                mainIngredient = mainIngredient.substring(0,1).toUpperCase() + mainIngredient.substring(1).toLowerCase();
                
                // Generate a title
                String[] titles = {
                    mainIngredient + " Delight",
                    "Quick " + mainIngredient + " Skillet",
                    "Easy " + mainIngredient + " Stir-Fry",
                    "Simple " + mainIngredient + " Bowl",
                    "One-Pan " + mainIngredient + " Feast"
                };
                Random rand = new Random();
                String title = titles[rand.nextInt(titles.length)];
                
                // Build ingredient list with dummy quantities
                StringBuilder ingredientList = new StringBuilder("<ul>");
                for (String ing : items) {
                    String trimmed = ing.trim();
                    if (!trimmed.isEmpty()) {
                        ingredientList.append("<li>").append(trimmed.substring(0,1).toUpperCase()).append(trimmed.substring(1).toLowerCase())
                                      .append(" – as needed</li>");
                    }
                }
                ingredientList.append("</ul>");
                
                // Simple instructions
                String instructions = "<ol>" +
                        "<li>Prepare all ingredients.</li>" +
                        "<li>Heat a pan over medium heat.</li>" +
                        "<li>Add the main ingredients and cook until tender.</li>" +
                        "<li>Season with salt, pepper, and your favourite spices.</li>" +
                        "<li>Serve hot and enjoy!</li>" +
                        "</ol>";
                
                // Combine into a styled recipe text
                String recipeText = "<strong>" + title + "</strong><br><br>" +
                                    "<strong>Ingredients:</strong><br>" + ingredientList.toString() + "<br>" +
                                    "<strong>Instructions:</strong><br>" + instructions;
    %>
                <div class="generated">
                    <h2>🍽️ AI Generated Recipe</h2>
                    <%= recipeText %>
                    <hr>
                    <p><em>Want to save this recipe? <a href="saveAIGeneratedRecipe.jsp?recipe=<%= URLEncoder.encode(recipeText, "UTF-8") %>&ingredients=<%= URLEncoder.encode(ingredients, "UTF-8") %>">Click here to add to your recipe collection</a></em></p>
                </div>
    <%
            } else {
                out.println("<p class='error'>Please enter at least one ingredient.</p>");
            }
        }
    %>

    <a href="index.jsp" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>