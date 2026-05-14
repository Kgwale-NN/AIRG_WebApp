<%@ page import="java.sql.*, airg.DatabaseConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    boolean isLoggedIn = session.getAttribute("userId") != null;
    String userName = (String) session.getAttribute("userName");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>AIRG | AI Recipe Generator Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif;
            background-image: url('airg.jpg');
            background-size: cover;
            background-position: center;
            background-attachment: fixed;
            color: #1e2a3e;
            line-height: 1.45;
            position: relative;
        }

        body::before {
            content: "";
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.55);
            z-index: -1;
        }

        .navbar {
            background: rgba(255, 255, 255, 0.96);
            backdrop-filter: blur(8px);
            border-bottom: 1px solid rgba(0,0,0,0.05);
            padding: 0 2rem;
            height: 64px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 10;
            flex-wrap: wrap;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .logo span:first-child {
            font-size: 26px;
        }

        .logo span:last-child {
            font-weight: 700;
            font-size: 1.35rem;
            color: #ff6b35;
            letter-spacing: -0.3px;
        }

        .nav-links {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }

        .nav-links a {
            text-decoration: none;
            color: #4a5b6e;
            font-weight: 500;
            font-size: 0.9rem;
        }

        .nav-links a:hover {
            color: #ff6b35;
        }

        .container {
            width: 95%;
            max-width: 1400px;
            margin: 0 auto;
            padding: 1.5rem 1rem;
            position: relative;
            z-index: 1;
        }

        .hero {
            margin-bottom: 1.5rem;
        }

        .hero h1 {
            font-size: 1.7rem;
            font-weight: 600;
            color: white;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }

        .hero p {
            color: rgba(255,255,255,0.9);
            font-size: 0.95rem;
        }

        .stats-row {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .stat-item {
            background: rgba(255,255,255,0.85);
            backdrop-filter: blur(4px);
            border-radius: 24px;
            padding: 0.8rem 1rem;
            min-width: 120px;
            flex: 1 1 150px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.03);
            border: 1px solid rgba(255,255,255,0.3);
            text-align: center;
        }

        .stat-number {
            font-size: 1.7rem;
            font-weight: 700;
            color: #ff6b35;
        }

        .stat-label {
            font-size: 0.7rem;
            text-transform: uppercase;
            color: #2c3e50;
            letter-spacing: 0.4px;
            margin-top: 4px;
        }

        .section-title {
            margin: 1.5rem 0 1rem 0;
        }

        .section-title h2 {
            font-size: 1.3rem;
            font-weight: 600;
            border-left: 3px solid #ff6b35;
            padding-left: 12px;
            color: white;
            text-shadow: 0 1px 2px rgba(0,0,0,0.2);
        }

        .card-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 1.2rem;
        }

        .card {
            background: rgba(255,255,255,0.85);
            backdrop-filter: blur(4px);
            border-radius: 20px;
            padding: 1.2rem;
            transition: all 0.2s;
            border: 1px solid rgba(255,255,255,0.3);
            box-shadow: 0 2px 6px rgba(0,0,0,0.02);
        }

        .card:hover {
            background: rgba(255,255,255,0.95);
            border-color: #ffd4c2;
            box-shadow: 0 10px 20px -10px rgba(0,0,0,0.08);
        }

        .card h3 {
            font-size: 1.2rem;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 0.5rem;
            color: #1f2e3e;
        }

        .card p {
            color: #2c3e50;
            font-size: 0.8rem;
            margin: 0.5rem 0 1rem;
            line-height: 1.4;
        }

        .btn-group {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .btn {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 40px;
            font-size: 0.75rem;
            font-weight: 500;
            text-decoration: none;
            transition: all 0.2s;
        }

        .btn-primary {
            background: #ff6b35;
            color: white;
        }

        .btn-primary:hover {
            background: #e85722;
        }

        .btn-outline {
            background: rgba(255,255,255,0.7);
            border: 1px solid #d4dfed;
            color: #4a5b6e;
        }

        .btn-outline:hover {
            border-color: #ff6b35;
            color: #ff6b35;
            background: #fff7f2;
        }

        .footer {
            text-align: center;
            padding: 1.5rem 1rem 1rem;
            color: rgba(255,255,255,0.8);
            font-size: 0.7rem;
            border-top: 1px solid rgba(255,255,255,0.2);
            margin-top: 1.5rem;
        }

        @media (max-width: 768px) {
            .navbar {
                padding: 0 1rem;
                height: auto;
                flex-direction: column;
                align-items: center;
                gap: 10px;
                padding-top: 10px;
                padding-bottom: 10px;
            }
            .nav-links {
                justify-content: center;
                gap: 15px;
            }
            .hero h1 {
                font-size: 1.5rem;
            }
            .stat-number {
                font-size: 1.4rem;
            }
            .card h3 {
                font-size: 1.1rem;
            }
            .btn {
                padding: 4px 10px;
                font-size: 0.7rem;
            }
        }

        @media (max-width: 480px) {
            .container {
                width: 98%;
                padding: 1rem;
            }
            .stats-row {
                gap: 0.8rem;
            }
            .stat-item {
                min-width: 100px;
                padding: 0.5rem;
            }
            .card-grid {
                gap: 1rem;
            }
            .btn-group {
                flex-direction: column;
                align-items: stretch;
            }
            .btn {
                text-align: center;
            }
        }
    </style>
</head>
<body>

<%
    int totalRecipes = 0, totalUsers = 0, totalIngredients = 0, totalFavorites = 0, totalRatings = 0;
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        stmt = conn.createStatement();
        rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_recipes");
        if (rs.next()) totalRecipes = rs.getInt(1);
        rs.close();
        rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_users");
        if (rs.next()) totalUsers = rs.getInt(1);
        rs.close();
        rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_ingredients");
        if (rs.next()) totalIngredients = rs.getInt(1);
        rs.close();
        rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_favorites");
        if (rs.next()) totalFavorites = rs.getInt(1);
        rs.close();
        rs = stmt.executeQuery("SELECT COUNT(*) FROM airg_ratings");
        if (rs.next()) totalRatings = rs.getInt(1);
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (stmt != null) try { stmt.close(); } catch (Exception e) {}
        if (conn != null) DatabaseConnection.closeConnection(conn);
    }
%>

<div class="navbar">
    <div class="logo">
        <span>🍳</span>
        <span>airg</span>
    </div>
    <div class="nav-links">
        <a href="#">dashboard</a>
        <a href="#">recipes</a>
        <a href="#">users</a>
        <a href="#">ingredients</a>
        <a href="#">favorites</a>
        <a href="#">ratings</a>
        <a href="#">reports</a>
        <% if (isLoggedIn) { %>
            <a href="logout.jsp" style="color: #ff6b35;">Logout</a>
        <% } %>
    </div>
</div>

<div class="container">
    <div class="hero">
        <h1>AI‑Powered Recipe Generator</h1>
        <p>Central dashboard – manage your entire recipe ecosystem.</p>
        <% if (isLoggedIn) { %>
            <p style="color: white;">Welcome, <%= userName %>! (<%= userRole %>)</p>
        <% } else { %>
            <p style="color: white;">Please <a href="login.jsp" style="color: #ff6b35;">login</a> or <a href="register.jsp" style="color: #ff6b35;">register</a> to access all features.</p>
        <% } %>
    </div>

    <div class="stats-row">
        <div class="stat-item"><div class="stat-number"><%= totalRecipes %></div><div class="stat-label">recipes</div></div>
        <div class="stat-item"><div class="stat-number"><%= totalUsers %></div><div class="stat-label">users</div></div>
        <div class="stat-item"><div class="stat-number"><%= totalIngredients %></div><div class="stat-label">ingredients</div></div>
        <div class="stat-item"><div class="stat-number"><%= totalFavorites %></div><div class="stat-label">favourites</div></div>
        <div class="stat-item"><div class="stat-number"><%= totalRatings %></div><div class="stat-label">ratings</div></div>
    </div>

    <div class="section-title">
        <h2>management hub</h2>
    </div>

    <div class="card-grid">
        <!-- Recipes -->
        <div class="card">
            <h3><span>📋</span> Recipes</h3>
            <p>Full CRUD: list, add, edit, delete. Core of your app.</p>
            <div class="btn-group">
                <a href="listRecipes.jsp" class="btn btn-primary">view / manage</a>
                <% if (isAdmin) { %>
                    <a href="insertRecipe.jsp" class="btn btn-outline">+ new recipe</a>
                <% } %>
            </div>
        </div>

        <!-- Users – only visible to admin -->
        <% if (isAdmin) { %>
        <div class="card">
            <h3><span>👥</span> Users</h3>
            <p>Manage accounts, roles, and profiles.</p>
            <div class="btn-group">
                <a href="listUsers.jsp" class="btn btn-primary">view / manage</a>
                <a href="insertUser.jsp" class="btn btn-outline">+ new user</a>
            </div>
        </div>
        <% } %>

        <!-- Ingredients – only visible to admin -->
        <% if (isAdmin) { %>
        <div class="card">
            <h3><span>🥕</span> Ingredients</h3>
            <p>Master ingredient list used across recipes.</p>
            <div class="btn-group">
                <a href="listIngredients.jsp" class="btn btn-primary">view / manage</a>
                <a href="insertIngredient.jsp" class="btn btn-outline">+ new ingredient</a>
            </div>
        </div>
        <% } %>

        <!-- Favorites – only visible to admin -->
        <% if (isAdmin) { %>
        <div class="card">
            <h3><span>❤️</span> Favorites</h3>
            <p>See which users favorited which recipes.</p>
            <div class="btn-group">
                <a href="listFavorites.jsp" class="btn btn-primary">view favorites</a>
                <a href="addFavorite.jsp" class="btn btn-outline">+ add favorite</a>
            </div>
        </div>
        <% } %>

        <!-- Ratings – only visible to admin -->
        <% if (isAdmin) { %>
        <div class="card">
            <h3><span>⭐</span> Ratings</h3>
            <p>User reviews and ratings.</p>
            <div class="btn-group">
                <a href="listRatings.jsp" class="btn btn-primary">view ratings</a>
                <a href="addRating.jsp" class="btn btn-outline">+ add rating</a>
            </div>
        </div>
        <% } %>

        <!-- Reports – visible to any logged‑in user -->
        <% if (isLoggedIn) { %>
        <div class="card">
            <h3><span>📊</span> Reports</h3>
            <p>Popular recipes, user activity, ingredient usage.</p>
            <div class="btn-group">
                <a href="popularRecipesReport.jsp" class="btn btn-outline">popular</a>
                <a href="userActivityReport.jsp" class="btn btn-outline">user activity</a>
                <a href="ingredientUsageReport.jsp" class="btn btn-outline">ingredient usage</a>
            </div>
        </div>
        <% } %>

        <!-- ========== USER TOOLS (visible to all logged‑in users) ========== -->
        <% if (isLoggedIn) { %>
        <div class="card">
            <h3><span>🛠️</span> User Tools</h3>
            <p>Search, filter, scale recipes, manage your favorites and ratings.</p>
            <div class="btn-group">
                <a href="searchRecipes.jsp" class="btn btn-outline">🔍 Search by Ingredients</a>
                <a href="filterRecipes.jsp" class="btn btn-outline">🎛️ Filter by Cuisine</a>
                <a href="scaleRecipe.jsp" class="btn btn-outline">📏 Scale Recipe</a>
                <a href="addFavorite.jsp" class="btn btn-outline">❤️ Add Favorite</a>
                <a href="addRating.jsp" class="btn btn-outline">⭐ Add Rating</a>
            </div>
        </div>

        <!-- ========== AI RECIPE GENERATOR CARD ========== -->
        <div class="card">
            <h3><span>🤖</span> AI Recipe Generator</h3>
            <p>Enter ingredients you have – AI creates a brand new recipe just for you!</p>
            <div class="btn-group">
                <a href="aiGenerateRecipe.jsp" class="btn btn-outline">✨ Generate Recipe</a>
            </div>
        </div>
        <% } %>

        <!-- Additional Features (placeholders) – only visible to admin -->
        <% if (isAdmin) { %>
        <div class="card">
            <h3><span>🔧</span>System & Administration</h3>
            <p>User registration, login, search, scaling, filtering, and admin dashboard.</p>
            <div class="btn-group">
                <a href="register.jsp" class="btn btn-outline">📝 Register</a>
                <a href="login.jsp" class="btn btn-outline">🔐 Login</a>
                <a href="searchRecipes.jsp" class="btn btn-outline">🔍 Search</a>
                <a href="scaleRecipe.jsp" class="btn btn-outline">📏 Scale</a>
                <a href="filterRecipes.jsp" class="btn btn-outline">🎛️ Filter</a>
                <a href="adminDashboard.jsp" class="btn btn-outline">👑 Admin</a>
            </div>
        </div>
        <% } %>
    </div>
</div>

<div class="footer">
    AIRG · AI‑Powered Recipe Generator · Dashboard
</div>
</body>
</html>