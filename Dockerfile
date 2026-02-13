# Use a minimal base image
FROM node:20-alpine

# Define working directory
WORKDIR /app

# Copy only dependency definitions first
# This allows Docker to cache npm install
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application source code
COPY . .

# Expose application port
EXPOSE 3000

# Define default command
CMD ["node", "server.js"]
