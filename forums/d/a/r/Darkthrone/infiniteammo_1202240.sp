#include <sourcemod>
 
public Plugin:myinfo = {
	name = "Infinite Ammo",
	author = "Darkthrone, Twelve-60, twistedeuphoria",
	description = "Automatically gives players infinite ammo",
	version = "1.1",
	url = "http://forums.alliedmods.net/showthread.php?t=55381"
};

new activeoffset = 1896
new clipoffset = 1204
new maxclients = 0;

new Handle:enablecvar;

public OnPluginStart()
{
	enablecvar = CreateConVar("sm_iammo_enable", "1", "<0|1> 0 = disable infinite ammo; 1 = enable infinite ammo");
	activeoffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	clipoffset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
}

public OnMapStart()
{
	maxclients = GetMaxClients();
}

public OnGameFrame()
{
	if (GetConVarBool(enablecvar))
	{
		new entity;
		for (new i = 1; i <= maxclients; i++)
		{
			if (IsClientInGame(i))
			{
				entity = GetEntDataEnt2(i, activeoffset);
				if(IsValidEntity(entity))
				{
				    SetEntData(entity, clipoffset, 50, 4, true);
				}
			}
		}
	}
}
