# Latest AHK v2 Repos Feed

## Overview

The Latest AHK v2 Repos Feed feature displays the most recently updated AutoHotkey v2 repositories from GitHub directly on the homepage.

## How It Works

### Client-Side Implementation

The feature is implemented entirely client-side using vanilla JavaScript:

1. **repos-feed.js** - Main module that handles:
   - Fetching repositories from GitHub's REST API
   - Parsing and displaying repository data
   - Error handling for network issues
   - Formatting dates and numbers for display

2. **index.html** - Integration point:
   - Includes the repos-feed.js script
   - Contains the container div for the feed
   - Initializes the feed on page load

3. **style.css** - Styling:
   - Dark theme matching the rest of the site
   - Responsive layout
   - Hover effects for repository cards

### GitHub API Integration

The feature uses GitHub's public search API:

```javascript
GET https://api.github.com/search/repositories
  ?q=autohotkey+v2+OR+"autohotkey 2"+language:AutoHotkey
  &sort=updated
  &order=desc
  &per_page=5
```

Query parameters:
- Searches for "autohotkey v2" or "autohotkey 2" 
- Filters by AutoHotkey language
- Sorts by recently updated
- Returns top 5 results

### Data Displayed

For each repository, the feed shows:
- Repository full name (owner/repo)
- Star count (formatted: 1.5k, 1.2m, etc.)
- Description (truncated to 2 lines)
- Primary language
- Last update time (relative: "2 days ago", "3 weeks ago", etc.)

### Error Handling

The implementation includes graceful error handling for:
- Network failures (CORS, blocked requests)
- API rate limiting
- Missing or malformed data
- Local development environments

When errors occur, a user-friendly message is displayed explaining that the feature works best when hosted on GitHub Pages.

## Usage

### Basic Usage

The feed is automatically initialized when the homepage loads. No user interaction is required.

### Customization

To modify the number of repositories displayed, update the `limit` option:

```javascript
const feed = new ReposFeed('repos-feed-container', { limit: 10 });
```

### Adding to Other Pages

To add the feed to another page:

1. Include the script:
   ```html
   <script src="repos-feed.js" defer></script>
   ```

2. Add a container div:
   ```html
   <div id="repos-feed-container"></div>
   ```

3. Initialize the feed:
   ```javascript
   document.addEventListener('DOMContentLoaded', function() {
     const feed = new ReposFeed('repos-feed-container', { limit: 5 });
     feed.fetchRepos();
   });
   ```

## Limitations

- **Rate Limiting**: GitHub's API has rate limits (60 requests/hour for unauthenticated requests)
- **CORS**: May not work in all local development environments
- **Client-Side Only**: Requires JavaScript enabled in the browser
- **No Caching**: Fetches fresh data on each page load

## Security

The implementation includes several security measures:

- **XSS Prevention**: All user-generated content is escaped using `escapeHtml()`
- **No Authentication**: Uses public API only, no tokens stored
- **No Personal Data**: Only displays public repository information
- **Safe URLs**: All GitHub links use HTTPS

## Browser Compatibility

The feature uses modern JavaScript features and requires:
- Fetch API support
- ES6+ syntax (arrow functions, template literals, async/await)
- Modern CSS (flexbox, CSS variables)

Compatible with all modern browsers (Chrome, Firefox, Safari, Edge).
