/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "createRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"scout\")",
    "deleteRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"scout\")",
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
        "collectionId": "_pb_users_auth_",
        "hidden": false,
        "id": "relation392724836",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "scout",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "hidden": false,
        "id": "number3632866850",
        "max": 10,
        "min": 1,
        "name": "rating",
        "onlyInt": true,
        "presentable": false,
        "required": true,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "select587532947",
        "maxSelect": 1,
        "name": "verdict",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "select",
        "values": [
          "recommend",
          "watch",
          "reject"
        ]
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text3458754147",
        "max": 2000,
        "min": 1,
        "name": "summary",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
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
    "id": "pbc_549778155",
    "indexes": [],
    "listRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"scout\")",
    "name": "scout_reports",
    "system": false,
    "type": "base",
    "updateRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"scout\")",
    "viewRule": "@request.auth.id != \"\" && (@request.auth.role = \"admin\" || @request.auth.role = \"scout\")"
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_549778155");

  return app.delete(collection);
})
