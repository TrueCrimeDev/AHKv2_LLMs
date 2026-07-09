#!/usr/bin/env node

/**
 * AHK v2 Scripts Build Script
 *
 * This script handles the build process for updating the AHK v2 script feed.
 * It fetches latest repositories from GitHub, updates the manifest, and
 * generates optimized output files.
 *
 * Usage:
 *   node scripts/build.js [options]
 *
 * Options:
 *   --fetch       Fetch new scripts from GitHub
 *   --validate    Validate existing scripts
 *   --stats       Show collection statistics
 *   --export      Export to different formats
 *   --help        Show help message
 *
 * Environment Variables:
 *   GITHUB_TOKEN          GitHub API token for higher rate limits
 *   AHK_FEED_LIMIT        Maximum number of repos to fetch (default: 50)
 *   AHK_SEARCH_QUERY      Custom search query for GitHub
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Configuration
const CONFIG = {
    manifestPath: path.join(__dirname, 'ahk-scripts.json'),
    outputDir: path.join(__dirname, '..', 'dist'),
    githubApiBase: 'api.github.com',
    searchQuery: process.env.AHK_SEARCH_QUERY || 'autohotkey v2 language:AutoHotkey',
    feedLimit: parseInt(process.env.AHK_FEED_LIMIT, 10) || 50,
    githubToken: process.env.GITHUB_TOKEN || null
};

// ANSI color codes for terminal output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    red: '\x1b[31m',
    cyan: '\x1b[36m',
    dim: '\x1b[2m'
};

/**
 * Log utility with colors
 */
function log(message, type = 'info') {
    const prefix = {
        info: `${colors.cyan}[INFO]${colors.reset}`,
        success: `${colors.green}[SUCCESS]${colors.reset}`,
        warn: `${colors.yellow}[WARN]${colors.reset}`,
        error: `${colors.red}[ERROR]${colors.reset}`
    };
    console.log(`${prefix[type] || prefix.info} ${message}`);
}

/**
 * Make an HTTPS request
 */
function httpsRequest(options, postData = null) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve({
                        status: res.statusCode,
                        headers: res.headers,
                        data: JSON.parse(data)
                    });
                } catch (e) {
                    resolve({
                        status: res.statusCode,
                        headers: res.headers,
                        data: data
                    });
                }
            });
        });

        req.on('error', reject);
        if (postData) req.write(postData);
        req.end();
    });
}

/**
 * Fetch repositories from GitHub API
 */
async function fetchGitHubRepos() {
    log('Fetching AHK v2 repositories from GitHub...');

    const query = encodeURIComponent(CONFIG.searchQuery);
    const options = {
        hostname: CONFIG.githubApiBase,
        path: `/search/repositories?q=${query}&sort=updated&per_page=${CONFIG.feedLimit}`,
        method: 'GET',
        headers: {
            'User-Agent': 'AHKv2-LLMs-BuildScript',
            'Accept': 'application/vnd.github.v3+json'
        }
    };

    if (CONFIG.githubToken) {
        options.headers['Authorization'] = `token ${CONFIG.githubToken}`;
        log('Using GitHub token for authentication', 'info');
    }

    try {
        const response = await httpsRequest(options);

        if (response.status === 403) {
            log('GitHub API rate limit reached. Try again later or use a token.', 'warn');
            return [];
        }

        if (response.status !== 200) {
            log(`GitHub API returned status ${response.status}`, 'error');
            return [];
        }

        const repos = response.data.items || [];
        log(`Fetched ${repos.length} repositories`, 'success');

        return repos.map(repo => ({
            id: `github-${repo.id}`,
            title: repo.name,
            category: 'GitHub Repository',
            description: repo.description || 'No description available',
            tags: ['github', 'repository', ...(repo.topics || [])].slice(0, 8),
            difficulty: 'varies',
            dateAdded: repo.created_at,
            lastModified: repo.updated_at,
            source: 'github',
            url: repo.html_url,
            stars: repo.stargazers_count,
            forks: repo.forks_count,
            owner: repo.owner.login,
            code: generateRepoCodeBlock(repo)
        }));
    } catch (error) {
        log(`Error fetching from GitHub: ${error.message}`, 'error');
        return [];
    }
}

/**
 * Generate a code block for a repository
 */
function generateRepoCodeBlock(repo) {
    return `\`\`\`cpp
; ============================================
; Repository: ${repo.full_name}
; ============================================
; URL: ${repo.html_url}
; Stars: ${repo.stargazers_count} | Forks: ${repo.forks_count}
; Last Updated: ${new Date(repo.updated_at).toLocaleDateString()}
; License: ${repo.license ? repo.license.name : 'Not specified'}
;
; Description:
; ${(repo.description || 'No description available').replace(/\n/g, '\n; ')}
;
; ============================================
; INSTALLATION
; ============================================
; Option 1: Clone the repository
;   git clone ${repo.clone_url}
;
; Option 2: Download ZIP
;   ${repo.html_url}/archive/refs/heads/${repo.default_branch || 'main'}.zip
;
; ============================================
; USAGE EXAMPLE
; ============================================
#Requires AutoHotkey v2.0

; Include the library (adjust path as needed)
; #Include <${repo.name}>

; Example initialization
class ${toPascalCase(repo.name)}Example {
    __New() {
        ; Initialize the library
        ; Refer to repository README for specific usage
        MsgBox("${repo.name} loaded successfully!")
    }
}

; Uncomment to run:
; app := ${toPascalCase(repo.name)}Example()
\`\`\``;
}

/**
 * Convert string to PascalCase
 */
function toPascalCase(str) {
    return str
        .replace(/[-_]/g, ' ')
        .split(' ')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join('');
}

/**
 * Load the existing manifest
 */
function loadManifest() {
    try {
        if (fs.existsSync(CONFIG.manifestPath)) {
            const content = fs.readFileSync(CONFIG.manifestPath, 'utf8');
            return JSON.parse(content);
        }
    } catch (error) {
        log(`Error loading manifest: ${error.message}`, 'error');
    }
    return { version: '1.0.0', scripts: [], categories: [] };
}

/**
 * Save the manifest
 */
function saveManifest(manifest) {
    try {
        manifest.lastUpdated = new Date().toISOString();
        manifest.totalScripts = manifest.scripts.length;

        const content = JSON.stringify(manifest, null, 2);
        fs.writeFileSync(CONFIG.manifestPath, content, 'utf8');
        log(`Manifest saved with ${manifest.scripts.length} scripts`, 'success');
        return true;
    } catch (error) {
        log(`Error saving manifest: ${error.message}`, 'error');
        return false;
    }
}

/**
 * Merge new scripts into manifest
 */
function mergeScripts(manifest, newScripts) {
    const existingIds = new Set(manifest.scripts.map(s => s.id));
    let added = 0;
    let updated = 0;

    for (const script of newScripts) {
        if (!existingIds.has(script.id)) {
            manifest.scripts.push(script);
            existingIds.add(script.id);
            added++;
        } else {
            const index = manifest.scripts.findIndex(s => s.id === script.id);
            if (index >= 0) {
                const existing = manifest.scripts[index];
                if (new Date(script.lastModified) > new Date(existing.lastModified)) {
                    manifest.scripts[index] = script;
                    updated++;
                }
            }
        }
    }

    log(`Added ${added} new scripts, updated ${updated} existing`, 'info');
    return manifest;
}

/**
 * Validate all scripts in the manifest
 */
function validateScripts(manifest) {
    log('Validating scripts...');

    const errors = [];
    const requiredFields = ['id', 'title', 'category', 'description'];

    for (const script of manifest.scripts) {
        for (const field of requiredFields) {
            if (!script[field]) {
                errors.push(`Script "${script.id || 'unknown'}": missing ${field}`);
            }
        }

        if (script.code && !script.code.includes('```cpp')) {
            errors.push(`Script "${script.id}": code block should use cpp format`);
        }
    }

    if (errors.length > 0) {
        log(`Found ${errors.length} validation errors:`, 'warn');
        errors.forEach(e => console.log(`  - ${e}`));
        return false;
    }

    log('All scripts validated successfully', 'success');
    return true;
}

/**
 * Generate statistics about the collection
 */
function generateStats(manifest) {
    const categories = {};
    const difficulties = {};
    const sources = {};
    const tagCounts = {};

    for (const script of manifest.scripts) {
        categories[script.category] = (categories[script.category] || 0) + 1;
        difficulties[script.difficulty] = (difficulties[script.difficulty] || 0) + 1;
        sources[script.source || 'local'] = (sources[script.source || 'local'] || 0) + 1;

        if (script.tags) {
            for (const tag of script.tags) {
                tagCounts[tag] = (tagCounts[tag] || 0) + 1;
            }
        }
    }

    console.log('\n' + colors.bright + '=== Script Collection Statistics ===' + colors.reset);
    console.log(`\nTotal Scripts: ${colors.cyan}${manifest.scripts.length}${colors.reset}`);
    console.log(`Last Updated: ${colors.dim}${manifest.lastUpdated || 'Never'}${colors.reset}`);

    console.log('\n' + colors.bright + 'By Category:' + colors.reset);
    Object.entries(categories)
        .sort((a, b) => b[1] - a[1])
        .forEach(([cat, count]) => {
            console.log(`  ${cat}: ${colors.green}${count}${colors.reset}`);
        });

    console.log('\n' + colors.bright + 'By Difficulty:' + colors.reset);
    Object.entries(difficulties)
        .forEach(([diff, count]) => {
            console.log(`  ${diff}: ${colors.yellow}${count}${colors.reset}`);
        });

    console.log('\n' + colors.bright + 'By Source:' + colors.reset);
    Object.entries(sources)
        .forEach(([src, count]) => {
            console.log(`  ${src}: ${colors.cyan}${count}${colors.reset}`);
        });

    console.log('\n' + colors.bright + 'Top 10 Tags:' + colors.reset);
    Object.entries(tagCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10)
        .forEach(([tag, count]) => {
            console.log(`  ${tag}: ${count}`);
        });

    console.log('');
}

/**
 * Export manifest to different formats
 */
function exportFormats(manifest) {
    log('Exporting to additional formats...');

    // Ensure output directory exists
    if (!fs.existsSync(CONFIG.outputDir)) {
        fs.mkdirSync(CONFIG.outputDir, { recursive: true });
    }

    // Export minified JSON
    const minified = JSON.stringify(manifest);
    fs.writeFileSync(
        path.join(CONFIG.outputDir, 'ahk-scripts.min.json'),
        minified,
        'utf8'
    );

    // Export scripts only (no metadata)
    const scriptsOnly = manifest.scripts.map(s => ({
        id: s.id,
        title: s.title,
        category: s.category,
        description: s.description,
        difficulty: s.difficulty,
        tags: s.tags
    }));
    fs.writeFileSync(
        path.join(CONFIG.outputDir, 'ahk-scripts-index.json'),
        JSON.stringify(scriptsOnly, null, 2),
        'utf8'
    );

    // Export categories list
    const categories = [...new Set(manifest.scripts.map(s => s.category))];
    fs.writeFileSync(
        path.join(CONFIG.outputDir, 'categories.json'),
        JSON.stringify(categories, null, 2),
        'utf8'
    );

    log(`Exported files to ${CONFIG.outputDir}`, 'success');
}

/**
 * Show help message
 */
function showHelp() {
    console.log(`
${colors.bright}AHK v2 Scripts Build Tool${colors.reset}

Usage: node scripts/build.js [options]

Options:
  --fetch       Fetch new scripts from GitHub
  --validate    Validate existing scripts
  --stats       Show collection statistics
  --export      Export to different formats
  --all         Run all tasks (fetch, validate, export)
  --help        Show this help message

Environment Variables:
  GITHUB_TOKEN       GitHub personal access token (increases rate limit)
  AHK_FEED_LIMIT     Maximum repos to fetch (default: 50)
  AHK_SEARCH_QUERY   Custom search query for GitHub

Examples:
  node scripts/build.js --fetch
  GITHUB_TOKEN=xxx node scripts/build.js --all
  AHK_FEED_LIMIT=100 node scripts/build.js --fetch --stats
`);
}

/**
 * Main build function
 */
async function main() {
    const args = process.argv.slice(2);

    if (args.includes('--help') || args.length === 0) {
        showHelp();
        return;
    }

    console.log(`\n${colors.bright}AHK v2 Scripts Build Process${colors.reset}\n`);
    console.log(`${colors.dim}Started: ${new Date().toISOString()}${colors.reset}\n`);

    let manifest = loadManifest();

    // Fetch from GitHub
    if (args.includes('--fetch') || args.includes('--all')) {
        const newScripts = await fetchGitHubRepos();
        if (newScripts.length > 0) {
            manifest = mergeScripts(manifest, newScripts);
            saveManifest(manifest);
        }
    }

    // Validate scripts
    if (args.includes('--validate') || args.includes('--all')) {
        validateScripts(manifest);
    }

    // Show statistics
    if (args.includes('--stats') || args.includes('--all')) {
        generateStats(manifest);
    }

    // Export formats
    if (args.includes('--export') || args.includes('--all')) {
        exportFormats(manifest);
    }

    console.log(`${colors.dim}Completed: ${new Date().toISOString()}${colors.reset}\n`);
}

// Run the build
main().catch(error => {
    log(`Build failed: ${error.message}`, 'error');
    process.exit(1);
});
