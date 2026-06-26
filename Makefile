COMPOSE = docker compose --env-file infra/.env -f infra/docker-compose.dev.yml

.PHONY: up down logs psql

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

psql:
	$(COMPOSE) exec postgres psql -U twende -d twende
