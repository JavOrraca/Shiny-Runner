# Install packages if you haven't already:
# install.packages("shiny")
# install.packages("shinyjs")

library(shiny)
library(shinyjs)

ui <- fluidPage(
  # Include the Google Font Monofett and custom CSS.
  tags$head(
    # Load Monofett from Google Fonts.
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Monofett"),
    tags$style(HTML("
      body {
        background-color: #222;
        color: #fff;
        font-family: 'Courier New', Courier, monospace;
      }
      /* Style for the header using Monofett */
      h1 {
        font-family: 'Monofett', cursive;
        text-align: center;
        font-size: 48px;
        margin-top: 20px;
        margin-bottom: 10px;
      }
      canvas {
        background-color: #000;
        image-rendering: pixelated;
        border: 2px solid #fff;
        display: block;
        margin: 20px auto;
      }
    "))
  ),
  
  # Header above the canvas.
  h1("Shiny Runner"),
  
  # The game canvas with a size of 1280 x 600.
  tags$canvas(id = "gameCanvas", width = 1280, height = 600),
  
  # Initialize shinyjs.
  useShinyjs(),
  
  # Inline JavaScript for the game logic.
  tags$script(HTML("
    // Get the canvas element and its context.
    var canvas = document.getElementById('gameCanvas');
    var ctx = canvas.getContext('2d');

    // Game constants.
    var gravity = 0.5;
    var scrollSpeed = 2;           // How fast obstacles move left.
    var obstacleFrequency = 150;   // Frames between new obstacles.
    var frameCount = 0;
    var groundHeight = 50;

    // Survival points: 1 point every 100ms.
    var points = 0;
    var lastPointUpdateTime = Date.now();

    // Global array to store top three scores.
    var topScores = [];

    // Variable to control the initial instructions display.
    var showInstructions = true;
    // After 5 seconds, clear the instructions and reinitialize the point timer.
    setTimeout(function(){
      showInstructions = false;
      lastPointUpdateTime = Date.now();
    }, 5000);

    // Define the player with additional properties for bird mode.
    var player = {
      x: 50,
      y: canvas.height - groundHeight - 20,
      width: 20,
      height: 20,
      dx: 0,
      dy: 0,
      jumpForce: -10,
      speed: 4,
      onGround: true,
      isBird: false
    };

    // Variables for detecting rapid up-arrow presses.
    var upKeyCount = 0;
    var lastUpKeyTime = 0;
    var keyThreshold = 300; // milliseconds between key presses to count as rapid

    // Array to hold obstacles.
    var obstacles = [];

    // Function to create a new obstacle.
    function createObstacle() {
      var obstacleHeight = Math.floor(Math.random() * 30) + 20; // height between 20 and 50
      var obstacle = {
        x: canvas.width,
        y: canvas.height - groundHeight - obstacleHeight,
        width: 20,
        height: obstacleHeight
      };
      obstacles.push(obstacle);
    }

    // Update obstacles: move them left and remove those off-screen.
    function updateObstacles() {
      obstacles.forEach(function(obstacle) {
        obstacle.x -= scrollSpeed;
      });
      obstacles = obstacles.filter(function(obstacle) {
        return obstacle.x + obstacle.width > 0;
      });
    }

    // Draw obstacles (red blocks).
    function drawObstacles() {
      ctx.fillStyle = '#f00';
      obstacles.forEach(function(obstacle) {
        ctx.fillRect(obstacle.x, obstacle.y, obstacle.width, obstacle.height);
      });
    }

    // Draw the ground.
    function drawGround() {
      ctx.fillStyle = '#555';
      ctx.fillRect(0, canvas.height - groundHeight, canvas.width, groundHeight);
    }

    // Draw the player.
    // In normal mode, draw a green square.
    // In bird mode, draw a cyan circle with a yellow beak.
    function drawPlayer() {
      if (player.isBird) {
        ctx.fillStyle = '#0ff';
        ctx.beginPath();
        ctx.arc(player.x + player.width/2, player.y + player.height/2, player.width/2, 0, Math.PI * 2);
        ctx.fill();
        
        ctx.fillStyle = '#ff0';
        ctx.beginPath();
        ctx.moveTo(player.x + player.width, player.y + player.height/2);
        ctx.lineTo(player.x + player.width + 5, player.y + player.height/2 - 3);
        ctx.lineTo(player.x + player.width + 5, player.y + player.height/2 + 3);
        ctx.closePath();
        ctx.fill();
      } else {
        ctx.fillStyle = '#0f0';
        ctx.fillRect(player.x, player.y, player.width, player.height);
      }
    }

    // Draw the survival points counter in the top middle of the canvas.
    function drawPoints() {
      ctx.font = '20px Courier New';
      ctx.fillStyle = 'white';
      ctx.textAlign = 'center';
      ctx.fillText('Points: ' + points, canvas.width / 2, 30);
    }

    // Draw the top three scores in the top right of the canvas.
    function drawHighScores() {
      ctx.font = '20px Courier New';
      ctx.fillStyle = 'white';
      ctx.textAlign = 'right';
      ctx.fillText('Top Scores:', canvas.width - 10, 30);
      for (var i = 0; i < topScores.length; i++) {
        ctx.fillText((i + 1) + '. ' + topScores[i], canvas.width - 10, 30 + (i + 1) * 25);
      }
    }

    // Draw the instructions message (if still enabled).
    function drawInstructions() {
      if (showInstructions) {
        ctx.font = '48px Courier New';
        ctx.fillStyle = '#fff';
        ctx.textAlign = 'center';
        ctx.fillText('Instructions: Figure it out!', canvas.width / 2, canvas.height / 2);
      }
    }

    // Basic rectangle collision detection.
    function checkCollision(rect1, rect2) {
      return !(rect1.x > rect2.x + rect2.width ||
               rect1.x + rect1.width < rect2.x ||
               rect1.y > rect2.y + rect2.height ||
               rect1.y + rect1.height < rect2.y);
    }

    // Reset the game when a collision occurs.
    // Note: Do not reset the instructions flag so the instructions only show on the very first launch.
    function resetGame() {
      // Only record a score if the instructions are no longer showing.
      if (!showInstructions) {
        topScores.push(points);
        // Sort scores descending and keep only the top three.
        topScores.sort(function(a, b) { return b - a; });
        if (topScores.length > 3) { 
          topScores = topScores.slice(0, 3);
        }
      }
      obstacles = [];
      player.x = 50;
      player.y = canvas.height - groundHeight - player.height;
      player.dx = 0;
      player.dy = 0;
      player.onGround = true;
      player.isBird = false;
      upKeyCount = 0;
      // Reset survival points.
      points = 0;
      lastPointUpdateTime = Date.now();
    }

    // Main game loop.
    function updateGame() {
      frameCount++;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Update survival points only if the instructions have cleared.
      if (!showInstructions) {
        var currentTime = Date.now();
        if (currentTime - lastPointUpdateTime >= 100) {
          points += Math.floor((currentTime - lastPointUpdateTime) / 100);
          lastPointUpdateTime = currentTime;
        }
      }

      // Update player's position.
      if (player.isBird) {
        // In bird mode, update position based on dx/dy (direct control; no gravity).
        player.x += player.dx;
        player.y += player.dy;
      } else {
        // Normal mode: apply gravity and update vertical position.
        player.dy += gravity;
        player.y += player.dy;
      }

      // Constrain the player within canvas bounds.
      if (player.x < 0) player.x = 0;
      if (player.x + player.width > canvas.width) player.x = canvas.width - player.width;
      if (player.y < 0) player.y = 0;
      if (!player.isBird && player.y + player.height > canvas.height - groundHeight) {
        player.y = canvas.height - groundHeight - player.height;
        player.dy = 0;
        player.onGround = true;
      } else if (player.isBird && player.y + player.height > canvas.height) {
        player.y = canvas.height - player.height;
      }

      // Generate obstacles only in normal mode.
      if (!player.isBird && frameCount % obstacleFrequency === 0) {
        createObstacle();
      }

      updateObstacles();

      // Check for collisions between the player and obstacles (only in normal mode).
      if (!player.isBird) {
        obstacles.forEach(function(obstacle) {
          if (checkCollision(player, obstacle)) {
            resetGame();
          }
        });
      }

      drawGround();
      drawPlayer();
      drawObstacles();
      drawPoints();
      drawHighScores();
      drawInstructions();

      requestAnimationFrame(updateGame);
    }

    // Listen for keydown events.
    document.addEventListener('keydown', function(e) {
      var currentTime = Date.now();

      if (e.code === 'ArrowUp') {
        if (!player.isBird) {
          // Rapid up-arrow detection for bird transformation.
          if (currentTime - lastUpKeyTime < keyThreshold) {
            upKeyCount++;
          } else {
            upKeyCount = 1;
          }
          lastUpKeyTime = currentTime;

          // If three rapid up-arrow presses are detected, transform into a bird.
          if (upKeyCount >= 3) {
            player.isBird = true;
            player.dx = 0;
            player.dy = 0;
            // Revert back to normal mode after 3 seconds.
            setTimeout(function() {
              player.isBird = false;
              player.dx = 0;
              player.dy = 0;
            }, 3000);
          }

          // Normal jump if on the ground.
          if (player.onGround) {
            player.dy = player.jumpForce;
            player.onGround = false;
          }
        } else {
          // In bird mode, pressing the up arrow moves the player upward.
          player.dy = -player.speed;
        }
      }

      // In bird mode, allow full directional control.
      if (player.isBird) {
        if (e.code === 'ArrowDown') {
          player.dy = player.speed;
        }
        if (e.code === 'ArrowRight') {
          player.dx = player.speed;
        }
        if (e.code === 'ArrowLeft') {
          player.dx = -player.speed;
        }
      }
    });

    // Listen for keyup events in bird mode to stop movement.
    document.addEventListener('keyup', function(e) {
      if (player.isBird) {
        if (e.code === 'ArrowUp' || e.code === 'ArrowDown') {
          player.dy = 0;
        }
        if (e.code === 'ArrowLeft' || e.code === 'ArrowRight') {
          player.dx = 0;
        }
      }
    });

    // Start the game loop.
    updateGame();
  "))
)

server <- function(input, output, session) {
  # No server-side logic is needed.
}

shinyApp(ui, server)
