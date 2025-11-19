# AHKv2_LLMs
LLM Performance in AHK v2 Coding Tasks

## Visit the Site
🌐 **[View the full site here](https://012090120901209.github.io/AHKv2_LLMs)**

This project explores using AI assistants like GitHub Copilot, ChatGPT, and Claude for AutoHotkey v2 development.

## Features

### Latest AHK v2 Repos Feed
The site includes a live feed of the latest AutoHotkey v2 repositories from GitHub, displayed in the right sidebar. This feature:
- Fetches the most recently updated AHK v2 repositories
- Shows repository name, description, stars, and last update time
- Refreshes automatically when you visit the page
- Works seamlessly when the site is hosted on GitHub Pages

### Blog Posts
Read about AutoHotkey v2 workflows, tips, and integration with LLMs and coding agents.

## Preview the Site Locally

To confirm that the latest homepage layout and blog posts are published, build the Jekyll site and view it in a
browser:

1. Install dependencies: `bundle install`
2. Build & serve: `bundle exec jekyll serve`
3. Open `http://localhost:4000` and check the "Latest site update" card on the homepage—the timestamp will reflect
   the newest post, so you can confirm the content you just added is live.

If you prefer a production build without starting a server, run `bundle exec jekyll build` and inspect the generated
files in `_site/`.

**Note:** The GitHub repos feed requires internet access and may not work in all local development environments due to CORS restrictions. The feature works best when deployed to GitHub Pages.