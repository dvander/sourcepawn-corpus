#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0"

new maxplayers;
new Handle:MaxFakeClientAllowed;
new Handle:FakeClientsDelay;

public Plugin:myinfo = 
{
  name = "FakeClients",
  author = "LouLoubizou",
  description = "Put fake clients in server",
  version = PL_VERSION,
  url = "http://sourcemod.net/"
};      

static String:FakeNames[32][] = {"System32", "TommyBoy", "RogerDodger", "BulletsLikeMe", "b!g", "ScoutItOut", "PopularAttraction", "Squ33z3", "quality", "bailoutnow", "ph34r", "1337sp34k", "soopaMAN", "www.LDuke.com", "omar", "achmed", "benthas", "hmmmm", "LOLLOL", "i.ride.the.short.bus", "roastAbowl", "winnt.dll", "Im_a_big_fake", "freeman", "alyx", "barney", "g-man", "xcellent", "obtuse", "Moridin", "Rand", "YoungBull"};

public OnPluginStart(){
	CreateConVar("sm_fakeclients_version", PL_VERSION, "Version of FakeClients plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	MaxFakeClientAllowed = CreateConVar("sm_fakeclients_players","1","Number of players to simulate", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 64.0);
	FakeClientsDelay = CreateConVar("sm_fakeclients_delay","0.1","Delay after map change before fake clients join (seconds)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.1, true, 10.0);
}

public OnMapStart(){
	maxplayers = 0;
	maxplayers = GetMaxClients();
	new i;
	new Float:Delay = GetConVarFloat(FakeClientsDelay);
	new Float:NewDelay = Delay;
	for(i=1; i<=GetConVarInt(MaxFakeClientAllowed); i++){
		CreateTimer(NewDelay, OnTimedCreateFakeClient, 0);
		NewDelay = NewDelay+Delay;
	}
}

public OnClientPutInServer(client){
	if (!IsFakeClient(client)){
		new i;
		for(i=1; i<=maxplayers; i++){
			if (IsClientConnected(i)){
				if(IsFakeClient(i)){
					KickClient(i, "Slot reserved", i);
					break;
				}
			}
		}
	}
}

public OnClientDisconnect(client){
	CreateTimer(0.1, OnTimedCreateFakeClient, client);
}

public Action:OnTimedKick(Handle:timer, any:client){	
	KickClient(client, "Slot reserved", client);
	return Plugin_Handled;
}

public Action:OnTimedCreateFakeClient(Handle:timer, any:client){
	new clientcount = GetClientCount(true);
	if (clientcount == maxplayers-1)
		return Plugin_Handled;
	
	new i;
	new NumberOfFakeClients = 0;		
	for (i=1; i<=maxplayers; i++){
		if (IsClientConnected(i)){
			if(IsFakeClient(i))
				NumberOfFakeClients++;
		}
	}
	if (NumberOfFakeClients == GetConVarInt(MaxFakeClientAllowed))
		return Plugin_Handled;

	if (clientcount >= GetConVarInt(MaxFakeClientAllowed))
		return Plugin_Handled;
	
	new RandomName = GetRandomInt(0, 31);
	CreateFakeClient(FakeNames[RandomName]);
	return Plugin_Handled;
}