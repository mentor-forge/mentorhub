FROM nginx:stable-alpine

LABEL org.opencontainers.image.source="https://github.com/mentor-forge/mentorhub"

# Copy the welcome page
COPY index.html /usr/share/nginx/html/index.html
COPY login.html /usr/share/nginx/html/login.html
COPY welcome-auth.js /usr/share/nginx/html/welcome-auth.js
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]