import { getSchema, Node, mergeAttributes } from '@tiptap/core';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';
import Table from '@tiptap/extension-table';
import TableRow from '@tiptap/extension-table-row';
import TableHeader from '@tiptap/extension-table-header';
import TableCell from '@tiptap/extension-table-cell';
import { yDocToProsemirrorJSON } from 'y-prosemirror';

function embed(name, attributes, dataAttribute, labels) {
  return Node.create({
    name, group: 'block', atom: true, selectable: true, draggable: true,
    addAttributes() {
      return Object.fromEntries(attributes.map(key => {
        const attribute = key === 'taskId' ? 'data-task-id' : `data-${key}`;
        return [key, { default: null, parseHTML: element => element.getAttribute(attribute),
          renderHTML: values => values[key] ? { [attribute]: values[key] } : {} }];
      }));
    },
    parseHTML() { return [{ tag: `div[${dataAttribute}]` }]; },
    renderHTML({ HTMLAttributes }) { return ['div', mergeAttributes(HTMLAttributes, { [dataAttribute]: '' })]; },
    addNodeView() {
      return ({ node }) => {
        const dom = document.createElement('div'); dom.className = 'task-embed'; dom.contentEditable = 'false';
        const update = current => {
          // These remain reference blocks. Task fetching/editing stays in the native project UI.
          dom.textContent = current.attrs.label || labels()[name] || '';
          dom.dataset.nodeType = name;
        };
        update(node);
        return { dom, update(current) { if (current.type.name !== name) return false; update(current); return true; } };
      };
    }
  });
}

export function baseExtensions(labels = () => ({})) {
  return [StarterKit.configure({ history: false }), Image, Table.configure({ resizable: true }),
    TableRow, TableHeader, TableCell,
    embed('taskEmbed', ['taskId'], 'data-task-embed', labels),
    embed('taskListEmbed', ['status', 'label'], 'data-task-list-embed', labels)];
}

export function makeSchema() { return getSchema(baseExtensions()); }

/** ProseMirror otherwise drops unsupported attributes; fail before any editable conversion. */
export function validateContent(content, schema) {
  const visit = node => {
    if (!node || typeof node !== 'object' || Array.isArray(node) || typeof node.type !== 'string') throw new Error('invalid_content');
    const type = schema.nodes[node.type];
    if (!type) throw new Error('unsupported_content');
    if (Object.keys(node).some(key => !['type', 'attrs', 'marks', 'content', 'text'].includes(key))) throw new Error('unsupported_content');
    checkAttrs(node.attrs, type.spec.attrs);
    if (node.marks !== undefined) {
      if (!Array.isArray(node.marks)) throw new Error('invalid_content');
      for (const mark of node.marks) {
        const markType = schema.marks[mark?.type];
        if (!markType || Object.keys(mark).some(key => !['type', 'attrs'].includes(key))) throw new Error('unsupported_content');
        checkAttrs(mark.attrs, markType.spec.attrs);
      }
    }
    if (node.content !== undefined) {
      if (!Array.isArray(node.content)) throw new Error('invalid_content');
      node.content.forEach(visit);
    }
  };
  visit(content);
  if (content.type !== 'doc') throw new Error('invalid_content');
  // An empty Yjs fragment is a valid newly-created note. Only its empty document is normalized.
  const checked = !content.content?.length ? { ...content, content: [{ type: 'paragraph' }] } : content;
  try { schema.nodeFromJSON(checked).check(); } catch { throw new Error('invalid_content'); }
  return checked;
}

function checkAttrs(attributes, known = {}) {
  if (attributes === undefined) return;
  if (!attributes || typeof attributes !== 'object' || Array.isArray(attributes)) throw new Error('invalid_content');
  if (Object.keys(attributes).some(key => !Object.prototype.hasOwnProperty.call(known, key))) throw new Error('unsupported_content');
}

export function contentFromDoc(doc, schema) {
  if ([...doc.share.keys()].some(key => key !== 'default')) throw new Error('unsupported_content');
  return validateContent(yDocToProsemirrorJSON(doc, 'default'), schema);
}
