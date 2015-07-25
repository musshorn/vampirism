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
				ChangeWood(pID, -1 * sellAmount)
			end

			if sellResource == "gold" and GOLD[pID] < sellAmount then
				FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
				return
			elseif sellResource == "gold" then
				ChangeGold(pID, -1 * sellAmount)
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
							ChangeWood(buyerPID, -1 * askingAmount)
							ChangeWood(sellerPID, askingAmount)
	
		  					ChangeGold(buyerPID, offers.sellAmount)
		  				end
		  			end

		  			-- Resolve trades asking for gold
					if askingResource == "gold" then
						if GOLD[buyerPID] < askingAmount then
							FireGameEvent( 'custom_error_show', { player_ID = buyerPID, _error = "You need more gold" } )
							return
						else
							ChangeGold(buyerPID, -1 * askingAmount)
							ChangeGold(sellerPID, askingAmount)
	
							ChangeWood(buyerPID, offers.sellAmount)
		  				end
		  			end

		  		-- Remove the trade
		  		Orders[k] = nil
		  		break
		  	end
		  end
		end
	end

	--'wood' sends wood to a player colour
	if chat[1] == "-wood" then
		if tonumber(chat[3]) then
			local senderID = keys.ply:GetPlayerID()
			local recieverID = ColourToID(chat[2])
			local sendAmount = tonumber(chat[3])

			-- Check the player has enough wood.
			if WOOD[senderID] < sendAmount then
				FireGameEvent( 'custom_error_show', { player_ID = senderID, _error = "You need more wood" } )
				return
			else
				ChangeWood(senderID, -1 * sendAmount)
				ChangeWood(recieverID, sendAmount)
			end			
		end
	end

	--'gold' sends gold to a player colour
	if chat[1] == "-gold" then
		if tonumber(chat[3]) then
			local senderID = keys.ply:GetPlayerID()
			local recieverID = ColourToID(chat[2])
			local sendAmount = tonumber(chat[3])

			if GOLD[senderID] < sendAmount then
				FireGameEvent( 'custom_error_show', { player_ID = senderID, _error = "You need more gold" } )
				return
			else
				ChangeGold(senderID, -1 * sendAmount)
				ChangeGold(recieverID, sendAmount)
			end
		end
	end

	if chat[1] == "-mycolor" then
		print('recieved, mycolor')
		local playerID = keys.ply:GetPlayerID()
		Notifications:Top(playerID, {text = "Your color is "..IDToColour(playerID), duration = 5, nil, style = {color="white", ["font-size"]="20px"}})
		print('sent Your color is '..IDToColour(playerID))
	end
end