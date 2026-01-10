function createLootModal() {
    if (document.getElementById("lootModal")) return;

    const style = document.createElement("style");
    style.textContent = `
        .loot-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); z-index: 9999; display: flex; align-items: center; justify-content: center; }
        .loot-modal { background: #1e1e1e; color: #fff; border-radius: 10px; width: 420px; padding: 20px; box-shadow: 0 10px 40px rgba(0,0,0,.6); font-family: sans-serif; animation: pop .15s ease-out; }
        @keyframes pop { from { transform: scale(.9); opacity: 0 } to { transform: scale(1); opacity: 1 } }
        .loot-modal h2 { margin: 0 0 12px; font-size: 18px; }
        .loot-links a { display: block; padding: 10px; border-radius: 6px; margin-bottom: 8px; background: #2b2b2b; color: #4fc3f7; text-decoration: none; cursor: pointer; }
        .loot-links a:hover { background: #3a3a3a; }
        .loot-close { margin-top: 14px; width: 100%; padding: 8px; border-radius: 6px; border: none; background: #ff5252; color: #fff; cursor: pointer; }
    `;
    document.head.appendChild(style);

    const overlay = document.createElement("div");
    overlay.className = "loot-overlay";
    overlay.id = "lootModal";
    overlay.style.display = "none";
    overlay.innerHTML = `
        <div class="loot-modal">
            <h2>Download Specific Loot</h2>
            <div class="loot-links">
                <p style="color:#aaa;">Fetching loot list...</p>
            </div>
            <button class="loot-close">Close</button>
        </div>
    `;
    document.body.appendChild(overlay);
    overlay.querySelector(".loot-close").onclick = () => overlay.style.display = "none";
    overlay.onclick = e => e.target === overlay && (overlay.style.display = "none");
}

function addLootSidebarButton() {
    const ul = document.querySelector("#sidebarnav ul");
    if (!ul) return;
    if (document.getElementById("lootSidebarBtn")) return;

    const li = document.createElement("li");
    li.innerHTML = `
        <a href="#" id="lootSidebarBtn">
            <i class="material-icons">download</i>
            <div class="sidebarsub">
                Download Specific Loot
                <div class="sidebarmini">
                    Download a specific loot folder from /root/loot
                </div>
            </div>
        </a>
    `;
    ul.appendChild(li);

    const sidebarBtn = document.getElementById("lootSidebarBtn");
    const overlay = document.getElementById("lootModal");
    const linksContainer = overlay.querySelector(".loot-links");

    sidebarBtn.addEventListener("click", async (e) => {
        e.preventDefault();
        overlay.style.display = "flex";
        linksContainer.innerHTML = `<p style="color:#aaa;">Fetching loot list...</p>`;

        const cmd = "ls /root/loot/ | tr '\\n' ','";
        try {
            const res = await sendServerRequest("command", cmd, true);
            if (!res || res.status !== "done") {
                linksContainer.innerHTML = `<p style="color:#aaa;">Failed to get loot list</p>`;
                return;
            }

            const output = res.output.trim();
            const list = output.split(",").map(s => s.trim()).filter(Boolean);

            linksContainer.innerHTML = "";
            if (!list.length) {
                linksContainer.innerHTML = "<p style='color:#aaa;'>No loot found</p>";
            } else {
                list.forEach(dir => {
                    const a = document.createElement("a");
                    a.textContent = dir;
                    a.href = "#";
                    a.addEventListener("click", e => {
                        e.preventDefault();
                        const zipUrl = `/api/files/zip/root/loot/${dir}`;
                        const tmp = document.createElement("a");
                        tmp.href = zipUrl;
                        tmp.download = `${dir}.zip`;
                        document.body.appendChild(tmp);
                        tmp.click();
                        document.body.removeChild(tmp);
                    });
                    linksContainer.appendChild(a);
                });
            }
        } catch (err) {
            console.error(err);
            linksContainer.innerHTML = `<p style="color:#aaa;">Error fetching loot list</p>`;
        }
    });
}

async function sendServerRequest(action, data, returnJson = false) {
    if (!action) {
        console.error("sendServerRequest: action parameter is required.");
        return;
    }

    const serverid = localStorage.getItem("serverid");
    if (!serverid) {
        console.error("No serverid found in localStorage.");
        return;
    }

    const cookieName = `AUTH_${serverid}`;
    const cookieValue = document.cookie
        .split("; ")
        .find(c => c.startsWith(cookieName + "="));

    if (!cookieValue) {
        console.error(`Cookie ${cookieName} not found.`);
        return;
    }

    const tokenValue = cookieValue.substring(cookieName.length + 1);

    const url = new URL(`http://${window.location.hostname}:4040/cgi-bin/api.sh`);
    url.searchParams.set("token", tokenValue);
    url.searchParams.set("serverid", serverid);
    url.searchParams.set("action", action);
    if (data !== undefined) url.searchParams.set("data", data);

    const res = await fetch(url.toString());
    if (returnJson) return res.json();
    return res;
}

function initLootUI() {
    createLootModal();
    addLootSidebarButton();
}

function waitForSidebarAndInit() {
    if (!document.body) {
        requestAnimationFrame(waitForSidebarAndInit);
        return;
    }

    const observer = new MutationObserver(() => {
        const sidebar = document.getElementById("sidebarnav");
        if (sidebar && window.getComputedStyle(sidebar).display !== "none") {
            onSidebarReady();
            observer.disconnect();
        }
    });

    observer.observe(document.body, { childList: true, subtree: true });

    const sidebar = document.getElementById("sidebarnav");
    if (sidebar && window.getComputedStyle(sidebar).display !== "none") {
        onSidebarReady();
        observer.disconnect();
    }
}

function onSidebarReady() {
    initLootUI();
    fetch("/api/api_ping")
        .then(res => res.json())
        .then(data => {
            if (data.serverid) localStorage.setItem("serverid", data.serverid);
        })
        .catch(err => console.error("Failed to fetch serverid:", err));
}

function setupLootFeature() {
    waitForSidebarAndInit();
}

setupLootFeature();
