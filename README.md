# Life OS

> A personal AI memory system built with Rails, PostgreSQL/pgvector, Hotwire, and OpenAI.
> Capture personal knowledge, see today at a glance, and ask natural-language questions about your life.

## Overview
Life OS is a personal memory layer for storing and retrieving the kinds of information that are usually scattered across notes, plans, logs, and calendars.

Instead of digging through documents, you can build a system that helps answer questions like:
- What did I do today?
- When does Mom arrive?
- What are my favorite recipes?
- What groceries do I usually buy?

Right now, the app combines:
- a daily dashboard for viewing today's context
- personal documents such as daily logs, recipes, itineraries, groceries, project notes, and medical notes
- AI-generated summaries and grounded answers
- semantic search powered by PostgreSQL + pgvector
- sync from a single Google Calendar instance

The goal is to make personal information easier to revisit, search, and use in everyday life.

## Current Features
- Daily dashboard at `/`
- UI built with Rails, Hotwire, and Tailwind CSS
- Daily log tracking with AI-generated summaries
- Natural-language question answering over stored memory
- Semantic document ingestion with chunking and embeddings
- Google Calendar sync for one configured calendar
- Calendar event display for today's schedule

## What the App Looks Like Today
The current experience centers around the homepage dashboard.

From there you can:
- see a quick snapshot of your day
- view today's calendar events
- see whether a daily log exists for today
- see whether an AI summary is available
- trigger a calendar sync from the UI

This means the project is no longer just a backend memory experiment — it now has a usable interface for day-to-day interaction.

## How It Works
At a high level, Life OS works like this:
1. personal documents are stored in the app
2. document content is split into smaller chunks
3. embeddings are generated for semantic search
4. relevant information is retrieved when you ask a question
5. the AI responds using the retrieved context

Daily logs can also be summarized and cached, and Google Calendar events can be synced into the app for use on the dashboard.

## Types of Information It Stores
Life OS currently supports content such as:
- daily logs
- recipes
- groceries
- itineraries
- project notes
- medical notes
- calendar events synced from Google Calendar

## Current Limitations
- Calendar sync is currently limited to one configured Google Calendar instance
- The product is still centered on the dashboard and backend memory workflows
- Retrieval and routing are still evolving
- Broader memory intelligence features are still in progress

## Local Setup
### Prerequisites
- Ruby / Rails environment
- PostgreSQL with `pgvector` enabled
- OpenAI API key
- Google Calendar credentials if you want calendar sync

### Install and run
```bash
bundle install
bin/rails db:create db:migrate
bin/rails server
```

Open the app at `http://localhost:3000`.

## Environment Variables
Minimum required:
```bash
OPENAI_API_KEY=your_key
LLM_MODEL=gpt-4o-mini
```

For Google Calendar sync:
```bash
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
GOOGLE_REFRESH_TOKEN=your_refresh_token
```

To generate a refresh token locally:
```bash
ruby scripts/google_calendar_oauth.rb
```

## Status
Life OS currently includes:
- a working Rails application
- a dashboard UI
- semantic document ingestion and retrieval
- AI-generated daily log summaries
- Google Calendar sync for one configured calendar

## Vision
Life OS is meant to become a durable personal memory layer.

Not just note storage.
Not just search.
Not just chat.

A system that helps you understand what happened, what matters, and what is coming next.
