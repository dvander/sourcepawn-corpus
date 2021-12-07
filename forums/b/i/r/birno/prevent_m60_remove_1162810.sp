#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Prevent M60 Remove"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Psycho Dad - Based on DJ_WEST code"

#define M60_CLASS "weapon_rifle_m60"

new g_ActiveWeaponOffset 

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Prevent the M60 remove when it empty",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	HookEvent("round_start", Event_Round_Start);
}

public Action:Event_Round_Start(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	new i_Client = GetClientOfUserId(GetEventInt(h_Event, "userid"))
}

public Action:OnPlayerRunCmd(i_Client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{
	if (i_Buttons & IN_ATTACK)
	{
		decl String:s_Weapon[32], i_Skin
	
		i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
		
		if (IsValidEntity(i_Weapon))
		{
			GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon))
			i_Skin = GetEntProp(i_Weapon, Prop_Send, "m_nSkin")
		}
		
		if (StrEqual(s_Weapon, M60_CLASS))
		{
			decl i_Clip

			i_Clip = GetEntProp(i_Weapon, Prop_Data, "m_iClip1")
			
			if (i_Clip <= 1)
			{
				decl i_Ent
			
				i_Ent = CreateEntityByName("weapon_rifle_m60")
				EquipPlayerWeapon(i_Client, i_Ent)
			}
		}
	}
}