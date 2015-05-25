if ShopUI == nil then
	ShopUI = {}
end

function ShopUI:Init()
	Convars:RegisterCommand("shop_pressed", function (name, p)
      local cmdPlayer = Convars:GetCommandClient()
      if cmdPlayer then
        local ent = EntIndexToHScript(tonumber(p))
        if ent:HasInventory() then
          local nearEnts = Entities:FindAllInSphere(ent:GetAbsOrigin(), 1000)
          for k, v in pairs(nearEnts) do
            if v:GetClassname() == 'npc_dota_creature' then
              if v:GetUnitName() == 'human_surplus' then
                --player has opened a human surplus, tell flash to display panel.
                FireGameEvent('shop_open', {player_ID = ent:GetMainControllingPlayer(), shop_type = 'human_surplus', shop_user = tonumber(p), shop_index = v:entindex()})
              end
            end
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

function Purchase( itemname, buyer )
  print('purchased')

  if buyer:HasInventory() then
  	print('HasInventory')
  	if buyer:HasAnyAvailableInventorySpace() then
  		print('has space, adding item')
  		local item = CreateItem(itemname, buyer, buyer)
  		item:SetPurchaser(buyer)
  		item:SetOwner(buyer)
  		buyer:AddItem(item)
  	end
  end
end