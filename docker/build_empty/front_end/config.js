const { port, hostname, protocol } = window.location;
window.env = { API_HOST: `${protocol}//${hostname}:${port}/api` };
