#define MaxClients 32
#define PLUGIN_VERSION "1.4.0"

#define CVARS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "L4D2 Infinite Ammo",
	author = "Machine",
	description = "Enables infinite ammo on clients",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

new bool:IAMMOPLAYER[MaxClients + 1];
new Handle:EnableIammo = INVALID_HANDLE;

public OnPluginStart()
{
	//Cmds
	RegAdminCmd("sm_iammo", Command_Ammo, ADMFLAG_BAN, "sm_iammo <#userid|name> <0|1> - Toggles Infinite Ammo on player(s)");

	//Convars
	CreateConVar("sm_iammo_version", PLUGIN_VERSION, "L4D2 Infinite Ammo Version", CVARS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	EnableIammo = CreateConVar("sm_iammo_enable", "1", "<0|1|2> Enable Infinite Ammo? 0=Off 1=On 2=Everyone");
	
	//Hooks
	HookConVarChange(EnableIammo, EnableChanged);
	HookEvent("player_disconnect", Event_Disconnect);

	LoadTranslations("common.phrases");

	AutoExecConfig(true, "sm_iammo_config");	
}

public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == EnableIammo)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if(newval == oldval) return;
		
		if((newval != 0) && (newval != 1) && (newval != 2))
		{
			SetConVarInt(EnableIammo, oldval);
		}
		else
		{
		
			if(oldval == 2) 
			{
				PrintToChatAll("\x01[SM]\x04 Infinite ammo for everyone removed!");
				for (new i = 1; i < MaxClients; i++)
				{
					if (IsValidEntity(i) && IsClientConnected(i))
					{
						IAMMOPLAYER[i] = false;
					}
				}
			}
		
			if(newval == 2)
			{
				PrintToChatAll("\x01[SM]\x04 Infinite ammo enabled for everyone!");
				for (new i = 1; i < MaxClients; i++)
				{
					if (IsValidEntity(i) && IsClientConnected(i))
					{
						IAMMOPLAYER[i] = true;
					}
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(GetConVarInt(EnableIammo) == 2)
	{
		IAMMOPLAYER[client] = true;
	}
}

public Action:Event_Disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client<=0)
		return;

	IAMMOPLAYER[client] = false;
}

public Action:Command_Ammo(client, args)
{
	new EnableVar = GetConVarInt(EnableIammo);
	
	if(EnableVar == 0)
	{
		ReplyToCommand(client, "[SM] Infinite Ammo is currently disabled.");

		return Plugin_Handled;
	}

	if (args < 1)
	{
		if(client==0)
		{
			ReplyToCommand(client, "[SM] Can not enable Infinite Ammo on console.");	
		}
		else
		{
			if (IAMMOPLAYER[client] == false)	
			{
				IAMMOPLAYER[client] = true;
				PrintToChat(client,"\x01[SM]\x04 Infinite Ammo on");
			}
			else
			{
				IAMMOPLAYER[client] = false;
				PrintToChat(client,"\x01[SM]\x04 Infinite Ammo off");
			}
		}

		return Plugin_Handled;
	}
			
	else if (args == 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_iammo <#userid|name> <0|1>");

		return Plugin_Handled;
	}
	
	else if (args == 2)
	{
		new String:target[32], String:arg2[32];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));
		new gstate = StringToInt(arg2);
			
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	
		for (new i = 0; i < target_count; i++)
		{	
			if (gstate == 1) //Turn on Infinite Ammo
			{
				if(client==0)
				{
					ReplyToCommand(client,"[SM] Infinite Ammo enabled on target.");	
				}
				else
				{
					PrintToChat(client,"\x01[SM]\x04 Infinite Ammo enabled on target.");
				}

				IAMMOPLAYER[target_list[i]] = true;
				PrintToChat(target_list[i],"\x01[SM]\x04 An admin has given you Infinite Ammo!");
			}	
			else if (gstate == 0) //Turn off Infinite Ammo
			{
				if(client==0)
				{
					ReplyToCommand(client,"[SM] Infinite Ammo disabled on target.");	
				}
				else
				{
					PrintToChat(client,"\x01[SM]\x04 Infinite Ammo disabled on target.");
				}

				IAMMOPLAYER[target_list[i]] = false;
				PrintToChat(target_list[i],"\x01[SM]\x04 An admin has taken away your Infinite Ammo!");
			}		
			else
			{
				ReplyToCommand(client, "[SM] Usage: sm_iammo <#userid|name> <0|1>");
			}
					
		}
	
		return Plugin_Handled;
	}
	else if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_iammo <#userid|name> <0|1>");

		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public OnGameFrame()
{
	if (!IsServerProcessing()) return;

	for (new i = 1; i < MaxClients; i++)
	{
		if ((IAMMOPLAYER[i]) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			new String:weapon[32];
			new clip;

			if (GetPlayerWeaponSlot(i, 0) != -1)
			{
				GetEdictClassname(GetPlayerWeaponSlot(i, 0), weapon, 32);
				clip = GetEntProp(GetPlayerWeaponSlot(i, 0), Prop_Send, "m_iClip1");

				if (StrEqual(weapon, "weapon_rifle_m60"))
				{
					if (clip < 150)
					{
						SetEntProp(GetPlayerWeaponSlot(i, 0), Prop_Send, "m_iClip1", 150);
					}
				}
			}
		}
	}
}