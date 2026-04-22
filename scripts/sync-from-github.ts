const manifestPath = "nix/package-manifest.json";
const manifest = await Bun.file(manifestPath).json();

const homepage = manifest.meta?.homepage;
const defaultBranch = process.argv[2] ?? manifest.source?.defaultBranch ?? "main";

const match = /^https:\/\/github\.com\/([^/]+)\/([^/#]+)(?:#.*)?$/.exec(homepage ?? "");
if (!match) {
  throw new Error(`Cannot parse GitHub owner/repo from homepage: ${homepage}`);
}

const [, owner, repo] = match;
const apiUrl = `https://api.github.com/repos/${owner}/${repo}/commits/${encodeURIComponent(defaultBranch)}`;
const response = await fetch(apiUrl, {
  headers: {
    accept: "application/vnd.github+json",
    "user-agent": "nixpkg-code-intel-rust-sync",
  },
});

if (!response.ok) {
  throw new Error(`Failed to fetch ${apiUrl}: ${response.status} ${response.statusText}`);
}

const payload = await response.json();
manifest.source = {
  channel: "github-head",
  defaultBranch,
  version: manifest.package.version,
  rev: payload.sha,
};

await Bun.write(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
console.log(JSON.stringify({ repo: `${owner}/${repo}`, branch: defaultBranch, rev: payload.sha }, null, 2));
