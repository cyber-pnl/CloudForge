#!/usr/bin/env bash
# CloudForge — Deploy an Azure Function App to the local Floci-AZ emulator.
#
# This is an emulator-specific helper. Floci-AZ does not emulate the Azure App
# Service Plan (Microsoft.Web/serverfarms -> 404), so the azurerm provider
# cannot provision Function Apps. Instead we talk to Floci-AZ's native
# Functions management API:
#
#   PUT {endpoint}/{account}-functions/admin/apps/{app}
#   PUT {endpoint}/{account}-functions/admin/apps/{app}/functions/{func}
#
# The emulator spawns a real Azure Functions runtime container and proxies HTTP
# invocations to it. See docs/02-infrastructure/multicloud-journal.md.
#
# Behaviour: idempotent — creating an existing app/function updates it.
#
# The Python v2 model is used: the deployed package is host.json + a generated
# function_app.py whose HTTP route is named after AZ_FUNCTIONS_FUNC. The public
# invocation URL is {endpoint}/{account}-functions/api/{app}/{func}.
#
# Only the Python runtime is supported (Python v2), matching the rest of the
# CloudForge workload (AWS lambdas are Python). Node/Java/.NET classic layouts
# are NOT picked up by the Floci-AZ runtime (0 functions found), so they are
# intentionally rejected here.
#
# Required env vars:
#   AZ_FUNCTIONS_ENDPOINT        base URL, e.g. https://localhost:4577
#   AZ_FUNCTIONS_ACCOUNT         storage account name, e.g. devstoreaccount1
#   AZ_FUNCTIONS_APP             function app name
#   AZ_FUNCTIONS_FUNC            function name inside the app
#   AZ_FUNCTIONS_PACKAGE_DIR     directory containing host.json
# Optional:
#   AZ_FUNCTIONS_RUNTIME_VERSION Python version, e.g. 3.12
#   AZ_APP_SETTINGS              JSON object of application settings
set -euo pipefail

: "${AZ_FUNCTIONS_ENDPOINT:?AZ_FUNCTIONS_ENDPOINT is required}"
: "${AZ_FUNCTIONS_ACCOUNT:?AZ_FUNCTIONS_ACCOUNT is required}"
: "${AZ_FUNCTIONS_APP:?AZ_FUNCTIONS_APP is required}"
: "${AZ_FUNCTIONS_FUNC:?AZ_FUNCTIONS_FUNC is required}"
: "${AZ_FUNCTIONS_PACKAGE_DIR:?AZ_FUNCTIONS_PACKAGE_DIR is required}"

AZ_FUNCTIONS_RUNTIME="${AZ_FUNCTIONS_RUNTIME:-python}"
if [[ "${AZ_FUNCTIONS_RUNTIME}" != "python" ]]; then
  echo "unsupported runtime '${AZ_FUNCTIONS_RUNTIME}': only 'python' is supported" >&2
  exit 2
fi

# Build a deterministic ZIP of a directory using python3's zipfile module.
# Defined here (before use) and streamed to stdout.
make_zip() {
  local dir="$1"
  python3 - "$dir" <<'PY'
import sys, zipfile, os, tempfile
src = sys.argv[1]
fd, tmp = tempfile.mkstemp(suffix=".zip")
os.close(fd)
try:
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(src):
            for f in sorted(files):
                full = os.path.join(root, f)
                rel = os.path.relpath(full, src)
                z.write(full, rel)
    with open(tmp, "rb") as fh:
        sys.stdout.buffer.write(fh.read())
finally:
    os.unlink(tmp)
PY
}

BASE="${AZ_FUNCTIONS_ENDPOINT%/}/${AZ_FUNCTIONS_ACCOUNT}-functions"
RUNTIME_VERSION="${AZ_FUNCTIONS_RUNTIME_VERSION:-3.12}"
LINUX_FX="Python|${RUNTIME_VERSION}"

# Assemble the deployment package into a temp build directory.
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT
cp "${AZ_FUNCTIONS_PACKAGE_DIR}/host.json" "${BUILD_DIR}/host.json"

# Python v2 model: function_app.py at the package root declaring a single
# HTTP-triggered function whose route matches the deployed function name.
cat > "${BUILD_DIR}/function_app.py" <<PY
import azure.functions as func

app = func.FunctionApp()


@app.function_name(name="${AZ_FUNCTIONS_FUNC}")
@app.route(route="${AZ_FUNCTIONS_FUNC}", auth_level=func.AuthLevel.ANONYMOUS)
def handler(req: func.HttpRequest) -> func.HttpResponse:
    name = req.params.get("name", "world")
    return func.HttpResponse(
        f"Hello {name} from ${AZ_FUNCTIONS_APP} (${AZ_FUNCTIONS_FUNC})!",
        status_code=200,
    )
PY

# Build a deterministic ZIP of the build directory.
B64_ZIP="$(make_zip "${BUILD_DIR}" | base64 -w0)"

APP_SETTINGS='{}'
if [[ -n "${AZ_APP_SETTINGS:-}" ]]; then
  APP_SETTINGS="${AZ_APP_SETTINGS}"
fi

APP_BODY=$(jq -nc \
  --arg runtime "python" \
  --arg linuxFxVersion "${LINUX_FX}" \
  --argjson environment "${APP_SETTINGS}" \
  '{runtime:$runtime, linuxFxVersion:$linuxFxVersion, environment:$environment}')

FUNC_BODY=$(jq -nc \
  --arg handler "index.handler" \
  --arg zipBase64 "${B64_ZIP}" \
  '{"handler":$handler, "timeoutSeconds":60, "zipBase64":$zipBase64}')

# Create (or update) the function app. -k skips TLS verification for the
# emulator's self-signed certificate (Floci-AZ serves HTTPS on :4577).
echo "Creating/updating function app '${AZ_FUNCTIONS_APP}'..."
curl -fskS -X PUT "${BASE}/admin/apps/${AZ_FUNCTIONS_APP}" \
  -H 'Content-Type: application/json' \
  -d "${APP_BODY}" >/dev/null

# Deploy the function package.
echo "Deploying function '${AZ_FUNCTIONS_FUNC}' to '${AZ_FUNCTIONS_APP}'..."
curl -fskS -X PUT "${BASE}/admin/apps/${AZ_FUNCTIONS_APP}/functions/${AZ_FUNCTIONS_FUNC}" \
  -H 'Content-Type: application/json' \
  -d "${FUNC_BODY}" >/dev/null

echo "Deployed. Invoke: ${BASE}/api/${AZ_FUNCTIONS_APP}/${AZ_FUNCTIONS_FUNC}"
