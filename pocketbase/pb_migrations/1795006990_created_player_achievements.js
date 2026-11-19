/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "createRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"sponsor\")",
    "deleteRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"sponsor\")",
    "fields": [
      {
        "autogeneratePattern": "[a-z0-9]{15}",
        "hidden": false,
        "id": "text3208210256",
        "max": 15,
        "min": 15,
        "name": "id",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": true,
        "required": true,
        "system": true,
        "type": "text"
      },
      {
        "cascadeDelete": false,
        "collectionId": "pbc_3072146508",
        "hidden": false,
        "id": "relation2551806565",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "player",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "cascadeDelete": false,
        "collectionId": "pbc_2260351736",
        "hidden": false,
        "id": "relation2524151793",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "achievement",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      }
    ],
    "id": "pbc_296355926",
    "indexes": [
      "CREATE UNIQUE INDEX `idx_player_ach` ON `player_achievements` (`player`, `achievement`)"
    ],
    "listRule": "@request.auth.id != \"\"",
    "name": "player_achievements",
    "system": false,
    "type": "base",
    "updateRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"sponsor\")",
    "viewRule": "@request.auth.id != \"\""
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_296355926");

  return app.delete(collection);
})
