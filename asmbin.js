import { argv, exit } from "node:process";
import * as asm from "./asmlib.js";
import * as fileSystem from "node:fs";

let asmFile = argv[2];
let outpudFile = argv[3];
let asmFileContent = fileSystem.readFileSync(asmFile, 'utf-8');

let resulta = asm.codeToInstrs(asmFileContent);
let result = resulta.result;
let hex = result.map(b => b.toString(16).padStart(2, '0')).join('\n');

//console.log(resulta);

if (argv.includes('-list')) {
    let narg = argv.indexOf('-list');
    let list = resulta.list;
    let itisit = []
    for (const it of Object.getOwnPropertyNames(list)) {
        let val = list[it];
        let lst = val;
        let sta = [];
        for (const ele of lst) {
            sta.push(`${Number(it).toString(16).padStart(6, '0')} ${ele.instr.map(v => Number(v).toString(16).padStart(2,'0')).join(" ").padEnd(16, ' ')} ${ele.line}`);
        }
        itisit.push(...sta);
    }
    fileSystem.writeFileSync(argv[narg+1], itisit.map(v => v.trimEnd()).join("\n"));
}

if (argv.includes("-d")) {
    hex = result.map(b => b.toString()).join('\n');
}
else if (argv.includes("-rbin")) {
    fileSystem.writeFileSync(outpudFile, Buffer.from(result));
    exit(0);
}

fileSystem.writeFileSync(outpudFile, hex);