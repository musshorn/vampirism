function CoinUsed(keys)
	local user = keys.caster
	local coin = keys.ability

	if user:IsRealHero() then
		user:SetGold(user:GetGold() + 1, false)
	end
end