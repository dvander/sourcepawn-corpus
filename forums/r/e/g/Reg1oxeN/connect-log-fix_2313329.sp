#include <sourcemod>
public Plugin:myinfo =
{
  name = "Player Connect Log Fix",
  author = "Reg1oxeN",
  version = "1.0"
};

public OnPluginStart() { HookEvent("player_connect", Player_ConnectPre, EventHookMode_Pre); }

public Action:Player_ConnectPre(Handle:event, const String:Name[], bool:dB)
{
	decl String:ip[3]; GetEventString(event, "address", ip, sizeof(ip));
	if (StrEqual(ip, "")) return Plugin_Handled;
	else return Plugin_Continue;
}

public OnClientConnected(client)
{
	decl String:clientName[MAX_NAME_LENGTH], String:networkID[64], String:address[32];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientAuthString(client, networkID, sizeof(networkID));
	GetClientIP(client, address, sizeof(address), false);
	
	new Handle:newEvent = CreateEvent("player_connect", true);
	SetEventString(newEvent, "name", clientName);
	SetEventInt(newEvent, "index", client-1);
	SetEventInt(newEvent, "userid", GetClientUserId(client));
	SetEventString(newEvent, "networkid", networkID);
	SetEventString(newEvent, "address", address);
	FireEvent(newEvent, false);
}