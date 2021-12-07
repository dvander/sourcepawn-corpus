/**
 * =============================================================================
 * Bot Controller (C)2015 Jessica "jess" Henderson
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

#define INFECTED	3
#define SURVIVOR	2
#define SPECTATOR 	1

#define GAMEMODECOOP 1
#define GAMEMODEVERSUS 2
#define GAMEMODESURVIVAL 3
#define GAMEMODESCAVENGE 4

#define PLUGIN_VERSION "1.5"
#define PLUGIN_LIBRARY "botcontrol"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

new Handle:g_sGameConf						= INVALID_HANDLE;
new Handle:hSetHumanSpec					= INVALID_HANDLE;
new Handle:hTakeOverBot						= INVALID_HANDLE;
new Handle:f_OnBotCreated					= INVALID_HANDLE;
new Handle:f_OnDestroySurvivorBots			= INVALID_HANDLE;
new Handle:f_OnRequestSurvivorBotRegulation	= INVALID_HANDLE;
new Handle:f_OnFirstClientLoaded			= INVALID_HANDLE;
new Handle:f_OnSurvivorIdle					= INVALID_HANDLE;
new Handle:f_OnSurvivorIdleEndFwd			= INVALID_HANDLE;
new Handle:f_OnClientLoaded					= INVALID_HANDLE;
new hSurvivorRequirement;
new hSurvivorMaximum;
new bool:bAllowSurvivorBotRegulation;
new bool:bPreviousSurvivorBotRegulation;
new Handle:cSurvivorLimit;
new Handle:cInfectedLimit;
new bool:bIsInRemovalQueue[MAXPLAYERS+1];
new Handle:PlayersOnMapChange;
new hReserveSlots;
new hMaximumSlots;
new hRemovalDelay;
new bool:bIsReserveSlotsAllowed;
new Handle:DSBParams;
new bool:bIsFirstClientLoaded;
new bool:bIsOnBreak[MAXPLAYERS+1];
new bool:hOnlySurvivorBotsIfHumans;

public Plugin:myinfo = { name = "bot control", author = "jess", description = "framework for bot management", version = PLUGIN_VERSION, url = "forums.alliedmods.net/showthread.php?t=275726", };

public APLRes:AskPluginLoad2(Handle:g_Me, bool:b_IsLate, String:s_Error[], s_ErrorMaxSize) {

	if (LibraryExists(PLUGIN_LIBRARY)) {

		strcopy(s_Error, s_ErrorMaxSize, "Plugin Already Loaded");
		return APLRes_SilentFailure;
	}
	
	if (!IsDedicatedServer()) {

		strcopy(s_Error, s_ErrorMaxSize, "Listen Server Not Supported");
		return APLRes_Failure;
	}

	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false)) {

		strcopy(s_Error, s_ErrorMaxSize, "Game Not Supported");
		return APLRes_Failure;
	}

	RegPluginLibrary(PLUGIN_LIBRARY);
	f_OnBotCreated = CreateGlobalForward("OnBotCreatedFwd", ET_Event, Param_Cell, Param_Cell, Param_String);
	f_OnDestroySurvivorBots = CreateGlobalForward("OnDestroySurvivorBotsFwd", ET_Event, Param_Cell);
	f_OnRequestSurvivorBotRegulation = CreateGlobalForward("OnRequestSurvivorBotRegulationFwd", ET_Event, Param_Cell);
	f_OnFirstClientLoaded = CreateGlobalForward("OnFirstClientLoadedFwd", ET_Ignore);
	f_OnSurvivorIdle = CreateGlobalForward("OnSurvivorIdleFwd", ET_Event, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell, Param_String, Param_String, Param_String);
	f_OnSurvivorIdleEndFwd = CreateGlobalForward("OnSurvivorIdleEndFwd", ET_Event, Param_Cell);
	f_OnClientLoaded = CreateGlobalForward("OnAnyClientLoaded", ET_Event, Param_Cell);

	CreateNative("OnRegulateSurvivorBots", nativeOnRegulateBots);
	CreateNative("OnJoinSurvivorTeam", nativeOnJoinSurvivorTeam);
	CreateNative("OnSetSurvivorRequirements", nativeOnSetSurvivorRequirements);
	CreateNative("OnBlockSurvivorBotRegulation", nativeOnBlockSurvivorBotRegulation);
	CreateNative("OnAllowSurvivorBotRegulation", nativeOnAllowSurvivorBotRegulation);
	CreateNative("OnCreateSurvivorBots", nativeOnCreateSurvivorBots);
	CreateNative("OnDestroySurvivorBots", nativeOnDestroySurvivorBots);
	CreateNative("OnSlotManagement", nativeOnSlotManagement);
	CreateNative("OnReserveSlotManagement", nativeOnReserveSlotManagement);
	CreateNative("OnAllowReserveSlots", nativeOnAllowReserveSlots);
	CreateNative("OnBlockReserveSlots", nativeOnBlockReserveSlots);
	CreateNative("OnDestroySurvivorBotsEx", nativeOnDestroySurvivorBotsEx);
	CreateNative("OnRequestSurvivorBotRegulation", nativeOnRequestSurvivorBotRegulation);
	CreateNative("OnBlockSoloSurvivorBots", nativeOnBlockSoloSurvivorBots);
	CreateNative("OnAllowSoloSurvivorBots", nativeOnAllowSoloSurvivorBots);

	return APLRes_Success;
}

stock ExecCheatCommand(client = 0,const String:command[],const String:parameters[] = "")
{
	new iFlags = GetCommandFlags(command);
	SetCommandFlags(command,iFlags & ~FCVAR_CHEAT);

	if(!IsClientInGame(client))
	{
		ServerCommand("%s %s",command,parameters);
	}
	else
	{
		FakeClientCommand(client,"%s %s",command,parameters);
	}

	SetCommandFlags(command,iFlags);
	SetCommandFlags(command,iFlags|FCVAR_CHEAT);
}

public Action:eventPlayer_Disconnect(Handle:event, const String:event_name[], bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) bIsInRemovalQueue[client] = false;
	if (bAllowSurvivorBotRegulation) RegulateSurvivorBots();
}

public OnMapEnd() {

	/*

			Let's override bAllowSurvivorBotRegulation if it's enabled (by another plugin or not)
			and set it to false - The map is ending, and we don't want bot creation until all
			connecting players have filled spots.

			I collect this data even if the server isn't full, because what if there's only one
			open slot, and two players connect during a map change? We'd obviously let the first
			player in, but without this list, we wouldn't know who the second one to remove was.

			However, once all players are fully in-game, the list is cleared. It also means there
			is no real reason to check the list every time a player attempts connection, in case
			someone in the list disconnected FOR REAL, because the connection restriction is
			really only in place until all players from the previous map have loaded into the new
			map.

	*/
	bPreviousSurvivorBotRegulation = bAllowSurvivorBotRegulation;
	bAllowSurvivorBotRegulation = false;
	bIsFirstClientLoaded = false;

	if (bIsReserveSlotsAllowed) {

		if (GetArraySize(PlayersOnMapChange) > 0) ClearArray(Handle:PlayersOnMapChange);

		decl String:SteamAuthId[64];
		for (new i = 1; i <= MaxClients; i++) {

			if (!i || IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {

				GetClientAuthId(i, AuthId_Steam3, SteamAuthId, sizeof(SteamAuthId));
				PushArrayString(Handle:PlayersOnMapChange, SteamAuthId);
			}
		}
	}
}

public OnMapStart() {

	/*

			Alright, once all clients have entered the game, we change it to true, and revert
			bAllowSurvivorBotRegulation to its previous status.
	
	*/
	CreateTimer(1.0, Timer_AllClientsConnected, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_AllClientsConnected(Handle:timer) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && !IsClientInGame(i)) return Plugin_Continue;
	}
	bAllowSurvivorBotRegulation = bPreviousSurvivorBotRegulation;
	ClearArray(Handle:PlayersOnMapChange);
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons) {

	if (buttons & IN_ATTACK) {

		if (IsClientInGame(client) && GetClientTeam(client) == 1 && bIsOnBreak[client]) {

			CreateOrJoinSurvivorTeam(client);
		}
	}
	return Plugin_Continue;
}

public OnPluginStart() {

	CreateConVar("sbc_version", PLUGIN_VERSION, "the version of the plugin.");
	hSurvivorRequirement = 4;	// The default, and it can be changed by another plugin.
	hSurvivorMaximum = 4;
	bAllowSurvivorBotRegulation = true;
	bPreviousSurvivorBotRegulation = true;
	cSurvivorLimit = FindConVar("survivor_limit");
	cInfectedLimit = FindConVar("z_max_player_zombies");

	SetConVarBounds(cSurvivorLimit, ConVarBound_Upper, true, 32.0);
	SetConVarBounds(cInfectedLimit, ConVarBound_Upper, true, 32.0);
	HookConVarChange(cSurvivorLimit, OverrideSurvivorLimit);
	HookConVarChange(cInfectedLimit, OverrideInfectedLimit);

	hReserveSlots = 0;
	hMaximumSlots = 0;
	hRemovalDelay = 30;
	bIsReserveSlotsAllowed = false;
	hOnlySurvivorBotsIfHumans = false;	/*	If enabled, bots will not exist if no human survivors exist		*/

	PlayersOnMapChange	= CreateArray(32);
	DSBParams = CreateArray(32);

	g_sGameConf = LoadGameConfigFile("botcontrol");
	if (g_sGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
		if (hSetHumanSpec == INVALID_HANDLE) SetFailState("SetHumanSpec SIGNATURE INVALID");
	
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();
		if (hTakeOverBot == INVALID_HANDLE) SetFailState("hTakeOverBot SIGNATURE INVALID");
	}
	else SetFailState("File not found: .../gamedata/botcontrol.txt");

	HookEvent("player_team", eventPlayerTeam);
	HookEvent("player_disconnect", eventPlayer_Disconnect);
	LoadTranslations("botcontroller.phrases");

	AddCommandListener(listenJointeam, "jointeam");
	AddCommandListener(listenTakeabreak, "go_away_from_keyboard");
}

public Action:listenTakeabreak(client, String:command[], argc) {

	if (!bIsOnBreak[client]) {

		/*


				Creating a forward to store all of the players data, or at least let other plugins
				know what the player was carrying when they went to spectator.


		*/
		new wi = -1;
		decl String:winame[64];
		Call_StartForward(f_OnSurvivorIdle);
		Call_PushCell(client);

		for (new i = 0; i <= 4; i++) {

			wi = GetPlayerWeaponSlot(client, i);
			if (wi == -1) {

				Call_PushString("-1");
				Call_PushCell(wi);
				continue;
			}
			GetEntPropString(wi, Prop_Data, "m_ModelName", winame, sizeof(winame));
			Call_PushString(winame);
			if (i <= 1) {

				GetEntProp(wi, Prop_Send, "m_upgradeBitVec");
				Call_PushCell(wi);
			}
		}
		Call_Finish();
		ChangeClientTeam(client, 1);
		bIsOnBreak[client] = true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:listenJointeam(client, String:command[], argc) {

	decl String:cteam[32];
	GetCmdArg(1, cteam, sizeof(cteam));
	if ((StrEqual(cteam, "Survivor", false) || StrEqual(cteam, "2", false)) && GetClientTeam(client) != 2) CreateOrJoinSurvivorTeam(client); 
	else if ((StrEqual(cteam, "Infected", false) || StrEqual(cteam, "3", false)) && GetClientTeam(client) != 3) ChangeClientTeam(client, 3);
	else if ((StrEqual(cteam, "Spectator", false) || StrEqual(cteam, "1", false)) && GetClientTeam(client) != 1) {

		bIsOnBreak[client] = true;
		ChangeClientTeam(client, 1);
	}
	return Plugin_Handled;
}

public Action:eventPlayerTeam(Handle:event, const String:event_name[], bool:dontBroadcast) {

	new client											= GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && bAllowSurvivorBotRegulation) {

		CreateTimer(0.1, DelayRegulateSurvivorBots);
	}
}

public Action:DelayRegulateSurvivorBots(Handle:timer) {

	RegulateSurvivorBots();
	return Plugin_Stop;
}

public nativeOnRegulateBots(Handle:plugin, params) {

	/*	This will override and force regulation, but not if the plugin has self-regulation enabled.		*/

	if (!bAllowSurvivorBotRegulation) RegulateSurvivorBots();
	else LogError("OnRegulateSurvivorBots() native rejected - Self-Regulation enabled, please use native OnBlockSurvivorBotRegulation() first.");
}

public nativeOnAllowSoloSurvivorBots(Handle:plugin, params) {

	hOnlySurvivorBotsIfHumans = false;
}

public nativeOnBlockSoloSurvivorBots(Handle:plugin, params) {

	hOnlySurvivorBotsIfHumans = true;
}

public nativeOnBlockSurvivorBotRegulation(Handle:plugin, params) {

	bAllowSurvivorBotRegulation = false;
}

public nativeOnAllowSurvivorBotRegulation(Handle:plugin, params) {

	bAllowSurvivorBotRegulation = true;
}

public nativeOnRequestSurvivorBotRegulation(Handle:plugin, params) {

	Call_StartForward(f_OnRequestSurvivorBotRegulation);
	Call_PushCell(bAllowSurvivorBotRegulation);
	Call_Finish();
}

public nativeOnAllowReserveSlots(Handle:plugin, params) {

	bIsReserveSlotsAllowed = true;
}

public nativeOnBlockReserveSlots(Handle:plugin, params) {

	bIsReserveSlotsAllowed = false;
}
// moved to OnClientPostAdminCheck. Makes more sense.
//public OnClientConnected(client) { if (!IsFakeClient(client) && bAllowSurvivorBotRegulation) RegulateSurvivorBots(); }

stock NumberOfInfected() {

	new infected = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3) infected++;
	}
	return infected;
}

stock NumberOfSurvivors() {

	new survivors = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == 2) survivors++;
	}
	return survivors;
}

stock NumberOfHumanSurvivors() {

	new survivors = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i)) survivors++;
	}
	return survivors;
}

/*

		Without proper regulation, robots would quite easily overthrow mankind.
		If OnBlockSurvivorBotRegulation has NOT been called by another plugin
		which means this plugin handles regulation, then the OnRegulateSurvivorBots()
		native will do nothing. By design decision, of course. And partially my sanity.


*/
stock RegulateSurvivorBots() {

	if (hOnlySurvivorBotsIfHumans && NumberOfHumanSurvivors() > 0 || !hOnlySurvivorBotsIfHumans) {

		if (IsSurvivorBotAvailable() > 0 && NumberOfSurvivors() > hSurvivorRequirement) {

			KickBot(NumberOfSurvivors() - hSurvivorRequirement);
		}
		if (NumberOfSurvivors() < hSurvivorRequirement) CreateOrJoinSurvivorTeam(0);
	}
	else KickBot(NumberOfSurvivors());
}

public nativeOnCreateSurvivorBots(Handle:plugin, params) {

	new count = GetNativeCell(1);
	while (count > 0) {

		CreateOrJoinSurvivorTeam(0);
		count--;
	}
}

public nativeOnDestroySurvivorBots(Handle:plugin, params) {

	new count = GetNativeCell(1);
	if (count > 0) KickBot(count);
}

public nativeOnDestroySurvivorBotsEx(Handle:plugin, params) {

	if (GetArraySize(Handle:DSBParams) > 0) LogError("Cannot destroy survivor bots while destroying survivor bots.");
	else {

		decl String:text[64];

		new count = GetNativeCell(1);
		new extype = GetNativeCell(2);
		GetNativeString(3, text, sizeof(text));
		PushArrayString(Handle:DSBParams, text);
		GetNativeString(4, text, sizeof(text));
		PushArrayString(Handle:DSBParams, text);
		GetNativeString(5, text, sizeof(text));
		PushArrayString(Handle:DSBParams, text);
		
		KickBot(count, extype);
	}
}

stock KickBot(count, isEx=0) {

	new sCount = 0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2) {

			if (isEx == 0 || IsExEligible(i, isEx)) {

				KickClient(i);
				count--;
				sCount++;
			}
			if (count < 1) break;
		}
	}
	if (GetArraySize(Handle:DSBParams) > 0) {

		ClearArray(Handle:DSBParams);
		Call_StartForward(f_OnDestroySurvivorBots);
		Call_PushCell(sCount);
		Call_Finish();
	}
}

/*

		This function will check certain data about a bot based on information passed through in order
		to determine if the specific bot qualifies for removal.


*/
stock bool:IsExEligible(bot, eligType) {

	decl String:text[64];
	decl String:DSBtext[64];

	new size = GetArraySize(Handle:DSBParams);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:DSBParams, i, DSBtext, sizeof(DSBtext));
		if (StrContains(DSBtext, "none", false) != -1) continue;
		if (StrContains(DSBtext, ".mdl", false) != -1) {

			GetClientModel(bot, text, sizeof(text));
			if (StrEqual(DSBtext, text, false)) {

				if (eligType == 1) return true;
				else continue;	// we continue -> return true if every condition passes, return false when the first one fails.
			}
			else {

				if (eligType == 1) continue;
				else return false;
			}
		}
		if (StrEqual(DSBtext, "!dead", false)) {

			if (bot > 0 && IsClientInGame(bot) && IsPlayerAlive(bot)) {

				if (eligType == 1) return true;
				else continue;
			}
			else {

				if (eligType == 1) continue;
				else return false;
			}

			if (eligType == 1) return true;
			else continue;
		}
		if (StrEqual(DSBtext, "dead", false)) {

			if (bot > 0 && IsClientInGame(bot) && !IsPlayerAlive(bot)) {

				if (eligType == 1) return true;
				else continue;
			}
			else {

				if (eligType == 1) continue;
				else return false;
			}
		}
		
	}
	return false;
}

#define FORCE_INT_CHANGE(%1,%2,%3) public %1 (Handle:c, const String:o[], const String:n[]) { SetConVarInt(%2,%3); } 
FORCE_INT_CHANGE(OverrideSurvivorLimit, cSurvivorLimit, GetConVarInt(cSurvivorLimit))
FORCE_INT_CHANGE(OverrideInfectedLimit, cInfectedLimit, GetConVarInt(cSurvivorLimit))
public nativeOnSlotManagement(Handle:plugin, params) {

	new survivorLimit = GetNativeCell(1);
	new infectedLimit = GetNativeCell(2);

	if (survivorLimit > 0) SetConVarInt(cSurvivorLimit, survivorLimit);
	if (infectedLimit > 0) SetConVarInt(cInfectedLimit, infectedLimit);
}

/*


		Allows the manual setting of both reserve slots and maximum slots.
		Please do be careful, you can actually set these values both to 0 and
		that would be pretty bad, wouldn't it?

		If there are more players in-game than the new settings, it will kick
		UP TO the amount of players over, or stop sooner if it runs out of
		players who don't have reserve access.

		These values don't actually affect the survivor_limit or z_max_player_zombies
		nor does it affect the servers actual client restrictions.

		The plugin enforces its own user-set restrictions, and stores all players
		STEAM ID's who successfully	enter the game, so when a player (or all players
		more accurately) are connecting during the next map, in the event that a
		player tries to connect, going over the player limit, it'll determine who
		isn't one of the players from the full game, because their STEAM ID won't
		be present in the list, and they will be dropped, unless of course, they're
		a reserve player, and they'll be sent to spectator, at which time a timer
		will start on a random player who doesn't have the reserve flag - If there
		are no eligible players, the player will ultimately be refused connection.


*/
public nativeOnReserveSlotManagement(Handle:plugin, params) {

	hReserveSlots = GetNativeCell(1);
	hMaximumSlots = GetNativeCell(2);
	hRemovalDelay = GetNativeCell(3);
	new players = PlayersInGame();
	if (players > hMaximumSlots) PlayerSlotManagement(hMaximumSlots - players);
	SetConVarInt(FindConVar("sv_maxplayers"), hMaximumSlots + hReserveSlots);
}

public PlayersInGame() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (i > 0 && IsClientConnected(i) && IsClientInGame(i)) count++;
	}
	return count;
}

stock PlayerSlotManagement(count) {

	new client = EligiblePlayerSlotManagement();

	if (PlayersInGame() < hMaximumSlots || client < 1 || bIsInRemovalQueue[client]) return;
	bIsInRemovalQueue[client] = true;
	if (hRemovalDelay > 0 && PlayersInGame() < hMaximumSlots + hReserveSlots) CreateTimer(1.0, DelayPlayerSlotManagement, client, TIMER_REPEAT);
	else {

		decl String:text[64];
		Format(text, sizeof(text), "%T", "slot reservation", client);
		KickClient(client, text);
	}
	count--;

	if (count > 0) PlayerSlotManagement(count);
}

public OnClientPostAdminCheck(client) {

	// || GetArraySize(PlayersOnMapChange) < 1)
	if (!bIsFirstClientLoaded) {

		bIsFirstClientLoaded	= true;
		Call_StartForward(f_OnFirstClientLoaded);
		Call_Finish();
	}
	if (GetArraySize(PlayersOnMapChange) > 0) {

		if (bIsReserveSlotsAllowed) {

			decl String:text[64];
			Format(text, sizeof(text), "%T", "slot reservation", client);

			if (client > 0 && !IsSavedPlayerStatus(client)) {

				if (hMaximumSlots <= GetArraySize(PlayersOnMapChange) && hMaximumSlots + hReserveSlots > GetArraySize(PlayersOnMapChange) &&
					!EligiblePlayerSlotManagement() && IsADMFLAG_RESERVATION(client)) {

					/*

							This is what I like to call a really shitty situation.
							It's great for admins who have to connect to the server in an emergency situation to deal with problem players
							allowing the player to connect on the reserve slots, though they're restricted to the time they can stay
							connected. The kick timer will appear, but will discontinue in the event that a slot opens up on the server.
					*/
					CreateTimer(1.0, DelayPlayerSlotManagement, client, TIMER_REPEAT);
					return;
				}

				/*

						The only time this array isn't empty is when players are still connecting from a recent map change.
						There are two options here: check if the size of this array is less than the maximum players allowed
						and if it is, yay, connect! If not, see if they're a reserve player, and if there's a spot. If they
						are, yay, connect! Otherwise, bye.


				*/
				if (hMaximumSlots < GetArraySize(PlayersOnMapChange)) {

					if (!IsADMFLAG_RESERVATION(client)) {

						KickClient(client, text);
						return;
					}
					else {

						/*

								If we can't find a player to remove, the player connecting is removed - even if they're reserve flagged.
								However, if we do find a player, two things can happen:

								First, if hRemovalDelay is 0, the player will be removed, without warning. Otherwise, if it's greater than 0
								and there are reserve slots not in use on the server, the new player connecting will be placed in spectator
								while the target player will be given a countdown, warning them of their inevitable doom.


						*/

						new target = EligiblePlayerSlotManagement();
						if (target < 1) {

							KickClient(client, text);
							return;
						}
						else {

							if (hRemovalDelay > 0 && PlayersInGame() < hMaximumSlots + hReserveSlots) CreateTimer(1.0, DelayPlayerSlotManagement, target, TIMER_REPEAT);
							else {

								decl String:SteamAuthId[64];
								GetClientAuthId(target, AuthId_Steam3, SteamAuthId, sizeof(SteamAuthId));

								KickClient(target, text);
								if (GetArraySize(PlayersOnMapChange) > 0) RemoveTargetFromList(SteamAuthId);
							}
						}
					}
				}
			}
		}
	}
	if (bAllowSurvivorBotRegulation) RegulateSurvivorBots();
	Call_StartForward(f_OnClientLoaded);
	Call_PushCell(client);
	Call_Finish();
}

stock RemoveTargetFromList(String:AuthId[]) {

	new size = GetArraySize(PlayersOnMapChange);
	if (size < 1) return;
	decl String:text[64];
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:PlayersOnMapChange, i, text, sizeof(text));
		if (StrEqual(AuthId, text, false)) {

			RemoveFromArray(Handle:PlayersOnMapChange, i);
			return;
		}
	}
}

stock EligiblePlayerSlotManagement() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i)) {

			/*

					Players eligible to be removed must already be fully in-game.


			*/
			if (!IsADMFLAG_RESERVATION(i)) return i;
		}
	}
	return 0;
}

stock bool:IsADMFLAG_RESERVATION(client) {
	
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {
		decl flags;
		flags = GetUserFlagBits(client);
		if (!(flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)) return false;
		return true;
	}
	else return false;
}

stock bool:IsSavedPlayerStatus(client) {

	decl String:SteamAuthId[64];
	GetClientAuthId(client, AuthId_Steam3, SteamAuthId, sizeof(SteamAuthId));
	decl String:text[64];

	new size = GetArraySize(Handle:PlayersOnMapChange);
	if (size < 1) {

		/*

				False-positive. Even if all players have loaded in and the array is cleared, if there are
				too many players in-game, and no openings, pretend the player failed the check and continue
				to checking the next best thing: if they're a player with the reserve flag and if there are
				players without it on the server, and then proceed to give one of them the boot if they are
				found.
		*/
		if (hMaximumSlots > PlayersInGame()) return true;
		else return false;
	}
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:PlayersOnMapChange, i, text, sizeof(text));
		if (StrEqual(SteamAuthId, text, false)) return true;
	}
	return false;
}

public Action:DelayPlayerSlotManagement(Handle:timer, any:client) {

	static count										= 0;
	count++;
	if (PlayersInGame() < hMaximumSlots) {

		bIsInRemovalQueue[client] = false;
		count = 0;
		return Plugin_Stop;
	}
	else if (count >= hRemovalDelay) {

		decl String:text[64];
		Format(text, sizeof(text), "%T", "slot reservation", client);
		KickClient(client, text);
		count = 0;
		bIsInRemovalQueue[client] = false;
		return Plugin_Stop;
	}
	else {

		if (IsClientInGame(client)) PrintHintText(client, "%T", "slot management delay", client, hRemovalDelay - count);
	}
	return Plugin_Continue;
}

public nativeOnSetSurvivorRequirements(Handle:plugin, params) {

	hSurvivorRequirement = GetNativeCell(1);
	hSurvivorMaximum = GetNativeCell(2);
	if (bAllowSurvivorBotRegulation) RegulateSurvivorBots();
}

public nativeOnJoinSurvivorTeam(Handle:plugin, params) {

	new client = GetNativeCell(1);
	if (client == 0 || client > 0 && GetClientTeam(client) != 2) {

		CreateOrJoinSurvivorTeam(client); 
	}
}

stock CreateOrJoinSurvivorTeam(client) {

	new bot = IsSurvivorBotAvailable();
	if (bot > 0 && client > 0) {

		new nCharacter = GetEntProp(bot, Prop_Send, "m_survivorCharacter");
		decl String:nModel[64];
		GetClientModel(bot, nModel, sizeof(nModel));

		SDKCall(hSetHumanSpec, bot, client);
		SDKCall(hTakeOverBot, client, true);

		Call_StartForward(f_OnBotCreated);
		Call_PushCell(client);
		Call_PushCell(nCharacter);
		Call_PushString(nModel);
		Call_Finish();

		if (bIsOnBreak[client]) {

			Call_StartForward(f_OnSurvivorIdleEndFwd);
			Call_PushCell(client);
			Call_Finish();
			bIsOnBreak[client] = false;
		}
	}
	else if (NumberOfSurvivors() < hSurvivorMaximum && client == 0 ||
			 NumberOfSurvivors() < GetConVarInt(cSurvivorLimit) && bot < 1 && client > 0) {
	/*

			The above statement allows some flexibility for server operators as well as plugin developers.
			
			hSurvivorMaximum dictates the maximum number of survivor bots that can ever be present, but
			keep in mind that the only way to reach this point is setting the minimum to the maximum or
			by forcing bots to spawn by passing client = 0.

			This lets you guarantee that even if the survivor team limit is 20, that, say, the most bots you
			would have without forcing additional bots would be 8, if for example. the hSurvivorMaximum was
			set to 8. Having a separate limit for survivor bots should also protect against a plugin that
			goes off its rails on bot spawning, at least through this plugin.

			And, if for some reason this feature ends up being redundant, it's an easy removal.
			I really shouldn't write code when I'm stoned, because I'm slightly questioning if anyone will
			ever use this feature. HEAR ME? SOMEONE PLEASE USE THIS.

			p.s. Yes, it will still always create a bot for players trying to join, if the team isn't full.
				 That's what the second half of the statement is for.
	*/

		bot = CreateFakeClient("bot");
		if (bot != 0) {

			ChangeClientTeam(bot, 2);
			if (DispatchKeyValue(bot, "classname", "survivorbot") && DispatchSpawn(bot)) {

				new Float:pos[3];
				if (IsPlayerAlive(bot)) {

					for (new i = 1; i <= MaxClients; i++) {

						if (IsClientInGame(i) && GetClientTeam(i) == 2 && i != bot) {

							GetClientAbsOrigin(i, pos);
							TeleportEntity(bot, pos, NULL_VECTOR, NULL_VECTOR);
							break;
						}
					}
				}
				if (IsClientInGame(bot) && GetClientTeam(bot) == 2) KickClient(bot);
			}
		}
		if (client > 0) CreateTimer(0.1, DelayJoinSurvivorTeam, client);
		if (NumberOfSurvivors() < hSurvivorRequirement && bAllowSurvivorBotRegulation) CreateOrJoinSurvivorTeam(0);
	}
}

public Action:DelayJoinSurvivorTeam(Handle:timer, any:client) {

	if (IsClientInGame(client) && !IsFakeClient(client)) CreateOrJoinSurvivorTeam(client);
	return Plugin_Stop;
}

public IsSurvivorBotAvailable() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2) return i;
	}
	return 0;
}