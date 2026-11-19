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
        "collectionId": "pbc_1568971955",
        "hidden": false,
        "id": "relation3303056927",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "team",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "cascadeDelete": false,
        "collectionId": "_pb_users_auth_",
        "hidden": false,
        "id": "relation2173487572",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "sponsor",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "hidden": false,
        "id": "number2484321137",
        "max": null,
        "min": 0,
        "name": "salary",
        "onlyInt": false,
        "presentable": false,
        "required": true,
        "system": false,
        "type": "number"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text3065852031",
        "max": 2000,
        "min": 0,
        "name": "message",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "select2063623452",
        "maxSelect": 1,
        "name": "status",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "select",
        "values": [
          "pending",
          "accepted",
          "rejected"
        ]
      },
      {
        "hidden": false,
        "id": "date2598124290",
        "max": "",
        "min": "",
        "name": "deletedAt",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "date"
      }
    ],
    "id": "pbc_3508122758",
    "indexes": [],
    "listRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"sponsor\")",
    "name": "transfer_offers",
    "system": false,
    "type": "base",
    "updateRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"sponsor\")",
    "viewRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"sponsor\")"
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3508122758");

  return app.delete(collection);
})
