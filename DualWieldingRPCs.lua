--RPCs for the Dual Wielding mod
--by NSKuber

local worldInfo = worldGlobals.worldInfo

local LaserBarrelSequence = {"BarrelLU","BarrelLD","BarrelRU","BarrelRD"}
local bIsInfiniteAmmoEnabled = false

local getBit = function(num,i)
  num = num % mthPow2F(i)
  if (num < mthPow2F(i-1)) then return false else return true end
end

--Function which actually executes weapon firing animations
local ExecuteAction = function(player,iCodedDataLeft,iCodedDataRight)
  if IsDeleted(player) then return end
  local weapon = player:GetRightHandWeapon()
  if IsDeleted(weapon) then return end
  local path = weapon:GetParams():GetFileName()
  
  local Weapons = worldGlobals.DWScriptedGenericWeapons[path]["weapons"]
  local WeaponParams = worldGlobals.DWWeaponParams[path]
  
  --print(iCodedDataLeft.." "..iCodedDataRight)
  iCodedDataLeft = mthRoundF(iCodedDataLeft)
  iCodedDataRight = mthRoundF(iCodedDataRight)
  
  local bGoToIdle,bFiredLeftThisFrame,bChargedLeftThisFrame,bFiringSecondary,bChargingSecondary,bMinigunReleaseLeft,
        iFrameLeft,iLeftWeapon,iLaserLeftBarrel,bFiredRightThisFrame,bChargedRightThisFrame,bFiringPrimary,
        bChargingPrimary,bMinigunReleaseRight,iFrameRight,iRightWeapon,iLaserRightBarrel
  
  if (iCodedDataLeft == 0) then bGoToIdle = true
  else
    local iCodedBoolsLeft = mthFloorF(iCodedDataLeft/100000)
    bFiredLeftThisFrame = getBit(iCodedBoolsLeft,1)
    bChargedLeftThisFrame = getBit(iCodedBoolsLeft,2)
    bFiringSecondary = getBit(iCodedBoolsLeft,3)
    bChargingSecondary = getBit(iCodedBoolsLeft,4)
    bMinigunReleaseLeft = getBit(iCodedBoolsLeft,5)
    
    iFrameLeft = mthFloorF(iCodedDataLeft/1000) % 100
    iLeftWeapon = mthFloorF(iCodedDataLeft/10) % 100
    iLaserLeftBarrel = iCodedDataLeft % 10
    
    
    local iCodedBoolsRight = mthFloorF(iCodedDataRight/100000)
    bFiredRightThisFrame = getBit(iCodedBoolsRight,1)
    bChargedRightThisFrame = getBit(iCodedBoolsRight,2)
    bFiringPrimary = getBit(iCodedBoolsRight,3)
    bChargingPrimary = getBit(iCodedBoolsRight,4)
    bMinigunReleaseRight = getBit(iCodedBoolsRight,5)
    iFrameRight = mthFloorF(iCodedDataRight/1000) % 100
    iRightWeapon = mthFloorF(iCodedDataRight/10) % 100
    iLaserRightBarrel = iCodedDataRight % 10
    
  end

  --PLAYING ALL ANIMS
  if bFiredLeftThisFrame or bFiredRightThisFrame or bChargedLeftThisFrame or bChargedRightThisFrame then
    local strAnimName = ""

    --LEFT
    if bFiredLeftThisFrame then
      SignalEvent(player,"DWFiredLeft")
      strAnimName = strAnimName.."Fire0"
      SignalEvent(player,"DWStopSound"..Weapons[iLeftWeapon]["name"].."ChargeLeft")
      if not bMinigunReleaseLeft then
        
        if (Weapons[iLeftWeapon]["name"] == "Laser") then
          player:HideAttachmentOnWeapon(Weapons[iLeftWeapon]["name"]..LaserBarrelSequence[iLaserLeftBarrel].."Left")
          iLaserLeftBarrel = iLaserLeftBarrel % 4 + 1
          worldGlobals.CurrentWeaponScriptedParams[weapon]["FireLeftLaser"][1]["source"] = LaserBarrelSequence[iLaserLeftBarrel].."Left" 
          player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"]..LaserBarrelSequence[iLaserLeftBarrel].."Left")
        end
        
        if worldGlobals.netIsHost and not bIsInfiniteAmmoEnabled then
          player:SetAmmoForWeapon(WeaponParams[iLeftWeapon],player:GetAmmoForWeapon(WeaponParams[iLeftWeapon]) - Weapons[iLeftWeapon]["ammoCost"])
        end
        
        player:ShowAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."MuzzleLeft")
        RunAsync(function()
          Wait(Delay(0.025))
          player:HideAttachmentOnWeapon(Weapons[iLeftWeapon]["name"].."MuzzleLeft")
        end)     
        RunAsync(function()
          SignalEvent(weapon,"Fire"..Weapons[iLeftWeapon]["name"].."Sound")
          SignalEvent(weapon,"FireLeft"..Weapons[iLeftWeapon]["name"],{index = player:GetWeaponIndex(WeaponParams[iLeftWeapon])})
        end)
        if (Weapons[iLeftWeapon]["name"] == "Minigun") or (Weapons[iLeftWeapon]["name"] == "MinigunHD") then 
          SignalEvent(weapon,"RotateLeft"..Weapons[iLeftWeapon]["name"])
          SignalEvent(weapon,"DWStopSound"..Weapons[iLeftWeapon]["name"].."SpinDownLeft")
        end
      else
        if (Weapons[iLeftWeapon]["name"] == "Chainsaw") then
          worldGlobals.DWPlayRandom3DSound(player,Weapons[iLeftWeapon]["name"].."End",false)
        else
          worldGlobals.DWPlayRandom3DSound(player,Weapons[iLeftWeapon]["name"].."SpinDown",false)
          worldGlobals.DWPlayRandom3DSound(player,Weapons[iLeftWeapon]["name"].."Click",false)
        end
      end
        
    elseif bChargedLeftThisFrame then
      SignalEvent(player,"DWChargingLeft")
      strAnimName = strAnimName.."Charge0"
      worldGlobals.DWPlayRandom3DSound(player,Weapons[iLeftWeapon]["name"].."Charge",false)
      if (Weapons[iLeftWeapon]["name"] == "Minigun") or (Weapons[iLeftWeapon]["name"] == "MinigunHD") then
        worldGlobals.DWPlayRandom3DSound(player,Weapons[iLeftWeapon]["name"].."Click",false)
      end
    elseif bFiringSecondary then
      strAnimName = strAnimName.."Fire"..iFrameLeft
    elseif bChargingSecondary then
      strAnimName = strAnimName.."Charge"..iFrameLeft
    else
      strAnimName = strAnimName.."Idle"
    end

    --RIGHT
    if bFiredRightThisFrame then
      SignalEvent(player,"DWFiredRight")
      strAnimName = strAnimName.."Fire0"
      SignalEvent(player,"DWStopSound"..Weapons[iRightWeapon]["name"].."ChargeRight")
      if not bMinigunReleaseRight then
        
        if (Weapons[iRightWeapon]["name"] == "Laser") then
          player:HideAttachmentOnWeapon(Weapons[iRightWeapon]["name"]..LaserBarrelSequence[iLaserRightBarrel].."Right")
          iLaserRightBarrel = iLaserRightBarrel % 4 + 1
          worldGlobals.CurrentWeaponScriptedParams[weapon]["FireRightLaser"][1]["source"] = LaserBarrelSequence[iLaserRightBarrel].."Right"
          player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"]..LaserBarrelSequence[iLaserRightBarrel].."Right")
        end        
        
        if worldGlobals.netIsHost and not bIsInfiniteAmmoEnabled then
          player:SetAmmoForWeapon(WeaponParams[iRightWeapon],player:GetAmmoForWeapon(WeaponParams[iRightWeapon]) - Weapons[iRightWeapon]["ammoCost"])
        end
        
        player:ShowAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."MuzzleRight")
        RunAsync(function()
          Wait(Delay(0.025))
          player:HideAttachmentOnWeapon(Weapons[iRightWeapon]["name"].."MuzzleRight")
        end)
        RunAsync(function()
          SignalEvent(weapon,"Fire"..Weapons[iRightWeapon]["name"].."Sound")
          SignalEvent(weapon,"FireRight"..Weapons[iRightWeapon]["name"],{index = player:GetWeaponIndex(WeaponParams[iRightWeapon])})
        end)
        if (Weapons[iRightWeapon]["name"] == "Minigun") or (Weapons[iRightWeapon]["name"] == "MinigunHD") then 
          SignalEvent(weapon,"RotateRight"..Weapons[iRightWeapon]["name"])
          SignalEvent(weapon,"DWStopSound"..Weapons[iRightWeapon]["name"].."SpinDownRight") 
        end
      else
        if (Weapons[iRightWeapon]["name"] == "Chainsaw") then
          worldGlobals.DWPlayRandom3DSound(player,Weapons[iRightWeapon]["name"].."End",false)
        else        
          worldGlobals.DWPlayRandom3DSound(player,Weapons[iRightWeapon]["name"].."SpinDown",true)
          worldGlobals.DWPlayRandom3DSound(player,Weapons[iRightWeapon]["name"].."Click",true)
        end
      end
    elseif bChargedRightThisFrame then
      SignalEvent(player,"DWChargingRight")
      strAnimName = strAnimName.."Charge0"
      worldGlobals.DWPlayRandom3DSound(player,Weapons[iRightWeapon]["name"].."Charge",true)
      if (Weapons[iRightWeapon]["name"] == "Minigun") or (Weapons[iRightWeapon]["name"] == "MinigunHD") then
        worldGlobals.DWPlayRandom3DSound(player,Weapons[iRightWeapon]["name"].."Click",true)
      end        
    elseif bFiringPrimary then
      strAnimName = strAnimName.."Fire"..iFrameRight
    elseif bChargingPrimary then
      strAnimName = strAnimName.."Charge"..iFrameRight
    else
      strAnimName = strAnimName.."Idle"
    end      
    
    player:PlayCustomAnimOnWeapon(strAnimName,0,false)
  elseif bGoToIdle then
    player:PlayCustomAnimOnWeapon("IdleIdle",0.1,true)
  end
end

--Syncing 'Fire' to and from server
if not worldInfo:IsSinglePlayer() then
  worldGlobals.CreateRPC("server","reliable","DWFireServer",function(player,iCodedDataLeft,iCodedDataRight)
    if IsDeleted(player) then return end
    if player:IsLocalOperator() then return end
    ExecuteAction(player,iCodedDataLeft,iCodedDataRight)
  end)
else
  worldGlobals.DWFireServer = function(player,iCodedDataLeft,iCodedDataRight)
    if IsDeleted(player) then return end
    if player:IsLocalOperator() then return end
    ExecuteAction(player,iCodedDataLeft,iCodedDataRight)
  end
end

worldGlobals.CreateRPC("client","reliable","DWFire",function(player,iCodedDataLeft,iCodedDataRight)
  if IsDeleted(player) then return end
  if player:IsLocalOperator() then
    ExecuteAction(player,iCodedDataLeft,iCodedDataRight)
  end
  if worldGlobals.netIsHost then
    worldGlobals.DWFireServer(player,iCodedDataLeft,iCodedDataRight)
  end
end)

--Syncing weapon switching
local SwitchWeapon = function(player,strCodedData)
  if IsDeleted(player) then return end
  if (string.sub(strCodedData,1,1) == "0") then
    SignalEvent(player,"DWSwitchWeaponRight",{weapon = tonumber(string.sub(strCodedData,3,-1)), barrel = tonumber(string.sub(strCodedData,2,2))})
  else
    SignalEvent(player,"DWSwitchWeaponLeft",{weapon = tonumber(string.sub(strCodedData,3,-1)), barrel = tonumber(string.sub(strCodedData,2,2))})
  end
end

if not worldInfo:IsSinglePlayer() then
  worldGlobals.CreateRPC("server","reliable","DWSwitchServer",function(player,strData)
    if IsDeleted(player) then return end
    if player:IsLocalOperator() then return end
    SwitchWeapon(player,strData)
  end)
else
  worldGlobals.DWSwitchServer = function(player,strData)
    if IsDeleted(player) then return end
    if player:IsLocalOperator() then return end
    SwitchWeapon(player,strData)
  end
end

worldGlobals.CreateRPC("client","reliable","DWSwitchWeapon",function(player,strData)
  if IsDeleted(player) then return end
  if player:IsLocalOperator() then
    SwitchWeapon(player,strData)
  end
  if worldGlobals.netIsHost then
    worldGlobals.DWSwitchServer(player,strData)
  end
end)

--Syncing playing an animation on the weapon
worldGlobals.CreateRPC("server","reliable","DWWeaponPlayAnimServer",function(player,name,fIn,bLoop)
  if IsDeleted(player) then return end
  if not player:IsLocalOperator() then
    player:PlayCustomAnimOnWeapon(name,fIn,bLoop)
  end
end)

worldGlobals.CreateRPC("client","reliable","DWWeaponPlayAnimClient",function(player,name,fIn,bLoop)
  if IsDeleted(player) then return end
  if player:IsLocalOperator() then
    player:PlayCustomAnimOnWeapon(name,fIn,bLoop)
  end
  if worldGlobals.netIsHost and not worldInfo:IsSinglePlayer() then
    worldGlobals.DWWeaponPlayAnimServer(player,name,fIn,bLoop)
  end
end)

worldGlobals.CreateRPC("server","reliable","DWSendWeaponPickupSwitch",function(player,i)
  if not IsDeleted(player) then
    if player:IsLocalOperator() then
      SignalEvent(player,"DWPickedUpWeapon",{index = i})
    end
  end
end)

worldGlobals.CreateRPC("client","reliable","DWWeaponSwitch",function(player,fIndex)
  if worldGlobals.netIsHost then
    player:DisableWeapons()
    Wait(CustomEvent("OnStep"))
    player:EnableWeapons()
    player:SelectWeapon(worldInfo:GetWeaponParamsForIndex(fIndex))
  end
end)

RunHandled(WaitForever,

OnEvery(Delay(1)),
function()
  string = prjGetCustomOccasion()
  local config = string.match(string, "{InfiniteAmmo=.-}")
  if not (config == nil) then
    local arg = string.sub(config,15,-2)
    if (arg == "1") then
      bIsInfiniteAmmoEnabled = true
    else
      bIsInfiniteAmmoEnabled = false
    end
  end
end)