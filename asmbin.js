import { argv, exit } from "node:process";
import * as asm from "./asmlib.js";
import * as fileSystem from "node:fs";

let asmFile = argv[2];
let outpudFile = argv[3];
let asmFileContent = fileSystem.readFileSync(asmFile, 'utf-8');

let resulta = asm.codeToInstrs(asmFileContent);
let result = resulta.result;
let hex = result.map(b => b.toString(16).padStart(2, '0')).join('\n');

console.log(resulta);

if (argv.includes("-d")) {
    hex = result.map(b => b.toString()).join('\n');
}
else if (argv.includes("-rbin")) {
    fileSystem.writeFileSync(outpudFile, Buffer.from(result));
    exit(0);
}

fileSystem.writeFileSync(outpudFile, hex);