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

// Splat animation variables
var splatAnimation = {
  active: false,
  particles: [],
  startTime: 0,
  duration: 1000,
  pixelSize: 4
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

// Initialize the splat explosion animation
function startSplatAnimation() {
  const centerX = player.x + player.width/2;
  const groundY = canvas.height - groundHeight;
  
  splatAnimation.active = true;
  splatAnimation.startTime = Date.now();
  splatAnimation.particles = [];
  
  // Create blood particle system - both pixelated squares and blood droplets
  const numParticles = 120; // More particles for a more dramatic effect
  
  for (let i = 0; i < numParticles; i++) {
    // Calculate random direction with more upward tendency
    const angle = Math.random() * Math.PI * 2;
    const speed = 1 + Math.random() * 7;
    
    // Some particles are squares (pixels) and some are circles (droplets)
    const isPixel = Math.random() > 0.3;
    const size = isPixel ? 
      splatAnimation.pixelSize * (0.8 + Math.random() * 1.2) : 
      2 + Math.random() * 5;
    
    // Vary the red color for a more retro look
    const redValue = 180 + Math.floor(Math.random() * 75);
    const alpha = 0.7 + Math.random() * 0.3;
    
    splatAnimation.particles.push({
      x: centerX,
      y: groundY,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed - 5, // Initial upward boost
      size: size,
      isPixel: isPixel,
      color: 'rgba(' + redValue + ', 0, 0, ' + alpha + ')',
      gravity: 0.2 + Math.random() * 0.3,
      rotation: Math.random() * Math.PI * 2,
      rotationSpeed: (Math.random() - 0.5) * 0.2
    });
  }
  
  // Add some screen shake effect with shinyjs
  const shake = function() {
    const intensity = 5;
    const shakeX = (Math.random() - 0.5) * intensity * 2;
    const shakeY = (Math.random() - 0.5) * intensity * 2;
    document.getElementById('gameCanvas').style.transform = 
      'translate(' + shakeX + 'px, ' + shakeY + 'px)';
    
    setTimeout(function() {
      document.getElementById('gameCanvas').style.transform = '';
    }, 50);
  };
  
  // Apply multiple shakes in sequence for a more dramatic effect
  shake();
  setTimeout(shake, 80);
  setTimeout(shake, 160);
}

// Draw the current state of the splat animation
function drawSplatAnimation() {
  if (!splatAnimation.active) return;
  
  const elapsed = Date.now() - splatAnimation.startTime;
  const progress = elapsed / splatAnimation.duration;
  
  // Animation is complete
  if (progress >= 1) {
    splatAnimation.active = false;
    player.showSplatText = true;
    return;
  }
  
  // Update and draw each particle
  splatAnimation.particles.forEach(function(particle) {
    // Update position with gravity
    particle.vy += particle.gravity;
    particle.x += particle.vx;
    particle.y += particle.vy;
    
    // Update rotation for square particles
    if (particle.isPixel) {
      particle.rotation += particle.rotationSpeed;
    }
    
    // Draw the particle
    ctx.save();
    ctx.fillStyle = particle.color;
    
    if (particle.isPixel) {
      // Draw a rotated square for pixel effect
      ctx.translate(particle.x, particle.y);
      ctx.rotate(particle.rotation);
      ctx.fillRect(-particle.size/2, -particle.size/2, 
                   particle.size, particle.size);
    } else {
      // Draw a circle for droplet effect
      ctx.beginPath();
      ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
      ctx.fill();
    }
    
    ctx.restore();
  });
  
  // Add a growing blood puddle on the ground
  const puddleProgress = Math.min(1, progress * 1.5);
  const puddleSize = player.width * 3 * puddleProgress;
  
  ctx.fillStyle = 'rgba(180, 0, 0, 0.8)';
  ctx.beginPath();
  ctx.ellipse(
    player.x + player.width/2, 
    canvas.height - groundHeight + 2, 
    puddleSize, 
    puddleSize * 0.3, 
    0, 0, Math.PI * 2
  );
  ctx.fill();
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

  pixels.forEach(function(row, y) {
    Array.from(row).forEach(function(char, x) {
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
    // The animated splat is now handled by drawSplatAnimation
    // We don't need to draw anything for the player here
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
  splatAnimation.active = false;
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
    setTimeout(function() {
      resetGame();
    }, 2000);
    return;
  }

  if (splatAnimation.active) {
    drawGround();
    drawSplatAnimation();
    drawPoints();
    drawHighScores();
    requestAnimationFrame(updateGame);
    return;
  }

  if (player.bloodSplat && !splatAnimation.active) {
    drawGround();
    setTimeout(function() {
      player.showSplatText = true;
    }, 2000);
    requestAnimationFrame(updateGame);
    return;
  }

  if (player.falling) {
    player.dy += gravity * 1.5;
    player.y += player.dy;

    if (player.y + player.height >= canvas.height - groundHeight) {
      player.y = canvas.height - groundHeight - player.height;
      player.bloodSplat = true;
      startSplatAnimation();
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

// Start the game when the document is ready
document.addEventListener('DOMContentLoaded', function() {
  updateGame();
});
