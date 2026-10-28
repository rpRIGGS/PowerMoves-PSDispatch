-- Lightweight field reporting until the complete SADOT.net interface exists.
-- /towreport opens the inspection form for your currently assigned 511 call.
-- Never moves, despawns, or impounds a vehicle.
local function notify(message, kind)
    lib.notify({ description = message, type = kind or 'inform', position = 'top' })
end

RegisterCommand('towreport', function()
    local playerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
    local job = playerData and playerData.job
    if not job or job.type ~= 'mechanic' or not job.onduty then
        notify('Only on-duty mechanics can file a 511 tow report', 'error')
        return
    end

    local calls = lib.callback.await('ps-dispatch:callback:getCalls', false) or {}
    local assigned
    for _, call in ipairs(calls) do
        if call.codeName == '511call' and type(call.units) == 'table' then
            for _, unit in ipairs(call.units) do
                if unit.citizenid == playerData.citizenid then
                    assigned = call
                    break
                end
            end
        end
        if assigned then break end
    end
    if not assigned then
        notify('Accept a 511 tow dispatch before filing its report', 'error')
        return
    end

    local values = lib.inputDialog('511 Tow Inspection - ' .. tostring(assigned.towRef or assigned.id), {
        { type = 'input', label = 'License plate', required = true, max = 24 },
        { type = 'input', label = 'Vehicle model', required = false, max = 100 },
        { type = 'textarea', label = 'Vehicle condition', required = false, max = 256 },
        { type = 'input', label = 'Tow destination', required = true, max = 160 },
        { type = 'textarea', label = 'Driver notes', required = false, max = 512 },
    })
    if not values then return end

    local response = lib.callback.await('ps-dispatch:callback:saveTowInspection', false, assigned.id, {
        plate = values[1],
        vehicleModel = values[2],
        condition = values[3],
        destination = values[4],
        notes = values[5],
    })
    if response and response.success then
        notify('Tow inspection saved: ' .. tostring(response.towRef), 'success')
    else
        notify(response and response.reason or 'Unable to save tow inspection', 'error')
    end
end, false)
