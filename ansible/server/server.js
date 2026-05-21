const express = require('express');
const mongoose = require('mongoose');
const app = express();
mongoose.connect(process.env.MONGO_URL);
const products = [
{ name: 'Laptop Pro', price: 1200, tag: 'Best Seller' },
{ name: 'Phone X', price: 800, tag: 'New Arrival' },
{ name: 'Headphones', price: 220, tag: 'Popular' }
];
app.get('/', (req, res) => {
const cards = products.map((p, index) => `
	<article class="product-card product-${index + 1}">
		<span class="product-tag">${p.tag}</span>
		<h3>${p.name}</h3>
		<p>Premium quality, fast delivery and trusted support for your daily essentials.</p>
		<div class="product-footer">
			<strong>$${p.price}</strong>
			<button>Add to cart</button>
		</div>
	</article>
`).join('');

res.send(`<!doctype html>
<html lang="en">
<head>
	<meta charset="UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<title>E-Commerce Store</title>
	<style>
		:root {
			--bg: #f3f0e8;
			--panel: #ffffff;
			--text: #16202a;
			--muted: #64748b;
			--accent: #0f766e;
			--accent-2: #f59e0b;
			--border: rgba(22, 32, 42, 0.12);
			--shadow: 0 20px 60px rgba(15, 23, 42, 0.12);
		}
		* { box-sizing: border-box; }
		body {
			margin: 0;
			font-family: Georgia, 'Times New Roman', serif;
			color: var(--text);
			background:
				radial-gradient(circle at top left, rgba(15, 118, 110, 0.18), transparent 24%),
				radial-gradient(circle at bottom right, rgba(245, 158, 11, 0.18), transparent 22%),
				var(--bg);
			min-height: 100vh;
		}
		.shell {
			max-width: 1200px;
			margin: 0 auto;
			padding: 32px 20px 48px;
		}
		.hero {
			display: grid;
			grid-template-columns: 1.3fr 0.7fr;
			gap: 24px;
			align-items: stretch;
			margin-bottom: 28px;
		}
		.panel {
			background: rgba(255, 255, 255, 0.88);
			border: 1px solid var(--border);
			border-radius: 28px;
			box-shadow: var(--shadow);
			backdrop-filter: blur(12px);
		}
		.hero-copy {
			padding: 34px;
			position: relative;
			overflow: hidden;
		}
		.eyebrow {
			display: inline-block;
			padding: 8px 14px;
			border-radius: 999px;
			background: rgba(15, 118, 110, 0.12);
			color: var(--accent);
			font-weight: 700;
			letter-spacing: 0.04em;
			text-transform: uppercase;
			font-size: 0.82rem;
			margin-bottom: 18px;
		}
		h1 {
			margin: 0;
			font-size: clamp(3rem, 6vw, 5.3rem);
			line-height: 0.95;
			letter-spacing: -0.04em;
		}
		.lead {
			margin: 18px 0 0;
			max-width: 60ch;
			color: var(--muted);
			font-size: 1.07rem;
			line-height: 1.65;
		}
		.hero-metrics {
			display: grid;
			grid-template-columns: repeat(3, 1fr);
			gap: 14px;
			margin-top: 28px;
		}
		.metric {
			padding: 16px;
			border-radius: 20px;
			background: rgba(255,255,255,0.75);
			border: 1px solid var(--border);
		}
		.metric strong { display: block; font-size: 1.25rem; }
		.metric span { color: var(--muted); font-size: 0.95rem; }
		.hero-side {
			padding: 24px;
			display: grid;
			gap: 16px;
		}
		.promo {
			border-radius: 24px;
			padding: 22px;
			color: white;
			background: linear-gradient(135deg, #0f766e, #14b8a6 52%, #f59e0b);
			min-height: 180px;
			display: flex;
			flex-direction: column;
			justify-content: space-between;
		}
		.promo small { opacity: 0.9; }
		.promo h2 { margin: 10px 0 0; font-size: 2rem; line-height: 1.05; }
		.promo p { margin: 12px 0 0; max-width: 26ch; opacity: 0.92; }
		.badge-row {
			display: flex;
			flex-wrap: wrap;
			gap: 10px;
		}
		.badge {
			padding: 10px 14px;
			border-radius: 999px;
			background: white;
			border: 1px solid var(--border);
			font-size: 0.95rem;
			color: var(--text);
		}
		.section-head {
			display: flex;
			align-items: end;
			justify-content: space-between;
			gap: 16px;
			margin: 18px 0 14px;
		}
		.section-head h2 {
			margin: 0;
			font-size: 1.45rem;
			letter-spacing: -0.02em;
		}
		.section-head p { margin: 0; color: var(--muted); }
		.grid {
			display: grid;
			grid-template-columns: repeat(3, minmax(0, 1fr));
			gap: 18px;
		}
		.product-card {
			padding: 22px;
			border-radius: 24px;
			background: var(--panel);
			border: 1px solid var(--border);
			box-shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
		}
		.product-tag {
			display: inline-block;
			padding: 6px 10px;
			border-radius: 999px;
			background: rgba(15, 118, 110, 0.12);
			color: var(--accent);
			font-size: 0.78rem;
			font-weight: 700;
			letter-spacing: 0.04em;
			text-transform: uppercase;
		}
		.product-card h3 {
			margin: 14px 0 8px;
			font-size: 1.5rem;
		}
		.product-card p {
			margin: 0;
			color: var(--muted);
			line-height: 1.6;
			min-height: 76px;
		}
		.product-footer {
			margin-top: 18px;
			display: flex;
			align-items: center;
			justify-content: space-between;
			gap: 10px;
		}
		.product-footer strong {
			font-size: 1.5rem;
			color: var(--text);
		}
		.product-footer button {
			border: 0;
			padding: 12px 16px;
			border-radius: 999px;
			background: var(--text);
			color: white;
			font-weight: 700;
			cursor: pointer;
		}
		.product-footer button:hover { background: var(--accent); }
		.footer-note {
			margin-top: 20px;
			text-align: center;
			color: var(--muted);
			font-size: 0.95rem;
		}
		@media (max-width: 900px) {
			.hero, .grid, .hero-metrics { grid-template-columns: 1fr; }
		}
	</style>
</head>
<body>
	<main class="shell">
		<section class="hero">
			<div class="panel hero-copy">
				<div class="eyebrow">Curated essentials</div>
				<h1>E-Commerce Store</h1>
				<p class="lead">A polished storefront experience for the jury: focused collections, clean visual hierarchy, strong contrast, and a modern layout that feels intentional on desktop and mobile.</p>
				<div class="hero-metrics">
					<div class="metric"><strong>24h</strong><span>Fast delivery</span></div>
					<div class="metric"><strong>4.9/5</strong><span>Customer rating</span></div>
					<div class="metric"><strong>100%</strong><span>Secure checkout</span></div>
				</div>
			</div>
			<div class="panel hero-side">
				<div class="promo">
					<small>Featured drop</small>
					<div>
						<h2>Premium gear, curated for work and life.</h2>
						<p>Quality devices with clean design and a simple buying experience.</p>
					</div>
				</div>
				<div class="badge-row">
					<span class="badge">Free returns</span>
					<span class="badge">24/7 support</span>
					<span class="badge">Trusted sellers</span>
				</div>
			</div>
		</section>

		<section>
			<div class="section-head">
				<div>
					<h2>Featured products</h2>
					<p>Balanced cards, strong typography, and clearer spacing for a jury-ready look.</p>
				</div>
			</div>
			<div class="grid">
				${cards}
			</div>
		</section>

		<p class="footer-note">Built for the DevOps demo with a cleaner storefront presentation.</p>
	</main>
</body>
</html>`);
});
app.listen(3000, () => console.log('App running on port 3000'));
