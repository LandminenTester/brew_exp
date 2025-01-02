-------------------------------------------------------------------------------------------
------------------------------- brew_exp - Client Main --------------------------------
-------------------------------------------------------------------------------------------

AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
		return
	end
	TriggerServerEvent('brew_exp:getUserData')
end)