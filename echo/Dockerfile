FROM python:3-alpine as base

ENV PYTHONFAULTHANDLER=1
ENV PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir --upgrade pip

WORKDIR /app

# Export dependencies from Poetry
FROM base as export-dependencies

RUN pip install --no-cache-dir poetry

# Export dependencies to requirements.txt format
COPY pyproject.toml poetry.lock ./
RUN poetry export -f requirements.txt -o requirements.txt

FROM base as runtime

COPY --from=export-dependencies /app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY echo ./echo
COPY --chmod=755 entrypoint.sh ./

EXPOSE 5000/tcp
ENTRYPOINT [ "./entrypoint.sh" ]
