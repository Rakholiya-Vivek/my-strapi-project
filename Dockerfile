
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package.json and package-lock.json first
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the project
COPY . .

# Expose Strapi default port
EXPOSE 1337

# Run Strapi in development mode
CMD ["npm", "run", "develop"]
