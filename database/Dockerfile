FROM postgres:16-alpine

# Set default environment variables
ENV POSTGRES_DB=studentdb
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres123

# Copy initialization script
# Scripts in /docker-entrypoint-initdb.d/ run automatically
# on first container start (when the data volume is empty)
COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
