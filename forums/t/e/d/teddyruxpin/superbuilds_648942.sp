#include <sourcemod>
#include <sdktools>
#include <events>
#include <clients> 
  
  #define PLUGIN_VERSION "1.0.0"
  
  // Plugin definitions
  public Plugin:myinfo =
 {
       name = "Super Buildables",
       author = "Teddy Ruxpin",
       description = "Allows Adjustments of buildable strength",
       version = PLUGIN_VERSION,
       url = "http://www.layeredtech.com"
 } 

new Handle:Cvar_Enable = INVALID_HANDLE;
new Handle:Cvar_SuperBuilds = INVALID_HANDLE;
new Handle:Cvar_MaxHealth = INVALID_HANDLE;
new Handle:Cvar_MinHealth = INVALID_HANDLE;

 
 
public OnPluginStart()
{
	Cvar_Enable = CreateConVar("sm_superbuilds_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_SuperBuilds = CreateConVar("sm_superbuilds", "1", "Buildable Objects with more health and ammo", FCVAR_PLUGIN);
	Cvar_MaxHealth = CreateConVar("sm_superbuilds_maxhealth", "1000");
	Cvar_MinHealth = CreateConVar("sm_superbuilds_minhealth", "500");

	
	HookEvent("player_builtobject", Event_player_builtobject)
   }

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
        if(!GetConVarInt(Cvar_Enable))
	{
		return Plugin_Continue;
	}
        if(!GetConVarInt(Cvar_SuperBuilds))
	{
		return Plugin_Continue;
	} 
	
	new strClassName[64]
	new MaxEntities = GetEntityCount()

	
	for (new i=1;i <= MaxEntities; i++)
    {
        if (IsValidEntity(i))
        {
            GetEntityNetClass(i, String:strClassName, 64)
            if (strcmp(String:strClassName, "CObjectSentrygun", true) == 0 || strcmp(String:strClassName, "CObjectDispenser", true) == 0 ||strcmp(String:strClassName, "CObjectTeleporter", true) 

== 0)
            {
				//Change the ojbects's health
				SetEntData( i , FindSendPropOffs("CObjectSentrygun","m_iMaxHealth") , GetConVarInt(Cvar_MaxHealth), 4, true );
				SetEntData( i , FindSendPropOffs("CObjectSentrygun","m_iHealth") , GetConVarInt(Cvar_MinHealth), 4, true );
			
                
            }
        }
	}
    
	return Plugin_Continue;
}