.PHONY: start stop test build

start:
	cd backend && node server.js &
	cd frontend && npm run dev &

stop:
	lsof -ti:8000 | xargs kill -9 2>/dev/null || true
	lsof -ti:3000 | xargs kill -9 2>/dev/null || true

test:
	pytest tests/test_api.py -v

build:
	docker compose -f infra/docker-compose.yml build
