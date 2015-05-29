if ShopUI == nil then
	ShopUI = {}
end

function ShopUI:Init()
	Convars:RegisterCommand("shop_pressed", function (name, p)
      local cmdPlayer = Convars:GetCommandClient()
      if cmdPlayer then
        print('pressed')
        local ent = EntIndexToHScript(tonumber(p))
        if ent:HasInventory() then
          print('has inventory')
          print(ent:GetUnitName())
        	local shop = FindNearestShop(ent:GetAbsOrigin(), 500)
        	if shop ~= nil then
            print(shop:GetUnitName())
        		FireGameEvent('shop_open', {player_ID = ent:GetMainControllingPlayer(), shop_type = 'human_surplus', shop_user = tonumber(p), shop_index = shop:entindex()})
        	end
        end
      end
  	end, "finds nearest shop", 0 )

  	Convars:RegisterCommand("shop_purchase", function(name, p)
  	  local cmdPlayer = Convars:GetCommandClient()
  	  if cmdPlayer then
  	    local itemName, entindex = p:match("([^,]+),([^,]+)")
  	    if tostring(itemName) == 'null' then
  	    	return
  	    end	
  	    local ent = EntIndexToHScript(tonumber(entindex))
  	    Purchase(itemName, ent)
  	  end
  	end, "user purchases an item", 0)
end

function FindNearestShop(vPos, fRange)
	local shopEnts = Entities:FindAllInSphere(vPos, fRange)
	for k, v in pairs(shopEnts) do
		if v:GetClassname() == "npc_dota_creature" then
			if v:HasAbility("util_is_shop") then
				print('found a shop, returning')
				return v
			end
		end
	end
end

function Purchase( itemname, buyer )
  local playerID = buyer:GetMainControllingPlayer()
  local gold = PlayerResource:GetGold(playerID)
  local lumber = WOOD[playerID]
  local goldCost = 0
  local lumberCost = 0
  if ITEM_KV[itemname]['GoldCost'] ~= nil then
  	goldCost = ITEM_KV[itemname]['GoldCost']
  end
  if ITEM_KV[itemname]['LumberCost'] ~= nil then
  	lumberCost = ITEM_KV[itemname]['LumberCost']
  end

  if buyer:HasInventory() then
  	if buyer:HasAnyAvailableInventorySpace() then
  		if gold >= goldCost and lumber >= lumberCost then
  			--check if user is still near shop, decrease that shops stock.
  			local shop = FindNearestShop(buyer:GetAbsOrigin(), 1000)
  			if shop ~= nil then

  				local item = CreateItem(itemname, buyer, buyer)
  				item:SetPurchaser(buyer)
  				item:SetOwner(buyer)
  				item:SetOwner(PlayerResource:GetPlayer(playerID))
  				item:SetPurchaser(PlayerResource:GetPlayer(playerID))
  				buyer:AddItem(item)
  				WOOD[playerID] = WOOD[playerID] - lumberCost
  				PlayerResource:SetGold(playerID, gold - goldCost, true)
  				FireGameEvent("vamp_gold_changed", {player_ID = playerID, gold_total = PlayerResource:GetGold(playerID)})
     			FireGameEvent("vamp_wood_changed", {player_ID = playerID, wood_total = WOOD[playerID]})
     			FireGameEvent("shop_item_bought", {player_ID = buyer:GetMainControllingPlayer(), shop_index = shop:entindex(), item_name = itemname} )
     		end
  		end
  	else
  		FireGameEvent( 'custom_error_show', { player_ID = buyer:GetMainControllingPlayer() , _error = "No room in inventory!" } )
  	end
  end
end