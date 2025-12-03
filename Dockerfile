# Sample Dockerfile for a simple web application
FROM nginx:alpine

# Copy custom nginx config (optional)
# COPY nginx.conf /etc/nginx/nginx.conf

# Copy static content
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
