#include <sourcemod>

#define PLUGIN_VERSION "1.5.1"

new Handle:cvarEnabled;
new Handle:cvarChat;
new Handle:cvarColor;
new Handle:cvarCenter;
new Handle:cvarHint;
new Handle:cvarHud;
new Handle:cvarSpecial;
new Handle:Version;
new bool:gameTF2 = false;
new bool:gameHL2MP = false;
new String:specialtext[128];

public Plugin:myinfo =
{
	name = "Admin Connect Message (Extended)",
	author = "ReFlexPoison",
	description = "Post connecting admins and VIP's through hud and say commands.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=183966"
}

public OnPluginStart()
{
	Version = CreateConVar("sm_adminconmsg_version", PLUGIN_VERSION, "Admin Connect Message (Extended) Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

	decl String:game[64];
	GetGameFolderName(game, sizeof(game));
	gameTF2 = StrEqual(game, "tf");
	gameHL2MP = StrEqual(game, "hl2mp");
	
	cvarEnabled = CreateConVar("sm_adminconmsg_enabled", "1", "Enable Admin Connect Message\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarChat = CreateConVar("sm_adminconmsg_chat", "1", "Post Admin Connect in Chat\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCenter = CreateConVar("sm_adminconmsg_center", "1", "Post Admin Connect in Center\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarHint = CreateConVar("sm_adminconmsg_hint", "0", "Post Admin Connect in Hint\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarColor = CreateConVar("sm_adminconmsg_color", "0", "Admin Connect Chat Color\n0 = Default\n1 = White\n2 = Lightgreen\n3 = Green\n4 = Olive", FCVAR_NONE, true, 0.0, true, 4.0);
	cvarSpecial = CreateConVar("sm_adminconmsg_special", "Doner", "What to Call <Special> Players");
	if((gameTF2) || (gameHL2MP))
	{
		cvarHud = CreateConVar("sm_adminconmsg_hud", "0", "Post Admin Connect in Hud\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	}

	HookConVarChange(cvarSpecial, CVarChange);
	HookConVarChange(Version, CVarChange);

	AutoExecConfig(true, "plugin.adminconmsg");
}

public OnConfigsExecuted()
{
	GetConVarString(cvarSpecial, specialtext, sizeof(specialtext));
}

public CVarChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == cvarSpecial)
	{
		GetConVarString(convar, specialtext, sizeof(specialtext));
	}
	else
	if(convar == Version)
	{
		SetConVarString(Version, PLUGIN_VERSION)
	}
}

public OnClientPostAdminCheck(client)
{
	if(CheckCommandAccess(client, "adminconmsg_admin_flag", ADMFLAG_GENERIC) || CheckCommandAccess(client, "adminconmsg_donator_flag", ADMFLAG_RESERVATION))
	{
		decl String:type[10];
		type[0] = '\0';
		if(CheckCommandAccess(client, "adminconmsg_admin_flag", ADMFLAG_GENERIC))
		{
			Format(type, sizeof(type), "Admin");
		}
		else
		{
			Format(type, sizeof(type), (specialtext));
		}
		if(GetConVarBool(cvarEnabled))
		{
			if(GetConVarInt(cvarChat) == 1)
			{
				//Hardcored Colors
				if(GetConVarInt(cvarColor) == 0)
				{
					//Default
					PrintToChatAll("\x01%s %N Connected", type, client);
				}
				if(GetConVarInt(cvarColor) == 1)
				{
					//White
					PrintToChatAll("\x02%s %N Connected", type, client);
				}
				if(GetConVarInt(cvarColor) == 2)
				{
					//Lightgreen
					PrintToChatAll("\x03%s %N Connected", type, client);
				}
				if(GetConVarInt(cvarColor) == 3)
				{
					//Green
					PrintToChatAll("\x04%s %N Connected", type, client);
				}
				if(GetConVarInt(cvarColor) == 4)
				{
					//Olive
					PrintToChatAll("\x05%s %N Connected", type, client);
				}
			}
			if(GetConVarBool(cvarCenter))
			{
				PrintCenterTextAll("%s %N Connected", type, client);
			}
			if((gameTF2) || (gameHL2MP))
			{
				if(GetConVarBool(cvarHud))
				{
					SetHudTextParams(-1.0, 0.3, 7.5, 255, 255, 255, 255)
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsValidClient(i))
						{
							ShowHudText(i, -1, "%s %N Connected", type, client);
						}
					}
				}
			}
			if(GetConVarBool(cvarHint))
			{
				PrintHintTextToAll("%s %N Connected", type, client);
			}
		}
		PrintToServer("%s %N Connected", type, client);
	}
}

//////////
//STOCKS//
//////////

stock IsValidClient(client, bool:replaycheck = true)
{
	if(client <= 0 || client > MaxClients)
	{
		return false;
	}
	if(!IsClientInGame(client))
	{
		return false;
	}
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}