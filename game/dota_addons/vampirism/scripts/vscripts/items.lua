function CoinUsed(keys)
	local user = keys.caster
	local coin = keys.ability

	if user:IsRealHero() then
    if keys.Type == "small" then
		  user:SetGold(user:GetGold() + 1, false)
    end
    if keys.Type == "large" then
      user:SetGold(user:GetGold() + 1, false)
    end
	end
end