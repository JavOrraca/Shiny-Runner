library(shiny)
library(shinyjs)

ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Monofett"),
    tags$style(HTML("
      body {
        background-color: #222;
        color: #fff;
        font-family: 'Courier New', Courier, monospace;
      }
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

  h1("Shiny Runner"),

  tags$canvas(id = "gameCanvas", width = 1280, height = 600),

  useShinyjs(),

  tags$script(HTML("
    var canvas = document.getElementById('gameCanvas');
    var ctx = canvas.getContext('2d');

    var gravity = 0.5;
    var scrollSpeed = 2;
    var obstacleFrequency = 150;
    var frameCount = 0;
    var groundHeight = 50;

    var points = 0;
    var lastPointUpdateTime = Date.now();

    var topScores = [];

    var showInstructions = true;
    setTimeout(function(){
      showInstructions = false;
      lastPointUpdateTime = Date.now();
    }, 5000);

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
      isBird: false,
      birdModeEnding: false,
      bloodSplat: false,
      falling: false,
      showSplatText: false,
      gameOver: false
    };

    var upKeyCount = 0;
    var lastUpKeyTime = 0;
    var keyThreshold = 300;
    var obstacles = [];

    function createObstacle() {
      var obstacleHeight = Math.floor(Math.random() * 30) + 20;
      var obstacle = {
        x: canvas.width,
        y: canvas.height - groundHeight - obstacleHeight,
        width: 20,
        height: obstacleHeight
      };
      obstacles.push(obstacle);
    }

    function drawSplatText() {
      const pixels = [
        '  SSSSS  PPPP   L      AAA   TTTTT  !!',
        ' S      P   P  L      A   A    T    !!',
        '  SSS   PPPP   L      AAAAA    T    !!',
        '     S  P      L      A   A    T    !!',
        'SSSSS   P      LLLLL  A   A    T    !!',
        '                                       ',
        '                                    !!'
      ];
        ctx.fillStyle = '#ff0000';
      const pixelSize = 20;
      const startX = canvas.width/2 - (pixels[0].length * pixelSize)/2;
      const startY = canvas.height/2 - (pixels.length * pixelSize)/2;

      pixels.forEach((row, y) => {
        [...row].forEach((char, x) => {
          if (char !== ' ') {
            ctx.fillRect(
              startX + x * pixelSize,
              startY + y * pixelSize,
              pixelSize,
              pixelSize
          );
        }
        });
      });
      }

    function updateObstacles() {
        obstacles.forEach(function(obstacle) {
        obstacle.x -= scrollSpeed;
        });
      obstacles = obstacles.filter(function(obstacle) {
        return obstacle.x + obstacle.width > 0;
      });
      }

    function drawObstacles() {
      ctx.fillStyle = '#f00';
        obstacles.forEach(function(obstacle) {
        ctx.fillRect(obstacle.x, obstacle.y, obstacle.width, obstacle.height);
      });
}

    function drawGround() {
      ctx.fillStyle = '#555';
      ctx.fillRect(0, canvas.height - groundHeight, canvas.width, groundHeight);
    }

    function drawPlayer() {
      if (player.bloodSplat) {
        ctx.fillStyle = '#ff0000';
        ctx.beginPath();
        ctx.arc(player.x + player.width/2, canvas.height - groundHeight, player.width * 1.5, 0, Math.PI * 2);
        ctx.fill();

        for (let i = 0; i < 12; i++) {
          let angle = (Math.PI * 2 * i) / 12;
          let distance = player.width * 2;
          ctx.beginPath();
          ctx.arc(
            player.x + player.width/2 + Math.cos(angle) * distance,
            canvas.height - groundHeight + Math.sin(angle) * distance,
            player.width/3,
            0,
            Math.PI * 2
          );
          ctx.fill();
        }
        return;
      }

      if (player.falling) {
        // Keep the bird appearance when falling
        // Bird body
        ctx.fillStyle = '#0ff';
        ctx.beginPath();
        ctx.arc(player.x + player.width/2, player.y + player.height/2, player.width/2, 0, Math.PI * 2);
        ctx.fill();
        
        // Bird wings
        ctx.fillStyle = '#00cccc';
        ctx.beginPath();
        ctx.ellipse(
          player.x + player.width/2, 
          player.y + player.height/2 + 2, 
          player.width/3, 
          player.height/4, 
          0, 0, Math.PI * 2
        );
        ctx.fill();
        
        // Bird beak
        ctx.fillStyle = '#ff0';
        ctx.beginPath();
        ctx.moveTo(player.x + player.width, player.y + player.height/2);
        ctx.lineTo(player.x + player.width + 5, player.y + player.height/2 - 3);
        ctx.lineTo(player.x + player.width + 5, player.y + player.height/2 + 3);
        ctx.closePath();
        ctx.fill();
        
        // Bird eye
        ctx.fillStyle = '#000';
        ctx.beginPath();
        ctx.arc(player.x + player.width/2 + 3, player.y + player.height/2 - 2, 2, 0, Math.PI * 2);
        ctx.fill();
        return;
      }

      if (player.isBird) {
        // Bird mode - blue bird with yellow beak
        // Bird body
        ctx.fillStyle = '#0ff';
        ctx.beginPath();
        ctx.arc(player.x + player.width/2, player.y + player.height/2, player.width/2, 0, Math.PI * 2);
        ctx.fill();
        
        // Bird wings
        ctx.fillStyle = '#00cccc';
        ctx.beginPath();
        ctx.ellipse(
          player.x + player.width/2, 
          player.y + player.height/2 + 2, 
          player.width/3, 
          player.height/4, 
          0, 0, Math.PI * 2
        );
        ctx.fill();
        
        // Bird beak
        ctx.fillStyle = '#ff0';
        ctx.beginPath();
        ctx.moveTo(player.x + player.width, player.y + player.height/2);
        ctx.lineTo(player.x + player.width + 5, player.y + player.height/2 - 3);
        ctx.lineTo(player.x + player.width + 5, player.y + player.height/2 + 3);
        ctx.closePath();
        ctx.fill();
        
        // Bird eye
        ctx.fillStyle = '#000';
        ctx.beginPath();
        ctx.arc(player.x + player.width/2 + 3, player.y + player.height/2 - 2, 2, 0, Math.PI * 2);
        ctx.fill();
      } else {
        // Retro 8-bit birdman
        const pixelSize = 4;
        const baseX = player.x;
        const baseY = player.y;
        
        // Body (green)
        ctx.fillStyle = '#0a0';
        ctx.fillRect(baseX + 4, baseY + 8, 12, 12);
        
        // Head (flesh tone)
        ctx.fillStyle = '#fca';
        ctx.fillRect(baseX + 4, baseY, 12, 8);
        
        // Eyes (black)
        ctx.fillStyle = '#000';
        ctx.fillRect(baseX + 6, baseY + 2, 2, 2);
        ctx.fillRect(baseX + 12, baseY + 2, 2, 2);
        
        // Beak/nose (yellow)
        ctx.fillStyle = '#ff0';
        ctx.fillRect(baseX + 9, baseY + 4, 2, 2);
        
        // Wings/arms (blue)
        ctx.fillStyle = '#00f';
        ctx.fillRect(baseX, baseY + 8, 4, 4);
        ctx.fillRect(baseX + 16, baseY + 8, 4, 4);
        
        // Feet (orange)
        ctx.fillStyle = '#f80';
        ctx.fillRect(baseX + 4, baseY + 20, 4, 2);
        ctx.fillRect(baseX + 12, baseY + 20, 4, 2);
      }
    }

    function drawPoints() {
      ctx.font = '20px Courier New';
      ctx.fillStyle = 'white';
      ctx.textAlign = 'center';
      ctx.fillText('Points: ' + points, canvas.width / 2, 30);
    }

    function drawHighScores() {
      ctx.font = '20px Courier New';
      ctx.fillStyle = 'white';
      ctx.textAlign = 'right';
      ctx.fillText('Top Scores:', canvas.width - 10, 30);
      for (var i = 0; i < topScores.length; i++) {
        ctx.fillText((i + 1) + '. ' + topScores[i], canvas.width - 10, 30 + (i + 1) * 25);
      }
    }

    function drawGameOver() {
      ctx.font = '48px Courier New';
      ctx.fillStyle = '#fff';
      ctx.textAlign = 'center';
      ctx.fillText('Game Over - Press Space to Restart', canvas.width / 2, canvas.height - 100);
    }

    function drawInstructions() {
      if (showInstructions) {
        ctx.font = '48px Courier New';
        ctx.fillStyle = '#fff';
        ctx.textAlign = 'center';
        ctx.fillText('Instructions: Figure it out!', canvas.width / 2, canvas.height / 2);
      }
    }

    function checkCollision(rect1, rect2) {
      return !(rect1.x > rect2.x + rect2.width ||
               rect1.x + rect1.width < rect2.x ||
               rect1.y > rect2.y + rect2.height ||
               rect1.y + rect1.height < rect2.y);
    }

    function resetGame() {
      if (!showInstructions) {
        topScores.push(points);
        topScores.sort(function(a, b) { return b - a; });
        if (topScores.length > 3) {
          topScores = topScores.slice(0, 3);
        }
      }
      player.gameOver = true;
      drawGameOver();
    }

    function startNewGame() {
      obstacles = [];
      player.x = 50;
      player.y = canvas.height - groundHeight - player.height;
      player.dx = 0;
      player.dy = 0;
      player.onGround = true;
      player.isBird = false;
      player.bloodSplat = false;
      player.birdModeEnding = false;
      player.falling = false;
      player.showSplatText = false;
      player.gameOver = false;
      upKeyCount = 0;
      points = 0;
      lastPointUpdateTime = Date.now();
    }

    function updateGame() {
      frameCount++;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      if (player.gameOver) {
        drawGround();
        drawGameOver();
        return;
      }

      if (player.showSplatText) {
        drawGround();
        drawSplatText();
        setTimeout(() => {
          resetGame();
        }, 2000);
        return;
      }

      if (player.bloodSplat) {
        drawGround();
        drawPlayer();
        drawPoints();
        drawHighScores();
        setTimeout(() => {
          player.showSplatText = true;
        }, 2000);
        requestAnimationFrame(updateGame);
        return;
      }

      if (player.falling) {
        player.dy += gravity * 1.5;
        player.y += player.dy;

        if (player.y + player.height >= canvas.height - groundHeight) {
          player.bloodSplat = true;
        }

        drawGround();
        drawPlayer();
        drawPoints();
        drawHighScores();
        requestAnimationFrame(updateGame);
        return;
      }

      if (!showInstructions) {
        var currentTime = Date.now();
        if (currentTime - lastPointUpdateTime >= 100) {
          points += Math.floor((currentTime - lastPointUpdateTime) / 100);
          lastPointUpdateTime = currentTime;
        }
      }

      if (player.isBird) {
        player.x += player.dx;
        player.y += player.dy;

        if (player.y + player.height > canvas.height - groundHeight) {
          player.y = canvas.height - groundHeight - player.height;
          player.dy = 0;
        }
      } else {
        player.dy += gravity;
        player.y += player.dy;
      }

      if (player.x < 0) player.x = 0;
      if (player.x + player.width > canvas.width) player.x = canvas.width - player.width;
      if (player.y < 0) player.y = 0;
      if (!player.isBird && player.y + player.height > canvas.height - groundHeight) {
        player.y = canvas.height - groundHeight - player.height;
        player.dy = 0;
        player.onGround = true;
      }

      if (!player.isBird && frameCount % obstacleFrequency === 0) {
        createObstacle();
      }
      updateObstacles();

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

    document.addEventListener('keydown', function(e) {
      if (e.code === 'Space' && player.gameOver) {
        startNewGame();
        requestAnimationFrame(updateGame);
        return;
      }

      var currentTime = Date.now();

      if (e.code === 'ArrowUp') {
        if (!player.isBird && !player.birdModeEnding) {
          if (currentTime - lastUpKeyTime < keyThreshold) {
            upKeyCount++;
          } else {
            upKeyCount = 1;
          }
          lastUpKeyTime = currentTime;

          if (upKeyCount >= 3) {
            player.isBird = true;
            player.dx = 0;
            player.dy = 0;
            setTimeout(function() {
              if (player.y < canvas.height * 0.2) {
                player.isBird = false;
                player.falling = true;
                player.dx = 0;
                player.dy = 0;
              } else {
                player.isBird = false;
                player.dx = 0;
                player.dy = 0;
              }
            }, 3000);
          }

          if (player.onGround) {
            player.dy = player.jumpForce;
            player.onGround = false;
          }
        } else {
          player.dy = -player.speed;
        }
      }

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

    updateGame();
  "))
)

server <- function(input, output, session) {
}

shinyApp(ui, server)
