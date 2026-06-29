#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.2"


public Plugin:myinfo = 
{
	name = "L4D Melee Bug Detector",
	author = "KawMAN",
	description = "Punish for using Melee Bug",
	version = PLUGIN_VERSION,
	url = "http://wsciekle.pl"
}

new first_shoved[15];
new sec_shoved[15];
new String:plr_weapon[15][255];
new String:plr_weapon2[15][255];
new Handle:ftimer[15];
new Handle:stimer[15];
new plr_warn[15];
new Handle:versus=INVALID_HANDLE;
new Handle:g_punish=INVALID_HANDLE;
new Handle:g_warns=INVALID_HANDLE;
new Handle:g_timer=INVALID_HANDLE;
new Handle:g_immun=INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_melee_detect_v", PLUGIN_VERSION, "L4D Melee Bug Detector", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_punish = CreateConVar("l4d_md_punishment", "5", "If 0 Kick from server If >=1 - ban for value minutes");
	g_warns = CreateConVar("l4d_md_warns", "2", "After how many warnings player should be kicked/banned");
	g_timer = CreateConVar("l4d_md_timer", "0.6", "How fast Melee Bug should be detected, Lower value - faster; Higher value - slower");
	g_immun = CreateConVar("l4d_md_immunity", "0", "If 1 plugin dont punish admins for using Melee Bug");
	HookEvent("entity_shoved", Event_entshov);
	HookEvent("player_shoved", Event_entshov);
	versus = FindConVar("director_no_human_zombies");


}

public OnClientPutInServer(client)
{
	plr_warn[client]=0;
}

public Event_entshov(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new userid = GetEventInt(event, "attacker");
	new plr_index = GetClientOfUserId(userid);
	if(sec_shoved[plr_index]==1)
	{
		GetClientWeapon(plr_index, plr_weapon2[plr_index], 255);
		if(strcmp(plr_weapon[plr_index],plr_weapon2[plr_index],false) != 0)
		{
			if(plr_warn[plr_index]!=GetConVarInt(g_warns))
			{
				plr_warn[plr_index]++;
				if(plr_warn[plr_index]!=GetConVarInt(g_warns))
				{
					PrintToChat(plr_index, "\x03[MBD] %d/%d warning for using Melee bug", plr_warn[plr_index],GetConVarInt(g_warns));
				}
				else
				{
					PrintToChat(plr_index, "\x03[MBD] Last warn!!!", plr_warn[plr_index],GetConVarInt(g_warns));
				}
				if(GetConVarInt(versus)==0)
				{
					SlapPlayer(plr_index, 0);
					for(new Float:k=0.1;k<=10.0;k=k+0.5)
					{
						CreateTimer(k, first_zero, plr_index);
						CreateTimer(k, sec_zero, plr_index);
					}
				}
				else
				{
					SlapPlayer(plr_index, 0);
					for(new Float:k=0.1;k<=10.0;k=k+0.5)
					{
						CreateTimer(k, first_zero, plr_index);
						CreateTimer(k, sec_zero, plr_index);
					}
				}
			}
			else if(plr_warn[plr_index]==GetConVarInt(g_warns))
			{
				new String:plr_name[100];
				GetClientName(plr_index, plr_name, sizeof(plr_name));
				new AdminId:aid = GetUserAdmin(plr_index);
				if(GetAdminFlag(aid, Admin_Generic)&&GetConVarInt(g_immun)==1)
				{
					plr_warn[plr_index]=0;
				}
				else
				{
					if(GetConVarInt(g_punish)<=0)
					{
						PrintToChatAll("[MBD]Player %s kicked from server for using Melee Bug", plr_name);
						KickClient(plr_index, "Kicked from server for using Melee bug");
					}
					else 
					{
						PrintToChatAll("[MBD]Player %s banned (%d min) from server for using Melee Bug", plr_name, GetConVarInt(g_punish));
						BanClient(plr_index, GetConVarInt(g_punish), BANFLAG_AUTHID , "Banned from server for using Melee bug", "Banned from server for using Melee bug")
					}
				}
			}
			
		}
	}
	else if(first_shoved[plr_index]==1)
	{
		
		GetClientWeapon(plr_index, plr_weapon2[plr_index], 255);
		if(strcmp(plr_weapon[plr_index],plr_weapon2[plr_index],false) != 0)
		{
			sec_shoved[plr_index]=1;
			if(stimer[plr_index]!=INVALID_HANDLE)
			{
				KillTimer(stimer[plr_index]);
			}
			stimer[plr_index] = CreateTimer(GetConVarFloat(g_timer), sec_zero, plr_index);
			GetClientWeapon(plr_index, plr_weapon[plr_index], 255);
		}
	}
	
	
	
	first_shoved[plr_index]=1;
	if(ftimer[plr_index]!=INVALID_HANDLE)
	{
		KillTimer(ftimer[plr_index]);
	}
	ftimer[plr_index] = CreateTimer(GetConVarFloat(g_timer), first_zero, plr_index);
	GetClientWeapon(plr_index, plr_weapon[plr_index], 255);


}


public Action:first_zero(Handle:timer, any:client)
{
	first_shoved[client]=0;
	ftimer[client]=INVALID_HANDLE;
}

public Action:sec_zero(Handle:timer, any:client)
{
	sec_shoved[client]=0;
	stimer[client]=INVALID_HANDLE;
}
public Action:player_return(Handle:timer, any:client)
{
	if(GetClientTeam(client)!=2 && IsClientConnected(client))
	{
		ChangeClientTeam(client,2);
	}
}
