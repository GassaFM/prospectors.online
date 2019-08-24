// Author: Ivan Kazmenko (gassa@mail.ru)
// Inspired by: https://stackoverflow.com/questions/10683712#57080195
const tableToSort = document.getElementById ('auction-list');
document.getElementById ('col-owner').addEventListener ('click', event =>
	{sortTable (tableToSort,  3 * 3, +1, 'str');});
document.getElementById ('col-active').addEventListener ('click', event =>
	{sortTable (tableToSort,  4 * 3, +1, 'num');});
document.getElementById ('col-price').addEventListener ('click', event =>
	{sortTable (tableToSort,  5 * 3, +1, 'num');});
document.getElementById ('col-bidder').addEventListener ('click', event =>
	{sortTable (tableToSort,  6 * 3, +1, 'str');});
document.getElementById ('col-rent').addEventListener ('click', event =>
	{sortTable (tableToSort,  7 * 3, -1, 'num');});
document.getElementById ('col-gold').addEventListener ('click', event =>
	{sortTable (tableToSort,  8 * 3, -1, 'num');});
document.getElementById ('col-wood').addEventListener ('click', event =>
	{sortTable (tableToSort,  9 * 3, -1, 'num');});
document.getElementById ('col-stone').addEventListener ('click', event =>
	{sortTable (tableToSort, 10 * 3, -1, 'num');});
document.getElementById ('col-coal').addEventListener ('click', event =>
	{sortTable (tableToSort, 11 * 3, -1, 'num');});
document.getElementById ('col-clay').addEventListener ('click', event =>
	{sortTable (tableToSort, 12 * 3, -1, 'num');});
document.getElementById ('col-ore').addEventListener ('click', event =>
	{sortTable (tableToSort, 13 * 3, -1, 'num');});
document.getElementById ('col-coffee').addEventListener ('click', event =>
	{sortTable (tableToSort, 14 * 3, -1, 'num');});
document.getElementById ('col-building').addEventListener ('click', event =>
	{sortTable (tableToSort, 15 * 3, +1, 'str');});

function sortTable (table, col, dir, type) {
	const body = table.querySelector ('tbody');
	const data = getData (body);
	data.sort ((a, b) => {
		if (a[col] == '?' && b[col] != '?') {
			return +1;
		}
		if (a[col] != '?' && b[col] == '?') {
			return -1;
		}
		if (a[col].length == 0 && b[col].length != 0) {
			return +1;
		}
		if (a[col].length != 0 && b[col].length == 0) {
			return -1;
		}

		mult = (a[col][0] == '-') ? -1 : +1;
		if (type == 'num') {
			if (a[col][0] == '-' && b[col][0] != '-') {
				return -dir;
			}
			if (a[col][0] != '-' && b[col][0] == '-') {
				return +dir;
			}
			if (a[col].length != b[col].length) {
				return ((a[col].length < b[col].length) ?
					-dir : +dir) * mult;
			}
		}
		if (a[col] != b[col]) {
			return ((a[col] < b[col]) ? -dir : +dir) * mult;
		}

		if (a[5 * 3].length != b[5 * 3].length) {
			return (a[5 * 3].length < b[5 * 3].length) ? -1 : +1;
		}
		if (a[5 * 3] != b[5 * 3]) {
			return (a[5 * 3] < b[5 * 3]) ? -1 : +1;
		}
		if (a[4 * 3] != b[4 * 3]) {
			return (a[4 * 3] < b[4 * 3]) ? -1 : +1;
		}
		return (a[2 * 3] < b[2 * 3]) ? -1 : +1;
	});
	putData (body, data);
}

function getData (body) {
	const data = [];
	body.querySelectorAll ('tr').forEach (row => {
		const line = [];
		row.querySelectorAll ('td').forEach (cell => {
			line.push (cell.innerText);
			line.push (cell.getAttribute ('class'));
			line.push (cell.getAttribute ('style'));
		});
		data.push (line);
	});
	return data;
}

function putData (body, data) {
	body.querySelectorAll ('tr').forEach ((row, i) => {
		const line = data[i];
		row.querySelectorAll ('td').forEach ((cell, j) => {
			if (j > 0) {
				cell.innerText = line[j * 3 + 0];
				cell.setAttribute ('class', line[j * 3 + 1]);
				cell.setAttribute ('style', line[j * 3 + 2]);
			}
		});
	});
}
