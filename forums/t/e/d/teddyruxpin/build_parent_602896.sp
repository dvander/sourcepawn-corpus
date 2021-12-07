#include <sourcemod>
#include <sdktools>
#include <events>
#include <clients> 
  
  #define PLUGIN_VERSION "1.0.0"
  
  // Plugin definitions
  public Plugin:myinfo =
 {
       name = "Buildable Parenting",
       author = "WoZeR - Teddy Ruxpin",
       description = "Allows buildable objects to parent with moving entities",
       version = PLUGIN_VERSION,
       url = "http://www.layeredtech.com"
 } 

public OnPluginStart()
   {
       HookEvent("player_builtobject", Event_player_builtobject)
   }

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)


{
    new strClassName[64]
    new MaxEntities = GetEntityCount()
    new Float:vecObjectPos[3]
    new Float:vecCheckBelow[3]
    
    for (new i=1;i <= MaxEntities; i++)
    {
        if (IsValidEntity(i))
        {
            GetEntityNetClass(i, String:strClassName, 64)
            if (strcmp(String:strClassName, "CObjectSentrygun", true) == 0 || strcmp(String:strClassName, "CObjectDispenser", true) == 0 || strcmp(String:strClassName, "CObjectTeleporter", true) == 0)
            {
                //Get the object's position
                GetEntDataVector(i, FindSendPropInfo("CPhysicsProp", "m_vecOrigin"), vecObjectPos)
                
                //Check below the object for an existing entity to parent to
                vecCheckBelow[0] = vecObjectPos[0]
                vecCheckBelow[1] = vecObjectPos[1]
                vecCheckBelow[2] = vecObjectPos[2] - 50.0
                
                //Check for colliding entities
                TR_TraceRayFilter(vecObjectPos, vecCheckBelow, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayDontHitSelf, i)

                if (TR_DidHit(INVALID_HANDLE))
                {
                    new TRIndex = TR_GetEntityIndex(INVALID_HANDLE)
                    if (TRIndex > 32) //Don't attach to players
                    {
                        //This part can be redone since BAILOPIN added the ability to read a string_t
                        new String:strTargetName[64]
                        IntToString(TRIndex, strTargetName, 64)
                    
                        DispatchKeyValue(TRIndex, "targetname", strTargetName)
                        
                        SetVariantString(strTargetName)
                        AcceptEntityInput(i, "SetParent", -1, -1, 0)

                        //PrintToServer("Setting MoveParent TRIndex %i", TRIndex)
                    }
                }
            }
        }
    }
    
    return Plugin_Continue
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    if(entity == data) // Check if the TraceRay hit the owning entity.
    {
        return false // Don't let the entity be hit
    }
    
    return true // It didn't hit itself
}


  

