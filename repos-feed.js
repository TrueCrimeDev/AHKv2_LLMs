// repos-feed.js - Fetch and display latest AHK v2 repositories from GitHub

class ReposFeed {
  constructor(containerId, options = {}) {
    this.container = document.getElementById(containerId);
    this.limit = options.limit || 10;
    this.loading = false;
  }

  /**
   * Fetch repositories from GitHub API
   * Searches for repositories with "autohotkey" topic or language
   * Sorted by recently updated
   */
  async fetchRepos() {
    try {
      this.loading = true;
      this.showLoading();

      // Search for AutoHotkey v2 repositories
      // Using GitHub search API to find repos with autohotkey topic/language
      // Search for repos that mention "v2" or "autohotkey 2" in readme/description
      const query = encodeURIComponent('autohotkey v2 OR "autohotkey 2" language:AutoHotkey');
      const perPage = this.limit;
      const url = `https://api.github.com/search/repositories?q=${query}&sort=updated&order=desc&per_page=${perPage}`;

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AHKv2-LLMs-Site'
        }
      });

      if (!response.ok) {
        // If rate limited or other API error, show a helpful message
        if (response.status === 403) {
          throw new Error('GitHub API rate limit exceeded. Please try again later.');
        } else if (response.status === 404) {
          throw new Error('GitHub API endpoint not found.');
        } else {
          throw new Error(`GitHub API error: ${response.status}`);
        }
      }

      const data = await response.json();
      
      if (!data.items || data.items.length === 0) {
        this.container.innerHTML = '<p class="repos-empty">No repositories found. Check back later for updates!</p>';
        return;
      }
      
      this.displayRepos(data.items);
    } catch (error) {
      // Check if it's a network error (CORS, blocked, etc.)
      if (error.message.includes('Failed to fetch') || error.name === 'TypeError') {
        this.showError('Unable to load repositories. This feature requires an internet connection and may not work in all environments.');
      } else {
        this.showError(error.message);
      }
      console.error('Error fetching repos:', error);
    } finally {
      this.loading = false;
    }
  }

  /**
   * Display repositories in the container
   */
  displayRepos(repos) {
    if (!this.container) {
      console.error('Container element not found');
      return;
    }

    if (repos.length === 0) {
      this.container.innerHTML = '<p class="repos-empty">No repositories found.</p>';
      return;
    }

    const reposList = repos.map(repo => this.createRepoCard(repo)).join('');
    this.container.innerHTML = `<ul class="repos-list">${reposList}</ul>`;
  }

  /**
   * Create HTML for a single repository card
   */
  createRepoCard(repo) {
    const updatedDate = new Date(repo.updated_at);
    const formattedDate = this.formatDate(updatedDate);
    const stars = this.formatNumber(repo.stargazers_count);
    const description = repo.description 
      ? `<p class="repo-description">${this.escapeHtml(repo.description)}</p>` 
      : '';

    return `
      <li class="repo-item">
        <a href="${repo.html_url}" target="_blank" rel="noopener noreferrer" class="repo-link">
          <div class="repo-header">
            <h3 class="repo-name">${this.escapeHtml(repo.full_name)}</h3>
            <span class="repo-stars" title="${repo.stargazers_count} stars">⭐ ${stars}</span>
          </div>
          ${description}
          <div class="repo-meta">
            <span class="repo-language">${repo.language || 'AutoHotkey'}</span>
            <span class="repo-updated">Updated ${formattedDate}</span>
          </div>
        </a>
      </li>
    `;
  }

  /**
   * Format date to relative time or short date
   */
  formatDate(date) {
    const now = new Date();
    const diffMs = now - date;
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return 'today';
    } else if (diffDays === 1) {
      return 'yesterday';
    } else if (diffDays < 7) {
      return `${diffDays} days ago`;
    } else if (diffDays < 30) {
      const weeks = Math.floor(diffDays / 7);
      return `${weeks} week${weeks > 1 ? 's' : ''} ago`;
    } else if (diffDays < 365) {
      const months = Math.floor(diffDays / 30);
      return `${months} month${months > 1 ? 's' : ''} ago`;
    } else {
      return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    }
  }

  /**
   * Format large numbers with k/m suffixes
   */
  formatNumber(num) {
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + 'm';
    } else if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'k';
    }
    return num.toString();
  }

  /**
   * Escape HTML to prevent XSS
   */
  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * Show loading state
   */
  showLoading() {
    if (this.container) {
      this.container.innerHTML = '<p class="repos-loading">Loading repositories...</p>';
    }
  }

  /**
   * Show error state
   */
  showError(message) {
    if (this.container) {
      this.container.innerHTML = `
        <div class="repos-error">
          <p class="repos-error-text">${this.escapeHtml(message)}</p>
          <p class="repos-error-note">This feature works best when the site is hosted on GitHub Pages.</p>
        </div>
      `;
    }
  }
}

// Initialize the feed when DOM is ready
if (typeof window !== 'undefined') {
  window.ReposFeed = ReposFeed;
}
