/* CloudForge console — vanilla JS, no build step.
 * Talks to the API Gateway execute plane on Floci with Bearer auth. */

const $ = (sel) => document.querySelector(sel);
const store = {
  get base() { return localStorage.getItem("cf_base") || ""; },
  set base(v) { localStorage.setItem("cf_base", v.trim().replace(/\/$/, "")); },
  get token() { return localStorage.getItem("cf_token") || ""; },
  set token(v) { localStorage.setItem("cf_token", v); },
};

let users = [];
let projects = [];

/* ---------- plumbing ---------- */

function toast(message, kind = "ok") {
  const el = $("#toast");
  el.textContent = message;
  el.className = kind;
  clearTimeout(el._timer);
  el._timer = setTimeout(() => (el.className = ""), kind === "ok" ? 2600 : 6000);
}

async function api(method, path, body) {
  if (!store.base) throw new Error("Configure the API base URL first");
  let response;
  try {
    response = await fetch(`${store.base}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${store.token}`,
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (networkError) {
    throw new Error(
      "Failed to reach the API. The base URL must start with " +
        "http://localhost:8080/floci/restapis/<api-id>/dev/_user_request_ " +
        "(same origin as this page, not localhost:4566) and the stack must be up (docker compose ps)."
    );
  }
  if (response.status === 204) return null;
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("application/json")) {
    await response.text();
    throw new Error(
      `The API answered ${response.status} with a non-JSON body (${contentType.split(";")[0] || "unknown"}). ` +
        "The base URL is probably incomplete — expected shape: " +
        "http://localhost:8080/floci/restapis/<api-id>/dev/_user_request_"
    );
  }
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(`${payload.error || response.status}: ${payload.message || "request failed"}`);
  }
  return payload;
}

function setConnected(ok, detail = "") {
  const badge = $("#conn-status");
  badge.textContent = ok ? "connected" : detail || "not connected";
  badge.className = `badge ${ok ? "ok" : "err"}`;
}

async function checkConnection() {
  if (!store.base) return setConnected(false, "configure URL + token");
  try {
    await api("GET", "/users");
    setConnected(true);
  } catch (error) {
    setConnected(false, error.message.slice(0, 60));
  }
}

/* ---------- tabs ---------- */

document.querySelectorAll(".tab").forEach((tab) =>
  tab.addEventListener("click", () => {
    document.querySelectorAll(".tab, .panel").forEach((el) => el.classList.remove("active"));
    tab.classList.add("active");
    $(`#tab-${tab.dataset.tab}`).classList.add("active");
    load(tab.dataset.tab);
  })
);

document.querySelectorAll(".refresh").forEach((btn) =>
  btn.addEventListener("click", () => load(btn.dataset.load))
);

function load(what) {
  if (what === "users") return renderUsers();
  if (what === "projects") return renderProjects();
  if (what === "artifacts") return renderArtifacts();
}

/* ---------- users ---------- */

async function renderUsers() {
  try {
    users = (await api("GET", "/users")).users ?? [];
  } catch (error) {
    return toast(error.message, "err");
  }
  setConnected(true);
  $("#users-table tbody").innerHTML =
    users
      .map(
        (u) => `<tr>
          <td><code>${u.pk}</code></td><td>${esc(u.name)}</td>
          <td>${esc(u.email)}</td><td>${fmt(u.created_at)}</td></tr>`
      )
      .join("") || emptyRow(4);
}

$("#user-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = new FormData(event.target);
  try {
    await api("POST", "/users", Object.fromEntries(form));
    toast("User created");
    event.target.reset();
    renderUsers();
  } catch (error) {
    toast(error.message, "err");
  }
});

/* ---------- projects ---------- */

const TRANSITIONS = { draft: ["active", "archived"], active: ["draft", "archived"], archived: [] };

async function renderProjects() {
  try {
    if (!users.length) users = (await api("GET", "/users")).users ?? [];
    projects = (await api("GET", "/projects")).projects ?? [];
  } catch (error) {
    return toast(error.message, "err");
  }
  setConnected(true);

  $("#project-form select").innerHTML = users
    .map((u) => `<option value="${u.pk}">${esc(u.name)} (${u.email})</option>`)
    .join("");

  $("#projects-table tbody").innerHTML =
    projects
      .map((p) => {
        const actions = (TRANSITIONS[p.status] ?? [])
          .map(
            (s) =>
              `<button class="small secondary" onclick="transition('${p.pk}','${s}')">${s}</button>`
          )
          .join(" ") || '<span class="empty">terminal</span>';
        return `<tr>
          <td><code>${p.pk}</code></td><td>${esc(p.name)}</td>
          <td><span class="badge status-${p.status}">${p.status}</span></td>
          <td>${ownerName(p.owner)}</td><td>${actions}</td></tr>`;
      })
      .join("") || emptyRow(5);
}

window.transition = async function (projectId, status) {
  const project = projects.find((p) => p.pk === projectId);
  try {
    await api("PUT", `/projects/${projectId}`, {
      name: project.name,
      owner: project.owner,
      description: project.description ?? "",
      status,
    });
    toast(`Project → ${status}`);
    renderProjects();
  } catch (error) {
    toast(error.message, "err");
  }
};

$("#project-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const data = Object.fromEntries(new FormData(event.target));
  try {
    await api("POST", "/projects", data);
    toast("Draft project created");
    event.target.reset();
    renderProjects();
  } catch (error) {
    toast(error.message, "err");
  }
});

/* ---------- artifacts ---------- */

async function renderArtifacts() {
  const selector = $("#artifact-project");
  try {
    if (!projects.length) projects = (await api("GET", "/projects")).projects ?? [];
  } catch (error) {
    return toast(error.message, "err");
  }
  const previous = selector.value;
  selector.innerHTML = projects
    .map((p) => `<option value="${p.pk}">${esc(p.name)}</option>`)
    .join("");
  if (previous && projects.some((p) => p.pk === previous)) selector.value = previous;

  const projectId = selector.value;
  if (!projectId) return ($("#artifacts-table tbody").innerHTML = emptyRow(3));
  let artifacts = [];
  try {
    artifacts = (await api("GET", `/projects/${projectId}/artifacts`)).artifacts ?? [];
  } catch (error) {
    return toast(error.message, "err");
  }
  $("#artifacts-table tbody").innerHTML =
    artifacts
      .map(
        (a) => `<tr>
          <td><code>${esc(a.key)}</code></td>
          <td>${Number(a.size).toLocaleString()} B</td>
          <td>${fmt(a.last_modified)}</td></tr>`
      )
      .join("") || emptyRow(3);
}

$("#artifact-project").addEventListener("change", renderArtifacts);

$("#artifact-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const file = event.target.querySelector("input[type=file]").files[0];
  const projectId = $("#artifact-project").value;
  if (!file || !projectId) return toast("Pick a project and a file first", "err");
  const content = await new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result.split(",")[1]);
    reader.readAsDataURL(file);
  });
  try {
    const result = await api("POST", `/projects/${projectId}/artifacts`, {
      filename: file.name.replace(/\//g, "_"),
      content_base64: content,
    });
    toast(`Uploaded ${result.artifact.key}`);
    event.target.reset();
    renderArtifacts();
  } catch (error) {
    toast(error.message, "err");
  }
});

/* ---------- helpers ---------- */

function esc(value) {
  const div = document.createElement("div");
  div.textContent = value ?? "";
  return div.innerHTML;
}

function fmt(iso) {
  return iso ? new Date(iso).toLocaleString() : "";
}

function ownerName(ownerId) {
  const owner = users.find((u) => u.pk === ownerId);
  return owner ? esc(owner.name) : `<code>${esc(ownerId)}</code>`;
}

function emptyRow(cols) {
  return `<tr><td colspan="${cols}" class="empty">nothing yet</td></tr>`;
}

/* ---------- boot ---------- */

const EXPECTED_BASE = /^https?:\/\/[^/]+\/floci\/restapis\/[^/]+\/[^/]+\/_user_request_$/;

$("#api-base").value = store.base;
$("#api-token").value = store.token;
$("#save-settings").addEventListener("click", () => {
  const base = $("#api-base").value.trim().replace(/\/+$/, "");
  if (!EXPECTED_BASE.test(base)) {
    toast(
      "This does not look like a valid execute-plane URL.\nExpected: " +
        "http://localhost:8080/floci/restapis/<api-id>/dev/_user_request_\n" +
        "Run 'make ui-url' to print yours.",
      "err"
    );
    return;
  }
  store.base = base;
  store.token = $("#api-token").value;
  toast("Settings saved");
  checkConnection().then(() => load(document.querySelector(".tab.active").dataset.tab));
});

if (store.base) checkConnection().then(() => renderUsers());
