-- DropDwarf: PlayerModule stub
-- Overrides Roblox's default PlayerModule in StarterPlayerScripts.
-- The default PlayerModule's ControlModule intercepts Space and fires
-- Humanoid:ChangeState(Jumping) regardless of JumpHeight/JumpPower = 0,
-- which causes the GettingUp state recovery to pop the character upward.
-- This stub exposes the required interface but does nothing for movement/camera/jump.

local PlayerModule = {}

function PlayerModule:GetControls()   return {} end
function PlayerModule:GetCameras()    return {} end
function PlayerModule:GetClickToMove() return {} end

return PlayerModule
