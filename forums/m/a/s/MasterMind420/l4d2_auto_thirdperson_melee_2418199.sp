#include <sourcemod>
#include <sdktools>

new bool:Third_Melee[MAXPLAYERS+1] = false;
new Handle:Auto_Thirdperson_Timer[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[L4D2] Auto Thirdperson Melee",
	author = "MasterMind420",
	description = "Switches to thirdperson when melee is equipped",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_tm", sm_tm);
}

public Action:sm_tm(client,args)
{
	if(client > 0)
	{
		Third_Melee[client]=!Third_Melee[client];
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
 	}
}

public void OnClientPostAdminCheck(client)
{
	if (client == 0) { return; }
	if (IsFakeClient(client)) { return; }
	Auto_Thirdperson_Timer[client] = CreateTimer(0.1, AutoThirdpersonCheck, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnGameFrame()
{
	for(new client=1; client<=MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			if(Third_Melee[client] == true)
			{
				new String:sClassName[64];
				new WeaponSlot = GetPlayerWeaponSlot(client, 6);
				if (WeaponSlot == -1) { return; }
				new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				GetEdictClassname(WeaponSlot, sClassName, sizeof(sClassName));
				if(StrEqual(sClassName, "weapon_melee") && WeaponSlot == ActiveWeapon)
				{
					SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
				}
				else
				{
					SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
				}
			}
		}
	}
}

public Action:AutoThirdpersonCheck(Handle:Timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
		{
			{
				QueryClientConVar(client, "c_thirdperson", QueryClientConVarCallback_Thirdperson);
				QueryClientConVar(client, "c_thirdperson_mayamode", QueryClientConVarCallback_ThirdpersonMaya);
				QueryClientConVar(client, "c_thirdpersonshoulder", QueryClientConVarCallback_Thirdpersonshoulder);
			}
		}
	}
}

public QueryClientConVarCallback_Thirdperson(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StrEqual(cvarValue, "true") && !StrEqual(cvarValue, "1"))
	{
		Third_Melee[client]=true
	}
	if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0"))
	{
		Third_Melee[client]=false
	}
}

public QueryClientConVarCallback_ThirdpersonMaya(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StrEqual(cvarValue, "true") && !StrEqual(cvarValue, "1"))
	{
		Third_Melee[client]=true
	}
	if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0"))
	{
		Third_Melee[client]=false
	}
}

public QueryClientConVarCallback_Thirdpersonshoulder(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StrEqual(cvarValue, "true") && !StrEqual(cvarValue, "1"))
	{
		Third_Melee[client]=true
	}
	if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0"))
	{
		Third_Melee[client]=false
	}
}