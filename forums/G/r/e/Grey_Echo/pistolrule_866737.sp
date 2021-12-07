#include <sourcemod>
#include <sdktools_functions>

public Plugin:myinfo = {
	name = "PistolCamp",
	author = "Grey Echo",
	description = "Forces a player to use his or her pistol when he or she is crouching",
	version = "1.0.1",
	url = "http://www.ke0.us/"
};

new m_OffsetDuck;
new Weapon_Offset;
new Weapon_ID;
new weapon;
new cflags;

public OnPluginStart()
{
	m_OffsetDuck = FindSendPropOffs("CBasePlayer", "m_fFlags");
	Weapon_Offset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	HookEvent("bullet_impact",ev_bullet_impact);
}

public Action:ev_bullet_impact( Handle:event, const String:name[], bool:dontBroadcast )
{
	decl client;
	client = GetClientOfUserId(GetEventInt(event,"userid"));

	if ( (IsClientConnected(client)) && (IsClientInGame(client)) && !(IsFakeClient(client)) )
	{
		cflags = GetEntData(client, m_OffsetDuck);
		if( cflags & FL_DUCKING )
		{
			decl String:sWeapon[32];
			GetClientWeapon(client, sWeapon, sizeof(sWeapon));

			if ( !StrEqual("weapon_knife",sWeapon) && !StrEqual("weapon_p228",sWeapon) && !StrEqual("weapon_elite",sWeapon) && !StrEqual("weapon_fiveseven",sWeapon) && !StrEqual("weapon_usp",sWeapon) && !StrEqual("weapon_glock18",sWeapon) && !StrEqual("weapon_deagle",sWeapon) )
			{
				weapon = GetPlayerWeaponSlot(client, 1);

				if ( weapon != -1 )
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
				}
				else
				{
					Weapon_ID = GetEntDataEnt2(client, Weapon_Offset);
					RemovePlayerItem(client, Weapon_ID);
					RemoveEdict(Weapon_ID);
					GivePlayerItem(client, sWeapon);
					GivePlayerItem(client, "weapon_deagle");
				}
			}
		}
	}
}