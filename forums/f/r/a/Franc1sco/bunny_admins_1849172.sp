#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:auto[MAXPLAYERS+1];
new bool:easyb[MAXPLAYERS+1];

#define DATA "v2.1 by Franc1sco franug"

public Plugin:myinfo =
{
	name = "SM Admin bunnyhopping",
	author = "Franc1sco Steam: franug",
	description = "bunny for admins",
	version = DATA,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
    CreateConVar("sm_adminbunnyhopping", DATA, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);



    HookEvent("player_jump", PlayerJump);

    RegAdminCmd("sm_easy", Easy, ADMFLAG_CUSTOM1);
    RegAdminCmd("sm_auto", Easy2, ADMFLAG_CUSTOM1);


}

public Action:PlayerJump(Handle:event, const String:name[], bool:dontBroadcast) 
{
      new client = GetClientOfUserId(GetEventInt(event, "userid"));

      if(GetUserAdmin(client) == INVALID_ADMIN_ID || !easyb[client]) return;

      SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{

			if (IsPlayerAlive(client) && GetUserAdmin(client) != INVALID_ADMIN_ID && auto[client])
			{
				if (buttons & IN_JUMP)
				{
					if (!(GetEntityFlags(client) & FL_ONGROUND))
					{
						if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
						{
							new iType = GetEntProp(client, Prop_Data, "m_nWaterLevel");
							if (iType <= 1)
							{
								buttons &= ~IN_JUMP;
							}
						}
					}
				}
			}
	                return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
         auto[client] = false;
         easyb[client] = false;
}

public Action:Easy(client, args)
{
    if (!easyb[client])
    {
         easyb[client] = true;
         PrintToChat(client, "[SM_Franug-bunnyadmins] Now you have easy bunny");
    }
    else
    {
         easyb[client] = false;
         PrintToChat(client, "[SM_Franug-bunnyadmins] Now you not have easy bunny");
    }
}  

public Action:Easy2(client, args)
{
    if (!auto[client])
    {
         auto[client] = true;
         PrintToChat(client, "[SM_Franug-bunnyadmins] Now you have auto jump");
    }
    else
    {
         auto[client] = false;
         PrintToChat(client, "[SM_Franug-bunnyadmins] Now you not have auto jump");
    }
}  

