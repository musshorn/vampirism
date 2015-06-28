--[[

General trade interface and managment

]]--

Trade = {}
Trade.NextID = 1
Orders = {}

function Trade:HandleChat( keys )

	-- Function returns colourised string for sending as a message
	function FormatOutput( keys )
		local resource = keys.resource
		local amount = keys.amount

		if resource == "wood" then
			resource = ColorIt(resource, "green")
			amount = ColorIt(amount, "green")
		end

		if resource == "gold" then
			resource = ColorIt(resource, "yellow")
			amount = ColorIt(amount, "yellow")
		end

		local response = {resource = resource, amount = amount}
		return response
	end

	chat = ParseChat(keys)

	-- Add a sell listing
	if chat[1] == "-sell" then
		if tonumber(chat[2]) and tonumber(chat[4]) then
			local pID = keys.ply:GetPlayerID()
			local name = PlayerResource:GetPlayerName(pID) -- idk if this even works

			local sellAmount = tonumber(chat[2])
			local sellResource = chat[3]
			local buyAmount = tonumber(chat[4])
			local buyResource = chat[5]


			-- Check the player has the required resources, deduct them if they do
			if sellResource == "wood" and WOOD[pID] < sellAmount then
				FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more wood" } )
				return
			elseif sellResource == "wood" then
				WOOD[pID] = WOOD[pID] - sellAmount
		  	FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})
			end

			if sellResource == "gold" and GOLD[pID] < sellAmount then
				FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
				return
			elseif sellResource == "gold" then
				GOLD[pID] = GOLD[pID] - sellAmount
				FireGameEvent('vamp_gold_changed', { player_ID = pID, gold_total = GOLD[pID]})
			end

			-- Generate order table and add it to the master table
			order = {ordertype = "sell", sellAmount = sellAmount, sellResource = sellResource, buyAmount = buyAmount, buyResource = buyResource, player = keys.ply, ID = self.NextID}
			table.insert(Orders, order)
			self.NextID = self.NextID + 1

			-- Format text and print it to all humans
			local sellFormatted = FormatOutput({resource = sellResource, amount = sellAmount})
			local buyFormatted = FormatOutput({resource = buyResource, amount = buyAmount})

			GameRules:SendCustomMessage(name .. " is selling " .. sellFormatted.amount .. " " .. sellFormatted.resource .. " for " .. buyFormatted.amount .. " " .. buyFormatted.resource, 0, 0)
		end
	end

	-- Print all current listings and their trade ID
	if chat[1] == "-list" then
		for k, offers in pairs(Orders) do
			local player = offers.player
			local pid = player:GetPlayerID()
			local name = PlayerResource:GetPlayerName(player:GetPlayerID())

			local sellAmount = offers.sellAmount
			local sellResource = offers.sellResource
			
			local sellFormatted = FormatOutput({resource = sellResource, amount = sellAmount})

			local buyAmount = offers.buyAmount
			local buyResource = offers.buyResource

			local buyFormatted = FormatOutput({resource = buyResource, amount = buyAmount})

			GameRules:SendCustomMessage("[ " .. offers.ID .. " ] " .. name .. " is selling " .. sellFormatted.amount .. " " .. sellFormatted.resource .. " for " .. buyFormatted.amount .. " " .. buyFormatted.resource, 0, 0)
		end
	end

	-- Process a buy order
	if chat[1] == "-buy" then
		if tonumber(chat[2]) then
			local tradeID = tonumber(chat[2])

			-- Find the mentioned trade
			for k, offers in pairs(Orders) do
				if offers.ID == tradeID then

					-- Resolve trade
					local sellerPID = offers.player:GetPlayerID()
					local buyerPID = keys.ply:GetPlayerID()
					local askingResource = offers.buyResource
					local askingAmount = offers.buyAmount

					-- Resolve trades asking for wood
					if askingResource == "wood" then
						if WOOD[buyerPID] < askingAmount then
							FireGameEvent( 'custom_error_show', { player_ID = buyerPID, _error = "You need more wood" } )
							return
						else
							WOOD[buyerPID] = WOOD[buyerPID] - askingAmount
							WOOD[sellerPID] = WOOD[sellerPID] + askingAmount
		  				FireGameEvent('vamp_wood_changed', { player_ID = buyerPID, wood_total = WOOD[buyerPID]})
		  				FireGameEvent('vamp_wood_changed', { player_ID = sellerPID, wood_total = WOOD[sellerPID]})

		  				GOLD[buyerPID] = GOLD[buyerPID] + offers.sellAmount
		  				FireGameEvent('vamp_gold_changed', { player_ID = buyerPID, gold_total = GOLD[buyerPID]})
		  			end
		  		end

		  		-- Resolve trades asking for gold
					if askingResource == "gold" then
						if GOLD[buyerPID] < askingAmount then
							FireGameEvent( 'custom_error_show', { player_ID = buyerPID, _error = "You need more gold" } )
							return
						else
							GOLD[buyerPID] = GOLD[buyerPID] - askingAmount
							GOLD[sellerPID] = GOLD[sellerPID] + askingAmount
		  				FireGameEvent('vamp_gold_changed', { player_ID = buyerPID, gold_total = GOLD[buyerPID]})
		  				FireGameEvent('vamp_gold_changed', { player_ID = sellerPID, gold_total = GOLD[sellerPID]})

		  				WOOD[buyerPID] = WOOD[buyerPID] + offers.sellAmount
		  				FireGameEvent('vamp_wood_changed', { player_ID = buyerPID, wood_total = WOOD[buyerPID]})
		  			end
		  		end

		  		-- Remove the trade
		  		Orders[k] = nil
		  		break
		  	end
		  end
		end
	end

	-- Process a trade request. Format:
	-- -trade A X Y
	-- A = player colour, X = amount, Y = resource
	if chat[1] == "-trade" then
		if tonumber(chat[3]) then
			local senderID = keys.ply:GetPlayerID()
			local recieverID = ColourToID(chat[2])
			local sendAmount = tonumber(chat[3])
			local sendResource = chat[4]

			-- Check the player has the required resources, deduct them if they do
			if sendResource == "wood" and WOOD[senderID] < sendAmount then
				FireGameEvent( 'custom_error_show', { player_ID = senderID, _error = "You need more wood" } )
				return
			elseif sendResource == "wood" then
				WOOD[senderID] = WOOD[senderID] - sendAmount
				WOOD[recieverID] = WOOD[recieverID] + sendAmount
		  	FireGameEvent('vamp_wood_changed', { player_ID = recieverID, wood_total = WOOD[recieverID]})
		  	FireGameEvent('vamp_wood_changed', { player_ID = recieverID, wood_total = WOOD[recieverID]})
			end

			if sendResource == "gold" and GOLD[senderID] < sendAmount then
				FireGameEvent( 'custom_error_show', { player_ID = senderID, _error = "You need more gold" } )
				return
			elseif sendResource == "gold" then
				GOLD[senderID] = GOLD[senderID] - sendAmount
				GOLD[recieverID] = GOLD[recieverID] + sendAmount
				FireGameEvent('vamp_gold_changed', { player_ID = senderID, gold_total = GOLD[senderID]})
				FireGameEvent('vamp_gold_changed', { player_ID = recieverID, gold_total = GOLD[recieverID]})
			end
		end
	end
end