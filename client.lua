ESX = exports["es_extended"]:getSharedObject()

local blips = {}
local isRepairing = false

local function CreateRepairBlips()
    for _, location in pairs(Config.RepairLocations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, 446)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 47)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Vehicle Repair")
        EndTextCommandSetBlipName(blip)
        table.insert(blips, blip)
    end
end

local function RemoveRepairBlips()
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end

local function IsAtRepairLocation()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for _, location in pairs(Config.RepairLocations) do
        local distance = #(playerCoords - location.coords)
        if distance < 10.0 then
            return true
        end
    end
    return false
end

local function CalculateRepairCost(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local totalDamage = (2000 - (bodyHealth + engineHealth))
    local repairCost = Config.InitialCost + math.ceil(totalDamage * 2) -- Base cost + $2 per damage point
    return repairCost
end

local function CalculateRepairTime(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local totalDamage = (2000 - (bodyHealth + engineHealth))
    local repairTime = math.ceil(totalDamage / 100) -- 1 second per 100 damage points
    return (repairTime * 1000) * Config.ProgressMultiply -- Convert to milliseconds and apply multiplier
end

CreateThread(function()
    CreateRepairBlips()
end)

local function RepairVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then return end
    
    local repairCost = CalculateRepairCost(vehicle)
    local repairTime = CalculateRepairTime(vehicle)

    lib.hideTextUI()
    isRepairing = true

    ESX.TriggerServerCallback('vehicle_repair:checkMoney', function(hasEnough)
        if hasEnough then
            if lib.progressCircle({
                duration = repairTime,
                label = 'Repairing Vehicle...',
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                },
            }) then
                -- Complete repair
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleUndriveable(vehicle, false)
                SetVehicleDirtLevel(vehicle, 0.0)
                WashDecalsFromVehicle(vehicle, 1.0)
                
                TriggerServerEvent('vehicle_repair:payRepair', repairCost)
                
                lib.notify({
                    title = 'Vehicle Repaired',
                    description = string.format('Paid $%d for repairs', repairCost),
                    type = 'success',
                    position = Config.NotifPosition,
                    duration = 5000
                })
            else
                lib.notify({
                    title = 'Repair Cancelled',
                    description = 'Vehicle repair was cancelled',
                    type = 'error',
                    position = Config.NotifPosition,
                    duration = 5000
                })
            end
        else
            lib.notify({
                title = 'Insufficient Funds',
                description = string.format('You need $%d for repairs', repairCost),
                type = 'error',
                position = Config.NotifPosition,
                duration = 5000
            })
        end
        isRepairing = false
    end, repairCost)
end

CreateThread(function()
    while true do
        Wait(0)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        
        if vehicle ~= 0 and IsAtRepairLocation() and not isRepairing then
            local bodyHealth = GetVehicleBodyHealth(vehicle)
            local engineHealth = GetVehicleEngineHealth(vehicle)
            
            if bodyHealth < 1000 or engineHealth < 1000 then
                lib.showTextUI('[E] - Repair Vehicle')
                
                if IsControlJustReleased(0, 38) then -- E key
                    RepairVehicle()
                end
            end
        else
            lib.hideTextUI()
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveRepairBlips()
    end
end)