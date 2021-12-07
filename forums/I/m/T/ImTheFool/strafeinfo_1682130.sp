//Option to turn it off
#include <sourcemod>
#include <sdktools>
#include <cstrike>

new bool:f_WKey[MAXPLAYERS+1];
new bool:f_AKey[MAXPLAYERS+1];
new bool:f_SKey[MAXPLAYERS+1];
new bool:f_DKey[MAXPLAYERS+1];
new bool:f_CKey[MAXPLAYERS+1];
new bool:f_JKey[MAXPLAYERS+1];
new bool:f_WantSpec[MAXPLAYERS+1];

new g_fOldButtons[MAXPLAYERS+1] = { 0, ... };

new Handle:g_specTimer;

public OnMapStart()
{
	for (new i=0;i<MaxClients+1;i++) {
		f_WKey[i]=false;
		f_AKey[i]=false;
		f_SKey[i]=false;
		f_DKey[i]=false;
		f_CKey[i]=false;
		f_JKey[i]=false;
		f_WantSpec[i]=true;
		g_fOldButtons[i]=0;
	}
	g_specTimer=CreateTimer(1.0, Spec_RepeatTimer, _, TIMER_REPEAT);
}

public OnMapEnd()
{
	CloseHandle(g_specTimer);
}

public OnPluginStart()
{
	HookEvent("player_disconnect", Event_SpecLeave);
	RegConsoleCmd("sm_specoff", Spec_Off, "Turns your spec HUD off.");
	RegConsoleCmd("sm_specon", Spec_On, "Turns your spec HUD back on.");
}

public Event_SpecLeave(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	
	f_WantSpec[client]=true;
}

public Action:Spec_Off(client, args) {
	f_WantSpec[client]=false;
	return Plugin_Continue;
}

public Action:Spec_On(client, args) {
	f_WantSpec[client]=true;
	return Plugin_Continue;
}

public Action:Spec_RepeatTimer(Handle:Timer, any:client)
{
	for( new i = 1; i <= MaxClients; i++) {		//Sets who everyone's speccing, and updates everyone's info if they're alive
		if (!IsClientInGame(i))
			continue;
		if (IsPlayerAlive(i)) {
			Spec_UpdateInfo(i);
		}
	}
}

public OnGameFrame() {
	decl fButtons;
	for( new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			fButtons = GetClientButtons(i);
			if (fButtons != g_fOldButtons[i]) {          // Client buttons have changed.
				if (fButtons & IN_JUMP) {                // This button IS DOWN
					if (!(g_fOldButtons[i] & IN_JUMP)) { // This buttons WAS UP last frame.
						PlusJump(i);                     // Button press function
					}                                    // This button WAS DOWN last frame as well.
				}
				else {                                 // This button IS UP
					if (g_fOldButtons[i] & IN_JUMP) {    // This button WAS DOWN last frame.
						MinusJump(i);                    // Button release function
					}                                    // This button WAS UP last frame as well
				}
				if (fButtons & IN_DUCK) {
					if (!(g_fOldButtons[i] & IN_DUCK)) {
						PlusDuck(i);
					}
				}
				else {
					if (g_fOldButtons[i] & IN_DUCK) {
						MinusDuck(i);
					}
				}
				if (fButtons & IN_FORWARD) {
					if (!(g_fOldButtons[i] & IN_FORWARD)) {
						PlusForward(i);
					}
				}
				else {
					if (g_fOldButtons[i] & IN_FORWARD) {
						MinusForward(i);
					}
				}
				if (fButtons & IN_BACK) {
					if (!(g_fOldButtons[i] & IN_BACK)) {
						PlusBack(i);
					}
				}
				else {
					if (g_fOldButtons[i] & IN_BACK) {
						MinusBack(i);
					}
				}
				if (fButtons & IN_MOVELEFT) {
					if (!(g_fOldButtons[i] & IN_MOVELEFT)) {
						PlusMoveLeft(i);
					}
				}
				else {
					if (g_fOldButtons[i] & IN_MOVELEFT) {
						MinusMoveLeft(i);
					}
				}
				if (fButtons & IN_MOVERIGHT) {
					if (!(g_fOldButtons[i] & IN_MOVERIGHT)) {
						PlusMoveRight(i);
					}
				}
				else {
					if (g_fOldButtons[i] & IN_MOVERIGHT) {
						MinusMoveRight(i);
					}
				}
				g_fOldButtons[i] = fButtons;             // Update state for next frame.
			}                                            // Client's buttons have not changed this frame.
		}                                                // Client is not in the game or is dead/spectating.
	}
}

//--------
//Jump
//--------
stock PlusJump(client) {
	f_JKey[client]=true;
	Spec_UpdateInfo(client);
}
stock MinusJump(client) {
	f_JKey[client]=false;
	Spec_UpdateInfo(client);
}
//--------
//Duck
//--------
stock PlusDuck(client) {
	f_CKey[client]=true;
	Spec_UpdateInfo(client);
}
stock MinusDuck(client) {
	f_CKey[client]=false;
	Spec_UpdateInfo(client);
}
//--------
//Move Forward
//--------
stock PlusForward(client) {
	f_WKey[client]=true;
	Spec_UpdateInfo(client);
}
stock MinusForward(client) {
	f_WKey[client]=false;
	Spec_UpdateInfo(client);
}
//--------
//Move Back
//--------
stock PlusBack(client) {
	f_SKey[client]=true;
	Spec_UpdateInfo(client);
}
stock MinusBack(client) {
	f_SKey[client]=false;
	Spec_UpdateInfo(client);
}
//--------
//Move Left
//--------
stock PlusMoveLeft(client) {
	f_AKey[client]=true;
	Spec_UpdateInfo(client);
}
stock MinusMoveLeft(client) {
	f_AKey[client]=false;
	Spec_UpdateInfo(client);
}
//--------
//Move Right
//--------
stock PlusMoveRight(client) {
	f_DKey[client]=true;
	Spec_UpdateInfo(client);
}
stock MinusMoveRight(client) {
	f_DKey[client]=false;
	Spec_UpdateInfo(client);
}

public Spec_UpdateInfo(client) {
	new String:tempW[2];
	new String:tempA[2];
	new String:tempS[2];
	new String:tempD[2];
	new String:tempC[5];
	new String:tempJ[5];
	if (f_WKey[client]==true)
		tempW="W";
	else
		tempW="-";
	if (f_AKey[client]==true)
		tempA="A";
	else
		tempA="-";
	if (f_SKey[client]==true)
		tempS="S";
	else
		tempS="-";
	if (f_DKey[client]==true)
		tempD="D";
	else
		tempD="-";
	if (f_CKey[client]==true)
		tempC="Duck"
	else
		tempC="   .";
	if (f_JKey[client]==true)
		tempJ="Jump";
	else
		tempJ="   .";
	
	for( new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsPlayerAlive(i)) {
			new iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			new iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			
			if (iSpecMode != 4 && iSpecMode != 5)
				continue;
			
			if (iTarget == client && f_WantSpec[i]) {
				PrintHintText(i, "  %s    %s\n%s %s %s %s",tempW,tempJ,tempA,tempS,tempD,tempC);
			}
		}
	}
}