#pragma semicolon 1

#define PL_NAME	"Admin Regenerate"
#define PL_VER	"1.2.0 SM1.6- (rewritten by Grey83)"

new Handle:hTimer,
	bool:bRegen[MAXPLAYERS+1],
	iMaxHP,
	iAdd,
	Float:fCD;

public Plugin:myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Lets admins regenerate their health with a command",
	author		= "joac1144/Zyanthius",
	url			= "https://forums.alliedmods.net/showthread.php?t=236606"
}

public OnPluginStart()
{
	RegAdminCmd("sm_adminregen", Cmd_Regeneration, ADMFLAG_SLAY, "Activates regeneration.");

	CreateConVar("adminregen_version", PL_VER, PL_NAME);

	new Handle:cvar;
	cvar = CreateConVar("adminregen_maxhp", "100", "Maximum health you can have by regenerating", _, true, 1.0);
	HookConVarChange(cvar, CVarChange_MaxHP);
	iMaxHP = GetConVarInt(cvar);

	cvar = CreateConVar("adminregen_health", "2", "Amount of health to regenerate", _, true, 1.0);
	HookConVarChange(cvar, CVarChange_Add);
	iAdd = GetConVarInt(cvar);

	cvar = CreateConVar("adminregen_time", "2.0", "Amount of time (in seconds) between each health", _, true, 0.1);
	HookConVarChange(cvar, CVarChange_CD);
	fCD = GetConVarFloat(cvar);

	AutoExecConfig(true, "plugin.adminregen");
}

public CVarChange_MaxHP(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iMaxHP = GetConVarInt(cvar);
}

public CVarChange_Add(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iAdd = GetConVarInt(cvar);
}

public CVarChange_CD(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	fCD = GetConVarFloat(cvar);

	OnMapEnd();
	hTimer = CreateTimer(fCD, Timer_Regen, _, TIMER_REPEAT);
}

public Action:Cmd_Regeneration(client, args)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	if(bRegen[client])
	{
		ReplyToCommand(client, "[SM] You have deactivated regeneration!");
		PrintToServer("[SM] %N has deactivated regeneration!", client);
		bRegen[client] = false;
		return Plugin_Handled;
	}

	new hp = GetClientHealth(client);
	if(hp >= iMaxHP)
	{
		ReplyToCommand(client, "[SM] You already have maximum HP!");
		PrintToServer("[SM] %N already has maximum HP!", client);
		return Plugin_Handled;
	}

	bRegen[client] = true;
	ReplyToCommand(client, "[SM] You have activated regeneration!");
	PrintToServer("[SM] %N has activated regeneration!", client);

	if(!hTimer) hTimer =  CreateTimer(fCD, Timer_Regen, _, TIMER_REPEAT);

	return Plugin_Handled;
}

public Action:Timer_Regen(Handle:timer)
{
	new num;
	for(new i = 1, hp, add; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i) && bRegen[i])
	{
		if((hp = GetClientHealth(i)) < iMaxHP)
		{
			if((add = hp + iAdd) >= iMaxHP)
			{
				bRegen[i] = false;
				add = iMaxHP;
			}
			else num++;
			SetEntityHealth(i, add);
		}
		else bRegen[i] = false;
	}

	if(!num)
	{
		hTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	bRegen[client] = false;
}

public OnMapEnd()
{
	if(!hTimer) return;

	CloseHandle(hTimer);
	hTimer = INVALID_HANDLE;
}