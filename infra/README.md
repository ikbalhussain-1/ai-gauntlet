# Infra

Docker Compose configuration to run the full stack locally with one command.

## Structure

- `docker-compose.yml` — defines backend and frontend services
- `nginx.conf` — serves the built React app on port 3000, proxies /api to backend

## Running the full stack

```bash
# From the project root
docker-compose -f infra/docker-compose.yml up --build
```

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API docs: http://localhost:8000/docs
