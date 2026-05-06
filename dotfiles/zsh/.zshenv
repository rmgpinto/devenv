export LINEAR_API_KEY=$(security find-generic-password -a "${USER}" -s linear-api-key -w 2>/dev/null)
