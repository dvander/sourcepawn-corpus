#include <sourcemod>

#include <sdktools>

#define VERSION "1.0.0"
#define WORK_LIGHT_MODEL "models/props_equipment/light_floodlight.mdl"


public Plugin:myinfo =

{
	
	name = "No Mercy Sewer Light Remover",
	
	author = "AbyssStaresBack",
	
	description = "Removes the work light from No Mercy 3 that the infected can use to block the tunnel",
	
	version = VERSION,
	
	url = "http://forums.alliedmods.net/showthread.php?t=154097"

};

public OnPluginStart()

{
	
	CreateConVar("nomercysewerlight_ver", VERSION, "Version of the No Mercy Sewer Light plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
        HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()

{
    
	PrecacheModel("WORK_LIGHT_MODEL"); // Just in case
        
        if (IsSewerMap())
        {
              RemoveLight();
        }
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (IsSewerMap())
        {
              RemoveLight();
        }
}

RemoveLight()
{
        new currentEntity = -1;
		
        new entityToRemove = -1;
		
	while ((currentEntity = FindEntityByClassname(currentEntity, "prop_physics")) != -1)
		
        {
	      if (entityToRemove > 0)
			
              {
				
                    RemoveEdict(entityToRemove);
				
                    //LogMessage("NoMercy Sewer Light Removed!");
			
              }
			
              entityToRemove = -1;

              decl String:buffer[128];
			
              GetEntPropString(currentEntity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
			
              if (StrEqual(buffer, WORK_LIGHT_MODEL))
			
              {
				
                    entityToRemove = currentEntity;
			
              }
        }

	if (entityToRemove > 0)
		
        {
			
              RemoveEdict(entityToRemove);
			
              //LogMessage("NoMercy Sewer Light Removed!");
		
        }
}

stock IsSewerMap()
{
        new String:map[128];
	GetCurrentMap(map, sizeof(map));

        if (StrEqual(map, "c8m3_sewers", false))
        {
              return true;
        }
        return false;
}