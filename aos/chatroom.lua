Members = Members or {}

Handlers.add(
	'Register',
	Handlers.utils.hasMatchingTag('Action', 'Register'),
	function(msg)
		table.insert(Members, msg.From)
		Handlers.utils.reply('registered')(msg)
	end
)

Handlers.add(
	'Broadcast',
	Handlers.utils.hasMatchingTag('Action', 'Broadcast'),
	function(msg)
    print('Broadcasting message from ' .. msg.From .. '. Content: ' .. msg.Data)

		for _, recipient in ipairs(Members) do
			ao.send({
				Target = recipient,
				Data = msg.Data,
			})
		end
		Handlers.utils.reply('Broadcasted.')(msg)
	end
)

-- Handlers.add(
-- 	'Broadcast',
-- 	Handlers.utils.hasMatchingTag('Action', 'Broadcast'),
-- 	function(m)
-- 		-- if Balances[m.From] == nil or tonumber(Balances[m.From]) < 1 then
-- 		-- 	print('UNAUTH REQ: ' .. m.From)
-- 		-- 	return
-- 		-- end
-- 		-- local type = m.Type or "Normal"
-- 		print('Broadcasting message from ' .. m.From .. '. Content: ' .. m.Data)
-- 		for i = 1, #Members, 1 do
-- 			ao.send({
-- 				Target = Members[i],
-- 				Action = 'Broadcasted',
-- 				Broadcaster = m.From,
-- 				Data = m.Data,
-- 			})
-- 		end
-- 	end
-- )
