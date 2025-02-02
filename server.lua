ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('vehicle_repair:checkMoney', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local money = xPlayer.getMoney()
    
    cb(money >= amount)
end)

RegisterNetEvent('vehicle_repair:payRepair')
AddEventHandler('vehicle_repair:payRepair', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeMoney(amount)
end)