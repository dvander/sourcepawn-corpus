#pragma semicolon 1
#pragma newdecls required

static const char	PLUGIN_NAME[]		= "HUD Spectator List",
					PLUGIN_VERSION[]	= "1.2.0",
					colors[][]			= {"R", "G", "B", "A"};

static const int	SPEC_1ST			= 4,
					SPEC_3RD			= 5;
static const float	UPDATE_INTERVAL		= 1.5;


Handle Timer_HUDSpecList[MAXPLAYERS+1];
bool bEnable,
	bAllowed,
	bAdminOnly,
	bNoAdmins;
int iColor[4];
float fPosX,
	fPosY;

enum
{
	CVar_Enable = 0,
	CVar_Allowed,
	CVar_AdminOnly,
	CVar_NoAdmins,
	CVar_PosX,
	CVar_PosY
};

bool bUsed[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "View who is spectating you",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=135353"
};

public void OnPluginStart()
{
	CreateConVar("sm_speclist_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_speclist_enabled","1","Enables the spectator list for all players by default.", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_Enabled);
	NewCVarValue_Bool(CVar_Enable, CVar);
	(CVar = CreateConVar("sm_speclist_allowed","1","Allows players to enable spectator list manually when disabled by default.", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_Allowed);
	NewCVarValue_Bool(CVar_Allowed, CVar);
	(CVar = CreateConVar("sm_speclist_adminonly","0","Only admins can use the features of this plugin.", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_AdminOnly);
	NewCVarValue_Bool(CVar_AdminOnly, CVar);
	(CVar = CreateConVar("sm_speclist_noadmins", "1","Don't show non-admins that admins are spectating them.", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_NoAdmins);
	NewCVarValue_Bool(CVar_NoAdmins, CVar);
	(CVar = CreateConVar("sm_speclist_color", "0 127 255 255","Spectator List color. Set by RGBA (0 - 255).")).AddChangeHook(CVarChange_Color);
	NewCVarValue_Color(CVar);
	(CVar = CreateConVar("sm_speclist_x", "1.0","List position X (0.0 - 1.0 or -1 for center)", _, true, -1.0, true, 1.0)).AddChangeHook(CVarChange_PosX);
	NewCVarValue_Float(CVar_PosX, CVar);
	(CVar = CreateConVar("sm_speclist_y", "1.0","List position Y (0.0 - 1.0 or -1 for center)", _, true, -1.0, true, 1.0)).AddChangeHook(CVarChange_PosY);
	NewCVarValue_Float(CVar_PosY, CVar);

	RegConsoleCmd("sm_speclist", Cmd_SpecList);

	AutoExecConfig(true, "plugin.speclist_hud");
}

public void CVarChange_Enabled(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Bool(CVar_Enable, CVar);
}

public void CVarChange_Allowed(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Bool(CVar_Allowed, CVar);
}

public void CVarChange_AdminOnly(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Bool(CVar_AdminOnly, CVar);
}

public void CVarChange_NoAdmins(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Bool(CVar_NoAdmins, CVar);
}

stock void NewCVarValue_Bool(const int cvar_type, const ConVar CVar)
{
	static bool new_value;
	switch(cvar_type)
	{
		case CVar_Enable:
		{
			if(bEnable == (new_value = CVar.BoolValue)) return;

			SwitchAllHudTimers((bEnable = new_value));
		}
		case CVar_Allowed:	bAllowed = CVar.BoolValue;
		case CVar_AdminOnly:
		{
			if(bAdminOnly == (new_value = CVar.BoolValue)) return;

			if((bAdminOnly = new_value))
			{
				for(int i = 1; i <= MaxClients; i++) if(!IsPlayerAdmin(i)) KillHUDTimer(i);
			}
			else for(int i = 1; i <= MaxClients; i++) if(bUsed[i] && Timer_HUDSpecList[i] == null) CreateHUDTimer(i);
		}
		case CVar_NoAdmins:	bNoAdmins = CVar.BoolValue;
	}
}

public void CVarChange_Color(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Color(CVar);
}

stock void NewCVarValue_Color(const ConVar CVar)
{
	char sBuffer[16];
	CVar.GetString(sBuffer, sizeof(sBuffer));
	String2Color(sBuffer);
}

public void CVarChange_PosX(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Float(CVar_PosX, CVar);
}

public void CVarChange_PosY(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Float(CVar_PosY, CVar);
}

stock void NewCVarValue_Float(const int cvar_type, const ConVar CVar)
{
	static float new_value;
	if(FloatCompare(cvar_type == CVar_PosX ? fPosX : fPosY, (new_value = CVar.FloatValue))) return;

	if(new_value < 0) new_value = -1.0;
	switch(cvar_type)
	{
		case CVar_PosX: fPosX = new_value;
		case CVar_PosY: fPosY = new_value;
	}
}

stock void String2Color(const char[] str)
{
	static char Splitter[4][16];
	static int num;
	if((num = ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[]))) > 4) num = 4;
	for(int i; i < num; i++)
	{
		if(StringIsNumeric(Splitter[i]))
		{
			static bool fail;
			fail = false;
			iColor[i] = StringToInt(Splitter[i]);
			if(iColor[i] < 0)
			{
				iColor[i] = 0;
				fail = true;
			}
			else if(iColor[i] > 255)
			{
				iColor[i] = 255;
				fail = true;
			}
			if(fail) PrintToServer("Spectator List warning: incorrect '%s' color parameter (%s)! Correct: 0 - 255.", colors[i], Splitter[i]);
		}
		else
		{
			iColor[i] = 255;
			PrintToServer("Spectator List warning: incorrect '%s' color parameter ('%s' is not numeric)!", colors[i], Splitter[i]);
		}
	}
	if(num > 3) return;

	Splitter[0][0] = 0;
	for(int i = num; i < 4; i++)
	{
		iColor[i] = 255;
		Format(Splitter[0], sizeof(Splitter[]), "%s'%s'%s", Splitter[0], colors[i], num < 3 ? ", " : "");
	}
	PrintToServer("Spectator List warning: %s are not specified! These parameters are set to '255'.", Splitter[0]);
}

stock bool StringIsNumeric(const char[] str)
{
	static int x;
	x = 0;
	static bool numeric;
	numeric = false;
	while (str[x] != '\0')
	{
		if('/' < str[x] <= '9') numeric = true;		// < ':'
		else return false;
		x++;
	}

	return numeric;
}

public void OnClientPostAdminCheck(int client)
{
	if(bEnable) CreateHUDTimer(client);
	bUsed[client] = true;
}

public void OnClientDisconnect(int client)
{
	KillHUDTimer(client);
	bUsed[client] = false;
}

// Using 'sm_speclist' to toggle the spectator list per player.
public Action Cmd_SpecList(int client, int args)
{
	if(Timer_HUDSpecList[client] != null)
	{
		KillHUDTimer(client);
		ReplyToCommand(client, "[SM] Spectator list disabled.");
		bUsed[client] = false;
	}
	else if(bEnable || bAllowed)
	{
		CreateHUDTimer(client);
		ReplyToCommand(client, "[SM] Spectator list enabled.");
		bUsed[client] = true;
	}

	return Plugin_Handled;
}


public Action Timer_UpdateHUD(Handle timer, any client)
{
	static int spec_mode;

	if(IsPlayerAlive(client)) FillSpecList(client, client);
	else if((spec_mode = GetEntProp(client, Prop_Send, "m_iObserverMode")) == SPEC_1ST || spec_mode == SPEC_3RD)
		FillSpecList(client, GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"));

	return Plugin_Continue;
}

stock void FillSpecList(int client, int target)
{
	static int spec_mode, num;
	static char buffer[256];
	num = 0;
	buffer[0] = '\0';
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client || i == target || !IsClientInGame(i) || !IsClientObserver(i)) continue;

		// The 'client' is not an admin and do not display admins is enabled and the client (i) is an admin, so ignore them.
		if(bNoAdmins && !IsPlayerAdmin(client) && IsPlayerAdmin(i)) continue;

		// The client isn't spectating any one person, so ignore them.
		if((spec_mode = GetEntProp(i, Prop_Send, "m_iObserverMode")) != SPEC_1ST && spec_mode != SPEC_3RD) continue;

		// Find out who the client is spectating. Are they spectating our player?
		if(GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == target
		&& Format(buffer, sizeof(buffer), "%s%N\n", buffer, i) < 256)
			num++;
		else break;
	}
	if(!num) return;

	SetHudTextParams(fPosX, fPosY, UPDATE_INTERVAL + 0.1, iColor[0], iColor[1], iColor[2], iColor[3], 0, 0.0, 0.1, 0.1);
	ShowHudText(client, -1, buffer);
}

stock void SwitchAllHudTimers(bool on = false)
{
	if(on)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) CreateHUDTimer(i);
	}
	else for(int i = 1; i <= MaxClients; i++) KillHUDTimer(i);
}

stock void CreateHUDTimer(int client)
{
	if(!bAdminOnly || (bAdminOnly && IsPlayerAdmin(client)))
	{
		Timer_HUDSpecList[client] = CreateTimer(UPDATE_INTERVAL, Timer_UpdateHUD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock void KillHUDTimer(int client)
{
	if(Timer_HUDSpecList[client] != null)
	{
		KillTimer(Timer_HUDSpecList[client]);
		Timer_HUDSpecList[client] = null;
	}
}

stock bool IsPlayerAdmin(int client)
{
	return IsClientInGame(client) && GetUserAdmin(client) != INVALID_ADMIN_ID;
}