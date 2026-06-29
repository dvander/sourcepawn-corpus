#include <sourcemod>
#include <zombiereloaded>

new bool:g_damage[MAXPLAYERS+1] = true;

public Plugin:myinfo =
{
	name = "SM Show Health Victim",
	author = "Franc1sco Steam: franug",
	description = "Show health victim for attacker",
	version = "3.1",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	CreateConVar("sm_showhealthvictim_version", "3.0", "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_showdamage",HookSay);
	RegConsoleCmd("sm_sd",HookSay);
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			g_damage[client] = true;
		}
	}
}
public Action:HookSay(client,args)
{
	if(!client) return Plugin_Continue;
	
	if(g_damage[client]) 
	{
		PrintToChat(client, "Showdamage Disabled");
		g_damage[client] = false;
	}
	else 
	{
		PrintToChat(client, "Showdamage Enabled");
		g_damage[client] = true;
	}
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	g_damage[client] = true;
}

// al herir un jugador
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!attacker || !g_damage[attacker] || !IsPlayerAlive(attacker)) // si no hay atacante no se sigue con el codigo
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ZR_IsClientZombie(attacker))
	{
		decl String:input[512];
		Format(input, 512, "<font color='#FFFFFF'>You Infected to</font> <font color='#0066FF'>%N</font>", client); // se muestra el mensaje de que le ha matado
		new Handle:pb = StartMessageOne("HintText", attacker);
		PbSetString(pb, "text", input);
		EndMessage();
		return;
	}
	new restante = GetClientHealth(client); // se obtiene la vida del cliente

	if(restante > 0) // si la vida del cliente es mayor a 0 (por lo que no esta muerto)
	{
		new damage = GetEventInt(event, "dmg_health"); // se obtiene el daño hecho
		
		decl String:input[512];
		Format(input, 512, "<font color='#FFFFFF'>You did</font> <font color='#FF0000'>%i</font> <font color='#FFFFFF'>Damage to <font color='#0066FF'>%N</font>\n<font color='#FFFFFF'>Health Remaining:</font> <font color='#00CC00'>%i</font>", damage, client, restante); // se muestra el mensaje del daño 
		new Handle:pb = StartMessageOne("HintText", attacker);
		PbSetString(pb, "text", input);
		EndMessage();
	}
	else
	{
		decl String:input[512];
		Format(input, 512, "<font color='#FFFFFF'>You Killed to</font> <font color='#0066FF'>%N</font>", client); // se muestra el mensaje de que le ha matado
		new Handle:pb = StartMessageOne("HintText", attacker);
		PbSetString(pb, "text", input);
		EndMessage();
	}
}