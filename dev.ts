const root = `${import.meta.dir}/public`;
const port = Number(process.env.PORT) || 3000;

// Resolve a request path to a file, mirroring GitHub Pages behaviour:
// try the exact path, then `<path>.html`, then `<path>/index.html`.
async function resolveFile(pathname: string) {
  const candidates: string[] = [];
  if (pathname.endsWith("/")) {
    candidates.push(`${pathname}index.html`);
  } else {
    candidates.push(pathname);
    if (!pathname.split("/").pop()!.includes(".")) {
      candidates.push(`${pathname}.html`);
      candidates.push(`${pathname}/index.html`);
    }
  }
  for (const candidate of candidates) {
    const file = Bun.file(`${root}${candidate}`);
    if (await file.exists()) return file;
  }
  return null;
}

Bun.serve({
  port,
  async fetch(req) {
    const url = new URL(req.url);
    let pathname = decodeURIComponent(url.pathname);
    // Prevent directory traversal outside of public/.
    if (pathname.includes("..")) return new Response("Not Found", { status: 404 });
    if (pathname === "/") pathname = "/index.html";
    const file = await resolveFile(pathname);
    if (file) return new Response(file);
    return new Response("Not Found", { status: 404 });
  },
  development: true,
});

console.log(`http://localhost:${port}`);
