--[[
    Skyway Tram (Cablecar) by GlitchDetector, Nov. 2018
    Thanks to:
        IllusiveTea for moral support and introduing me to the topic of cable cars

    These trams try to sync between players, but is no guaranteed, they only sync whenever the hosts car reaches the bottom
    You can enter the cars when they are docked, and you'll have to press E to attach yourself, if you're not attached the car kicks you out
    Cars makes noise upon arrival and departure, and makes a running sound while moving
]]

-- Lerp, not to be confused with Liable Emerates Role Play
function Lerp(a, b, t)
	return a + (b - a) * t
end

-- Mass lerper
function VecLerp(x1, y1, z1, x2, y2, z2, l, clamp)
    if clamp then
        if l < 0.0 then l = 0.0 end
        if l > 1.0 then l = 1.0 end
    end
    local x = Lerp(x1, x2, l)
    local y = Lerp(y1, y2, l)
    local z = Lerp(z1, z2, l)
    return vector3(x, y, z)
end

-- The script train tracks (basically every node that the "trains" move between in order)
local TRACKS = {
    [0] = { -- Left skytram (from bottom)
        vector3(-740.911, 5599.341, 47.25),
        vector3(-739.557, 5599.346, 46.997),
        vector3(-581.009, 5596.517, 77.379),
        vector3(-575.717, 5596.388, 79.22),
        vector3(-273.805, 5590.844, 240.795),
        vector3(-268.707, 5590.744, 243.395),
        vector3(6.896, 5585.668, 423.614),
        vector3(11.774, 5585.591, 426.711),
        vector3(236.82, 5581.445, 599.642),
        vector3(241.365, 5581.369, 603.183),
        vector3(412.855, 5578.216, 774.401),
        vector3(417.541, 5578.124, 777.688),
        vector3(444.93, 5577.589, 786.535),
        vector3(446.288, 5577.59, 786.75),
    },
    [1] = { -- Right skytram (from bottom)
        vector3(446.291, 5566.377, 786.75),
        vector3(444.937, 5566.383, 786.551),
        vector3(417.371, 5567.001, 777.708),
        vector3(412.661, 5567.085, 774.439),
        vector3(241.31, 5570.594, 603.137),
        vector3(236.821, 5570.663, 599.561),
        vector3(11.35, 5575.298, 426.629),
        vector3(6.575, 5575.391, 423.57),
        vector3(-268.965, 5580.996, 243.386),
        vector3(-273.993, 5581.124, 240.808),
        vector3(-575.898, 5587.286, 79.251),
        vector3(-581.321, 5587.4, 77.348),
        vector3(-739.646, 5590.614, 47.006),
        vector3(-740.97, 5590.617, 47.306),
    },
}

-- Cable car data, lots is left-over from experiments and old iterations
local CABLE_CARS = {
    [0] = { -- Left track car
        entity = nil, -- The car itself

        -- Doors (I don't actually know if the left ones are on the left or not)
        doorLL = nil,
        doorLR = nil,
        doorRL = nil,
        doorRR = nil,
        index = 0, -- The index, used to set the track
        position = vector3(0,0,0), -- The current position of the car
        direction = 1, -- What direction we're moving (up or down)
        gradient = 1, -- Believed to be the gradient during research, but was actually just the current node we're moving from
        run_timer = 0, -- Scale used for lerping
        altitude = 0, -- Used for the scenic camera in SP, not used here
        activation_timer = 0, -- Not used here
        gradient_distance = 0.0, -- Distance between the current node we're moving from and the next node
        offset_modifier = 0.0, -- Something believed to be an offset modifier
        can_move = true, -- Determine if the car can move, not actually used here though
        is_player_seated = false, -- Another value from the SP script, not actually used because fucking hell I'm tired
        speed = 17.5, -- Movement speed modifier, determines the speed of the car on the track
		maxSpeedDistance = 50, -- Distance from station at which the car will attain maximum speed
        state = "IDLE", -- The current state of the car
        offset = vector3(-0.2, 0.0, 0.0),
    },
    [1] = { -- Right track car
        entity = nil,
        doorLL = nil,
        doorLR = nil,
        doorRL = nil,
        doorRR = nil,
        index = 1,
        position = vector3(0,0,0),
        direction = 1,
        gradient = 1,
        run_timer = 0,
        altitude = 0,
        activation_timer = 0,
        gradient_distance = 0.0,
        offset_modifier = 0.0,
        can_move = true,
        is_player_seated = false,
        speed = 17.5,
		maxSpeedDistance = 50,
        state = "IDLE",
        offset = vector3(-0.2, 0.0, 0.0),
    },
}

Citizen.CreateThread(function()
    -- Load the things we need
    while not HasModelLoaded("p_cablecar_s") do
        RequestModel("p_cablecar_s")
        Wait(100)
    end
    while not HasModelLoaded("p_cablecar_s_door_l") do
        RequestModel("p_cablecar_s_door_l")
        Wait(100)
    end
    while not HasModelLoaded("p_cablecar_s_door_r") do
        RequestModel("p_cablecar_s_door_r")
        Wait(100)
    end
    while not HasAnimDictLoaded("p_cablecar_s") do
        RequestAnimDict("p_cablecar_s")
        Wait(100)
    end
    RequestScriptAudioBank("CABLE_CAR", false, -1)
    RequestScriptAudioBank("CABLE_CAR_SOUNDS", false, -1)
    LoadStream("CABLE_CAR", "CABLE_CAR_SOUNDS")
    LoadStream("CABLE_CAR_SOUNDS", "CABLE_CAR")

    -- Spawn all them entities and attach the doors to the cars
    CABLE_CARS[0].entity = CreateObjectNoOffset("p_cablecar_s", -740.911, 5599.341, 47.25, 0, 1, 0)
    CABLE_CARS[0].doorLL = CreateObjectNoOffset("p_cablecar_s_door_l", -740.911, 5599.341, 47.25, 0, 1, 0)
    CABLE_CARS[0].doorLR = CreateObjectNoOffset("p_cablecar_s_door_r", -740.911, 5599.341, 47.25, 0, 1, 0)
    AttachEntityToEntity(CABLE_CARS[0].doorLL, CABLE_CARS[0].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 1, 0, 2, 1)
    AttachEntityToEntity(CABLE_CARS[0].doorLR, CABLE_CARS[0].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 1, 0, 2, 1)
    CABLE_CARS[0].doorRL = CreateObjectNoOffset("p_cablecar_s_door_l", -740.911, 5599.341, 47.25, 0, 1, 0)
    CABLE_CARS[0].doorRR = CreateObjectNoOffset("p_cablecar_s_door_r", -740.911, 5599.341, 47.25, 0, 1, 0)
    AttachEntityToEntity(CABLE_CARS[0].doorRL, CABLE_CARS[0].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0, 0, 1, 0, 2, 1)
    AttachEntityToEntity(CABLE_CARS[0].doorRR, CABLE_CARS[0].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0, 0, 1, 0, 2, 1)

    -- Do the same to the right track car
    CABLE_CARS[1].entity = CreateObjectNoOffset("p_cablecar_s", 446.291, 5566.377, 786.75, 0, 1, 0)
    CABLE_CARS[1].doorLL = CreateObjectNoOffset("p_cablecar_s_door_l", -740.911, 5599.341, 47.25, 0, 1, 0)
    CABLE_CARS[1].doorLR = CreateObjectNoOffset("p_cablecar_s_door_r", -740.911, 5599.341, 47.25, 0, 1, 0)
    AttachEntityToEntity(CABLE_CARS[1].doorLL, CABLE_CARS[1].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 1, 0, 2, 1)
    AttachEntityToEntity(CABLE_CARS[1].doorLR, CABLE_CARS[1].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 1, 0, 2, 1)
    CABLE_CARS[1].doorRL = CreateObjectNoOffset("p_cablecar_s_door_l", -740.911, 5599.341, 47.25, 0, 1, 0)
    CABLE_CARS[1].doorRR = CreateObjectNoOffset("p_cablecar_s_door_r", -740.911, 5599.341, 47.25, 0, 1, 0)
    AttachEntityToEntity(CABLE_CARS[1].doorRL, CABLE_CARS[1].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0, 0, 1, 0, 2, 1)
    AttachEntityToEntity(CABLE_CARS[1].doorRR, CABLE_CARS[1].entity, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0, 0, 1, 0, 2, 1)

    -- Align everything so it fits on the track
    FreezeEntityPosition(CABLE_CARS[0].entity, true)
    FreezeEntityPosition(CABLE_CARS[1].entity, true)
    SetEntityRotation(CABLE_CARS[0].entity, 0.0, 0.0, 270.0, 0, 1)
    SetEntityRotation(CABLE_CARS[1].entity, 0.0, 0.0, 90.0, 0, 1)

    -- Initialize the state
    CABLE_CARS[0].state = "MOVE_TO_IDLE_TOP"
    CABLE_CARS[1].state = "MOVE_TO_IDLE_TOP"
    -- KickPlayerOutOfMyCablecar(CABLE_CARS[0])
    -- KickPlayerOutOfMyCablecar(CABLE_CARS[1])
    -- Control movement forever
    while true do
        Wait(0)
        for ccIndex, cablecar in next, CABLE_CARS do
            UpdateCablecarMovement(cablecar)
        end
    end
end)

RegisterNetEvent("omni:cablecar:forceState")
AddEventHandler("omni:cablecar:forceState", function(index, state)
    local cablecar = CABLE_CARS[index]
    if state == "IDLE_BOTTOM" then
        cablecar.state = "MOVE_TO_IDLE_BOTTOM"
        cablecar.run_timer = 0.0
    end
    if state == "IDLE_TOP" then
        cablecar.state = "MOVE_TO_IDLE_TOP"
        cablecar.run_timer = 0.0
    end
    if state == "MOVE_DOWN" then
        cablecar.state = "IDLE_TO_MOVE_DOWN"
        cablecar.gradient = #TRACKS[index]
        cablecar.gradient_distance = 0.0
        cablecar.run_timer = 0.0
    end
    if state == "MOVE_UP" then
        cablecar.state = "IDLE_TO_MOVE_UP"
        cablecar.gradient = 1
        cablecar.gradient_distance = 0.0
        cablecar.run_timer = 0.0
    end
end)

AddEventHandler("onResourceStop", function(name)
    -- Delete all cable car things if the resource stops, just so we don't have cable cars galore sitting around
    if name == GetCurrentResourceName() then
        if CABLE_CARS[0].is_player_seated then
            KickPlayerOutOfMyCablecar(CABLE_CARS[0])
        end
        if CABLE_CARS[1].is_player_seated then
            KickPlayerOutOfMyCablecar(CABLE_CARS[1])
        end
        DeleteEntity(CABLE_CARS[0].entity)
        DeleteEntity(CABLE_CARS[1].entity)
        DeleteEntity(CABLE_CARS[0].doorLL)
        DeleteEntity(CABLE_CARS[1].doorLL)
        DeleteEntity(CABLE_CARS[0].doorLR)
        DeleteEntity(CABLE_CARS[1].doorLR)
        DeleteEntity(CABLE_CARS[0].doorRL)
        DeleteEntity(CABLE_CARS[1].doorRL)
        DeleteEntity(CABLE_CARS[0].doorRR)
        DeleteEntity(CABLE_CARS[1].doorRR)
    end
end)

function DrawCablecarText3D(text, x, y, z, s, font, a)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)

    if s == nil then
        s = 1.0
    end
    if font == nil then
        font = 4
    end
    if a == nil then
        a = 255
    end

    local scale = ((1 / dist) * 2) * s
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    if onScreen then
        if true then
            SetDrawOrigin(x, y, z, 0)
        end
        SetTextScale(0.0 * scale, 1.1 * scale)
        if true then
            SetTextFont(font)
        else
            SetTextFont(font)
        end
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, a)
        -- SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        if true then
            DrawText(0.0, 0.0)
            ClearDrawOrigin()
        else
            DrawText(_x, _y)
        end
    end
end

-- Control the movements of a car
function UpdateCablecarMovement(cablecar)
    if cablecar.state == "MOVE_UP" then

        -- Assign a directional value used to determine the moving direction of the car
        cablecar.direction = 1.0

        -- Get the previous node and the next node (basically the two points of the track on each side of us)
        local _prev, _next = TRACKS[cablecar.index][cablecar.gradient], TRACKS[cablecar.index][cablecar.gradient + 1]

        -- Initialize the segment distance if there is none already
        if cablecar.gradient_distance == 0.0 then
            cablecar.gradient_distance = GetDistanceBetweenCoords(_prev, _next, true)
        end

        -- Calculate the speed we want to move between segments
        local dist = cablecar.gradient_distance
        local speed = ((1.0 / dist) * Timestep()) * cablecar.speed
		
		local distanceFromOrigin = GetDistanceBetweenCoords(TRACKS[cablecar.index][#TRACKS[cablecar.index]], cablecar.position, true)
		local distanceFromDestin = GetDistanceBetweenCoords(TRACKS[cablecar.index][1], cablecar.position, true)
		if distanceFromOrigin <= cablecar.maxSpeedDistance then
			speed = speed * math.abs(distanceFromOrigin + 1)/cablecar.maxSpeedDistance
		elseif distanceFromDestin <= cablecar.maxSpeedDistance then
			speed = speed * math.abs(distanceFromDestin + 1)/cablecar.maxSpeedDistance
		end

        -- Add the speed to the timer
        cablecar.run_timer = cablecar.run_timer + speed

        -- Check if we've reached the end of the segment
        if cablecar.run_timer > 1.0 then

            -- Add one to the current node index we're at
            cablecar.gradient = cablecar.gradient + 1

            -- Get the next set of nodes
            _prev, _next = TRACKS[cablecar.index][cablecar.gradient], TRACKS[cablecar.index][cablecar.gradient + 1]
            cablecar.gradient_distance = GetDistanceBetweenCoords(_prev, _next, true)
            cablecar.run_timer = 0.0

            -- Check if we've reached the top
            if cablecar.gradient >= #TRACKS[cablecar.index] then
                cablecar.state = "MOVE_TO_IDLE_TOP"
                cablecar.gradient_distance = 0.0
                return
            end

            -- Update the cars hook angle
            UpdateCablecarGradient(cablecar)
        else
            -- Update the position of the car
            cablecar.position = VecLerp(_prev.x, _prev.y, _prev.z, _next.x, _next.y, _next.z, cablecar.run_timer, true)
        end

        -- Add a bit of "hang" on the long segments since the cable sags slightly (ATTENTION TO DETAIL!! xd)
        local zLerp = 0.0
        if cablecar.gradient_distance > 30.0 then
            zLerp = (-1.0 + math.abs(Lerp(1.0, -1.0, cablecar.run_timer))) * 0.25
        end

        -- Set the position of the car
        SetEntityCoords(cablecar.entity, cablecar.position + cablecar.offset + vector3(0.0, 0.0, zLerp), 1, false, 0, 1)
        GivePlayerOptionToJoinMyCablecar(cablecar, true)

    elseif cablecar.state == "MOVE_DOWN" then

        -- Assign a directional value used to determine the moving direction of the car
        cablecar.direction = -1.0

        -- Get the previous node and the next node (basically the two points of the track on each side of us)
        local _prev, _next = TRACKS[cablecar.index][cablecar.gradient], TRACKS[cablecar.index][cablecar.gradient - 1]

        -- Initialize the segment distance if there is none already
        if cablecar.gradient_distance == 0.0 then
            cablecar.gradient_distance = GetDistanceBetweenCoords(_prev, _next, true)
        end

        -- Calculate the speed we want to move between segments
        local dist = cablecar.gradient_distance
        local speed = ((1.0 / dist) * Timestep()) * cablecar.speed
		
		local distanceFromOrigin = GetDistanceBetweenCoords(TRACKS[cablecar.index][#TRACKS[cablecar.index]], cablecar.position, true)
		local distanceFromDestin = GetDistanceBetweenCoords(TRACKS[cablecar.index][1], cablecar.position, true)
		if distanceFromOrigin <= cablecar.maxSpeedDistance then
			speed = speed * math.abs(distanceFromOrigin + 1)/cablecar.maxSpeedDistance
		elseif distanceFromDestin <= cablecar.maxSpeedDistance then
			speed = speed * math.abs(distanceFromDestin + 1)/cablecar.maxSpeedDistance
		end

        -- Add the speed to the timer
        cablecar.run_timer = cablecar.run_timer + speed

        -- Check if we've reached the end of the segment
        if cablecar.run_timer > 1.0 then

            -- Take one from the current node index we're at, since we're going backwards
            cablecar.gradient = cablecar.gradient - 1

            -- Get the next set of nodes
            _prev, _next = TRACKS[cablecar.index][cablecar.gradient], TRACKS[cablecar.index][cablecar.gradient - 1]
            cablecar.gradient_distance = GetDistanceBetweenCoords(_prev, _next, true)
            cablecar.run_timer = 0.0

            -- Check if we've reached the bottom again
            if cablecar.gradient <= 1 then
                -- Set to raw idle to do nothing and ask the server to sync cars
                cablecar.state = "IDLE"
                cablecar.gradient_distance = 0.0
                TriggerServerEvent("omni:cablecar:host:sync", cablecar.index, "IDLE_BOTTOM")
                return
            end

            -- Update the cars hook angle
            UpdateCablecarGradient(cablecar)
        else
            cablecar.position = VecLerp(_prev.x, _prev.y, _prev.z, _next.x, _next.y, _next.z, cablecar.run_timer, true)
        end

        -- Add a bit of "hang" on the long segments since the cable sags slightly (ATTENTION TO DETAIL!! xd)
        local zLerp = 0.0
        if cablecar.gradient_distance > 20.0 then
            zLerp = (-1.0 + math.abs(Lerp(1.0, -1.0, cablecar.run_timer))) * 0.25
        end

        -- Set the position of the car
        SetEntityCoords(cablecar.entity, cablecar.position + cablecar.offset + vector3(0.0, 0.0, zLerp), 1, false, 0, 1)
        GivePlayerOptionToJoinMyCablecar(cablecar, true)

    elseif cablecar.state == "IDLE_TO_MOVE_UP" then

        cablecar.gradient = 1
        cablecar.gradient_distance = 0.0
        cablecar.run_timer = 0.0

        if cablecar.is_player_seated then
            -- add scenic camera
        else
            CheckIfPlayerShouldBeKickedOut(cablecar)
        end

        -- Close doors
        SetCablecarDoors(cablecar, false)

        cablecar.audio = GetSoundId()
        PlaySoundFromEntity(cablecar.audio, "Running", cablecar.entity, "CABLE_CAR_SOUNDS", 0, 0)

        cablecar.state = "MOVE_UP"

    elseif cablecar.state == "IDLE_TO_MOVE_DOWN" then

        cablecar.gradient = #TRACKS[cablecar.index]
        cablecar.gradient_distance = 0.0
        cablecar.run_timer = 0.0

        if cablecar.is_player_seated then
            -- add scenic camera
        else
            CheckIfPlayerShouldBeKickedOut(cablecar)
        end

        -- Close doors
        SetCablecarDoors(cablecar, false)

        cablecar.audio = GetSoundId()
        PlaySoundFromEntity(cablecar.audio, "Running", cablecar.entity, "CABLE_CAR_SOUNDS", 0, 0)

        cablecar.state = "MOVE_DOWN"

    elseif cablecar.state == "MOVE_TO_IDLE_TOP" then

        cablecar.position = TRACKS[cablecar.index][#TRACKS[cablecar.index]]
        SetEntityCoords(cablecar.entity, cablecar.position + cablecar.offset + vector3(0.0, 0.0, 0.0), 1, false, 0, 1)

        if cablecar.is_player_seated then
            -- kick player out
            -- KickPlayerOutOfMyCablecar(cablecar)
            -- cablecar.is_player_seated = false
        end

        -- Open doors
        SetCablecarDoors(cablecar, true)

        ReleaseRunningSound(cablecar)

        cablecar.state = "IDLE_TOP"
        cablecar.run_timer = 0.0

    elseif cablecar.state == "MOVE_TO_IDLE_BOTTOM" then

        cablecar.position = TRACKS[cablecar.index][1]
        SetEntityCoords(cablecar.entity, cablecar.position + cablecar.offset + vector3(0.0, 0.0, 0.0), 1, false, 0, 1)

        if cablecar.is_player_seated then
            -- kick player out
            -- KickPlayerOutOfMyCablecar(cablecar)
            -- cablecar.is_player_seated = false
        end

        -- Open doors
        SetCablecarDoors(cablecar, true)

        ReleaseRunningSound(cablecar)

        cablecar.state = "IDLE_BOTTOM"
        cablecar.run_timer = 0.0

    elseif cablecar.state == "IDLE_TOP" then

        -- Idle state for idling at the top station

        -- Wait 10 seconds (if that's even how it works lmao)
        cablecar.run_timer = cablecar.run_timer + (Timestep() / 20.0)

        -- If the time is up we start moving down
        if cablecar.run_timer > 1.0 then
            cablecar.state = "IDLE_TO_MOVE_DOWN"
            cablecar.run_timer = 0.0
        end

        GivePlayerOptionToJoinMyCablecar(cablecar)

    elseif cablecar.state == "IDLE_BOTTOM" then

        -- Idle state for idling at the bottom station

        -- Wait 10 seconds (if that's even how it works lmao)
        cablecar.run_timer = cablecar.run_timer + (Timestep() / 20.0)

        -- If the time is up we start moving up
        if cablecar.run_timer > 1.0 then
            cablecar.state = "IDLE_TO_MOVE_UP"
            cablecar.run_timer = 0.0
        end

        GivePlayerOptionToJoinMyCablecar(cablecar)

    elseif cablecar.state == "IDLE" then

        -- Just a default state, it does absolutely fuck all
        -- Used to halt movement until host and server sync is done

    end
end

function ReleaseRunningSound(cablecar)
    if cablecar.audio ~= -1 and cablecar.audio ~= nil then
        StopSound(cablecar.audio)
        ReleaseSoundId(cablecar.audio)
        cablecar.audio = -1
    end
end

function CheckIfPlayerShouldBeKickedOut(cablecar)
    local ply = PlayerPedId()
    local pos = cablecar.position + vector3(0.0, 0.0, -5.3)
    local plypos = GetEntityCoords(ply, true)
    local dist = #(pos - plypos)
    if dist < 3.0 then
        KickPlayerOutOfMyCablecar(cablecar)
    end
end

function KickPlayerOutOfMyCablecar(cablecar)
    local ply = PlayerPedId()
    cablecar.is_player_seated = false
    DetachEntity(ply, 0, 0)
    local _, rightvec, _ = GetEntityMatrix(cablecar.entity)
    local right = vector3(rightvec.x * 3.5, rightvec.y * 3.5, rightvec.z * 3.5)
    SetEntityCoords(ply, cablecar.position + right + vector3(0.0, 0.0, -5.3), xAxis, yAxis, zAxis, clearArea)
end

function GivePlayerOptionToJoinMyCablecar(cablecar, moving)
    local ply = PlayerPedId()
    local pos = cablecar.position + vector3(0.0, 0.0, -5.3)
    if not cablecar.is_player_seated then
        local plypos = GetEntityCoords(ply, true)
        local dist = #(pos - plypos)
        if dist < 3.0 then
            DrawCablecarText3D("Press ~g~E ~w~to enter the cablecar", pos.x, pos.y, pos.z + 1.0)
            if IsControlJustPressed(0, 38) then
                cablecar.is_player_seated = true
                AttachEntityToEntity(ply, cablecar.entity, 0, (plypos - cablecar.position), GetEntityRotation(ply, 0), 0, 0, 0, 1, 0, 0)
            end
        end
    else
        -- give player option to exit
        if not moving then
            DrawCablecarText3D("Press ~g~E ~w~to exit the cablecar", pos.x, pos.y, pos.z + 1.0)
            if IsControlJustPressed(0, 38) then
                cablecar.is_player_seated = false
                DetachEntity(ply, 0, 0)
            end
        end
    end
end

function SetCablecarDoors(cablecar, state)
    local doorOffset = 0.0
    if state == true then
        doorOffset = 2.0
        PlaySoundFromEntity(-1, "Arrive_Station", cablecar.entity, "CABLE_CAR_SOUNDS", 0, 0)
        PlaySoundFromEntity(-1, "DOOR_OPEN", cablecar.entity, "CABLE_CAR_SOUNDS", 0, 0)
    else
        doorOffset = 0.0
        PlaySoundFromEntity(-1, "Leave_Station", cablecar.entity, "CABLE_CAR_SOUNDS", 0, 0)
        PlaySoundFromEntity(-1, "DOOR_CLOSE", cablecar.entity, "CABLE_CAR_SOUNDS", 0, 0)
    end
    DetachEntity(cablecar.doorLL, 0, 0)
    DetachEntity(cablecar.doorLR, 0, 0)
    DetachEntity(cablecar.doorRL, 0, 0)
    DetachEntity(cablecar.doorRR, 0, 0)
    AttachEntityToEntity(cablecar.doorLL, cablecar.entity, 0, 0.0, doorOffset, 0.0, 0.0, 0.0, 0.0, 0, 0, 1, 0, 2, 1)
    AttachEntityToEntity(cablecar.doorLR, cablecar.entity, 0, 0.0, -doorOffset, 0.0, 0.0, 0.0, 0.0, 0, 0, 1, 0, 2, 1)
    AttachEntityToEntity(cablecar.doorRL, cablecar.entity, 0, 0.0, doorOffset, 0.0, 0.0, 0.0, 180.0, 0, 0, 1, 0, 2, 1)
    AttachEntityToEntity(cablecar.doorRR, cablecar.entity, 0, 0.0, -doorOffset, 0.0, 0.0, 0.0, 180.0, 0, 0, 1, 0, 2, 1)
end

-- Check what direction the specific car is going
function WhatDirectionDoesMyCablecarGo(cablecar)
    if cablecar.index == 0 then
        if cablecar.direction >= 0 then
            return 0
        else
            return 1
        end
    else
        -- since they start on opposing ends, the right car is reversed and treats up as down and down as up
        if cablecar.direction >= 0 then
            return 1
        else
            return 0
        end
    end
end

-- Set the hook angle using magical anims, doesn't work properly backwards but eh whatever
function UpdateCablecarGradient(cablecar)
    local text = "C" .. (cablecar.index + 1)
    if WhatDirectionDoesMyCablecarGo(cablecar) == 0 then
        local _data = {
            [0] = "_up_9",
            [1] = "_up_1",
            [3] = "_up_3",
            [5] = "_up_4",
            [7] = "_up_5",
            [9] = "_up_6",
            [11] = "_up_8",
            [12] = "_up_9",
        }
        if _data[cablecar.gradient - 1] then
            text = text .. _data[cablecar.gradient - 1]
        else
            return 0
        end
    else
        local _data = {
            [0] = "_down_1",
            [1] = "_down_2",
            [3] = "_down_3",
            [5] = "_down_4",
            [7] = "_down_5",
            [9] = "_down_6",
            [11] = "_down_8",
            [12] = "_down_9",
        }
        if _data[cablecar.gradient - 1] then
            text = text .. _data[cablecar.gradient - 1]
        else
            return 0
        end
    end
    PlayEntityAnim(cablecar.entity, text, "p_cablecar_s", 8.0, false, 1, 0, 0, 0)
    return 1
end
