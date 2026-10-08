// Standard formatting symbols are local vector paths, independent of the current locale.
// The enclosing native HTML button supplies the translated tooltip and accessible name.
const paths = Object.freeze({
  bold: ['M6 4h6a4 4 0 0 1 0 8H6z M6 12h7a4 4 0 0 1 0 8H6z'],
  italic: ['M10 4h9 M5 20h9 M15 4 9 20'],
  bulletList: ['M9 6h11 M9 12h11 M9 18h11', 'M4 6h.01 M4 12h.01 M4 18h.01'],
  orderedList: ['M10 7h10 M10 17h10', 'M3 4h1v6 M3 10h2 M2.5 15.5a1.5 1.5 0 0 1 3 0c0 1-3 2-3 4.5h3'],
  heading: ['M5 4v16 M19 4v16 M5 12h14'],
  undo: ['M8 4 3 9l5 5 M3 9h11a6 6 0 0 1 0 12'],
  redo: ['M16 4 21 9l-5 5 M21 9H10a6 6 0 0 0 0 12']
});

export function createToolbarIcon(key, document) {
  const namespace = 'http://www.w3.org/2000/svg';
  const icon = document.createElementNS(namespace, 'svg');
  for (const [name, value] of Object.entries({ viewBox: '0 0 24 24', fill: 'none',
    stroke: 'currentColor', 'stroke-width': key === 'bold' ? '2.5' : '2',
    'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'aria-hidden': 'true', focusable: 'false',
    class: 'toolbar-icon' })) icon.setAttribute(name, value);
  for (const data of paths[key]) {
    const path = document.createElementNS(namespace, 'path');
    path.setAttribute('d', data); icon.appendChild(path);
  }
  return icon;
}
