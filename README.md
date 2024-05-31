# AO Experimentation

Template for W3C Verifiable Credentials transported on AO by Arweave.

<ol>
  <li>Set up your editor: https://cookbook_ao.g8way.io/guides/aos/editor.html</li>
  <li>- Also: https://cookbook_ao.g8way.io/references/editor-setup.html</li>
  <li>Install the aos cli: `npm i -g https://get_ao.g8way.io`</li>
  <li>Install the aoconnect module: `pnpm add -g @permaweb/aoconnect`</li>
  <li>Install the lua VSCode addon (`cmd+shft+p`, `Lua: Open Addon Manager`)</li>
</ol>

Read:

- https://cookbook_ao.g8way.io/concepts/tour.html
- https://cookbook_ao.g8way.io/guides/aos/intro.html

Optionally install [ao cli](https://github.com/permaweb/ao/tree/main/dev-cli):

- curl -L https://arweave.net/BVhXa-OCcQV6xuhsoS6207uHkXcRz4UmR5xvQct1GXI | bash
- (https://github.com/permaweb/ao/blob/main/dev-cli/deno.json#L63)

Check out the aos blueprints:

- https://github.com/permaweb/aos/tree/main/blueprints

## aos CLI Console

```bash
Commands:

  .load [file]                  Loads local lua file into connected Process
  .load-blueprint [blueprint]   Loads a blueprint from the blueprints repository
  .monitor                      Starts monitoring cron messages for this Process
  .unmonitor                    Stops monitoring cron messages for this Process
  .editor                       Simple code editor for writing multi-line lua expressions
  .help                         Print this help screen
  .exit                         Quit console
```

```lua
-- Start the process
aos p3
-- Load the blueprints
.load src/medallion.lua
.load src/xp.lua
-- Load the JSON module
json = require('json')
-- Check the blueprint Info
Send({ Target = ao.id, Action = "Info" })
Inbox[#Inbox].Tags

Send({ Target = ao.id, Action = "Info" })
Inbox[#Inbox].Tags

.editor
Send({
  Target = ao.id,
  Receiver = "LREm7rWyZOaXK8hnf0vJRDeLXyQcpOy2CTZPq44XGWc",
  Action = "Mint",
  Credential = json.encode({
      ["@context"] = {
        "https://www.w3.org/ns/credentials/v2",
        "https://www.w3.org/ns/credentials/examples/v2"
      },
      id = "http://university.example/credentials/3732",
      type = {"VerifiableCredential", "ExampleDegreeCredential"},
      issuer = "https://university.example/issuers/565049",
      validFrom = "2010-01-01T00:00:00Z",
      credentialSubject = {
        id = "did:example:ebfeb1f712ebc6f1c276e12ec21",
        degree = {
          type = "ExampleBachelorDegree",
          name = "Bachelor of Science and Arts"
        }
      }
    })
})
.done

Inbox[#Inbox].Tags

-- Mint tokens to a user process
.editor
Send({
  Target = ao.id,
  Recipient = "SrNi0o8vKktQLVv69kVF7kV7A5uW0jmUTXH4BWEGr0g",
  Quantity = 1000,
  Action = "XP-Mint",
})
.done

Inbox[#Inbox].Tags
```
