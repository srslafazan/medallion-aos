local bint = require('.bint')(256)
local ao = require('ao')
--[[
  This module implements the ao Standard Token Specification.

  Terms:
    Sender: the wallet or Process that sent the Message

  It will first initialize the internal state, and then attach handlers,
    according to the ao Standard Token Spec API:

    - Info(): return the token parameters, like Name, Ticker, Logo, and Denomination

    - Balance(Target?: string): return the token balance of the Target. If Target is not provided, the Sender
        is assumed to be the Target

    - Balances(): return the token balance of all participants

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
  add = function (a,b) 
    return tostring(bint(a) + bint(b))
  end,
  subtract = function (a,b)
    return tostring(bint(a) - bint(b))
  end,
  toBalanceValue = function (a)
    return tostring(bint(a))
  end,
  toNumber = function (a)
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
Owners = {}
Tokens = {}
Nonce = utils.toBalanceValue(0)
TotalSupply = utils.toBalanceValue(0)
Name = 'Medallion'
Ticker = 'MDLN'
Logo = 'SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY'

--[[
     Add handlers for each incoming Action defined by the ao Standard Token Specification
   ]]
--

--[[
     Info
   ]]
--
Handlers.add('medallion-info', Handlers.utils.hasMatchingTag('Action', 'Medallion-Info'), function(msg)
  ao.send({
    Owners,
    Tokens,
    Nonce,
    TotalSupply,
    Name,
    Ticker,
    Logo,
  })
end)

--[[
     Balance
   ]]
--
Handlers.add('medallion-balance', Handlers.utils.hasMatchingTag('Action', 'Medallion-Balance'), function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient and Balances[msg.Tags.Recipient]) then
    bal = Balances[msg.Tags.Recipient]
  elseif msg.Tags.Target and Balances[msg.Tags.Target] then
    bal = Balances[msg.Tags.Target]
  elseif Balances[msg.From] then
    bal = Balances[msg.From]
  end

  ao.send({
    Target = msg.From,
    Balance = bal,
    Ticker = Ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

--[[
     Balances
   ]]
--
Handlers.add('medallion-balances', Handlers.utils.hasMatchingTag('Action', 'Medallion-Balances'),
  function(msg) ao.send({ Target = msg.From, Data = json.encode(Balances) }) end)




--[[
    Mint
   ]]
--
Handlers.add('medallion-mint', Handlers.utils.hasMatchingTag('Action', 'Medallion-Mint'), function(msg)
  assert(type(msg.Credential) == 'json', 'Credential is required!')
  assert(type(msg.Receiver) == 'string', 'Receiver is required!')

  if not Owners[msg.Receiver] then Owners[msg.Receiver] = { Tokens = {}, Total = 0 } end

  if msg.From == ao.id then
    TotalSupply = utils.add(TotalSupply, 1)
    Nonce = utils.add(Nonce, 1)
    Owners[msg.Receiver].Total = utils.add(Owners[msg.Receiver].Total, 1)
    Owners[msg.Receiver].Tokens[Nonce] = {
      Id = Nonce,
      Credential = msg.Credential,
    }
    ao.send({
      Target = msg.From,
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. "0" .. Colors.reset
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
Handlers.add('medallion-totalSupply', Handlers.utils.hasMatchingTag('Action', 'Medallion-Total-Supply'), function(msg)
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
]] --
Handlers.add('medallion-burn', Handlers.utils.hasMatchingTag('Action', 'Medallion-Burn'), function(msg)
  assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(bint(msg.Quantity) <= bint(Balances[msg.From]), 'Quantity must be less than or equal to the current balance!')

  Balances[msg.From] = utils.subtract(Balances[msg.From], msg.Quantity)
  TotalSupply = utils.subtract(TotalSupply, msg.Quantity)

  ao.send({
    Target = msg.From,
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. msg.Quantity .. Colors.reset
  })
end)