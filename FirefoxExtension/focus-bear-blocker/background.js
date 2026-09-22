// ------------------------------------------------------------
// Focus Bear Blocker - background.js
// ------------------------------------------------------------

const MAC_PORT = 50502;  // Swift local HTTP server
const MANAGED_NAVIGATION_VERSION = 2;
const BLOCK_PAGE = "http://localhost:50501";

// Cache last URL to avoid duplicate blocking
let lastUrl = null;

// WebSocket state
let ws = null;
let wsConnected = false;

// ------------------------------------------------------------
// WebSocket Connection
// ------------------------------------------------------------
function connectWS() {
    console.log("[WS] Connecting to macOS…");

    try {
        ws = new WebSocket(`ws://127.0.0.1:${MAC_PORT}`);

        ws.onopen = () => {
            console.log("[WS] Connected");
            wsConnected = true;

        };

        ws.onerror = err => {
            console.error("[WS] Error:");
        };

        ws.onclose = () => {
            console.warn("[WS] Closed. Retrying…");
            wsConnected = false;

            // Retry after 2 seconds
            setTimeout(connectWS, 2000);
        };

        ws.onmessage = event => {
            try {
                const msg = JSON.parse(event.data);
                handleWSMessage(msg);
            } catch (e) {
                console.error("Invalid WS JSON:");
            }
        };
    } catch (e) {
        console.error("[WS] Connect exception:");
        setTimeout(connectWS, 2000);
    }
}

connectWS();

// start polling when extension starts
pollMacApp();
// ------------------------------------------------------------
// Handle WebSocket message from macOS app
// ------------------------------------------------------------
function handleWSMessage(msg) {
    if (!msg || typeof msg !== "object") {
        console.error("⚠ Invalid WS message:");
        return;
    }

    // Apply only to the exact observed window/tab and acknowledge whether navigation succeeded.
    if (msg.action === "managed_navigate" && typeof msg.url === "string" && typeof msg.expected_url === "string") {
        applyManagedNavigation(msg);
        return;
    }

    // macOS requests immediate blocking of a URL
    if (msg.action === "block_now" && msg.url) {
        console.log("⛔ macOS requested immediate block:");

        // Forward macOS parameters to block page
        const params = msg.params || {};

        // Force-block any currently open matching tabs
        forceBlockTabs(msg.url, params);

        return;
    }
	if (msg.action === "unblock_now" && msg.url) {
    console.log("✅ macOS requested unblock and open:");

    // Open the URL in the current active tab
    browser.tabs.query({active: true, currentWindow: true}, tabs => {
        if (tabs && tabs.length > 0) {
            const activeTab = tabs[0];
            browser.tabs.update(activeTab.id, {url: msg.url})
                .then(() => {
                    console.log("✅ Successfully opened unblocked URL:");
                })
                .catch(err => {
                    console.error("❌ Failed to open unblocked URL:");
                });
			} else {
				console.log("No active tab found, creating new tab");
				browser.tabs.create({url: msg.url});
			}
		});
		return;
	}

    console.warn("⚠ Unknown WS action:");
}

async function applyManagedNavigation(msg) {
    let applied = false;
    try {
        const tabs = await browser.tabs.query({ active: true, lastFocusedWindow: true });
        const tab = tabs[0];
        if (tab && tab.id === msg.tab_id && tab.windowId === msg.window_id && tab.url === msg.expected_url) {
            const current = await browser.tabs.get(tab.id);
            if (current.active && current.url === msg.expected_url && current.windowId === msg.window_id) {
                await browser.tabs.update(tab.id, { url: msg.url });
                applied = true;
            }
        }
    } catch (_) { /* Report only the result; URLs and browser errors stay out of logs. */ }
    try {
        await fetch(`http://127.0.0.1:${MAC_PORT}/check_url`, {
            method: "POST", headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ action: "managed_navigation_result", request_id: msg.request_id, applied })
        });
    } catch (_) { /* The Mac client times out and reports degraded enforcement. */ }
}

// ------------------------------------------------------------
// Helper: Force block any tab currently showing this URL
// ------------------------------------------------------------
function forceBlockTabs(targetUrl, params = {}) {
    console.log("⛔ forceBlockTabs immediate block for:");
    
    browser.tabs.query({active: true, currentWindow: true}, tabs => {
        if (!tabs || tabs.length === 0) {
            console.log("No active tab found");
            return;
        }
        
        const activeTab = tabs[0];
        if (!activeTab.url) {
            console.log("Active tab has no URL");
            return;
        }
        
        console.log("⛔ forceBlockTabs active tab url:");
        
        // Use includes() to check if URL contains the target string
        if (activeTab.url.includes(targetUrl)) {
            console.log("🔨 Forcing block on active tab:");
            openBlockPage(activeTab.id, params);
        } else {
            console.log("Active tab URL does not contain target:");
        }
    });
}


// ------------------------------------------------------------
// Helper: Send URL to macOS app
// ------------------------------------------------------------
async function checkUrlWithMacApp(url, pageTitle) {
    try {
        const response = await fetch(`http://127.0.0.1:${MAC_PORT}/check_url`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                action: "check_url",
                url: url,
				title: pageTitle
            })
        });

        return await response.json();

    } catch (err) {
        console.error("❌ Focus Bear macOS app not responding:");
        return null;
    }
}

// ------------------------------------------------------------
// Helper: Open block page with parameters
// ------------------------------------------------------------
function openBlockPage(tabId, params) {
    const qs = new URLSearchParams(params || {}).toString();
    const finalUrl = `${BLOCK_PAGE}?${qs}`;

    browser.tabs.update(tabId, { url: finalUrl })
        .catch(() => console.error("Failed to update tab"));
}

// ------------------------------------------------------------
// Central handler: When a tab's URL changes
// ------------------------------------------------------------
async function handleUrlChange(tabId, url, pageTitle) {
    if (!url ) return;

    if (url === lastUrl) return;  // prevent loops
    lastUrl = url;

    const result = await checkUrlWithMacApp(url, pageTitle);

    if (!result) return; // macOS app not available

    if (result.action === "block") {
        const tab = await browser.tabs.get(tabId);
        if (tab && tab.url === url) openBlockPage(tabId, result.params);
    }
}

// ------------------------------------------------------------
// Listener: Tab updated (URL changes)
// ------------------------------------------------------------
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.url && tab.active) {
        handleUrlChange(tabId, changeInfo.url, tab.title);
    }
});

// ------------------------------------------------------------
// Listener: When user switches to another tab
// ------------------------------------------------------------
browser.tabs.onActivated.addListener(async (activeInfo) => {
    try {
        const tab = await browser.tabs.get(activeInfo.tabId);
        if (tab && tab.url) {
            handleUrlChange(activeInfo.tabId, tab.url, tab.title);
        }
    } catch (e) {
        console.error("Failed to get active tab:");
    }
});

// ------------------------------------------------------------
// On extension startup: Check the current active tab
// ------------------------------------------------------------
(async () => {
    try {
        const tabs = await browser.tabs.query({ active: true, currentWindow: true });
        if (tabs.length > 0 && tabs[0].url) {
            handleUrlChange(tabs[0].id, tabs[0].url, tabs[0].title);
        }
    } catch (e) {
        console.error("Startup check failed:");
    }
})();

async function pollMacApp() {
    try {
        const tabs = await browser.tabs.query({ active: true, lastFocusedWindow: true });
        const tab = tabs[0];
        const observation = tab && tab.url ? { url: tab.url, title: tab.title, window_id: tab.windowId, tab_id: tab.id } : null;
        const response = await fetch(`http://127.0.0.1:${MAC_PORT}/push`, {
            method: "POST", headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ managed_navigation_version: MANAGED_NAVIGATION_VERSION, observation })
        });
        if (response.status !== 204 && response.ok) handleWSMessage(await response.json());
    } catch (_) { /* Retry without logging website data. */ }
    finally { setTimeout(pollMacApp, 1000); }
}
