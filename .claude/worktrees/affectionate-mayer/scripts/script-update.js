/**
 * AHK v2 Script Update Function
 *
 * This module handles fetching, updating, and storing AHK v2 scripts
 * from various sources including GitHub repositories and the local manifest.
 *
 * Works with both browser environments and Node.js build processes.
 */

class ScriptUpdateManager {
    constructor(options = {}) {
        this.config = {
            manifestPath: options.manifestPath || 'scripts/ahk-scripts.json',
            cacheKey: options.cacheKey || 'ahk_scripts_cache',
            cacheTTL: options.cacheTTL || 300000, // 5 minutes
            githubApiBase: options.githubApiBase || 'https://api.github.com',
            searchQuery: options.searchQuery || 'autohotkey v2 language:AutoHotkey',
            maxResults: options.maxResults || 50,
            enableGitHubFetch: options.enableGitHubFetch !== false,
            ...options
        };

        this.scripts = [];
        this.lastUpdate = null;
        this.updateCallbacks = [];
    }

    /**
     * Initialize the update manager and load scripts
     */
    async init() {
        await this.loadFromManifest();
        this.loadFromCache();
        return this;
    }

    /**
     * Load scripts from the local manifest file
     */
    async loadFromManifest() {
        try {
            const response = await fetch(this.config.manifestPath);
            if (!response.ok) {
                throw new Error(`Failed to load manifest: ${response.status}`);
            }

            const manifest = await response.json();
            this.scripts = manifest.scripts || [];
            this.lastUpdate = manifest.lastUpdated;

            console.log(`Loaded ${this.scripts.length} scripts from manifest`);
            return true;
        } catch (error) {
            console.error('Error loading manifest:', error);
            return false;
        }
    }

    /**
     * Load cached scripts from localStorage
     */
    loadFromCache() {
        if (typeof localStorage === 'undefined') return false;

        try {
            const cached = localStorage.getItem(this.config.cacheKey);
            if (!cached) return false;

            const { scripts, timestamp } = JSON.parse(cached);
            const age = Date.now() - timestamp;

            if (age < this.config.cacheTTL) {
                // Merge cached scripts with manifest scripts
                this.mergeScripts(scripts);
                console.log('Loaded scripts from cache');
                return true;
            }
        } catch (error) {
            console.error('Error loading from cache:', error);
        }
        return false;
    }

    /**
     * Save scripts to localStorage cache
     */
    saveToCache() {
        if (typeof localStorage === 'undefined') return;

        try {
            const cacheData = {
                scripts: this.scripts,
                timestamp: Date.now()
            };
            localStorage.setItem(this.config.cacheKey, JSON.stringify(cacheData));
        } catch (error) {
            console.error('Error saving to cache:', error);
        }
    }

    /**
     * Fetch latest AHK v2 repositories from GitHub
     */
    async fetchFromGitHub() {
        if (!this.config.enableGitHubFetch) return [];

        const query = encodeURIComponent(this.config.searchQuery);
        const url = `${this.config.githubApiBase}/search/repositories?q=${query}&sort=updated&per_page=${this.config.maxResults}`;

        try {
            const response = await fetch(url, {
                headers: {
                    'Accept': 'application/vnd.github.v3+json',
                    'User-Agent': 'AHKv2-LLMs-ScriptUpdater'
                }
            });

            if (response.status === 403) {
                console.warn('GitHub API rate limit reached');
                return [];
            }

            if (!response.ok) {
                throw new Error(`GitHub API error: ${response.status}`);
            }

            const data = await response.json();
            return this.parseGitHubRepos(data.items || []);
        } catch (error) {
            console.error('Error fetching from GitHub:', error);
            return [];
        }
    }

    /**
     * Parse GitHub repository data into script format
     */
    parseGitHubRepos(repos) {
        return repos.map(repo => ({
            id: `github-${repo.id}`,
            title: repo.name,
            category: 'GitHub Repository',
            description: repo.description || 'No description available',
            tags: ['github', 'repository', ...(repo.topics || [])],
            difficulty: 'varies',
            dateAdded: repo.created_at,
            lastModified: repo.updated_at,
            source: 'github',
            url: repo.html_url,
            stars: repo.stargazers_count,
            owner: repo.owner.login,
            code: this.generateRepoCodeBlock(repo)
        }));
    }

    /**
     * Generate a code block for a GitHub repository
     */
    generateRepoCodeBlock(repo) {
        return `\`\`\`cpp
; Repository: ${repo.full_name}
; URL: ${repo.html_url}
; Stars: ${repo.stargazers_count}
; Last Updated: ${new Date(repo.updated_at).toLocaleDateString()}
;
; Description: ${repo.description || 'No description'}
;
; To use this repository:
; 1. Clone: git clone ${repo.clone_url}
; 2. Or download ZIP from GitHub
; 3. Include the main script in your project
;
#Requires AutoHotkey v2.0

; Example usage pattern for ${repo.name}:
#Include <${repo.name}>

; Initialize and use the library
; (Refer to repository README for specific instructions)
\`\`\``;
    }

    /**
     * Merge new scripts with existing scripts
     */
    mergeScripts(newScripts) {
        const existingIds = new Set(this.scripts.map(s => s.id));

        for (const script of newScripts) {
            if (!existingIds.has(script.id)) {
                this.scripts.push(script);
                existingIds.add(script.id);
            } else {
                // Update existing script if newer
                const index = this.scripts.findIndex(s => s.id === script.id);
                if (index >= 0 && script.lastModified > this.scripts[index].lastModified) {
                    this.scripts[index] = script;
                }
            }
        }
    }

    /**
     * Perform a full update from all sources
     */
    async update() {
        console.log('Starting script update...');

        // Fetch from GitHub
        const githubScripts = await this.fetchFromGitHub();
        if (githubScripts.length > 0) {
            this.mergeScripts(githubScripts);
        }

        // Update timestamp
        this.lastUpdate = new Date().toISOString();

        // Save to cache
        this.saveToCache();

        // Notify callbacks
        this.notifyUpdate();

        console.log(`Update complete. Total scripts: ${this.scripts.length}`);
        return this.scripts;
    }

    /**
     * Register a callback for update events
     */
    onUpdate(callback) {
        this.updateCallbacks.push(callback);
    }

    /**
     * Notify all registered callbacks
     */
    notifyUpdate() {
        for (const callback of this.updateCallbacks) {
            try {
                callback(this.scripts, this.lastUpdate);
            } catch (error) {
                console.error('Error in update callback:', error);
            }
        }
    }

    /**
     * Get scripts filtered by category
     */
    getByCategory(category) {
        return this.scripts.filter(s => s.category === category);
    }

    /**
     * Get scripts filtered by tag
     */
    getByTag(tag) {
        return this.scripts.filter(s => s.tags && s.tags.includes(tag));
    }

    /**
     * Get scripts filtered by difficulty
     */
    getByDifficulty(difficulty) {
        return this.scripts.filter(s => s.difficulty === difficulty);
    }

    /**
     * Search scripts by query
     */
    search(query) {
        const lowerQuery = query.toLowerCase();
        return this.scripts.filter(s =>
            s.title.toLowerCase().includes(lowerQuery) ||
            s.description.toLowerCase().includes(lowerQuery) ||
            (s.tags && s.tags.some(t => t.toLowerCase().includes(lowerQuery)))
        );
    }

    /**
     * Get all unique categories
     */
    getCategories() {
        return [...new Set(this.scripts.map(s => s.category))];
    }

    /**
     * Get all unique tags
     */
    getAllTags() {
        const tags = new Set();
        for (const script of this.scripts) {
            if (script.tags) {
                script.tags.forEach(t => tags.add(t));
            }
        }
        return [...tags].sort();
    }

    /**
     * Get script by ID
     */
    getById(id) {
        return this.scripts.find(s => s.id === id);
    }

    /**
     * Get recent scripts (sorted by lastModified)
     */
    getRecent(limit = 10) {
        return [...this.scripts]
            .sort((a, b) => new Date(b.lastModified) - new Date(a.lastModified))
            .slice(0, limit);
    }

    /**
     * Get statistics about the script collection
     */
    getStats() {
        const categories = {};
        const difficulties = {};
        const tags = {};

        for (const script of this.scripts) {
            categories[script.category] = (categories[script.category] || 0) + 1;
            difficulties[script.difficulty] = (difficulties[script.difficulty] || 0) + 1;

            if (script.tags) {
                for (const tag of script.tags) {
                    tags[tag] = (tags[tag] || 0) + 1;
                }
            }
        }

        return {
            totalScripts: this.scripts.length,
            lastUpdated: this.lastUpdate,
            categories,
            difficulties,
            topTags: Object.entries(tags)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10)
                .map(([tag, count]) => ({ tag, count }))
        };
    }

    /**
     * Export scripts to JSON format
     */
    exportToJSON() {
        return JSON.stringify({
            version: '1.0.0',
            lastUpdated: this.lastUpdate,
            totalScripts: this.scripts.length,
            scripts: this.scripts
        }, null, 2);
    }
}

/**
 * Script Feed UI Component
 * Renders scripts in a container element
 */
class ScriptFeedUI {
    constructor(containerId, options = {}) {
        this.container = document.getElementById(containerId);
        this.options = {
            showCode: options.showCode !== false,
            showTags: options.showTags !== false,
            itemsPerPage: options.itemsPerPage || 10,
            ...options
        };

        this.manager = null;
        this.currentPage = 1;
        this.currentFilter = null;
    }

    /**
     * Initialize with a ScriptUpdateManager
     */
    async init(manager) {
        this.manager = manager;
        this.manager.onUpdate(() => this.render());
        await this.manager.init();
        this.render();
        return this;
    }

    /**
     * Render the script feed
     */
    render() {
        if (!this.container || !this.manager) return;

        const scripts = this.getFilteredScripts();
        const start = (this.currentPage - 1) * this.options.itemsPerPage;
        const pageScripts = scripts.slice(start, start + this.options.itemsPerPage);

        this.container.innerHTML = `
            <div class="script-feed">
                <div class="script-feed-header">
                    <h3>AHK v2 Script Collection</h3>
                    <span class="script-count">${scripts.length} scripts</span>
                </div>
                <div class="script-feed-filters">
                    ${this.renderFilters()}
                </div>
                <div class="script-feed-list">
                    ${pageScripts.map(s => this.renderScript(s)).join('')}
                </div>
                ${this.renderPagination(scripts.length)}
            </div>
        `;

        this.attachEventListeners();
    }

    /**
     * Get scripts based on current filter
     */
    getFilteredScripts() {
        if (!this.currentFilter) {
            return this.manager.scripts;
        }

        const { type, value } = this.currentFilter;
        switch (type) {
            case 'category':
                return this.manager.getByCategory(value);
            case 'tag':
                return this.manager.getByTag(value);
            case 'difficulty':
                return this.manager.getByDifficulty(value);
            case 'search':
                return this.manager.search(value);
            default:
                return this.manager.scripts;
        }
    }

    /**
     * Render filter controls
     */
    renderFilters() {
        const categories = this.manager.getCategories();
        return `
            <select class="filter-select" data-filter="category">
                <option value="">All Categories</option>
                ${categories.map(c => `<option value="${c}">${c}</option>`).join('')}
            </select>
            <select class="filter-select" data-filter="difficulty">
                <option value="">All Levels</option>
                <option value="beginner">Beginner</option>
                <option value="intermediate">Intermediate</option>
                <option value="advanced">Advanced</option>
            </select>
            <input type="text" class="filter-search" placeholder="Search scripts..." />
            <button class="refresh-btn" title="Refresh">↻</button>
        `;
    }

    /**
     * Render a single script card
     */
    renderScript(script) {
        const tagsHtml = this.options.showTags && script.tags
            ? `<div class="script-tags">${script.tags.slice(0, 4).map(t =>
                `<span class="tag">${this.escapeHtml(t)}</span>`).join('')}</div>`
            : '';

        const difficultyClass = `difficulty-${script.difficulty}`;

        return `
            <div class="script-card" data-id="${script.id}">
                <div class="script-header">
                    <h4 class="script-title">${this.escapeHtml(script.title)}</h4>
                    <span class="script-difficulty ${difficultyClass}">${script.difficulty}</span>
                </div>
                <p class="script-description">${this.escapeHtml(script.description)}</p>
                <div class="script-meta">
                    <span class="script-category">${this.escapeHtml(script.category)}</span>
                    <span class="script-date">${this.formatDate(script.lastModified)}</span>
                </div>
                ${tagsHtml}
                ${this.options.showCode ? `<button class="view-code-btn">View Code</button>` : ''}
            </div>
        `;
    }

    /**
     * Render pagination controls
     */
    renderPagination(totalItems) {
        const totalPages = Math.ceil(totalItems / this.options.itemsPerPage);
        if (totalPages <= 1) return '';

        return `
            <div class="script-pagination">
                <button class="page-btn prev" ${this.currentPage === 1 ? 'disabled' : ''}>← Prev</button>
                <span class="page-info">Page ${this.currentPage} of ${totalPages}</span>
                <button class="page-btn next" ${this.currentPage === totalPages ? 'disabled' : ''}>Next →</button>
            </div>
        `;
    }

    /**
     * Attach event listeners to rendered elements
     */
    attachEventListeners() {
        // Filter selects
        this.container.querySelectorAll('.filter-select').forEach(select => {
            select.addEventListener('change', (e) => {
                const filterType = e.target.dataset.filter;
                const value = e.target.value;
                this.currentFilter = value ? { type: filterType, value } : null;
                this.currentPage = 1;
                this.render();
            });
        });

        // Search input
        const searchInput = this.container.querySelector('.filter-search');
        if (searchInput) {
            let timeout;
            searchInput.addEventListener('input', (e) => {
                clearTimeout(timeout);
                timeout = setTimeout(() => {
                    const value = e.target.value.trim();
                    this.currentFilter = value ? { type: 'search', value } : null;
                    this.currentPage = 1;
                    this.render();
                }, 300);
            });
        }

        // Refresh button
        const refreshBtn = this.container.querySelector('.refresh-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', async () => {
                refreshBtn.disabled = true;
                refreshBtn.textContent = '...';
                await this.manager.update();
                refreshBtn.disabled = false;
                refreshBtn.textContent = '↻';
            });
        }

        // Pagination
        const prevBtn = this.container.querySelector('.page-btn.prev');
        const nextBtn = this.container.querySelector('.page-btn.next');

        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                if (this.currentPage > 1) {
                    this.currentPage--;
                    this.render();
                }
            });
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                this.currentPage++;
                this.render();
            });
        }

        // View code buttons
        this.container.querySelectorAll('.view-code-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const card = e.target.closest('.script-card');
                const id = card.dataset.id;
                this.showCodeModal(id);
            });
        });
    }

    /**
     * Show code in a modal
     */
    showCodeModal(scriptId) {
        const script = this.manager.getById(scriptId);
        if (!script) return;

        // Remove existing modal
        const existing = document.querySelector('.code-modal');
        if (existing) existing.remove();

        const modal = document.createElement('div');
        modal.className = 'code-modal';
        modal.innerHTML = `
            <div class="code-modal-content">
                <div class="code-modal-header">
                    <h3>${this.escapeHtml(script.title)}</h3>
                    <button class="close-modal">×</button>
                </div>
                <div class="code-modal-body">
                    <pre><code>${this.escapeHtml(script.code.replace(/```cpp\n?|```/g, ''))}</code></pre>
                </div>
                <div class="code-modal-footer">
                    <button class="copy-code-btn">Copy Code</button>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Close modal
        modal.querySelector('.close-modal').addEventListener('click', () => modal.remove());
        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.remove();
        });

        // Copy code
        modal.querySelector('.copy-code-btn').addEventListener('click', () => {
            const code = script.code.replace(/```cpp\n?|```/g, '');
            navigator.clipboard.writeText(code).then(() => {
                const btn = modal.querySelector('.copy-code-btn');
                btn.textContent = 'Copied!';
                setTimeout(() => btn.textContent = 'Copy Code', 2000);
            });
        });
    }

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(str) {
        if (!str) return '';
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }

    /**
     * Format date for display
     */
    formatDate(dateStr) {
        const date = new Date(dateStr);
        const now = new Date();
        const diffMs = now - date;
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

        if (diffDays === 0) return 'Today';
        if (diffDays === 1) return 'Yesterday';
        if (diffDays < 7) return `${diffDays} days ago`;
        if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
        if (diffDays < 365) return `${Math.floor(diffDays / 30)} months ago`;
        return date.toLocaleDateString();
    }
}

// Export for use in different environments
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ScriptUpdateManager, ScriptFeedUI };
} else if (typeof window !== 'undefined') {
    window.ScriptUpdateManager = ScriptUpdateManager;
    window.ScriptFeedUI = ScriptFeedUI;
}
