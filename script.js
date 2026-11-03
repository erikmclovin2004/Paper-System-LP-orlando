/* ============================================================
   CONFIGURACIÓN
   ============================================================ */

// Imágenes del carrusel: pon tus fotos en la carpeta /img
// y cambia aquí la ruta y el texto de cada una.
const SLIDES = [
    { src: "img/slide1.jpg", titulo: "Todo para la escuela y la oficina", texto: "Cuadernos, papel y escritura en un solo lugar." },
    { src: "img/slide2.jpg", titulo: "Encuentra cada producto",           texto: "Pasillo, anaquel y estante al instante." },
    { src: "img/slide3.jpg", titulo: "Inventario siempre al día",         texto: "Detecta lo que necesita reposición." }
];

// Dirección de tu servidor que devuelve los productos en JSON.
// Formato esperado (arreglo):
// [{ "nombre": "Cuaderno profesional", "categoria": "Cuadernos",
//    "ubicacion": "P1-A2-E3", "existencia": 8, "unidad": "unidades", "minimo": 5 }]
const API_PRODUCTOS = "api/productos.php";

/* ============================================================
   CARRUSEL
   ============================================================ */

const carousel = document.getElementById("carousel");
const slidesBox = document.getElementById("slides");
const dotsBox = document.getElementById("dots");
const intervalo = Number(carousel.dataset.interval) || 5000;
let actual = 0;
let timer = null;

SLIDES.forEach((s, i) => {
    const slide = document.createElement("figure");
    slide.className = "slide" + (i === 0 ? " active" : "");
    slide.style.backgroundImage = `url("${s.src}")`;

    const cap = document.createElement("figcaption");
    const h = document.createElement("strong");
    const p = document.createElement("span");
    h.textContent = s.titulo;
    p.textContent = s.texto;
    cap.append(h, p);
    slide.append(cap);
    slidesBox.append(slide);

    const dot = document.createElement("button");
    dot.type = "button";
    dot.className = "dot" + (i === 0 ? " active" : "");
    dot.setAttribute("aria-label", `Ir a la imagen ${i + 1}`);
    dot.addEventListener("click", () => { irA(i); reiniciar(); });
    dotsBox.append(dot);
});

function irA(n) {
    const slides = slidesBox.children;
    const dots = dotsBox.children;
    slides[actual].classList.remove("active");
    dots[actual].classList.remove("active");
    actual = (n + slides.length) % slides.length;
    slides[actual].classList.add("active");
    dots[actual].classList.add("active");
}

function iniciar() { timer = setInterval(() => irA(actual + 1), intervalo); }
function detener() { clearInterval(timer); }
function reiniciar() { detener(); iniciar(); }

carousel.querySelector(".prev").addEventListener("click", () => { irA(actual - 1); reiniciar(); });
carousel.querySelector(".next").addEventListener("click", () => { irA(actual + 1); reiniciar(); });
carousel.addEventListener("mouseenter", detener);
carousel.addEventListener("mouseleave", iniciar);

if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) iniciar();

/* ============================================================
   INVENTARIO
   ============================================================ */

const lista = document.getElementById("productList");
const contador = document.getElementById("resultCount");
const feedback = document.getElementById("feedback");
const input = document.getElementById("searchInput");

let productos = [];
let filtro = "all";

function estado(p) {
    if (p.existencia <= 0) return "out";
    if (p.existencia <= (p.minimo ?? 5)) return "low";
    return "available";
}

const ETIQUETA = { available: "Disponible", low: "Stock bajo", out: "Agotado" };

function mensaje(texto) {
    feedback.textContent = texto;
    feedback.style.display = texto ? "block" : "none";
}

function render() {
    const q = input.value.trim().toLowerCase();

    const visibles = productos.filter(p => {
        const coincide = [p.nombre, p.categoria, p.ubicacion]
            .some(v => String(v ?? "").toLowerCase().includes(q));
        const est = estado(p);
        const pasaFiltro = filtro === "all" || est === filtro;
        return coincide && pasaFiltro;
    });

    lista.replaceChildren();

    if (!visibles.length) {
        const vacio = document.createElement("div");
        vacio.className = "empty-state";
        vacio.textContent = productos.length
            ? "No hay productos que coincidan con la búsqueda."
            : "Aún no hay productos registrados.";
        lista.append(vacio);
    }

    visibles.forEach(p => {
        const est = estado(p);
        const art = document.createElement("article");
        art.className = "product";

        const info = document.createElement("div");
        const nombre = document.createElement("h4");
        const detalle = document.createElement("p");
        nombre.textContent = p.nombre;
        detalle.textContent = `${p.categoria ?? "Sin categoría"} · Ubicación: ${p.ubicacion ?? "Sin asignar"}`;
        info.append(nombre, detalle);

        const stock = document.createElement("div");
        stock.className = "stock";
        const cant = document.createElement("strong");
        const badge = document.createElement("span");
        cant.textContent = `${p.existencia} ${p.unidad ?? "unidades"}`;
        badge.className = "status " + est;
        badge.textContent = ETIQUETA[est];
        stock.append(cant, badge);

        art.append(info, stock);
        lista.append(art);
    });

    contador.textContent = productos.length
        ? `${visibles.length} de ${productos.length} productos`
        : "Sin productos";
}

function aplicarFiltro(f) {
    filtro = f;
    document.querySelectorAll(".chip").forEach(c =>
        c.classList.toggle("active", c.dataset.filter === f));
    render();
}

document.querySelectorAll("[data-filter]").forEach(el =>
    el.addEventListener("click", () => aplicarFiltro(el.dataset.filter)));

document.getElementById("searchForm").addEventListener("submit", e => {
    e.preventDefault();
    render();
    document.getElementById("inventario").scrollIntoView({ behavior: "smooth" });
});
input.addEventListener("input", render);

async function cargarProductos() {
    try {
        const res = await fetch(API_PRODUCTOS);
        if (!res.ok) throw new Error(res.status);
        productos = await res.json();
        mensaje("");
    } catch (err) {
        productos = [];
        mensaje("No se pudo conectar con la base de datos. Revisa que el servidor esté activo.");
    }
    render();
}

cargarProductos();
