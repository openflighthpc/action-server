# API and Routes Documentation

This API broadly conforms the [JSON:API Specifications](https://jsonapi.org/). The major deviations are:
1. The resource's `id` are alphanumeric and are quasi dependent on the attributes,

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

## Nodes

### ID

The ID for a `node` is MUST be the same as its `name`. This means the `id` SHOULD be `alphanumeric` but MAY contain `-_`.

### List

Return a list of the available `nodes`.

```
GET /nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Node-Resource-Object>, ...],
  ... see JSON:API spec ...
}
```

### Show

Return a single `node` by its ID

```
GET /nodes/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "nodes",
    "id": "<name>",
    "attributes": {
      "name": "<name>",
    },
    "links": ... see JSON:API spec ...

  }, ... see JSON:API spec ...
}
```

## Groups

### ID

The `id` of the group is dependant of the mode the server is in. In general, the `id` SHOULD be alphanumeric but MAY contain the following: `,_-[]`. Not all combinations of the valid symbols will produce a valid `id`, this behaviour is mode specific.

*Exploding Mode*

When in exploding mode, the `id` represents comma separated list of `node` names. Refer to the `Node#ID` section for valid `node_id` syntax.

Multiple `node_id` can be joined together as a single group as a comma separated list.
E.G. `node1,node2` would be a group containing `node1`, and `node2`.

Multiple nodes maybe generated using a "range expression". All range expressions must follow the following syntax: `\w+[\d+-\d+]`. There must be a starting "base name" which SHOULD be alphanumeric but MAY contain `-` and `_`. The range expression MUST be two non negative integers separated by a hyphen contained within brackets. This will cause the parser to repeat the "base name" for every integer within the inclusive range.

*NOTE*: Whilst the first integer SHOULD be smaller then the second integer, this is not an enforced constraint. All other ranges are considered "valid" syntactically but may have surprising results. When the two integers are equal, it will generate a single node range. If the first integer is larger, than it will generate an empty range.

It is possible to pad the indices by ending the "base name" with trailing zeros. The minimum character width of indices is equal to the number of zeros plus one. An indices width is padded up to the minimum width by adding leading zero characters.
*NOTE*: Any padding zeros within the range brackets MUST be ignored; but the syntax is otherwise valid.

*Example Range Expressions*
```
node[0-3]
node0,node1,node2,node3

node[001-03]
node1,node2,node3

node[1-1]
node1

node[2-1]
# noop - Valid syntax but otherwise generates an empty list

node00[98-101]
node098,node099,node100,node101

node0[019-0020]
node19,node20

node01,node0[3-5]
node01,node03,node04,node05
```

### List

Returns a list of static groups. This will always be an empty array in exploding mode.
*TBA*: Returns a list of statically configured groups in upstream mode.

```
GET /groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Group-Resource-Object>, ...],
  ... see JSON:API spec ...
}
```

### Show

Return a single `group` by its ID. It is possible to show groups that do not appear in the list due to the ephemeral nature.
  
The related `nodes` resource will contain a different set of `node` resources depending on the mode.

In exploding mode, the set of `nodes` is determined by the name expansion first, which is then filtered to remove any missing nodes. This means nodes my be missing from the set even if they are specified in the range.

```
GET /groups/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "groups",
    "id": "<name>",
    "attributes": {
      "name": "<name>",
    },
    "relationship": {
      "nodes": {
        "data": [<Node-Resource-Identifier-Object>, ...],
        "links": ... see JSON:API spec
      }
    },
    "links": ... see JSON:API spec ...
  }, ... see JSON:API spec ...
}
```

## Commands

### ID

The ID for a `command` is generally intended to be command line friendly. As such it SHOULD be alphanumeric and MAY contain hypens; but MUST NOT contain underscores.

### List

Return all the available commands.

```
GET /commands
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Command-Resource-Object>, ...],
  ... see JSON:API spec ...
}
```

### Show

Return a single `command` by its ID. The `name`, `summary`, and `description` attributes can be used to generate command line help text.

```
GET /commands/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "commands",
    "id": "<name>",
    "attributes": {
      "name": "<name>",
      "summary": "<summary>",
      "description": "<description">
    },
    "links": ... see JSON:API spec ...
  }, ... see JSON:API spec ...
}
```

## Jobs

A `job` is a completely virtual resource that does not have any dedicated end points. Instead they are returned as part of a relationship to `tickets`. They are not persisted on the server and can not be directly created or destroyed.

### ID

The ID for a `job` resource MUST be alphanumeric.

### Resource Object

The `job` resource object has the following syntax. The `stdout`, `stderr`, and `status` are from the system command associated with the `job`. The `stdout` and `stderr` will be strings, where `status` is an integer.

```
{
  "type": "jobs",
  "id": "<id>",
  "attributes": {
    "stdout": "<stdout>",
    "stderr": "<srderr>",
    "status": <status>
  },
  "relationships": {
    "node": <Node-Resource-Identifier-Object>,
    "ticket": <Ticket-Resource-Identifier-Object>
  },
  ... see JSON:API spec ...
}
```

## Ticket

A `ticket` is an ephemeral resource that only exists when they are created. They are not persisted on the server and can not be recalled or indexed at a latter date.

### ID

The ID for a `ticket` MUST be alphanumeric.

### Create

Creating a `ticket` is dedicated way to run `jobs` through the API. When creating a `ticket`, the `command` and `context` relationships SHOULD be specified. Whilst the request MAY omit these relationships the response SHALL return `201 CREATED` with a blank association with the `jobs` resource; and SHALL include the other relevant related resources.

The `context` MUST be either a `group` or `node` resource identifier object. Requests with a `node context` SHOULD create a `ticket` with a single entity `jobs` resource for the `node`. Requests with `node context` MAY return an empty `jobs` resource if the `node` is missing. Requests with a `group context` SHOULD return a `jobs` resource containing a `job` for each `node` within the `group`. The `jobs` resource SHALL NOT contain `jobs` for missing nodes.

The response MAY contain a `true` attribute with value `true`. This is a compatibility fix with clients that are not fully JSON:API compliant. The `true` attribute MAY be permanently removed without notice.

This method "creates" an ephemeral `ticket` resource that only lives during the lifetime of the request. The ticket SHALL NOT be saved and/or persisted after the response has been issued. Due to this ephemeral nature the response SHALL include the related `command`, `context`, `jobs`, `jobs.node` resources. The request SHOULD NOT specify an `include` query as it SHALL be ignored.

The life cycle of a request SHOULD complete the following stages:
* Identify the `context` and generate a `nodes` list,
* Build the `jobs` resource from the `nodes` list and `command`,
* Run each `job`, and
* Issues a synchronous response to the client.
[Refer here for further details](ticket-lifecycle.md)

```
POST /tickets
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "tickets",
    "relationships": {
      "context": {
        "data": <Group-or-Node-Resource-Identifier-Object>
      },
      "command": {
        "data": <Command-Resource-Identifier-Object>
      }
    },
    "links": ... see JSON:API spec ...
  }, ... see JSON:API spec ...
}

HTTP/1.1 201 CREATED
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "tickets",
    "id": "<id>",
    "attributes": {
      "true": true
    },
    "relationships": {
      "command": {
        "data": <Command-Resource-Identifier-Object>,
        "links": ... see JSON:API spec ...
      },
      "context": {
        "data": <Group-or-Node-Resource-Identifier-Object>,
        "links": ... see JSON:API spec ...
      },
      "jobs": {
        "data": [<Job-Resource-Identifier-Object>, ...]
      }
    },
    "links": ... see JSON:API spec ...
  },
  included: [<Command-Group-Node-or-Job-Resource-Object>, ...],
  ... see JSON:API spec ...
}
```
