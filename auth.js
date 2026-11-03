/* ==========================================================================
   ARCHIVO: auth.js
   QUÉ HACE:
     1. Cambia entre las pestañas "Iniciar sesión" y "Crear cuenta"
     2. Valida los datos ANTES de enviarlos
     3. Envía los datos al servidor y muestra el resultado
   SE CONECTA CON:
     - login.html -> formularios #loginForm y #registroForm
     - Tu servidor -> mediante API_LOGIN y API_REGISTRO (ver abajo)

   IMPORTANTE (seguridad): este archivo corre en el navegador y cualquiera
   puede verlo. Por eso NUNCA compara contraseñas aquí ni las guarda: solo las
   envía al servidor, que debe verificarlas y guardarlas CIFRADAS (hash).
   Tampoco guardes usuarios ni contraseñas en un archivo de GitHub.
   ========================================================================== */


/* ==========================================================================
   CONFIGURACIÓN
   ========================================================================== */

/* Direcciones de tu servidor. Cada una recibe un POST con JSON.
   - API_LOGIN    recibe  { correo, password }
                  responde 200 con { nombre: "Ana" }
                  o con error (401, etc.) y { error: "Texto para mostrar" }
   - API_REGISTRO recibe  { nombre, correo, password }
                  responde 201 con { mensaje: "Cuenta creada" }
                  o con error (409 si el correo ya existe, etc.) y { error: "..." }
   Si usas sesiones con cookies, el servidor debe iniciar la sesión en API_LOGIN. */
const API_LOGIN    = "api/login.php";
const API_REGISTRO = "api/registro.php";

// Página a la que se va después de iniciar sesión correctamente
const DESTINO_TRAS_LOGIN = "index.html";


/* ==========================================================================
   ELEMENTOS DE LA PÁGINA (todos vienen de login.html)
   ========================================================================== */

const loginForm    = document.getElementById("loginForm");
const registroForm = document.getElementById("registroForm");
const mensajeBox   = document.getElementById("authMessage");
const passHint     = document.getElementById("passHint");


/* ==========================================================================
   MENSAJES
   ========================================================================== */

// Muestra un mensaje arriba del formulario. tipo: "error" (rojo) o "success" (verde).
// Con texto vacío lo oculta.
function mostrarMensaje(texto, tipo) {
    mensajeBox.textContent = texto;
    mensajeBox.className = "auth-message" + (texto ? " " + tipo : "");
}

// Marca un campo como inválido (borde rojo) y lo enfoca para que el usuario lo corrija
function marcarInvalido(input) {
    input.classList.add("invalid");
    input.focus();
}

// Quita las marcas de error de un formulario
function limpiarErrores(form) {
    form.querySelectorAll("input").forEach(i => i.classList.remove("invalid"));
}


/* ==========================================================================
   PESTAÑAS: Iniciar sesión / Crear cuenta
   ========================================================================== */

function cambiarPestana(nombre) {
    // Marca la pestaña activa
    document.querySelectorAll(".tab").forEach(t => {
        const activa = t.dataset.tab === nombre;
        t.classList.toggle("active", activa);
        t.setAttribute("aria-selected", activa);
    });
    // Muestra solo el formulario correspondiente
    loginForm.hidden    = nombre !== "login";
    registroForm.hidden = nombre !== "registro";
    mostrarMensaje("");   // borra mensajes anteriores
}

document.querySelectorAll(".tab").forEach(t =>
    t.addEventListener("click", () => cambiarPestana(t.dataset.tab)));

// Si abres login.html#registro, se abre directo la pestaña de registro
if (location.hash === "#registro") cambiarPestana("registro");


/* ==========================================================================
   BOTÓN "VER" DE LAS CONTRASEÑAS
   ========================================================================== */

document.querySelectorAll(".toggle-pass").forEach(btn =>
    btn.addEventListener("click", () => {
        const campo = btn.previousElementSibling;   // el input que está junto al botón
        const oculto = campo.type === "password";
        campo.type = oculto ? "text" : "password";  // alterna entre texto y puntos
        btn.textContent = oculto ? "Ocultar" : "Ver";
        btn.setAttribute("aria-label", oculto ? "Ocultar contraseña" : "Mostrar contraseña");
    }));


/* ==========================================================================
   SEGURIDAD DE LA CONTRASEÑA (indicador en el registro)
   ========================================================================== */

// Devuelve "weak", "medium" o "strong" según longitud y variedad de caracteres
function nivelPassword(p) {
    let puntos = 0;
    if (p.length >= 8) puntos++;
    if (p.length >= 12) puntos++;
    if (/[a-z]/.test(p) && /[A-Z]/.test(p)) puntos++;
    if (/\d/.test(p)) puntos++;
    if (/[^A-Za-z0-9]/.test(p)) puntos++;
    return puntos <= 2 ? "weak" : puntos <= 3 ? "medium" : "strong";
}

const TEXTO_NIVEL = {
    weak:   "Contraseña débil: agrega más caracteres, letras y números.",
    medium: "Contraseña aceptable. Puedes reforzarla con mayúsculas o símbolos.",
    strong: "Contraseña segura."
};

// Actualiza el texto de ayuda mientras el usuario escribe
document.getElementById("regPassword").addEventListener("input", e => {
    const v = e.target.value;
    if (!v) {
        passHint.className = "hint";
        passHint.textContent = "Mínimo 8 caracteres, con letras y números.";
        return;
    }
    const nivel = nivelPassword(v);
    passHint.className = "hint " + nivel;
    passHint.textContent = TEXTO_NIVEL[nivel];
});


/* ==========================================================================
   ENVÍO AL SERVIDOR
   ========================================================================== */

// Envía datos en JSON a una dirección y devuelve { ok, datos }.
// Si no hay conexión con el servidor, lanza un error que se atrapa más abajo.
async function enviar(url, datos) {
    const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "same-origin",   // permite que el servidor guarde la cookie de sesión
        body: JSON.stringify(datos)
    });
    let cuerpo = {};
    try { cuerpo = await res.json(); } catch (_) { /* respuesta sin JSON */ }
    return { ok: res.ok, datos: cuerpo };
}

// Bloquea el botón mientras se envía para evitar clics dobles
function bloquear(form, bloqueado) {
    const btn = form.querySelector(".submit");
    btn.disabled = bloqueado;
}

const ERROR_CONEXION = "No se pudo conectar con el servidor. Revisa tu conexión e intenta de nuevo.";
const EMAIL_VALIDO = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;


/* ==========================================================================
   INICIAR SESIÓN
   ========================================================================== */

loginForm.addEventListener("submit", async e => {
    e.preventDefault();   // evita que el navegador recargue la página
    limpiarErrores(loginForm);
    mostrarMensaje("");

    const correo   = loginForm.correo.value.trim();
    const password = loginForm.password.value;

    // Validación antes de enviar
    if (!EMAIL_VALIDO.test(correo)) {
        mostrarMensaje("Escribe un correo electrónico válido.", "error");
        return marcarInvalido(loginForm.correo);
    }
    if (!password) {
        mostrarMensaje("Escribe tu contraseña.", "error");
        return marcarInvalido(loginForm.password);
    }

    bloquear(loginForm, true);
    try {
        const { ok, datos } = await enviar(API_LOGIN, { correo, password });
        if (!ok) {
            mostrarMensaje(datos.error || "Correo o contraseña incorrectos.", "error");
            return;
        }
        // Guarda solo el nombre (no datos sensibles) para poder saludar en otras páginas
        try { sessionStorage.setItem("piwis_nombre", datos.nombre || ""); } catch (_) {}
        window.location.href = DESTINO_TRAS_LOGIN;   // entra al sistema
    } catch (err) {
        mostrarMensaje(ERROR_CONEXION, "error");
    } finally {
        bloquear(loginForm, false);
    }
});


/* ==========================================================================
   CREAR CUENTA
   ========================================================================== */

registroForm.addEventListener("submit", async e => {
    e.preventDefault();
    limpiarErrores(registroForm);
    mostrarMensaje("");

    const nombre    = registroForm.nombre.value.trim();
    const correo    = registroForm.correo.value.trim();
    const password  = registroForm.password.value;
    const confirmar = registroForm.confirmar.value;

    // Validaciones antes de enviar (el servidor debe repetirlas: aquí son solo comodidad)
    if (nombre.length < 3) {
        mostrarMensaje("Escribe tu nombre completo.", "error");
        return marcarInvalido(registroForm.nombre);
    }
    if (!EMAIL_VALIDO.test(correo)) {
        mostrarMensaje("Escribe un correo electrónico válido.", "error");
        return marcarInvalido(registroForm.correo);
    }
    if (password.length < 8 || !/[A-Za-z]/.test(password) || !/\d/.test(password)) {
        mostrarMensaje("La contraseña debe tener al menos 8 caracteres, con letras y números.", "error");
        return marcarInvalido(registroForm.password);
    }
    if (password !== confirmar) {
        mostrarMensaje("Las contraseñas no coinciden.", "error");
        return marcarInvalido(registroForm.confirmar);
    }

    bloquear(registroForm, true);
    try {
        // La confirmación NO se envía; solo nombre, correo y contraseña
        const { ok, datos } = await enviar(API_REGISTRO, { nombre, correo, password });
        if (!ok) {
            mostrarMensaje(datos.error || "No se pudo crear la cuenta. Intenta de nuevo.", "error");
            return;
        }
        // Cuenta creada: limpia el formulario y pasa a "Iniciar sesión"
        registroForm.reset();
        passHint.className = "hint";
        passHint.textContent = "Mínimo 8 caracteres, con letras y números.";
        cambiarPestana("login");
        loginForm.correo.value = correo;   // deja el correo listo para entrar
        mostrarMensaje("Cuenta creada. Ahora inicia sesión.", "success");
        loginForm.password.focus();
    } catch (err) {
        mostrarMensaje(ERROR_CONEXION, "error");
    } finally {
        bloquear(registroForm, false);
    }
});
