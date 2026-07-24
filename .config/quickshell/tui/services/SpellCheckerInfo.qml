pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var results: []

    property bool active: false
    property bool correct: false

    function check(text: string) {
        correct = false;
        if (process.running) {
            process.write(text + "\n");
        }
    }

    function parseSpellcheckOutput(rawOutput) {
        // Split the output line into individual word tokens by whitespace
        const tokens = rawOutput.trim().split(/\s+/);

        return tokens.map(token => {
            const changes = [];
            let formattedWord = '';

            // Regex explanation:
            // 1. \+\+(.*?)\+\+              Matches ++char++ (Add/Insert)
            // 2. --(.*?)--                  Matches --char-- (Delete)
            // 3. ~~(.*?)\->(.*?)~~        Matches ~~char->char~~ (Replace)
            // 3. ~~(.*?)<\->(.*?)~~        Matches ~~char->char~~ (Replace)
            // 4. ([^+~-]+)                  Matches normal unchanged characters
            const tokenRegex = /\+\+(.*?)\+\+|--(.*?)--|~~(.*?)<\->(.*?)~~|~~(.*?)->(.*?)~~|([^+~-]+)/g;

            let match;
            while ((match = tokenRegex.exec(token)) !== null) {
                if (match[1] !== undefined) {
                    // Insert / Add
                    const char = match[1];
                    changes.push({
                        type: 'insert',
                        char
                    });
                    formattedWord += char;
                } else if (match[2] !== undefined) {
                    // Delete
                    const char = match[2];
                    changes.push({
                        type: 'delete',
                        char
                    });
                    // Deleted char is skipped in the final word representation
                } else if (match[3] !== undefined && match[4] !== undefined) {
                    // Replace
                    const from = match[3];
                    const to = match[4];
                    changes.push({
                        type: 'transpose',
                        from,
                        to
                    });
                    formattedWord += from + to;
                } else if (match[5] !== undefined && match[6] !== undefined) {
                    // Replace
                    const from = match[5];
                    const to = match[6];
                    changes.push({
                        type: 'replace',
                        from,
                        to
                    });
                    formattedWord += to;
                } else if (match[7] !== undefined) {
                    // Match / Unchanged
                    const chars = match[7];
                    for (const char of chars) {
                        changes.push({
                            type: 'match',
                            char
                        });
                        formattedWord += char;
                    }
                }
            }

            return {
                rawToken: token,
                word: formattedWord,
                changes
            };
        });
    }

    Process {
        id: process

        onRunningChanged: root.correct = false
        running: root.active
        command: [SystemInfo.configdir + "/scripts/spellchecker"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: text => {
                if (text) {
                    if (text.trim() == "*") {
                        root.correct = true;
                        root.results = [];
                    } else {
                        const suggestions = root.parseSpellcheckOutput(text);
                        root.results = suggestions;
                    }
                    // console.log(JSON.stringify(root.results, null, 2));
                }
            }
        }
    }
}
