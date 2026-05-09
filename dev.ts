const root = `${import.meta.dir}/public`;
const port = Number(process.env.PORT) || 3000;

Bun.serve({
  port,
  async fetch(req) {
    const url = new URL(req.url);
    let pathname = decodeURIComponent(url.pathname);
    if (pathname.endsWith("/")) pathname += "index.html";
    if (pathname === "/") pathname = "/index.html";
    const filePath = `${root}${pathname}`;
    const file = Bun.file(filePath);
    if (await file.exists()) return new Response(file);
    return new Response("Not Found", { status: 404 });
  },
  development: true,
});

console.log(`http://localhost:${port}`);
