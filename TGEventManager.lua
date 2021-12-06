TGEventManager = {}

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

function TGEventManager.Initialize()
    TGEventManager.eventListeners  = {}
    TGEventManager.updateListeners = {}
    TGEventManager.cleuListeners   = {}

    -- A dummy frame to get us the events we are interested in.
    TGEventManager.tguFrame = CreateFrame("Frame")
    TGEventManager.tguFrame:SetScript("OnEvent",TGEventManager.OnEvent)
    TGEventManager.tguFrame:SetScript("OnUpdate",TGEventManager.OnUpdate)
    TGEventManager.tguFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function TGEventManager.Register(obj)
    -- All keys in obj that are completely uppercase are assumed to be event
    -- handler static methods.  If an "OnUpdate" method exists, it is also
    -- registered and assumed to be a static method.
    for k in pairs(obj) do
        if string.upper(k) == k then
            if starts_with(k, "CLEU_") then
                local subEvent = k:sub(6)
                if TGEventManager.cleuListeners[subEvent] == nil then
                    TGEventManager.cleuListeners[subEvent] = {}
                end
                table.insert(TGEventManager.cleuListeners[subEvent],
                             {obj=obj, method=k})
            elseif not starts_with(k, "_") then
                TGEventManager.tguFrame:RegisterEvent(k)
                if TGEventManager.eventListeners[k] == nil then
                    TGEventManager.eventListeners[k] = {}
                end
                table.insert(TGEventManager.eventListeners[k], obj)
            end
        end
    end

    if obj["OnUpdate"] ~= nil then
        table.insert(TGEventManager.updateListeners, obj)
    end
end

function TGEventManager.OnEvent(frame, event, ...)
    local listeners = TGEventManager.eventListeners[event]

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if listeners then
            for _, l in ipairs(listeners) do
                l[event](...)
            end
        end
        TGEventManager.OnCLEU(CombatLogGetCurrentEventInfo())
    else
        for _, l in ipairs(listeners) do
            l[event](...)
        end
    end
end

function TGEventManager.OnCLEU(timestamp, subEvent, ...)
    local listeners = TGEventManager.cleuListeners[subEvent]
    if listeners == nil then
        return
    end

    for _, l in ipairs(listeners) do
        l.obj[l.method](timestamp, ...)
    end
end

function TGEventManager.OnUpdate()
    for _, ul in ipairs(TGEventManager.updateListeners) do
        ul.OnUpdate()
    end
end

TGEventManager.Initialize()
