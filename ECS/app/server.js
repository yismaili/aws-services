const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// health check endpoint for ALB
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.get('/', (req, res) => {
  console.log(`Request received at ${new Date().toISOString()}`);
  res.send(`
    <html>
      <body style="font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
        <div style="text-align: center; color: white;">
          <h1 style="font-size: 3em; margin-bottom: 0.5em;">Hello World!</h1>
          <p style="font-size: 1.2em;">Running on AWS ECS Fargate</p>
          <p style="font-size: 0.9em; opacity: 0.8;">Container Instance: ${process.env.HOSTNAME || 'unknown'}</p>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});