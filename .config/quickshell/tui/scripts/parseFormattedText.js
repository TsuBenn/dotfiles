// ─── CellTextFormat parser ─────────────────────────────────────────────
//
// Converts a Markdown-like string into a flat list of {value, type} objects
// that a future CellTextFormat.qml component will render.
//
// Block-level types (one per output entry):
//   heading1 / heading2 / heading3      → "# H1", "## H2", "### H3"
//   paragraph                           → plain text line (may contain inline markup)
//   list_item_ordered                   → "1. item"  (value: { marker, text, level })
//   list_item_unordered                 → "- item"   (value: { marker, text, level })
//   code_block                          → fenced ``` block (value: { lang, code })
//   separator                           → "--- or ***
//   image                               → ![alt](src) on its own line (value: { alt, src })
//   blank                               → empty line (vertical spacer)
//
// Inline markup (carried inside the .value string of paragraph / list / heading entries):
//   <b>…</b>   bold         from **…** or __…__
//   <i>…</i>   italic       from *…* or _…_
//   <s>…</s>   strike       from ~~…~~
//   <code>…</code>          from `…`
//   <a href="url">label</a> from [label](url)
//   <img src="url" alt="…"> from ![alt](url) inside a paragraph
//   <br>                    from a hard line break (two trailing spaces + \n)
//
// These tags are exactly what CellText.richify() already understands, so
// the future QML component can pass `value` straight through to CellText.text.
//
// Design choices:
//   - Single-pass tokenizer, line-oriented for blocks.
//   - Inline parser uses a scanning regex with alternation rather than
//     nested replace() calls — keeps O(n) and avoids double-escaping bugs.
//   - Malformed input never throws: unclosed emphasis falls through as
//     literal text, unclosed link as literal `[label](url`.
//   - Indentation under a list line is tracked as `level` (0,1,2,...) so
//     the QML layer can indent nested lists.

function parseFormattedText(input) {
    if (input == null) return []
    const src = String(input)
    if (src.length === 0) return []

    const lines = src.split("\n")
    const out = []

    let i = 0
    while (i < lines.length) {
        const raw = lines[i]
        const line = raw.replace(/\s+$/, "")   // trim trailing whitespace (preserves hard-break detection if we add it later)

        // ── Blank line → blank spacer entry ──
        if (line.trim() === "") {
            out.push({ type: "blank", value: "" })
            i++
            continue
        }

        // ── Code fence: ```lang ... ``` ──
        const fenceMatch = line.match(/^```(\w*)\s*$/)
        if (fenceMatch) {
            const lang = fenceMatch[1] || ""
            const codeLines = []
            i++
            while (i < lines.length && !/^```\s*$/.test(lines[i])) {
                codeLines.push(lines[i])
                i++
            }
            // Skip closing fence (if present — graceful on EOF)
            if (i < lines.length) i++
            out.push({
                type: "code_block",
                value: { lang, code: codeLines.join("\n") }
            })
            continue
        }

        // ── Separator: --- or *** (3+ same chars, alone on line) ──
        if (/^(-{3,}|\*{3,}|_{3,})\s*$/.test(line)) {
            out.push({ type: "separator", value: "" })
            i++
            continue
        }

        // ── Heading: # / ## / ### (cap at 3 levels) ──
        const headingMatch = line.match(/^(#{1,3})\s+(.*)$/)
        if (headingMatch) {
            const level = headingMatch[1].length
            const text = headingMatch[2].trim()
            out.push({
                type: "heading" + level,
                value: parseInline(text)
            })
            i++
            continue
        }

        // ── List item (ordered or unordered, with indentation nesting) ──
        const listMatch = line.match(/^(\s*)(\d+\.|-|\*|\+)\s+(.*)$/)
        if (listMatch) {
            const indent = listMatch[1].replace(/\t/g, "    ").length
            const level = Math.floor(indent / 2)  // 2-space indent = 1 level
            const marker = listMatch[2]
            const text = listMatch[3]
            const isOrdered = /^\d+\.$/.test(marker)
            out.push({
                type: isOrdered ? "list_item_ordered" : "list_item_unordered",
                value: {
                    marker,
                    level,
                    text: parseInline(text)
                }
            })
            i++
            continue
        }

        // ── Standalone image: ![alt](src) on its own line ──
        const imageMatch = line.match(/^!\[([^\]]*)\]\(([^)\s]+)\)\s*$/)
        if (imageMatch) {
            out.push({
                type: "image",
                value: { alt: imageMatch[1], src: imageMatch[2] }
            })
            i++
            continue
        }

        // ── Blockquote: > text (treat as paragraph with a marker) ──
        const quoteMatch = line.match(/^>\s?(.*)$/)
        if (quoteMatch) {
            out.push({
                type: "quote",
                value: parseInline(quoteMatch[1])
            })
            i++
            continue
        }

        // ── Default: paragraph ──
        // Collect consecutive non-blank, non-special lines into one paragraph.
        const paraLines = [line]
        i++
        while (i < lines.length) {
            const next = lines[i].replace(/\s+$/, "")
            if (next.trim() === "") break
            if (/^```/.test(next)) break
            if (/^(-{3,}|\*{3,}|_{3,})\s*$/.test(next)) break
            if (/^(#{1,3})\s+/.test(next)) break
            if (/^(\s*)(\d+\.|-|\*|\+)\s+/.test(next)) break
            if (/^!\[([^\]]*)\]\(([^)\s]+)\)\s*$/.test(next)) break
            if (/^>\s?/.test(next)) break
            paraLines.push(next)
            i++
        }
        out.push({
            type: "paragraph",
            value: parseInline(paraLines.join("\n"))
        })
    }

    return out
}

// ─── Inline parser ─────────────────────────────────────────────────────
//
// Walks the input string with a single combined regex that matches any of:
//   **bold**       __bold__
//   *italic*       _italic_
//   ~~strike~~
//   `code`
//   ![alt](url)    [label](url)
//
// Anything between matches is escaped (entities) and emitted as plain text.
// Inline images inside paragraphs become <img> tags (the QML layer can
// decide whether to render them or strip them).
//
// Hard line breaks within a paragraph (\n inside the value) become <br>.

function parseInline(str) {
    if (!str) return ""

    // Combined regex — alternation order matters:
    //   1. Image  ![…]  (must come before link)
    //   2. Link    […]
    //   3. Bold+Italic  ***…***  (3 stars — must come before plain bold)
    //   4. Bold    **…** or __…__  (must come before italic — ** beats *)
    //   5. Italic  *…*   or _…_    (non-greedy, must not match across **)
    //   6. Strike  ~~…~~
    //   7. Code    `…`   (must be last — code content is verbatim)
    //
    // Italic regex uses (?!\s) and (?!\*) lookarounds so that:
    //   - `*italic*`                → matches
    //   - `**bold**`                → already eaten by bold branch above
    //   - `a * b * c`               → not italic (space after opening *)
    //
    // Note on ambiguous nesting: `**bold *both***` (2 opening, 3 closing)
    // is not handled as nested bold+italic — like CommonMark, we close bold
    // at the first `**`, leaving a trailing literal `*`. Users wanting
    // bold+italic should use the unambiguous `***both***` form, which
    // branch #3 handles cleanly.
    const re = /!\[([^\]]*)\]\(([^)\s]+)\)|\[([^\]]+)\]\(([^)\s]+)\)|\*\*\*([\s\S]+?)\*\*\*|\*\*([\s\S]+?)\*\*|__([\s\S]+?)__|\*(?!\s)([\s\S]+?)\*(?!\*)|_(?!\s)([\s\S]+?)_(?!_)|~~([\s\S]+?)~~|`([^`]+)`/g

    let result = ""
    let lastIndex = 0
    let m

    while ((m = re.exec(str)) !== null) {
        // Emit plain text before this match
        if (m.index > lastIndex) {
            result += escapeHtml(str.substring(lastIndex, m.index))
        }

        if (m[1] !== undefined) {
            // Image
            result += `<img src="${escapeAttr(m[2])}" alt="${escapeAttr(m[1])}">`
        } else if (m[3] !== undefined) {
            // Link
            result += `<a href="${escapeAttr(m[4])}">${parseInline(m[3])}</a>`
        } else if (m[5] !== undefined) {
            // Bold+Italic ***…***
            result += `<b><i>${parseInline(m[5])}</i></b>`
        } else if (m[6] !== undefined) {
            // Bold **…**
            result += `<b>${parseInline(m[6])}</b>`
        } else if (m[7] !== undefined) {
            // Bold __…__
            result += `<b>${parseInline(m[7])}</b>`
        } else if (m[8] !== undefined) {
            // Italic *…*
            result += `<i>${parseInline(m[8])}</i>`
        } else if (m[9] !== undefined) {
            // Italic _…_
            result += `<i>${parseInline(m[9])}</i>`
        } else if (m[10] !== undefined) {
            // Strike
            result += `<s>${parseInline(m[10])}</s>`
        } else if (m[11] !== undefined) {
            // Inline code — NO recursive parse (content is verbatim)
            result += `<code>${escapeHtml(m[11])}</code>`
        }

        lastIndex = re.lastIndex
    }

    // Tail
    if (lastIndex < str.length) {
        result += escapeHtml(str.substring(lastIndex))
    }

    // Newlines → <br> (CellText.richify already does this, but we may
    // have introduced them via multi-line paragraph collection).
    return result.replace(/\n/g, "<br>")
}

function escapeHtml(s) {
    if (s == null) return ""
    return String(s).replace(/[&<>"']/g, ch => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;"
    })[ch])
}

function escapeAttr(s) {
    if (s == null) return ""
    // For use inside attribute values: escape quotes + ampersand.
    return String(s).replace(/[&"]/g, ch => ({
        "&": "&amp;",
        '"': "&quot;"
    })[ch])
}

    function parseMarkdown(md, width = 80) {
        const lines = md.split('\n');
        const blocks = [];
        let inCodeBlock = false;
        let codeContent = [];

        // Helper 1: Escapes raw HTML entities to keep things safe
        const escapeHtml = str => {
            return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        };

        // Helper 2: Converts markdown emphasis symbols to HTML inline tags
        const processTextStyles = str => {
            let escaped = escapeHtml(str);
            escaped = escaped.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');
            escaped = escaped.replace(/\*(.*?)\*/g, '<i>$1</i>');
            escaped = escaped.replace(/~~(.*?)~~/g, '<s>$1</s>');
            return escaped;
        };

        // Helper 3: Tokenizes a string into discrete structural text/code/link/img entities
        const parseInline = text => {
            const regex = /(!?\[[^\]]*\]\([^)]+\)|`[^`]+`)/g;
            const parts = text.split(regex);
            const tokens = [];

            for (const part of parts) {
                if (!part)
                    continue;

                if (part.startsWith('`') && part.endsWith('`')) {
                    tokens.push({
                        type: 'code',
                        value: escapeHtml(part.slice(1, -1))
                    });
                } else if (part.startsWith('![')) {
                    const imgMatch = part.match(/!\[([^\]]*)\]\(([^)]+)\)/);
                    if (imgMatch) {
                        tokens.push({
                            type: 'img',
                            value: imgMatch[1],
                            data: imgMatch[2]
                        });
                    }
                } else if (part.startsWith('[')) {
                    const linkMatch = part.match(/\[([^\]]+)\]\(([^)]+)\)/);
                    if (linkMatch) {
                        tokens.push({
                            type: 'link',
                            value: processTextStyles(linkMatch[1]),
                            data: linkMatch[2]
                        });
                    }
                } else {
                    tokens.push({
                        type: 'text',
                        value: processTextStyles(part)
                    });
                }
            }
            return tokens;
        };

        // Helper 4: Breaks structured tokens into line chunks without chopping open HTML tags
        const wrapTokens = (tokens, maxWidth) => {
            const wrappedLines = [];
            let currentLine = [];
            let currentLen = 0;
            let activeTags = [];

            for (const token of tokens) {
                if (token.type === 'text') {
                    const parts = token.value.split(/(<\/?(?:b|i|s)>|\s+)/).filter(Boolean);

                    for (const part of parts) {
                        if (part.match(/^<\/?(?:b|i|s)>$/)) {
                            if (part.startsWith('</')) {
                                activeTags.pop();
                            } else {
                                activeTags.push(part);
                            }

                            if (currentLine.length > 0 && currentLine[currentLine.length - 1].type === 'text') {
                                currentLine[currentLine.length - 1].value += part;
                            } else {
                                currentLine.push({
                                    type: 'text',
                                    value: part
                                });
                            }
                            continue;
                        }

                        const visibleLen = part.replace(/<[^>]*>/g, '').length;

                        if (currentLen + visibleLen > maxWidth && currentLen > 0 && part.trim() !== "") {
                            if (currentLine.length > 0 && currentLine[currentLine.length - 1].type === 'text') {
                                for (let i = activeTags.length - 1; i >= 0; i--) {
                                    currentLine[currentLine.length - 1].value += activeTags[i].replace('<', '</');
                                }
                            }

                            wrappedLines.push(currentLine);
                            currentLine = [];
                            currentLen = 0;

                            const reopenedTags = activeTags.join('');
                            currentLine.push({
                                type: 'text',
                                value: reopenedTags + part
                            });
                        } else {
                            if (currentLine.length > 0 && currentLine[currentLine.length - 1].type === 'text') {
                                currentLine[currentLine.length - 1].value += part;
                            } else {
                                currentLine.push({
                                    type: 'text',
                                    value: part
                                });
                            }
                        }
                        currentLen += visibleLen;
                    }
                } else {
                    const visibleLen = token.value.length;
                    if (currentLen + visibleLen > maxWidth && currentLen > 0) {
                        wrappedLines.push(currentLine);
                        currentLine = [];
                        currentLen = 0;
                    }
                    currentLine.push(token);
                    currentLen += visibleLen;
                }
            }
            if (currentLine.length > 0)
                wrappedLines.push(currentLine);
            return wrappedLines.length > 0 ? wrappedLines : [[]];
        };

        // Main Engine Loop: Block Level Line Tokenizer
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            if (line.trim().startsWith('```')) {
                if (inCodeBlock) {
                    blocks.push({
                        type: 'code_block',
                        value: codeContent.join('\n')
                    });
                    inCodeBlock = false;
                    codeContent = [];
                } else {
                    inCodeBlock = true;
                }
                continue;
            }
            if (inCodeBlock) {
                codeContent.push(line);
                continue;
            }

            if (line.trim() === '') {
                blocks.push({
                    type: 'blank'
                });
                continue;
            }
            if (/^(---|\*\*\*|___)$/.test(line.trim())) {
                blocks.push({
                    type: 'separator'
                });
                continue;
            }

            const headingMatch = line.match(/^(#{1,6})\s+(.*)/);
            if (headingMatch) {
                blocks.push({
                    type: `h${headingMatch[1].length}`,
                    value: wrapTokens(parseInline(headingMatch[2]), width)
                });
                continue;
            }

            const quoteMatch = line.match(/^(\s*)(>+)\s+(.*)/);
            if (quoteMatch) {
                blocks.push({
                    type: 'quote',
                    level: quoteMatch[1].length / 4 | 0,
                    value: wrapTokens(parseInline(quoteMatch[3]), width)
                });
                continue;
            }

            const ulMatch = line.match(/^(\s*)([-*+])\s+(.*)/);
            if (ulMatch) {
                blocks.push({
                    type: 'unordered_list',
                    marker: ulMatch[2],
                    level: ulMatch[1].length / 4 | 0,
                    value: wrapTokens(parseInline(ulMatch[3]), width - 2 - ulMatch[2].length - 2 * (ulMatch[1].length / 4 | 0))
                });
                continue;
            }

            const olMatch = line.match(/^(\s*)(\d+)\.\s+(.*)/);
            if (olMatch) {
                blocks.push({
                    type: `ordered_list`,
                    marker: olMatch[2],
                    level: olMatch[1].length / 4 | 0,
                    value: wrapTokens(parseInline(olMatch[3]), width - 3 - olMatch[2].length - 2 * (olMatch[1].length / 4 | 0))
                });
                continue;
            }

            const blockImgMatch = line.match(/^\s*!\[([^\]]*)\]\(([^)]+)\)\s*$/);
            if (blockImgMatch) {
                blocks.push({
                    type: 'img',
                    value: blockImgMatch[1] // alt text
                    ,
                    data: blockImgMatch[2]   // path or link
                });
                continue;
            }

            // Paragraph Fallback
            blocks.push({
                type: 'p',
                value: wrapTokens(parseInline(line), width)
            });
        }

        return blocks;
    }

// Try running this test case!
const testMarkdown = `
### Headings

This is a **normal text**, it can have \`inline code\` and [hyper link](https://example.com)

1. This is an *ordered* list

* This is an *unordered* list

> This is a quote - me
   > This is an indented quote - also me

\`\`\`

This is a code block

\`\`\`

![image](path/to/image)
---
`;

console.log(JSON.stringify(parseMarkdown(testMarkdown, 20), null, 2));
