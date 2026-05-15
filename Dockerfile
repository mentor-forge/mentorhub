FROM nginx:stable-alpine

LABEL org.opencontainers.image.source="{{org.git_host}}/{{org.git_org}}/{{info.slug}}"

# Copy the welcome page
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
