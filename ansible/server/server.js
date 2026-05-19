const express = require('express');
const mongoose = require('mongoose');
const app = express();
mongoose.connect(process.env.MONGO_URL);
const products = [
{ name: 'Laptop', price: 1200 },
{ name: 'Phone', price: 800 }
];
app.get('/', (req, res) => {
let html = '<h1>E-Commerce Store</h1><ul>';
products.forEach(p => {
html += `<li>${p.name} - $${p.price}</li>`;
});
html += '</ul>';
res.send(html);
});
app.listen(3000, () => console.log('App running on port 3000'));
