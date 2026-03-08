# Run/Restart nginx command for local testing.
alias rs="sed -e 's|##SERVER_PORT##|${HTTP_SERVER_PORT:-8000}|g' -e 's|##SERVER_BUILD_DIR##|${HTTP_SERVER_DIR:-/workspaces/docs/build/html}|g' /etc/nginx/templates/default.template > /etc/nginx/sites-available/default && service nginx restart"
