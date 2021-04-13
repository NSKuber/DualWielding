--Dual Wielding main script
--by NSKuber

--Preliminary setup

worldGlobals.DWScriptedGenericWeapons = {}
worldGlobals.DWUsedScriptedGenericWeapons = {}

worldGlobals.DWAbilitySounds = {}
worldGlobals.DWLastForcedNewAnim = {}
worldGlobals.DWLastChargedShot = {}

worldGlobals.DWSounds = {}

dofile("Content/Shared/Scripts/DualWielding/Database.lua")
dofile("Content/Shared/Scripts/DualWielding/DatabaseHD.lua")

local worldInfo = worldGlobals.worldInfo
local Pi = 3.14159265359

local strSwitchToDWCommand = "plcmdSwitchToDW"

if corIsAppEditor() then strSwitchToDWCommand = "plcmdUse" end

--player : CPlayerPuppetEntity

local qNullQuat = mthHPBToQuaternion(0,0,0)

--MAIN FUNCTION

local DWWeaponPathsFromIndex = {}

local LaserBarrelSequence = {"BarrelLU","BarrelLD","BarrelRU","BarrelRD"}
local iPosToWeaponNumBFE = {6,7,8,9,2,3,4,5}
local iPosToWeaponNumHD = {{3,1,2},{8,9,10,11,4,5,6,7}}

local rscButtonFocusSound
local rscWeaponSelectSound

worldGlobals.DWWeaponParams = {}
local PreviousWeaponIndex = {}

local iLastSelectedLeftWeapon = 1
local iLastSelectedRightWeapon = 1 
local iLastSelectedLeftWeaponHD = 3
local iLastSelectedRightWeaponHD = 3 

local fMouseSensitivity = 8

local bToNum = function(bBool)
  if bBool then return 1 else return 0 end
end

--Main function handling the DualWield weapon.
--Technically, 'Dual Wielding' is a singular weapon 
--with all others built in it using Weapon Engine
local HandleWeapon = function(player,weapon,ParamsTable)
RunAsync(function()

  local params = weapon:GetParams()
  local maxAmmo = 0
  local path = params:GetFileName()  

  local Weapons = ParamsTable["weapons"]  
  
  local iPosToWeaponNum = iPosToWeaponNumBFE
  local isHD = false
  for i=1,#Weapons,1 do
    if (string.find(Weapons[i]["name"],"HD") ~= nil) then
      isHD = true
      iPosToWeaponNum = iPosToWeaponNumHD
      break
    end
  end
  
  worldGlobals.DWWeaponParams[path] = {}
  local WeaponTools = {}
  
  for i=1,4,1 do
    player:ShowAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Right")
    player:ShowAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Left")
    player:HideAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Right")
    player:HideAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Left")
  end    
  
  for i=1,#Weapons,1 do
    worldGlobals.DWWeaponParams[path][i] = LoadResource(Weapons[i]["path"])
    WeaponTools[i] = LoadResource(Weapons[i]["tool"])
    
    player:ShowAttachmentOnWeapon(Weapons[i]["name"].."Left")
    player:ShowAttachmentOnWeapon(Weapons[i]["name"].."Right")  
    player:HideAttachmentOnWeapon(Weapons[i]["name"].."Left")
    player:HideAttachmentOnWeapon(Weapons[i]["name"].."Right")    
    
  end
  
  for i=1,#Weapons,1 do
    player:ShowAttachmentOnWeapon("Selection"..Weapons[i]["name"])
    player:HideAttachmentOnWeapon("Selection"..Weapons[i]["name"])
  end  

  --Automatically award pistol/colt in HD/BFE if not owned
  --So that Dual Wield can be used with some weapon
  local WeaponParams = worldGlobals.DWWeaponParams[path]
  if worldGlobals.netIsHost then
    RunAsync(function()
      Wait(Delay(0.25))
      if IsDeleted(weapon) then return end
      if isHD then
        if not player:HasWeaponInInventory(Weapons[3]["path"]) then
          player:AwardWeapon(WeaponParams[3])
        end
      else
        if not player:HasWeaponInInventory(Weapons[1]["path"]) then
          player:AwardWeapon(WeaponParams[1])
        end      
      end
      Wait(CustomEvent("OnStep"))
      if IsDeleted(weapon) then return end
      player:SelectWeapon(params)
    end)
  end    

  local iLaserLeftBarrel = 4
  local iLaserRightBarrel = 4  
  
  local iLeftWeapon
  if not isHD then
    iLeftWeapon = 1
    if player:IsLocalOperator() then iLeftWeapon = mthMinF(iLastSelectedLeftWeapon,#Weapons) end
  else
    iLeftWeapon = 3
    if player:IsLocalOperator() then iLeftWeapon = mthMinF(iLastSelectedLeftWeaponHD,#Weapons) end
  end
  
  local iRightWeapon
  if not isHD then
    iRightWeapon = 1
    if player:IsLocalOperator() then iRightWeapon = iLastSelectedRightWeapon end
  else
    iRightWeapon = 3
    if player:IsLocalOperator() then iRightWeapon = iLastSelectedRightWeaponHD end
  end
  
  while not player:HasWeaponInInventory(Weapons[iLeftWeapon]["path"]) do
    iLeftWeapon = (iLeftWeapon + #Weapons - 2) % #Weapons + 1
    if (isHD and (iLeftWeapon == 3)) or (not isHD and (iLeftWeapon == 1)) then break end
  end
  while not player:HasWeaponInInventory(Weapons[iRightWeapon]["path"]) do
    iRightWeapon = (iRightWeapon + #Weapons - 2) % #Weapons + 1
    if (isHD and (iRightWeapon == 3)) or (not isHD and (iRightWeapon == 1)) then break end
  end
  
  player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."Left")
  player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."ArmLeft")
  player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"]..LaserBarrelSequence[iLaserLeftBarrel].."Left")
  player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."Right")
  player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."ArmRight")    
  player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"]..LaserBarrelSequence[iLaserRightBarrel].."Right")
  
  if (rscButtonFocusSound == nil) then
    rscButtonFocusSound = LoadResource("Content/SeriousSamFusion/Sounds/Interface/ButtonFocusGain.wav")
    rscWeaponSelectSound = LoadResource("Content/Shared/Sounds/Interface/WeaponSwitch04.wav") 
  end
  local enButtonFocusSound
  local enWeaponSelectSound
  
  local bActivated = false
  if player:IsLocalOperator() then
    RunAsync(function()  
      Wait(Delay(0.1))
      if IsDeleted(weapon) then return end
      worldGlobals.DWSwitchWeapon(player,"0"..iLaserRightBarrel..iRightWeapon)
      worldGlobals.DWSwitchWeapon(player,"1"..iLaserLeftBarrel..iLeftWeapon)      
      Wait(Any(CustomEvent(weapon,"Activated"),Delay(0.1)))
      if IsDeleted(weapon) then return end
      worldGlobals.DWFire(player,0,0)
      bActivated = true      
    end)
  end
  
  --weapon : CWeaponEntity
  local fWeaponIndex = player:GetWeaponIndex(weapon:GetParams())
  local fDesiredWeaponIndex = fWeaponIndex

  local fLeftFiringTimer = 0
  local fLeftAnimTimer = 0
  local fRightFiringTimer = 0
  local fRightAnimTimer = 0
  
  local bFiringPrimary = false
  local bFiringSecondary = false
  local bChargingPrimary = false
  local bChargingSecondary = false
  
  local bFirePressed = false
  local bAltFirePressed = false  
  local bFireReleased = true
  local bAltFireReleased = true
  
  local bReloadPressed = false
  local bReloading = false 

  local bFreeToFireLeft = true
  local bFreeToFireRight = true
  local bFreeToAbility = true
  local bIsSwitchingWeapons = false
  local enLookTarget
  local vMousePos
  
  local iDesiredLeftWeapon
  local iDesiredRightWeapon
  local iPrevSelectedWeapon
  
  local bFireButtonsSwitched = false

  local bIsSelectionOpen = false
  local OwnedWeapons = {}
  
  local bIsSprinting = false
  local vDesiredTempo = player:GetDesiredTempoAbs()
  if (mthLenV3f(mthVector3f(vDesiredTempo.x,0,vDesiredTempo.z)) > 1) then bIsSprinting = true end  
  
  --Preliminary setup finished
  
  --RUNHANDLED STARTS
  RunHandled(function()
    while not IsDeleted(weapon) and not IsDeleted(player) do
      Wait(CustomEvent("OnStep"))
    end
    
    --When the weapon or the player are deleted, clean up 
    --and remember last used weapons for the next time
    if bIsSelectionOpen then
      if worldInfo:IsSinglePlayer() then
        worldInfo:SetRealTimeFactor(1,0.1)
      end
    end 
    
    if IsDeleted(player) then return end
    if not player:IsLocalOperator() then return end

    if isHD then
      iLastSelectedLeftWeaponHD = iLeftWeapon
      iLastSelectedRightWeaponHD = iRightWeapon         
    else
      iLastSelectedLeftWeapon = iLeftWeapon
      iLastSelectedRightWeapon = iRightWeapon     
    end
    
    if IsDeleted(weapon) then
      bIsSwitchingWeapons = false
      local bIsPressed = false
      while not IsDeleted(player) do
        if not player:IsAlive() then break end
        if (player:GetRightHandWeapon() ~= nil) then break end
        
        if player:IsCommandPressed("plcmdToggleLastWeapon") then
          if (PreviousWeaponIndex[player] ~= nil) then
            if (fDesiredWeaponIndex ~= PreviousWeaponIndex[player]) then
              fDesiredWeaponIndex = PreviousWeaponIndex[player]
            else
              fDesiredWeaponIndex = fWeaponIndex
            end
          end
        end        
        
        fDesiredWeaponIndex,bIsPressed = worldGlobals.DWCheckDesiredWeapon(player,fDesiredWeaponIndex)
        
        if bIsPressed and not bIsSwitchingWeapons then
          bIsSwitchingWeapons = true
          worldGlobals.DWWeaponSwitch(player,fDesiredWeaponIndex)
          break
        end 
        
        Wait(CustomEvent("OnStep"))   
            
      end
    end
    
  end,
  
  On(CustomEvent(weapon,"Deactivated")),
  function()
    bActivated = false
  end,
  
  --Handling charging weapons
  OnEvery(CustomEvent(player,"DWChargingLeft")),
  function()
  
    local fTimer = 0
  
    RunHandled(function()
      Wait(Any(CustomEvent(player,"DWFiredLeft"),CustomEvent(weapon,"Deactivated")))
    end,
    
    OnEvery(CustomEvent("OnStep")),
    function()
      fTimer = mthMinF(fTimer + worldInfo:SimGetStep(),Weapons[iLeftWeapon]["chargingStats"][1])
      if worldGlobals.netIsHost and ((Weapons[iLeftWeapon]["name"] == "Cannon") or (Weapons[iLeftWeapon]["name"] == "CannonHD")) then
        local DefObject = worldGlobals.WeaponScriptedFiringParams[path]["FireLeft"..Weapons[iLeftWeapon]["name"]][1]
        local iNum = mthRoundF(fTimer * 20)*5
        local fRealVel = DefObject["velocity"][1] + (DefObject["velocity"][2]-DefObject["velocity"][1]) * fTimer/1.25
        worldGlobals.CurrentWeaponScriptedParams[weapon]["FireLeft"..Weapons[iLeftWeapon]["name"]][1]["velocity"] = {fRealVel,fRealVel}
        if (Weapons[iLeftWeapon]["name"] == "CannonHD") then
          worldGlobals.CurrentWeaponScriptedParams[weapon]["FireLeft"..Weapons[iLeftWeapon]["name"]][1]["projectile"] = "Content/SeriousSamHD/Databases/Projectiles/DualWield/Canonball"..iNum..".ep"
        else
          worldGlobals.CurrentWeaponScriptedParams[weapon]["FireLeft"..Weapons[iLeftWeapon]["name"]][1]["projectile"] = "Content/SeriousSam3/Databases/Projectiles/DualWielding/Cannonballs/Canonball"..iNum..".ep"
        end
      end 
      
      if worldGlobals.netIsHost and (Weapons[iLeftWeapon]["name"] == "GL") then
        local DefObject = worldGlobals.WeaponScriptedFiringParams[path]["FireLeft"..Weapons[iLeftWeapon]["name"]][1]
        local fRealVel = DefObject["velocity"][1] + (DefObject["velocity"][2]-DefObject["velocity"][1]) * fTimer/0.5
        worldGlobals.CurrentWeaponScriptedParams[weapon]["FireLeft"..Weapons[iLeftWeapon]["name"]][1]["velocity"] = {fRealVel,fRealVel}        
      end           
    end)
  end,
  
  OnEvery(CustomEvent(player,"DWChargingRight")),
  function()
  
    local fTimer = 0
  
    RunHandled(function()
      Wait(Any(CustomEvent(player,"DWFiredRight"),CustomEvent(weapon,"Deactivated")))
    end,
    
    OnEvery(CustomEvent("OnStep")),
    function()
      fTimer = mthMinF(fTimer + worldInfo:SimGetStep(),Weapons[iRightWeapon]["chargingStats"][1])
      if worldGlobals.netIsHost and ((Weapons[iRightWeapon]["name"] == "Cannon") or (Weapons[iRightWeapon]["name"] == "CannonHD")) then
        local DefObject = worldGlobals.WeaponScriptedFiringParams[path]["FireRight"..Weapons[iRightWeapon]["name"]][1]
        local iNum = mthRoundF(fTimer * 20)*5
        local fRealVel = DefObject["velocity"][1] + (DefObject["velocity"][2]-DefObject["velocity"][1]) * fTimer/1.25
        worldGlobals.CurrentWeaponScriptedParams[weapon]["FireRight"..Weapons[iRightWeapon]["name"]][1]["velocity"] = {fRealVel,fRealVel}
        if (Weapons[iRightWeapon]["name"] == "CannonHD") then
          worldGlobals.CurrentWeaponScriptedParams[weapon]["FireRight"..Weapons[iRightWeapon]["name"]][1]["projectile"] = "Content/SeriousSamHD/Databases/Projectiles/DualWield/Canonball"..iNum..".ep"
        else
          worldGlobals.CurrentWeaponScriptedParams[weapon]["FireRight"..Weapons[iRightWeapon]["name"]][1]["projectile"] = "Content/SeriousSam3/Databases/Projectiles/DualWielding/Cannonballs/Canonball"..iNum..".ep"
        end
      end
      
      if worldGlobals.netIsHost and (Weapons[iRightWeapon]["name"] == "GL") then
        local DefObject = worldGlobals.WeaponScriptedFiringParams[path]["FireRight"..Weapons[iRightWeapon]["name"]][1]
        local fRealVel = DefObject["velocity"][1] + (DefObject["velocity"][2]-DefObject["velocity"][1]) * fTimer/0.5
        worldGlobals.CurrentWeaponScriptedParams[weapon]["FireRight"..Weapons[iRightWeapon]["name"]][1]["velocity"] = {fRealVel,fRealVel}        
      end
    end)
  end,  
  
  --Handling weapon switch on pickup of a new weapon
  OnEvery(CustomEvent(player,"DWPickedUpWeapon")),
  function(pay)
    fDesiredWeaponIndex = pay.index
  end,

  --Switch weapons (visuals)
  OnEvery(CustomEvent(player,"DWSwitchWeaponRight")),
  function(pay)  
    if (Weapons[iRightWeapon]["name"] == "Chainsaw") then
      worldGlobals.DWPlayRandom3DSound(player,"ChainsawBringDown",true)
    end    
    player:RemoveDesiredTool(WeaponTools[iRightWeapon])
    player:HideAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."Right")
    player:HideAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."ArmRight")
    for i=1,4,1 do
      player:HideAttachmentOnWeapon(Weapons[iRightWeapon]["name"]..LaserBarrelSequence[i].."Right")
    end
    iRightWeapon = pay.weapon
    player:AddDesiredTool(WeaponTools[iRightWeapon],true,nil)
    player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."Right")
    player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."ArmRight")
    player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"]..LaserBarrelSequence[pay.barrel].."Right")  
    if (Weapons[iRightWeapon]["name"] == "Chainsaw") then
      worldGlobals.DWPlayRandom3DSound(player,"ChainsawBringUp",true)
    end
  end,  
    
  OnEvery(CustomEvent(player,"DWSwitchWeaponLeft")),
  function(pay)
    if (Weapons[iLeftWeapon]["name"] == "Chainsaw") then
      worldGlobals.DWPlayRandom3DSound(player,"ChainsawBringDown",false)
    end
    player:RemoveDesiredTool(WeaponTools[iLeftWeapon])
    player:HideAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."Left")
    player:HideAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."ArmLeft")
    for i=1,4,1 do
      player:HideAttachmentOnWeapon(Weapons[iLeftWeapon]["name"]..LaserBarrelSequence[i].."Left")
    end
    iLeftWeapon = pay.weapon
    player:AddDesiredTool(WeaponTools[iLeftWeapon],true,nil)
    player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."Left")
    player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."ArmLeft")
    player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"]..LaserBarrelSequence[pay.barrel].."Left")
    if (Weapons[iLeftWeapon]["name"] == "Chainsaw") then
      worldGlobals.DWPlayRandom3DSound(player,"ChainsawBringUp",false)
    end    
  end,
  
  OnEvery(Delay(0.1)),
  function()
    if (Weapons[iLeftWeapon]["name"] == "Chainsaw") then
      SignalEvent(weapon,"ChainsawIdleLeft")
    end
    if (Weapons[iRightWeapon]["name"] == "Chainsaw") then
      SignalEvent(weapon,"ChainsawIdleRight")
    end    
  end,
  
  --KNIFE DAMAGING
  OnEvery(Any(CustomEvent(weapon,"FireLeftKnife"),CustomEvent(weapon,"FireRightKnife"))),
  function(pay)
    if not worldGlobals.netIsHost then return end
    
    local qvHitOrigin = player:GetLookOrigin()
    qvHitOrigin:SetVect(qvHitOrigin:GetVect()+2*mthQuaternionToDirection(qvHitOrigin:GetQuat()))
    
    local iKnifeIndex 
    if (pay.any.signaledIndex == 1) then
      iKnifeIndex = player:GetWeaponIndex(WeaponParams[iLeftWeapon])
    else
      iKnifeIndex = player:GetWeaponIndex(WeaponParams[iRightWeapon])
    end
    
    local locator = worldGlobals.DWTemplates:SpawnEntityFromTemplateByName("KnifeLocator",worldInfo,qvHitOrigin)
    local HitMonsters = {}
    
    local enHitMob
    
    local AllMobs = worldInfo:GetCharacters("","Evil",locator,20)
    for i=1,#AllMobs,1 do
      if locator:IsInside(AllMobs[i]) and player:CanSeeEntity(AllMobs[i]) then
        HitMonsters[#HitMonsters+1] = AllMobs[i]
      end
    end

    locator:Delete()
    
    local fClosestDist = 10000
    for _,monster in pairs(HitMonsters) do
      if (worldInfo:GetDistance(player,monster) < fClosestDist) then
        fClosestDist = worldInfo:GetDistance(player,monster)
        enHitMob = monster
      end
    end
    
    if (enHitMob ~= nil) then
      local damage = 100
      if (worldGlobals.WeaponEngineIsPlayerPoweredUp[player] > 0) then
        damage = damage * 4
      end
      worldGlobals.DWKnifeHitEffects(enHitMob)
      player:InflictDamageToTarget(enHitMob,damage,iKnifeIndex,"Cut")      
    else
      qvHitOrigin = player:GetLookOrigin()
      local enHitEntity,_,_ = CastRay(worldInfo,player,qvHitOrigin:GetVect(),mthQuaternionToDirection(qvHitOrigin:GetQuat()),3,1,"character_only_solids")
      if enHitEntity then
        if (enHitEntity:GetClassName() == "CStaticModelEntity") then
          player:InflictDamageToTarget(enHitEntity,100,iKnifeIndex,"Cut")          
        end
      end      
    end
  end,
    
  OnEvery(CustomEvent("OnStep")),
  function()

    if IsDeleted(player) or IsDeleted(weapon) then return end

    worldGlobals.DWDisplayNumber(weapon,player:GetAmmoForWeapon(WeaponParams[iRightWeapon]),player:GetMaxAmmoForWeapon(WeaponParams[iRightWeapon]),false,Weapons[iRightWeapon]["name"] == "Minigun")
    worldGlobals.DWDisplayNumber(weapon,player:GetAmmoForWeapon(WeaponParams[iLeftWeapon]),player:GetMaxAmmoForWeapon(WeaponParams[iLeftWeapon]),true,Weapons[iLeftWeapon]["name"] == "Minigun")  
    
    if not player:IsLocalOperator() then return end

    if IsDeleted(enLookTarget) then 
      for i=1,4,1 do
        player:ShowAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Right")
        player:ShowAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Left")
        player:HideAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Right")
        player:HideAttachmentOnWeapon("Laser"..LaserBarrelSequence[i].."Left")
      end    
      
      for i=1,#Weapons,1 do
        player:ShowAttachmentOnWeapon(Weapons[i]["name"].."Left")
        player:ShowAttachmentOnWeapon(Weapons[i]["name"].."Right")  
        player:HideAttachmentOnWeapon(Weapons[i]["name"].."Left")
        player:HideAttachmentOnWeapon(Weapons[i]["name"].."Right")    
      end 
      
      player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."Right")
      player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"]..LaserBarrelSequence[iLaserRightBarrel].."Right")
      player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."Left")
      player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"]..LaserBarrelSequence[iLaserRightBarrel].."Left")      
      
      enLookTarget = worldGlobals.DWTemplates:SpawnEntityFromTemplateByName("LookTarget",worldInfo,player:GetPlacement())
    end    
    
    if bIsSprinting then
      local vDesiredTempo = player:GetDesiredTempoAbs()
      if (mthLenV3f(mthVector3f(vDesiredTempo.x,0,vDesiredTempo.z)) <= 1) then 
        bIsSprinting = false 
        worldGlobals.DWFire(player,0,0)
      end
    end
    
    if bIsSprinting then return end
    
    --Scripted weapon switching (from the Dual Wield weapon to others)
    --Unfortunarely, PlayAnimOnWeapon() blocks the weapon
    --so it has to be 'deleted' manually from scripts 
    --to be switched from.
    if player:IsCommandPressed("plcmdToggleLastWeapon") then
      if (PreviousWeaponIndex[player] ~= nil) then
        if (fDesiredWeaponIndex ~= PreviousWeaponIndex[player]) then
          fDesiredWeaponIndex = PreviousWeaponIndex[player]
        else
          fDesiredWeaponIndex = fWeaponIndex
        end
      end
    end
    fDesiredWeaponIndex = worldGlobals.DWCheckDesiredWeapon(player,fDesiredWeaponIndex)
    
    if (fDesiredWeaponIndex == fWeaponIndex) then
      if player:IsCommandPressed(strSwitchToDWCommand) then 
        fDesiredWeaponIndex = player:GetWeaponIndex(WeaponParams[iRightWeapon])
      end
    end
      
    if (fDesiredWeaponIndex ~= fWeaponIndex) and not bIsSelectionOpen and bFreeToFireLeft and bFreeToFireRight and not bIsSwitchingWeapons then
          
      bIsSwitchingWeapons = true
      worldGlobals.DWWeaponPlayAnimClient(player,"Deactivate",0.1,false)
      Wait(Any(Delay(0.5),CustomEvent(weapon,"Switch")))
      worldGlobals.DWWeaponSwitch(player,fDesiredWeaponIndex)
      Wait(Delay(0.5))
      if not IsDeleted(weapon) then bIsSwitchingWeapons = false end
          
      return
          
    end

    --IF WEAPON SWITCHED OFF OR NOT ACTIVATED YET, DO NOTHING
    if not bActivated or bIsSwitchingWeapons then return end
    
    --Check which buttons are pressed
    bFirePressed = false
    bAltFirePressed = false        
    if not bIsSelectionOpen then
      if ((player:GetCommandValue("plcmdFire") > 0) and not bFireButtonsSwitched) or ((player:GetCommandValue("plcmdAltFire") > 0) and bFireButtonsSwitched) then bAltFirePressed = true end
      if ((player:GetCommandValue("plcmdAltFire") > 0) and not bFireButtonsSwitched) or ((player:GetCommandValue("plcmdFire") > 0) and bFireButtonsSwitched) then bFirePressed = true end      
    end
    
    OwnedWeapons = {}
    for i=1,#Weapons,1 do
      if player:HasWeaponInInventory(Weapons[i]["path"]) then
        if (WeaponParams[i] == nil) then
          WeaponParams[i] = LoadResource(Weapons[i]["path"])
        end                       
        OwnedWeapons[Weapons[i]["name"]] = WeaponParams[i]
      end
    end   
            
    --SWITCHING WEAPONS (INSIDE THE DUAL WIELDING)
    if (player:GetCommandValue("plcmdReload") > 0) then
    
      bFirePressed = false
      bAltFirePressed = false
    
      if player:IsCommandPressed("plcmdUse") then bFireButtonsSwitched = not bFireButtonsSwitched end
    
      if IsDeleted(enButtonFocusSound) then
        local qvPlace = player:GetPlacement()
        qvPlace.vy = qvPlace.vy + 1
        enButtonFocusSound = worldGlobals.DWTemplates:SpawnEntityFromTemplateByName("EmptySound",worldInfo,qvPlace)
        enButtonFocusSound:SetSound(rscButtonFocusSound)
        enButtonFocusSound:SetParent(player,"")
      end
      if IsDeleted(enWeaponSelectSound) then
        local qvPlace = player:GetPlacement()
        qvPlace.vy = qvPlace.vy + 1
        enWeaponSelectSound = worldGlobals.DWTemplates:SpawnEntityFromTemplateByName("EmptySound",worldInfo,qvPlace)
        enWeaponSelectSound:SetSound(rscWeaponSelectSound)
        enWeaponSelectSound:SetParent(player,"")
      end
    
      if not bIsSelectionOpen then
        bIsSelectionOpen = true
        vMousePos = mthVector3f(0,0,0)   
        if worldInfo:IsSinglePlayer() then
          worldInfo:SetRealTimeFactor(0.25,0.1)
        end
        for name,params in pairs(OwnedWeapons) do
          player:ShowAttachmentOnWeapon("Selection"..name)
        end
        player:ShowAttachmentOnWeapon("SelectionCursor")
      end
      
      local lookDir = player:GetLookDirEul()
      local qvLookTarget = player:GetLookOrigin()
      qvLookTarget:SetVect(qvLookTarget:GetVect()+1000*mthEulerToDirectionVector(lookDir))
      enLookTarget:SetPlacement(qvLookTarget)      
      player:SetLookTarget(enLookTarget)
      
      local fHMouseMovement = mthMaxF(player:GetCommandValue("plcmdMouseH-"),player:GetCommandValue("plcmdH-")) - mthMaxF(player:GetCommandValue("plcmdMouseH+"),player:GetCommandValue("plcmdH+"))
      local fPMouseMovement = mthMaxF(player:GetCommandValue("plcmdMouseP+"),player:GetCommandValue("plcmdP+")) - mthMaxF(player:GetCommandValue("plcmdMouseP-"),player:GetCommandValue("plcmdP-"))
      
      vMousePos.x = vMousePos.x + fHMouseMovement*worldInfo:SimGetStep()*fMouseSensitivity
      vMousePos.y = vMousePos.y + fPMouseMovement*worldInfo:SimGetStep()*fMouseSensitivity
      
      local selectedNum
      if isHD then
        vMousePos = mthMinF(mthLenV3f(vMousePos),0.8)*mthNormalize(vMousePos)
        local fRadius = mthLenV3f(vMousePos)
        local fAngle = mthMaxF(mthMinF(mthATan2F(vMousePos.x,vMousePos.y)/Pi*180 + 180,360-0.0001),0.0001)
        if (fRadius < 0.4) then
          selectedNum = iPosToWeaponNum[1][mthRoundF((fAngle + 60)/120)]
        else
          selectedNum = iPosToWeaponNum[2][mthRoundF(fAngle/45) % 8 + 1]
        end
      else
        vMousePos = mthMinF(mthLenV3f(vMousePos),0.72)*mthNormalize(vMousePos)
        local fRadius = mthLenV3f(vMousePos)
        local fAngle = mthMaxF(mthMinF(mthATan2F(vMousePos.x,vMousePos.y)/Pi*180 + 180,360-0.0001),0.0001)
        if (fRadius < 0.24) then
          selectedNum = 1
        else
          selectedNum = iPosToWeaponNum[mthRoundF(fAngle/45) % 8 + 1]
        end 
      end
      
      weapon:SetShaderArgValFloat("MouseX",0.5*(-1)*vMousePos.x)
      weapon:SetShaderArgValFloat("MouseY",0.5*vMousePos.y)      
      
      if (selectedNum ~= iPrevSelectedWeapon) and (selectedNum ~= nil) then
        if (OwnedWeapons[Weapons[selectedNum]["name"]] ~= nil) then
          enButtonFocusSound:PlayOnce()
        end
      end
      iPrevSelectedWeapon = selectedNum
      
      for i=1,#Weapons,1 do
        if (i == selectedNum) then
          weapon:SetShaderArgValFloat("Selected"..Weapons[i]["name"],0)
        else
          weapon:SetShaderArgValFloat("Selected"..Weapons[i]["name"],1)
        end
      end
      
      for name,params in pairs(OwnedWeapons) do
        if (player:GetMaxAmmoForWeapon(params) > 0) then
          weapon:SetShaderArgValFloat("Ammo"..name,mthMaxF(player:GetAmmoForWeapon(params),0)/player:GetMaxAmmoForWeapon(params))
        else
          weapon:SetShaderArgValFloat("Ammo"..name,-0.1)
        end
      end
      
      if ((player:IsCommandPressed("plcmdFire") and bFireButtonsSwitched) or (player:IsCommandPressed("plcmdAltFire") and not bFireButtonsSwitched)) and (selectedNum ~= nil) then
        if (OwnedWeapons[Weapons[selectedNum]["name"]] ~= nil) then
          if (player:GetAmmoForWeapon(WeaponParams[selectedNum]) >= 0) or (player:GetMaxAmmoForWeapon(WeaponParams[selectedNum]) <= 0) then
            iDesiredRightWeapon = selectedNum
            enWeaponSelectSound:PlayOnce()
          end
        end
      end
      if ((player:IsCommandPressed("plcmdFire") and not bFireButtonsSwitched) or (player:IsCommandPressed("plcmdAltFire") and bFireButtonsSwitched)) and (selectedNum ~= nil) then
        if (OwnedWeapons[Weapons[selectedNum]["name"]] ~= nil) then
          if (player:GetAmmoForWeapon(WeaponParams[selectedNum]) >= 0) or (player:GetMaxAmmoForWeapon(WeaponParams[selectedNum]) <= 0) then
            iDesiredLeftWeapon = selectedNum
            enWeaponSelectSound:PlayOnce()
          end
        end
      end      
      
    else
      if bIsSelectionOpen then
        if not IsDeleted(enLookTarget) then enLookTarget:Delete() end
        enLookTarget = worldGlobals.DWTemplates:SpawnEntityFromTemplateByName("LookTarget",worldInfo,player:GetPlacement())
        if worldInfo:IsSinglePlayer() then
          worldInfo:SetRealTimeFactor(1,0.1)
        end
        bIsSelectionOpen = false
        player:HideAttachmentOnWeapon("SelectionCursor")
        for i=1,#Weapons,1 do
          if player:HasWeaponInInventory(Weapons[i]["path"]) then
            player:HideAttachmentOnWeapon("Selection"..Weapons[i]["name"])
          end
        end
      end
    end
    
    --Force switch to prev weapon if ammo for the current one runs out
    if (player:GetAmmoForWeapon(WeaponParams[iLeftWeapon]) == 0) and (player:GetMaxAmmoForWeapon(WeaponParams[iLeftWeapon]) > 0) then
      iDesiredLeftWeapon = (iLeftWeapon + #Weapons - 2)% #Weapons + 1
      while true do
        while (OwnedWeapons[Weapons[iDesiredLeftWeapon]["name"]] == nil) do
          iDesiredLeftWeapon = (iDesiredLeftWeapon + #Weapons - 2)% #Weapons + 1
        end
        if (player:GetAmmoForWeapon(WeaponParams[iDesiredLeftWeapon]) == 0) and (player:GetMaxAmmoForWeapon(WeaponParams[iDesiredLeftWeapon]) > 0) then
          iDesiredLeftWeapon = (iDesiredLeftWeapon + #Weapons - 2)% #Weapons + 1
        else
          break
        end
      end
    end
    
    if (player:GetAmmoForWeapon(WeaponParams[iRightWeapon]) == 0) and (player:GetMaxAmmoForWeapon(WeaponParams[iRightWeapon]) > 0) then
      iDesiredRightWeapon = (iRightWeapon + #Weapons - 2)% #Weapons + 1
      while true do
        while (OwnedWeapons[Weapons[iDesiredRightWeapon]["name"]] == nil) do
          iDesiredRightWeapon = (iDesiredRightWeapon + #Weapons - 2)% #Weapons + 1
        end
        if (player:GetAmmoForWeapon(WeaponParams[iDesiredRightWeapon]) == 0) and (player:GetMaxAmmoForWeapon(WeaponParams[iDesiredRightWeapon]) > 0) then
          iDesiredRightWeapon = (iDesiredRightWeapon + #Weapons - 2)% #Weapons + 1
        else
          break
        end
      end
    end    
    
    if (iDesiredRightWeapon ~= nil) and bFreeToFireRight and bFreeToFireLeft then
      worldGlobals.DWSwitchWeapon(player,"0"..iLaserRightBarrel..iDesiredRightWeapon)
      iDesiredRightWeapon = nil
    end
    if (iDesiredLeftWeapon ~= nil) and bFreeToFireLeft and bFreeToFireRight then
      worldGlobals.DWSwitchWeapon(player,"1"..iLaserLeftBarrel..iDesiredLeftWeapon)
      iDesiredLeftWeapon = nil
    end
    
    local iAmmoLeft = player:GetAmmoForWeapon(WeaponParams[iLeftWeapon])
    if (Weapons[iLeftWeapon]["ammoCost"] == 0) then iAmmoLeft = 1 end
    local iAmmoRight = player:GetAmmoForWeapon(WeaponParams[iRightWeapon])
    if (Weapons[iRightWeapon]["ammoCost"] == 0) then iAmmoRight = 1 end
    
    local bChargedLeftThisFrame = false
    local bChargedRightThisFrame = false    
    local bFiredLeftThisFrame = false
    local bFiredRightThisFrame = false
    
    local bMinigunReleaseLeft = false
    local bMinigunReleaseRight = false
    
    local bGoToIdle = false
  
    
    --REGULAR PRIMARY FIRE WHEN HELD DOWN FOR OPERATOR
    if bFiringPrimary then

      --REGULAR ONE-TIME FIRING ANIM     
      fRightFiringTimer = fRightFiringTimer + worldInfo:SimGetStep()
      fRightAnimTimer = fRightAnimTimer + worldInfo:SimGetStep()      
        
      if (fRightFiringTimer >= Weapons[iRightWeapon]["firingStats"][1]) then
          
        if bFirePressed and (iAmmoRight > 0) and not Weapons[iRightWeapon]["regularChargeable"] and not bFreeToFireRight then
          
          fRightFiringTimer = fRightFiringTimer - Weapons[iRightWeapon]["firingStats"][1]
          fRightAnimTimer = 0
          bFiringPrimary = true
          bFreeToFireRight = false
          bFiredRightThisFrame = true
          
        else
          
          if ((Weapons[iRightWeapon]["name"] == "Minigun") or (Weapons[iRightWeapon]["name"] == "MinigunHD")) then
            if not bFreeToFireRight then
              bFiredRightThisFrame = true
              bMinigunReleaseRight = true
            end
            if (fRightFiringTimer >= 0.8) then
              bFiringPrimary = false
              fRightFiringTimer = 0
              fRightAnimTimer = 0              
            end
          elseif (Weapons[iRightWeapon]["name"] == "Chainsaw") then
            if not bFreeToFireRight then
              bFiredRightThisFrame = true
              bMinigunReleaseRight = true
            end
            if (fRightFiringTimer >= 0.25) then
              bFiringPrimary = false
              fRightFiringTimer = 0
              fRightAnimTimer = 0              
            end
          else
            bFiringPrimary = false
            fRightFiringTimer = 0
            fRightAnimTimer = 0         
          end
          
          bFreeToAbility = true
          bFreeToFireRight = true

          if not bChargingSecondary and not bFiringSecondary and not bFiringPrimary then     
            bGoToIdle = true
          end

        end
        
      end

    end
    
    --CHARGING PRIMARY
    if bChargingPrimary then
    
      fRightFiringTimer = mthMinF(fRightFiringTimer + worldInfo:SimGetStep(),Weapons[iRightWeapon]["chargingStats"][1])
      fRightAnimTimer = fRightAnimTimer + worldInfo:SimGetStep()    
          
      if (fRightFiringTimer >= Weapons[iRightWeapon]["chargingStats"][1]) or not bFirePressed then
        
        if (fRightFiringTimer < Weapons[iRightWeapon]["chargingStats"][1]) and not Weapons[iRightWeapon]["regularChargeable"] then
          bMinigunReleaseRight = true
          bFreeToFireRight = true
        end        
        
        if (Weapons[iRightWeapon]["name"] == "GL") then
          fRightFiringTimer = (Weapons[iRightWeapon]["chargingStats"][1] - fRightFiringTimer)/8*3
        elseif (Weapons[iRightWeapon]["name"] == "Cannon") or (Weapons[iRightWeapon]["name"] == "CannonHD") then
          fRightFiringTimer = (Weapons[iRightWeapon]["chargingStats"][1] - fRightFiringTimer)/5     
        else        
          fRightFiringTimer = 0
        end

        fRightAnimTimer = 0
        bChargingPrimary = false
        bFiringPrimary = true
        bFiredRightThisFrame = true
        
      end
      
    end  
        
    --REGULAR SECONDARY FIRE WHEN HELD DDWN FOR OPERATOR
    if bFiringSecondary then
      
      --REGULAR ONE-TIME FIRING ANIM
      fLeftFiringTimer = fLeftFiringTimer + worldInfo:SimGetStep()
      fLeftAnimTimer = fLeftAnimTimer + worldInfo:SimGetStep()
      

      if (fLeftFiringTimer >= Weapons[iLeftWeapon]["firingStats"][1]) then

        if bAltFirePressed and (iAmmoLeft > 0) and not Weapons[iLeftWeapon]["regularChargeable"] and not bFreeToFireLeft then
          fLeftFiringTimer = fLeftFiringTimer - Weapons[iLeftWeapon]["firingStats"][1]
          fLeftAnimTimer = 0         
          bFiringSecondary = true
          bFreeToFireLeft = false
          bFiredLeftThisFrame = true
        
        else
        
          if ((Weapons[iLeftWeapon]["name"] == "Minigun") or (Weapons[iLeftWeapon]["name"] == "MinigunHD")) then
            if not bFreeToFireLeft then
              bFiredLeftThisFrame = true
              bMinigunReleaseLeft = true
            end
            if (fLeftFiringTimer >= 0.8) then
              bFiringSecondary = false
              fLeftFiringTimer = 0
              fLeftAnimTimer = 0              
            end
          elseif (Weapons[iLeftWeapon]["name"] == "Chainsaw") then
            if not bFreeToFireLeft then
              bFiredLeftThisFrame = true
              bMinigunReleaseLeft = true
            end
            if (fLeftFiringTimer >= 0.25) then
              bFiringSecondary = false
              fLeftFiringTimer = 0
              fLeftAnimTimer = 0              
            end            
          else
            bFiringSecondary = false
            fLeftFiringTimer = 0
            fLeftAnimTimer = 0
          end          
        
          bFreeToAbility = true
          bFreeToFireLeft = true
       
          if not bFiringPrimary and not bChargingPrimary and not bFiringSecondary then     
            bGoToIdle = true
          end
          
        end
          
      end      
      
    end 
    
    --CHARGING SECONDARY
    if bChargingSecondary then
      
      fLeftFiringTimer = mthMinF(fLeftFiringTimer + worldInfo:SimGetStep(),Weapons[iLeftWeapon]["chargingStats"][1])
      fLeftAnimTimer = fLeftAnimTimer + worldInfo:SimGetStep()           
       
      if ((fLeftFiringTimer >= Weapons[iLeftWeapon]["chargingStats"][1]) or not bAltFirePressed) then
        
        if (fLeftFiringTimer < Weapons[iLeftWeapon]["chargingStats"][1]) and not Weapons[iLeftWeapon]["regularChargeable"] then
          bMinigunReleaseLeft = true
          bFreeToFireLeft = true
        end         

        if (Weapons[iLeftWeapon]["name"] == "GL") then
          fLeftFiringTimer = (Weapons[iLeftWeapon]["chargingStats"][1] - fLeftFiringTimer)/8*3
        elseif (Weapons[iLeftWeapon]["name"] == "Cannon") or (Weapons[iLeftWeapon]["name"] == "CannonHD") then
          fLeftFiringTimer = (Weapons[iLeftWeapon]["chargingStats"][1] - fLeftFiringTimer)/5  
        else        
          fLeftFiringTimer = 0
        end        
        
        fLeftAnimTimer = 0
        bFiringSecondary = true
        bChargingSecondary = false
        bFiredLeftThisFrame = true

      end
      
    end    
    
    --STARTING FIRE FOR OPERATOR
    if player:IsLocalOperator() then

      --REGULAR PRIMARY
      if bFreeToFireRight and bFirePressed and (iAmmoRight > 0) then

        bFreeToFireRight = false
        
        if ((Weapons[iRightWeapon]["name"] == "Minigun") or (Weapons[iRightWeapon]["name"] == "MinigunHD")) and (fRightFiringTimer > 0) then
          fRightFiringTimer = (0.8-fRightFiringTimer)/2
        else       
          fRightFiringTimer = 0
        end
        fRightAnimTimer = 0         
        
        if (Weapons[iRightWeapon]["chargingStats"] == nil) then 
          bFiredRightThisFrame = true 
          bFiringPrimary = true
          bChargingPrimary = false
        else
          bChargedRightThisFrame = true
          bChargingPrimary = true
          bFiringPrimary = false
        end
      end
      
      --REGULAR SECONDARY
      if bFreeToFireLeft and bAltFirePressed and (iAmmoLeft > 0) then

        bFreeToFireLeft = false

        if ((Weapons[iLeftWeapon]["name"] == "Minigun") or (Weapons[iLeftWeapon]["name"] == "MinigunHD")) and (fLeftFiringTimer > 0) then
          fLeftFiringTimer = (0.8-fLeftFiringTimer)/2
        else       
          fLeftFiringTimer = 0
        end
        fLeftAnimTimer = 0          

        if (Weapons[iLeftWeapon]["chargingStats"] == nil) then 
          bFiredLeftThisFrame = true
          bFiringSecondary = true
          bChargingSecondary = false
        else
          bChargedLeftThisFrame = true
          bChargingSecondary = true
          bFiringSecondary = false
        end        
      end    
    end
    
    --Encode the firing information to the server to sync to everyone
    if bFiredLeftThisFrame or bFiredRightThisFrame or bChargedLeftThisFrame or bChargedRightThisFrame then

      local iCodedBoolsLeft = bToNum(bFiredLeftThisFrame)*mthPow2F(0) + bToNum(bChargedLeftThisFrame)*mthPow2F(1) +
        bToNum(bFiringSecondary)*mthPow2F(2) + bToNum(bChargingSecondary)*mthPow2F(3) + bToNum(bMinigunReleaseLeft)*mthPow2F(4)
      if (iCodedBoolsLeft < 10) then iCodedBoolsLeft = "0"..iCodedBoolsLeft end
      local iCodedBoolsRight = bToNum(bFiredRightThisFrame)*mthPow2F(0) + bToNum(bChargedRightThisFrame)*mthPow2F(1) +
        bToNum(bFiringPrimary)*mthPow2F(2) + bToNum(bChargingPrimary)*mthPow2F(3) + bToNum(bMinigunReleaseRight)*mthPow2F(4)    
      if (iCodedBoolsRight < 10) then iCodedBoolsRight = "0"..iCodedBoolsRight end
          
      local iFrameLeft = 0
      if bFiringSecondary then iFrameLeft = mthMinF(mthCeilF(fLeftAnimTimer/Weapons[iLeftWeapon]["firingStats"][2]),Weapons[iLeftWeapon]["firingStats"][3]) end
      if bChargingSecondary then iFrameLeft = mthMinF(mthCeilF(fLeftAnimTimer/Weapons[iLeftWeapon]["chargingStats"][2]),Weapons[iLeftWeapon]["chargingStats"][3]) end
      if (iFrameLeft < 10) then iFrameLeft = "0"..iFrameLeft end
        
      local iFrameRight = 0
      if bFiringPrimary then iFrameRight = mthMinF(mthCeilF(fRightAnimTimer/Weapons[iRightWeapon]["firingStats"][2]),Weapons[iRightWeapon]["firingStats"][3]) end
      if bChargingPrimary then iFrameRight = mthMinF(mthCeilF(fRightAnimTimer/Weapons[iRightWeapon]["chargingStats"][2]),Weapons[iRightWeapon]["chargingStats"][3]) end
      if (iFrameRight < 10) then iFrameRight = "0"..iFrameRight end
          
      worldGlobals.DWFire(player,iCodedBoolsLeft*100000 + iFrameLeft*1000 + iLeftWeapon*10 + iLaserLeftBarrel,
                                 iCodedBoolsRight*100000 + iFrameRight*1000 + iRightWeapon*10 + iLaserRightBarrel)
      
      if bFiredLeftThisFrame and (Weapons[iLeftWeapon]["name"] == "Laser") then
        iLaserLeftBarrel = iLaserLeftBarrel % 4 + 1
      end
      if bFiredRightThisFrame and (Weapons[iRightWeapon]["name"] == "Laser") then
        iLaserRightBarrel = iLaserRightBarrel % 4 + 1
      end      
      
    elseif bGoToIdle then worldGlobals.DWFire(player,0,0) end
  
  end)
  
end)

end

worldGlobals.CreateRPC("client","reliable","DWAwardAndSelectWeapon",function(player,path,num)
  
  if (#worldGlobals.DWScriptedGenericWeapons[path]["weapons"] == 9) then
    iLastSelectedLeftWeapon = num
    iLastSelectedRightWeapon = num
  else
    iLastSelectedLeftWeaponHD = num
    iLastSelectedRightWeaponHD = num
  end
  
  local tempParams = LoadResource(path)
  if worldGlobals.netIsHost then
    if not player:HasWeaponInInventory(path) then
      player:AwardWeapon(tempParams)
    end
    player:SelectWeapon(tempParams)
  end
                      
end)

--Main player handling functions
local IsHandled = {}

local HandlePlayer = function(player)
  RunAsync(function()
  
    local fIndex
    
    while not IsDeleted(player) do
      local weapon = player:GetRightHandWeapon()
      if weapon then
        if not IsHandled[weapon] then
          IsHandled[weapon] = true
          
          if (fIndex ~= player:GetWeaponIndex(weapon:GetParams())) then
            PreviousWeaponIndex[player] = fIndex
          end
          fIndex = player:GetWeaponIndex(weapon:GetParams())          
          
          local path = weapon:GetParams():GetFileName()
          if (worldGlobals.DWScriptedGenericWeapons[path] ~= nil) then 
            HandleWeapon(player,weapon,worldGlobals.DWScriptedGenericWeapons[path])
          end
          
          while not IsDeleted(weapon) do
            if player:IsCommandPressed(strSwitchToDWCommand) then
              for pathDW,Table in pairs(worldGlobals.DWScriptedGenericWeapons) do
                for num,weaponTable in pairs(Table["weapons"]) do
                  if (weaponTable["path"] == path) then
                    worldGlobals.DWAwardAndSelectWeapon(player,pathDW,num)
                  end
                end
              end
            end
            Wait(CustomEvent("OnStep"))
          end
          
        else
          Wait(CustomEvent("OnStep"))
        end
      else
        Wait(CustomEvent("OnStep"))
      end
      
    end  
  end)
end

Wait(CustomEvent("OnStep"))

while true do
  local Players = worldInfo:GetAllPlayersInRange(worldInfo,10000)
  for i=1,#Players,1 do
    if not IsHandled[Players[i]] then
      IsHandled[Players[i]] = true
      HandlePlayer(Players[i])
    end
  end

  Wait(CustomEvent("OnStep"))
end