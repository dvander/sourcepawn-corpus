#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <saxtonhale>

//For damage tracking...
new Damage[MAXPLAYERS+1];
new RGBA[MAXPLAYERS+1][4];
new damageTracker[MAXPLAYERS+1];
new Handle:damageHUD;

#define RED 0
#define GREEN 1
#define BLUE 2
#define ALPHA 3

public Plugin:myinfo = {
	name = "Versus Saxton Hale Improvements",
	author = "Aurora",
	description = "Some VSH improvements...",
	version = "2.0",
	url = "http://uno-gamer.com"
};

public OnPluginStart()
{
	RegConsoleCmd("haledmg", Command_damagetracker, "haledmg - Enable/disable the damage tracker.");
	CreateTimer(0.1, Timer_Millisecond);
	CreateTimer(180.0, Timer_Advertise);
	damageHUD = CreateHudSynchronizer();
}

public Action:Timer_Advertise(Handle:timer)
{
	CreateTimer(180.0, Timer_Advertise);
	CPrintToChatAll("{olive}[VSH]{default} Type \"!haledmg on\" to display the top 3 players! Type \"!haledmg off\" to turn it off again.");
	return Plugin_Handled;
}

public Action:Command_damagetracker(client, args)
{
	if (client == 0)
	{
		PrintToServer("[VSH] The damage tracker cannot be enabled by Console.");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		new String:playersetting[3];
		if (damageTracker[client] == 0) playersetting = "Off";
		if (damageTracker[client] > 0) playersetting = "On";
		CPrintToChat(client, "{olive}[VSH]{default} The damage tracker is {olive}%s{default}.\n{olive}[VSH]{default} Change it by saying \"!haledmg on [R] [G] [B] [A]\" or \"!haledmg off\"!", playersetting);
		return Plugin_Handled;
	}
	new String:arg1[64];
	new newval = 3;
	GetCmdArg(1, arg1, sizeof(arg1));
	if (StrEqual(arg1,"off",false)) damageTracker[client] = 0;
	if (StrEqual(arg1,"on",false)) damageTracker[client] = 3;
	if (StrEqual(arg1,"0",false)) damageTracker[client] = 0;
	if (StrEqual(arg1,"of",false)) damageTracker[client] = 0;
	if (!StrEqual(arg1,"off",false) && !StrEqual(arg1,"on",false) && !StrEqual(arg1,"0",false) && !StrEqual(arg1,"of",false))
	{
		newval = StringToInt(arg1);
		new String:newsetting[3];
		if (newval > 8) newval = 8;
		if (newval != 0) damageTracker[client] = newval;
		if (newval != 0 && damageTracker[client] == 0) newsetting = "off";
		if (newval != 0 && damageTracker[client] > 0) newsetting = "on";
		CPrintToChat(client, "{olive}[VSH]{default} The damage tracker is now {lightgreen}%s{default}!", newsetting);
	}
	
	new String:r[4], String:g[4], String:b[4], String:a[4];
	
	if(args >= 2)
	{
		GetCmdArg(2, r, sizeof(r));
		if(!StrEqual(r, "_"))
			RGBA[client][RED] = StringToInt(r);
	}
	
	if(args >= 3)
	{
		GetCmdArg(3, g, sizeof(g));
		if(!StrEqual(g, "_"))
			RGBA[client][GREEN] = StringToInt(g);
	}
	
	if(args >= 4)
	{
		GetCmdArg(4, b, sizeof(b));
		if(!StrEqual(b, "_"))
			RGBA[client][BLUE] = StringToInt(b);
	}
	
	if(args >= 5)
	{
		GetCmdArg(5, a, sizeof(a));
		if(!StrEqual(a, "_"))
			RGBA[client][ALPHA] = StringToInt(a);
	}
	
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	damageTracker[client] = 0;
	RGBA[client][RED] = 255;
	RGBA[client][GREEN] = 255;
	RGBA[client][BLUE] = 255;
	RGBA[client][ALPHA] = 255;
}

public Action:Timer_Millisecond(Handle:timer)
{
	CreateTimer(0.1, Timer_Millisecond);
	for(new i=1; i<=GetMaxClients(); i++)
	{
		Damage[i] = VSH_GetClientDamage(i);
	}
	
	// OLD SHIT CODE
	
	//SortIntegers(damage, sizeof(damage), Sort_Descending);
	//PrintToServer("First: %d, Second: %d, Third: %d", damage[1], damage[2], damage[3]);
	
	/*
	new f=0, s=0, t=0;
	for(new i=1; i<=GetMaxClients(); i++)
	{
		new tempDMG = VSH_GetClientDamage(i);
		if(tempDMG == 0)
			continue;
		if(tempDMG == damage[1])
			f=i;
		if(tempDMG == damage[2])
			s=i;
		if(tempDMG == damage[3])
			t=i;
	}
	*/
	
	// END OLD SHIT CODE
	
	// BEGIN NEW SHIT CODE
	
	new top[3];
	Damage[0] = 0;
	for (new i = 0; i <= MaxClients; i++)
	{
		if (Damage[i] >= Damage[top[0]])
		{
			top[2]=top[1];
			top[1]=top[0];
			top[0]=i;
		}
		else if (Damage[i] >= Damage[top[1]])
		{
			top[2]=top[1];
			top[1]=i;
		}
		else if (Damage[i] >= Damage[top[2]])
		{
			top[2]=i;
		}
	}
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsValidClient(z) && damageTracker[z] > 0)
		{
			new a_index = GetClientOfUserId(VSH_GetSaxtonHaleUserId());
			if (a_index != z) // client is not Hale
			{
				SetHudTextParams(0.0, 0.0, 0.2, RGBA[z][RED], RGBA[z][GREEN], RGBA[z][BLUE], RGBA[z][ALPHA]);
				new String:first[64], String:second[64], String:third[64];
				if(IsValidClient(top[0]))
					Format(first, sizeof(first), "[1] %N - %d\n", top[0], Damage[top[0]]);
				else
					Format(first, sizeof(first), "[1] N/A - 0\n");
				if(IsValidClient(top[1]))
					Format(second, sizeof(second), "[2] %N - %d\n", top[1], Damage[top[1]]);
				else
					Format(second, sizeof(second), "[2] N/A - 0\n");
				if(IsValidClient(top[2]))
					Format(third, sizeof(third), "[3] %N - %d\n", top[2], Damage[top[2]]);
				else
					Format(third, sizeof(third), "[3] N/A - 0\n");
				if (!(GetClientButtons(z) & IN_SCORE)) ShowSyncHudText(z, damageHUD, "%s%s%s", first, second, third);
			}
		}
	}
	return Plugin_Handled;
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}  
