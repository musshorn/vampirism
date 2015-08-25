if ShopUI == nil then
	ShopUI = {}
end

function ShopUI:Init()
  Convars:RegisterCommand("shop_pressed", function (name, p)
      local cmdPlayer = Convars:GetCommandClient()
      if cmdPlayer then
        local ent = EntIndexToHScript(tonumber(p))
        if ent:HasInventory() then
        	local shop = FindNearestShop(ent:GetAbsOrigin(), 800)
        	if shop ~= nil then
            local playerID = ent:GetMainControllingPlayer()
            local shopIndex = shop:entindex()
            local shopName = shop:GetUnitName()
            if SHOPS[shopIndex] == nil then
              SHOPS[shopIndex] = {}
              for k, v in pairs(SHOP_KV[shopName]) do
                local index = v['index']
                SHOPS[shopIndex][index] = {}
                SHOPS[shopIndex][index]['name'] = k
                SHOPS[shopIndex][index]['stock'] = v['initstock']
                SHOPS[shopIndex][index]['queue'] = {}
                SHOPS[shopIndex][index]['stocktime'] = v['stocktime']
                if SHOPS[shopIndex][index]['stock'] == 0 then
                  table.insert(SHOPS[shopIndex][index]['queue'], v['stocktime'])
                end
              end             
            end
            if shopName ~= 'vampire_shop' then
              for k, v in pairs(SHOPS[shopIndex]) do
                --only sending the timer of the TOP item in the queue, not the queue itself.
                --player owning shop has needed tech
                local hasTech = TechTree:GetRequired(v['name'], shop:GetMainControllingPlayer(), shopName, "item")
                if hasTech ~= true then hasTech = false end
                FireGameEvent('shop_preload', {player_ID = playerID, shop_index = shopIndex, shop_type = shopName, item_name = v['name'], item_stock = v['stock'], item_time = v['queue'][0], item_index = k, has_tech = hasTech})
              end
            else
              for k,v in pairs(SHOPS[shopIndex]) do
                FireGameEvent('shop_preload', {player_ID = playerID, shop_index = shopIndex, shop_type = shopName, item_name = v['name'], item_stock = v['stock'], item_time = v['queue'][0], item_index = k, has_tech = true})
              end
            end
        		FireGameEvent('shop_open', {player_ID = playerID, shop_type = shopName, shop_user = tonumber(p), shop_index = shopIndex})
            Timers:CreateTimer(function ()
              if CalcDistanceBetweenEntityOBB(shop, ent) > 500 then
                FireGameEvent('shop_close', {player_ID = ent:GetMainControllingPlayer()})
                return nil
              else
                return 0.03
              end
            end)
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

-- Add stock delay to vampire items.
function ShopUI:InitVampShop( vampshop )
  print('making vamp shop')
  local shopIndex = vampshop:entindex()
  local shopName = vampshop:GetUnitName()

  SHOPS[shopIndex] = {}
  print(shopIndex, 'VAMP SHOP INDEX')

  for k, v in pairs(SHOP_KV[shopName]) do
    local index = v['index']
    SHOPS[shopIndex][index] = {}
    SHOPS[shopIndex][index]['name'] = k
    SHOPS[shopIndex][index]['stock'] = v['initstock']
    SHOPS[shopIndex][index]['queue'] = {}
    SHOPS[shopIndex][index]['stocktime'] = v['stocktime']
    SHOPS[shopIndex][index]['unlocktime'] = v['unlocktime']
    if SHOPS[shopIndex][index]['unlocktime'] ~= nil then
      print('this item unlcoks delayed', k)
      SHOPS[shopIndex][index]['stock'] = 0
      table.insert(SHOPS[shopIndex][index]['queue'], SHOPS[shopIndex][index]['unlocktime'])
    end
    for i = -1, 11 do
      FireGameEvent('shop_preload', {player_ID = i, shop_index = shopIndex, shop_type = shopName, item_name = k, item_stock = SHOPS[shopIndex][index]['stock'], item_time = SHOPS[shopIndex][index]['queue'][0], item_index = v['index'], has_tech = true})
    end
  end
end

function FindNearestShop(vPos, fRange)
	local shopEnts = Entities:FindAllInSphere(vPos, fRange)
	for k, v in pairs(shopEnts) do
		if v:GetClassname() == "npc_dota_creature" then
			if v:HasAbility("util_is_shop") then
				return v
			end
		end
	end
end

function Purchase( itemname, buyer )
  local playerID = buyer:GetMainControllingPlayer()
  local gold = GOLD[playerID]
  local lumber = WOOD[playerID]
  local food = CURRENT_FOOD[playerID]
  local foodCap = TOTAL_FOOD[playerID]
  local goldCost = 0
  local lumberCost = 0
  local foodCost = 0
  if ITEM_KV[itemname]['GoldCost'] ~= nil then
  	goldCost = ITEM_KV[itemname]['GoldCost']
  end
  if ITEM_KV[itemname]['LumberCost'] ~= nil then
  	lumberCost = ITEM_KV[itemname]['LumberCost']
  end
  if ITEM_KV[itemname]['FoodCost'] ~= nil then
    foodCost = ITEM_KV[itemname]['FoodCost']
  end

  if lumber < lumberCost then
    FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough lumber!'})
    return
  end
  if gold < goldCost then
    FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough gold!'})
    return
  end
  if food + foodCost > foodCap then
    FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough food!'})
    return
  end
  if food + foodCost > 250 then
    FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Food cap reached!'})
    return
  end

  local isRecipe = false

  if string.find(itemname, 'recipe') then
    isRecipe = true
  end

  if buyer:HasInventory() then
    -- table of item handles to remove if buyer passes all requirements
    local itemsToRemove = {}

    if isRecipe then
      local hasComponents = true
      for k, v in pairs(ITEM_KV[itemname]['ItemRequirements']) do
        if not buyer:HasItemInInventory(v) then
          hasComponents = false
        end
      end

      if hasComponents then
        for k, v in pairs(ITEM_KV[itemname]['ItemRequirements']) do
          for i = 0, 5 do
            if buyer:GetItemInSlot(i) ~= nil then
              if buyer:GetItemInSlot(i):GetName() == tostring(v) then
                table.insert(itemsToRemove, buyer:GetItemInSlot(i))
              end
            end
          end
        end
      else
        FireGameEvent('custom_error_show', {player_ID = playerID, _error = "Missing required items!"})
        return
      end
    end

  	if buyer:HasAnyAvailableInventorySpace() then
  		if gold >= goldCost and lumber >= lumberCost then
  			--check if user is still near shop, decrease that shops stock.
  			local shop = FindNearestShop(buyer:GetAbsOrigin(), 1000)
  			if shop ~= nil then
          local shopIndex = shop:entindex()
          local playerID = buyer:GetMainControllingPlayer()
          --get the index of item
          local index = nil
          for k, v in pairs(SHOPS[shopIndex]) do
            if v['name'] == itemname then
              index = k
            end
          end

          if shop:GetUnitName() ~= 'vampire_shop' then
            local hasTech = TechTree:GetRequired(itemname, playerID, shop:GetUnitName(), "item")
            if hasTech ~= true then
              FireGameEvent( 'custom_error_show', { player_ID = playerID , _error = "Shop owner is missing tech!" } )
              return
            end
          end
  
          --check stock, handle recipies
          if SHOPS[shopIndex][index]['stock'] > 0 then
           if itemsToRemove[1] ~= nil then
              for k, v in pairs(itemsToRemove) do
                buyer:RemoveItem(v)
              end
              local recipeResult = ITEM_KV[itemname]['ItemResult']
              local item = CreateItem(recipeResult, buyer, buyer)
              item:SetPurchaser(buyer)
              item:SetOwner(buyer)
              item:SetOwner(PlayerResource:GetPlayer(playerID))
              item:SetPurchaser(PlayerResource:GetPlayer(playerID))
              buyer:AddItem(item)
           else
              local item = CreateItem(itemname, buyer, buyer)
              item:SetPurchaser(buyer)
              item:SetOwner(buyer)
              item:SetOwner(PlayerResource:GetPlayer(playerID))
              item:SetPurchaser(PlayerResource:GetPlayer(playerID))
              buyer:AddItem(item)
           end
           CURRENT_FOOD[playerID] = CURRENT_FOOD[playerID] + foodCost
           ChangeWood(playerID, -1 * lumberCost)
           ChangeGold(playerID, -1 * goldCost)
           FireGameEvent("vamp_food_changed", {player_ID = playerID, food_total = CURRENT_FOOD[playerID]})
      		 FireGameEvent("shop_item_bought", {player_ID = playerID, shop_index = shopIndex, item_index = index, item_name = itemname, stock = SHOPS[shopIndex][index]['stock'], stock_time = 0})
           SHOPS[shopIndex][index]['stock'] = SHOPS[shopIndex][index]['stock'] - 1
           table.insert(SHOPS[shopIndex][index]['queue'],  SHOPS[shopIndex][index]['stocktime'])
           if ITEM_KV[itemname].AnnounceItem == 1 and UNIQUE_TABLE[itemname] == nil then
             local playerName = PlayerResource:GetPlayerName(playerID)
             GameRules:SendCustomMessage(ColorIt(playerName, IDToColour(playerID))..' has purchased '..ITEM_NAMES[itemname]..'!', 0, 1)
             UNIQUE_TABLE[itemname] = playerID
           end
          else
            --out of stock, fire event anyway and send remaining time for next restock.
            FireGameEvent("shop_item_bought", {player_ID = playerID, shop_index = shopIndex, item_index = index, item_name = itemname, stock = SHOPS[shopIndex][index]['stock'], stock_time = SHOPS[shopIndex][index]['queue'][1]})
          end
        end
  		end
  	else
  		FireGameEvent( 'custom_error_show', { player_ID = playerID , _error = "No room in inventory!" } )
  	end
  end
end

function ShopUI:ProcessQueues()
  Timers:CreateTimer(function ()
    --for each shop
    for k, v in pairs(SHOPS) do
        --for each item in shop
        for index, item in pairs(v) do
          --if a queue exists
          if #item['queue'] > 0 then
            for qIndex, qTime in pairs(item['queue']) do
              if item['queue'][qIndex] > 0 then
                --lower that timer
                item['queue'][qIndex] = item['queue'][qIndex] - 1
              else
                local shopName = EntIndexToHScript(k):GetUnitName()
                --pop that queue, restock item, fire flash restock event.
                item['stock'] = item['stock'] + 1
                FireGameEvent('shop_restock', {shop_type = shopName, shop_index = k, item_index = index, item_name = item['name']})
                table.remove(item['queue'])
              end
            end
          end
        end
      end
    return 1
  end)
end