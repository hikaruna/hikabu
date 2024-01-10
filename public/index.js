//@ts-check

import { default as sqlite3InitModule } from "@sqlite.org/sqlite-wasm";




const sqlite3 = await sqlite3InitModule();
const oo = sqlite3.oo1;

function importDb() {

  const sqlFilePath = '/production.sqlite3';
  const response = await fetch(sqlFilePath);
  const arrayBuffer = await response.arrayBuffer();
  const db = new oo.DB();
  const p = sqlite3.wasm.allocFromTypedArray(arrayBuffer);
  db.onclose = { after: function () { sqlite3.wasm.dealloc(p) } };

  const rc = sqlite3.capi.sqlite3_deserialize(
    // @ts-ignore
    db.pointer,
    'main',
    p,
    arrayBuffer.byteLength,
    arrayBuffer.byteLength,
    0
  );
  db.checkRc(rc);

  let query = "SELECT * FROM stocks";
  let contents = db.exec(query);
  let res = JSON.stringify(contents);
  console.log("transient db =", db.filename);
  const selectedValue = db.selectValues('SELECT code FROM stocks')
  console.log(selectedValue);
}
