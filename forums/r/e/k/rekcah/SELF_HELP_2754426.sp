#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
    HookEvent("player_ledge_grab", reset);
    HookEvent("player_incapacitated", reset);
}

public Plugin myinfo =
{
	name = "improved self help",
	author = "spirit/rekcah,saccie",
	description = "self help that shouldnt ever break",
	version = "v1.0",
	url = "NONE"
};

// Get medpack item entity
stock int GetMedkitEntity(const int client){
    int Tmp = GetPlayerWeaponSlot(client, 3);
    return ((IsValidEntity(Tmp)) ? Tmp : -1);
}

// Get health item entity
stock int GetHealthItemEntity(const int client){
    int Tmp = GetPlayerWeaponSlot(client, 4);
    return ((IsValidEntity(Tmp)) ? Tmp : -1);
}
// Return true if  Can Auto revive, or return true and take items if Take = true
bool ManageClientInventory(const int client,const bool Take = false){
    if((!IsIncapacitated(client) && !IsHanging(client)) || capped(client)){ return false;}
    int Temp = GetHealthItemEntity(client);
    int Kit  = GetMedkitEntity(client);
    int item = Temp>0?Temp:Kit>0?Kit:-1;
    return (item ==-1) ? false : (Take ? RemovePlayerItem(client, item) : true);
}
// if player can self help display a message for them, also starts ot selff help timer
public void reset(Event event, char []hEvent, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(ManageClientInventory(client,false)){
		PrintHintText(client,"hold crtl to help yourself up");
		if(IsFakeClient(client))
		{
			PrintToChatAll("%N Will SelfHelp In 15 Seconds!!!",client);
			CreateTimer(15.0, AutoHelpBot,client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);	
		}
	}		
}

public Action AutoHelpBot(Handle hTimer, int client)
{
	if(((client < 0) || (client > MaxClients)) || !IsClientInGame(client))
		return Plugin_Stop;
    if(!IsPlayerAlive(client) || (GetClientTeam(client) != 2))
		return Plugin_Stop;
	
	if(ManageClientInventory(client,true) && IsFakeClient(client) && !capped(client))
	{
        CheatCommand(client, "give", "health", "");
        SetEntDataFloat(client, FindSendPropInfo("CTerrorPlayer","m_healthBuffer"), 60.0, true);
        SetEntityHealth(client, 1);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons){
    float STime = CharacterStarted(client,0);
    if (STime < 0.0)
	{ return Plugin_Continue;  }
    CharacterStarted(client,(buttons & IN_DUCK)?-1:-2);
    return Plugin_Continue;
}
// 0 = return character delay, -1 = self helping, -2 = released ctrl / no longer elligable
stock float CharacterStarted(const int client, int reason = 0){
    if(((client < 0) || (client > MaxClients)) || !IsClientInGame(client))
	{ return -1.0; }
    if(!IsPlayerAlive(client) || (GetClientTeam(client) != 2))
	{ return -1.0; }
    if(IsFakeClient(client))
	{ return -1.0; }

	static float CTimes[4+1];
    // 0 - "Bill"   or "Nick", 1 - "Rochelle" or "Zoey",2 - "Coach" or "Louis",3 - "Francis"  or "ellis"
    int IdX = GetEntProp(client, Prop_Send, "m_survivorCharacter");
    float CTime = GetEngineTime();
    float STime = CTimes[IdX];
    int DTime = STime != 0.0 ? RoundToFloor(CTime-STime) : 0;
    CTimes[IdX] = DTime > 10 ? 0.0 : STime;
    
	if(!reason ||  ((reason == -2) && (STime == 0.0)) )
	{ return STime; }
    
	if(reason == -1){
        if(!ManageClientInventory(client,false)){ 
		reason = -2; 
		}
        else if(STime == 0.0){
            CTimes[IdX] = CTime;
            SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
            SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 5.0);
        }
        else if (DTime > 4){
            ManageClientInventory(client,true) ;
            CheatCommand(client, "give", "health", "");
            SetEntDataFloat(client, FindSendPropInfo("CTerrorPlayer","m_healthBuffer"), 60.0, true);
            SetEntityHealth(client, 1);
            reason = -2;
        }
    }
    if ((reason == -2) && (DTime < 5)){
        CTimes[IdX] = 0.0;
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
    }
    return CTimes[IdX];
}

stock bool IsIncapacitated(const int client){
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

stock bool IsHanging(const int client){
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
}

stock void CheatCommand(const int client, char []command, char []parameter1, char []parameter2)
{
    int userflags = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, userflags);
}

bool capped(const int client){
    return 
         (GetEntPropEnt(client, Prop_Send, "m_tongueOwner"   ) > 0) ? true : 
         (GetEntPropEnt(client, Prop_Send, "m_carryAttacker" ) > 0) ? true : 
         (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) ? true : false; 
}
