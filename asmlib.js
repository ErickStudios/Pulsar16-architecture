function tokenize(code) {
    const tokens = [];
    let i = 0;
    const isLetter = (c) => /[a-zA-Z_]/.test(c);
    const isNumber = (c) => /[0-9]/.test(c);
    while (i < code.length) {
        let c = code[i];
        if (/\s/.test(c)) {
            i++;
            continue;
        }
        if (c === "/" && code[i + 1] === "/") {
            while (i < code.length && code[i] !== "\n") {
                i++;
            }
            continue;
        }
        if (c === "'") {
            let quoteType = c;
            let value = "";
            i++;
            while (i < code.length && code[i] !== quoteType) {
                value += code[i++];
            }
            i++;
            for (let a = 0; a < value.length; a++) {
                tokens.push({ type: "number", value: value.charCodeAt(a) });
                if (a !== (value.length - 1)) {
                    tokens.push({ type: "symbol", value: ',' });
                }
            }
            continue;
        }
        if (isLetter(c)) {
            let value = "";
            while (i < code.length && (isLetter(code[i]) || isNumber(code[i]))) {
                value += code[i++];
            }
            tokens.push({ type: "identifier", value });
            continue;
        }
        if (isNumber(c)) {
            let value = "";

            while (
                i < code.length &&
                (
                    isNumber(code[i]) ||
                    "ABCDEFabcdef".includes(code[i])
                )
            ) {
                value += code[i++];
            }

            if (
                i < code.length &&
                code[i].toLowerCase() === "h"
            ) {
                i++;
                value = parseInt(value, 16);
            }
            else if (value === "0" && code[i] === "x") {
                i++;
                let value2 = "";
                while (i < code.length && (isNumber(code[i]) || ['A', 'B', 'C', 'D', 'E', 'F'].includes(code[i].toUpperCase()))) {
                    value2 += code[i++];
                }
                value = parseInt(value2, 16);
            }
            else {
                value = Number(value);
            }

            tokens.push({
                type: "number",
                value
            });

            continue;
        }
        tokens.push({ type: "symbol", value: c });
        i++;
    }
    return tokens;
}
export class Context {
    constructor() {
        this.symbs = new Map();
        this.codeLen = 0;
        this.currentIp = 0;
        this.currentLabel = 'start';
        this.result = [];
    }
}
/** @param {Context} context  */
export function lineToInstr(line, context) {
    let toks = tokenize(line);
    let i = 0;
    function peek() {
        return toks[i];
    }
    function consume() {
        return toks[i++];
    }
    function expect(v) {
        let c = peek().value;
        if (c !== v) {
            throw new Error(`expected: ${v}`);
        }
        return consume();
    }
    let result = [];
    function oprGetId(name) {
        if (name == "add") return 0;
        if (name == "sub") return 1;
        if (name == "mov") return 2;
        if (name == "cmp") return 3;

        return null;
    }
    function lsGetId(name) {
        if (name == 'load') return 0;
        if (name == 'store') return 1;
        return null;
    }
    function indexGetId(name) {
        if (name == 'a') return 0;
        if (name == 'b') return 1;
        if (name == 'c') return 2;
        if (name == 'd') return 3;
        if (name == 'e') return 4;
        if (name == 'f') return 5;
        if (name == 'g') return 6;
        if (name == 'h') return 7;
        if (name == 'i') return 8;
        if (name == 'j') return 9;
        if (name == 'k') return 10;
        return null;
    }
    function valueGetId(name) {
        if (name == 'a') return 0;
        if (name == 'hi') return 1;
        if (name == 'jk') return 2;
        if (name == 'fg') return 3;

        return null;
    }
    function xdrsGetId(name) {
        if (name == 'dbc') return 0;
        if (name == 'ebc') return 1;
        if (name == 'dfg') return 2;
        if (name == 'efg') return 3;
        return null;
    }
    function jmpGetId(name) {
        if (name == 'jmp') return 0;
        if (name == 'call') return 1;
        if (name == 'jz') return 2;
        if (name == 'jn') return 3;

        return null;
    }
    function parseSyntx() {
        if (peek().value == '(') {
            consume();
            let result = parseSyntx();
            while (peek() && peek().value != ')') {
                if (peek().value !== ')') {
                    let xc = consume().value;
                    if (xc == '+') result = result + parseSyntx();
                    else if (xc == '-') result = result - parseSyntx();
                    else if (xc == '*') result = result * parseSyntx();
                    else if (xc == '/') result = result / parseSyntx();
                }
            }
            consume();
            return result;
        }
        if (peek().value == '.') {
            consume();
            return context.symbs.get(context.currentLabel + '.' + consume().value);
        }
        if (peek().value == '$') {
            consume();
            return context.currentIp;
        }
        if (peek().value == 'offs8') {
            consume();
            let syn = parseSyntx();
            syn = syn - context.currentIp;
            if (syn < 0) {
                syn = 0x80 | (-syn);
            }
            return syn & 0xFF;
        }
        if (context.symbs.has(peek().value)) {
            return context.symbs.get(consume().value);
        }
        if (peek().type !== 'number') {
            consume();
            return 0;
        }
        return consume().value;
    }
    function parseSize(name) {
        switch (name) {
        case 'db': return 1;
        case 'dw': return 2;
        case 'dd': return 4;
        case 'dq': return 8;
        }
    }
    function toBigEndianBytes(n, x) {
        let bytes = [];
        while (n > 0) {
            bytes.push(n & 0xFF);
            n = n >>> 8;
        }
        bytes.reverse();
        while (bytes.length < x) {
            bytes.unshift(0);
        }
        return bytes;
    }
    while (i < toks.length) {
        if (peek().value == ';') {
            return result;
        }
        else if (peek().value == 'ret') {
            consume();
            result.push(0x41, 0x00);
        }
        else if (peek().value == 'cmpw') {
            consume();
            let rDst = valueGetId(consume().value);
            expect(",")
            let rSrc = valueGetId(consume().value);
            result.push(0x42, (rDst << 4) | rSrc);
        }
        else if (peek().value == 'addw') {
            consume();
            let rDst = valueGetId(consume().value);
            expect(",")
            let rSrc = valueGetId(consume().value);
            result.push(0x43, (rDst << 4) | rSrc);
        }
        else if (peek().value == 'mul') {
            consume();
            let rDst = valueGetId(consume().value);
            expect(",")
            let rSrc = valueGetId(consume().value);
            result.push(0x40, (rDst << 4) | rSrc);
        }
        else if (jmpGetId(peek().value) !== null) {
            let oSrc = jmpGetId(consume().value);
            result.push(0x30 | oSrc, parseSyntx());
        }
        else if (oprGetId(peek().value) !== null) {
            let oSrc = oprGetId(consume().value);
            let rDst = indexGetId(consume().value);
            expect(',');
            if (indexGetId(peek().value) == null && oSrc == 2) {
                result.push(0x00 | rDst, parseSyntx());
            }
            else {
                result.push(0x10 | oSrc, (rDst << 4) | indexGetId(consume().value));
            }
        }
        else if (lsGetId(peek().value) !== null) {
            let oSrc = lsGetId(consume().value);
            let rAddr = xdrsGetId(consume().value);
            expect(",");
            let vSrc = valueGetId(consume().value);
            result.push(0x20 | rAddr, (oSrc << 4) | vSrc);
        }
        else if (peek().value == 'lea') {
            consume();
            let xDupl = consume().value;
            expect(",");
            let ps = parseSyntx();
            let x1 = indexGetId(xDupl[0]);
            let x2 = indexGetId(xDupl[1]);
            result.push(0x00 | x1, ((ps >> 8) & 0xFF));
            result.push(0x00 | x2, ps & 0xFF);
        }
        else if (parseSize(peek().value) !== undefined) {
            let sizeof = parseSize(consume().value);
            let primarys = toBigEndianBytes(parseSyntx(), sizeof);
            while (peek() && peek().value === ",") {
            consume();
            primarys.push(...toBigEndianBytes(
                parseSyntx(), sizeof
            ));
            }
            result.push(...primarys);
        }
        else if (peek().value == 'reserve') {
            consume();
            let sx = parseSyntx();
            result.push(...(new Array(sx).fill(0)));
        }
        else if (peek().value == '.') {
            consume();
            let ident = consume().value;
            expect(":");
            context.symbs.set(context.currentLabel + '.' + ident, context.currentIp);
        }
        else if (peek().type == 'identifier') {
            let ident = consume().value;
            if (peek().value == 'equ') {
                consume();
                context.symbs.set(ident, parseSyntx())
            }
            else {
                expect(":");
                context.currentLabel = ident
                context.symbs.set(ident, context.currentIp)
            }
        }
    }
    return result;
}
/** @param {string} code  */
export function codeToInstrs(code) {
    let ctx = new Context();
    let lines = code.split("\n");
    lines.forEach(line => {
        let instr = lineToInstr(line, ctx);
        ctx.currentIp += instr.length;
    });
    ctx.currentIp = 0;
    lines.forEach(line => {
        let instr = lineToInstr(line, ctx);
        ctx.result.push(...instr);
        ctx.currentIp += instr.length;
    })
    return ctx;
}