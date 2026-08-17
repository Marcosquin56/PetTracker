/** Escapa para uso dentro de HTML (texto o atributos entre comillas dobles). */
function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * uid/token vienen de un query param público: no son de fiar como HTML ni
 * como JS, así que se escapan para el atributo `value` y se pasan al script
 * vía JSON.stringify (no interpolación cruda) para no abrir un XSS reflejado.
 */
export function renderResetPasswordPage({ uid, token }: { uid: string; token: string }): string {
  const safeUid = escapeHtml(uid ?? '');
  const safeToken = escapeHtml(token ?? '');

  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Restablecer contraseña — PetTracker</title>
<style>
  body { font-family: -apple-system, sans-serif; background: #fdf3ec; color: #2a1a12; display: flex; justify-content: center; padding: 32px 16px; }
  main { max-width: 360px; width: 100%; }
  h1 { font-size: 1.3rem; }
  input { width: 100%; padding: 12px; margin-top: 12px; border-radius: 8px; border: 1px solid #cbb7a8; box-sizing: border-box; font-size: 1rem; }
  button { width: 100%; margin-top: 16px; padding: 12px; border-radius: 8px; border: none; background: #8a4b32; color: #fff; font-size: 1rem; cursor: pointer; }
  button:disabled { opacity: 0.6; }
  #status { margin-top: 16px; font-size: 0.95rem; }
</style>
</head>
<body>
<main>
  <h1>🐾 Restablecer contraseña</h1>
  <form id="reset-form">
    <input type="hidden" id="uid" value="${safeUid}" />
    <input type="hidden" id="token" value="${safeToken}" />
    <input type="password" id="newPassword" placeholder="Contraseña nueva (mín. 8 caracteres)" minlength="8" required />
    <button type="submit">Cambiar contraseña</button>
  </form>
  <p id="status"></p>
</main>
<script>
  var uid = ${JSON.stringify(uid ?? '')};
  var token = ${JSON.stringify(token ?? '')};
  document.getElementById('reset-form').addEventListener('submit', function (event) {
    event.preventDefault();
    var status = document.getElementById('status');
    var button = event.target.querySelector('button');
    var newPassword = document.getElementById('newPassword').value;
    button.disabled = true;
    status.textContent = 'Cambiando contraseña...';

    fetch('/auth/reset-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ uid: uid, token: token, newPassword: newPassword }),
    })
      .then(function (res) {
        return res.json().then(function (body) { return { ok: res.ok, body: body }; });
      })
      .then(function (result) {
        if (result.ok) {
          status.textContent = '✅ ' + result.body.message;
          event.target.querySelector('input[type=password]').disabled = true;
        } else {
          status.textContent = '❌ ' + (result.body.message || 'No se pudo cambiar la contraseña.');
          button.disabled = false;
        }
      })
      .catch(function () {
        status.textContent = '❌ Error de conexión. Probá de nuevo.';
        button.disabled = false;
      });
  });
</script>
</body>
</html>`;
}
