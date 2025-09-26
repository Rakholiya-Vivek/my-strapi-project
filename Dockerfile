
# FROM node:18-alpine

# # Set working directory inside container
# WORKDIR /app

# # Copy package.json and package-lock.json first
# COPY package*.json ./

# # Install dependencies
# RUN npm install

# # Copy the rest of the project
# COPY . .

# # Expose Strapi default port
# EXPOSE 1337

# # Run Strapi in development mode
# CMD ["npm", "run", "develop"]



# for postgre db

# FROM node:20-alpine

# WORKDIR /srv/app

# COPY package*.json ./

# RUN npm install

# COPY . .

# EXPOSE 1337

# CMD ["npm", "run", "develop"]


# Base image
FROM node:20-alpine

# Set working directory
WORKDIR /srv/app

# Copy package files first (for caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the project
COPY . .

# Build the Strapi admin panel
RUN npm run build

# Expose port
EXPOSE 1337

# Start Strapi in production
CMD ["npm", "run", "start"]
