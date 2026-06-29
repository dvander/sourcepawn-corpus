/*
 Modified by Grrrrrrrrrrrrrrrrrrr
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new const String:PLUGIN_NAME[]= "WhoBangedMe?: Source";
new const String:PLUGIN_DESCRIPTION[]= "Tells who banged who!";
#define PLUGIN_VERSION "0.0.5"

public Plugin:myinfo=
{
	name= PLUGIN_NAME,
	author= "Alican 'AlicanC' Çubukçuoðlu",
	description= PLUGIN_DESCRIPTION,
	version= PLUGIN_VERSION,
	url= "http://www.sourcemod.net/"
}

new maxpclients;
new tmbangcount[MAXPLAYERS+1];
new Float:lastbanger[MAXPLAYERS+1];
new Handle:g_CvarEnable = INVALID_HANDLE,Handle:g_Cvartmonly = INVALID_HANDLE,Handle:g_Cvarblimit = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("whobangedmesource_version", PLUGIN_VERSION, "WhoBangedMe?: Source Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnable = CreateConVar("whobangedmesource_enable", "1", "WhoBangedMe? Source | Enable/disable.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvartmonly = CreateConVar("whobangedmesource_tmonly", "1", "WhoBangedMe? Source | Tell to teammates only.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvarblimit = CreateConVar("whobangedmesource_tmbanglimit", "1", "WhoBangedMe? Source | Punish player when bangs a teammate. 0: Off, 1: Instant slay, >=2: Slay after limit is reached", FCVAR_PLUGIN|FCVAR_NOTIFY, true, -1.0, true, 20.0);
	
	LoadTranslations("plugin.whobangedmesource.base");

	HookEvent("weapon_fire",Event_Fire);
	HookEvent("player_blind", Event_PlayerBlind);
}

public OnMapStart()
{
	maxpclients = GetMaxClients();
}

public OnClientPutInServer(client)
{
	if(!Running()) { return; }
	PrintToChat(client, "%T", "WBMS Running", PLUGIN_VERSION);
	tmbangcount[client]= 0;
}

public Event_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    new String:weapon[30];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    if (!StrEqual(weapon,"flashbang")) {
        return;
    }
    
    CreateTimer(0.1, timer, client);
}

public Action:timer(Handle:timer, any:client)
{
    new ent = -1;
    new lastent;
    new owner;
    
    ent = FindEntityByClassname(ent, "flashbang_projectile");
    
    while (ent != -1)
    {
        owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
        
        if (IsValidEntity(ent) && owner == client) {
            break;
	  }
    
        ent = FindEntityByClassname(ent, "flashbang_projectile");
        
        if (ent == lastent)
        {
            ent = -1;
            break;
        }
        
        lastent = ent;
    }

    if (ent != -1)
    {
	  lastbanger[client] = FloatAdd(GetGameTime(),GetEntPropFloat(ent, Prop_Send, "m_fThrowTime"));
    }
}

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Running()) { return; }
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsPlayerAlive(victim)) { return; }
	new Float:nowtime = GetGameTime();

	new Handle:data;
	WritePackCell(data, victim);
	new fltcomp;
	
      for(new x=1;x<=maxpclients;x++)
      {
		if(IsClientInGame(x)) {
			fltcomp = FloatCompare(nowtime,lastbanger[x]);
			if(fltcomp==0) {
				WritePackCell(data, x);
				CreateDataTimer(0.1, WhoBangedWho, data);
			} else if(fltcomp==1&&FloatSub(nowtime,lastbanger[x])<0.2) { //0.2 sec
					WritePackCell(data, x);
					CreateDataTimer(0.1, WhoBangedWho, data);
			} else if(FloatSub(lastbanger[x],nowtime)<0.2) { //0.2 sec
				WritePackCell(data, x);
				CreateDataTimer(0.1, WhoBangedWho, data);
			}
		}
	}
}

public Action:WhoBangedWho(Handle:timer, Handle:data)
{
	ResetPack(data);
	new victim = ReadPackCell(data);
	new attacker = ReadPackCell(data);

	new String:attacker_name[MAX_NAME_LENGTH];
	GetClientName(attacker, attacker_name, sizeof(attacker_name));

	if(victim==attacker)
	{
		PrintCenterText(victim, "%T", "WBMS BangedSelf");
		return;
	}

	new vteam = GetClientTeam(victim);
	new ateam = GetClientTeam(attacker); 
	new bool:teamonly = GetConVarBool(g_Cvartmonly);

	if(vteam==ateam) {
		TMbang(attacker);
	}

	if(!teamonly || (teamonly && vteam==ateam)) {
		PrintCenterText(victim, "%T", "WBMS BangedBy", attacker_name);
	}
}

public bool:Running()
{
	return GetConVarBool(g_CvarEnable);
}

public TMbang(client)
{
	new banglimit= GetConVarInt(g_Cvarblimit);
	tmbangcount[client]++;
	if(banglimit==0) { return; }

	if(tmbangcount[client]>=banglimit)
	{
		PrintCenterText(client, "%T", "WBMS ReachedTheLimit");
		ForcePlayerSuicide(client);
		tmbangcount[client]= 0;
	} else {
		new remaining = banglimit-tmbangcount[client];
		if(remaining==1) {
			PrintCenterText(client, "%T", "WBMS WillBeSlayedIf Singular");
		} else {
			PrintCenterText(client, "%T", "WBMS WillBeSlayedIf Plural", remaining);
		}
	}
}