local bint = require('.bint')(256)
local ao = require('ao')

--[[
  This module implements a subset of the ao Standard Token Specification.

  Terms:
    Sender: the wallet or Process that sent the Message

  It will first initialize the internal state, and then attach handlers,
    according to the ao Standard Token Spec API:

    - Info(): return the token parameters, like Name, Ticker, Logo, and Denomination

    - Mint(Quantity: number): if the Sender matches the Process Owner, then mint the desired Quantity of tokens, adding
        them the Processes' balance
]]
--

local json = require('json')

--[[
  utils helper functions to remove the bint complexity.
]]
--


local utils = {
  add = function(a, b)
    return tostring(bint(a) + bint(b))
  end,
  subtract = function(a, b)
    return tostring(bint(a) - bint(b))
  end,
  toBalanceValue = function(a)
    return tostring(bint(a))
  end,
  toNumber = function(a)
    return tonumber(a)
  end
}


--[[
     Initialize State

     ao.id is equal to the Process.Id
   ]]
--
Variant = "0.0.3"

-- token should be idempotent and not change previous state updates
Nonce = utils.toBalanceValue(0)
TotalSupply = utils.toBalanceValue(0)
Owners = {}
Tokens = {}
Name = 'Medallion'
Ticker = 'MLN'
Logo = 'SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY'
XPId = 'm_cG2KZYoqK_707HcgTUtcIpTHLL4opeDfRS5O6RW_I'
XPMintQty = utils.toBalanceValue(200)

--[[
     Add handlers for each incoming Action defined by the ao Standard Token Specification
   ]]
--

--[[
     Info
   ]]
--
Handlers.add('info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
  ao.send({
    Target = msg.From,
    Name = Name,
    Ticker = Ticker,
    Logo = Logo,
    Denomination = tostring(Denomination)
  })
end)

--[[
    Mint
   ]]
--
Handlers.add('mint', Handlers.utils.hasMatchingTag('Action', 'Mint'), function(msg)
  assert(msg.Credential ~= nil, 'Credential is required!')
  assert(type(msg.Receiver) == 'string', 'Receiver is required!')

  TotalSupply = utils.add(TotalSupply, 1)
  Nonce = utils.add(Nonce, 1)

  if not Owners[msg.Receiver] then
    Owners[msg.Receiver] = {
      Total = utils.toBalanceValue(0),
      Tokens = {}
    }
  end

  if not Tokens[Nonce] then
    Tokens[Nonce] = {}
  end

  -- Note: Minting is reserved for the Process owner
  if msg.From == ao.id then
    table.insert(Owners[msg.Receiver].Tokens, Nonce)

    Tokens[Nonce] = {
      Id = Nonce,
      Credential = msg.Credential,
      Owner = msg.Receiver,
    }

    Owners[msg.Receiver].Total = utils.add(Owners[msg.Receiver].Total, 1)

    ao.send({
      Target = msg.From,
      Data = Colors.gray .. "Minted MDLN " .. Colors.green .. Nonce .. Colors.reset,
      Credential = msg.Credential,
      Id = Nonce,
    })

    ao.send({
      Target = XPId,
      Action = 'Mint',
      Quantity = XPMintQty,
      Receiver = msg.Receiver,
    })

    ao.send({
      Target = msg.From,
      Data = Colors.gray .. "Minted XP " .. Colors.green .. Nonce .. Colors.reset,
      Credential = msg.Credential,
      Id = Nonce,
    })

    ao.send({
      Target = msg.Receiver,
      Data = Colors.gray .. "Received MDLN " .. Colors.blue .. Nonce .. Colors.reset,
      Credential = msg.Credential,
      Id = Nonce,
    })

    ao.send({
      Target = msg.Receiver,
      Data = Colors.gray .. "Received XP " .. Colors.blue .. XPMintQty .. Colors.reset,
      Credential = msg.Credential,
      Id = Nonce,
    })

   else
    ao.send({
      Target = msg.From,
      Action = 'Mint-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Only the Process Id can mint new ' .. Ticker .. ' tokens!'
    })
  end

end)

--[[
     Total Supply
   ]]
--
Handlers.add('totalSupply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  ao.send({
    Target = msg.From,
    Action = 'Total-Supply',
    Data = TotalSupply,
    Ticker = Ticker
  })
end)

--[[
 Burn
]]
   --
Handlers.add('burn', Handlers.utils.hasMatchingTag('Action', 'Burn'), function(msg)
  assert(type(msg.Id) == 'string', 'Token Id is required!')

  -- TODO: burn token from Owner

  ao.send({
    Target = msg.From,
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. msg.Quantity .. Colors.reset
  })
end)

--[[
  tokensOf
]]

Handlers.add('tokensOf', Handlers.utils.hasMatchingTag('Action', 'Tokens-Of'), function(msg)
  assert(type(msg.Owner) == 'string', 'Owner is required!')

  local tokens = Owners[msg.Owner].Tokens

  local filteredTokens = {}
  for _, tokenId in ipairs(tokens) do
    if Tokens[tokenId] then
      table.insert(filteredTokens, Tokens[tokenId])
    end
  end

  ao.send({
    Target = msg.From,
    Tokens = json.encode(filteredTokens),
    Data = Colors.blue .. msg.Owner .. Colors.reset,
  })

end)

-- GetMembers