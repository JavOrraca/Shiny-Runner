library(shiny)
library(shinyjs)

# Define custom JavaScript function for enhancing the splat effect
jsCode <- "
shinyjs.enhanceSplat = function() {
  // Create a brief screen flash effect when splat occurs
  var overlay = document.createElement('div');
  overlay.style.position = 'fixed';
  overlay.style.top = '0';
  overlay.style.left = '0';
  overlay.style.width = '100%';
  overlay.style.height = '100%';
  overlay.style.backgroundColor = 'rgba(255, 0, 0, 0.3)';
  overlay.style.zIndex = '9999';
  overlay.style.pointerEvents = 'none';
  document.body.appendChild(overlay);
  
  // Remove the flash effect after a short delay
  setTimeout(function() {
    document.body.removeChild(overlay);
  }, 150);
}
"

# Custom CSS for the retro game
retro_css <- "
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
    transition: transform 0.05s ease-in-out;
  }
  .splat-effect {
    animation: splat-pulse 0.5s ease-in-out;
  }
  @keyframes splat-pulse {
    0% { transform: scale(1); box-shadow: 0 0 0 rgba(255, 0, 0, 0); }
    25% { transform: scale(1.02); box-shadow: 0 0 20px rgba(255, 0, 0, 0.8); }
    50% { transform: scale(1); box-shadow: 0 0 10px rgba(255, 0, 0, 0.5); }
    100% { transform: scale(1); box-shadow: 0 0 0 rgba(255, 0, 0, 0); }
  }
"

# Custom JavaScript to intercept the splat event
splat_interceptor <- "
window.addEventListener('DOMContentLoaded', function() {
  // Wait for the game.js to load
  setTimeout(function() {
    if (typeof window.startSplatAnimation === 'function') {
      // Store the original function
      var originalStartSplat = window.startSplatAnimation;
      
      // Override with our enhanced version
      window.startSplatAnimation = function() {
        // Call original first
        originalStartSplat.apply(this, arguments);
        
        // Now enhance with shinyjs
        if (typeof Shiny !== 'undefined') {
          Shiny.setInputValue('splat_triggered', new Date().getTime());
          
          // Add the CSS animation class
          var canvas = document.getElementById('gameCanvas');
          if (canvas) {
            canvas.classList.add('splat-effect');
            
            // Remove the class after animation completes
            setTimeout(function() {
              canvas.classList.remove('splat-effect');
            }, 500);
          }
        }
      };
    }
  }, 1000);
});
"

ui <- fluidPage(
  # Include external resources
  tags$head(
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Monofett"),
    tags$style(HTML(retro_css))
  ),

  # Main UI elements
  h1("Shiny Runner"),
  
  tags$canvas(id = "gameCanvas", width = 1280, height = 600),
  
  # Initialize shinyjs
  useShinyjs(),
  extendShinyjs(text = jsCode, functions = c("enhanceSplat")),
  
  # Include our game script with the interceptor script
  tags$script(HTML(splat_interceptor)),
  includeScript("www/game.js")
)

server <- function(input, output, session) {
  # Listen for splat events from the game
  observeEvent(input$splat_triggered, {
    # Trigger the enhanced splat effect using shinyjs
    js$enhanceSplat()
  })
}

shinyApp(ui, server)
